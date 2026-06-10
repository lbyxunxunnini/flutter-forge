#!/usr/bin/env python3
"""Validate P0/P1 hard-rule release bindings.

The registry is intentionally explicit: every hard-rule group must point to
source docs, runtime surfaces, release checks, and strings that prove those
checks contain the expected positive/negative coverage.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def as_nonempty_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) and len(value) > 0 else []


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
    )
    parser.add_argument(
        "--registry",
        type=Path,
        default=Path("references/release_bindings.json"),
    )
    args = parser.parse_args()

    root = args.root.resolve()
    registry_path = (root / args.registry).resolve()
    errors: list[str] = []

    try:
        data = json.loads(registry_path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"FAIL cannot read release binding registry: {exc}")
        return 1

    bindings = as_nonempty_list(data.get("bindings"))
    if not bindings:
        errors.append("registry has no bindings")

    seen_ids: set[str] = set()
    for index, binding in enumerate(bindings):
        if not isinstance(binding, dict):
            errors.append(f"binding[{index}] is not an object")
            continue

        binding_id = str(binding.get("id", "")).strip()
        prefix = binding_id or f"binding[{index}]"
        if not binding_id:
            errors.append(f"{prefix}: missing id")
        elif binding_id in seen_ids:
            errors.append(f"{prefix}: duplicate id")
        seen_ids.add(binding_id)

        severity = binding.get("severity")
        if severity not in {"P0", "P1"}:
            errors.append(f"{prefix}: severity must be P0 or P1")

        if not str(binding.get("rule", "")).strip():
            errors.append(f"{prefix}: missing rule")

        for field in ("sources", "runtime", "positive_cases", "negative_cases"):
            values = as_nonempty_list(binding.get(field))
            if not values:
                errors.append(f"{prefix}: missing {field}")
                continue
            if field in {"sources", "runtime"}:
                for value in values:
                    path = root / str(value)
                    if not path.exists():
                        errors.append(f"{prefix}: {field} path does not exist: {value}")

        release_checks = as_nonempty_list(binding.get("release_checks"))
        if not release_checks:
            errors.append(f"{prefix}: missing release_checks")
            continue

        for check_index, check in enumerate(release_checks):
            if not isinstance(check, dict):
                errors.append(f"{prefix}: release_checks[{check_index}] is not an object")
                continue
            check_file = str(check.get("file", "")).strip()
            if not check_file:
                errors.append(f"{prefix}: release_checks[{check_index}] missing file")
                continue
            path = root / check_file
            if not path.exists():
                errors.append(f"{prefix}: release check file does not exist: {check_file}")
                continue
            needles = as_nonempty_list(check.get("needles"))
            if not needles:
                errors.append(f"{prefix}: release check {check_file} has no needles")
                continue
            text = path.read_text(encoding="utf-8")
            for needle in needles:
                needle_text = str(needle)
                if needle_text not in text:
                    errors.append(f"{prefix}: release check {check_file} missing needle: {needle_text}")

    if errors:
        for error in errors:
            print(f"FAIL {error}")
        return 1

    print(f"PASS {len(bindings)} P0/P1 release bindings validated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
