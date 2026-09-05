from __future__ import annotations

from pathlib import Path

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app import persistence_config
from app.routes import documents
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services import audio_service, audiobook_service, rag_service
from app.services.private_artifact_storage import (
    build_private_artifact_path,
    download_private_artifact,
    list_private_artifacts_for_user,
    upload_private_artifact,
)


class _StorageBucket:
    def __init__(self, objects: dict[str, bytes]):
        self.objects = objects

    def upload(self, *, path, file, file_options):
        del file_options
        self.objects[path] = bytes(file)
        return {"path": path}

    def download(self, path):
        return self.objects[path]

    def remove(self, paths):
        for path in paths:
            self.objects.pop(path, None)

    def list(self, *, path, options=None):
        options = options or {}
        prefix = f"{path}/"
        rows = [
            {"name": key.removeprefix(prefix)}
            for key in self.objects
            if key.startswith(prefix) and "/" not in key.removeprefix(prefix)
        ]
        offset = int(options.get("offset", 0))
        limit = int(options.get("limit", len(rows)))
        return rows[offset:offset + limit]


class _Storage:
    def __init__(self):
        self.objects: dict[str, dict[str, bytes]] = {}

    def from_(self, bucket):
        return _StorageBucket(self.objects.setdefault(bucket, {}))


class _Client:
    def __init__(self):
        self.storage = _Storage()


class _EmbeddingFunction:
    def embed_documents(self, texts):
        return [[float(index + 1), 0.5] for index, _ in enumerate(texts)]

    def embed_query(self, text):
        return [float(len(text)), 0.5]


class _SpeechResponse:
    def __init__(self):
        self.path: Path | None = None

    def write_to_file(self, path):
        self.path = Path(path)
        self.path.write_bytes(b"private-audio")


