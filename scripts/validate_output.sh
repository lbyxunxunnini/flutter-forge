#!/usr/bin/env bash
# validate_output.sh — 校验 LLM 输出是否符合 [f-forge] 可见性协议
#
# 用法: scripts/validate_output.sh [--require-complete] < <llm_output>
#   或: scripts/validate_output.sh [--require-complete] "llm output text"
#   或: scripts/validate_output.sh [--require-complete] /path/to/output_file
#
# 校验规则：
#   1. 含 [f-forge] 的行必须以 [f-forge] 开头
#   2. 第一条 [f-forge] 行必须是进入日志
#   3. 模式日志必须出现在阶段日志之前
#   4. 模式日志中的模式名必须在允许列表中
#   5. 阶段日志中的阶段编号必须合法
#   6. 角色名必须在允许列表中
#   7. --require-complete 时必须包含完成日志
#
# 输出: PASS 或 FAIL + 具体违规行和原因

set -euo pipefail

# 允许的模式名
ALLOWED_MODES="直通模式|轻量任务|中等任务|UI 优化|架构级任务|功能开发|页面开发|新项目共创|启动握手"

# 允许的阶段编号
ALLOWED_PHASES="C0|C1|C2|C3|S0|S1|S2|S3|S4|S5|S6"

# 允许的角色名
ALLOWED_ROLES="需求分析师|UI 设计师|架构设计师|页面工程师|验证工程师|主控"

# 读取输入
require_complete=false
if [ $# -ge 1 ] && [ "${1:-}" = "--require-complete" ]; then
  require_complete=true
  shift
fi

if [ $# -ge 1 ]; then
  if [ -f "$1" ]; then
    INPUT="$(cat "$1")"
  else
    INPUT="$*"
  fi
else
  INPUT="$(cat)"
fi

errors=0
line_num=0
has_forge=false
first_forge_seen=false
mode_seen=false
stage_seen=false
completion_seen=false
waiting_seen=false
exit_seen=false

while IFS= read -r line; do
  line_num=$((line_num + 1))

  # 跳过空行和非 [f-forge] 行
  if [ -z "$line" ]; then
    continue
  fi

  # 如果整段输出中没有任何 [f-forge] 行，跳过（可能是纯代码输出）
  if ! echo "$INPUT" | grep -q '\[f-forge\]'; then
    continue
  fi

  # 只检查含 [f-forge] 的行
  if echo "$line" | grep -q '\[f-forge\]'; then
    has_forge=true
    # 规则1: 必须以 [f-forge] 开头（允许前导空格）
    if ! echo "$line" | grep -qE '^[[:space:]]*\[f-forge\]'; then
      echo "FAIL line $line_num: [f-forge] not at line start: $line"
      errors=$((errors + 1))
    fi

    if [ "$first_forge_seen" = false ]; then
      first_forge_seen=true
      if ! echo "$line" | grep -qE '^[[:space:]]*\[f-forge\][[:space:]]+进入 controller[[:space:]]*$'; then
        echo "FAIL line $line_num: first [f-forge] line must be '[f-forge] 进入 controller': $line"
        errors=$((errors + 1))
      fi
    fi

    if echo "$line" | grep -qE '\[f-forge\][[:space:]]*(模式：|页面工程师：.*任务|直通模式：)'; then
      mode_seen=true
    fi

    if echo "$line" | grep -qE '\[f-forge\][[:space:]]*(本轮完成：|直通模式：完成|页面工程师：已完成|页面工程师：已按 ff-fast 完成)'; then
      completion_seen=true
    fi

    if echo "$line" | grep -qE '\[f-forge\][[:space:]]*主控：任务描述不明确'; then
      waiting_seen=true
    fi

    if echo "$line" | grep -qE '\[f-forge\][[:space:]]*误触发，退出'; then
      exit_seen=true
    fi

    # 规则2: 模式日志中的模式名校验
    if echo "$line" | grep -qE '\[f-forge\] *(模式：|页面工程师：.*任务|直通模式|页面工程师：ff-fast|全自动：)'; then
      # 提取模式名部分进行校验
      mode_part=$(echo "$line" | sed -E 's/.*\[f-forge\][[:space:]]*//' | sed -E 's/：.*//')
      # 对于 "模式：XXX" 格式，提取 XXX
      if echo "$line" | grep -qE '模式：'; then
        mode_name=$(echo "$line" | sed -E 's/.*模式：//' | sed -E 's/[[:space:]]*$//' | sed -E 's/[^一-龥a-zA-Z ]*$//')
        if ! echo "$mode_name" | grep -qE "^($ALLOWED_MODES)$"; then
          echo "FAIL line $line_num: invalid mode name '$mode_name'"
          errors=$((errors + 1))
        fi
      fi
    fi

    # 规则3: 阶段日志中的阶段编号校验
    if echo "$line" | grep -qE '阶段：'; then
      stage_seen=true
      if [ "$mode_seen" = false ]; then
        echo "FAIL line $line_num: phase log appears before mode log: $line"
        errors=$((errors + 1))
      fi
      phase=$(echo "$line" | sed -E 's/.*阶段：//' | sed -E 's/[[:space:]]*$//' | sed -E 's/ .*//')
      if ! echo "$phase" | grep -qE "^($ALLOWED_PHASES)$"; then
        echo "FAIL line $line_num: invalid phase '$phase'"
        errors=$((errors + 1))
      fi
    fi

    # 规则4: 角色名校验（[f-forge] 后面紧跟的角色名）
    if echo "$line" | grep -qE '\[f-forge\][[:space:]]+[^：]+：'; then
      role=$(echo "$line" | sed -E 's/.*\[f-forge\][[:space:]]*//' | sed -E 's/：.*//')
      # 跳过 "模式"、"阶段"、"全自动" 等非角色前缀
      if ! echo "$role" | grep -qE '^(模式|阶段|全自动|本轮完成|直通模式)'; then
        if ! echo "$role" | grep -qE "^($ALLOWED_ROLES)$"; then
          echo "FAIL line $line_num: invalid role name '$role'"
          errors=$((errors + 1))
        fi
      fi
    fi
  fi
done <<< "$INPUT"

if [ "$has_forge" = true ] && [ "$mode_seen" = false ] && [ "$waiting_seen" = false ] && [ "$exit_seen" = false ]; then
  echo "FAIL: missing [f-forge] mode log"
  errors=$((errors + 1))
fi

if [ "$has_forge" = true ] && [ "$require_complete" = true ] && [ "$completion_seen" = false ]; then
  echo "FAIL: missing [f-forge] completion log"
  errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
  echo "PASS"
  exit 0
else
  echo "FAILED with $errors error(s)"
  exit 1
fi
