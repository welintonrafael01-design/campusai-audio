#!/usr/bin/env python3
"""Remove common credentials from QA command output before it is persisted."""

from __future__ import annotations

import re
import sys


PATTERNS = (
    (
        re.compile(r"(?i)(authorization\s*[:=]\s*bearer\s+)[^\s\"']+"),
        r"\1[REDACTED]",
    ),
    (
        re.compile(
            r"(?i)((?:[\"']?(?:password|access_token|refresh_token|token|supabase[_-]?anon[_-]?key|"
            r"supabase[_-]?service[_-]?role[_-]?key|stripe[_-]?(?:secret|publishable)[_-]?key|"
            r"openai[_-]?api[_-]?key)[\"']?)\s*[=:]\s*[\"']?)[^\s\"',}]+"
        ),
        r"\1[REDACTED]",
    ),
    (re.compile(r"\bsk_(?:live|test)_[A-Za-z0-9_]+\b"), "[REDACTED_STRIPE_KEY]"),
    (re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{16,}\b"), "[REDACTED_OPENAI_KEY]"),
    (
        re.compile(r"\bsb_(?:publishable|secret)_[A-Za-z0-9_-]{16,}\b"),
        "[REDACTED_SUPABASE_KEY]",
    ),
    (re.compile(r"\b(?:eyJ[a-zA-Z0-9_-]+\.){2}[a-zA-Z0-9_-]+\b"), "[REDACTED_JWT]"),
)


def redact(text: str) -> str:
    for pattern, replacement in PATTERNS:
        text = pattern.sub(replacement, text)
    return text


for line in sys.stdin:
    sys.stdout.write(redact(line))
