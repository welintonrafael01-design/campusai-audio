import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routes import billing, educator
from app.security.entitlements import (
    ProductCapability,
    canonical_plan,
    commercial_plan_code,
    effective_stored_plan,
    has_capability,
    normalize_stored_plan,
    plan_capabilities,
    resolve_role,
)
from app.security.user_auth import AuthenticatedUser, require_current_user


@pytest.mark.parametrize(
    ("raw", "stored", "canonical"),
    [
        ("free", "free", "free"),
        ("student", "student", "student"),
        ("teacher", "teacher", "teacher"),
        ("institution", "institution", "institution"),
        ("pro", "student", "student"),
        ("educator", "teacher", "teacher"),
        ("accessibility", "accessibility", "student"),
        ("ultra", "ultra", "student"),
        ("arbitrary-plan", "free", "free"),
    ],
)
def test_plan_normalization_is_centralized(raw, stored, canonical):
    assert normalize_stored_plan(raw) == stored
    assert canonical_plan(raw) == canonical


def test_unknown_and_inactive_subscription_states_fail_closed():
    assert effective_stored_plan(plan="student", status="active") == "student"
    assert effective_stored_plan(plan="student", status="trialing") == "student"
    assert effective_stored_plan(plan="student", status="past_due") == "free"
    assert effective_stored_plan(plan="teacher", status="unknown") == "free"
    assert effective_stored_plan(plan="teacher", status="canceled") == "free"


def test_free_demonstrates_value_without_premium_cost_capabilities():
    capabilities = plan_capabilities("free", status="free")

    assert ProductCapability.LIBRARY in capabilities
    assert ProductCapability.DOCUMENT_UPLOAD in capabilities
    assert ProductCapability.CHAT in capabilities
    assert ProductCapability.SUMMARY in capabilities
    assert ProductCapability.FLASHCARDS in capabilities
    assert ProductCapability.QUIZ in capabilities
    assert ProductCapability.CLOUD_RESTORE in capabilities
    assert ProductCapability.EXAM_GENERATION not in capabilities
    assert ProductCapability.AUDIOBOOK not in capabilities
    assert ProductCapability.VOICE_TUTOR not in capabilities
    assert ProductCapability.QUESTION_BANK not in capabilities


def test_student_pro_has_learning_capabilities_but_not_teacher_tools():
    for capability in {
        ProductCapability.AUDIOBOOK,
        ProductCapability.VOICE_TUTOR,
        ProductCapability.FLASHCARDS,
        ProductCapability.QUIZ,
        ProductCapability.EXAM_GENERATION,
        ProductCapability.QUESTION_BANK,
        ProductCapability.CLOUD_RESTORE,
    }:
        assert has_capability(
            capability,
            role="student",
            plan="student",
            status="active",
        )

    assert not has_capability(
        ProductCapability.TEACHER_WORKSPACE,
        role="student",
        plan="teacher",
        status="active",
    )


def test_teacher_and_institution_require_teacher_role_for_teacher_core():
    for plan in {"teacher", "institution"}:
        assert has_capability(
            ProductCapability.TEACHER_WORKSPACE,
            role="teacher",
            plan=plan,
            status="active",
        )
        assert not has_capability(
            ProductCapability.TEACHER_WORKSPACE,
            role="student",
            plan=plan,
            status="active",
        )


def test_legacy_ultra_retains_student_premium_without_teacher_elevation():
    assert has_capability(
        ProductCapability.AUDIOBOOK,
        role="student",
        plan="ultra",
        status="active",
    )
    assert not has_capability(
        ProductCapability.TEACHER_WORKSPACE,
        role="teacher",
        plan="ultra",
        status="active",
    )


def test_admin_metadata_alone_is_not_admin_authority():
    assert resolve_role({"role": "admin"}) == "student"
    assert resolve_role({"role": "admin"}, admin_authorized=True) == "admin"


def test_commercial_plan_mapping_never_exposes_internal_aliases():
    assert commercial_plan_code("pro") == "student_pro"
    assert commercial_plan_code("accessibility") == "student_pro"
    assert commercial_plan_code("ultra") == "student_pro"
    assert commercial_plan_code("educator") == "teacher_pro"


def test_subscription_endpoint_returns_server_resolved_access_context(monkeypatch):
    user = AuthenticatedUser(
        user_id="teacher-1",
        email="teacher@studybook.ai",
        app_metadata={"role": "teacher"},
    )
    app = FastAPI()
    app.include_router(billing.router)
    app.dependency_overrides[require_current_user] = lambda: user
    monkeypatch.setattr(
        billing,
        "get_user_subscription",
        lambda **kwargs: {
            "user_id": kwargs["user_id"],
            "plan": "teacher",
            "canonical_plan": "teacher",
            "subscription_status": "active",
            "source": "supabase",
        },
    )
    monkeypatch.setattr(billing, "is_admin_user", lambda current_user: False)

    response = TestClient(app).get("/billing/subscription/me")

    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "teacher"
    assert data["commercial_plan"] == "teacher_pro"
    assert "teacher_workspace" in data["capabilities"]
    assert "admin_console" not in data["capabilities"]


def test_teacher_payload_spoof_does_not_bypass_server_authority(monkeypatch):
    app = FastAPI()
    app.include_router(educator.router)
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id="student-1",
        email="student@studybook.ai",
        app_metadata={"role": "student"},
    )
    monkeypatch.setattr(
        "app.security.teacher_auth.get_user_subscription",
        lambda **kwargs: {
            "plan": "student",
            "subscription_status": "active",
        },
    )

    response = TestClient(app).post(
        "/educator/sync",
        json={
            "plan": "teacher",
            "role": "teacher",
            "capabilities": ["teacher_workspace"],
        },
    )

    assert response.status_code == 403
