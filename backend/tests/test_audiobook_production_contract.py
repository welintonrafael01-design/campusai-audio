import pytest
from fastapi import HTTPException

from app.routes import audiobook as audiobook_route
from app.routes.health import health_check
from app.security.user_auth import AuthenticatedUser
from app.services.audiobook_service import (
    audio_filename_belongs_to_user,
    audiobook_owner_scope,
    scoped_audiobook_storage_id,
)
from app.services.cloud_service import _audiobook_payload_contains_filename


def _user(user_id: str) -> AuthenticatedUser:
    return AuthenticatedUser(user_id=user_id, email=f"{user_id}@example.com")


def test_audiobook_audio_scope_is_stable_and_owner_specific():
    scope_a = audiobook_owner_scope("student_a")
    scope_b = audiobook_owner_scope("student_b")
    storage_id = scoped_audiobook_storage_id(
        user_id="student_a",
        audiobook_id="document_alpha_audiobook",
    )
    filename = f"{storage_id}_chapter_1.mp3"

    assert scope_a != scope_b
    assert storage_id.startswith(f"{scope_a}_")
    assert audio_filename_belongs_to_user(
        user_id="student_a",
        filename=filename,
    )
    assert not audio_filename_belongs_to_user(
        user_id="student_b",
        filename=filename,
    )


@pytest.mark.asyncio
async def test_chapter_generation_never_trusts_client_owner_scope(monkeypatch):
    captured = {}

    def fake_generate(**kwargs):
        captured.update(kwargs)
        return {"audio_url": "/audiobook/audio/safe.mp3"}

    monkeypatch.setattr(
        audiobook_route,
        "generate_chapter_audio_payload",
        fake_generate,
    )

    await audiobook_route.generate_chapter_audio_endpoint(
        payload=audiobook_route.AudioBookChapterAudioPayload(
            audiobook_id="document_alpha_audiobook",
            chapter_id="chapter_1",
            script="Contenido seguro",
        ),
        current_user=_user("student_a"),
    )

    assert captured["audiobook_id"].startswith(
        f"{audiobook_owner_scope('student_a')}_"
    )
    assert "student_a" not in captured["audiobook_id"]


@pytest.mark.asyncio
async def test_student_cannot_fetch_another_users_audio(monkeypatch):
    filename = (
        f"{scoped_audiobook_storage_id(user_id='student_a', audiobook_id='book')}"
        "_chapter_1.mp3"
    )
    monkeypatch.setattr(
        audiobook_route,
        "user_owns_legacy_audiobook_audio",
        lambda **_: False,
    )

    with pytest.raises(HTTPException) as error:
        await audiobook_route.get_audiobook_audio(
            filename=filename,
            current_user=_user("student_b"),
        )

    assert error.value.status_code == 404


def test_legacy_audio_ownership_matches_exact_filename_only():
    payload = {
        "chapters": [
            {"audio_url": "/audiobook/audio/alpha_chapter_1.mp3"},
        ]
    }

    assert _audiobook_payload_contains_filename(
        payload,
        "alpha_chapter_1.mp3",
    )
    assert not _audiobook_payload_contains_filename(
        payload,
        "beta_chapter_1.mp3",
    )


def test_health_exposes_release_build_identity(monkeypatch):
    monkeypatch.setenv("APP_BUILD_SHA", "abc123")

    health = health_check()

    assert health["status"] == "ok"
    assert health["build_sha"] == "abc123"
    assert health["started_at"]
