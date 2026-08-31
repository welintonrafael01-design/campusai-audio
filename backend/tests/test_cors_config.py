import pytest
from fastapi.testclient import TestClient

from app.main import app, get_cors_origin_regex, get_cors_origins
from app.public_urls import PublicUrlConfigurationError


def test_cors_preflight_allows_ephemeral_flutter_web_loopback_origin():
    origin = "http://localhost:45678"
    response = TestClient(app).options(
        "/cloud/library-documents",
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "authorization,content-type",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == origin


def test_cors_preflight_rejects_non_loopback_untrusted_origin():
    response = TestClient(app).options(
        "/cloud/library-documents",
        headers={
            "Origin": "https://untrusted.example",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers


def test_production_cors_fails_closed_without_public_origin(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.delenv("APP_WEB_URL", raising=False)
    monkeypatch.delenv("BACKEND_CORS_ORIGINS", raising=False)

    with pytest.raises(PublicUrlConfigurationError):
        get_cors_origins()


def test_production_cors_uses_exact_https_origin_without_regex(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("APP_WEB_URL", "https://example.com")
    monkeypatch.delenv("BACKEND_CORS_ORIGINS", raising=False)
    monkeypatch.delenv("BACKEND_CORS_ORIGIN_REGEX", raising=False)

    assert get_cors_origins() == ["https://example.com"]
    assert get_cors_origin_regex() is None


def test_production_cors_accepts_only_studybook_web_origins(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("APP_WEB_URL", "https://studybookai.com")
    monkeypatch.setenv(
        "BACKEND_CORS_ORIGINS",
        "https://studybookai.com,https://www.studybookai.com",
    )
    monkeypatch.delenv("BACKEND_CORS_ORIGIN_REGEX", raising=False)

    assert get_cors_origins() == [
        "https://studybookai.com",
        "https://www.studybookai.com",
    ]
    assert get_cors_origin_regex() is None
