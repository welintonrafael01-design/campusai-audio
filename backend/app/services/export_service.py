from __future__ import annotations

import textwrap
from datetime import datetime
from io import BytesIO
from urllib.parse import quote

import qrcode

from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader

from app.public_urls import configured_app_web_origin


def public_verification_url(record_id: str) -> str:
    app_origin = configured_app_web_origin()
    if app_origin is None:
        app_origin = "http://localhost:3000"
    return f"{app_origin}/#/verify/{quote(str(record_id), safe='')}"


def build_text_pdf(
    *,
    title: str,
    content: str,
    footer: str = "Generado por StudyBook AI",
) -> bytes:
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=letter)

    width, height = letter
    margin_x = 54
    y = height - 54

    blue = (0.02, 0.18, 0.43)
    accent = (0.38, 0.32, 0.95)
    light = (0.95, 0.97, 1.00)
    gray = (0.35, 0.35, 0.35)

    pdf.setTitle(title)

    def draw_header():
        nonlocal y
        pdf.setFillColorRGB(*blue)
        pdf.rect(0, height - 90, width, 90, fill=1, stroke=0)

        pdf.setFillColorRGB(1, 1, 1)
        pdf.setFont("Helvetica-Bold", 18)
        pdf.drawString(margin_x, height - 42, "STUDYBOOK AI")

        pdf.setFont("Helvetica-Bold", 13)
        pdf.drawString(margin_x, height - 66, title[:90])

        pdf.setFont("Helvetica", 8)
        pdf.drawRightString(
            width - margin_x,
            height - 42,
            datetime.now().strftime("%Y-%m-%d %H:%M"),
        )

        y = height - 120

    def draw_footer():
        pdf.setFillColorRGB(*gray)
        pdf.setFont("Helvetica-Oblique", 8)
        pdf.drawString(margin_x, 28, footer)

    def new_page():
        nonlocal y
        draw_footer()
        pdf.showPage()
        draw_header()

    draw_header()

    clean_content = (content or "").strip()
    if not clean_content:
        clean_content = "Sin contenido para exportar."

    blocks = [
        item.strip()
        for item in clean_content.split("-----------------------------")
        if item.strip()
    ]

    if not blocks:
        blocks = [clean_content]

    for index, block in enumerate(blocks, start=1):
        lines = []
        for paragraph in block.splitlines():
            paragraph = paragraph.strip()
            if not paragraph:
                continue
            lines.extend(textwrap.wrap(paragraph, width=82))

        card_height = max(54, 22 + len(lines) * 14)

        if y - card_height < 70:
            new_page()

        pdf.setFillColorRGB(*light)
        pdf.setStrokeColorRGB(*accent)
        pdf.setLineWidth(0.7)
        pdf.roundRect(
            margin_x - 8,
            y - card_height + 10,
            width - (margin_x * 2) + 16,
            card_height,
            9,
            fill=1,
            stroke=1,
        )

        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 10)
        pdf.drawString(margin_x, y, f"Registro #{index}")

        y -= 18
        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 9)

        for line in lines:
            if y < 70:
                new_page()
                pdf.setFont("Helvetica", 9)
            pdf.drawString(margin_x, y, line)
            y -= 14

        y -= 18

    draw_footer()
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

    if y < 190:
        new_page()

    pdf.line(margin_x, y, width - margin_x, y)
    y -= 30

    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(margin_x, y, "Validación y firmas")
    y -= 26

    pdf.setFont("Helvetica", 9)
    pdf.drawString(margin_x, y, "Docente: ______________________________________")
    pdf.drawString(margin_x + 330, y, "Fecha: __________________")
    y -= 28

    pdf.drawString(margin_x, y, "Firma docente: ________________________________")
    pdf.drawString(margin_x + 330, y, "Sello institucional:")
    y -= 18

    pdf.rect(margin_x + 330, y - 45, 120, 55, fill=0, stroke=1)
    y -= 34

    pdf.drawString(margin_x, y, "Coordinador académico: ________________________")
    y -= 28

    pdf.drawString(margin_x, y, "Director / Encargado académico: _______________")
    y -= 26

    pdf.setFont("Helvetica-Oblique", 7)
    for line in textwrap.wrap(
        "Observación: Esta acta se genera automáticamente a partir del Libro de Calificaciones y registros académicos del curso.",
        width=110,
    ):
        pdf.drawString(margin_x, y, line)
        y -= 10

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


