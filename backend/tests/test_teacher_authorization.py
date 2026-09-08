import pytest
from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

from app.routes import certificates, documents, educator, export
from app.security import teacher_auth
from app.security import user_auth
from app.services import certificate_service
from app.security.teacher_auth import has_teacher_access, require_teacher_access
from app.security.user_auth import AuthenticatedUser, require_current_user


def _user(
    *,
    role: str,
    user_id: str = "user_1",
    email: str = "user@studybook.ai",
) -> AuthenticatedUser:
    return AuthenticatedUser(
        user_id=user_id,
        email=email,
        app_metadata={"role": role},
    )


def _subscription(
    *,
    plan: str,
    status: str = "active",
) -> dict:
    return {
        "plan": plan,
        "subscription_status": status,
    }


def _authorized_client(
    monkeypatch,
    *,
    user: AuthenticatedUser,
    subscription: dict,
) -> TestClient:
    app = FastAPI()
    app.include_router(educator.router)
    app.include_router(documents.router)
    app.include_router(certificates.router)
    app.include_router(export.router)
    app.dependency_overrides[require_current_user] = lambda: user
    monkeypatch.setattr(
        teacher_auth,
        "get_user_subscription",
        lambda *, user_id: subscription,
    )
    return TestClient(app)


@pytest.fixture(autouse=True)
def _clear_admin_policy(monkeypatch):
    monkeypatch.setenv("ADMIN_EMAILS", "")


def test_teacher_access_requires_server_role_and_active_teacher_plan():
    assert has_teacher_access(
        _user(role="teacher"),
        subscription=_subscription(plan="teacher"),
    )
    assert has_teacher_access(
        _user(role="educator"),
        subscription=_subscription(plan="educator"),
    )
    assert not has_teacher_access(
        _user(role="teacher"),
        subscription=_subscription(plan="ultra"),
    )
    assert has_teacher_access(
        _user(role="teacher"),
        subscription=_subscription(plan="institution"),
    )

    assert not has_teacher_access(
        _user(role="student"),
        subscription=_subscription(plan="teacher"),
    )
    assert not has_teacher_access(
        _user(role="teacher"),
        subscription=_subscription(plan="student"),
    )
    assert not has_teacher_access(
        _user(role="teacher"),
        subscription=_subscription(plan="teacher", status="canceled"),
    )


def test_teacher_dependency_returns_consistent_403(monkeypatch):
    monkeypatch.setattr(
        teacher_auth,
        "get_user_subscription",
        lambda *, user_id: _subscription(plan="student"),
    )

    with pytest.raises(HTTPException) as exc:
        require_teacher_access(_user(role="student"))

    assert exc.value.status_code == 403
    assert exc.value.detail["required_plan"] == "teacher_pro"
    assert exc.value.detail["cta"]["label"] == "Ver Teacher Pro"


def test_authenticated_identity_keeps_only_server_app_metadata(monkeypatch):
    class FakeUser:
        id = "user_1"
        email = "student@studybook.ai"
        app_metadata = {"role": "student"}
        user_metadata = {"role": "teacher"}

    class FakeAuth:
        @staticmethod
        def get_user(token):
            return type("Response", (), {"user": FakeUser()})()

    fake_client = type("Client", (), {"auth": FakeAuth()})()
    monkeypatch.setattr(user_auth, "get_supabase_client", lambda: fake_client)

    identity = user_auth.require_current_user("Bearer safe-test-token")

    assert identity.app_metadata == {"role": "student"}
    assert not hasattr(identity, "user_metadata")


def test_configured_admin_is_allowed_by_existing_policy(monkeypatch):
    monkeypatch.setenv("ADMIN_EMAILS", "admin@studybook.ai")

    assert has_teacher_access(
        _user(role="admin", email="admin@studybook.ai"),
        subscription=_subscription(plan="free", status="free"),
    )


