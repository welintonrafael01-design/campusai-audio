import pytest

from app.public_urls import (
    PublicUrlConfigurationError,
    configured_app_web_origin,
    resolve_web_redirect,
    validate_public_https_url,
)


def test_production_requires_public_web_origin(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.delenv("APP_WEB_URL", raising=False)

    with pytest.raises(PublicUrlConfigurationError):
        configured_app_web_origin()


@pytest.mark.parametrize(
    "value",
    [
        "http://example.com",
        "https://localhost",
        "https://127.0.0.1",
        "https://release-validation.invalid",
    ],
)
def test_production_public_url_rejects_unsafe_hosts(value):
    with pytest.raises(PublicUrlConfigurationError):
        validate_public_https_url(value, variable_name="APP_WEB_URL")


def test_production_redirect_uses_configured_public_web_origin(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("APP_WEB_URL", "https://example.com")
    monkeypatch.delenv("APP_SUCCESS_URL", raising=False)

    assert resolve_web_redirect(
        "APP_SUCCESS_URL",
        app_path="/#/plans?checkout=success",
        development_default="http://localhost:5000",
    ) == "https://example.com/#/plans?checkout=success"


def test_development_redirect_keeps_local_default(monkeypatch):
    monkeypatch.setenv("APP_ENV", "development")
    monkeypatch.delenv("APP_WEB_URL", raising=False)
    monkeypatch.delenv("APP_SUCCESS_URL", raising=False)

    assert resolve_web_redirect(
        "APP_SUCCESS_URL",
        app_path="/#/plans?checkout=success",
        development_default="http://localhost:5000",
    ) == "http://localhost:5000"
