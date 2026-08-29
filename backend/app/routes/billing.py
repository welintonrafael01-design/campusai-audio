import os

import stripe
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, ConfigDict, Field

from app.security.admin_auth import is_admin_user
from app.security.entitlements import (
    commercial_plan_code,
    normalize_stored_plan,
    resolve_capabilities,
    resolve_role,
)
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.public_urls import PublicUrlConfigurationError, resolve_web_redirect

from app.services.usage_limit_service import get_usage_summary_for_user
from app.services.subscription_service import (
    auth_user_exists,
    downgrade_user_to_free,
    get_user_subscription,
    upsert_user_subscription,
)
from app.services.play_billing_service import (
    PLAY_PACKAGE_NAME,
    PlayPurchaseVerifier,
    PlayVerificationUnavailable,
    configured_play_products,
    get_play_purchase_verifier,
)


router = APIRouter(
    prefix="/billing",
    tags=["billing"],
)


PLAN_MONTHLY_PRICES = {
    "free": 0.0,
    "student": 4.99,
    "accessibility": 3.99,
    "teacher": 9.99,
    "ultra": 24.99,
    # Institution is provisioned contractually; no public Stripe price exists.
    "institution": None,
}

PLAN_ESTIMATED_AI_COSTS = {
    "free": 0.10,
    "student": 1.40,
    "accessibility": 1.25,
    "teacher": 3.25,
    "ultra": 7.50,
    "institution": 0.0,
}


class CheckoutSessionRequest(BaseModel):
    plan: str = Field(
        ...,
        description="Plan solicitado: student, teacher, accessibility o ultra.",
    )


class CheckoutSessionResponse(BaseModel):
    checkout_url: str


class PlayPurchaseVerificationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    product_id: str = Field(min_length=1, max_length=255)
    purchase_token: str = Field(min_length=16, max_length=20000)
    transaction_id: str | None = Field(default=None, max_length=512)


class CustomerPortalResponse(BaseModel):
    portal_url: str


class FinancialDashboardResponse(BaseModel):
    currency: str
    mrr: float
    arr: float
    paid_users: int
    free_users: int
    total_users: int
    conversion_rate: float
    estimated_ai_cost: float
    estimated_gross_margin: float
    estimated_gross_margin_rate: float
    plans: dict



def _require_billing_admin(current_user: AuthenticatedUser) -> None:
    admin_emails = {
        email.strip().lower()
        for email in os.getenv("ADMIN_EMAILS", "").split(",")
        if email.strip()
    }

    user_email = (current_user.email or "").strip().lower()

    if admin_emails and user_email in admin_emails:
        return

    raise HTTPException(
        status_code=403,
        detail="No tienes permiso para ver el dashboard financiero.",
    )


def _normalize_plan(plan: str | None) -> str:
    return normalize_stored_plan(plan)


def _stripe_price_map() -> dict[str, str]:
    return {
        "student": (
            os.getenv("STRIPE_STUDENT_PRICE_ID", "")
            or os.getenv("STRIPE_PRICE_STUDENT", "")
            or os.getenv("STRIPE_PRICE_PRO", "")
        ),
        "teacher": (
            os.getenv("STRIPE_TEACHER_PRICE_ID", "")
            or os.getenv("STRIPE_PRICE_TEACHER", "")
            or os.getenv("STRIPE_PRICE_EDUCATOR", "")
        ),
        "accessibility": (
            os.getenv("STRIPE_ACCESSIBILITY_PRICE_ID", "")
            or os.getenv("STRIPE_PRICE_ACCESSIBILITY", "")
        ),
        "ultra": (
            os.getenv("STRIPE_ULTRA_PRICE_ID", "")
            or os.getenv("STRIPE_PRICE_ULTRA", "")
        ),
    }


def _metadata_from_checkout_session(subscription_id: str | None) -> dict:
    if not subscription_id:
        return {}

    try:
        sessions = stripe.checkout.Session.list(
            subscription=subscription_id,
            limit=1,
        )
    except Exception:
        return {}

    if not sessions.data:
        return {}

    session = sessions.data[0]
    metadata = dict(session.metadata or {})

    if session.customer_email and not metadata.get("email"):
        metadata["email"] = session.customer_email

    return metadata


def _resolve_plan_from_stripe_object(data_object: dict, fallback: str = "free") -> str:
    metadata = data_object.get("metadata", {}) or {}

    plan = _normalize_plan(str(metadata.get("plan") or ""))
    if plan != "free":
        return plan

    price_map = _stripe_price_map()
    reverse_price_map = {
        price_id: plan_code
        for plan_code, price_id in price_map.items()
        if price_id
    }

    items = data_object.get("items", {}).get("data", []) or []

    for item in items:
        price = item.get("price", {}) or {}
        price_id = price.get("id") or item.get("plan", {}).get("id")

        if price_id in reverse_price_map:
            return reverse_price_map[price_id]

    return _normalize_plan(fallback)


