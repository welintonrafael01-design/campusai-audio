import pytest
from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

from app.routes import audiobook, documents, voice
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services import usage_limit_service


FREE_USER = AuthenticatedUser(
    user_id="free-user",
    email="free@studybook.ai",
    app_metadata={"role": "student"},
)


@pytest.mark.parametrize(
    ("event_type", "limit", "enforcer", "kwargs"),
    [
        ("pdf_upload", 3, usage_limit_service.enforce_pdf_upload_limit, {}),
        ("chat_message", 10, usage_limit_service.enforce_chat_limit, {}),
        ("summary_generated", 3, usage_limit_service.enforce_summary_limit, {}),
        (
            "flashcards_generated",
            1,
            usage_limit_service.enforce_flashcard_limit,
            {"requested_amount": 10},
        ),
        (
            "quiz_generated",
            1,
            usage_limit_service.enforce_quiz_limit,
            {"requested_amount": 10},
        ),
    ],
)
def test_free_monthly_quotas_allow_boundary_and_deny_next_use(
    monkeypatch,
    event_type,
    limit,
    enforcer,
    kwargs,
):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: "free",
    )
    used = {event_type: limit - 1}
    monkeypatch.setattr(
        usage_limit_service,
        "count_usage_this_month",
        lambda *, user_id, event_type: used.get(event_type, 0),
    )

    assert enforcer(user_id="free-user", **kwargs) == "free"

    used[event_type] = limit
    with pytest.raises(HTTPException) as exc:
        enforcer(user_id="free-user", **kwargs)

    assert exc.value.status_code == 403
    assert exc.value.detail == usage_limit_service.quota_denial_detail(
        event_type=event_type,
        limit=limit,
        used=limit,
    )


@pytest.mark.parametrize(
    "enforcer",
    [
        usage_limit_service.enforce_audiobook_permission,
        usage_limit_service.enforce_voice_permission,
        usage_limit_service.enforce_question_bank_permission,
    ],
)
def test_free_paid_generation_capabilities_are_denied(monkeypatch, enforcer):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: "free",
    )

    with pytest.raises(HTTPException) as exc:
        enforcer(user_id="free-user")

    assert exc.value.status_code == 403
    assert exc.value.detail["code"] == "capability_required"
    assert exc.value.detail["required_plan"] == "student_pro"


def test_free_exam_direct_api_bypass_is_denied(monkeypatch):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: "free",
    )
    monkeypatch.setattr(documents, "validate_document_owner", lambda **kwargs: {})
    app = FastAPI()
    app.include_router(documents.router)
    app.dependency_overrides[require_current_user] = lambda: FREE_USER

    response = TestClient(app).post(
        "/documents/exam/owned-document?generation_type=exam"
    )

    assert response.status_code == 403
    detail = response.json()["detail"]
    assert detail["capability"] == "exam_generation"
    assert detail["cta"]["label"] == "Ver Student Pro"


def test_free_question_bank_direct_api_bypass_is_denied(monkeypatch):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: "free",
    )
    monkeypatch.setattr(documents, "validate_document_owner", lambda **kwargs: {})
    app = FastAPI()
    app.include_router(documents.router)
    app.dependency_overrides[require_current_user] = lambda: FREE_USER

    response = TestClient(app).post(
        "/documents/question-bank/owned-document?number_of_questions=5"
    )

    assert response.status_code == 403
    detail = response.json()["detail"]
    assert detail["capability"] == "question_bank"
    assert detail["cta"]["label"] == "Ver Student Pro"


