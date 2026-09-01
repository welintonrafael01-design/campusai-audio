from dotenv import load_dotenv
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from pathlib import Path
from typing import Callable

import chromadb
import hashlib
import os

from app.database.supabase_client import get_supabase_admin_client
from app.persistence_config import RAG_CHUNKS_TABLE
from app.public_urls import is_production_environment


load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent.parent
CHROMA_PATH = BASE_DIR / "chroma_db"

if is_production_environment():
    client = None
else:
    CHROMA_PATH.mkdir(parents=True, exist_ok=True)
    client = chromadb.PersistentClient(path=str(CHROMA_PATH))

embedding_function = OpenAIEmbeddings(
    api_key=os.getenv("OPENAI_API_KEY")
)

CHUNK_SIZE = 1200
CHUNK_OVERLAP = 200
DEFAULT_TOP_K = 5


def _required_owner_scope(owner_scope: str | None) -> str:
    clean_owner = str(owner_scope or "").strip()
    if not clean_owner:
        raise PermissionError("owner_scope es requerido para RAG en produccion.")
    return clean_owner


def _production_document_exists(*, document_id: str, owner_scope: str) -> bool:
    response = (
        get_supabase_admin_client()
        .table(RAG_CHUNKS_TABLE)
        .select("id")
        .eq("user_id", owner_scope)
        .eq("document_id", document_id)
        .limit(1)
        .execute()
    )
    return bool(response.data)


def _store_production_chunks(
    *,
    document_id: str,
    owner_scope: str,
    chunks: list[dict],
    embeddings: list[list[float]],
) -> None:
    rows = [
        {
            "user_id": owner_scope,
            "document_id": document_id,
            "chunk_index": index,
            "page_number": chunk.get("page_number"),
            "content": chunk["text"],
            "embedding": embedding,
            "metadata": {
                "chunk_size": CHUNK_SIZE,
                "chunk_overlap": CHUNK_OVERLAP,
            },
        }
        for index, (chunk, embedding) in enumerate(zip(chunks, embeddings))
    ]
    if not rows:
        raise ValueError("No hay fragmentos para persistir.")
    (
        get_supabase_admin_client()
        .table(RAG_CHUNKS_TABLE)
        .upsert(rows, on_conflict="user_id,document_id,chunk_index")
        .execute()
    )


def _query_production_chunks(
    *,
    owner_scope: str,
    question: str,
    top_k: int,
    document_ids: list[str] | None,
) -> list[dict]:
    embedding = embedding_function.embed_query(question)
    response = get_supabase_admin_client().rpc(
        "match_studybook_document_chunks",
        {
            "p_user_id": owner_scope,
            "p_query_embedding": embedding,
            "p_document_ids": document_ids,
            "p_match_count": top_k,
        },
    ).execute()
    return [dict(item) for item in (response.data or [])]


def normalize_text(text: str) -> str:
    return " ".join(
        text.replace("\x00", " ")
        .replace("\t", " ")
        .replace("\r", " ")
        .split()
    )


def generate_document_id(text: str) -> str:
    clean_text = normalize_text(text)

    if not clean_text:
        raise ValueError(
            "No se puede generar ID: el documento no contiene texto válido."
        )

    return hashlib.sha256(
        clean_text.encode("utf-8")
    ).hexdigest()[:24]


def generate_user_scoped_document_id(
    text: str,
    *,
    user_id: str,
) -> str:
    clean_user_id = user_id.strip()

    if not clean_user_id:
        raise ValueError("user_id es requerido para generar el ID.")

    content_id = generate_document_id(text)

    return hashlib.sha256(
        f"{clean_user_id}:{content_id}".encode("utf-8")
    ).hexdigest()[:24]


def create_document_chunks(text: str) -> list[str]:
    clean_text = normalize_text(text)

    if not clean_text:
        raise ValueError(
            "No se pueden crear chunks: el texto está vacío."
        )

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP,
        separators=[
            "\n\n",
            "\n",
            ". ",
            " ",
            "",
        ],
    )

    chunks = splitter.split_text(clean_text)

    return [
        chunk.strip()
        for chunk in chunks
        if chunk.strip()
    ]




