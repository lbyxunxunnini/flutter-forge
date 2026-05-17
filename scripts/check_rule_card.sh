#!/usr/bin/env bash
# check_rule_card.sh — 快速判定当前项目的规则卡状态
#
# 用法: scripts/check_rule_card.sh <project_root>
#
# 输出结构化 key-value，LLM 直接读取，无需自行搜索路径。
#
# 输出字段:
#   status       : found | draft | not_found
#   path         : 命中的规则卡相对路径（无则 -）
#   project_name : 项目名（目录名）
#   has_draft    : true | false
#   draft_path   : 草案相对路径（无则 -）

set -euo pipefail

PROJECT_ROOT="${1:-.}"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

# 按优先级排列的查找路径（相对项目根目录）
SEARCH_PATHS=(
  ".claude/.flutter-forge/projects/${PROJECT_NAME}.rule_card.yaml"
  ".trae/.flutter-forge/projects/${PROJECT_NAME}.rule_card.yaml"
  ".agents/.flutter-forge/projects/${PROJECT_NAME}.rule_card.yaml"
  ".flutter-forge/projects/${PROJECT_NAME}.rule_card.yaml"
)

# 草案路径（与正式卡同目录，_draft 后缀）
DRAFT_PATHS=(
  ".claude/.flutter-forge/projects/${PROJECT_NAME}.rule_card_draft.yaml"
  ".trae/.flutter-forge/projects/${PROJECT_NAME}.rule_card_draft.yaml"
  ".agents/.flutter-forge/projects/${PROJECT_NAME}.rule_card_draft.yaml"
  ".flutter-forge/projects/${PROJECT_NAME}.rule_card_draft.yaml"
)

found_card=""
found_draft=""

# 查找正式规则卡（命中即停）
for p in "${SEARCH_PATHS[@]}"; do
  if [ -f "${PROJECT_ROOT}/${p}" ]; then
    found_card="$p"
    break
  fi
done

# 查找草案（命中即停）
for p in "${DRAFT_PATHS[@]}"; do
  if [ -f "${PROJECT_ROOT}/${p}" ]; then
    found_draft="$p"
    break
  fi
done

# 输出结果
if [ -n "$found_card" ]; then
  status="found"
  card_path="$found_card"
elif [ -n "$found_draft" ]; then
  status="draft"
  card_path="$found_draft"
else
  status="not_found"
  card_path="-"
fi

if [ -n "$found_draft" ]; then
  has_draft_py="True"
else
  has_draft_py="False"
fi

# --json 模式：输出 JSON 供 hook / 自动化消费
if [[ "${2:-}" == "--json" ]]; then
  STATUS="$status" CARD_PATH="$card_path" PROJ_NAME="$PROJECT_NAME" \
  HAS_DRAFT_PY="$has_draft_py" DRAFT_PATH="${found_draft:--}" \
  python3 -c "
import json, os
print(json.dumps({
    'status': os.environ['STATUS'],
    'path': os.environ['CARD_PATH'],
    'project_name': os.environ['PROJ_NAME'],
    'has_draft': os.environ['HAS_DRAFT_PY'] == 'True',
    'draft_path': os.environ['DRAFT_PATH'],
}, ensure_ascii=False))
"
  exit 0
fi

# 写入状态文件供 hook 读取
STATE_DIR="${PROJECT_ROOT}/.flutter-forge/runtime"
mkdir -p "$STATE_DIR" 2>/dev/null || true
STATUS="$status" CARD_PATH="$card_path" PROJ_NAME="$PROJECT_NAME" \
HAS_DRAFT_PY="$has_draft_py" DRAFT_PATH="${found_draft:--}" \
STATE_DIR="$STATE_DIR" \
python3 -c "
import json, os
state = {
    'status': os.environ['STATUS'],
    'path': os.environ['CARD_PATH'],
    'project_name': os.environ['PROJ_NAME'],
    'has_draft': os.environ['HAS_DRAFT_PY'] == 'True',
    'draft_path': os.environ['DRAFT_PATH'],
}
state_file = os.path.join(os.environ['STATE_DIR'], 'rule_card_status.json')
with open(state_file, 'w') as f:
    json.dump(state, f, ensure_ascii=False, indent=2)
" 2>/dev/null || true

echo "status: $status"
echo "path: $card_path"
echo "project_name: $PROJECT_NAME"
echo "has_draft: $([ -n "$found_draft" ] && echo true || echo false)"
echo "draft_path: ${found_draft:--}"
