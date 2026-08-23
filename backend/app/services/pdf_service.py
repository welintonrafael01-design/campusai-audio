from pathlib import Path

import fitz
import pytesseract

from PIL import Image


MAX_CHARACTERS = 120000
MIN_OCR_CONFIDENCE = 45.0


def prepare_page_image_for_ocr(page) -> Image.Image:
    pix = page.get_pixmap(
        matrix=fitz.Matrix(2, 2),
        alpha=False,
    )

    image = Image.frombytes(
        "RGB",
        [pix.width, pix.height],
        pix.samples,
    )

    rotation = int(page.rotation or 0) % 360
    if rotation:
        image = image.rotate(rotation, expand=True)

    return image


def extract_text_with_ocr(page) -> str:
    image = prepare_page_image_for_ocr(page)
    data = pytesseract.image_to_data(
        image,
        lang="eng+spa",
        output_type=pytesseract.Output.DICT,
    )

    lines: dict[tuple[int, int, int], list[str]] = {}
    confidences: list[float] = []

    for index, raw_word in enumerate(data.get("text", [])):
        word = str(raw_word).strip()
        if not word:
            continue

        line_key = (
            int(data["block_num"][index]),
            int(data["par_num"][index]),
            int(data["line_num"][index]),
        )
        lines.setdefault(line_key, []).append(word)

        try:
            confidence = float(data["conf"][index])
        except (TypeError, ValueError):
            continue

        if confidence >= 0:
            confidences.append(confidence)

    average_confidence = (
        sum(confidences) / len(confidences)
        if confidences
        else 0.0
    )

    if not lines or average_confidence < MIN_OCR_CONFIDENCE:
        raise ValueError(
            "La calidad OCR del PDF es insuficiente para generar contenido fiable."
        )

    return "\n".join(
        " ".join(words)
        for words in lines.values()
    )


def extract_text_from_pdf(pdf_path: str) -> str:
    path = Path(pdf_path)

    if not path.exists():
        raise FileNotFoundError(
            f"No se encontró el archivo PDF: {pdf_path}"
        )

    text = ""

    try:
        with fitz.open(pdf_path) as document:

            if document.page_count == 0:
                raise ValueError(
                    "El PDF no contiene páginas."
                )

            for page in document:

                # =====================================================
                # TEXTO NORMAL
                # =====================================================
                page_text = page.get_text()

                if page_text and page_text.strip():
                    text += page_text + "\n"
                    continue

                # =====================================================
                # OCR FALLBACK
                # =====================================================
                ocr_text = extract_text_with_ocr(page)

                if ocr_text:
                    text += ocr_text + "\n"

    except Exception as error:
        raise Exception(
            f"Error leyendo PDF: {error}"
        )

    clean = normalize_text(text)

    if not clean.strip():
        raise ValueError(
            "No se pudo extraer texto del PDF."
        )

    return clean[:MAX_CHARACTERS]


def normalize_text(text: str) -> str:
    return (
        text.replace("\x00", "")
        .replace("\t", " ")
        .replace("\r", " ")
        .strip()
    )



def extract_pages_from_pdf(pdf_path: str) -> list[dict]:
    path = Path(pdf_path)

    if not path.exists():
        raise FileNotFoundError(
            f"No se encontró el archivo PDF: {pdf_path}"
        )

    pages: list[dict] = []

    try:
        with fitz.open(pdf_path) as document:

            if document.page_count == 0:
                raise ValueError(
                    "El PDF no contiene páginas."
                )

            for page_index, page in enumerate(document):
                page_number = page_index + 1

                page_text = page.get_text()

                if not page_text or not page_text.strip():
                    page_text = extract_text_with_ocr(page)

                clean_text = normalize_text(page_text or "")

                if clean_text.strip():
                    pages.append(
                        {
                            "page_number": page_number,
                            "text": clean_text,
                        }
                    )

    except Exception as error:
        raise Exception(
            f"Error leyendo páginas del PDF: {error}"
        )

    if not pages:
        raise ValueError(
            "No se pudo extraer texto por páginas del PDF."
        )

    return pages
