from __future__ import annotations

from dataclasses import dataclass, field
import logging
from typing import Protocol

from app.database.supabase_client import get_supabase_admin_client
from app.services.audio_service import delete_audio_for_user
from app.services.certificate_service import delete_certificates_for_user
from app.services.document_registry_service import (
    delete_documents_for_user,
    list_documents_for_user,
)
from app.services.rag_service import delete_document_embeddings
from app.services.storage_service import get_storage_bucket
from app.services.private_artifact_storage import (
    list_private_artifacts_for_user,
)
from app.persistence_config import private_artifacts_bucket
from app.public_urls import is_production_environment


logger = logging.getLogger(__name__)

EDUCATOR_TABLES = (
    "educator_question_banks",
    "educator_gradebook",
    "educator_attendance",
    "educator_students",
    "educator_courses",
)

USER_TABLES = (
    "study_results",
    "audiobooks",
    *EDUCATOR_TABLES,
    "quota_reservations",
    "user_usage_events",
    "user_subscriptions",
    "certificates",
    "document_chunks",
)


@dataclass(frozen=True)
class AccountDeletionInventory:
    workspace_ids: tuple[str, ...] = ()
    chat_ids: tuple[str, ...] = ()
    document_ids: tuple[str, ...] = ()
    storage_objects: tuple[tuple[str, str], ...] = ()
    external_subscription_action_required: bool = False


@dataclass(frozen=True)
class AccountDeletionResult:
    success: bool
    status: str
    completed_steps: tuple[str, ...] = ()
    failed_step: str | None = None
    external_subscription_action_required: bool = False


class AccountDeletionOperations(Protocol):
    def prepare(self, *, user_id: str) -> AccountDeletionInventory: ...

    def delete_storage(
        self,
        *,
        user_id: str,
        inventory: AccountDeletionInventory,
    ) -> None: ...

    def delete_runtime_data(
        self,
        *,
        user_id: str,
        inventory: AccountDeletionInventory,
    ) -> None: ...

    def delete_database_rows(
        self,
        *,
        user_id: str,
        inventory: AccountDeletionInventory,
    ) -> None: ...

    def delete_auth_user(self, *, user_id: str) -> None: ...


def _is_missing_relation(error: Exception) -> bool:
    message = str(error).lower()
    return any(code in message for code in ("42p01", "pgrst205"))


def _is_missing_column(error: Exception, column: str) -> bool:
    message = str(error).lower()
    return column.lower() in message and any(
        code in message for code in ("42703", "pgrst204")
    )


