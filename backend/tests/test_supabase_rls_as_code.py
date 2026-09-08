import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "supabase/migrations/20260829000100_studybook_rls_security.sql"
CORE_SCHEMA_MIGRATION = (
    ROOT / "supabase/migrations/20260828000100_studybook_core_schema.sql"
)
SQL_TEST = ROOT / "supabase/tests/rls_policy_contract.sql"
PERSISTENCE_MIGRATION = (
    ROOT / "supabase/migrations/20260831000100_production_persistence.sql"
)
OWNERSHIP_MIGRATION = (
    ROOT / "supabase/migrations/20260901000100_document_ownership_hardening.sql"
)
OWNERSHIP_BACKFILL = (
    ROOT / "supabase/backfills/document_ownership_backfill.sql"
)
PERSISTENCE_SQL_TEST = (
    ROOT / "supabase/tests/production_persistence_contract.sql"
)
ATOMIC_QUOTA_MIGRATION = (
    ROOT / "supabase/migrations/20260907000100_atomic_free_quota.sql"
)
ATOMIC_QUOTA_SQL_TEST = (
    ROOT / "supabase/tests/atomic_free_quota_contract.sql"
)

EXPECTED_TABLES = {
    "workspaces",
    "documents",
    "study_results",
    "audiobooks",
    "chats",
    "messages",
    "user_subscriptions",
    "user_usage_events",
    "educator_courses",
    "educator_students",
    "educator_attendance",
    "educator_gradebook",
    "educator_question_banks",
    "certificates",
    "document_chunks",
}


def _migration_sql() -> str:
    return MIGRATION.read_text(encoding="utf-8").lower()


def test_core_schema_makes_clean_migration_chain_reproducible():
    sql = CORE_SCHEMA_MIGRATION.read_text(encoding="utf-8").lower()

    for table in EXPECTED_TABLES - {"certificates", "document_chunks"}:
        assert f"create table if not exists public.{table}" in sql

    assert "drop table" not in sql
    assert "drop schema" not in sql
    assert "references auth.users(id) on delete cascade" in sql
    assert "unique (user_id, document_id, type)" in sql
    assert "unique (user_id, document_id)" in sql


def test_migration_covers_every_backend_supabase_table():
    source = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for path in (ROOT / "backend/app").rglob("*.py")
        if ".bak" not in path.name
    )
    literal_tables = set(re.findall(r'\.table\("([a-z_]+)"\)', source))
    educator_tables = set(re.findall(r'table="(educator_[a-z_]+)"', source))
    configured_tables = set(
        re.findall(r'[A-Z_]+_TABLE\s*=\s*"([a-z_]+)"', source)
    )

    assert literal_tables | educator_tables | configured_tables == EXPECTED_TABLES

    sql = _migration_sql()
    for table in EXPECTED_TABLES - {"certificates", "document_chunks"}:
        assert f"alter table public.{table} enable row level security" in sql

    persistence_sql = PERSISTENCE_MIGRATION.read_text(encoding="utf-8").lower()
    for table in {"certificates", "document_chunks"}:
        assert f"alter table public.{table} enable row level security" in persistence_sql


def test_persistence_migration_keeps_private_data_server_side():
    sql = PERSISTENCE_MIGRATION.read_text(encoding="utf-8").lower()

    assert "public.document_chunks" in sql
    assert "extensions.vector(1536)" in sql
    assert "where chunk.user_id = p_user_id" in sql
    assert "studybook-private-artifacts" in sql
    assert "public=false" not in sql
    assert "public)\nvalues ('studybook-private-artifacts'" in sql
    assert "revoke all on public.document_chunks from public, anon, authenticated" in sql
    assert "operator(extensions.<=>)" in sql


def test_document_ownership_backfill_is_deterministic_and_fail_closed():
    migration = OWNERSHIP_MIGRATION.read_text(encoding="utf-8").lower()
    backfill = OWNERSHIP_BACKFILL.read_text(encoding="utf-8").lower()

    for statement in (
        "set user_id = workspace.user_id",
        "auth_user.id::text = substring",
        "document/workspace ownership conflict requires quarantine",
        "document/storage ownership conflict requires quarantine",
        "unowned documents require quarantine before hardening",
    ):
        assert statement in migration
        assert statement in backfill

    assert "alter table public.documents alter column user_id set not null" in migration
    assert "delete from" not in backfill
    assert "truncate" not in backfill