def build_rubric_pdf(
    *,
    title: str,
    rubric: dict,
    student: dict | None = None,
    scores: dict | None = None,
    observations: dict | None = None,
    footer: str = "Generado por StudyBook AI",
) -> bytes:
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=letter)

    width, height = letter
    margin = 34
    blue = (0.02, 0.18, 0.43)
    light_blue = (0.92, 0.96, 1.0)
    gray = (0.35, 0.35, 0.35)

    student = student or {}
    scores = scores or {}
    observations = observations or {}

    pdf.setTitle(title)

    def wrap_lines(text: str, width_chars: int = 70) -> list[str]:
        return textwrap.wrap(str(text or ""), width=width_chars) or [""]

    def draw_footer():
        pdf.setFont("Helvetica-Oblique", 7)
        pdf.setFillColorRGB(*gray)
        pdf.drawString(margin, 20, footer)

    def new_page():
        draw_footer()
        pdf.showPage()

    def text_value(data: dict, key: str, default: str = "") -> str:
        return str(data.get(key, default) or "").strip()

    def draw_header():
        y = height - 38
        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 20)
        pdf.drawCentredString(width / 2, y, "RÚBRICA DE EVALUACIÓN")
        y -= 16

        pdf.setFont("Helvetica-Bold", 10)
        subtitle = text_value(rubric, "title", title)
        for line in wrap_lines(subtitle, 70)[:2]:
            pdf.drawCentredString(width / 2, y, line)
            y -= 13

        pdf.setLineWidth(1.4)
        pdf.line(margin, y - 4, width - margin, y - 4)
        return y - 22

    def draw_label_value(x, y, label, value):
        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 7.5)
        pdf.drawString(x, y, label.upper())
        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 8)
        for i, line in enumerate(wrap_lines(value, 24)[:2]):
            pdf.drawString(x, y - 11 - (i * 10), line)

    y = draw_header()

    total_points = rubric.get("total_points", 100)
    rubric_type = rubric.get("rubric_type", "Académica")
    criteria = rubric.get("criteria", [])
    if not isinstance(criteria, list):
        criteria = []

    assigned_total = 0.0
    for value in scores.values():
        try:
            assigned_total += float(value)
        except Exception:
            pass

    draw_label_value(margin, y, "Estudiante", text_value(student, "name", "No especificado"))
    draw_label_value(margin + 155, y, "Código", text_value(student, "studentCode", "N/D"))
    draw_label_value(margin + 260, y, "Curso", text_value(student, "course", "No especificado"))
    draw_label_value(margin + 405, y, "Tipo", str(rubric_type))

    y -= 46

    pdf.setFillColorRGB(*light_blue)
    pdf.rect(margin, y - 26, width - margin * 2, 30, fill=1, stroke=0)

    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(margin + 10, y - 8, f"Puntaje obtenido: {assigned_total:.1f} / {total_points}")
    pdf.drawRightString(width - margin - 10, y - 8, f"Fecha: {datetime.now().strftime('%d/%m/%Y')}")

    y -= 48

    def draw_criterion(criterion_index: int, item: dict, y: float) -> float:
        if y < 170:
            new_page()
            y = height - 42

        criterion_title = text_value(item, "criterion", f"Criterio {criterion_index + 1}")
        description = text_value(item, "description", "")
        max_points = item.get("points", 0)
        assigned = scores.get(str(criterion_index), scores.get(criterion_index, ""))
        observation = observations.get(str(criterion_index), observations.get(criterion_index, ""))

        pdf.setFillColorRGB(*blue)
        pdf.rect(margin, y - 18, width - margin * 2, 20, fill=1, stroke=0)

        pdf.setFillColorRGB(1, 1, 1)
        pdf.setFont("Helvetica-Bold", 8)
        pdf.drawString(margin + 10, y - 12, f"CRITERIO {criterion_index + 1}: {criterion_title[:74]}")
        pdf.drawRightString(width - margin - 10, y - 12, f"{assigned} / {max_points} pts")

        y -= 30

        if description:
            pdf.setFillColorRGB(0, 0, 0)
            pdf.setFont("Helvetica", 7.8)
            for line in wrap_lines(description, 95)[:3]:
                pdf.drawString(margin + 8, y, line)
                y -= 10
            y -= 4

        levels = item.get("levels", {})
        if isinstance(levels, dict) and levels:
            level_items = list(levels.items())

            col_w = (width - margin * 2) / min(len(level_items), 4)
            x = margin
            shown = level_items[:4]

            max_lines = 0
            prepared = []
            for level_key, level_text in shown:
                label = {
                    "excellent": "Excelente",
                    "good": "Bueno",
                    "basic": "Básico",
                    "insufficient": "Insuficiente",
                }.get(str(level_key), str(level_key).replace("_", " ").title())

                lines = wrap_lines(level_text, 24)[:5]
                max_lines = max(max_lines, len(lines))
                prepared.append((label, lines))

            row_h = 25 + max_lines * 9

            if y - row_h < 55:
                new_page()
                y = height - 42

            for label, lines in prepared:
                pdf.setFillColorRGB(*light_blue)
                pdf.rect(x, y - row_h, col_w, row_h, fill=1, stroke=1)

                pdf.setFillColorRGB(*blue)
                pdf.setFont("Helvetica-Bold", 7)
                pdf.drawCentredString(x + col_w / 2, y - 11, label)

                pdf.setFillColorRGB(0, 0, 0)
                pdf.setFont("Helvetica", 6.8)

                ty = y - 23
                for line in lines:
                    pdf.drawString(x + 5, ty, line[:32])
                    ty -= 9

                x += col_w

            y -= row_h + 12

        if str(observation).strip():
            if y < 80:
                new_page()
                y = height - 42

            pdf.setFillColorRGB(0, 0, 0)
            pdf.setFont("Helvetica-Bold", 7.5)
            pdf.drawString(margin, y, "OBSERVACIÓN")
            y -= 10
            pdf.setFont("Helvetica", 7.2)
            for line in wrap_lines(str(observation), 98)[:4]:
                pdf.drawString(margin + 8, y, line)
                y -= 9

        return y - 14

    for idx, item in enumerate(criteria):
        if isinstance(item, dict):
            y = draw_criterion(idx, item, y)

    recommendations = rubric.get("recommendations", [])
    if isinstance(recommendations, list) and recommendations:
        if y < 130:
            new_page()
            y = height - 42

        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 9)
        pdf.drawString(margin, y, "RECOMENDACIONES")
        y -= 12

        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 7.5)
        for rec in recommendations[:6]:
            for line in wrap_lines(f"• {rec}", 95)[:2]:
                pdf.drawString(margin + 8, y, line)
                y -= 9

    if y < 95:
        new_page()
        y = height - 42

    y -= 22
    pdf.setStrokeColorRGB(0.75, 0.82, 0.92)
    pdf.line(margin, y, width - margin, y)
    y -= 28

    pdf.setFillColorRGB(0, 0, 0)
    pdf.setFont("Helvetica", 8)
    pdf.drawString(margin, y, "Firma docente: ________________________________")
    pdf.drawString(margin + 310, y, "Fecha: __________________")

    draw_footer()
    pdf.save()
    buffer.seek(0)
    return buffer.read()