def _get_price_id(plan: str) -> str:
    price_map = _stripe_price_map()
    price_id = price_map.get(plan)

    if not price_id:
        raise HTTPException(
            status_code=400,
            detail=(
                f"El plan {plan} no tiene Price ID configurado en Stripe. "
                "Configura STRIPE_STUDENT_PRICE_ID, STRIPE_TEACHER_PRICE_ID, "
                "STRIPE_ACCESSIBILITY_PRICE_ID o STRIPE_ULTRA_PRICE_ID."
            ),
        )

    return price_id


def _billing_redirect_url(
    variable_name: str,
    *,
    app_path: str,
    development_default: str,
) -> str:
    try:
        return resolve_web_redirect(
            variable_name,
            app_path=app_path,
            development_default=development_default,
        )
    except PublicUrlConfigurationError as error:
        raise HTTPException(
            status_code=503,
            detail="La configuracion publica de billing esta incompleta.",
        ) from error


@router.post(
    "/create-checkout-session",
    response_model=CheckoutSessionResponse,
)
def create_checkout_session(
    payload: CheckoutSessionRequest,
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    plan = _normalize_plan(payload.plan)

    if plan not in {"student", "teacher", "accessibility", "ultra"}:
        raise HTTPException(
            status_code=400,
            detail="Plan inválido. Usa student, teacher, accessibility o ultra.",
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

    success_url_base = _billing_redirect_url(
        "APP_SUCCESS_URL",
        app_path="/#/plans?checkout=success",
        development_default="http://localhost:5000/#/plans?checkout=success",
    )
    cancel_url_base = _billing_redirect_url(
        "APP_CANCEL_URL",
        app_path="/#/plans?checkout=cancel",
        development_default="http://localhost:5000/#/plans?checkout=cancel",
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
            detail="No se pudo iniciar el pago. Intenta nuevamente.",
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

    return_url = _billing_redirect_url(
        "STRIPE_CUSTOMER_PORTAL_RETURN_URL",
        app_path="/#/settings",
        development_default="http://localhost:54713/#/settings",
    )

    try:
        session = stripe.billing_portal.Session.create(
            customer=stripe_customer_id,
            return_url=return_url,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail="No se pudo abrir el portal de suscripción.",
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
        subscription = get_user_subscription(
            user_id=current_user.user_id,
        )
        role = resolve_role(
            current_user.app_metadata,
            admin_authorized=is_admin_user(current_user),
        )
        capabilities = resolve_capabilities(
            role=role,
            plan=subscription.get("plan"),
            status=subscription.get("subscription_status"),
        )
        return {
            **subscription,
            "role": role,
            "commercial_plan": commercial_plan_code(
                subscription.get("plan"),
            ),
            "capabilities": sorted(
                capability.value for capability in capabilities
            ),
        }
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail="No se pudo consultar la suscripción.",
        ) from error


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
            detail="No se pudo consultar el uso del plan.",
        ) from error


@router.post("/google-play/verify-purchase")
def verify_google_play_purchase(
    payload: PlayPurchaseVerificationRequest,
    current_user: AuthenticatedUser = Depends(require_current_user),
    verifier: PlayPurchaseVerifier = Depends(get_play_purchase_verifier),
):
    products = configured_play_products()
    plan = products.get(payload.product_id)
    if not plan:
        raise HTTPException(
            status_code=400,
            detail="El producto de Google Play no está configurado.",
        )

    try:
        purchase = verifier.verify(
            package_name=PLAY_PACKAGE_NAME,
            product_id=payload.product_id,
            purchase_token=payload.purchase_token,
        )
    except PlayVerificationUnavailable as error:
        raise HTTPException(
            status_code=503,
            detail="La verificación de Google Play aún no está disponible.",
        ) from error
    except Exception as error:
        raise HTTPException(
            status_code=502,
            detail="No se pudo verificar la compra con Google Play.",
        ) from error

    if (
        not purchase.active
        or purchase.product_id != payload.product_id
        or purchase.purchase_token != payload.purchase_token
        or purchase.user_id != current_user.user_id
    ):
        raise HTTPException(
            status_code=403,
            detail="La compra no pertenece a esta cuenta o no está activa.",
        )

    subscription = upsert_user_subscription(
        user_id=current_user.user_id,
        email=current_user.email,
        plan=plan,
        subscription_status="active",
    )
    return {
        "verified": True,
        "plan": subscription.get("plan", plan),
        "subscription_status": subscription.get(
            "subscription_status",
            "active",
        ),
    }


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

        if not auth_user_exists(user_id=user_id):
            return {
                "received": True,
                "type": event_type,
                "ignored": "unknown_or_deleted_user",
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
        "invoice.paid",
        "invoice.payment_succeeded",
        "invoice_payment.paid",
    }:
        metadata = data_object.get("metadata", {}) or {}
        subscription_id = data_object.get("id")

        if event_type in {"invoice.paid", "invoice.payment_succeeded", "invoice_payment.paid"}:
            subscription_id = data_object.get("subscription")

        checkout_metadata = _metadata_from_checkout_session(subscription_id)

        merged_metadata = {
            **checkout_metadata,
            **metadata,
        }

        user_id = merged_metadata.get("user_id", "")
        email = merged_metadata.get("email")
        plan = _resolve_plan_from_stripe_object(
            data_object,
            merged_metadata.get("plan", "free"),
        )

        if not user_id:
            return {
                "received": True,
                "type": event_type,
                "ignored": "missing_user_id",
            }

        if not auth_user_exists(user_id=user_id):
            return {
                "received": True,
                "type": event_type,
                "ignored": "unknown_or_deleted_user",
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
                stripe_subscription_id=subscription_id,
                subscription_status=status or "canceled",
            )
        else:
            upsert_user_subscription(
                user_id=user_id,
                email=email,
                plan=plan,
                stripe_customer_id=data_object.get("customer"),
                stripe_subscription_id=subscription_id,
                subscription_status=status,
            )

    return {
        "received": True,
        "type": event_type,
    }


@router.get(
    "/admin/financial-dashboard",
    response_model=FinancialDashboardResponse,
)
def get_financial_dashboard(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    _require_billing_admin(current_user)

    from app.database.supabase_client import get_supabase_admin_client

    client = get_supabase_admin_client()

    try:
        response = (
            client
            .table("user_subscriptions")
            .select("plan,subscription_status")
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="No se pudo cargar el resumen financiero.",
        ) from exc

    rows = response.data or []

    plans = {
        plan: {
            "users": 0,
            "active_users": 0,
            "monthly_price": price,
            "mrr": 0.0,
            "estimated_ai_cost": 0.0,
            "estimated_gross_margin": 0.0,
        }
        for plan, price in PLAN_MONTHLY_PRICES.items()
    }

    for row in rows:
        raw_plan = row.get("plan") or "free"
        plan = _normalize_plan(raw_plan)
        status = row.get("subscription_status") or "unknown"

        if status != "active":
            plan = "free"

        if plan not in plans:
            plan = "free"

        plans[plan]["users"] += 1

        if status == "active" and plan != "free":
            plans[plan]["active_users"] += 1

    for plan, data in plans.items():
        active_users = data["active_users"] if plan != "free" else 0
        users_for_cost = data["users"]

        monthly_price = PLAN_MONTHLY_PRICES[plan]
        mrr = round(active_users * monthly_price, 2) if monthly_price else 0.0
        estimated_cost = round(
            users_for_cost * PLAN_ESTIMATED_AI_COSTS.get(plan, 0.0),
            2,
        )
        gross_margin = round(mrr - estimated_cost, 2)

        data["mrr"] = mrr
        data["estimated_ai_cost"] = estimated_cost
        data["estimated_gross_margin"] = gross_margin

    mrr = round(sum(data["mrr"] for data in plans.values()), 2)
    arr = round(mrr * 12, 2)
    paid_users = sum(data["active_users"] for plan, data in plans.items() if plan != "free")
    total_users = sum(data["users"] for data in plans.values())
    free_users = plans["free"]["users"]
    estimated_ai_cost = round(
        sum(data["estimated_ai_cost"] for data in plans.values()),
        2,
    )
    estimated_gross_margin = round(mrr - estimated_ai_cost, 2)
    estimated_gross_margin_rate = (
        round((estimated_gross_margin / mrr) * 100, 2)
        if mrr > 0
        else 0.0
    )
    conversion_rate = (
        round((paid_users / total_users) * 100, 2)
        if total_users > 0
        else 0.0
    )

    return FinancialDashboardResponse(
        currency="USD",
        mrr=mrr,
        arr=arr,
        paid_users=paid_users,
        free_users=free_users,
        total_users=total_users,
        conversion_rate=conversion_rate,
        estimated_ai_cost=estimated_ai_cost,
        estimated_gross_margin=estimated_gross_margin,
        estimated_gross_margin_rate=estimated_gross_margin_rate,
        plans=plans,
    )
