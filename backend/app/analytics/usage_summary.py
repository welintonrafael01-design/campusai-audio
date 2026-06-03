from __future__ import annotations

import json
from collections import Counter
from pathlib import Path
from statistics import mean


BASE_DIR = Path(__file__).resolve().parent.parent.parent
LOG_FILE = BASE_DIR / "logs" / "usage_events.jsonl"


def get_usage_summary() -> dict:
    if not LOG_FILE.exists():
        return {
            "total_requests": 0,
            "errors": 0,
            "average_duration_seconds": 0,
            "requests_by_path": {},
            "requests_by_status": {},
        }

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

    return {
        "total_requests": len(events),
        "errors": len(errors),
        "average_duration_seconds": round(mean(durations), 4)
        if durations
        else 0,
        "requests_by_path": dict(Counter(paths).most_common(20)),
        "requests_by_status": dict(Counter(status_codes)),
    }
