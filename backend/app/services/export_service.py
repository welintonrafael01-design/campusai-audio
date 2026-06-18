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


def build_final_report_pdf(
    *,
    title: str,
    course_name: str,
    rows: list[dict],
    stats: dict,
    footer: str = "Generado por StudyBook AI",
) -> bytes:
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=letter)

    width, height = letter
    margin_x = 32
    y = height - 42

    pdf.setTitle(title)

    def new_page():
        nonlocal y
        pdf.setFont("Helvetica-Oblique", 8)
        pdf.drawString(margin_x, 24, footer)
        pdf.showPage()
        y = height - 42

    pdf.setFont("Helvetica-Bold", 18)
    pdf.drawCentredString(width / 2, y, "STUDYBOOK AI")
    y -= 23

    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawCentredString(width / 2, y, "ACTA FINAL UNIVERSITARIA")
    y -= 26

    pdf.setFont("Helvetica", 9)
    pdf.drawString(margin_x, y, f"Curso / Sección: {course_name}")
    y -= 14
    pdf.drawString(
        margin_x,
        y,
        f"Fecha de emisión: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
    )
    y -= 20

    pdf.setFont("Helvetica-Bold", 8)
    pdf.drawString(margin_x, y, f"Total: {stats.get('students', 0)}")
    pdf.drawString(margin_x + 95, y, f"Promedio: {stats.get('average', '')}")
    pdf.drawString(margin_x + 210, y, f"Aprobados: {stats.get('approved', 0)}")
    pdf.drawString(margin_x + 330, y, f"Reprobados: {stats.get('failed', 0)}")
    y -= 22

    base_keys = [
        "student_code",
        "student_name",
        "course",
        "average",
        "attendance_rate",
        "evaluations",
        "attended_classes",
        "total_classes",
        "status",
    ]

    dynamic_keys = []
    for row in rows:
        for key in row.keys():
            if key not in base_keys and key not in dynamic_keys:
                dynamic_keys.append(key)

    dynamic_keys = dynamic_keys[:4]

    columns = [
        ("Código", "student_code", 32, 62),
        ("Estudiante", "student_name", 95, 150),
    ]

    x = 250
    for key in dynamic_keys:
        columns.append((key[:10], key, x, 52))
        x += 55

    columns.extend(
        [
            ("Prom.", "average", x, 48),
            ("Estado", "status", x + 55, 70),
        ]
    )

    def draw_header():
        nonlocal y
        pdf.setFont("Helvetica-Bold", 7)
        pdf.line(margin_x, y + 8, width - margin_x, y + 8)

        for label, _key, col_x, _w in columns:
            pdf.drawString(col_x, y, label)

        pdf.line(margin_x, y - 4, width - margin_x, y - 4)
        y -= 15

    draw_header()
    pdf.setFont("Helvetica", 7)

    for row in rows:
        if y < 65:
            new_page()
            draw_header()
            pdf.setFont("Helvetica", 7)

        for label, key, col_x, col_width in columns:
            value = str(row.get(key, ""))

            if key == "student_name":
                value = value[:32]
                pdf.drawString(col_x, y, value)
            elif key in ["average"] or key in dynamic_keys:
                pdf.drawRightString(col_x + col_width - 4, y, value[:8])
            else:
                pdf.drawString(col_x, y, value[:16])

        y -= 13

    y -= 24

    if y < 115:
        new_page()

    pdf.line(margin_x, y, width - margin_x, y)
    y -= 34

    pdf.setFont("Helvetica", 9)
    pdf.drawString(margin_x, y, "Firma docente: ________________________________")
    pdf.drawString(margin_x + 310, y, "Fecha: __________________")

    pdf.setFont("Helvetica-Oblique", 8)
    pdf.drawString(margin_x, 24, footer)

    pdf.save()
    buffer.seek(0)
    return buffer.read()



