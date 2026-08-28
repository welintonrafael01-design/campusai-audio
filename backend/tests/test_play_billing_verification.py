from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routes import billing
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.play_billing_service import (
    VerifiedPlayPurchase,
    get_play_purchase_verifier,
)


TOKEN = "play-purchase-token-with-safe-test-length"


class FakeVerifier:
    def __init__(self, *, user_id: str, active: bool = True):
        self.user_id = user_id
        self.active = active

    def verify(self, *, package_name, product_id, purchase_token):
        assert package_name == "com.studybookai.app"
        return VerifiedPlayPurchase(
            product_id=product_id,
            purchase_token=purchase_token,
            active=self.active,
            user_id=self.user_id,
            purchase_id="test-purchase",
        )


def _app(*, verifier, user_id: str = "student-a") -> FastAPI:
    app = FastAPI()
    app.include_router(billing.router)
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id=user_id,
        email=f"{user_id}@example.test",
    )
    app.dependency_overrides[get_play_purchase_verifier] = lambda: verifier
    return app


def test_verified_play_purchase_activates_only_authenticated_owner(monkeypatch):
    monkeypatch.setenv("GOOGLE_PLAY_STUDENT_PRODUCT_ID", "student-product")
    captured = {}

    def fake_upsert(**kwargs):
        captured.update(kwargs)
        return kwargs

    monkeypatch.setattr(billing, "upsert_user_subscription", fake_upsert)
    client = TestClient(_app(verifier=FakeVerifier(user_id="student-a")))

    response = client.post(
        "/billing/google-play/verify-purchase",
        json={
            "product_id": "student-product",
            "purchase_token": TOKEN,
        },
    )

    assert response.status_code == 200
    assert response.json()["verified"] is True
    assert captured["user_id"] == "student-a"
    assert captured["plan"] == "student"


def test_purchase_spoof_by_product_or_user_is_denied(monkeypatch):
    monkeypatch.setenv("GOOGLE_PLAY_STUDENT_PRODUCT_ID", "student-product")
    client = TestClient(_app(verifier=FakeVerifier(user_id="student-b")))

    wrong_owner = client.post(
        "/billing/google-play/verify-purchase",
        json={"product_id": "student-product", "purchase_token": TOKEN},
    )
    manipulated_product = client.post(
        "/billing/google-play/verify-purchase",
        json={"product_id": "teacher-product", "purchase_token": TOKEN},
    )
    injected_plan = client.post(
        "/billing/google-play/verify-purchase",
        json={
            "product_id": "student-product",
            "purchase_token": TOKEN,
            "plan": "teacher",
        },
    )

    assert wrong_owner.status_code == 403
    assert manipulated_product.status_code == 400
    assert injected_plan.status_code == 422