def build_exam_pdf(
    *,
    title: str,
    questions: list[dict],
    include_answers: bool = False,
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

    def wrap_lines(text: str, width_chars: int = 86) -> list[str]:
        return textwrap.wrap(str(text or ""), width=width_chars) or [""]

    def get_text(item: dict, *keys: str, default: str = "") -> str:
        for key in keys:
            value = item.get(key)
            if value is not None and str(value).strip():
                return str(value).strip()
        return default

    def get_options(item: dict) -> dict:
        options = item.get("options") or item.get("opciones") or {}
        return options if isinstance(options, dict) else {}

    def draw_footer():
        pdf.setFont("Helvetica-Oblique", 7)
        pdf.setFillColorRGB(*gray)
        pdf.drawString(margin, 20, footer)

    def new_page():
        draw_footer()
        pdf.showPage()

    def draw_header():
        y = height - 38
        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 11)
        pdf.drawString(margin, y, "STUDYBOOK AI")
        pdf.setFont("Helvetica", 8)
        pdf.drawString(margin, y - 12, "Sistema Inteligente de Evaluación Académica")

        pdf.setFont("Helvetica-Bold", 20)
        pdf.drawCentredString(
            width / 2,
            y - 2,
            "CLAVE DOCENTE" if include_answers else "EXAMEN ACADÉMICO",
        )
        y -= 26

        pdf.setFont("Helvetica-Bold", 10)
        for line in wrap_lines(title, 76)[:2]:
            pdf.drawCentredString(width / 2, y, line)
            y -= 13

        if questions:
            first = questions[0]
            meta = [
                ("Tipo", get_text(first, "exam_type", "question_type")),
                ("Nivel", get_text(first, "exam_difficulty", "difficulty")),
                ("Bloom", get_text(first, "bloom_level")),
                ("Versión", get_text(first, "exam_version")),
                ("Valor", f"{get_text(first, 'exam_total_points', default='100')} puntos"),
            ]

            y -= 10
            pdf.setFillColorRGB(*light_blue)
            pdf.roundRect(margin, y - 42, width - margin * 2, 42, 10, fill=1, stroke=0)
            pdf.setFillColorRGB(*blue)
            pdf.setFont("Helvetica-Bold", 8)

            x = margin + 12
            for label, value in meta:
                if str(value).strip():
                    pdf.drawString(x, y - 16, f"{label}:")
                    pdf.setFont("Helvetica", 8)
                    pdf.drawString(x, y - 29, str(value)[:24])
                    pdf.setFont("Helvetica-Bold", 8)
                    x += 105

            y -= 62

        if not include_answers:
            pdf.setFillColorRGB(0, 0, 0)
            pdf.setFont("Helvetica-Bold", 9)
            pdf.drawString(margin, y, "Datos del estudiante")
            y -= 16

            pdf.setFont("Helvetica", 9)
            pdf.drawString(margin, y, "Nombre: ________________________________________________")
            pdf.drawString(margin + 310, y, "Matrícula: __________________")
            y -= 18
            pdf.drawString(margin, y, "Sección: ________________________________________________")
            pdf.drawString(margin + 310, y, "Calificación: _______________")
            y -= 26

        return y

    def ensure_space(y: int, needed: int = 100) -> int:
        if y < needed:
            new_page()
            return draw_header()
        return y

    y = draw_header()

    for index, item in enumerate(questions, start=1):
        q_type = get_text(item, "question_type", "tipo", "type", default="Pregunta")
        question = get_text(item, "question", "pregunta", "text", "enunciado", "prompt")
        answer = get_text(item, "correct_answer", "answer", "respuesta", "respuesta_correcta")
        explanation = get_text(item, "explanation", "explicacion")
        topic = get_text(item, "topic", "tema")
        options = get_options(item)

        y = ensure_space(y, 145)

        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 12)
        pdf.drawString(margin, y, f"Pregunta {index}")
        pdf.setFont("Helvetica", 8)
        pdf.setFillColorRGB(*gray)
        pdf.drawRightString(width - margin, y, q_type)
        y -= 16

        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 10)
        for line in wrap_lines(question, 92):
            y = ensure_space(y, 80)
            pdf.drawString(margin, y, line)
            y -= 13

        if topic:
            y -= 3
            pdf.setFillColorRGB(*gray)
            pdf.setFont("Helvetica-Oblique", 8)
            for line in wrap_lines(f"Tema: {topic}", 92):
                pdf.drawString(margin, y, line)
                y -= 11

        if options:
            y -= 5
            pdf.setFillColorRGB(0, 0, 0)
            pdf.setFont("Helvetica", 9)
            for key in ["A", "B", "C", "D"]:
                value = options.get(key)
                if value is None:
                    continue
                for line in wrap_lines(f"{key}. {value}", 88):
                    y = ensure_space(y, 75)
                    pdf.drawString(margin + 14, y, line)
                    y -= 12
        else:
            y -= 6
            pdf.setFillColorRGB(*gray)
            pdf.setFont("Helvetica", 9)
            for line in wrap_lines("Respuesta: ________________________________________________", 88)[:1]:
                pdf.drawString(margin + 14, y, line)
                y -= 14
            for _ in range(3):
                pdf.drawString(margin + 14, y, "____________________________________________________________")
                y -= 14

        if include_answers:
            competence = get_text(item, "competence", "competencia", "learning_outcome", "resultado_aprendizaje")
            bloom = get_text(item, "bloom_level", "nivel_bloom")
            difficulty = get_text(item, "exam_difficulty", "difficulty", "dificultad")

            y -= 6
            y = ensure_space(y, 145)
            pdf.setFillColorRGB(0.88, 0.96, 0.90)
            pdf.roundRect(margin, y - 118, width - margin * 2, 118, 8, fill=1, stroke=0)

            pdf.setFillColorRGB(0.05, 0.30, 0.10)
            pdf.setFont("Helvetica-Bold", 9)
            pdf.drawString(margin + 10, y - 15, "CLAVE DOCENTE")
            yy = y - 30

            pdf.setFont("Helvetica-Bold", 8)
            pdf.drawString(margin + 10, yy, "Respuesta correcta / modelo:")
            yy -= 11
            pdf.setFont("Helvetica", 8)
            for line in wrap_lines(answer or "No especificada", 90)[:3]:
                pdf.drawString(margin + 10, yy, line)
                yy -= 10

            if explanation:
                yy -= 2
                pdf.setFont("Helvetica-Bold", 8)
                pdf.drawString(margin + 10, yy, "Explicación:")
                yy -= 11
                pdf.setFont("Helvetica", 8)
                for line in wrap_lines(explanation, 90)[:3]:
                    pdf.drawString(margin + 10, yy, line)
                    yy -= 10

            meta = []
            if competence:
                meta.append(f"Competencia: {competence}")
            if bloom:
                meta.append(f"Bloom: {bloom}")
            if difficulty:
                meta.append(f"Dificultad: {difficulty}")

            if meta:
                yy -= 2
                pdf.setFont("Helvetica-Bold", 8)
                pdf.drawString(margin + 10, yy, "Metadatos pedagógicos:")
                yy -= 11
                pdf.setFont("Helvetica", 8)
                for line in wrap_lines(" | ".join(meta), 90)[:2]:
                    pdf.drawString(margin + 10, yy, line)
                    yy -= 10

            y -= 132

        y -= 12

    draw_footer()
    pdf.save()
    buffer.seek(0)
    return buffer.read()



