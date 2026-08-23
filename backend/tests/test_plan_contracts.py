import pytest
from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

from app.routes import export as export_routes
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services import usage_limit_service


@pytest.mark.parametrize(
    ("plan", "export_type", "allowed"),
    [
        ("free", "pdf", True),
        ("free", "docx", False),
        ("student", "docx", True),
        ("student", "pptx", False),
        ("accessibility", "docx", True),
        ("accessibility", "pptx", False),
        ("teacher", "pptx", True),
        ("ultra", "pptx", True),
    ],
)
def test_export_permissions_match_flutter_plan_contract(
    monkeypatch,
    plan,
    export_type,
    allowed,
):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: plan,
    )

    if allowed:
        assert (
            usage_limit_service.enforce_export_permission(
                user_id="user-1",
                export_type=export_type,
            )
            == plan
        )
        return

    with pytest.raises(HTTPException) as exc:
        usage_limit_service.enforce_export_permission(
            user_id="user-1",
            export_type=export_type,
        )
    assert exc.value.status_code == 403


@pytest.mark.parametrize(
    ("plan", "allowed"),
    [
        ("free", False),
        ("student", True),
        ("teacher", True),
        ("accessibility", True),
        ("ultra", True),
    ],
)
def test_voice_permissions_match_flutter_plan_contract(monkeypatch, plan, allowed):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: plan,
    )

    if allowed:
        assert (
            usage_limit_service.enforce_voice_permission(user_id="user-1")
            == plan
        )
        return

    with pytest.raises(HTTPException) as exc:
        usage_limit_service.enforce_voice_permission(user_id="user-1")
    assert exc.value.status_code == 403


@pytest.mark.parametrize(
    ("plan", "allowed"),
    [
        ("free", False),
        ("student", True),
        ("teacher", True),
        ("accessibility", True),
        ("ultra", True),
    ],
)
def test_question_bank_permissions_match_flutter_contract(
    monkeypatch,
    plan,
    allowed,
):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: plan,
    )

    if allowed:
        assert (
            usage_limit_service.enforce_question_bank_permission(
                user_id="user-1"
            )
            == plan
        )
        return

    with pytest.raises(HTTPException) as exc:
        usage_limit_service.enforce_question_bank_permission(user_id="user-1")
    assert exc.value.status_code == 403


def test_export_endpoint_preserves_plan_denial(monkeypatch):
    app = FastAPI()
    app.include_router(export_routes.router)
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id="free-1",
        email="free@studybook.ai",
        app_metadata={"role": "student"},
    )

    def deny_export(**kwargs):
        del kwargs
        raise HTTPException(
            status_code=403,
            detail="Este formato no está incluido en tu plan.",
        )

    monkeypatch.setattr(export_routes, "enforce_export_permission", deny_export)

    response = TestClient(app).post(
        "/export/pdf",
        json={"title": "Resumen", "content": "Contenido"},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Este formato no está incluido en tu plan."
