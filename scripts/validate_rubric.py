#!/usr/bin/env python3
"""validate_rubric.py — 校验 Rubric 条目完整性。

用法:
    python3 scripts/validate_rubric.py < input.txt
    python3 scripts/validate_rubric.py input.txt
    cat input.txt | python3 scripts/validate_rubric.py

输入: 包含 ```yaml ... ``` rubric 块的 LLM 输出文本（requirement_analyst 或 verify_agent 输出）
输出: PASS / FAIL + 具体错误，FAIL 时退出码 2

校验维度:
1. rubric 块存在且可解析
2. 每条 rubric 条目包含 id / layer / level / criterion 必填字段
3. layer 在合法枚举内（functional / robustness / ui / interaction）
4. level 在合法枚举内（Essential / Important / Optional / Pitfall）
5. 四层均有覆盖（至少各 1 条）
6. Pitfall 至少 2 条
7. criterion 非占位值

设计原则:
- 不依赖第三方库，标准库实现
- 失败信息精确到条目，便于 LLM 自纠
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from typing import Any


# ---------- Constants ----------

VALID_LAYERS = ("functional", "robustness", "ui", "interaction")
VALID_LEVELS = ("Essential", "Important", "Optional", "Pitfall")

PLACEHOLDER_PATTERNS = [
    r"^$",
    r"^\.{2,}$",
    r"^[xX]+$",
    r"^TBD$",
    r"^TODO$",
    r"^待补$",
    r"^未填$",
    r"^\?+$",
    r"^_+$",
]


# ---------- Parser ----------

YAML_BLOCK_RE = re.compile(
    r"```ya?ml\s*\n(?P<body>.*?)\n```",
    re.DOTALL | re.IGNORECASE,
)

RUBRIC_KEY_RE = re.compile(r"^\s*rubric\s*:", re.MULTILINE)
CHECKLIST_RUBRIC_KEY_RE = re.compile(r"^\s*rubric_items\s*:", re.MULTILINE)


def extract_rubric_block(text: str) -> str | None:
    """从输出中提取 rubric YAML 块。

    优先识别带 rubric: 或 rubric_items: 顶级 key 的 yaml 块；
    若不存在则取第一个 yaml 块。
    """
    for match in YAML_BLOCK_RE.finditer(text):
        body = match.group("body")
        if RUBRIC_KEY_RE.search(body) or CHECKLIST_RUBRIC_KEY_RE.search(body):
            return body
    first = YAML_BLOCK_RE.search(text)
    return first.group("body") if first else None


def parse_simple_yaml(body: str) -> dict[str, Any]:
    """轻量 YAML 解析器，支持 rubric schema 用到的语法。"""
    lines = body.splitlines()

    def parse_scalar(raw: str) -> Any:
        s = raw.strip()
        if "#" in s:
            new_s = []
            in_quote = None
            for ch in s:
                if in_quote:
                    if ch == in_quote:
                        in_quote = None
                    new_s.append(ch)
                elif ch in ('"', "'"):
                    in_quote = ch
                    new_s.append(ch)
                elif ch == "#":
                    break
                else:
                    new_s.append(ch)
            s = "".join(new_s).strip()
        if s.lower() == "true":
            return True
        if s.lower() == "false":
            return False
        if s.lower() in ("null", "~", ""):
            return None
        if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
            return s[1:-1]
        if s == "[]":
            return []
        return s

    def get_indent(line: str) -> int:
        return len(line) - len(line.lstrip(" "))

    def parse_block(start: int, min_indent: int) -> tuple[dict[str, Any], int]:
        result: dict[str, Any] = {}
        i = start

        while i < len(lines):
            line = lines[i]
            stripped = line.strip()

            if not stripped or stripped.startswith("#"):
                i += 1
                continue

            indent = get_indent(line)

            if indent < min_indent:
                break

            if stripped.startswith("- "):
                break

            if ":" in stripped:
                key, _, rest = stripped.partition(":")
                key = key.strip()
                rest_stripped = rest.strip()

                if rest_stripped:
                    result[key] = parse_scalar(rest_stripped)
                    i += 1
                else:
                    j = i + 1
                    while j < len(lines) and (not lines[j].strip() or lines[j].strip().startswith("#")):
                        j += 1

                    if j >= len(lines):
                        result[key] = None
                        i = j
                        continue

                    nxt = lines[j]
                    nxt_indent = get_indent(nxt)

                    if nxt_indent <= indent:
                        result[key] = None
                        i = j
                        continue

                    if nxt.lstrip().startswith("- "):
                        items: list[Any] = []
                        k = j
                        list_indent = nxt_indent
                        while k < len(lines):
                            cur = lines[k]
                            cur_stripped = cur.strip()
                            if not cur_stripped or cur_stripped.startswith("#"):
                                k += 1
                                continue
                            cur_indent = get_indent(cur)
                            if cur_indent < list_indent:
                                break
                            if cur_indent == list_indent and cur_stripped.startswith("- "):
                                item_raw = cur_stripped[2:]
                                # Check if this is a dict item (has key: value on next lines)
                                if ":" in item_raw and not item_raw.startswith('"'):
                                    # Inline dict start
                                    item_key, _, item_val = item_raw.partition(":")
                                    item_dict: dict[str, Any] = {item_key.strip(): parse_scalar(item_val)}
                                    k += 1
                                    # Read continuation lines
                                    while k < len(lines):
                                        cont = lines[k]
                                        cont_stripped = cont.strip()
                                        if not cont_stripped or cont_stripped.startswith("#"):
                                            k += 1
                                            continue
                                        cont_indent = get_indent(cont)
                                        if cont_indent <= list_indent:
                                            break
                                        if ":" in cont_stripped and not cont_stripped.startswith("- "):
                                            ck, _, cv = cont_stripped.partition(":")
                                            item_dict[ck.strip()] = parse_scalar(cv)
                                            k += 1
                                        else:
                                            break
                                    items.append(item_dict)
                                else:
                                    items.append(parse_scalar(item_raw))
                                    k += 1
                            elif cur_indent > list_indent:
                                if items:
                                    prev = items[-1]
                                    if isinstance(prev, str):
                                        items[-1] = f"{prev} {cur_stripped}"
                                    elif isinstance(prev, dict) and ":" in cur_stripped:
                                        ck, _, cv = cur_stripped.partition(":")
                                        prev[ck.strip()] = parse_scalar(cv)
                                k += 1
                            else:
                                break
                        result[key] = items
                        i = k
                    else:
                        sub, i = parse_block(j, nxt_indent)
                        result[key] = sub
            else:
                i += 1

        return result, i

    data, _ = parse_block(0, 0)
    return data


# ---------- Validator ----------

@dataclass
class RubricError:
    item_id: str
    reason: str

    def __str__(self) -> str:
        return f"  - [{self.item_id}] {self.reason}"


def is_placeholder(value: str) -> bool:
    s = value.strip() if isinstance(value, str) else ""
    if len(s) <= 1:
        return True
    for pat in PLACEHOLDER_PATTERNS:
        if re.match(pat, s, re.IGNORECASE):
            return True
    if len(s) < 4 and not re.search(r"[\w\u4e00-\u9fff]{2,}", s):
        return True
    return False


def validate_rubric_items(items: list[Any]) -> list[RubricError]:
    errors: list[RubricError] = []

    if not isinstance(items, list):
        return [RubricError("_root", "rubric/rubric_items 应为列表")]

    layer_coverage: dict[str, int] = {"functional": 0, "robustness": 0, "ui": 0, "interaction": 0}
    pitfall_count = 0

    for idx, item in enumerate(items):
        item_id = f"item[{idx}]"
        if not isinstance(item, dict):
            errors.append(RubricError(item_id, "条目应为对象/dict"))
            continue

        item_id = str(item.get("id", item_id))

        # Required fields
        for field in ("id", "layer", "level", "criterion"):
            val = item.get(field)
            if val is None or (isinstance(val, str) and is_placeholder(val)):
                errors.append(RubricError(item_id, f"缺少必填字段 '{field}'"))

        # Layer validation
        layer = item.get("layer")
        if isinstance(layer, str):
            if layer not in VALID_LAYERS:
                errors.append(RubricError(item_id, f"layer 应为 {list(VALID_LAYERS)} 之一，实际为 '{layer}'"))
            else:
                layer_coverage[layer] += 1

        # Level validation
        level = item.get("level")
        if isinstance(level, str):
            if level not in VALID_LEVELS:
                errors.append(RubricError(item_id, f"level 应为 {list(VALID_LEVELS)} 之一，实际为 '{level}'"))
            if level == "Pitfall":
                pitfall_count += 1

        # Criterion validation
        criterion = item.get("criterion")
        if isinstance(criterion, str) and is_placeholder(criterion):
            errors.append(RubricError(item_id, f"criterion 为占位值 '{criterion}'"))

    # Layer coverage check
    for layer, count in layer_coverage.items():
        if count == 0:
            errors.append(RubricError("_coverage", f"层 '{layer}' 没有覆盖（至少需要 1 条）"))

    # Pitfall minimum
    if pitfall_count < 2:
        errors.append(RubricError("_pitfall", f"Pitfall 条目至少需要 2 条，当前 {pitfall_count} 条"))

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="校验 Rubric 条目完整性")
    parser.add_argument(
        "input",
        nargs="?",
        help="输入文件路径，省略则从 stdin 读取",
    )
    parser.add_argument(
        "--json-output",
        action="store_true",
        help="以 JSON 格式输出结果",
    )
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

    body = extract_rubric_block(text)
    if body is None:
        msg = "FAIL: 输出中未找到 ```yaml ... ``` rubric 块"
        if args.json_output:
            print(json.dumps({
                "result": "fail",
                "errors": [{"item": "_block", "reason": "missing yaml rubric block"}],
            }, ensure_ascii=False))
        else:
            print(msg)
        return 2

    try:
        data = parse_simple_yaml(body)
    except Exception as exc:
        msg = f"FAIL: YAML 解析失败: {exc}"
        if args.json_output:
            print(json.dumps({
                "result": "fail",
                "errors": [{"item": "_parse", "reason": str(exc)}],
            }, ensure_ascii=False))
        else:
            print(msg)
        return 2

    # Extract rubric items - support both "rubric:" and "rubric_items:" keys
    items = None
    if "rubric" in data and isinstance(data["rubric"], list):
        items = data["rubric"]
    elif "rubric_items" in data and isinstance(data["rubric_items"], list):
        items = data["rubric_items"]
    elif "checklist" in data and isinstance(data["checklist"], dict):
        if "rubric_items" in data["checklist"] and isinstance(data["checklist"]["rubric_items"], list):
            items = data["checklist"]["rubric_items"]

    if items is None:
        msg = "FAIL: YAML 块中未找到 rubric 或 rubric_items 列表"
        if args.json_output:
            print(json.dumps({
                "result": "fail",
                "errors": [{"item": "_items", "reason": "missing rubric/rubric_items list"}],
            }, ensure_ascii=False))
        else:
            print(msg)
        return 2

    errors = validate_rubric_items(items)

    if args.json_output:
        print(json.dumps({
            "result": "pass" if not errors else "fail",
            "item_count": len(items),
            "errors": [{"item": e.item_id, "reason": e.reason} for e in errors],
        }, ensure_ascii=False))
    else:
        if not errors:
            print(f"PASS: rubric 校验通过（{len(items)} 条）")
        else:
            print(f"FAIL: rubric 校验失败（{len(items)} 条，{len(errors)} 项错误）")
            for e in errors:
                print(e)

    return 0 if not errors else 2


if __name__ == "__main__":
    sys.exit(main())
