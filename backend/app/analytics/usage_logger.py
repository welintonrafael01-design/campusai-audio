from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


BASE_DIR = Path(__file__).resolve().parent.parent.parent
LOG_DIR = BASE_DIR / "logs"
LOG_FILE = LOG_DIR / "usage_events.jsonl"

LOG_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


def log_usage_event(
    event: dict[str, Any],
) -> None:
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **event,
    }

    with LOG_FILE.open("a", encoding="utf-8") as file:
        file.write(
            json.dumps(
                payload,
                ensure_ascii=False,
            )
            + "\n"
        )
