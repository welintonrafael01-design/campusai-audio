from __future__ import annotations

import json
from collections import Counter
from pathlib import Path
from statistics import mean

from app.public_urls import is_production_environment


BASE_DIR = Path(__file__).resolve().parent.parent.parent
LOG_FILE = BASE_DIR / "logs" / "usage_events.jsonl"


def classify_activity(path: str) -> str:
    if path == "/documents/upload":
        return "pdf_uploads"

    if path.startswith("/documents/chat"):
        return "chat_requests"

    if path.startswith("/documents/flashcards"):
        return "flashcards_generated"

    if path.startswith("/documents/exam"):
        return "exams_generated"

    if path.startswith("/export"):
        return "exports_generated"

    if path.startswith("/analytics"):
        return "admin_analytics"

    if path.startswith("/documents/source-chunk"):
        return "source_views"

    if path.startswith("/documents/file"):
        return "pdf_views"

    return "other"


def get_usage_summary() -> dict:
    if is_production_environment():
        return {
            **_empty_usage_summary(),
            "source": "production_telemetry",
            "local_log_available": False,
        }

    if not LOG_FILE.exists():
        return _empty_usage_summary()

    events = []

    with LOG_FILE.open("r", encoding="utf-8") as file:
        for line in file:
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue

    durations = [
        event.get("duration_seconds", 0)
        for event in events
        if isinstance(event.get("duration_seconds"), (int, float))
    ]

    status_codes = [
        str(event.get("status_code", "unknown"))
        for event in events
    ]

    errors = [
        event
        for event in events
        if int(event.get("status_code", 200)) >= 400
    ]

    paths = [
        event.get("path", "unknown")
        for event in events
    ]

    activity_counts = Counter(
        classify_activity(path)
        for path in paths
    )

    total_requests = len(events)
    error_rate = (
        len(errors) / total_requests
        if total_requests
        else 0
    )

    avg_duration = (
        mean(durations)
        if durations
        else 0
    )

    health_score = 100

    health_score -= int(error_rate * 100)

    if avg_duration > 2:
        health_score -= 10

    if avg_duration > 5:
        health_score -= 20

    health_score = max(
        0,
        min(100, health_score),
    )

    return {
        "total_requests": total_requests,
        "errors": len(errors),
        "average_duration_seconds": round(avg_duration, 4),
        "requests_by_path": dict(Counter(paths).most_common(20)),
        "requests_by_status": dict(Counter(status_codes)),
        "activity_counts": dict(activity_counts),
        "pdf_uploads": activity_counts.get("pdf_uploads", 0),
        "chat_requests": activity_counts.get("chat_requests", 0),
        "flashcards_generated": activity_counts.get("flashcards_generated", 0),
        "exams_generated": activity_counts.get("exams_generated", 0),
        "exports_generated": activity_counts.get("exports_generated", 0),
        "source_views": activity_counts.get("source_views", 0),
        "pdf_views": activity_counts.get("pdf_views", 0),
        "health_score": health_score,
    }


def _empty_usage_summary() -> dict:
    return {
            "total_requests": 0,
            "errors": 0,
            "average_duration_seconds": 0,
            "requests_by_path": {},
            "requests_by_status": {},
            "activity_counts": {},
            "pdf_uploads": 0,
            "chat_requests": 0,
            "flashcards_generated": 0,
            "exams_generated": 0,
            "exports_generated": 0,
            "source_views": 0,
            "pdf_views": 0,
            "health_score": 100,
    }