def build_certificate_pdf(
    *,
    student_name: str,
    student_code: str,
    course_name: str,
    average: str,
    period: str = "",
    certificate_id: str = "",
    certificate_title: str = "CERTIFICADO ACADÉMICO",
    footer: str = "Generado por StudyBook AI",
) -> bytes:
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=letter)

    width, height = letter
    margin = 46
    blue = (0.02, 0.18, 0.43)
    accent = (0.38, 0.32, 0.95)
    light = (0.95, 0.97, 1.00)
    gray = (0.35, 0.35, 0.35)

    title = certificate_title.strip() or "CERTIFICADO ACADÉMICO"

    pdf.setTitle(title)

    # Fondo y marco
    pdf.setFillColorRGB(1, 1, 1)
    pdf.rect(0, 0, width, height, fill=1, stroke=0)

    pdf.setStrokeColorRGB(*blue)
    pdf.setLineWidth(3)
    pdf.roundRect(margin, margin, width - margin * 2, height - margin * 2, 16)

    pdf.setStrokeColorRGB(*accent)
    pdf.setLineWidth(1)
    pdf.roundRect(margin + 10, margin + 10, width - (margin + 10) * 2, height - (margin + 10) * 2, 12)

    # Header
    y = height - 105
    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 26)
    pdf.drawCentredString(width / 2, y, "STUDYBOOK AI")
    y -= 28

    pdf.setFillColorRGB(*gray)
    pdf.setFont("Helvetica", 10)
    pdf.drawCentredString(width / 2, y, "Sistema de Certificación Académica Verificable")
    y -= 40

    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 20)
    pdf.drawCentredString(width / 2, y, title[:80])
    y -= 36

    # Banda central
    pdf.setFillColorRGB(*light)
    pdf.roundRect(margin + 34, y - 210, width - (margin + 34) * 2, 210, 12, fill=1, stroke=0)

    pdf.setFillColorRGB(0, 0, 0)
    pdf.setFont("Helvetica", 12)
    pdf.drawCentredString(width / 2, y - 30, "Se certifica que")

    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 23)
    pdf.drawCentredString(width / 2, y - 70, student_name[:72])

    pdf.setFillColorRGB(0, 0, 0)
    pdf.setFont("Helvetica", 10)
    if student_code:
        pdf.drawCentredString(width / 2, y - 95, f"Código / Matrícula: {student_code}")

    pdf.setFont("Helvetica", 12)
    pdf.drawCentredString(width / 2, y - 128, "ha completado satisfactoriamente:")

    pdf.setFont("Helvetica-Bold", 15)
    pdf.drawCentredString(width / 2, y - 158, course_name[:82])

    pdf.setFont("Helvetica", 11)
    pdf.drawCentredString(width / 2, y - 185, f"Promedio final: {average}")

    if period:
        pdf.drawCentredString(width / 2, y - 204, f"Período académico: {period}")

    # Código y fecha
    y = 275
    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 10)

    if certificate_id:
        pdf.drawString(margin + 34, y, f"Código de validación: {certificate_id}")
    else:
        pdf.drawString(margin + 34, y, "Código de validación: No especificado")

    pdf.drawRightString(
        width - margin - 34,
        y,
        f"Fecha de emisión: {datetime.now().strftime('%d/%m/%Y')}",
    )

    # QR y URL pública
    if certificate_id:
        verification_url = public_verification_url(certificate_id)

        qr = qrcode.make(verification_url)
        qr_buffer = BytesIO()
        qr.save(qr_buffer, format="PNG")
        qr_buffer.seek(0)

        pdf.drawImage(
            ImageReader(qr_buffer),
            width / 2 - 45,
            145,
            width=90,
            height=90,
            mask="auto",
        )

        pdf.setFont("Helvetica", 8)
        pdf.setFillColorRGB(*gray)
        pdf.drawCentredString(width / 2, 132, "Escanee el QR para verificar la autenticidad.")
        pdf.drawCentredString(width / 2, 120, verification_url)

    # Firmas
    y = 105
    pdf.setStrokeColorRGB(*blue)
    pdf.line(105, y, 260, y)
    pdf.line(350, y, 505, y)
    y -= 15

    pdf.setFillColorRGB(*gray)
    pdf.setFont("Helvetica", 9)
    pdf.drawCentredString(182, y, "Firma docente")
    pdf.drawCentredString(427, y, "Coordinación académica")

    pdf.setFont("Helvetica-Bold", 8)
    pdf.setFillColorRGB(*blue)
    pdf.drawString(margin, 28, footer)

    pdf.save()
    buffer.seek(0)
    return buffer.read()


