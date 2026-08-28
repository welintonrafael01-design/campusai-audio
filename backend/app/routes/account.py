from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.account_deletion_service import delete_user_account


router = APIRouter(prefix="/account", tags=["account"])


class DeleteAccountRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    confirmation: str = Field(min_length=1, max_length=64)


@router.delete("/me")
def delete_my_account(
    payload: DeleteAccountRequest,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    if payload.confirmation != "ELIMINAR MI CUENTA":
        raise HTTPException(
            status_code=400,
            detail="La confirmación de eliminación no coincide.",
        )

    result = delete_user_account(user_id=current_user.user_id)
    if not result.success:
        raise HTTPException(
            status_code=503,
            detail={
                "status": result.status,
                "message": (
                    "La eliminación no terminó. Tu cuenta permanece accesible "
                    "para que puedas reintentar sin perder control del proceso."
                ),
                "failed_step": result.failed_step,
            },
        )

    return {
        "deleted": True,
        "status": result.status,
        "external_subscription_action_required": (
            result.external_subscription_action_required
        ),
    }
