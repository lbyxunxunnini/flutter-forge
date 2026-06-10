#!/usr/bin/env python3
"""Validate verify_agent rubric_evaluation output.

This check focuses on the execution-time evaluation block, not the S1 rubric
definition. L3/L4 judgments are visual or interaction quality judgments, so
they must declare how the evidence was obtained. When runtime visual evidence is
unavailable, the evaluator must explicitly downgrade to code_review_only and
state that no visual verification was performed.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from typing import Any

from validate_rubric import parse_simple_yaml


YAML_BLOCK_RE = re.compile(
    r"```ya?ml\s*\n(?P<body>.*?)\n```",
    re.DOTALL | re.IGNORECASE,
)
RUBRIC_EVALUATION_KEY_RE = re.compile(r"^\s*rubric_evaluation\s*:", re.MULTILINE)

VALID_RESULTS = {"PASS", "FAIL", "WARN"}
VALID_VERIFICATION_METHODS = {
    "runtime_observation",
    "screenshot_observation",
    "interactive_observation",
    "code_review_only",
}
VISUAL_DETAIL_PREFIXES = ("L3", "L4")
CODE_REVIEW_LIMITATION_MARKERS = (
    "未进行视觉验证",
    "未进行交互验证",
    "code_review_only",
    "无截图",
    "无运行证据",
)


@dataclass
class EvaluationError:
    item_id: str
    reason: str

    def __str__(self) -> str:
        return f"  - [{self.item_id}] {self.reason}"


def extract_rubric_evaluation_block(text: str) -> str | None:
    for match in YAML_BLOCK_RE.finditer(text):
        body = match.group("body")
        if RUBRIC_EVALUATION_KEY_RE.search(body):
            return body
    first = YAML_BLOCK_RE.search(text)
    return first.group("body") if first else None


def is_blank(value: Any) -> bool:
    return value is None or (isinstance(value, str) and not value.strip())


def parse_float(value: Any) -> float | None:
    try:
        return float(str(value).strip())
    except (TypeError, ValueError):
        return None


def is_visual_detail(item_id: str, item: dict[str, Any]) -> bool:
    layer = str(item.get("layer", "")).strip()
    return item_id.startswith(VISUAL_DETAIL_PREFIXES) or layer in {"ui", "interaction"}


def has_code_review_limitation(item: dict[str, Any]) -> bool:
    text = " ".join(
        str(item.get(field, ""))
        for field in ("evidence", "limitation", "improvement_hint")
    )
    return any(marker in text for marker in CODE_REVIEW_LIMITATION_MARKERS)


def validate_evaluation(data: dict[str, Any]) -> list[EvaluationError]:
    errors: list[EvaluationError] = []
    evaluation = data.get("rubric_evaluation")

    if not isinstance(evaluation, dict):
        return [EvaluationError("_root", "缺少 rubric_evaluation 对象")]

    required_fields = (
        "total_score",
        "layer_scores",
        "essential_pass_rate",
        "pitfall_violations",
        "details",
    )
    for field in required_fields:
        if field not in evaluation:
            errors.append(EvaluationError("_root", f"缺少必填字段 '{field}'"))

    total_score = parse_float(evaluation.get("total_score"))
    if total_score is None or total_score < 0 or total_score > 5:
        errors.append(EvaluationError("_root", "total_score 必须为 0-5 数值"))

    essential_pass_rate = parse_float(evaluation.get("essential_pass_rate"))
    if essential_pass_rate is None or essential_pass_rate < 0 or essential_pass_rate > 1:
        errors.append(EvaluationError("_root", "essential_pass_rate 必须为 0.0-1.0 数值"))

    pitfall_violations = parse_float(evaluation.get("pitfall_violations"))
    if pitfall_violations is None or pitfall_violations < 0:
        errors.append(EvaluationError("_root", "pitfall_violations 必须为非负数值"))

    layer_scores = evaluation.get("layer_scores")
    if not isinstance(layer_scores, dict):
        errors.append(EvaluationError("_root", "layer_scores 必须为对象"))
    else:
        for layer in ("functional", "robustness", "ui", "interaction"):
            value = parse_float(layer_scores.get(layer))
            if value is None or value < 0 or value > 5:
                errors.append(EvaluationError("_root", f"layer_scores.{layer} 必须为 0-5 数值"))

    details = evaluation.get("details")
    if not isinstance(details, list) or not details:
        errors.append(EvaluationError("_root", "details 必须为非空列表"))
        return errors

    for index, detail in enumerate(details):
        item_id = f"detail[{index}]"
        if not isinstance(detail, dict):
            errors.append(EvaluationError(item_id, "detail 条目必须为对象"))
            continue

        item_id = str(detail.get("id", item_id)).strip() or item_id

        for field in ("id", "result", "score", "evidence"):
            if is_blank(detail.get(field)):
                errors.append(EvaluationError(item_id, f"缺少必填字段 '{field}'"))

        result = str(detail.get("result", "")).strip()
        if result and result not in VALID_RESULTS:
            errors.append(EvaluationError(item_id, f"result 应为 {sorted(VALID_RESULTS)} 之一"))

        score = parse_float(detail.get("score"))
        if score is None or score < 1 or score > 5:
            errors.append(EvaluationError(item_id, "score 必须为 1-5 数值"))

        if is_visual_detail(item_id, detail):
            method = str(detail.get("verification_method", "")).strip()
            if not method:
                errors.append(EvaluationError(item_id, "L3/L4 或 ui/interaction 条目必须声明 verification_method"))
            elif method not in VALID_VERIFICATION_METHODS:
                errors.append(EvaluationError(item_id, f"verification_method 应为 {sorted(VALID_VERIFICATION_METHODS)} 之一"))
            elif method == "code_review_only" and not has_code_review_limitation(detail):
                errors.append(EvaluationError(item_id, "code_review_only 必须在 evidence/limitation 中说明未进行视觉或交互验证"))

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="校验 verify_agent rubric_evaluation 输出")
    parser.add_argument("input", nargs="?", help="输入文件路径，省略则从 stdin 读取")
    parser.add_argument("--json-output", action="store_true", help="以 JSON 格式输出结果")
    args = parser.parse_args()

    if args.input:
        try:
            with open(args.input, encoding="utf-8") as f:
                text = f.read()
        except OSError as exc:
            print(f"FAIL: 无法读取文件 {args.input}: {exc}", file=sys.stderr)
            return 2
    else:
        text = sys.stdin.read()

    body = extract_rubric_evaluation_block(text)
    if body is None:
        errors = [EvaluationError("_block", "输出中未找到 ```yaml ... ``` rubric_evaluation 块")]
    else:
        try:
            data = parse_simple_yaml(body)
            errors = validate_evaluation(data)
        except Exception as exc:
            errors = [EvaluationError("_parse", f"YAML 解析失败: {exc}")]

    if args.json_output:
        print(json.dumps({
            "result": "pass" if not errors else "fail",
            "errors": [{"item": e.item_id, "reason": e.reason} for e in errors],
        }, ensure_ascii=False))
    elif errors:
        print(f"FAIL: rubric_evaluation 校验失败（{len(errors)} 项错误）")
        for error in errors:
            print(error)
    else:
        print("PASS: rubric_evaluation 校验通过")

    return 0 if not errors else 2


if __name__ == "__main__":
    sys.exit(main())