def build_academic_badge_pdf(
    *,
    student_name: str,
    student_code: str = "",
    course_name: str,
    badge_title: str = "Curso Aprobado",
    average: str = "",
    certificate_id: str = "",
    footer: str = "Generado por StudyBook AI",
) -> bytes:
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=letter)

    width, height = letter
    blue = (0.02, 0.18, 0.43)
    accent = (0.38, 0.32, 0.95)
    gold = (0.95, 0.68, 0.18)
    light = (0.95, 0.97, 1.00)
    gray = (0.35, 0.35, 0.35)

    title = badge_title.strip() or "Insignia Académica"

    pdf.setTitle("Insignia académica premium")

    pdf.setFillColorRGB(*blue)
    pdf.rect(0, 0, width, height, fill=1, stroke=0)

    pdf.setStrokeColorRGB(1, 1, 1)
    pdf.setLineWidth(2.2)
    pdf.roundRect(42, 42, width - 84, height - 84, 18)

    pdf.setStrokeColorRGB(*gold)
    pdf.setLineWidth(1.3)
    pdf.roundRect(55, 55, width - 110, height - 110, 14)

    y = height - 78
    pdf.setFillColorRGB(1, 1, 1)
    pdf.setFont("Helvetica-Bold", 23)
    pdf.drawCentredString(width / 2, y, "STUDYBOOK AI")
    y -= 17

    pdf.setFont("Helvetica", 8.5)
    pdf.drawCentredString(width / 2, y, "Reconocimiento Oficial Verificable")

    medal_x = width / 2
    medal_y = height - 205

    pdf.setFillColorRGB(1, 1, 1)
    pdf.circle(medal_x, medal_y, 80, fill=1, stroke=0)

    pdf.setFillColorRGB(*gold)
    pdf.circle(medal_x, medal_y, 64, fill=1, stroke=0)

    pdf.setFillColorRGB(*accent)
    pdf.circle(medal_x, medal_y, 48, fill=1, stroke=0)

    pdf.setFillColorRGB(1, 1, 1)
    pdf.setFont("Helvetica-Bold", 42)
    pdf.drawCentredString(medal_x, medal_y - 14, "★")

    y = height - 330
    pdf.setFillColorRGB(1, 1, 1)
    pdf.setFont("Helvetica-Bold", 23)
    pdf.drawCentredString(width / 2, y, f"INSIGNIA DE {title.upper()}"[:62])
    y -= 17

    pdf.setFont("Helvetica", 8.5)
    pdf.drawCentredString(width / 2, y, "Credencial académica digital emitida por StudyBook AI")
    y -= 27

    pdf.setFont("Helvetica-Bold", 17)
    pdf.drawCentredString(width / 2, y, student_name[:70])
    y -= 19

    if student_code:
        pdf.setFont("Helvetica", 9)
        pdf.drawCentredString(width / 2, y, f"Código / Matrícula: {student_code}")
        y -= 20

    box_y = y - 82
    pdf.setFillColorRGB(1, 1, 1)
    pdf.roundRect(88, box_y, width - 176, 92, 12, fill=1, stroke=0)

    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica", 9)
    pdf.drawCentredString(
        width / 2,
        box_y + 64,
        "Reconocimiento otorgado por desempeño académico destacado en:",
    )

    pdf.setFont("Helvetica-Bold", 13)
    pdf.drawCentredString(width / 2, box_y + 39, course_name[:78])

    if average:
        pdf.setFont("Helvetica-Bold", 11)
        pdf.drawCentredString(width / 2, box_y + 18, f"Promedio final: {average}")

    y = box_y - 25

    if certificate_id:
        verification_url = public_verification_url(certificate_id)

        pdf.setStrokeColorRGB(*gold)
        pdf.setLineWidth(1)
        pdf.line(130, y, width - 130, y)
        y -= 15

        pdf.setFillColorRGB(1, 1, 1)
        pdf.setFont("Helvetica-Bold", 10)
        pdf.drawCentredString(width / 2, y, "VERIFICACIÓN DIGITAL")
        y -= 17

        pdf.setFont("Helvetica", 8)
        pdf.drawCentredString(width / 2, y, "Código de validación")
        y -= 13

        pdf.setFont("Helvetica-Bold", 10)
        pdf.drawCentredString(width / 2, y, certificate_id)
        y -= 10

        qr = qrcode.make(verification_url)
        qr_buffer = BytesIO()
        qr.save(qr_buffer, format="PNG")
        qr_buffer.seek(0)

        qr_size = 96
        qr_box = 108
        qr_x = width / 2 - qr_box / 2
        qr_y = y - qr_box + 18

        pdf.setFillColorRGB(1, 1, 1)
        pdf.roundRect(qr_x, qr_y, qr_box, qr_box, 9, fill=1, stroke=0)

        pdf.drawImage(
            ImageReader(qr_buffer),
            width / 2 - qr_size / 2,
            qr_y + 6,
            width=qr_size,
            height=qr_size,
            mask="auto",
        )

        y = qr_y - 10
        pdf.setFillColorRGB(1, 1, 1)
        pdf.setFont("Helvetica", 7)
        pdf.drawCentredString(width / 2, y, "Escanee para verificar autenticidad")

    pdf.setFillColorRGB(1, 1, 1)
    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawCentredString(width / 2, 58, "SELLO DIGITAL STUDYBOOK AI")

    pdf.setFont("Helvetica", 7)
    pdf.drawCentredString(width / 2, 45, "Credencial académica verificable")

    pdf.setFont("Helvetica-Oblique", 7.5)
    pdf.setFillColorRGB(0.78, 0.82, 0.90)
    pdf.drawString(56, 30, footer)

    pdf.save()
    buffer.seek(0)
    return buffer.read()