def test_educator_endpoints_reject_student(monkeypatch):
    client = _authorized_client(
        monkeypatch,
        user=_user(role="student"),
        subscription=_subscription(plan="student"),
    )

    assert client.get("/educator/snapshot").status_code == 403
    assert client.post("/educator/sync", json={}).status_code == 403


def test_educator_endpoint_requires_authentication():
    app = FastAPI()
    app.include_router(educator.router)
    client = TestClient(app)

    assert client.get("/educator/snapshot").status_code == 401


def test_teacher_can_access_educator_snapshot(monkeypatch):
    monkeypatch.setattr(educator, "_candidate_user_ids", lambda user: [user.user_id])
    monkeypatch.setattr(
        educator,
        "_select_for_user_candidates",
        lambda **kwargs: [],
    )
    client = _authorized_client(
        monkeypatch,
        user=_user(role="teacher"),
        subscription=_subscription(plan="teacher"),
    )

    response = client.get("/educator/snapshot")

    assert response.status_code == 200
    assert response.json()["source"] == "supabase"


def test_educator_row_ids_are_scoped_per_user_and_namespace():
    first = educator._scoped_row_id(
        user_id="teacher-a",
        namespace="course",
        record_id="mat101",
    )
    other_user = educator._scoped_row_id(
        user_id="teacher-b",
        namespace="course",
        record_id="mat101",
    )
    other_namespace = educator._scoped_row_id(
        user_id="teacher-a",
        namespace="student",
        record_id="mat101",
    )

    assert first != other_user
    assert first != other_namespace
    assert len(first) == 32


def test_educator_snapshot_never_expands_identity_by_email(monkeypatch):
    monkeypatch.setattr(
        educator,
        "get_supabase_admin_client",
        lambda: pytest.fail("Identity lookup must not query subscriptions by email."),
    )

    candidates = educator._candidate_user_ids(
        AuthenticatedUser(
            user_id="current-user-id",
            email="reused@example.test",
            app_metadata={"role": "teacher"},
        )
    )

    assert candidates == ["current-user-id"]


def test_educator_snapshot_identifies_only_stale_cloud_rows():
    stale = educator._stale_row_ids(
        existing_rows=[
            {"id": "keep"},
            {"id": "remove"},
            {"id": ""},
        ],
        incoming_rows=[{"id": "keep"}, {"id": "new"}],
    )

    assert stale == ["remove"]


def test_student_cannot_call_teacher_document_endpoint(monkeypatch):
    client = _authorized_client(
        monkeypatch,
        user=_user(role="student"),
        subscription=_subscription(plan="student"),
    )

    response = client.post("/documents/teaching-plan/doc_1")

    assert response.status_code == 403


def test_student_cannot_list_or_write_academic_recognitions(monkeypatch):
    client = _authorized_client(
        monkeypatch,
        user=_user(role="student"),
        subscription=_subscription(plan="student"),
    )

    listing = client.get("/certificates/list")
    create = client.post("/certificates/auto-recognitions", json={"recognitions": []})

    assert listing.status_code == 403
    assert create.status_code == 403


def test_student_cannot_issue_public_certificate_or_badge(monkeypatch):
    client = _authorized_client(
        monkeypatch,
        user=_user(role="student"),
        subscription=_subscription(plan="student"),
    )

    certificate = client.post(
        "/export/certificate-pdf",
        json={
            "student_name": "Student",
            "course_name": "Course",
            "average": "100",
        },
    )
    badge = client.post(
        "/export/academic-badge-pdf",
        json={
            "student_name": "Student",
            "course_name": "Course",
        },
    )

    assert certificate.status_code == 403
    assert badge.status_code == 403


