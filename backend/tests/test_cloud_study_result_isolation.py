import pytest

from app.routes.cloud import handle_cloud_error
from app.services import cloud_service


def test_study_result_allowlist_matches_product_resources():
    assert {
        "assessment_report",
        "audiobook",
        "curriculum_intelligence",
        "exam",
        "final_report",
        "flashcards",
        "question_bank",
        "quiz",
        "rubric",
        "study_guide",
        "teaching_plan",
        "teaching_resources",
    }.issubset(cloud_service.ALLOWED_STUDY_RESULT_TYPES)


class _Response:
    def __init__(self, data):
        self.data = data


class _Query:
    def __init__(self, table_name, rows):
        self.table_name = table_name
        self.rows = rows
        self.filters = []
        self.single = False
        self.upsert_payload = None

    def select(self, _columns):
        return self

    def eq(self, key, value):
        self.filters.append((key, value))
        return self

    def maybe_single(self):
        self.single = True
        return self

    def order(self, _key, desc=False):
        return self

    def upsert(self, payload, on_conflict=None):
        self.upsert_payload = dict(payload)
        return self

    def execute(self):
        if self.upsert_payload is not None:
            self.rows.setdefault(self.table_name, []).append(self.upsert_payload)
            return _Response([self.upsert_payload])

        data = self.rows.get(self.table_name, [])
        for key, value in self.filters:
            data = [row for row in data if row.get(key) == value]
        if self.single:
            return _Response(data[0] if data else None)
        return _Response(data)


class _FakeSupabase:
    def __init__(self, rows):
        self.rows = rows
        self.tables = []

    def table(self, table_name):
        self.tables.append(table_name)
        return _Query(table_name, self.rows)


class _NoRowQuery(_Query):
    def execute(self):
        return None


class _NoRowSupabase(_FakeSupabase):
    def table(self, table_name):
        self.tables.append(table_name)
        return _NoRowQuery(table_name, self.rows)


def test_get_study_result_filters_by_user_document_and_type(monkeypatch):
    fake = _FakeSupabase(
        {
            "study_results": [
                {
                    "user_id": "user_a",
                    "document_id": "doc_1",
                    "type": "quiz",
                    "content": "A",
                },
                {
                    "user_id": "user_b",
                    "document_id": "doc_1",
                    "type": "quiz",
                    "content": "B",
                },
            ]
        }
    )
    monkeypatch.setattr(cloud_service, "get_supabase_admin_client", lambda: fake)

    result = cloud_service.get_study_result(
        user_id="user_b",
        document_id="doc_1",
        type="quiz",
    )

    assert result["content"] == "B"
    assert fake.tables == ["study_results"]


def test_get_study_result_returns_none_when_client_has_no_row(monkeypatch):
    fake = _NoRowSupabase({"study_results": []})
    monkeypatch.setattr(cloud_service, "get_supabase_admin_client", lambda: fake)

    result = cloud_service.get_study_result(
        user_id="user_b",
        document_id="doc_a",
        type="flashcards",
    )

    assert result is None


def test_list_study_results_never_returns_other_users(monkeypatch):
    fake = _FakeSupabase(
        {
            "study_results": [
                {
                    "user_id": "user_a",
                    "document_id": "doc_a",
                    "type": "quiz",
                    "content": "A",
                },
                {
                    "user_id": "user_b",
                    "document_id": "doc_b",
                    "type": "quiz",
                    "content": "B",
                },
            ]
        }
    )
    monkeypatch.setattr(cloud_service, "get_supabase_admin_client", lambda: fake)

    results = cloud_service.list_study_results(
        user_id="user_a",
        type="quiz",
    )

    assert [item["document_id"] for item in results] == ["doc_a"]


def test_valid_audiobook_result_persists_with_authenticated_owner(monkeypatch):
    fake = _FakeSupabase({"study_results": []})
    monkeypatch.setattr(cloud_service, "get_supabase_admin_client", lambda: fake)

    result = cloud_service.upsert_study_result(
        user_id="user_a",
        document_id="doc_audiobook",
        type=" AUDIOBOOK ",
        content='{"chapters": [{"title": "Capítulo 1"}]}',
    )

    assert result["user_id"] == "user_a"
    assert result["document_id"] == "doc_audiobook"
    assert result["type"] == "audiobook"
    assert fake.tables == ["study_results"]


@pytest.mark.parametrize("invalid_type", ["audio", "audio_book", "audio-book", "custom"])
def test_invalid_study_result_type_is_rejected(invalid_type, monkeypatch):
    monkeypatch.setattr(
        cloud_service,
        "get_supabase_admin_client",
        lambda: pytest.fail("Invalid types must fail before persistence."),
    )

    with pytest.raises(ValueError, match="Tipo de resultado inválido"):
        cloud_service.upsert_study_result(
            user_id="user_a",
            document_id="doc_audiobook",
            type=invalid_type,
            content="{}",
        )


def test_invalid_study_result_type_is_reported_as_client_error():
    response = handle_cloud_error(ValueError("Tipo de resultado inválido."))

    assert response.status_code == 400
    assert response.detail == "Tipo de resultado inválido."
