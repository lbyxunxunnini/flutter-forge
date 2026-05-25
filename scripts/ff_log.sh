#!/usr/bin/env bash
# ff_log.sh — 记录 [f-forge] 日志并自动更新 session
#
# 用法:
#   scripts/ff_log.sh --project-root <root> --phase S2 --mode 页面开发 --role 页面工程师 --message "扫描完成"
#   scripts/ff_log.sh --project-root <root> --enter-controller
#   scripts/ff_log.sh --project-root <root> --mode 功能开发 --reason "需求涉及跨页面状态联动"
#   scripts/ff_log.sh --project-root <root> --phase S4 --skip-s3
#   scripts/ff_log.sh --project-root <root> --complete "已完成订单导出功能"
#
# 功能:
#   1. 输出 [f-forge] 日志到 stdout
#   2. 同时写入 .flutter-forge/runtime/forge_log.txt
#   3. 自动更新 session 中的相关字段
#   4. 运行 validate_output.sh 校验日志格式

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_LOG_FILE=""
SESSION_SCRIPT="$SCRIPT_DIR/ff_session.sh"
VALIDATE_SCRIPT="$SCRIPT_DIR/validate_output.sh"

PROJECT_ROOT=""
PHASE=""
MODE=""
ROLE=""
MESSAGE=""
ENTER_CONTROLLER=false
MODE_REASON=""
SKIP_S3=false
COMPLETE_MSG=""
OUTPUT_VALIDATION=false

while [ $# -gt 0 ]; do
  case "$1" in
    --project-root) PROJECT_ROOT="$2"; shift 2 ;;
    --phase) PHASE="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --role) ROLE="$2"; shift 2 ;;
    --message) MESSAGE="$2"; shift 2 ;;
    --enter-controller) ENTER_CONTROLLER=true; shift ;;
    --reason) MODE_REASON="$2"; shift 2 ;;
    --skip-s3) SKIP_S3=true; shift ;;
    --complete) COMPLETE_MSG="$2"; shift 2 ;;
    --validate) OUTPUT_VALIDATION=true; shift ;;
    *) shift ;;
  esac
done

PROJECT_ROOT_ABS="$(cd "${PROJECT_ROOT:-.}" && pwd)"
RUNTIME_DIR="$PROJECT_ROOT_ABS/.flutter-forge/runtime"
FORGE_LOG_FILE="$RUNTIME_DIR/forge_log.txt"

mkdir -p "$RUNTIME_DIR" 2>/dev/null || true

phase_label() {
  case "$1" in
    C0) echo "C0 想法收口" ;;
    C1) echo "C1 方向共创" ;;
    C2) echo "C2 工程定型" ;;
    C3) echo "C3 首批范围冻结" ;;
    S0) echo "S0 未收口" ;;
    S1) echo "S1 需求确认" ;;
    S2) echo "S2 方案确认" ;;
    S3) echo "S3 拆包冻结" ;;
    S4) echo "S4 实现中" ;;
    S5) echo "S5 验证中" ;;
    S6) echo "S6 已收口" ;;
    *) echo "$1" ;;
  esac
}

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

write_log() {
  local log_line="$1"
  echo "$log_line"
  echo "$log_line" >> "$FORGE_LOG_FILE"
}

update_session_phase() {
  local phase="$1"
  if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
    bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" update \
      --phase "$phase" \
      --recent_action "[f-forge] 阶段：$(phase_label "$phase")" \
      --output_validation 未校验 \
      >/dev/null 2>&1 || true
  fi
}

update_session_mode() {
  local mode="$1"
  if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
    bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" update \
      --mode "$mode" \
      >/dev/null 2>&1 || true
  fi
}

update_session_role() {
  local role="$1"
  local role_key=""
  case "$role" in
    需求分析师) role_key="requirement_analyst" ;;
    UI\ 设计师) role_key="ui_designer" ;;
    架构设计师) role_key="architecture_designer" ;;
    页面工程师) role_key="page_engineer" ;;
    验证工程师) role_key="verify_agent" ;;
    主控) role_key="controller" ;;
    *) role_key="controller" ;;
  esac
  if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
    bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" update \
      --active_agents "$role_key" \
      >/dev/null 2>&1 || true
  fi
}

