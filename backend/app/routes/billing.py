import os

import stripe
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field


router = APIRouter(
    prefix="/billing",
    tags=["billing"],
)


class CheckoutSessionRequest(BaseModel):
    plan: str = Field(
        ...,
        description="Plan solicitado: pro o educator.",
    )


class CheckoutSessionResponse(BaseModel):
    checkout_url: str


def _get_price_id(plan: str) -> str:
    price_map = {
        "pro": os.getenv("STRIPE_PRICE_PRO", ""),
        "educator": os.getenv("STRIPE_PRICE_EDUCATOR", ""),
    }

    price_id = price_map.get(plan)

    if not price_id:
        raise HTTPException(
            status_code=400,
            detail=(
                "Plan no configurado para pagos. "
                "Configura STRIPE_PRICE_PRO o STRIPE_PRICE_EDUCATOR."
            ),
        )

    return price_id


@router.post(
    "/create-checkout-session",
    response_model=CheckoutSessionResponse,
)
def create_checkout_session(
    payload: CheckoutSessionRequest,
):
    plan = payload.plan.strip().lower()

    if plan not in {"pro", "educator"}:
        raise HTTPException(
            status_code=400,
            detail="Plan inválido. Usa pro o educator.",
        )

    stripe_secret_key = os.getenv("STRIPE_SECRET_KEY", "")

    if not stripe_secret_key:
        raise HTTPException(
            status_code=503,
            detail=(
                "Stripe no está configurado. "
                "Falta STRIPE_SECRET_KEY."
            ),
        )

    stripe.api_key = stripe_secret_key

    price_id = _get_price_id(plan)

    success_url_base = os.getenv(
        "APP_SUCCESS_URL",
        "http://localhost:5000/#/plans?checkout=success",
    )
    cancel_url_base = os.getenv(
        "APP_CANCEL_URL",
        "http://localhost:5000/#/plans?checkout=cancel",
    )

    separator_success = "&" if "?" in success_url_base else "?"
    separator_cancel = "&" if "?" in cancel_url_base else "?"

    success_url = f"{success_url_base}{separator_success}plan={plan}"
    cancel_url = f"{cancel_url_base}{separator_cancel}plan={plan}"

    try:
        session = stripe.checkout.Session.create(
            mode="subscription",
            line_items=[
                {
                    "price": price_id,
                    "quantity": 1,
                }
            ],
            success_url=success_url,
            cancel_url=cancel_url,
            metadata={
                "plan": plan,
                "source": "studybook_ai",
            },
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"No se pudo crear la sesión de pago: {exc}",
        ) from exc

    if not session.url:
        raise HTTPException(
            status_code=502,
            detail="Stripe no devolvió una URL de checkout.",
        )

    return CheckoutSessionResponse(
        checkout_url=session.url,
    )
