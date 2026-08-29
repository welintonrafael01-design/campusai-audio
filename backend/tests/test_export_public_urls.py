import pytest

from app.public_urls import PublicUrlConfigurationError
from app.services.export_service import public_verification_url


def test_verification_url_keeps_local_development_default(monkeypatch):
    monkeypatch.setenv("APP_ENV", "development")
    monkeypatch.delenv("APP_WEB_URL", raising=False)

    assert public_verification_url("REC 123") == (
        "http://localhost:3000/#/verify/REC%20123"
    )


def test_verification_url_requires_public_origin_in_production(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.delenv("APP_WEB_URL", raising=False)

    with pytest.raises(PublicUrlConfigurationError):
        public_verification_url("REC-123")


def test_verification_url_uses_public_origin_in_production(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("APP_WEB_URL", "https://example.com")

    assert public_verification_url("REC-123") == (
        "https://example.com/#/verify/REC-123"
    )
