from __future__ import annotations

import os
from urllib.parse import urlsplit


PRODUCTION_ENVIRONMENTS = {"production", "prod"}
LOCAL_HOSTS = {"localhost", "127.0.0.1", "10.0.2.2", "::1"}


class PublicUrlConfigurationError(RuntimeError):
    pass


def is_production_environment() -> bool:
    return (
        os.getenv("APP_ENV", "development").strip().lower()
        in PRODUCTION_ENVIRONMENTS
    )


def validate_public_https_url(
    value: str,
    *,
    variable_name: str,
    origin_only: bool = False,
) -> str:
    clean = str(value or "").strip()
    parsed = urlsplit(clean)
    host = (parsed.hostname or "").lower()

    if (
        parsed.scheme != "https"
        or not host
        or parsed.username is not None
        or parsed.password is not None
        or host in LOCAL_HOSTS
        or host.endswith(".invalid")
    ):
        raise PublicUrlConfigurationError(
            f"{variable_name} debe ser una URL HTTPS publica no local."
        )

    if origin_only and (
        parsed.path not in {"", "/"} or parsed.query or parsed.fragment
    ):
        raise PublicUrlConfigurationError(
            f"{variable_name} debe contener solo el origen publico."
        )

    return clean.rstrip("/") if origin_only else clean


def configured_app_web_origin(*, required: bool | None = None) -> str | None:
    value = os.getenv("APP_WEB_URL", "").strip()
    must_exist = is_production_environment() if required is None else required
    if not value:
        if must_exist:
            raise PublicUrlConfigurationError(
                "APP_WEB_URL es obligatorio en produccion."
            )
        return None

    if is_production_environment():
        return validate_public_https_url(
            value,
            variable_name="APP_WEB_URL",
            origin_only=True,
        )
    return value.rstrip("/")


def resolve_web_redirect(
    variable_name: str,
    *,
    app_path: str,
    development_default: str,
) -> str:
    value = os.getenv(variable_name, "").strip()
    if not value:
        app_origin = configured_app_web_origin()
        value = (
            f"{app_origin}{app_path}"
            if app_origin is not None
            else development_default
        )

    if is_production_environment():
        return validate_public_https_url(
            value,
            variable_name=variable_name,
        )
    return value
