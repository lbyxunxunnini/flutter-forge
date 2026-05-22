#!/usr/bin/env bash
# check_project_guardrails.sh — 项目锚点与护栏状态检查
#
# 用法:
#   scripts/check_project_guardrails.sh <project_root>
#   scripts/check_project_guardrails.sh <project_root> --json
#   scripts/check_project_guardrails.sh <project_root> --cached [ttl]

set -euo pipefail

PROJECT_ROOT="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="${PROJECT_ROOT}/.flutter-forge/runtime/project_guardrails_status.json"

cached_json() {
  local ttl="$1"
  if [ ! -f "$STATE_FILE" ]; then
    return 1
  fi
  PROJECT_ROOT_ABS="$(cd "$PROJECT_ROOT" && pwd)"
  STATE_FILE="$STATE_FILE" PROJECT_ROOT_ABS="$PROJECT_ROOT_ABS" TTL="$ttl" python3 - <<'PY'
import json
import os
import sys
import time

path = os.environ["STATE_FILE"]
project_root = os.environ["PROJECT_ROOT_ABS"]
ttl = int(os.environ["TTL"])
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    raise SystemExit(1)

age = int(time.time()) - int(data.get("checked_at", 0))
if data.get("project_root") != project_root or age > ttl:
    raise SystemExit(1)
data["cache_hit"] = True
data["cache_age"] = age
print(json.dumps(data, ensure_ascii=False))
PY
}

if [[ "${2:-}" == "--cached" ]]; then
  TTL="${3:-300}"
  if CACHED="$(cached_json "$TTL" 2>/dev/null)"; then
    echo "$CACHED"
    exit 0
  fi
  exec bash "$0" "$PROJECT_ROOT" --json
fi

DETECTION_JSON="$(python3 "${SCRIPT_DIR}/detect_project_root_state.py" "$PROJECT_ROOT")"

RESULT_JSON="$(
DETECTION_JSON="$DETECTION_JSON" PROJECT_ROOT="$PROJECT_ROOT" python3 - <<'PY'
import json
import os
from pathlib import Path

data = json.loads(os.environ["DETECTION_JSON"])
project_root = Path(os.environ["PROJECT_ROOT"]).resolve()
project_name = project_root.name

search_paths = [
    f".claude/.flutter-forge/projects/{project_name}.project_guardrails.yaml",
    f".trae/.flutter-forge/projects/{project_name}.project_guardrails.yaml",
    f".agents/.flutter-forge/projects/{project_name}.project_guardrails.yaml",
    f".flutter-forge/projects/{project_name}.project_guardrails.yaml",
]

found_path = next((path for path in search_paths if (project_root / path).is_file()), "-")
root_type = data["root_type"]
if root_type == "empty_new":
    status = "empty_new"
elif root_type == "non_flutter":
    status = "non_flutter"
elif found_path != "-":
    status = "found"
else:
    status = "missing"

result = {
    "status": status,
    "path": found_path,
    "project_name": project_name,
    "project_root": str(project_root),
    "root_type": root_type,
    "forge_enabled": data["forge_enabled"],
    "is_empty_dir": data["is_empty_dir"],
    "has_pubspec": data["has_pubspec"],
    "has_lib_dir": data["has_lib_dir"],
    "ignored_hidden_files": data["ignored_hidden_files"],
    "checked_at": data["checked_at"],
}
print(json.dumps(result, ensure_ascii=False))
PY
)"

mkdir -p "${PROJECT_ROOT}/.flutter-forge/runtime" 2>/dev/null || true
printf '%s\n' "$RESULT_JSON" > "$STATE_FILE"

if [[ "${2:-}" == "--json" ]]; then
  echo "$RESULT_JSON"
  exit 0
fi

printf '%s' "$RESULT_JSON" | python3 - <<'PY'
import json
import sys

data = json.load(sys.stdin)
for key in (
    "status",
    "path",
    "project_name",
    "root_type",
    "forge_enabled",
    "is_empty_dir",
    "has_pubspec",
    "has_lib_dir",
):
    value = data[key]
    if isinstance(value, bool):
        value = str(value).lower()
    print(f"{key}: {value}")
PY