def create_page_chunks(
    pages: list[dict],
) -> list[dict]:
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP,
        separators=[
            "\n\n",
            "\n",
            ". ",
            " ",
            "",
        ],
    )

    chunks: list[dict] = []

    for page in pages:
        page_number = int(page.get("page_number", 0))
        page_text = normalize_text(page.get("text", ""))

        if not page_text:
            continue

        page_chunks = splitter.split_text(page_text)

        for chunk in page_chunks:
            clean_chunk = chunk.strip()

            if clean_chunk:
                chunks.append(
                    {
                        "text": clean_chunk,
                        "page_number": page_number,
                    }
                )

    return chunks


def store_document_page_embeddings(
    pages: list[dict],
    *,
    owner_scope: str | None = None,
) -> str:
    full_text = " ".join(
        page.get("text", "")
        for page in pages
    )

    document_id = (
        generate_user_scoped_document_id(
            full_text,
            user_id=owner_scope,
        )
        if owner_scope
        else generate_document_id(full_text)
    )
    collection_name = get_collection_name(document_id)

    if collection_exists(collection_name, owner_scope=owner_scope):
        return document_id

    chunks = create_page_chunks(pages)

    if not chunks:
        raise ValueError(
            "No se generaron fragmentos válidos por página."
        )

    documents = [
        chunk["text"]
        for chunk in chunks
    ]

    embeddings = embedding_function.embed_documents(documents)

    if is_production_environment():
        _store_production_chunks(
            document_id=document_id,
            owner_scope=_required_owner_scope(owner_scope),
            chunks=chunks,
            embeddings=embeddings,
        )
        return document_id

    collection = client.create_collection(
        name=collection_name,
        metadata={
            "document_id": document_id,
            "chunk_size": CHUNK_SIZE,
            "chunk_overlap": CHUNK_OVERLAP,
            "page_aware": True,
        },
    )

    ids = [
        str(index)
        for index, _ in enumerate(documents)
    ]

    metadatas = [
        {
            "document_id": document_id,
            "chunk_index": index,
            "page_number": chunks[index]["page_number"],
        }
        for index, _ in enumerate(documents)
    ]

    collection.add(
        ids=ids,
        documents=documents,
        embeddings=embeddings,
        metadatas=metadatas,
    )

    return document_id


def get_collection_name(document_id: str) -> str:
    clean_id = document_id.strip()

    if not clean_id:
        raise ValueError(
            "document_id inválido."
        )

    return f"doc_{clean_id}"


def collection_exists(
    collection_name: str,
    *,
    owner_scope: str | None = None,
) -> bool:
    if is_production_environment():
        document_id = collection_name.removeprefix("doc_")
        return _production_document_exists(
            document_id=document_id,
            owner_scope=_required_owner_scope(owner_scope),
        )
    collections = client.list_collections()

    return any(
        collection.name == collection_name
        for collection in collections
    )


def delete_document_embeddings(
    document_id: str,
    *,
    owner_scope: str | None = None,
) -> bool:
    collection_name = get_collection_name(document_id)
    if is_production_environment():
        owner = _required_owner_scope(owner_scope)
        existed = _production_document_exists(
            document_id=document_id,
            owner_scope=owner,
        )
        (
            get_supabase_admin_client()
            .table(RAG_CHUNKS_TABLE)
            .delete()
            .eq("user_id", owner)
            .eq("document_id", document_id)
            .execute()
        )
        return existed
    if not collection_exists(collection_name):
        return False

    client.delete_collection(name=collection_name)
    return True


