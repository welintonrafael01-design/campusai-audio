from pathlib import Path
import os

from dotenv import load_dotenv

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.middleware.security_middleware import SecurityMiddleware
from app.public_urls import (
    PublicUrlConfigurationError,
    configured_app_web_origin,
    is_production_environment,
    validate_public_https_url,
)
from app.persistence_config import validate_production_persistence_configuration

load_dotenv()

from app.routes.documents import router as documents_router
from app.routes.cloud import router as cloud_router
from app.routes.health import router as health_router
from app.routes.pptx_export import router as pptx_export_router
from app.routes.export import router as export_router
from app.routes.certificates import router as certificates_router
from app.routes.analytics import router as analytics_router
from app.routes.billing import router as billing_router
from app.routes.educator import router as educator_router
from app.routes.audiobook import router as audiobook_router
from app.routes.voice import router as voice_router
from app.routes.audio import router as audio_router
from app.routes.account import router as account_router


APP_DIR = Path(__file__).resolve().parent
PROJECT_DIR = APP_DIR.parent

UPLOADS_DIR = PROJECT_DIR / "uploads"
CHROMA_DIR = PROJECT_DIR / "chroma_db"

if not is_production_environment():
    UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    CHROMA_DIR.mkdir(parents=True, exist_ok=True)

validate_production_persistence_configuration()


def get_cors_origins() -> list[str]:
    raw_origins = os.getenv("BACKEND_CORS_ORIGINS", "").strip()

    if not raw_origins:
        if is_production_environment():
            return [configured_app_web_origin(required=True)]
        raw_origins = (
            "http://localhost:54713,http://localhost:3000,"
            "http://127.0.0.1:54713"
        )

    origins = [
        origin.strip()
        for origin in raw_origins.split(",")
        if origin.strip()
    ]

    if is_production_environment():
        origins = [
            validate_public_https_url(
                origin,
                variable_name="BACKEND_CORS_ORIGINS",
                origin_only=True,
            )
            for origin in origins
        ]

    return origins


def get_cors_origin_regex() -> str | None:
    """Allow ephemeral Flutter Web ports only on the local loopback host."""
    configured = os.getenv("BACKEND_CORS_ORIGIN_REGEX")
    if is_production_environment():
        if configured and configured.strip():
            raise PublicUrlConfigurationError(
                "BACKEND_CORS_ORIGIN_REGEX no se permite en produccion."
            )
        return None

    value = (
        configured
        if configured is not None
        else r"^http://(?:localhost|127\.0\.0\.1)(?::\d+)?$"
    ).strip()
    return value or None


def api_docs_enabled() -> bool:
    explicit = os.getenv("ENABLE_API_DOCS", "").strip().lower()
    if explicit:
        return explicit in {"1", "true", "yes", "on"}

    environment = os.getenv("APP_ENV", "development").strip().lower()
    return environment not in {"production", "prod"}


docs_enabled = api_docs_enabled()

app = FastAPI(
    title="StudyBook AI API",
    description=(
        "Backend de StudyBook AI para procesamiento de documentos, "
        "RAG, chat académico y audio inteligente."
    ),
    version="1.0.0",
    docs_url="/docs" if docs_enabled else None,
    redoc_url="/redoc" if docs_enabled else None,
    openapi_url="/openapi.json" if docs_enabled else None,
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=get_cors_origins(),
    allow_origin_regex=get_cors_origin_regex(),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=[
        "Authorization",
        "Content-Type",
        "Accept",
        "Origin",
        "X-Admin-Key",
        "X-Request-ID",
        "Idempotency-Key",
    ],
    expose_headers=["Content-Disposition", "X-Request-ID", "X-Process-Time"],
)

app.add_middleware(
    SecurityMiddleware,
    max_requests=120,
    window_seconds=60,
)


app.include_router(health_router)
app.include_router(pptx_export_router)
app.include_router(documents_router)
app.include_router(cloud_router)
app.include_router(export_router)
app.include_router(certificates_router)
app.include_router(analytics_router)
app.include_router(billing_router)
app.include_router(educator_router)
app.include_router(audiobook_router)
app.include_router(voice_router)
app.include_router(audio_router)
app.include_router(account_router)


@app.get("/")
def home():
    return {
        "app": "StudyBook AI",
        "message": "StudyBook AI API funcionando correctamente.",
        "status": "online",
        "version": "1.0.0",
    }