def test_migration_preserves_server_authorities_and_denies_owner_spoof():
    sql = _migration_sql()

    assert "auth.uid()" in sql
    assert "auth.jwt() -> 'app_metadata'" in sql
    assert "user_metadata" not in sql
    assert "add column if not exists user_id uuid references auth.users(id)" in sql
    assert "private.is_current_user(user_id::text)" in sql
    assert "private.has_teacher_access()" in sql
    assert (
        "'private.is_current_user(user_id::text) and "
        "private.owns_document(user_id::text"
    ) in sql
    assert "security definer" in sql
    assert "studybook_user_subscriptions_insert" not in sql
    assert "studybook_user_subscriptions_update" not in sql
    assert "studybook_user_subscriptions_delete" not in sql
    assert "studybook_messages_update" not in sql


def test_migration_secures_only_the_confirmed_private_storage_bucket():
    sql = _migration_sql()

    assert "'studybook-documents'" in sql
    assert "on conflict (id) do update set public = false" in sql
    assert "coalesce(nullif(storage_bucket, ''), 'studybook-documents')" in sql
    assert "private.owns_document_object(bucket_id::text, name::text)" in sql
    assert "split_part(coalesce(object_name, ''), '/', 1) = auth.uid()::text" in sql
    assert "(^|/)\\.{1,2}(/|$)" in sql


def test_migration_does_not_replace_existing_policies_or_create_app_tables():
    sql = _migration_sql()

    assert "drop policy" not in sql
    assert "create table" not in sql
    assert "unknown public policy detected" in sql
    assert "unknown storage policy detected" in sql
    assert sql.count("call private.ensure_policy(") == 49
    assert sql.count("  'public',") == 45
    assert sql.count("  'storage',") == 4


def test_sql_contract_covers_negative_identity_and_storage_cases():
    sql = SQL_TEST.read_text(encoding="utf-8").lower()

    assert "user_metadata" in sql
    assert "student a/b ownership isolation failed" in sql
    assert "storage path traversal was accepted" in sql
    assert "an arbitrary document bucket was accepted" in sql
    assert "a spoofed document user_id was accepted" in sql
    assert "student obtained teacher access" in sql
    assert "app_metadata admin bypassed the backend admin boundary" in sql
    assert "teacher role without an entitled subscription was accepted" in sql
    assert "unknown identity did not fail closed" in sql
    assert sql.strip().endswith("rollback;")


def test_local_persistence_contract_covers_real_rows_storage_and_vectors():
    sql = PERSISTENCE_SQL_TEST.read_text(encoding="utf-8").lower()

    assert "student a workspace isolation failed" in sql
    assert "student a storage isolation failed" in sql
    assert "student a reached teacher data" in sql
    assert "owner spoof was accepted" in sql
    assert "storage owner-path spoof was accepted" in sql
    assert "direct private-artifact write was accepted" in sql
    assert "owner-scoped vector retrieval failed" in sql
    assert sql.strip().endswith("rollback;")


def test_atomic_quota_migration_is_server_only_and_fail_closed():
    sql = ATOMIC_QUOTA_MIGRATION.read_text(encoding="utf-8").lower()

    assert "create table if not exists public.quota_reservations" in sql
    assert "alter table public.quota_reservations enable row level security" in sql
    assert "pg_advisory_xact_lock" in sql
    assert "reservation_expired" in sql
    assert "interval '30 minutes'" in sql
    assert "date_trunc('month'" in sql
    assert "at time zone 'utc'" in sql
    assert "v_reservation.reserved_at" in sql
    assert sql.count("security invoker") == 3
    assert sql.count("set search_path = ''") == 3
    assert "security definer" not in sql
    for role in ("public", "anon", "authenticated"):
        assert role in sql
    for function_name in (
        "reserve_studybook_free_quota",
        "commit_studybook_free_quotas",
        "release_studybook_free_quota",
    ):
        assert f"grant execute on function public.{function_name}" in sql
    assert "to service_role" in sql


def test_atomic_quota_sql_contract_covers_concurrency_security_and_lifecycle():
    sql = ATOMIC_QUOTA_SQL_TEST.read_text(encoding="utf-8").lower()

    assert "quota boundary exceeded" in sql
    assert "idempotent commit duplicated usage" in sql
    assert "released reservation continued blocking quota" in sql
    assert "cross-user release was accepted" in sql
    assert "authenticated role executed quota reservation rpc" in sql
    assert sql.strip().endswith("rollback;")
