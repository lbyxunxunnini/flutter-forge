#!/usr/bin/env bash
# ff_session.sh — session.md 结构化管理
#
# 用法:
#   scripts/ff_session.sh read                           # 读取当前 session
#   scripts/ff_session.sh update --phase S4 --mode 页面开发  # 更新指定字段
#   scripts/ff_session.sh wait --waiting_state artifact --expected_input screenshot --pending_question "请补充截图"
#   scripts/ff_session.sh reset                          # 重置 session（任务完成时）
#   scripts/ff_session.sh init --track execution         # 初始化新 session
#
# 支持的 update 字段:
#   --track <cocreation|execution>
#   --phase <C0-C3|S0-S6>
#   --mode <模式名>
#   --decision_version <v1|v2|v3>
#   --rule_card <已加载|未加载>
#   --rule_card_summary <摘要文本>
#   --active_agents <agent列表>
#   --work_packages <P1/P2/P3|无>
#   --stale_results <结果列表|无>
#   --recent_action <操作描述>
#   --waiting_state <none|user_input|artifact|confirmation>
#   --expected_input <none|text|screenshot|document|design|confirmation|any>
#   --pending_question <等待用户回答的问题>
#   --task_object <页面/模块/业务对象>
#   --resume_keys <恢复关键词>
#   --change_contract <改动契约摘要>
#   --confirmation_status <不需要|未确认|用户已确认>
#   --summary_package <摘要包路径或摘要标识>
#   --last_user_input <最后用户输入摘要>
#
# session 路径: 与规则卡宿主目录一致；无规则卡时回退 .flutter-forge/session.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_FILE=""

# 解析 project_root 参数
PROJECT_ROOT=""
if [ "${1:-}" = "--project-root" ] && [ "${2:-}" != "" ]; then
  PROJECT_ROOT="$2"
  shift 2
fi

PROJECT_ROOT_ABS="$(cd "${PROJECT_ROOT:-.}" && pwd)"

legacy_session_file() {
  printf '%s/.flutter-forge/session.md\n' "$PROJECT_ROOT_ABS"
}