def build_student_transcript_pdf(
    *,
    student_name: str,
    student_code: str,
    courses: list[dict],
    general_average: str = "",
    attendance_average: str = "",
    gpa4: str = "",
    academic_standing: str = "",
    distinctions: list[str] | None = None,
    ranking_position: int = 0,
    ranking_total: int = 0,
    ranking_percentile: float = 0,
    footer: str = "Generado por StudyBook AI",
) -> bytes:
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=letter)

    width, height = letter
    margin = 42
    blue = (0.02, 0.18, 0.43)
    accent = (0.38, 0.32, 0.95)
    light = (0.95, 0.97, 1.00)
    gray = (0.35, 0.35, 0.35)

    pdf.setTitle("Expediente académico premium")

    def clean_percent(value: str) -> float:
        try:
            return float(str(value).replace("%", "").strip())
        except Exception:
            return 0.0

    avg_value = clean_percent(general_average)

    if avg_value >= 90:
        classification = "EXCELENCIA ACADÉMICA"
        observation = (
            "El estudiante mantiene un desempeño sobresaliente, ubicándose "
            "dentro de los niveles más altos de rendimiento académico institucional."
        )
    elif avg_value >= 85:
        classification = "HONOR ACADÉMICO"
        observation = (
            "El estudiante presenta un rendimiento académico destacado y consistente, "
            "con indicadores superiores al promedio esperado."
        )
    elif avg_value >= 70:
        classification = "BUEN RENDIMIENTO"
        observation = (
            "El estudiante cumple satisfactoriamente con los indicadores académicos "
            "establecidos para el período evaluado."
        )
    else:
        classification = "RIESGO ACADÉMICO"
        observation = (
            "Se recomienda acompañamiento académico, seguimiento del progreso "
            "estudiantil y acciones de mejora oportunas."
        )

    # Fondo y marco institucional
    pdf.setFillColorRGB(1, 1, 1)
    pdf.rect(0, 0, width, height, fill=1, stroke=0)

    pdf.setStrokeColorRGB(*blue)
    pdf.setLineWidth(2.5)
    pdf.roundRect(30, 30, width - 60, height - 60, 14)

    pdf.setStrokeColorRGB(*accent)
    pdf.setLineWidth(0.8)
    pdf.roundRect(40, 40, width - 80, height - 80, 10)

    # Encabezado
    y = height - 72
    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 24)
    pdf.drawString(margin + 18, y, "STUDYBOOK AI")

    pdf.setFont("Helvetica-Bold", 15)
    pdf.drawRightString(width - margin - 18, y, "EXPEDIENTE ACADÉMICO")
    y -= 18

    pdf.setFillColorRGB(*gray)
    pdf.setFont("Helvetica", 8.5)
    pdf.drawString(margin + 18, y, "Sistema de inteligencia académica, certificación y trazabilidad educativa")
    y -= 34

    # Datos del estudiante
    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 16)
    pdf.drawString(margin + 18, y, student_name[:70])
    y -= 16

    pdf.setFillColorRGB(0, 0, 0)
    pdf.setFont("Helvetica", 9)
    pdf.drawString(margin + 18, y, f"Código / Matrícula: {student_code}")
    pdf.drawRightString(width - margin - 18, y, f"Fecha de emisión: {datetime.now().strftime('%d/%m/%Y')}")
    y -= 26

    # Resumen ejecutivo
    pdf.setFillColorRGB(*light)
    pdf.roundRect(margin + 8, y - 98, width - (margin + 8) * 2, 98, 10, fill=1, stroke=0)

    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 11)
    pdf.drawString(margin + 22, y - 18, "RESUMEN EJECUTIVO ACADÉMICO")

    def metric_card(x: float, title: str, value: str):
        pdf.setFillColorRGB(1, 1, 1)
        pdf.roundRect(x, y - 82, 118, 44, 8, fill=1, stroke=0)
        pdf.setFillColorRGB(*gray)
        pdf.setFont("Helvetica", 7)
        pdf.drawCentredString(x + 59, y - 52, title)
        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 11)
        pdf.drawCentredString(x + 59, y - 70, value[:18])

    metric_y = y
    x0 = margin + 22
    metric_card(x0, "PROMEDIO", general_average or "N/D")
    metric_card(x0 + 128, "GPA 4.0", gpa4 or "N/D")
    metric_card(
        x0 + 256,
        "RANKING",
        f"#{ranking_position}" if ranking_total else "N/D",
    )
    metric_card(
        x0 + 384,
        "PERCENTIL",
        f"{ranking_percentile:.1f}%" if ranking_total else "N/D",
    )

    y -= 120

    # Estado y observación
    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 10)
    pdf.drawString(margin + 18, y, f"Clasificación académica: {classification}")
    y -= 14

    pdf.setFillColorRGB(0, 0, 0)
    pdf.setFont("Helvetica", 8.5)
    for line in textwrap.wrap(observation, width=92):
        pdf.drawString(margin + 18, y, line)
        y -= 11

    y -= 8

    # Distinciones
    distinctions = distinctions or []
    if distinctions:
        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 10)
        pdf.drawString(margin + 18, y, "Distinciones automáticas")
        y -= 14

        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 8.5)
        for item in distinctions:
            pdf.drawString(margin + 28, y, f"- {str(item)}")
            y -= 11

        y -= 8

    # Ranking
    if ranking_total and ranking_total > 0:
        pdf.setFillColorRGB(*blue)
        pdf.setFont("Helvetica-Bold", 10)
        pdf.drawString(margin + 18, y, "Ranking académico")
        y -= 14

        pdf.setFillColorRGB(0, 0, 0)
        pdf.setFont("Helvetica", 8.5)
        pdf.drawString(margin + 28, y, f"Posición: #{ranking_position}")
        pdf.drawString(margin + 160, y, f"Total estudiantes: {ranking_total}")
        pdf.drawString(margin + 330, y, f"Percentil: {ranking_percentile:.1f}%")
        y -= 22

    # Tabla
    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(margin + 18, y, "Curso")
    pdf.drawString(margin + 315, y, "Promedio")
    pdf.drawString(margin + 395, y, "Asistencia")
    pdf.drawString(margin + 485, y, "Estado")
    y -= 8

    pdf.setStrokeColorRGB(*blue)
    pdf.line(margin + 18, y, width - margin - 18, y)
    y -= 15

    pdf.setFillColorRGB(0, 0, 0)
    pdf.setFont("Helvetica", 8)

    for item in courses:
        if y < 150:
            pdf.showPage()
            y = height - 70
            pdf.setFont("Helvetica", 8)

        course = str(item.get("course_name", ""))[:52]
        average = str(item.get("average", ""))
        attendance = str(item.get("attendance", ""))
        status = str(item.get("status", ""))

        pdf.drawString(margin + 18, y, course)
        pdf.drawString(margin + 315, y, average)
        pdf.drawString(margin + 395, y, attendance)
        pdf.drawString(margin + 485, y, status)
        y -= 15

    # Código verificable y QR
    import hashlib
    transcript_id_raw = (
        f"TRANSCRIPT|{student_code}|{student_name}|{general_average}|"
        f"{datetime.now().strftime('%Y')}"
    )
    transcript_digest = hashlib.sha256(transcript_id_raw.encode("utf-8")).hexdigest()[:8].upper()
    transcript_id = f"EXP-{datetime.now().strftime('%Y')}-{transcript_digest}"
    verification_url = public_verification_url(transcript_id)

    y = 148
    pdf.setStrokeColorRGB(*blue)
    pdf.line(margin + 18, y, width - margin - 18, y)
    y -= 20

    pdf.setFillColorRGB(*blue)
    pdf.setFont("Helvetica-Bold", 9)
    pdf.drawString(margin + 18, y, f"Código verificable del expediente: {transcript_id}")
    y -= 14

    pdf.setFillColorRGB(0, 0, 0)
    pdf.setFont("Helvetica", 8.5)
    pdf.drawString(margin + 18, y, "Firma / Validación académica: ________________________________")
    y -= 14
    pdf.drawString(margin + 18, y, "Sello digital StudyBook AI")

    qr = qrcode.make(verification_url)
    qr_buffer = BytesIO()
    qr.save(qr_buffer, format="PNG")
    qr_buffer.seek(0)

    pdf.drawImage(
        ImageReader(qr_buffer),
        width - margin - 92,
        62,
        width=76,
        height=76,
        mask="auto",
    )

    pdf.setFont("Helvetica", 7)
    pdf.setFillColorRGB(*gray)
    pdf.drawRightString(width - margin - 16, 50, "Escanee para verificación digital")
    pdf.drawRightString(width - margin - 16, 40, verification_url[:80])

    pdf.setFont("Helvetica-Oblique", 8)
    pdf.setFillColorRGB(*gray)
    pdf.drawString(margin + 18, 24, footer)

    pdf.save()
    buffer.seek(0)
    return buffer.read()