def test_production_persistence_fails_closed_without_required_config(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    for name in (
        "SUPABASE_URL",
        "SUPABASE_ANON_KEY",
        "SUPABASE_SERVICE_ROLE_KEY",
        "SUPABASE_STORAGE_BUCKET",
        "SUPABASE_PRIVATE_ARTIFACTS_BUCKET",
    ):
        monkeypatch.delenv(name, raising=False)

    with pytest.raises(
        persistence_config.ProductionPersistenceConfigurationError
    ):
        persistence_config.validate_production_persistence_configuration()


def test_private_artifact_paths_reject_traversal():
    with pytest.raises(ValueError):
        build_private_artifact_path(
            user_id="user-a",
            category="audio",
            filename="../other-user.mp3",
        )


def test_private_artifact_survives_service_calls_and_is_owner_scoped(monkeypatch):
    monkeypatch.setenv("SUPABASE_PRIVATE_ARTIFACTS_BUCKET", "private")
    client = _Client()

    upload_private_artifact(
        user_id="user-a",
        category="audio",
        filename="lesson.mp3",
        content=b"durable",
        content_type="audio/mpeg",
        client=client,
    )

    assert download_private_artifact(
        user_id="user-a",
        category="audio",
        filename="lesson.mp3",
        client=client,
    ) == b"durable"
    with pytest.raises(KeyError):
        download_private_artifact(
            user_id="user-b",
            category="audio",
            filename="lesson.mp3",
            client=client,
        )


def test_private_artifact_inventory_paginates_for_account_deletion(monkeypatch):
    monkeypatch.setenv("SUPABASE_PRIVATE_ARTIFACTS_BUCKET", "private")
    client = _Client()
    bucket = client.storage.objects.setdefault("private", {})
    for index in range(1001):
        bucket[f"user-a/audio/audio-{index}.mp3"] = b"audio"

    paths = list_private_artifacts_for_user(user_id="user-a", client=client)

    assert len(paths) == 1001
    assert len(set(paths)) == 1001


def test_production_audio_upload_cleans_temporary_file(monkeypatch):
    response = _SpeechResponse()
    captured: dict = {}
    monkeypatch.setattr(audio_service, "is_production_environment", lambda: True)
    monkeypatch.setattr(
        audio_service.client.audio.speech,
        "create",
        lambda **kwargs: response,
    )
    monkeypatch.setattr(
        audio_service,
        "upload_private_artifact",
        lambda **kwargs: captured.update(kwargs),
    )

    filename = audio_service.generate_audio_from_text(
        "Contenido educativo",
        user_id="user-a",
    )

    assert filename.endswith(".mp3")
    assert captured["content"] == b"private-audio"
    assert response.path is not None
    assert not response.path.exists()


def test_production_audiobook_audio_restores_from_private_storage(monkeypatch):
    response = _SpeechResponse()
    stored: dict[str, bytes] = {}
    monkeypatch.setattr(
        audiobook_service,
        "is_production_environment",
        lambda: True,
    )
    monkeypatch.setattr(
        audiobook_service.client.audio.speech,
        "create",
        lambda **kwargs: response,
    )

    def upload(**kwargs):
        stored[kwargs["filename"]] = kwargs["content"]

    monkeypatch.setattr(audiobook_service, "upload_private_artifact", upload)
    monkeypatch.setattr(
        audiobook_service,
        "download_private_artifact",
        lambda **kwargs: stored[kwargs["filename"]],
    )
    audiobook_id = audiobook_service.scoped_audiobook_storage_id(
        user_id="user-a",
        audiobook_id="book-a",
    )

    payload = audiobook_service.generate_chapter_audio_payload(
        user_id="user-a",
        audiobook_id=audiobook_id,
        chapter_id="chapter-1",
        script="Explicacion del capitulo",
    )
    filename = payload["audio_url"].rsplit("/", 1)[-1]

    assert audiobook_service.read_audiobook_audio_content(
        user_id="user-a",
        filename=filename,
    ) == b"private-audio"
    assert response.path is not None
    assert not response.path.exists()


def test_production_rag_requires_owner_and_restores_owner_scoped_chunks(monkeypatch):
    rows_by_owner: dict[str, list[dict]] = {}
    monkeypatch.setattr(rag_service, "is_production_environment", lambda: True)
    monkeypatch.setattr(rag_service, "embedding_function", _EmbeddingFunction())
    monkeypatch.setattr(
        rag_service,
        "_production_document_exists",
        lambda **kwargs: False,
    )

    def store(**kwargs):
        rows_by_owner[kwargs["owner_scope"]] = [
            {
                "document_id": kwargs["document_id"],
                "chunk_index": 0,
                "page_number": 1,
                "content": kwargs["chunks"][0]["text"],
                "distance": 0.1,
            }
        ]

    monkeypatch.setattr(rag_service, "_store_production_chunks", store)
    monkeypatch.setattr(
        rag_service,
        "_query_production_chunks",
        lambda **kwargs: rows_by_owner.get(kwargs["owner_scope"], []),
    )

    document_id = rag_service.store_document_page_embeddings(
        [{"page_number": 1, "text": "Contenido privado A"}],
        owner_scope="user-a",
    )
    restored = rag_service.search_similar_chunks(
        document_id,
        "Contenido",
        owner_scope="user-a",
    )

    assert "Contenido privado A" in restored
    assert rag_service.search_similar_chunks(
        document_id,
        "Contenido",
        owner_scope="user-b",
    ) == ""
    with pytest.raises(PermissionError):
        rag_service.search_similar_chunks(document_id, "Contenido")


def test_document_upload_rolls_back_durable_state_on_partial_failure(
    monkeypatch,
    tmp_path,
):
    temporary_pdf = tmp_path / "upload.pdf"
    temporary_pdf.write_bytes(b"%PDF-1.4 fixture")
    rollback: dict[str, object] = {}

    async def save_upload(_file):
        return temporary_pdf

    app = FastAPI()
    app.include_router(documents.router)
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id="user-a",
        email="user-a@example.test",
    )
    monkeypatch.setattr(documents, "is_production_environment", lambda: True)
    monkeypatch.setattr(documents, "enforce_pdf_upload_limit", lambda **kwargs: "student")
    monkeypatch.setattr(documents, "enforce_summary_limit", lambda **kwargs: "student")
    monkeypatch.setattr(documents, "save_upload_file", save_upload)
    monkeypatch.setattr(
        documents,
        "extract_pages_from_pdf",
        lambda path: [{"page_number": 1, "text": "Contenido"}],
    )
    monkeypatch.setattr(
        documents,
        "index_document_pages_for_rag",
        lambda pages, owner_scope: "doc-a",
    )
    monkeypatch.setattr(
        documents,
        "upload_document_to_storage",
        lambda **kwargs: {
            "bucket": "documents",
            "storage_path": "user-a/documents/doc-a/upload.pdf",
        },
    )
    monkeypatch.setattr(
        documents,
        "register_document_file",
        lambda **kwargs: kwargs,
    )
    monkeypatch.setattr(documents, "register_usage_event", lambda **kwargs: None)
    monkeypatch.setattr(documents, "generate_ai_summary", lambda *args, **kwargs: "Resumen")
    monkeypatch.setattr(
        documents,
        "create_cloud_document",
        lambda **kwargs: (_ for _ in ()).throw(RuntimeError("database down")),
    )
    monkeypatch.setattr(
        documents,
        "delete_document_storage_object",
        lambda **kwargs: rollback.update(storage=kwargs),
    )
    monkeypatch.setattr(
        documents,
        "delete_document_embeddings",
        lambda document_id, owner_scope: rollback.update(
            rag=(document_id, owner_scope)
        ),
    )

    response = TestClient(app).post(
        "/documents/upload",
        files={"file": ("upload.pdf", b"%PDF-1.4 fixture", "application/pdf")},
    )

    assert response.status_code == 500
    assert rollback["rag"] == ("doc-a", "user-a")
    assert rollback["storage"] == {
        "bucket": "documents",
        "storage_path": "user-a/documents/doc-a/upload.pdf",
    }
    assert not temporary_pdf.exists()
