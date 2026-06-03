from fastapi import APIRouter, Depends

from app.analytics.usage_summary import get_usage_summary
from app.security.admin_auth import require_admin_key


router = APIRouter(
    prefix="/analytics",
    tags=["Analytics"],
)


@router.get("/summary", dependencies=[Depends(require_admin_key)])
async def analytics_summary():
    return get_usage_summary()
