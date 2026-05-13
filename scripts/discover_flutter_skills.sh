#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_STATE_DIR="${PROJECT_ROOT}/.flutter-forge"
LOCAL_MAPPING_FILE="${LOCAL_STATE_DIR}/skill_mapping.local.env"

mkdir -p "${LOCAL_STATE_DIR}"

echo "[f-forge] 正在查询需要协作的 Flutter skill..."

COMMON_ROOTS=(
  "${PROJECT_ROOT}/.claude/skills"
  "${PROJECT_ROOT}/.agents/skills"
  "${PROJECT_ROOT}/.cc-switch/skills"
  "${PROJECT_ROOT}/.trae/skills"
  "${HOME}/.claude/skills"
  "${HOME}/.agents/skills"
  "${HOME}/.cc-switch/skills"
  "${HOME}/.trae/skills"
)

declare -a FOUND_ROOTS=()
declare -a FOUND_SUMMARIES=()
declare -a FOUND_TYPES=()

for root in "${COMMON_ROOTS[@]}"; do
  if [[ -d "${root}" ]]; then
    filtered=()
    while IFS= read -r skill; do
      [[ -z "${skill}" ]] && continue
      if [[ "${skill}" != "flutter-forge" ]]; then
        filtered+=("${skill}")
      fi
    done < <(find "${root}" -maxdepth 1 -mindepth 1 -type d -name 'flutter-*' -exec basename {} \; | sort)
    if [[ "${#filtered[@]}" -gt 0 ]]; then
      FOUND_ROOTS+=("${root}")
      case "${root}" in
        "${PROJECT_ROOT}/.claude/skills"|\
        "${PROJECT_ROOT}/.agents/skills"|\
        "${PROJECT_ROOT}/.cc-switch/skills"|\
        "${PROJECT_ROOT}/.trae/skills")
          FOUND_TYPES+=("项目内技能目录")
          ;;
        *)
          FOUND_TYPES+=("宿主根技能目录")
          ;;
      esac
      preview="$(printf '%s, ' "${filtered[@]:0:5}")"
      preview="${preview%, }"
      FOUND_SUMMARIES+=("${#filtered[@]} 个 Flutter skills（例如：${preview}）")
    fi
  fi
done

if [[ "${#FOUND_ROOTS[@]}" -eq 0 ]]; then
  cat <<'EOF'
[f-forge] 未在常见目录中检测到可协作的 Flutter skills。
你可以继续使用 Flutter Forge 内置流程，但将无法直接映射官方/等价 Flutter skills。

官方地址：
- 仓库：https://github.com/flutter/skills
- 文档：https://docs.flutter.dev/ai/agent-skills

建议安装：
  npx skills add flutter/skills --skill '*' --agent universal
EOF
  exit 0
fi

echo
echo "[f-forge] 已找到以下可选协作技能目录："
for i in "${!FOUND_ROOTS[@]}"; do
  idx=$((i + 1))
  echo "  ${idx}. ${FOUND_ROOTS[$i]}"
  echo "     类型：${FOUND_TYPES[$i]}"
  echo "     ${FOUND_SUMMARIES[$i]}"
done

echo
printf "请选择 flutter-forge 的协作技能映射路径 [1-%d]（直接回车默认 1）： " "${#FOUND_ROOTS[@]}"
read -r choice

if [[ -z "${choice}" ]]; then
  choice=1
fi

if ! [[ "${choice}" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#FOUND_ROOTS[@]} )); then
  echo "[f-forge] 输入无效，取消写入映射配置。"
  exit 1
fi

selected_root="${FOUND_ROOTS[$((choice - 1))]}"
selected_type="${FOUND_TYPES[$((choice - 1))]}"

cat > "${LOCAL_MAPPING_FILE}" <<EOF
# local only, ignored by git
FLUTTER_FORGE_SKILL_SOURCE="${selected_root}"
FLUTTER_FORGE_SKILL_SOURCE_TYPE="${selected_type}"
FLUTTER_FORGE_SKILL_SOURCE_SET_AT="$(date '+%Y-%m-%d %H:%M:%S')"
EOF

echo
echo "[f-forge] 已写入本地协作技能映射："
echo "  ${LOCAL_MAPPING_FILE}"
echo "[f-forge] 当前选定类型："
echo "  ${selected_type}"
echo "[f-forge] 当前选定目录："
echo "  ${selected_root}"
