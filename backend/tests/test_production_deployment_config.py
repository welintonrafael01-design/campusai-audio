import json
from pathlib import Path

import yaml

from app.routes.health import health_check


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
MOBILE_ROOT = REPOSITORY_ROOT / "mobile" / "campusai_mobile"


def test_render_blueprint_is_manual_and_uses_production_contract():
    blueprint = yaml.safe_load(
        (REPOSITORY_ROOT / "render.yaml").read_text(encoding="utf-8")
    )
    service = blueprint["services"][0]
    environment = {item["key"]: item for item in service["envVars"]}

    assert service["runtime"] == "python"
    assert service["rootDir"] == "backend"
    assert service["autoDeployTrigger"] == "off"
    assert service["healthCheckPath"] == "/health"
    assert "$PORT" in service["startCommand"]
    assert environment["APP_ENV"]["value"] == "production"
    assert environment["APP_WEB_URL"]["sync"] is False
    assert environment["BACKEND_CORS_ORIGINS"]["sync"] is False
    assert environment["SUPABASE_SERVICE_ROLE_KEY"]["sync"] is False
    assert environment["OPENAI_API_KEY"]["sync"] is False


def test_vercel_contract_builds_flutter_output_and_routes_public_pages():
    config = json.loads(
        (MOBILE_ROOT / "vercel.json").read_text(encoding="utf-8")
    )
    rewrites = {
        item["source"]: item["destination"]
        for item in config["rewrites"]
    }

    assert config["buildCommand"] == "bash tool/build_vercel_web.sh"
    assert config["outputDirectory"] == "build/web"
    assert config["redirects"][0]["has"] == [
        {"type": "host", "value": "www.studybookai.com"}
    ]
    assert config["redirects"][0]["destination"] == (
        "https://studybookai.com/:path*"
    )
    assert rewrites["/privacy"] == "/privacy/index.html"
    assert rewrites["/account-deletion"] == (
        "/account-deletion/index.html"
    )
    assert config["rewrites"][-1] == {
        "source": "/(.*)",
        "destination": "/index.html",
    }


def test_release_template_uses_registered_public_domain():
    config = json.loads(
        (MOBILE_ROOT / "config" / "release.example.json").read_text(
            encoding="utf-8"
        )
    )

    assert config["API_BASE_URL"] == "https://api.studybookai.com"
    assert config["APP_WEB_URL"] == "https://studybookai.com"
    assert config["PRIVACY_URL"] == "https://studybookai.com/privacy"
    assert config["ACCOUNT_DELETION_URL"] == (
        "https://studybookai.com/account-deletion"
    )


def test_public_legal_pages_remain_honest_drafts_until_human_review():
    pages = {
        "privacy": "https://studybookai.com/privacy",
        "account-deletion": "https://studybookai.com/account-deletion",
    }

    for directory, canonical_url in pages.items():
        content = (
            MOBILE_ROOT / "web" / directory / "index.html"
        ).read_text(encoding="utf-8")

        assert 'name="robots" content="noindex, nofollow"' in content
        assert f'href="{canonical_url}"' in content
        assert "Borrador" in content


def test_health_uses_render_commit_when_explicit_sha_is_absent(monkeypatch):
    monkeypatch.delenv("APP_BUILD_SHA", raising=False)
    monkeypatch.setenv("RENDER_GIT_COMMIT", "render-commit-sha")

    payload = health_check()

    assert payload["status"] == "ok"
    assert payload["service"] == "StudyBook AI API"
    assert payload["build_sha"] == "render-commit-sha"
