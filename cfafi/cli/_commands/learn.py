"""Placeholder — implemented in a later task."""

from __future__ import annotations

import argparse


def _not_implemented(_args: argparse.Namespace) -> int:
    raise NotImplementedError("stub")


def register(sub: argparse._SubParsersAction) -> None:
    p = sub.add_parser("learn", help="(stub)")
    p.set_defaults(func=_not_implemented)
