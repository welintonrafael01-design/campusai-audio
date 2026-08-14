import pytest
from fastapi import HTTPException

from app.security.admin_auth import require_admin_user
from app.security.user_auth import AuthenticatedUser


def test_require_admin_user_allows_configured_admin_email(monkeypatch):
    monkeypatch.setenv("ADMIN_EMAILS", "admin@studybook.ai")

    user = require_admin_user(
        AuthenticatedUser(
            user_id="user_1",
            email="admin@studybook.ai",
        )
    )

    assert user.user_id == "user_1"


def test_require_admin_user_rejects_non_admin_email(monkeypatch):
    monkeypatch.setenv("ADMIN_EMAILS", "admin@studybook.ai")

    with pytest.raises(HTTPException) as exc:
        require_admin_user(
            AuthenticatedUser(
                user_id="user_2",
                email="student@studybook.ai",
            )
        )

    assert exc.value.status_code == 403
