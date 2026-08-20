from app.services import documents_cloud_service
from app.services.rag_service import (
    generate_document_id,
    generate_user_scoped_document_id,
)


class _Response:
    def __init__(self, data):
        self.data = data


class _InsertQuery:
    def __init__(self, client, payload):
        self.client = client
        self.payload = payload

    def execute(self):
        if "user_id" in self.payload:
            raise Exception(
                "{'code': 'PGRST204', "
                "'message': \"Could not find the 'user_id' column of "
                "'documents' in the schema cache\"}"
            )

        self.client.inserted.append(self.payload)
        return _Response([self.payload])


class _Table:
    def __init__(self, client):
        self.client = client

    def insert(self, payload):
        return _InsertQuery(self.client, payload)


class _LegacyDocumentsClient:
    def __init__(self):
        self.inserted = []

    def table(self, table_name):
        assert table_name == "documents"
        return _Table(self)


def test_document_ids_are_scoped_by_owner():
    text = "El mismo documento académico."

    user_a_id = generate_user_scoped_document_id(text, user_id="user-a")
    user_b_id = generate_user_scoped_document_id(text, user_id="user-b")

    assert user_a_id != user_b_id
    assert user_a_id != generate_document_id(text)
    assert len(user_a_id) == 24


def test_cloud_insert_supports_legacy_schema_without_user_id(monkeypatch):
    client = _LegacyDocumentsClient()
    monkeypatch.setattr(
        documents_cloud_service,
        "get_supabase_admin_client",
        lambda: client,
    )

    result = documents_cloud_service.create_document(
        user_id="user-a",
        document_id="doc-a",
        filename="fixture.pdf",
        storage_bucket="documents",
        storage_path="user-a/documents/doc-a/fixture.pdf",
    )

    assert client.inserted[0]["document_id"] == "doc-a"
    assert "user_id" not in client.inserted[0]
    assert result[0]["user_id"] == "user-a"
