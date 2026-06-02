from __future__ import annotations

import textwrap
from datetime import datetime
from io import BytesIO

from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas


def build_text_pdf(
    *,
    title: str,
    content: str,
    footer: str = "Generado por StudyBook AI",
) -> bytes:
    buffer = BytesIO()

    pdf = canvas.Canvas(
        buffer,
        pagesize=letter,
    )

    width, height = letter

    margin_x = 54
    y = height - 54

    pdf.setTitle(title)

    pdf.setFont("Helvetica-Bold", 16)
    pdf.drawString(margin_x, y, title[:90])

    y -= 28

    pdf.setFont("Helvetica", 9)
    pdf.drawString(
        margin_x,
        y,
        datetime.now().strftime("%Y-%m-%d %H:%M"),
    )

    y -= 28

    pdf.setFont("Helvetica", 11)

    clean_content = (content or "").strip()

    if not clean_content:
        clean_content = "Sin contenido para exportar."

    for paragraph in clean_content.splitlines():
        paragraph = paragraph.strip()

        if not paragraph:
            y -= 10
            continue

        lines = textwrap.wrap(
            paragraph,
            width=88,
        )

        for line in lines:
            if y < 72:
                pdf.setFont("Helvetica-Oblique", 8)
                pdf.drawString(margin_x, 36, footer)
                pdf.showPage()
                y = height - 54
                pdf.setFont("Helvetica", 11)

            pdf.drawString(margin_x, y, line)
            y -= 15

        y -= 6

    pdf.setFont("Helvetica-Oblique", 8)
    pdf.drawString(margin_x, 36, footer)

    pdf.save()

    buffer.seek(0)
    return buffer.read()
