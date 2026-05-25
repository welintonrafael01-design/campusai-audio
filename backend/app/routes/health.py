from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "CampusAI Audio API",
        "message": "El backend está funcionando correctamente"
    }