class SupabaseAccountDeletionOperations:
    def __init__(self, client=None):
        self._client = client

    @property
    def client(self):
        return self._client or get_supabase_admin_client()

    def prepare(self, *, user_id: str) -> AccountDeletionInventory:
        client = self.client
        workspaces = self._select_user_rows("workspaces", user_id, "id")
        chats = self._select_user_rows("chats", user_id, "id")
        subscriptions = self._select_user_rows(
            "user_subscriptions",
            user_id,
            "stripe_customer_id,stripe_subscription_id,subscription_status",
        )

        workspace_ids = tuple(
            str(row.get("id") or "").strip()
            for row in workspaces
            if str(row.get("id") or "").strip()
        )
        chat_ids = tuple(
            str(row.get("id") or "").strip()
            for row in chats
            if str(row.get("id") or "").strip()
        )

        documents = self._select_documents(
            user_id=user_id,
            workspace_ids=workspace_ids,
        )
        registry_documents = list_documents_for_user(user_id=user_id)
        all_documents = [*documents, *registry_documents]

        document_ids = tuple(
            sorted(
                {
                    str(row.get("document_id") or "").strip()
                    for row in all_documents
                    if str(row.get("document_id") or "").strip()
                }
            )
        )
        document_storage_objects = {
            (
                str(row.get("storage_bucket") or get_storage_bucket()),
                str(row.get("storage_path") or "").strip(),
            )
            for row in all_documents
            if str(row.get("storage_path") or "").strip().startswith(
                f"{user_id}/documents/"
            )
        }
        artifact_storage_objects = (
            {
                (private_artifacts_bucket(), path)
                for path in list_private_artifacts_for_user(
                    user_id=user_id,
                    client=client,
                )
            }
            if is_production_environment()
            else set()
        )
        storage_objects = tuple(
            sorted(document_storage_objects | artifact_storage_objects)
        )
        external_subscription = any(
            str(row.get("stripe_subscription_id") or "").strip()
            or str(row.get("stripe_customer_id") or "").strip()
            for row in subscriptions
        )

        return AccountDeletionInventory(
            workspace_ids=workspace_ids,
            chat_ids=chat_ids,
            document_ids=document_ids,
            storage_objects=storage_objects,
            external_subscription_action_required=external_subscription,
        )

    def delete_storage(
        self,
        *,
        user_id: str,
        inventory: AccountDeletionInventory,
    ) -> None:
        del user_id
        by_bucket: dict[str, list[str]] = {}
        for bucket, path in inventory.storage_objects:
            by_bucket.setdefault(bucket, []).append(path)

        for bucket, paths in by_bucket.items():
            self.client.storage.from_(bucket).remove(paths)

    def delete_runtime_data(
        self,
        *,
        user_id: str,
        inventory: AccountDeletionInventory,
    ) -> None:
        for document_id in inventory.document_ids:
            delete_document_embeddings(document_id, owner_scope=user_id)

        delete_documents_for_user(user_id=user_id)
        delete_audio_for_user(user_id=user_id)
        delete_certificates_for_user(user_id=user_id)

    def delete_database_rows(
        self,
        *,
        user_id: str,
        inventory: AccountDeletionInventory,
    ) -> None:
        client = self.client

        if inventory.chat_ids:
            (
                client.table("messages")
                .delete()
                .in_("chat_id", list(inventory.chat_ids))
                .execute()
            )

        if inventory.workspace_ids:
            (
                client.table("documents")
                .delete()
                .in_("workspace_id", list(inventory.workspace_ids))
                .execute()
            )

        (
            client.table("documents")
            .delete()
            .like("storage_path", f"{user_id}/documents/%")
            .execute()
        )

        try:
            client.table("documents").delete().eq("user_id", user_id).execute()
        except Exception as error:
            if not _is_missing_column(error, "user_id"):
                raise

        for table in USER_TABLES:
            self._delete_user_rows(table, user_id)

        self._delete_user_rows("chats", user_id)
        self._delete_user_rows("workspaces", user_id)

    def delete_auth_user(self, *, user_id: str) -> None:
        self.client.auth.admin.delete_user(user_id)

    def _select_user_rows(
        self,
        table: str,
        user_id: str,
        columns: str,
    ) -> list[dict]:
        try:
            response = (
                self.client.table(table)
                .select(columns)
                .eq("user_id", user_id)
                .execute()
            )
        except Exception as error:
            if _is_missing_relation(error):
                return []
            raise
        return list(response.data or [])

    def _select_documents(
        self,
        *,
        user_id: str,
        workspace_ids: tuple[str, ...],
    ) -> list[dict]:
        rows: list[dict] = []
        if workspace_ids:
            response = (
                self.client.table("documents")
                .select("*")
                .in_("workspace_id", list(workspace_ids))
                .execute()
            )
            rows.extend(response.data or [])

        response = (
            self.client.table("documents")
            .select("*")
            .like("storage_path", f"{user_id}/documents/%")
            .execute()
        )
        rows.extend(response.data or [])
        return rows

    def _delete_user_rows(self, table: str, user_id: str) -> None:
        try:
            self.client.table(table).delete().eq("user_id", user_id).execute()
        except Exception as error:
            if not _is_missing_relation(error):
                raise


def delete_user_account(
    *,
    user_id: str,
    operations: AccountDeletionOperations | None = None,
) -> AccountDeletionResult:
    clean_user_id = str(user_id or "").strip()
    if not clean_user_id:
        raise ValueError("user_id es requerido.")

    runner = operations or SupabaseAccountDeletionOperations()
    completed: list[str] = []
    inventory = AccountDeletionInventory()
    steps = (
        ("inventory", lambda: runner.prepare(user_id=clean_user_id)),
        (
            "storage",
            lambda: runner.delete_storage(
                user_id=clean_user_id,
                inventory=inventory,
            ),
        ),
        (
            "runtime_data",
            lambda: runner.delete_runtime_data(
                user_id=clean_user_id,
                inventory=inventory,
            ),
        ),
        (
            "database_rows",
            lambda: runner.delete_database_rows(
                user_id=clean_user_id,
                inventory=inventory,
            ),
        ),
        ("auth_identity", lambda: runner.delete_auth_user(user_id=clean_user_id)),
    )

    for step, action in steps:
        try:
            value = action()
            if step == "inventory":
                inventory = value
            completed.append(step)
        except Exception:
            logger.exception("Account deletion stopped at step %s", step)
            return AccountDeletionResult(
                success=False,
                status="retry_required",
                completed_steps=tuple(completed),
                failed_step=step,
                external_subscription_action_required=(
                    inventory.external_subscription_action_required
                ),
            )

    return AccountDeletionResult(
        success=True,
        status="deleted",
        completed_steps=tuple(completed),
        external_subscription_action_required=(
            inventory.external_subscription_action_required
        ),
    )
