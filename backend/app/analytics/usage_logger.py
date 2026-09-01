from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.public_urls import is_production_environment


BASE_DIR = Path(__file__).resolve().parent.parent.parent
LOG_DIR = BASE_DIR / "logs"
LOG_FILE = LOG_DIR / "usage_events.jsonl"

logger = logging.getLogger("studybook.usage")

if not is_production_environment():
    LOG_DIR.mkdir(parents=True, exist_ok=True)


def log_usage_event(
    event: dict[str, Any],
) -> None:
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **event,
    }

    serialized = json.dumps(payload, ensure_ascii=False)
    if is_production_environment():
        logger.info("usage_event=%s", serialized)
        return

    with LOG_FILE.open("a", encoding="utf-8") as file:
        file.write(
            serialized + "\n"
        )
