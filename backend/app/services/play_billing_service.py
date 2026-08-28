from __future__ import annotations

from dataclasses import dataclass
import os
from typing import Protocol


PLAY_PACKAGE_NAME = "com.studybookai.app"


class PlayVerificationUnavailable(RuntimeError):
    pass


@dataclass(frozen=True)
class VerifiedPlayPurchase:
    product_id: str
    purchase_token: str
    active: bool
    user_id: str
    purchase_id: str | None = None


class PlayPurchaseVerifier(Protocol):
    def verify(
        self,
        *,
        package_name: str,
        product_id: str,
        purchase_token: str,
    ) -> VerifiedPlayPurchase: ...


class UnavailablePlayPurchaseVerifier:
    def verify(
        self,
        *,
        package_name: str,
        product_id: str,
        purchase_token: str,
    ) -> VerifiedPlayPurchase:
        del package_name, product_id, purchase_token
        raise PlayVerificationUnavailable(
            "La verificación de Google Play requiere configuración externa."
        )


def get_play_purchase_verifier() -> PlayPurchaseVerifier:
    return UnavailablePlayPurchaseVerifier()


def configured_play_products() -> dict[str, str]:
    return {
        product_id.strip(): plan
        for plan, product_id in {
            "student": os.getenv("GOOGLE_PLAY_STUDENT_PRODUCT_ID", ""),
            "teacher": os.getenv("GOOGLE_PLAY_TEACHER_PRODUCT_ID", ""),
        }.items()
        if product_id.strip()
    }
