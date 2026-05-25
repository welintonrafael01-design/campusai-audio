from pathlib import Path

import fitz
import pytesseract

from PIL import Image


MAX_CHARACTERS = 120000


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
                pix = page.get_pixmap(
                    matrix=fitz.Matrix(2, 2)
                )

                image = Image.frombytes(
                    "RGB",
                    [pix.width, pix.height],
                    pix.samples,
                )

                ocr_text = pytesseract.image_to_string(
                    image,
                    lang="eng+spa",
                )

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
