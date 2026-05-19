#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

info() {
  printf 'PASS %s\n' "$1"
}

version="$(tr -d '[:space:]' < VERSION)"
skillhub_version="$(python3 - <<'PY'
import json
print(json.load(open(".skillhub.json", encoding="utf-8"))["version"])
PY
)"
readme_version="$(python3 - <<'PY'
import re
text = open("README.md", encoding="utf-8").read()
match = re.search(r"当前版本：\*\*([^*]+)\*\*", text)
print(match.group(1) if match else "")
PY
)"
changelog_has_version="$(grep -c "^## ${version}$" CHANGELOG.md || true)"
top_changelog_version="$(python3 - <<'PY'
import re
text = open("CHANGELOG.md", encoding="utf-8").read()
match = re.search(r"^## (v?[0-9]+\.[0-9]+\.[0-9]+)\s*$", text, re.M)
print(match.group(1) if match else "")
PY
)"

[[ "$version" == "$skillhub_version" ]] || fail "VERSION ($version) != .skillhub.json ($skillhub_version)"
[[ "$version" == "$readme_version" ]] || fail "VERSION ($version) != README current version ($readme_version)"
[[ "$changelog_has_version" != "0" ]] || fail "CHANGELOG.md has no section for $version"

if [[ -n "$top_changelog_version" && "$top_changelog_version" != "$version" ]]; then
  fail "top CHANGELOG section is $top_changelog_version but VERSION is $version"
fi

info "version metadata is consistent: $version"

tracked_local_files="$(git ls-files | grep -E '(^|/)(\.DS_Store|\.flutter-forge/|\.claude/|memory/runtime/current_task\.yaml$)' || true)"
if [[ -n "$tracked_local_files" ]]; then
  printf '%s\n' "$tracked_local_files" >&2
  fail "local-only files are tracked"
fi
info "no tracked local-only files"

python3 scripts/validate_rule_card.py --allow-placeholders \
  references/rule_card_template.yaml \
  memory/projects/example_project.rule_card.yaml

python3 scripts/validate_flutter_stack_scan.py
python3 scripts/validate_rule_card_resolution.py
python3 scripts/project_snapshot.py tests/fixtures/flutter_sample >/dev/null
tmp_rule_card="$(mktemp -t flutter-forge-rule-card.XXXXXX.yaml)"
python3 scripts/init_rule_card.py tests/fixtures/flutter_sample --output "$tmp_rule_card" >/dev/null
grep -q 'recommended_profile: "riverpod_feature_profile"' "$tmp_rule_card" || fail "init_rule_card did not auto-detect riverpod profile"
python3 scripts/validate_rule_card.py "$tmp_rule_card" >/dev/null
rm -f "$tmp_rule_card"
python3 scripts/route_golden_tests.py

tmp_session_project="$(mktemp -d -t flutter-forge-session.XXXXXX)"
tmp_session_name="$(basename "$tmp_session_project")"
mkdir -p "$tmp_session_project/.claude/.flutter-forge/projects"
printf 'project_rule_card:\n  project_name: "%s"\n' "$tmp_session_name" > "$tmp_session_project/.claude/.flutter-forge/projects/${tmp_session_name}.rule_card.yaml"
session_init_output="$(scripts/ff_session.sh --project-root "$tmp_session_project" init --track execution --phase S2 --mode 页面开发)"
printf '%s\n' "$session_init_output" | grep -q "$tmp_session_project/.claude/.flutter-forge/session.md" || fail "ff_session did not use rule-card host session path"
scripts/ff_session.sh --project-root "$tmp_session_project" wait \
  --waiting_state artifact \
  --expected_input screenshot \
  --pending_question "请补充当前 UI 截图" \
  --task_object "订单详情页" \
  --resume_keys "订单详情页,截图" >/dev/null
scripts/ff_session.sh --project-root "$tmp_session_project" validate >/dev/null
grep -q '^- 等待状态：artifact' "$tmp_session_project/.claude/.flutter-forge/session.md" || fail "ff_session did not persist waiting_state"
grep -q '^- 等待输入类型：screenshot' "$tmp_session_project/.claude/.flutter-forge/session.md" || fail "ff_session did not persist expected_input"
rm -rf "$tmp_session_project"
info "session path and waiting-state validation passed"

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 页面工程师：轻量任务，直接执行' \
  '[f-forge] 页面工程师：已完成修改并完成基本验证' \
  | scripts/validate_output.sh --require-complete >/dev/null

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 全自动：已启用 ff-a，非阻塞缺口将采用推荐方案推进；安全、不可逆或高风险架构决策才中断确认。' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] UI 设计师：未提供设计图，自动采用推荐方案：沿用项目现有卡片列表风格。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 页面工程师：按自动冻结方案实现' \
  '[f-forge] 本轮完成：已完成自动实现和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 >/dev/null

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 页面工程师：中等任务，先扫描后执行' \
  '[f-forge] 页面工程师：已完成修改' \
  | scripts/validate_output.sh --require-complete >/dev/null 2>&1; then
  fail "validate_output accepted medium task without analysis role result"
