#!/usr/bin/env bash
# hook_check_rule_card.sh — preToolCall hook: 规则卡门禁（按工具类型分级）
#
# 被 .claude/settings.json 的 preToolCall hook 调用。
#
# 工作机制：
#   1. 优先读取 .flutter-forge/runtime/rule_card_status.json 缓存（300s TTL）
#   2. 缓存命中：直接消费状态，不重跑 check_rule_card.sh
#   3. 缓存未命中：调用 check_rule_card.sh --cached 300（脚本内部会再回退完整检查）
#   4. status == not_found 且工具是写操作（Edit/MultiEdit/Write）→ 输出 JSON block 决策并 exit 2
#   5. status == not_found 但工具是读操作或命令执行 → 软提醒（stderr 输出，不阻断）
#   6. status == found / draft → 放行
#   7. 当工具调用本身就是规则卡初始化相关命令时放行（避免初始化死锁）
#   8. 脚本不可用或解析异常时放行（fail-open，避免误阻断）
#
# 用法: hook_check_rule_card.sh <project_root>

set -euo pipefail

PROJECT_ROOT="${1:-.}"

# 解析 hook 输入：Claude Code preToolCall hook 通过 stdin 传 JSON
# 格式参考: { "tool_name": "...", "tool_input": {...} }
HOOK_INPUT=""
if [ ! -t 0 ]; then
  HOOK_INPUT="$(cat 2>/dev/null || true)"
fi

# 提取 tool_name 与 command 文本
TOOL_NAME=""
COMMAND_TEXT=""
if [ -n "$HOOK_INPUT" ]; then
  TOOL_INFO="$(printf '%s' "$HOOK_INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    name = data.get('tool_name', '')
    cmd = data.get('tool_input', {}).get('command', '') or ''
    print(name)
    print(cmd)
except Exception:
    print('')
    print('')
" 2>/dev/null || printf '\n\n')"
  TOOL_NAME="$(printf '%s' "$TOOL_INFO" | sed -n '1p')"
  COMMAND_TEXT="$(printf '%s' "$TOOL_INFO" | sed -n '2p')"
fi

# 初始化白名单：当工具调用本身就是规则卡初始化、检查或修复时放行
# 防止 hook 阻断初始化流程导致死锁
if [ -n "$COMMAND_TEXT" ]; then
  if printf '%s' "$COMMAND_TEXT" | grep -qE '(check_rule_card\.sh|init_rule_card\.py|hook_check_rule_card\.sh|project_snapshot\.py|find_existing_rules\.sh|flutter_stack_scan\.py|validate_rule_card)'; then
    exit 0
  fi
fi

# 解析 skill 安装目录（脚本所在目录的父目录）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_SCRIPT="$SCRIPT_DIR/check_rule_card.sh"

# 脚本不存在 → fail-open
if [ ! -x "$CHECK_SCRIPT" ]; then
  exit 0
fi

# 优先用缓存（TTL 300s），未命中时脚本内部会回退到完整检查
RAW="$(bash "$CHECK_SCRIPT" "$PROJECT_ROOT" --cached 300 2>/dev/null || true)"

# 解析失败 → fail-open
if [ -z "$RAW" ]; then
  exit 0
fi

STATUS="$(printf '%s' "$RAW" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('status', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")"

# 写操作工具列表：未初始化时硬阻断
case "$TOOL_NAME" in
  Edit|MultiEdit|Write|str_replace|fs_write|fs_append|smartRelocate|semanticRename)
    IS_WRITE="true"
    ;;
  *)
    IS_WRITE="false"
    ;;
esac

if [ "$STATUS" = "not_found" ]; then
  if [ "$IS_WRITE" = "true" ]; then
    # 硬阻断：写操作前必须有规则卡
    python3 -c "
import json, sys
json.dump({
    'permissionDecision': 'block',
    'reason': '规则卡未初始化，且当前工具调用涉及代码改动。请先运行 scripts/init_rule_card.py 扫描项目并生成规则卡草案，确认后再继续；或确认无需规则卡（直通/轻量任务）后通过非写操作执行。'
}, sys.stdout, ensure_ascii=False)
"
    exit 2
  else
    # 软提醒：读操作和命令执行不阻断，但写到 stderr 提醒
    printf '[hook] rule_card not_found（读操作放行；写操作前请先 init_rule_card）\n' >&2
    exit 0
  fi
fi

# found / draft / 解析为空 → 放行
exit 0