def store_document_embeddings(
    text: str,
    *,
    owner_scope: str | None = None,
) -> str:
    document_id = (
        generate_user_scoped_document_id(text, user_id=owner_scope)
        if owner_scope
        else generate_document_id(text)
    )
    collection_name = get_collection_name(document_id)

    if collection_exists(collection_name, owner_scope=owner_scope):
        return document_id

    chunks = create_document_chunks(text)

    if not chunks:
        raise ValueError(
            "No se generaron fragmentos válidos del documento."
        )

    embeddings = embedding_function.embed_documents(chunks)
    if is_production_environment():
        _store_production_chunks(
            document_id=document_id,
            owner_scope=_required_owner_scope(owner_scope),
            chunks=[{"text": chunk, "page_number": None} for chunk in chunks],
            embeddings=embeddings,
        )
        return document_id

    collection = client.create_collection(
        name=collection_name,
        metadata={
            "document_id": document_id,
            "chunk_size": CHUNK_SIZE,
            "chunk_overlap": CHUNK_OVERLAP,
        },
    )

    ids = [
        str(index)
        for index, _ in enumerate(chunks)
    ]

    metadatas = [
        {
            "document_id": document_id,
            "chunk_index": index,
        }
        for index, _ in enumerate(chunks)
    ]

    collection.add(
        ids=ids,
        documents=chunks,
        embeddings=embeddings,
        metadatas=metadatas,
    )

    return document_id


def search_similar_chunks(
    document_id: str,
    question: str,
    top_k: int = DEFAULT_TOP_K,
    owner_scope: str | None = None,
) -> str:
    clean_question = question.strip()

    if not clean_question:
        raise ValueError(
            "La pregunta está vacía."
        )

    if is_production_environment():
        rows = _query_production_chunks(
            owner_scope=_required_owner_scope(owner_scope),
            question=clean_question,
            top_k=top_k,
            document_ids=[document_id],
        )
        return "\n\n".join(
            f"[FUENTE document={document_id} chunk={row.get('chunk_index', index)}]\n"
            f"{str(row.get('content') or '').strip()}"
            for index, row in enumerate(rows)
            if str(row.get("content") or "").strip()
        )

    collection_name = get_collection_name(document_id)

    if not collection_exists(collection_name):
        raise ValueError(
            "El documento no está indexado en la base vectorial."
        )

    collection = client.get_collection(
        name=collection_name
    )

    question_embedding = embedding_function.embed_query(
        clean_question
    )

    results = collection.query(
        query_embeddings=[question_embedding],
        n_results=top_k,
        include=[
            "documents",
            "metadatas",
            "distances",
        ],
    )

    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]

    formatted_chunks: list[str] = []

    for index, document in enumerate(documents):
        if not document or not document.strip():
            continue

        metadata = (
            metadatas[index]
            if index < len(metadatas)
            else {}
        )

        chunk_index = metadata.get(
            "chunk_index",
            index,
        )

        formatted_chunks.append(
            f"[FUENTE document={document_id} chunk={chunk_index}]\n"
            f"{document.strip()}"
        )

    if not formatted_chunks:
        return ""

    return "\n\n".join(formatted_chunks)



def get_document_display_name(
    document_id: str,
    *,
    owner_scope: str | None = None,
) -> str:
    clean_document_id = document_id.strip()

    if not clean_document_id:
        return "Documento sin nombre"

    try:
        client = get_supabase_admin_client()

        query = (
            client
            .table("documents")
            .select("document_name,filename")
            .eq("document_id", clean_document_id)
            .not_.is_("filename", "null")
            .limit(1)
        )
        if owner_scope or is_production_environment():
            query = query.eq("user_id", _required_owner_scope(owner_scope))
        result = query.execute()

        if result.data:
            item = result.data[0]
            name = (
                item.get("document_name")
                or item.get("filename")
                or clean_document_id
            )
            return str(name).strip() or clean_document_id

    except Exception:
        pass

    return clean_document_id


