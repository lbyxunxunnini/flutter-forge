#!/usr/bin/env bash
# hook_check_rule_card.sh — preToolCall hook: 规则卡门禁
#
# 被 .claude/settings.json 的 preToolCall hook 调用。
# 当检测到 ff- 触发但规则卡未初始化时，输出阻断消息。
#
# 工作机制：
#   1. SKILL.md 指示 LLM 在路由步骤 1 运行 check_rule_card.sh
#   2. check_rule_card.sh 结果写入 .flutter-forge/runtime/rule_card_status.json
#   3. 本 hook 在后续工具调用前检查该状态文件
#   4. 若 not_found 且存在活跃会话 → 阻断并要求初始化
#
# 用法: hook_check_rule_card.sh <project_root>

set -euo pipefail

PROJECT_ROOT="${1:-.}"
STATUS_FILE="$PROJECT_ROOT/.flutter-forge/runtime/rule_card_status.json"

# 状态文件不存在或为空 → 首次调用，放行（让 LLM 先运行检查）
if [[ ! -s "$STATUS_FILE" ]]; then
  exit 0
fi

# 读取状态
status="$(python3 -c "import json; print(json.load(open('$STATUS_FILE'))['status'])" 2>/dev/null)" || {
  # 解析失败，放行
  exit 0
}

if [[ "$status" == "not_found" ]]; then
  echo "BLOCKED: 规则卡未初始化。请先执行项目初始化：运行 init_rule_card.py 扫描项目并生成规则卡草案，或确认无需规则卡后继续。"
  exit 2
fi

exit 0
