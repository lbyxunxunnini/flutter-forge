#!/usr/bin/env bash
# hook_check_rule_card.sh — preToolCall hook: 规则卡门禁
#
# 被 .claude/settings.json 的 preToolCall hook 调用。
# 通过直接调用 check_rule_card.sh 自行检测规则卡状态，不依赖 LLM 写入状态文件。
#
# 工作机制：
#   1. 直接执行 check_rule_card.sh --json 获取当前项目规则卡状态
#   2. status == not_found 时输出 JSON block 决策并 exit 2
#   3. status == found / draft 时放行
#   4. 当工具调用本身就是规则卡初始化相关命令时放行（避免初始化死锁）
#   5. 脚本不可用或解析异常时放行（fail-open，避免误阻断）
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

# 初始化白名单：当工具调用本身就是规则卡初始化、检查或修复时放行
# 防止 hook 阻断初始化流程导致死锁
if [ -n "$HOOK_INPUT" ]; then
  # 提取 tool_input 中的 command 字段（仅对 Bash 类工具有效）
  COMMAND_TEXT="$(printf '%s' "$HOOK_INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command', '')
    print(cmd)
except Exception:
    pass
" 2>/dev/null || true)"

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

# 直接调用 check_rule_card.sh --json，不依赖状态文件
RAW="$(bash "$CHECK_SCRIPT" "$PROJECT_ROOT" --json 2>/dev/null || true)"

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

if [ "$STATUS" = "not_found" ]; then
  python3 -c "
import json, sys
json.dump({
    'permissionDecision': 'block',
    'reason': '规则卡未初始化。请先运行 scripts/init_rule_card.py 扫描项目并生成规则卡草案，或确认无需规则卡后再继续。'
}, sys.stdout, ensure_ascii=False)
"
  exit 2
fi

# found / draft / 解析为空 → 放行
exit 0
