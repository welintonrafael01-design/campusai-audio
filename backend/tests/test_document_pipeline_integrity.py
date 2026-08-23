from pathlib import Path

import chromadb
from fastapi import FastAPI
from fastapi.testclient import TestClient
from PIL import Image

from app.routes import documents
from app.security.user_auth import AuthenticatedUser, require_current_user
from app.services import pdf_service, rag_service


class _FakeEmbeddingFunction:
    @staticmethod
    def _vector(text: str) -> list[float]:
        normalized = text.lower()
        return [
            float(normalized.count("alpha") + 1),
            float(normalized.count("beta") + 1),
            1.0,
        ]

    def embed_documents(self, texts: list[str]) -> list[list[float]]:
        return [self._vector(text) for text in texts]

    def embed_query(self, text: str) -> list[float]:
        return self._vector(text)


class _FakePixmap:
    width = 4
    height = 2
    samples = bytes([255, 0, 0] * width * height)


class _FakeRotatedPage:
    rotation = 270

    @staticmethod
    def get_pixmap(**_kwargs):
        return _FakePixmap()


def test_rotated_scanned_page_is_normalized_before_ocr():
    image = pdf_service.prepare_page_image_for_ocr(_FakeRotatedPage())

    assert image.mode == "RGB"
    assert image.size == (2, 4)


def test_low_confidence_ocr_is_rejected(monkeypatch):
    monkeypatch.setattr(
        pdf_service,
        "prepare_page_image_for_ocr",
        lambda page: Image.new("RGB", (10, 10)),
    )
    monkeypatch.setattr(
        pdf_service.pytesseract,
        "image_to_data",
        lambda *args, **kwargs: {
            "text": ["atreivni"],
            "conf": ["20"],
            "block_num": [1],
            "par_num": [1],
            "line_num": [1],
        },
    )

    try:
        pdf_service.extract_text_with_ocr(object())
    except ValueError as error:
        assert "calidad OCR" in str(error)
    else:
        raise AssertionError("Low-confidence OCR must not reach AI summary.")


def test_rag_collections_keep_alpha_and_beta_documents_isolated(monkeypatch):
    monkeypatch.setattr(rag_service, "client", chromadb.EphemeralClient())
    monkeypatch.setattr(
        rag_service,
        "embedding_function",
        _FakeEmbeddingFunction(),
    )

    alpha_id = rag_service.store_document_page_embeddings(
        [{"page_number": 1, "text": "ALPHA exclusivo astronomia"}],
        owner_scope="user-a",
    )
    beta_id = rag_service.store_document_page_embeddings(
        [{"page_number": 1, "text": "BETA exclusivo botanica"}],
        owner_scope="user-b",
    )

    alpha_context = rag_service.search_similar_chunks(
        alpha_id,
        "ALPHA",
    )
    beta_context = rag_service.search_similar_chunks(
        beta_id,
        "BETA",
    )

    assert alpha_id != beta_id
    assert "ALPHA exclusivo" in alpha_context
    assert "BETA exclusivo" not in alpha_context
    assert "BETA exclusivo" in beta_context
    assert "ALPHA exclusivo" not in beta_context


def test_semantic_search_filters_ownership_before_querying_collections(monkeypatch):
    monkeypatch.setattr(rag_service, "client", chromadb.EphemeralClient())
    monkeypatch.setattr(
        rag_service,
        "embedding_function",
        _FakeEmbeddingFunction(),
    )

    alpha_id = rag_service.store_document_page_embeddings(
        [{"page_number": 1, "text": "ALPHA contenido privado"}],
        owner_scope="user-a",
    )
    beta_id = rag_service.store_document_page_embeddings(
        [{"page_number": 1, "text": "BETA contenido privado"}],
        owner_scope="user-b",
    )

    results = rag_service.semantic_search_all_documents(
        "BETA",
        document_filter=lambda document_id: document_id == alpha_id,
    )

    assert results
    assert {item["document_id"] for item in results} == {alpha_id}
    assert beta_id not in {item["document_id"] for item in results}


def test_retrieval_citations_include_only_real_page_metadata(monkeypatch):
    monkeypatch.setattr(rag_service, "client", chromadb.EphemeralClient())
    monkeypatch.setattr(
        rag_service,
        "embedding_function",
        _FakeEmbeddingFunction(),
    )

    document_id = rag_service.store_document_page_embeddings(
        [{"page_number": 3, "text": "ALPHA fuente legible y verificable"}],
        owner_scope="user-a",
    )

    citations = rag_service.get_retrieval_citations(
        document_id,
        "ALPHA",
        top_k=1,
    )

    assert len(citations) == 1
    assert citations[0]["page_number"] == 3
    assert "ALPHA fuente legible" in citations[0]["preview"]


