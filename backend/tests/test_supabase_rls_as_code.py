import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / "supabase/migrations/20260829000100_studybook_rls_security.sql"
SQL_TEST = ROOT / "supabase/tests/rls_policy_contract.sql"
PERSISTENCE_MIGRATION = (
    ROOT / "supabase/migrations/20260831000100_production_persistence.sql"
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
