from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routes import voice
from app.security import user_auth
from app.security.user_auth import AuthenticatedUser, require_current_user


def _app() -> FastAPI:
    app = FastAPI()
    app.include_router(voice.router)
    return app


def test_voice_endpoints_require_authentication():
    client = TestClient(_app())

    coach = client.post("/voice/coach", json={"message": "Hola"})
    tts = client.post("/voice/tts", json={"text": "Hola"})

    assert coach.status_code == 401
    assert tts.status_code == 401


def test_authenticated_voice_coach_uses_existing_contract(monkeypatch):
    app = _app()
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id="student_1",
        email="student@studybook.ai",
        app_metadata={"role": "student"},
    )
    monkeypatch.setattr(
        voice,
        "ask_ai_coach",
        lambda **kwargs: {"response": kwargs["message"]},
    )
    monkeypatch.setattr(
        voice,
        "enforce_voice_permission",
        lambda **kwargs: "student",
    )

    response = TestClient(app).post(
        "/voice/coach",
        json={"message": "Repasemos"},
    )

    assert response.status_code == 200
    assert response.json() == {"response": "Repasemos"}


def test_voice_endpoints_enforce_subscription_entitlement(monkeypatch):
    app = _app()
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id="free_1",
        email="free@studybook.ai",
        app_metadata={"role": "student"},
    )

    def deny_voice(**kwargs):
        del kwargs
        from fastapi import HTTPException

        raise HTTPException(
            status_code=403,
            detail="Voice Tutor no está disponible en tu plan.",
        )

    monkeypatch.setattr(voice, "enforce_voice_permission", deny_voice)

    client = TestClient(app)
    coach = client.post("/voice/coach", json={"message": "Hola"})
    tts = client.post("/voice/tts", json={"text": "Hola"})

    assert coach.status_code == 403
    assert tts.status_code == 403


def test_invalid_token_error_does_not_leak_provider_details(monkeypatch):
    class FailingAuth:
        @staticmethod
        def get_user(token):
            raise RuntimeError("provider-secret-debug-detail")

    fake_client = type("Client", (), {"auth": FailingAuth()})()
    monkeypatch.setattr(user_auth, "get_supabase_client", lambda: fake_client)

    client = TestClient(_app())
    response = client.post(
        "/voice/coach",
        headers={"Authorization": "Bearer invalid-token"},
        json={"message": "Hola"},
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "La sesión no es válida o ha expirado."
    assert "provider-secret-debug-detail" not in response.text