run_validation() {
  if [ -x "$VALIDATE_SCRIPT" ] && [ -f "$FORGE_LOG_FILE" ]; then
    local result
    result=$(bash "$VALIDATE_SCRIPT" < "$FORGE_LOG_FILE" 2>&1 || true)
    if echo "$result" | grep -q "PASS"; then
      if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
        bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" update \
          --output_validation 已通过 \
          --validation_phase "${PHASE:-S0}" \
          >/dev/null 2>&1 || true
      fi
    fi
  fi
}

if [ "$ENTER_CONTROLLER" = true ]; then
  write_log "[f-forge] 进入 controller"
  if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
    bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" init \
      --track execution \
      --phase S0 \
      --mode 未定 \
      >/dev/null 2>&1 || true
  fi
  exit 0
fi

if [ -n "$COMPLETE_MSG" ]; then
  write_log "[f-forge] 本轮完成：$COMPLETE_MSG"
  if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
    bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" update \
      --phase S6 \
      --mode_lock 可退出 \
      --exit_permission 允许 \
      --recent_action "[f-forge] 本轮完成：$COMPLETE_MSG" \
      >/dev/null 2>&1 || true
  fi
  run_validation
  exit 0
fi

if [ -n "$MODE" ]; then
  if [ ! -f "$FORGE_LOG_FILE" ] || ! grep -q "进入 controller" "$FORGE_LOG_FILE" 2>/dev/null; then
    write_log "[f-forge] 进入 controller"
    if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
      bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" init \
        --track execution \
        --phase S0 \
        --mode 未定 \
        >/dev/null 2>&1 || true
    fi
  fi
  if [ -n "$MODE_REASON" ]; then
    write_log "[f-forge] 模式：$MODE"
    write_log "- 升级原因：$MODE_REASON"
  else
    case "$MODE" in
      直通模式) write_log "[f-forge] 直通模式：快速处理" ;;
      轻量任务) write_log "[f-forge] 页面工程师：轻量任务，直接执行" ;;
      中等任务) write_log "[f-forge] 页面工程师：中等任务，先扫描后执行" ;;
      *) write_log "[f-forge] 模式：$MODE" ;;
    esac
  fi
  update_session_mode "$MODE"
fi

if [ -n "$PHASE" ]; then
  if [ ! -f "$FORGE_LOG_FILE" ] || ! grep -q "进入 controller" "$FORGE_LOG_FILE" 2>/dev/null; then
    write_log "[f-forge] 进入 controller"
    if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
      bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" init \
        --track execution \
        --phase S0 \
        --mode 未定 \
        >/dev/null 2>&1 || true
    fi
  fi
  if [ "$SKIP_S3" = true ]; then
    write_log "[f-forge] 主控：首批范围足够小，跳过 S3 拆包冻结，直接进入 S4 实现。"
  fi
  write_log "[f-forge] 阶段：$(phase_label "$PHASE")"
  update_session_phase "$PHASE"
fi

if [ -n "$ROLE" ] && [ -n "$MESSAGE" ]; then
  if [ ! -f "$FORGE_LOG_FILE" ] || ! grep -q "进入 controller" "$FORGE_LOG_FILE" 2>/dev/null; then
    write_log "[f-forge] 进入 controller"
    if [ -x "$SESSION_SCRIPT" ] && [ -n "$PROJECT_ROOT_ABS" ]; then
      bash "$SESSION_SCRIPT" --project-root "$PROJECT_ROOT_ABS" init \
        --track execution \
        --phase S0 \
        --mode 未定 \
        >/dev/null 2>&1 || true
    fi
  fi
  write_log "[f-forge] ${ROLE}：${MESSAGE}"
  update_session_role "$ROLE"
fi

if [ "$OUTPUT_VALIDATION" = true ]; then
  run_validation
fi
