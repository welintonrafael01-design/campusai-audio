#!/usr/bin/env python3
"""Run Flutter Web drive and close its known post-test teardown hang safely."""

from __future__ import annotations

import os
import queue
import signal
import subprocess
import sys
import threading
import time


def stop_process_group(process: subprocess.Popen[str]) -> None:
    for sig, timeout in (
        (signal.SIGINT, 5),
        (signal.SIGTERM, 5),
        (signal.SIGKILL, 2),
    ):
        if process.poll() is not None:
            return
        os.killpg(process.pid, sig)
        try:
            process.wait(timeout=timeout)
            return
        except subprocess.TimeoutExpired:
            continue


def main() -> int:
    if "--" not in sys.argv:
        print("Usage: supervise_flutter_web_drive.py -- <command>", file=sys.stderr)
        return 2

    command = sys.argv[sys.argv.index("--") + 1 :]
    if not command:
        print("Missing Flutter drive command.", file=sys.stderr)
        return 2

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        start_new_session=True,
    )
    assert process.stdout is not None

    output: queue.Queue[str | None] = queue.Queue()

    def read_output() -> None:
        for line in process.stdout:
            output.put(line)
        output.put(None)

    threading.Thread(target=read_output, daemon=True).start()
    deadline = time.monotonic() + 20 * 60
    core_complete = False
    tests_passed = False

    try:
        while time.monotonic() < deadline:
            try:
                line = output.get(timeout=1)
            except queue.Empty:
                line = ""

            if line is None:
                return process.wait()
            if line:
                print(line, end="", flush=True)
                if "E2E_RESULT CORE=" in line:
                    core_complete = True
                if "All tests passed!" in line:
                    tests_passed = True

            if core_complete and tests_passed:
                stop_process_group(process)
                print("E2E_RESULT WEB_DRIVER_TEARDOWN=PASS", flush=True)
                return 0

        print("Flutter Web drive timed out before completing the core.", file=sys.stderr)
        return 1
    finally:
        stop_process_group(process)


if __name__ == "__main__":
    raise SystemExit(main())