def search_similar_chunks_multi(
    document_ids: list[str],
    question: str,
    top_k_per_document: int = 4,
    owner_scope: str | None = None,
) -> str:
    clean_question = question.strip()

    if not clean_question:
        raise ValueError(
            "La pregunta está vacía."
        )

    clean_document_ids = [
        document_id.strip()
        for document_id in document_ids
        if document_id and document_id.strip()
    ]

    if not clean_document_ids:
        raise ValueError(
            "No se recibieron documentos válidos."
        )

    contexts: list[str] = []

    for document_id in clean_document_ids:
        try:
            context = search_similar_chunks(
                document_id=document_id,
                question=clean_question,
                top_k=top_k_per_document,
                owner_scope=owner_scope,
            )

            if context.strip():
                document_name = get_document_display_name(
                    document_id,
                    owner_scope=owner_scope,
                )
                contexts.append(
                    f"[Documento: {document_name}]\n{context}"
                )

        except Exception as error:
            document_name = get_document_display_name(
                document_id,
                owner_scope=owner_scope,
            )
            contexts.append(
                f"[Documento: {document_name}]\nNo se pudo recuperar contexto: {error}"
            )

    valid_contexts = [
        context
        for context in contexts
        if context.strip()
    ]

    if not valid_contexts:
        return ""

    return "\n\n---\n\n".join(valid_contexts)


def semantic_search_all_documents(
    query: str,
    top_k_per_document: int = 3,
    max_results: int = 20,
    document_filter: Callable[[str], bool] | None = None,
    owner_scope: str | None = None,
) -> list[dict]:
    clean_query = query.strip()

    if not clean_query:
        raise ValueError(
            "La búsqueda está vacía."
        )

    if is_production_environment():
        rows = _query_production_chunks(
            owner_scope=_required_owner_scope(owner_scope),
            question=clean_query,
            top_k=max_results,
            document_ids=None,
        )
        return [
            {
                "document_id": row.get("document_id"),
                "chunk_index": row.get("chunk_index"),
                "distance": row.get("distance"),
                "preview": str(row.get("content") or "")[:700],
            }
            for row in rows
            if row.get("document_id")
            and (
                document_filter is None
                or document_filter(str(row.get("document_id")))
            )
        ][:max_results]

    query_embedding = embedding_function.embed_query(clean_query)

    results: list[dict] = []

    collections = client.list_collections()

    for collection_info in collections:
        collection_name = collection_info.name

        if not collection_name.startswith("doc_"):
            continue

        document_id = collection_name.replace(
            "doc_",
            "",
            1,
        )

        if document_filter is not None and not document_filter(document_id):
            continue

        try:
            collection = client.get_collection(
                name=collection_name
            )

            search_result = collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k_per_document,
                include=[
                    "documents",
                    "metadatas",
                    "distances",
                ],
            )

            documents = search_result.get("documents", [[]])[0]
            metadatas = search_result.get("metadatas", [[]])[0]
            distances = search_result.get("distances", [[]])[0]

            for index, document in enumerate(documents):
                if not document or not document.strip():
                    continue

                metadata = (
                    metadatas[index]
                    if index < len(metadatas)
                    else {}
                )

                distance = (
                    distances[index]
                    if index < len(distances)
                    else None
                )

                results.append(
                    {
                        "document_id": document_id,
                        "chunk_index": metadata.get(
                            "chunk_index",
                            index,
                        ),
                        "distance": distance,
                        "preview": document.strip()[:700],
                    }
                )

        except Exception:
            continue

    results.sort(
        key=lambda item: (
            item["distance"]
            if item["distance"] is not None
            else 999999
        )
    )

    return results[:max_results]



def get_source_chunk(
    document_id: str,
    chunk_index: int,
    owner_scope: str | None = None,
) -> dict:
    clean_document_id = document_id.strip()

    if not clean_document_id:
        raise ValueError(
            "document_id inválido."
        )

    if is_production_environment():
        response = (
            get_supabase_admin_client()
            .table(RAG_CHUNKS_TABLE)
            .select("document_id,chunk_index,page_number,content,metadata")
            .eq("user_id", _required_owner_scope(owner_scope))
            .eq("document_id", clean_document_id)
            .eq("chunk_index", chunk_index)
            .limit(1)
            .execute()
        )
        if not response.data:
            raise ValueError("No se encontro el fragmento solicitado.")
        row = dict(response.data[0])
        metadata = dict(row.get("metadata") or {})
        if row.get("page_number") is not None:
            metadata["page_number"] = row["page_number"]
        return {
            "document_id": clean_document_id,
            "chunk_index": chunk_index,
            "content": row.get("content") or "",
            "metadata": metadata,
        }

    collection_name = get_collection_name(
        clean_document_id,
    )

    if not collection_exists(collection_name):
        raise ValueError(
            "El documento no está indexado."
        )

    collection = client.get_collection(
        name=collection_name,
    )

    result = collection.get(
        ids=[str(chunk_index)],
        include=[
            "documents",
            "metadatas",
        ],
    )

    documents = result.get("documents", [])
    metadatas = result.get("metadatas", [])

    if not documents:
        raise ValueError(
            "No se encontró el chunk solicitado."
        )

    metadata = metadatas[0] if metadatas else {}

    return {
        "document_id": clean_document_id,
        "chunk_index": chunk_index,
        "content": documents[0],
        "metadata": metadata,
    }