def test_certificate_store_is_scoped_to_issuing_teacher(monkeypatch, tmp_path):
    store = tmp_path / "certificates.json"
    monkeypatch.setattr(certificate_service, "DATA_DIR", tmp_path)
    monkeypatch.setattr(certificate_service, "CERTIFICATES_FILE", store)

    certificate_service.save_certificate(
        {"certificate_id": "CERT-A", "student_name": "Student A"},
        user_id="teacher-a",
    )
    certificate_service.save_certificate(
        {"certificate_id": "CERT-B", "student_name": "Student B"},
        user_id="teacher-b",
    )

    teacher_a = certificate_service.list_certificates(user_id="teacher-a")
    teacher_b = certificate_service.list_certificates(user_id="teacher-b")

    assert [item["certificate_id"] for item in teacher_a] == ["CERT-A"]
    assert [item["certificate_id"] for item in teacher_b] == ["CERT-B"]
    assert all("user_id" not in item for item in teacher_a + teacher_b)

    with pytest.raises(PermissionError):
        certificate_service.save_certificate(
            {"certificate_id": "CERT-A", "student_name": "Intruder"},
            user_id="teacher-b",
        )


def test_certificate_verification_remains_public(monkeypatch):
    monkeypatch.setattr(
        certificates,
        "get_certificate",
        lambda certificate_id: {
            "certificate_id": certificate_id,
            "status": "valid",
        },
    )
    app = FastAPI()
    app.include_router(certificates.router)
    client = TestClient(app)

    response = client.get("/certificates/verify/REC-TEST")

    assert response.status_code == 200
    assert response.json()["valid"] is True


def test_student_keeps_shared_question_bank_and_exam_access(monkeypatch):
    monkeypatch.setattr(documents, "validate_document_owner", lambda **kwargs: {})
    monkeypatch.setattr(
        documents,
        "enforce_exam_limit",
        lambda **kwargs: "student",
    )
    monkeypatch.setattr(
        documents,
        "enforce_question_count_limit",
        lambda **kwargs: "student",
    )
    monkeypatch.setattr(
        documents,
        "enforce_question_bank_permission",
        lambda **kwargs: "student",
    )
    monkeypatch.setattr(
        documents,
        "build_document_context",
        lambda **kwargs: "owned academic content",
    )
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
    monkeypatch.setattr(documents, "register_usage_event", lambda **kwargs: {})

    class FakeUsageOperation:
        def commit(self, metadata=None):
            del metadata

        def release(self, *, reason):
            del reason

    monkeypatch.setattr(
        documents,
        "begin_usage_operation",
        lambda **kwargs: FakeUsageOperation(),
    )
    client = _authorized_client(
        monkeypatch,
        user=_user(role="student"),
        subscription=_subscription(plan="student"),
    )

    question_bank = client.post("/documents/question-bank/doc_1")
    exam = client.post("/documents/exam/doc_1")

    assert question_bank.status_code == 200
    assert exam.status_code == 200


def test_teacher_can_call_teacher_endpoint_for_owned_document(monkeypatch):
    monkeypatch.setattr(documents, "validate_document_owner", lambda **kwargs: {})
    monkeypatch.setattr(
        documents,
        "build_document_context",
        lambda **kwargs: "owned academic content",
    )
    monkeypatch.setattr(
        documents,
        "generate_teaching_plan_from_context",
        lambda **kwargs: '{"weeks": []}',
    )
    monkeypatch.setattr(documents, "register_usage_event", lambda **kwargs: {})
    client = _authorized_client(
        monkeypatch,
        user=_user(role="teacher"),
        subscription=_subscription(plan="teacher"),
    )

    response = client.post("/documents/teaching-plan/doc_1")

    assert response.status_code == 200
    assert response.json()["document_id"] == "doc_1"


def test_teacher_cannot_access_document_owned_by_another_user(monkeypatch):
    def deny_ownership(**kwargs):
        raise HTTPException(status_code=403, detail="Documento no disponible.")

    monkeypatch.setattr(documents, "validate_document_owner", deny_ownership)
    client = _authorized_client(
        monkeypatch,
        user=_user(role="teacher"),
        subscription=_subscription(plan="teacher"),
    )

    response = client.post("/documents/teaching-plan/other_user_doc")

    assert response.status_code == 403
    assert response.json()["detail"] == "Documento no disponible."