fi

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 页面工程师：中等任务，先扫描后执行' \
  '[f-forge] 页面工程师：扫描结论：已定位 third_party_handler.dart 与 share_action_utils.dart，重复点集中在分享链接生成和邀请弹窗入口。' \
  '[f-forge] 页面工程师：执行策略：复用 share_action_utils 的链接生成与统一入口，只改 2 个文件，保持原弹窗触发时机和分享参数不变。' \
  '[f-forge] 页面工程师：改动契约：允许改动 third_party_handler.dart、share_action_utils.dart；禁止改动授权、登录、路由和埋点；确认状态：用户已确认。' \
  '[f-forge] 页面工程师：已完成修改' \
  | scripts/validate_output.sh --require-complete >/dev/null

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 页面工程师：中等任务，先扫描后执行' \
  '[f-forge] 页面工程师：扫描结论：已定位 third_party_handler.dart 与 share_action_utils.dart，重复点集中在分享链接生成和邀请弹窗入口。' \
  '[f-forge] 页面工程师：执行策略：复用 share_action_utils 的链接生成与统一入口，只改 2 个文件，保持原弹窗触发时机和分享参数不变。' \
  '[f-forge] 页面工程师：已完成修改' \
  | scripts/validate_output.sh --require-complete >/dev/null 2>&1; then
  fail "validate_output accepted medium task without pre-write change contract"
fi

if printf '%s\n' \
  '[f-forge] 页面工程师：轻量任务，直接执行' \
  '[f-forge] 页面工程师：改动契约：允许改动首页购买按钮点击处理；禁止改动路由表、支付流程和登录状态；行为不变项：按钮样式和埋点保持一致；确认状态：用户已确认。' \
  '[f-forge] 页面工程师：已完成修改并完成基本验证' \
  | scripts/validate_output.sh --require-complete >/dev/null 2>&1; then
  fail "validate_output accepted missing entry log"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求确认' \
  | scripts/validate_output.sh --require-complete >/dev/null 2>&1; then
  fail "validate_output accepted missing completion log"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求分析' \
  | scripts/validate_output.sh >/dev/null 2>&1; then
  fail "validate_output accepted invalid full phase name"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求确认' \
  '需求分析师：需求已确认' \
  | scripts/validate_output.sh >/dev/null 2>&1; then
  fail "validate_output accepted bare role result without [f-forge] prefix"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求确认' \
  '分析结论：需求已确认' \
  | scripts/validate_output.sh >/dev/null 2>&1; then
  fail "validate_output accepted bare conclusion without role prefix"
fi

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 页面工程师：方案已确认，继续进入实现' \
  | scripts/validate_output.sh >/dev/null

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 页面工程师：方案已确认，继续进入实现' \
  | scripts/validate_output.sh --require-s4 >/dev/null 2>&1; then
  fail "validate_output accepted S2 without S4 under --require-s4"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：UI 优化' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 页面工程师：直接实现' \
  | scripts/validate_output.sh --require-s4 >/dev/null 2>&1; then
  fail "validate_output accepted UI optimization S4 without S2 under --require-s4"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 页面工程师：直接实现' \
  | scripts/validate_output.sh --require-s4 >/dev/null 2>&1; then
  fail "validate_output accepted S2 to S4 without role result"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 页面工程师：改动契约：允许改动商品详情页相关文件；禁止改动支付、登录和全局主题；行为不变项：购买按钮行为保持一致；确认状态：等待用户确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 页面工程师：直接实现' \
  | scripts/validate_output.sh --require-s4 >/dev/null 2>&1; then
  fail "validate_output accepted S4 before user-confirmed change contract"
fi

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 页面工程师：方案已确认，继续进入实现' \
  '[f-forge] 页面工程师：改动契约：允许改动商品详情页相关文件；禁止改动全局路由表以外的业务模块；确认状态：用户已确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 本轮完成：已完成实现和验证' \
  | scripts/validate_output.sh --require-s4 --require-complete >/dev/null

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 页面工程师：方案已确认，继续进入实现' \
  '[f-forge] 页面工程师：改动契约：允许改动商品详情页相关文件；禁止改动全局路由表以外的业务模块；确认状态：用户已确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 本轮完成：已完成实现和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 >/dev/null

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：UI 优化' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] UI 设计师：头像 40x40，第二个压住第一个 8px；禁用播放保留视觉但拦截交互。' \
  '[f-forge] 页面工程师：改动契约：允许改动头像叠放与播放禁用态相关 UI；禁止改动业务状态和播放服务；确认状态：用户已确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 页面工程师：按已确认 UI 方案实现' \
  '[f-forge] 本轮完成：已完成 UI 调整和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 >/dev/null

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：启动握手' \
  '[f-forge] 主控：规则卡已初始化：.claude/.flutter-forge/projects/app.rule_card.yaml' \
  '[f-forge] 本轮完成：已完成规则卡初始化' \
  | scripts/validate_output.sh --require-complete >/dev/null

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 主控：任务描述不明确，请描述你想做什么（例如：新建页面、修改现有功能、修复 bug）。' \
  | scripts/validate_output.sh >/dev/null

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 规则卡已初始化：.claude/.flutter-forge/projects/app.rule_card.yaml' \
  '[f-forge] 本轮完成：已完成规则卡初始化' \
  | scripts/validate_output.sh --require-complete >/dev/null 2>&1; then
  fail "validate_output accepted rule-card status without role or mode"
fi

python3 scripts/validate_docs_sync.py

info "release validation completed"