def build_teaching_plan_pdf(
    *,
    title: str,
    plan: dict,
    footer: str = "Generado por StudyBook AI",
) -> bytes:
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=letter)

    width, height = letter
    margin = 34
    blue = (0.02, 0.18, 0.43)
    light_blue = (0.92, 0.96, 1.0)
    gray = (0.35, 0.35, 0.35)

    pdf.setTitle(title)

    def text_value(key: str, default: str = "") -> str:
        value = plan.get(key, default)
        return str(value or "").strip()

    def list_value(key: str) -> list[str]:
        value = plan.get(key, [])
        if isinstance(value, list):
            return [str(item).strip() for item in value if str(item).strip()]
        return []

    def wrap_lines(text: str, width_chars: int = 70) -> list[str]:
        return textwrap.wrap(str(text or ""), width=width_chars) or [""]

    def draw_footer():
        pdf.setFont("Helvetica-Oblique", 7)
        pdf.setFillColorRGB(*gray)
        pdf.drawString(margin, 20, footer)

    def new_page():
        draw_footer()
        pdf.showPage()

    def draw_header():
        nonlocal_y = height - 38

        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 20)
        pdf.drawCentredString(width / 2, nonlocal_y, "PLANIFICACIÓN DOCENTE")

        pdf.setFont("Helvetica-Bold", 10)
        subtitle = text_value("title", title)
        for line in wrap_lines(subtitle, 70)[:2]:
            nonlocal_y -= 15
            pdf.drawCentredString(width / 2, nonlocal_y, line)

        pdf.setLineWidth(1.4)
        pdf.line(margin, nonlocal_y - 16, width - margin, nonlocal_y - 16)

        return nonlocal_y - 34

    def draw_label_value(x, y, label, value, w=120):
        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 7.5)
        pdf.drawString(x, y, label.upper())
        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 8)
        for i, line in enumerate(wrap_lines(value, 22)[:2]):
            pdf.drawString(x, y - 11 - (i * 10), line)

    def draw_section_box(x, y, w, title_text, body_lines, max_lines=9):
        box_h = 22 + min(len(body_lines), max_lines) * 10 + 10

        pdf.setFillColorRGB(*light_blue)
        pdf.rect(x, y - box_h + 8, w, box_h, fill=1, stroke=0)

        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 9)
        pdf.drawString(x + 10, y, title_text.upper())

        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 7.8)

        text_y = y - 15
        for line in body_lines[:max_lines]:
            pdf.drawString(x + 10, text_y, line[:82])
            text_y -= 10

        return y - box_h - 10

    def lines_from_list(items, width_chars=58):
        lines = []
        for item in items:
            wrapped = wrap_lines(item, width_chars)
            for idx, line in enumerate(wrapped):
                prefix = "• " if idx == 0 else "  "
                lines.append(prefix + line)
        return lines

    y = draw_header()

    subject = text_value("subject", "No especificada")
    weeks = plan.get("weeks", [])
    weeks_count = len(weeks) if isinstance(weeks, list) else 0

    draw_label_value(margin, y, "Asignatura", subject, 125)
    draw_label_value(margin + 145, y, "Duración", f"{weeks_count} semanas", 90)
    draw_label_value(margin + 260, y, "Fecha de emisión", datetime.now().strftime("%d/%m/%Y"), 110)
    draw_label_value(margin + 400, y, "Docente", "____________________", 130)

    y -= 55
    pdf.setStrokeColorRGB(0.75, 0.82, 0.92)
    pdf.line(margin, y, width - margin, y)
    y -= 22

    col_gap = 18
    col_w = (width - (2 * margin) - col_gap) / 2
    left_x = margin
    right_x = margin + col_w + col_gap
    left_y = y
    right_y = y

    general_objective = text_value("general_objective")
    if general_objective:
        left_y = draw_section_box(
            left_x,
            left_y,
            col_w,
            "Objetivo general",
            wrap_lines(general_objective, 58),
            max_lines=7,
        )

    competencies = list_value("competencies")
    if competencies:
        left_y = draw_section_box(
            left_x,
            left_y,
            col_w,
            "Competencias",
            lines_from_list(competencies, 52),
            max_lines=11,
        )

    resources = list_value("resources")
    if resources:
        left_y = draw_section_box(
            left_x,
            left_y,
            col_w,
            "Recursos",
            lines_from_list(resources, 52),
            max_lines=9,
        )

    methodology = text_value("methodology")
    if methodology:
        right_y = draw_section_box(
            right_x,
            right_y,
            col_w,
            "Metodología",
            wrap_lines(methodology, 58),
            max_lines=9,
        )

    evaluation = text_value("evaluation_strategy")
    if evaluation:
        right_y = draw_section_box(
            right_x,
            right_y,
            col_w,
            "Estrategia de evaluación",
            wrap_lines(evaluation, 58),
            max_lines=10,
        )

    recommendations = list_value("recommendations")
    if recommendations:
        right_y = draw_section_box(
            right_x,
            right_y,
            col_w,
            "Recomendaciones",
            lines_from_list(recommendations, 52),
            max_lines=9,
        )

    new_page()

    def draw_week_header(y, week_number, topic):
        pdf.setFillColorRGB(*blue)
        pdf.rect(margin, y - 17, 86, 18, fill=1, stroke=0)

        pdf.setFillColorRGB(1, 1, 1)
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawCentredString(margin + 43, y - 12, f"SEMANA {week_number}")

        pdf.setFillColorRGB(*light_blue)
        pdf.rect(margin + 86, y - 17, width - margin * 2 - 86, 18, fill=1, stroke=1)

        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawString(margin + 96, y - 12, str(topic)[:88])

        return y - 28

    def draw_week_row(y, label, items):
        row_h = 18
        lines = []

        if isinstance(items, list):
            lines = lines_from_list(items, 82)
        elif items:
            lines = wrap_lines(str(items), 82)

        if not lines:
            return y

        row_h = max(32, 16 + len(lines[:5]) * 9)

        if y - row_h < 42:
            new_page()
            y = height - 42

        pdf.setStrokeColorRGB(0.75, 0.82, 0.92)
        pdf.rect(margin, y - row_h, 110, row_h, fill=0, stroke=1)
        pdf.rect(margin + 110, y - row_h, width - margin * 2 - 110, row_h, fill=0, stroke=1)

        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawString(margin + 10, y - 18, label.upper())

        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 7.5)
        ty = y - 14
        for line in lines[:5]:
            pdf.drawString(margin + 122, ty, line[:100])
            ty -= 9

        return y - row_h

    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 14)
    pdf.drawCentredString(width / 2, height - 42, "CRONOGRAMA SEMANAL")
    y = height - 68

    if isinstance(weeks, list):
        for week in weeks:
            if not isinstance(week, dict):
                continue

            week_number = week.get("week", "")
            topic = week.get("topic", "")

            if y < 130:
                new_page()
                pdf.setFillColorRGB(*blue)
                pdf.setFont("Helvetica-Bold", 14)
                pdf.drawCentredString(width / 2, height - 42, "CRONOGRAMA SEMANAL")
                y = height - 68

            y = draw_week_header(y, week_number, topic)
            y = draw_week_row(y, "Objetivos", week.get("objectives", []))
            y = draw_week_row(y, "Contenidos", week.get("contents", []))
            y = draw_week_row(y, "Actividades", week.get("activities", []))
            y = draw_week_row(y, "Recursos", week.get("resources", []))
            y = draw_week_row(y, "Evaluación", week.get("assessment", ""))
            y -= 16

    draw_footer()
    pdf.save()
    buffer.seek(0)
    return buffer.read()
