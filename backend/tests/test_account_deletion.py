from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.routes import account
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services.account_deletion_service import (
    AccountDeletionInventory,
    AccountDeletionResult,
    delete_user_account,
)
from app.services import subscription_service


class FakeDeletionOperations:
    def __init__(self, *, fail_at: str | None = None):
        self.fail_at = fail_at
        self.calls: list[tuple[str, str]] = []

    def _record(self, step: str, user_id: str) -> None:
        self.calls.append((step, user_id))
        if self.fail_at == step:
            raise RuntimeError("controlled deletion failure")

    def prepare(self, *, user_id: str) -> AccountDeletionInventory:
        self._record("inventory", user_id)
        return AccountDeletionInventory(
            document_ids=("doc-a",),
            external_subscription_action_required=True,
        )

    def delete_storage(self, *, user_id: str, inventory) -> None:
        assert inventory.document_ids == ("doc-a",)
        self._record("storage", user_id)

    def delete_runtime_data(self, *, user_id: str, inventory) -> None:
        self._record("runtime_data", user_id)

    def delete_database_rows(self, *, user_id: str, inventory) -> None:
        self._record("database_rows", user_id)

    def delete_auth_user(self, *, user_id: str) -> None:
        self._record("auth_identity", user_id)


def _authenticated_app(user_id: str = "student-a") -> FastAPI:
    app = FastAPI()
    app.include_router(account.router)
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id=user_id,
        email=f"{user_id}@example.test",
    )
    return app


def test_account_deletion_uses_only_authenticated_user():
    operations = FakeDeletionOperations()

    result = delete_user_account(
        user_id="student-a",
        operations=operations,
    )

    assert result.success is True
    assert result.external_subscription_action_required is True
    assert {user_id for _, user_id in operations.calls} == {"student-a"}
    assert operations.calls[-1] == ("auth_identity", "student-a")


def test_partial_deletion_never_removes_auth_identity():
    operations = FakeDeletionOperations(fail_at="database_rows")

    result = delete_user_account(
        user_id="student-a",
        operations=operations,
    )

    assert result.success is False
    assert result.status == "retry_required"
    assert result.failed_step == "database_rows"
    assert ("auth_identity", "student-a") not in operations.calls


def test_account_deletion_is_retry_safe():
    first = FakeDeletionOperations(fail_at="storage")
    retry = FakeDeletionOperations()

    failed = delete_user_account(user_id="student-a", operations=first)
    completed = delete_user_account(user_id="student-a", operations=retry)

    assert failed.status == "retry_required"
    assert completed.status == "deleted"


def test_cross_user_fields_are_rejected_before_deletion():
    client = TestClient(_authenticated_app("student-a"))

    response = client.request(
        "DELETE",
        "/account/me",
        json={
            "confirmation": "ELIMINAR MI CUENTA",
            "user_id": "teacher-b",
            "email": "admin@example.test",
        },
    )

    assert response.status_code == 422


def test_successful_own_deletion_endpoint(monkeypatch):
    captured = {}

    def fake_delete_user_account(*, user_id: str):
        captured["user_id"] = user_id
        return AccountDeletionResult(success=True, status="deleted")

    monkeypatch.setattr(account, "delete_user_account", fake_delete_user_account)
    client = TestClient(_authenticated_app("student-a"))

    response = client.request(
        "DELETE",
        "/account/me",
        json={"confirmation": "ELIMINAR MI CUENTA"},
    )

    assert response.status_code == 200
    assert response.json()["deleted"] is True
    assert captured == {"user_id": "student-a"}


def test_unauthenticated_deletion_is_denied():
    app = FastAPI()
    app.include_router(account.router)

    response = TestClient(app).request(
        "DELETE",
        "/account/me",
        json={"confirmation": "ELIMINAR MI CUENTA"},
    )

    assert response.status_code == 401


def test_deleted_auth_user_cannot_be_recreated_by_billing_lookup(monkeypatch):
    class Admin:
        @staticmethod
        def get_user_by_id(user_id):
            raise RuntimeError("user not found")

    fake_client = type(
        "Client",
        (),
        {"auth": type("Auth", (), {"admin": Admin()})()},
    )()
    monkeypatch.setattr(
        subscription_service,
        "get_supabase_admin_client",
        lambda: fake_client,
    )

    assert subscription_service.auth_user_exists(user_id="deleted-user") is False