def extract_best_highlight(
    document: str,
    question: str,
    max_characters: int = 420,
) -> str:
    clean_document = normalize_text(document)
    clean_question = normalize_text(question).lower()

    if not clean_document:
        return ""

    sentences = [
        sentence.strip()
        for sentence in clean_document.replace("?", ".").replace("!", ".").split(".")
        if sentence.strip()
    ]

    if not sentences:
        return clean_document[:max_characters]

    keywords = [
        word
        for word in clean_question.split()
        if len(word) >= 4
    ]

    scored: list[tuple[int, str]] = []

    for sentence in sentences:
        lower_sentence = sentence.lower()

        score = sum(
            1
            for keyword in keywords
            if keyword in lower_sentence
        )

        scored.append(
            (
                score,
                sentence,
            )
        )

    scored.sort(
        key=lambda item: item[0],
        reverse=True,
    )

    best_sentence = scored[0][1]

    if len(best_sentence) > max_characters:
        return best_sentence[:max_characters].strip()

    return best_sentence.strip()


def get_retrieval_citations(
    document_id: str,
    question: str,
    top_k: int = DEFAULT_TOP_K,
    owner_scope: str | None = None,
) -> list[dict]:
    clean_question = question.strip()

    if not clean_question:
        raise ValueError("La pregunta está vacía.")

    clean_document_id = document_id.strip()

    if is_production_environment():
        rows = _query_production_chunks(
            owner_scope=_required_owner_scope(owner_scope),
            question=clean_question,
            top_k=top_k,
            document_ids=[clean_document_id],
        )
        citations = []
        for index, row in enumerate(rows):
            document = str(row.get("content") or "").strip()
            if not document:
                continue
            page = row.get("page_number")
            citations.append(
                {
                    "document_id": clean_document_id,
                    "chunk_index": row.get("chunk_index", index),
                    "distance": row.get("distance"),
                    "page_number": page if isinstance(page, int) and page > 0 else None,
                    "preview": document[:240],
                    "highlight": extract_best_highlight(
                        document=document,
                        question=clean_question,
                    ),
                }
            )
        return citations

    collection_name = get_collection_name(clean_document_id)

    if not collection_exists(collection_name):
        raise ValueError("El documento no está indexado.")

    collection = client.get_collection(name=collection_name)

    question_embedding = embedding_function.embed_query(clean_question)

    results = collection.query(
        query_embeddings=[question_embedding],
        n_results=top_k,
        include=["documents", "metadatas", "distances"],
    )

    documents = results.get("documents", [[]])[0]
    metadatas = results.get("metadatas", [[]])[0]
    distances = results.get("distances", [[]])[0]

    citations: list[dict] = []

    for index, document in enumerate(documents):
        if not document or not document.strip():
            continue

        metadata = metadatas[index] if index < len(metadatas) else {}
        distance = distances[index] if index < len(distances) else None
        raw_page_number = metadata.get("page_number")
        page_number = (
            raw_page_number
            if isinstance(raw_page_number, int) and raw_page_number > 0
            else None
        )

        citations.append(
            {
                "document_id": clean_document_id,
                "chunk_index": metadata.get("chunk_index", index),
                "distance": distance,
                "page_number": page_number,
                "preview": document.strip()[:240],
                "highlight": extract_best_highlight(
                    document=document,
                    question=clean_question,
                ),
            }
        )

    return citations