def test_free_quiz_api_allows_first_set_and_denies_next(monkeypatch):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: "free",
    )
    used = {"quiz_generated": 0}
    monkeypatch.setattr(
        usage_limit_service,
        "count_usage_this_month",
        lambda *, user_id, event_type: used.get(event_type, 0),
    )
    monkeypatch.setattr(documents, "validate_document_owner", lambda **kwargs: {})
    monkeypatch.setattr(documents, "build_document_context", lambda **kwargs: "context")
    monkeypatch.setattr(
        documents,
        "generate_exam_questions_from_context",
        lambda **kwargs: "{}",
    )
    monkeypatch.setattr(
        documents,
        "parse_ai_json_list",
        lambda *args, **kwargs: [{"question": "Q"}],
    )

    def register_event(**kwargs):
        used[kwargs["event_type"]] = used.get(kwargs["event_type"], 0) + 1
        return kwargs

    monkeypatch.setattr(documents, "register_usage_event", register_event)
    app = FastAPI()
    app.include_router(documents.router)
    app.dependency_overrides[require_current_user] = lambda: FREE_USER
    client = TestClient(app)

    first = client.post(
        "/documents/exam/owned-document?generation_type=quiz"
    )
    second = client.post(
        "/documents/exam/owned-document?generation_type=quiz"
    )

    assert first.status_code == 200
    assert first.json()["generation_type"] == "quiz"
    assert second.status_code == 403
    assert second.json()["detail"]["code"] == "monthly_quota_exceeded"


def test_free_direct_audiobook_and_voice_api_bypass_is_denied(monkeypatch):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: "free",
    )
    app = FastAPI()
    app.include_router(audiobook.router)
    app.include_router(voice.router)
    app.dependency_overrides[require_current_user] = lambda: FREE_USER
    client = TestClient(app)

    audiobook_response = client.post(
        "/audiobook/generate",
        json={"title": "Owned", "text": "Content"},
    )
    voice_response = client.post(
        "/voice/coach",
        json={"message": "Explain this"},
    )

    assert audiobook_response.status_code == 403
    assert voice_response.status_code == 403


def test_free_quota_is_scoped_by_authenticated_user(monkeypatch):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: "free",
    )
    monkeypatch.setattr(
        usage_limit_service,
        "count_usage_this_month",
        lambda *, user_id, event_type: 3 if user_id == "student-a" else 0,
    )

    with pytest.raises(HTTPException):
        usage_limit_service.enforce_pdf_upload_limit(user_id="student-a")

    assert (
        usage_limit_service.enforce_pdf_upload_limit(user_id="student-b") == "free"
    )


def test_student_and_teacher_keep_paid_learning_capabilities(monkeypatch):
    monkeypatch.setattr(
        usage_limit_service,
        "count_usage_today",
        lambda **kwargs: 0,
    )
    for plan in ("student", "teacher"):
        monkeypatch.setattr(
            usage_limit_service,
            "get_plan_for_user",
            lambda user_id, current_plan=plan: current_plan,
        )
        assert usage_limit_service.enforce_audiobook_permission(user_id="paid") == plan
        assert usage_limit_service.enforce_voice_permission(user_id="paid") == plan
        assert usage_limit_service.enforce_question_bank_permission(user_id="paid") == plan
        assert (
            usage_limit_service.enforce_exam_limit(
                user_id="paid",
                requested_amount=10,
            )
            == plan
        )


def test_free_usage_summary_exposes_monthly_contract(monkeypatch):
    monkeypatch.setattr(
        usage_limit_service,
        "get_plan_for_user",
        lambda user_id: "free",
    )
    used = {
        "pdf_upload": 2,
        "chat_message": 7,
        "summary_generated": 2,
        "flashcards_generated": 1,
        "quiz_generated": 0,
    }
    monkeypatch.setattr(
        usage_limit_service,
        "count_usage_this_month",
        lambda *, user_id, event_type: used.get(event_type, 0),
    )
    monkeypatch.setattr(
        usage_limit_service,
        "count_usage_total",
        lambda **kwargs: 0,
    )

    summary = usage_limit_service.get_usage_summary_for_user(user_id="free-user")

    assert summary["quota_period"] == "month"
    assert summary["usage"]["pdf_uploads"] == {
        "used": 2,
        "period": "month",
        "limit": 3,
    }
    assert summary["usage"]["chat_messages"]["limit"] == 10
    assert summary["usage"]["summaries_generated"]["limit"] == 3
    assert summary["usage"]["flashcards_generated"]["limit"] == 1
    assert summary["usage"]["quizzes_generated"]["limit"] == 1
    assert summary["usage"]["exams_generated"]["period"] == "not_included"
