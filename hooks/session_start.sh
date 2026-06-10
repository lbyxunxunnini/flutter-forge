#!/usr/bin/env bash
# session_start.sh — Flutter Forge Session Hook
# 会话启动时自动检测 Flutter 项目并注入上下文提示

set -euo pipefail

WORKSPACE_ROOT="${1:-.}"

# 1. 检测是否是 Flutter 项目
is_flutter_project() {
  local root="$1"
  if [[ -f "$root/pubspec.yaml" ]] && [[ -d "$root/lib" ]]; then
    # 检查 pubspec.yaml 是否包含 flutter 依赖
    if grep -q "flutter:" "$root/pubspec.yaml" 2>/dev/null || \
       grep -q "flutter_sdk:" "$root/pubspec.yaml" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# 2. 检查 flutter-forge 安装状态
check_forge_installed() {
  local paths=(
    "$HOME/.claude/skills/flutter-forge/SKILL.md"
    "$HOME/.trae/skills/flutter-forge/SKILL.md"
    "$HOME/.codex/skills/flutter-forge/SKILL.md"
    "$HOME/.agents/skills/flutter-forge/SKILL.md"
    "$HOME/.cc-switch/skills/flutter-forge/SKILL.md"
    "$HOME/.gemini/skills/flutter-forge/SKILL.md"
    "$HOME/.opencode/skills/flutter-forge/SKILL.md"
  )
  for p in "${paths[@]}"; do
    if [[ -f "$p" ]]; then
      echo "installed"
      return 0
    fi
  done
  echo "not_found"
  return 0
}

# 3. 检查 project_guardrails 状态
check_guardrails_status() {
  local root="$1"
  local status_file="$root/.flutter-forge/runtime/project_guardrails_status.json"
  if [[ -f "$status_file" ]]; then
    if grep -q '"status".*"found"' "$status_file" 2>/dev/null; then
      echo "found"
    elif grep -q '"status".*"missing"' "$status_file" 2>/dev/null; then
      echo "missing"
    else
      echo "unknown"
    fi
  else
    # 尝试查找 project_guardrails 文件
    if find "$root" -name "*.project_guardrails.yaml" -not -path "*/.venv/*" | head -1 | grep -q .; then
      echo "found"
    else
      echo "missing"
    fi
  fi
}

# 4. 主逻辑
main() {
  if ! is_flutter_project "$WORKSPACE_ROOT"; then
    # 不是 Flutter 项目，静默退出
    exit 0
  fi

  local forge_status
  forge_status=$(check_forge_installed)

  if [[ "$forge_status" == "not_found" ]]; then
    # flutter-forge 未安装，静默退出
    exit 0
  fi

  local guardrails_status
  guardrails_status=$(check_guardrails_status "$WORKSPACE_ROOT")

  # 输出 bootstrap 上下文提示
  echo "[flutter-forge] Flutter 项目已检测到。"
  echo "[flutter-forge] 可用触发词：ff-（标准）、ff-fast（快速）、ff-a（全自动）、/flutter-forge（原生斜杠命令）。"
  echo "[flutter-forge] 项目护栏状态：${guardrails_status}。"

  if [[ "$guardrails_status" == "missing" ]]; then
    echo "[flutter-forge] 首次接入建议：ff- 这是一个迭代中的 Flutter 项目，先扫描项目结构并初始化 project_guardrails，不要先写代码。"
  fi
}

main
