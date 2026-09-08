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


class _ExecuteResponse:
    def __init__(self, data=None):
        self.data = data

    def execute(self):
        return self


class _RpcClient:
    def __init__(self, responses):
        self.responses = responses
        self.calls = []

    def rpc(self, name, payload):
        self.calls.append((name, payload))
        response = self.responses.get(name)
        if isinstance(response, Exception):
            raise response
        return _ExecuteResponse(response)


class _EndpointUsageOperation:
    def __init__(self, on_commit):
        self.on_commit = on_commit
        self.released = False

    def commit(self, metadata=None):
        self.on_commit(metadata or {})

    def release(self, *, reason):
        self.released = True


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

    monkeypatch.setattr(
        documents,
        "begin_usage_operation",
        lambda **kwargs: _EndpointUsageOperation(
            lambda metadata: used.update(
                quiz_generated=used["quiz_generated"] + 1,
            )
        ),
    )
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


def test_atomic_reservation_maps_denial_to_structured_contract(monkeypatch):
    client = _RpcClient(
        {
            "reserve_studybook_free_quota": [
                {
                    "reservation_id": None,
                    "reservation_status": "denied",
                    "acquired": False,
                    "idempotent": False,
                    "used_count": 10,
                    "quota_limit": 10,
                }
            ]
        }
    )
    monkeypatch.setattr(
        usage_limit_service,
        "get_supabase_admin_client",
        lambda: client,
    )

    with pytest.raises(HTTPException) as exc:
        usage_limit_service.begin_usage_operation(
            user_id="free-user",
            event_type="chat_message",
            plan="free",
            operation_id="atomic-operation-0001",
        )

    assert exc.value.status_code == 403
    assert exc.value.detail["reason"] == "quota_exceeded"
    assert exc.value.detail["capability"] == "chat"
    assert exc.value.detail["required_plan"] == "student_pro"


def test_atomic_reservation_fails_closed_when_database_rpc_is_unavailable(
    monkeypatch,
):
    client = _RpcClient(
        {"reserve_studybook_free_quota": RuntimeError("database unavailable")}
    )
    monkeypatch.setattr(
        usage_limit_service,
        "get_supabase_admin_client",
        lambda: client,
    )

    with pytest.raises(HTTPException) as exc:
        usage_limit_service.begin_usage_operation(
            user_id="free-user",
            event_type="summary_generated",
            plan="free",
            operation_id="atomic-operation-0004",
        )

    assert exc.value.status_code == 503
    assert exc.value.detail["code"] == "quota_service_unavailable"
    assert "database" not in exc.value.detail["message"].lower()


def test_atomic_operation_releases_on_failure(monkeypatch):
    client = _RpcClient(
        {
            "reserve_studybook_free_quota": [
                {
                    "reservation_id": "00000000-0000-4000-8000-000000000001",
                    "reservation_status": "reserved",
                    "acquired": True,
                    "idempotent": False,
                    "used_count": 1,
                    "quota_limit": 1,
                }
            ],
            "release_studybook_free_quota": True,
        }
    )
    monkeypatch.setattr(
        usage_limit_service,
        "get_supabase_admin_client",
        lambda: client,
    )

    with pytest.raises(RuntimeError):
        with usage_limit_service.begin_usage_operation(
            user_id="free-user",
            event_type="quiz_generated",
            plan="free",
            operation_id="atomic-operation-0002",
        ):
            raise RuntimeError("provider failed")

    assert [name for name, _ in client.calls] == [
        "reserve_studybook_free_quota",
        "release_studybook_free_quota",
    ]


def test_atomic_batch_commit_is_idempotency_aware(monkeypatch):
    reservation_rows = [
        {
            "reservation_id": "00000000-0000-4000-8000-000000000002",
            "reservation_status": "reserved",
            "acquired": True,
            "idempotent": False,
            "used_count": 1,
            "quota_limit": 3,
        }
    ]
    client = _RpcClient(
        {
            "reserve_studybook_free_quota": reservation_rows,
            "commit_studybook_free_quotas": 1,
        }
    )
    monkeypatch.setattr(
        usage_limit_service,
        "get_supabase_admin_client",
        lambda: client,
    )
    operation = usage_limit_service.begin_usage_operation(
        user_id="free-user",
        event_type="pdf_upload",
        plan="free",
        operation_id="atomic-operation-0003",
    )

    operation.commit({"document_id": "document-a"})
    operation.commit({"document_id": "document-a"})

    assert [name for name, _ in client.calls].count(
        "commit_studybook_free_quotas"
    ) == 1
    assert operation.status == "consumed"


def test_operation_id_is_scoped_and_rejects_unsafe_client_key():
    first = usage_limit_service.operation_id_for_request(
        idempotency_key="same-client-key",
        request_id=None,
        scope="/documents/chat/a",
    )
    second = usage_limit_service.operation_id_for_request(
        idempotency_key="same-client-key",
        request_id=None,
        scope="/documents/chat/b",
    )
    assert first != second
    assert "same-client-key" not in first

    with pytest.raises(HTTPException) as exc:
        usage_limit_service.operation_id_for_request(
            idempotency_key="unsafe key with spaces",
            request_id=None,
        )
    assert exc.value.status_code == 400


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