session_file_from_rule_card() {
  local output card_path host_dir
  if [ ! -x "${SCRIPT_DIR}/check_rule_card.sh" ]; then
    return 1
  fi
  output="$("${SCRIPT_DIR}/check_rule_card.sh" "$PROJECT_ROOT_ABS" --cached 300 2>/dev/null || true)"
  card_path="$(printf '%s\n' "$output" | python3 -c '
import json, sys
text = sys.stdin.read().strip()
if not text:
    raise SystemExit(1)
try:
    data = json.loads(text)
    path = data.get("path", "-")
except Exception:
    path = "-"
    for line in text.splitlines():
        if line.startswith("path:"):
            path = line.split(":", 1)[1].strip()
            break
if not path or path == "-":
    raise SystemExit(1)
print(path)
' 2>/dev/null || true)"
  if [ -z "$card_path" ]; then
    return 1
  fi
  case "$card_path" in
    .claude/.flutter-forge/projects/*) host_dir=".claude/.flutter-forge" ;;
    .trae/.flutter-forge/projects/*) host_dir=".trae/.flutter-forge" ;;
    .agents/.flutter-forge/projects/*) host_dir=".agents/.flutter-forge" ;;
    .flutter-forge/projects/*) host_dir=".flutter-forge" ;;
    *) return 1 ;;
  esac
  printf '%s/%s/session.md\n' "$PROJECT_ROOT_ABS" "$host_dir"
}

candidate_session_files() {
  session_file_from_rule_card || true
  printf '%s/.claude/.flutter-forge/session.md\n' "$PROJECT_ROOT_ABS"
  printf '%s/.trae/.flutter-forge/session.md\n' "$PROJECT_ROOT_ABS"
  printf '%s/.agents/.flutter-forge/session.md\n' "$PROJECT_ROOT_ABS"
  legacy_session_file
}

resolve_session_file_for_read() {
  local candidate seen=""
  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    case ":$seen:" in *":$candidate:"*) continue ;; esac
    seen="${seen}:$candidate"
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(candidate_session_files)
  legacy_session_file
}

resolve_session_file_for_write() {
  local preferred legacy candidate
  preferred="$(session_file_from_rule_card || true)"
  legacy="$(legacy_session_file)"
  if [ -n "$preferred" ]; then
    if [ ! -f "$preferred" ] && [ -f "$legacy" ] && [ "$preferred" != "$legacy" ]; then
      mkdir -p "$(dirname "$preferred")"
      mv "$legacy" "$preferred"
    fi
    printf '%s\n' "$preferred"
    return 0
  fi
  candidate="$(resolve_session_file_for_read)"
  printf '%s\n' "$candidate"
}

ACTION="${1:-read}"
shift || true
case "$ACTION" in
  read|validate) SESSION_FILE="$(resolve_session_file_for_read)" ;;
  *) SESSION_FILE="$(resolve_session_file_for_write)" ;;
esac

write_session_template() {
  local track="$1"
  local phase="$2"
  local mode="$3"
  local rule_card="$4"
  mkdir -p "$(dirname "$SESSION_FILE")"
  cat > "$SESSION_FILE" <<EOF
# Flutter Forge Session

- 轨道：${track}
- 当前阶段：${phase}
- 当前模式：${mode}
- 决策版本：v1
- 规则卡：${rule_card}
- 规则卡摘要：-
- 活跃代理：controller
- 工作包：无
- 失效结果：无
- 等待状态：none
- 等待输入类型：none
- 待确认问题：-
- 任务对象：-
- 恢复键：-
- 改动契约：-
- 确认状态：不需要
- 摘要包：-
- 最后用户输入摘要：-
- 最近操作：初始化
- 更新时间：$(date +"%Y-%m-%d %H:%M")
EOF
}

update_field() {
  local field="$1"
  local value="$2"
  FIELD="$field" VALUE="$value" python3 - "$SESSION_FILE" <<'PY'
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
field = os.environ["FIELD"]
value = os.environ["VALUE"]
prefix = f"- {field}："
lines = path.read_text(encoding="utf-8").splitlines()
for i, line in enumerate(lines):
    if line.startswith(prefix):
        lines[i] = f"{prefix}{value}"
        break
else:
    lines.append(f"{prefix}{value}")
path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

# --- read ---
cmd_read() {
  if [ ! -f "$SESSION_FILE" ]; then
    echo "status: no_session"
    echo "path: -"
    exit 0
  fi
  echo "status: has_session"
  echo "path: $SESSION_FILE"
  echo "---"
  cat "$SESSION_FILE"
}

# --- init ---
cmd_init() {
  local track="execution"
  local phase="S0"
  local mode="未定"
  local rule_card="未加载"

  while [ $# -gt 0 ]; do
    case "$1" in
      --track) track="$2"; shift 2 ;;
      --phase) phase="$2"; shift 2 ;;
      --mode) mode="$2"; shift 2 ;;
      --rule_card) rule_card="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  write_session_template "$track" "$phase" "$mode" "$rule_card"
  echo "status: initialized"
  echo "path: $SESSION_FILE"
}

# --- update ---
cmd_update() {
  if [ ! -f "$SESSION_FILE" ]; then
    write_session_template "execution" "S0" "未定" "未加载"
  fi

  # 解析参数
  while [ $# -gt 0 ]; do
    case "$1" in
      --track) update_field "轨道" "$2"; shift 2 ;;
      --phase) update_field "当前阶段" "$2"; shift 2 ;;
      --mode) update_field "当前模式" "$2"; shift 2 ;;
      --decision_version) update_field "决策版本" "$2"; shift 2 ;;
      --rule_card) update_field "规则卡" "$2"; shift 2 ;;
      --rule_card_summary) update_field "规则卡摘要" "$2"; shift 2 ;;
      --active_agents) update_field "活跃代理" "$2"; shift 2 ;;
      --work_packages) update_field "工作包" "$2"; shift 2 ;;
      --stale_results) update_field "失效结果" "$2"; shift 2 ;;
      --waiting_state) update_field "等待状态" "$2"; shift 2 ;;
      --expected_input) update_field "等待输入类型" "$2"; shift 2 ;;
      --pending_question) update_field "待确认问题" "$2"; shift 2 ;;
      --task_object) update_field "任务对象" "$2"; shift 2 ;;
      --resume_keys) update_field "恢复键" "$2"; shift 2 ;;
      --change_contract) update_field "改动契约" "$2"; shift 2 ;;
      --confirmation_status) update_field "确认状态" "$2"; shift 2 ;;
      --summary_package) update_field "摘要包" "$2"; shift 2 ;;
      --last_user_input) update_field "最后用户输入摘要" "$2"; shift 2 ;;
      --recent_action) update_field "最近操作" "$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # 更新时间戳
  update_field "更新时间" "$(date +"%Y-%m-%d %H:%M")"

  echo "status: updated"
  echo "path: $SESSION_FILE"
}

# --- wait ---
cmd_wait() {
  cmd_update "$@" --recent_action "等待用户输入"
}

# --- reset ---
cmd_reset() {
  if [ -f "$SESSION_FILE" ]; then
    rm "$SESSION_FILE"
    echo "status: reset"
    echo "path: $SESSION_FILE"
  else
    echo "status: no_session_to_reset"
  fi
}

# --- 校验 session 字段完整性 ---
cmd_validate() {
  if [ ! -f "$SESSION_FILE" ]; then
    echo "status: no_session"
    exit 0
  fi

  errors=0
  required_fields=("轨道" "当前阶段" "当前模式" "决策版本" "规则卡" "活跃代理" "工作包" "失效结果" "等待状态" "等待输入类型" "待确认问题" "任务对象" "恢复键" "改动契约" "确认状态" "摘要包" "最后用户输入摘要" "最近操作" "更新时间")

  for field in "${required_fields[@]}"; do
    if ! grep -q "^- ${field}：" "$SESSION_FILE"; then
      echo "FAIL missing field: $field"
      errors=$((errors + 1))
    fi
  done

  # 校验阶段值
  phase=$(grep "^- 当前阶段：" "$SESSION_FILE" | sed 's/^- 当前阶段：//' | xargs)
  if ! echo "$phase" | grep -qE '^(C[0-3]|S[0-6])$'; then
    echo "FAIL invalid phase: $phase"
    errors=$((errors + 1))
  fi

  waiting_state=$(grep "^- 等待状态：" "$SESSION_FILE" | sed 's/^- 等待状态：//' | xargs)
  if ! echo "$waiting_state" | grep -qE '^(none|user_input|artifact|confirmation)$'; then
    echo "FAIL invalid waiting_state: $waiting_state"
    errors=$((errors + 1))
  fi

  expected_input=$(grep "^- 等待输入类型：" "$SESSION_FILE" | sed 's/^- 等待输入类型：//' | xargs)
  if ! echo "$expected_input" | grep -qE '^(none|text|screenshot|document|design|confirmation|any)$'; then
    echo "FAIL invalid expected_input: $expected_input"
    errors=$((errors + 1))
  fi

  if [ "$waiting_state" != "none" ] && [ "$expected_input" = "none" ]; then
    echo "FAIL waiting session must record expected input"
    errors=$((errors + 1))
  fi

  if [ $errors -eq 0 ]; then
    echo "PASS session valid"
  else
    echo "FAILED with $errors error(s)"
    exit 1
  fi
}

# --- main ---
case "$ACTION" in
  read) cmd_read ;;
  init) cmd_init "$@" ;;
  update) cmd_update "$@" ;;
  wait) cmd_wait "$@" ;;
  reset) cmd_reset ;;
  validate) cmd_validate ;;
  *)
    echo "Usage: ff_session.sh {read|init|update|reset|validate} [options]"
    exit 1
    ;;
esac
