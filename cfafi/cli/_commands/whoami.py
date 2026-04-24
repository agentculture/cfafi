"""``cfafi whoami`` — verify the configured CloudFlare API token.

Calls ``GET /user/tokens/verify``. Renders markdown key-value (matching
``cf-whoami.sh``) or raw JSON envelope under ``--json``.
"""

from __future__ import annotations

import argparse

import cfafi._api as _api
from cfafi.cli._output import emit_json, emit_kv, emit_result


def cmd_whoami(args: argparse.Namespace) -> int:
    response = _api.http_request("GET", "/user/tokens/verify")
    json_mode = bool(getattr(args, "json", False))
    if json_mode:
        emit_json(response)
        return 0
    result = response.get("result") or {}
    emit_result("**CloudFlare token**", json_mode=False)
    emit_kv([
        ("id", result.get("id", "—")),
        ("status", result.get("status", "—")),
        ("not_before", result.get("not_before") or "—"),
        ("expires_on", result.get("expires_on") or "never"),
    ])
    return 0


def register(sub: argparse._SubParsersAction) -> None:
    p = sub.add_parser(
        "whoami",
        help="Verify the configured CloudFlare API token.",
    )
    p.add_argument("--json", action="store_true", help="Emit raw CloudFlare response envelope.")
    p.set_defaults(func=cmd_whoami)
