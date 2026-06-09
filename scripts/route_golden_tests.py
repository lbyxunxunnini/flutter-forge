#!/usr/bin/env python3
"""Run deterministic golden checks for Flutter Forge routing examples."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def classify_with_script(root: Path, prompt: str) -> dict[str, str]:
    script = root / "scripts" / "classify_task.sh"
    result = subprocess.run(
        [str(script), prompt],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    output = result.stdout.strip()
    try:
        parsed = json.loads(output)
        # Normalize bool fields to strings for comparison
        for key in ("should_load_guardrails", "forge_enabled"):
            if key in parsed and isinstance(parsed[key], bool):
                parsed[key] = str(parsed[key]).lower()
        return parsed
    except json.JSONDecodeError:
        # Fallback: parse key-value format
        parsed: dict[str, str] = {}
        for line in output.splitlines():
            if ": " not in line:
                continue
            key, value = line.split(": ", 1)
            parsed[key] = value
        return parsed


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cases",
        type=Path,
        default=root / "tests" / "route_golden_cases.json",
        help="Path to route golden fixtures.",
    )
    args = parser.parse_args()

    cases = json.loads(args.cases.read_text(encoding="utf-8"))
    failed = False

    for case in cases:
        actual = classify_with_script(root, case["prompt"])
        expected = {
            "mode": case["expected_mode"],
            "policy": case.get("expected_policy", "标准"),
        }
        for optional_key in (
            "confidence",
            "guardrails_check",
            "should_load_guardrails",
            "required_phases",
            "project_root_state",
            "forge_enabled",
        ):
            case_key = f"expected_{optional_key}"
            if case_key in case:
                expected[optional_key] = str(case[case_key])

        mismatches = {
            key: (expected_value, actual.get(key))
            for key, expected_value in expected.items()
            if actual.get(key) != expected_value
        }

        if mismatches:
            failed = True
            mismatch_text = ", ".join(
                f"{key}: expected {expected_value}, got {actual_value}"
                for key, (expected_value, actual_value) in mismatches.items()
            )
            print(f"FAIL {case['name']}: {mismatch_text}")
            print(f"  prompt: {case['prompt']}")
        else:
            print(f"PASS {case['name']}: {actual['mode']}/{actual['policy']}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