def test_document_chat_returns_human_source_title(monkeypatch):
    app = FastAPI()
    app.include_router(documents.router)
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id="user-a",
        email="user-a@example.test",
        app_metadata={"role": "student"},
    )
    monkeypatch.setattr(
        documents,
        "validate_document_owner",
        lambda **kwargs: {"filename": "Biología molecular.pdf"},
    )
    monkeypatch.setattr(documents, "enforce_chat_limit", lambda **kwargs: "student")
    monkeypatch.setattr(documents, "chat_with_document_id", lambda **kwargs: "Respuesta")
    monkeypatch.setattr(documents, "register_usage_event", lambda **kwargs: None)
    monkeypatch.setattr(
        documents,
        "get_retrieval_citations",
        lambda **kwargs: [
            {
                "document_id": "doc-a",
                "chunk_index": 0,
                "page_number": 2,
                "preview": "Fragmento legible",
                "distance": 0.2,
            }
        ],
    )

    response = TestClient(app).post("/documents/chat/doc-a?question=¿Qué dice?")

    assert response.status_code == 200
    assert response.json()["citations"][0]["document_title"] == (
        "Biología molecular.pdf"
    )


def test_upload_summarizes_selected_document_and_hides_internal_fields(
    monkeypatch,
    tmp_path: Path,
):
    app = FastAPI()
    app.include_router(documents.router)
    app.dependency_overrides[require_current_user] = lambda: AuthenticatedUser(
        user_id="user-a",
        email="user-a@example.test",
        app_metadata={"role": "student"},
    )

    async def fake_save_upload(file):
        path = tmp_path / (file.filename or "fixture.pdf")
        path.write_bytes(await file.read())
        return path

    def fake_extract_pages(path: str):
        marker = "ALPHA" if "alpha" in path else "BETA"
        return [{"page_number": 1, "text": f"{marker} contenido exclusivo"}]

    summary_inputs: list[str] = []

    def fake_summary(text: str, language: str):
        summary_inputs.append(text)
        return f"Resumen {text.split()[0]}"

    monkeypatch.setattr(documents, "enforce_pdf_upload_limit", lambda **kwargs: "student")
    monkeypatch.setattr(documents, "save_upload_file", fake_save_upload)
    monkeypatch.setattr(documents, "extract_pages_from_pdf", fake_extract_pages)
    monkeypatch.setattr(
        documents,
        "index_document_pages_for_rag",
        lambda pages, owner_scope: f"doc-{pages[0]['text'].split()[0].lower()}",
    )
    monkeypatch.setattr(
        documents,
        "upload_document_to_storage",
        lambda **kwargs: {
            "bucket": "private",
            "storage_path": "user-a/private.pdf",
        },
    )
    monkeypatch.setattr(
        documents,
        "register_document_file",
        lambda **kwargs: {
            **kwargs,
            "user_id": "user-a",
        },
    )
    monkeypatch.setattr(documents, "register_usage_event", lambda **kwargs: None)
    monkeypatch.setattr(documents, "generate_ai_summary", fake_summary)
    monkeypatch.setattr(documents, "create_cloud_document", lambda **kwargs: None)

    client = TestClient(app)
    alpha = client.post(
        "/documents/upload?language=es",
        files={"file": ("alpha.pdf", b"%PDF-alpha", "application/pdf")},
    )
    beta = client.post(
        "/documents/upload?language=es",
        files={"file": ("beta.pdf", b"%PDF-beta", "application/pdf")},
    )

    assert alpha.status_code == 200
    assert beta.status_code == 200
    assert summary_inputs == [
        "ALPHA contenido exclusivo",
        "BETA contenido exclusivo",
    ]
    assert alpha.json()["ai_summary"] == "Resumen ALPHA"
    assert beta.json()["ai_summary"] == "Resumen BETA"

    forbidden = {
        "text_preview",
        "document_info",
        "file_path",
        "storage_path",
        "user_id",
    }
    assert forbidden.isdisjoint(alpha.json())
    assert forbidden.isdisjoint(beta.json())
