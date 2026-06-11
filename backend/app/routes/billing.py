import os

import stripe
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from app.security.user_auth import AuthenticatedUser, require_current_user

from app.services.usage_limit_service import get_usage_summary_for_user
from app.services.subscription_service import upsert_user_subscription, downgrade_user_to_free, get_user_subscription


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


class CustomerPortalResponse(BaseModel):
    portal_url: str



def _resolve_plan_from_stripe_object(data_object: dict, fallback: str = "free") -> str:
    metadata = data_object.get("metadata", {}) or {}

    plan = str(metadata.get("plan") or "").strip().lower()
    if plan in {"pro", "educator"}:
        return plan

    price_pro = os.getenv("STRIPE_PRICE_PRO", "")
    price_educator = os.getenv("STRIPE_PRICE_EDUCATOR", "")

    items = data_object.get("items", {}).get("data", []) or []

    for item in items:
        price = item.get("price", {}) or {}
        price_id = price.get("id") or item.get("plan", {}).get("id")

        if price_id == price_educator:
            return "educator"

        if price_id == price_pro:
            return "pro"

    return fallback.strip().lower() or "free"


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
    current_user: AuthenticatedUser = Depends(require_current_user),
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
            customer_email=current_user.email,
            metadata={
                "plan": plan,
                "user_id": current_user.user_id,
                "email": current_user.email or "",
                "source": "studybook_ai",
            },
            subscription_data={
                "metadata": {
                    "plan": plan,
                    "user_id": current_user.user_id,
                    "email": current_user.email or "",
                    "source": "studybook_ai",
                },
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


@router.post(
    "/create-customer-portal-session",
    response_model=CustomerPortalResponse,
)
def create_customer_portal_session(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    stripe_secret_key = os.getenv("STRIPE_SECRET_KEY", "")

    if not stripe_secret_key:
        raise HTTPException(
            status_code=503,
            detail="Stripe no está configurado. Falta STRIPE_SECRET_KEY.",
        )

    stripe.api_key = stripe_secret_key

    subscription = get_user_subscription(
        user_id=current_user.user_id,
    )

    stripe_customer_id = subscription.get("stripe_customer_id")

    if not stripe_customer_id:
        raise HTTPException(
            status_code=404,
            detail=(
                "No se encontró un cliente de Stripe asociado a esta cuenta. "
                "Primero debes tener una suscripción activa."
            ),
        )

    return_url = os.getenv(
        "STRIPE_CUSTOMER_PORTAL_RETURN_URL",
        os.getenv(
            "APP_SUCCESS_URL",
            "http://localhost:54713/#/settings",
        ),
    )

    try:
        session = stripe.billing_portal.Session.create(
            customer=stripe_customer_id,
            return_url=return_url,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"No se pudo crear el portal de cliente: {exc}",
        ) from exc

    if not session.url:
        raise HTTPException(
            status_code=502,
            detail="Stripe no devolvió una URL del portal.",
        )

    return CustomerPortalResponse(
        portal_url=session.url,
    )


@router.get("/subscription/me")
def get_my_subscription_endpoint(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return get_user_subscription(
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.get("/usage/me")
def get_my_usage_endpoint(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    try:
        return get_usage_summary_for_user(
            user_id=current_user.user_id,
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=str(error),
        )


@router.post("/webhook")
async def stripe_webhook(request: Request):
    payload = await request.body()
    signature = request.headers.get("stripe-signature", "")
    webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET", "")

    if not webhook_secret:
        raise HTTPException(
            status_code=503,
            detail="STRIPE_WEBHOOK_SECRET no está configurado.",
        )

    try:
        event = stripe.Webhook.construct_event(
            payload=payload,
            sig_header=signature,
            secret=webhook_secret,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail="Payload inválido.",
        ) from exc
    except stripe.SignatureVerificationError as exc:
        raise HTTPException(
            status_code=400,
            detail="Firma de webhook inválida.",
        ) from exc

    event_type = event.get("type")
    data_object = event.get("data", {}).get("object", {})

    if event_type == "checkout.session.completed":
        metadata = data_object.get("metadata", {}) or {}

        user_id = metadata.get("user_id", "")
        email = metadata.get("email") or data_object.get("customer_email")
        plan = _resolve_plan_from_stripe_object(
            data_object,
            metadata.get("plan", "free"),
        )

        if not user_id:
            return {
                "received": True,
                "type": event_type,
                "ignored": "missing_user_id",
            }

        upsert_user_subscription(
            user_id=user_id,
            email=email,
            plan=plan,
            stripe_customer_id=data_object.get("customer"),
            stripe_subscription_id=data_object.get("subscription"),
            subscription_status="active",
        )

    elif event_type in {
        "customer.subscription.created",
        "customer.subscription.updated",
        "customer.subscription.deleted",
    }:
        metadata = data_object.get("metadata", {}) or {}

        user_id = metadata.get("user_id", "")
        email = metadata.get("email")
        plan = _resolve_plan_from_stripe_object(
            data_object,
            metadata.get("plan", "free"),
        )

        if not user_id:
            return {
                "received": True,
                "type": event_type,
                "ignored": "missing_user_id",
            }

        status = data_object.get("status")

        if event_type == "customer.subscription.deleted" or status in {
            "canceled",
            "unpaid",
            "incomplete_expired",
        }:
            downgrade_user_to_free(
                user_id=user_id,
                email=email,
                stripe_customer_id=data_object.get("customer"),
                stripe_subscription_id=data_object.get("id"),
                subscription_status=status or "canceled",
            )
        else:
            upsert_user_subscription(
                user_id=user_id,
                email=email,
                plan=plan,
                stripe_customer_id=data_object.get("customer"),
                stripe_subscription_id=data_object.get("id"),
                subscription_status=status,
            )

    return {
        "received": True,
        "type": event_type,
    }

