from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.middleware.security_middleware import SecurityMiddleware

from app.routes.documents import router as documents_router
from app.routes.cloud import router as cloud_router
from app.routes.health import router as health_router
from app.routes.pptx_export import router as pptx_export_router
from app.routes.export import router as export_router
from app.routes.analytics import router as analytics_router
from app.routes.billing import router as billing_router


APP_DIR = Path(__file__).resolve().parent
PROJECT_DIR = APP_DIR.parent

AUDIO_DIR = APP_DIR / "audio"
UPLOADS_DIR = PROJECT_DIR / "uploads"
CHROMA_DIR = PROJECT_DIR / "chroma_db"

AUDIO_DIR.mkdir(parents=True, exist_ok=True)
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
CHROMA_DIR.mkdir(parents=True, exist_ok=True)


app = FastAPI(
    title="StudyBook AI API",
    description=(
        "Backend de StudyBook AI para procesamiento de documentos, "
        "RAG, chat académico y audio inteligente."
    ),
    version="1.0.0",
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
app.include_router(analytics_router)
app.include_router(billing_router)


app.mount(
    "/audio",
    StaticFiles(directory=str(AUDIO_DIR)),
    name="audio",
)


@app.get("/")
def home():
    return {
        "app": "StudyBook AI",
        "message": "StudyBook AI API funcionando correctamente.",
        "status": "online",
        "version": "1.0.0",
        "audio_dir": str(AUDIO_DIR),
    }