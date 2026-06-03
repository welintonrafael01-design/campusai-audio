from dotenv import load_dotenv
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from pathlib import Path

import chromadb
import hashlib
import os


load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent.parent
CHROMA_PATH = BASE_DIR / "chroma_db"

CHROMA_PATH.mkdir(
    parents=True,
    exist_ok=True,
)

client = chromadb.PersistentClient(
    path=str(CHROMA_PATH)
)

embedding_function = OpenAIEmbeddings(
    api_key=os.getenv("OPENAI_API_KEY")
)

CHUNK_SIZE = 1200
CHUNK_OVERLAP = 200
DEFAULT_TOP_K = 5


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
) -> str:
    full_text = " ".join(
        page.get("text", "")
        for page in pages
    )

    document_id = generate_document_id(full_text)
    collection_name = get_collection_name(document_id)

    if collection_exists(collection_name):
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

    collection = client.create_collection(
        name=collection_name,
        metadata={
            "document_id": document_id,
            "chunk_size": CHUNK_SIZE,
            "chunk_overlap": CHUNK_OVERLAP,
            "page_aware": True,
        },
    )

    embeddings = embedding_function.embed_documents(
        documents
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


def collection_exists(collection_name: str) -> bool:
    collections = client.list_collections()

    return any(
        collection.name == collection_name
        for collection in collections
    )


def store_document_embeddings(text: str) -> str:
    document_id = generate_document_id(text)
    collection_name = get_collection_name(document_id)

    if collection_exists(collection_name):
        return document_id

    chunks = create_document_chunks(text)

    if not chunks:
        raise ValueError(
            "No se generaron fragmentos válidos del documento."
        )

    collection = client.create_collection(
        name=collection_name,
        metadata={
            "document_id": document_id,
            "chunk_size": CHUNK_SIZE,
            "chunk_overlap": CHUNK_OVERLAP,
        },
    )

    embeddings = embedding_function.embed_documents(chunks)

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
) -> str:
    clean_question = question.strip()

    if not clean_question:
        raise ValueError(
            "La pregunta está vacía."
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


def search_similar_chunks_multi(
    document_ids: list[str],
    question: str,
    top_k_per_document: int = 4,
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
            )

            if context.strip():
                contexts.append(
                    f"[Documento {document_id}]\n{context}"
                )

        except Exception as error:
            contexts.append(
                f"[Documento {document_id}]\nNo se pudo recuperar contexto: {error}"
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
) -> list[dict]:
    clean_query = query.strip()

    if not clean_query:
        raise ValueError(
            "La búsqueda está vacía."
        )

    query_embedding = embedding_function.embed_query(
        clean_query
    )

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
) -> dict:
    clean_document_id = document_id.strip()

    if not clean_document_id:
        raise ValueError(
            "document_id inválido."
        )

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
) -> list[dict]:
    clean_question = question.strip()

    if not clean_question:
        raise ValueError("La pregunta está vacía.")

    clean_document_id = document_id.strip()

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

        citations.append(
            {
                "document_id": clean_document_id,
                "chunk_index": metadata.get("chunk_index", index),
                "distance": distance,
                "preview": document.strip()[:240],
                "highlight": extract_best_highlight(
                    document=document,
                    question=clean_question,
                ),
            }
        )

    return citations
