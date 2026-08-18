# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Send the Playground smoke prompts to a deployed Agent Engine and print JSON."""

from __future__ import annotations

import argparse
import json
import sys
import time
import uuid

TURN1 = (
    "I am reviewing the Sterling familys current application. Can you summarize "
    "their 2024 and 2025 tax returns and verify if their total household income "
    "meets our 2026 debt-to-income requirements?"
)
TURN2_FOLLOWUP = "Can you send a summary of this to my email jane@example.com"
TURN2_STANDALONE = (
    "I reviewed the Sterling family mortgage application. Please send a short "
    "summary of their tax returns and household income to jane@example.com"
)


def _collect_text(event: object) -> str:
    if event is None:
        return ""
    if isinstance(event, str):
        return event
    if isinstance(event, bytes):
        return event.decode("utf-8", errors="replace")
    if isinstance(event, (int, float, bool)):
        return str(event)
    if isinstance(event, dict):
        parts: list[str] = []
        for key in ("text", "content", "output", "message"):
            if key in event:
                parts.append(_collect_text(event[key]))
        if "parts" in event and isinstance(event["parts"], list):
            for part in event["parts"]:
                parts.append(_collect_text(part))
        if not parts:
            parts.append(json.dumps(event, default=str))
        return "\n".join(p for p in parts if p)
    if isinstance(event, (list, tuple)):
        return "\n".join(_collect_text(item) for item in event)
    text = getattr(event, "text", None)
    if text:
        return str(text)
    return str(event)


def _stream(remote: object, *, user_id: str, message: str, session_id: str | None = None) -> str:
    chunks: list[str] = []
    kwargs = {"user_id": user_id, "message": message}
    if session_id:
        kwargs["session_id"] = session_id
    try:
        events = remote.stream_query(**kwargs)
    except TypeError:
        events = remote.stream_query(user_id=user_id, message=message)
    for event in events:
        chunks.append(_collect_text(event))
    return "\n".join(c for c in chunks if c).strip()


def _stream_with_retry(remote: object, *, user_id: str, message: str, session_id: str | None, attempts: int = 4) -> str:
    last: Exception | None = None
    for i in range(attempts):
        try:
            return _stream(remote, user_id=user_id, message=message, session_id=session_id)
        except Exception as exc:  # noqa: BLE001 — engine often returns generic FAILED_PRECONDITION
            last = exc
            wait = 15 * (i + 1)
            print(f"stream_query failed (attempt {i + 1}/{attempts}): {exc}; sleeping {wait}s", file=sys.stderr)
            time.sleep(wait)
    assert last is not None
    raise last


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True)
    parser.add_argument("--region", required=True)
    parser.add_argument("--engine", required=True)
    args = parser.parse_args()

    import vertexai
    from vertexai import agent_engines

    vertexai.init(project=args.project, location=args.region)
    remote = agent_engines.get(args.engine)
    user_id = "cft-playground"
    session_id = str(uuid.uuid4())
    turn1 = ""
    turn2 = ""

    print(f"Querying {args.engine} session={session_id}", file=sys.stderr)
    print("Waiting 30s for Agent Engine revision to become ready...", file=sys.stderr)
    time.sleep(30)

    try:
        turn1 = _stream_with_retry(remote, user_id=user_id, message=TURN1, session_id=session_id)
        print("turn1 complete", file=sys.stderr)
        time.sleep(10)
        try:
            turn2 = _stream_with_retry(
                remote, user_id=user_id, message=TURN2_FOLLOWUP, session_id=session_id, attempts=2
            )
        except Exception as exc:  # noqa: BLE001
            print(f"follow-up turn2 failed ({exc}); retrying standalone prompt", file=sys.stderr)
            turn2 = _stream_with_retry(
                remote,
                user_id=user_id,
                message=TURN2_STANDALONE,
                session_id=None,
                attempts=3,
            )
        print("turn2 complete", file=sys.stderr)
    finally:
        json.dump({"turn1": turn1, "turn2": turn2}, sys.stdout)
        sys.stdout.write("\n")
        sys.stdout.flush()

    if not turn1 or not turn2:
        raise SystemExit("playground chat missing turn text")


if __name__ == "__main__":
    main()
