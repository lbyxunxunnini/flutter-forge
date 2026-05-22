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

python3 scripts/validate_project_guardrails.py --allow-placeholders \
  references/project_guardrails_template.yaml \
  memory/projects/example_project.project_guardrails.yaml

python3 scripts/validate_flutter_stack_scan.py
python3 scripts/validate_project_guardrails_resolution.py
python3 scripts/project_snapshot.py tests/fixtures/flutter_sample >/dev/null
tmp_guardrails="$(mktemp -t flutter-forge-guardrails.XXXXXX.yaml)"
python3 scripts/init_project_guardrails.py tests/fixtures/flutter_sample --output "$tmp_guardrails" >/dev/null
grep -q 'root_type: "flutter_existing"' "$tmp_guardrails" || fail "init_project_guardrails did not detect flutter_existing"
grep -q 'project_guardrails:' "$tmp_guardrails" || fail "init_project_guardrails did not use project_guardrails root key"
grep -q '_draft' "$tmp_guardrails" && fail "init_project_guardrails still generates draft files"
rm -f "$tmp_guardrails"
info "init_project_guardrails validation passed"

tmp_empty_project="$(mktemp -d -t flutter-forge-empty.XXXXXX)"
empty_state="$(python3 scripts/detect_project_root_state.py "$tmp_empty_project")"
printf '%s\n' "$empty_state" | grep -q '"root_type": "empty_new"' || fail "detect_project_root_state did not classify empty dir as empty_new"
printf '%s\n' "$empty_state" | grep -q '"forge_enabled": true' || fail "detect_project_root_state did not enable forge for empty_new"
rm -rf "$tmp_empty_project"

tmp_non_flutter="$(mktemp -d -t flutter-forge-nonflutter.XXXXXX)"
printf 'hello\n' > "$tmp_non_flutter/README.md"
non_flutter_state="$(python3 scripts/detect_project_root_state.py "$tmp_non_flutter")"
printf '%s\n' "$non_flutter_state" | grep -q '"root_type": "non_flutter"' || fail "detect_project_root_state did not classify non-flutter workspace"
printf '%s\n' "$non_flutter_state" | grep -q '"forge_enabled": false' || fail "detect_project_root_state did not disable forge for non-flutter workspace"
rm -rf "$tmp_non_flutter"
python3 scripts/route_golden_tests.py

tmp_session_project="$(mktemp -d -t flutter-forge-session.XXXXXX)"
tmp_session_name="$(basename "$tmp_session_project")"
mkdir -p "$tmp_session_project/.claude/.flutter-forge/projects"
printf 'project_guardrails:\n  project:\n    name: "%s"\n    root_type: "flutter_existing"\n' "$tmp_session_name" > "$tmp_session_project/.claude/.flutter-forge/projects/${tmp_session_name}.project_guardrails.yaml"
session_init_output="$(scripts/ff_session.sh --project-root "$tmp_session_project" init --track execution --phase S2 --mode 页面开发)"
printf '%s\n' "$session_init_output" | grep -q "$tmp_session_project/.claude/.flutter-forge/session.md" || fail "ff_session did not use project_guardrails host session path"
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

tmp_resume_project="$(mktemp -d -t flutter-forge-resume.XXXXXX)"
tmp_resume_name="$(basename "$tmp_resume_project")"
mkdir -p "$tmp_resume_project/.claude/.flutter-forge/projects"
printf 'project_guardrails:\n  project:\n    name: "%s"\n    root_type: "flutter_existing"\n' "$tmp_resume_name" > "$tmp_resume_project/.claude/.flutter-forge/projects/${tmp_resume_name}.project_guardrails.yaml"
scripts/ff_session.sh --project-root "$tmp_resume_project" init --track execution --phase S2 --mode 页面开发 >/dev/null
scripts/ff_session.sh --project-root "$tmp_resume_project" save-resume \
  --waiting_state confirmation \
  --expected_input confirmation \
  --pending_question "方案A和方案B你倾向哪个？" \
  --task_object "订单详情页" \
  --resume_keys "订单详情页,方案A,方案B" >/dev/null
resume_check_output="$(scripts/ff_session.sh --project-root "$tmp_resume_project" check-resume --user-input "方案A")"
printf '%s\n' "$resume_check_output" | grep -q 'status: resume_match' || fail "ff_session did not detect resume match"
printf '%s\n' "$resume_check_output" | grep -q 'phase: S2' || fail "ff_session resume did not keep phase"
scripts/ff_session.sh --project-root "$tmp_resume_project" save-resume \
  --waiting_state artifact \
  --expected_input screenshot \
  --pending_question "请补充当前 UI 截图" \
  --task_object "订单详情页" \
  --resume_keys "订单详情页,截图" >/dev/null
artifact_resume_output="$(scripts/ff_session.sh --project-root "$tmp_resume_project" check-resume --user-input "" --has-attachment true)"
printf '%s\n' "$artifact_resume_output" | grep -q 'status: resume_match' || fail "ff_session did not detect attachment-only resume"
printf '%s\n' "$artifact_resume_output" | grep -q 'reason: artifact_reply' || fail "ff_session attachment resume reason mismatch"
scripts/ff_session.sh --project-root "$tmp_resume_project" consume-resume --user-input "方案A" >/dev/null
grep -q '^- 等待状态：none' "$tmp_resume_project/.claude/.flutter-forge/session.md" || fail "ff_session did not clear waiting_state after consume-resume"
grep -q '\[f-forge\] 等待：等待用户确认改动契约' "$tmp_resume_project/.flutter-forge/runtime/session_events.log" || fail "ff_session did not append waiting event"
grep -q '\[f-forge\] 恢复等待：已消费用户补充输入，继续当前阶段。' "$tmp_resume_project/.flutter-forge/runtime/session_events.log" || fail "ff_session did not append resume-consumed event"
rm -rf "$tmp_resume_project"
info "session resume and event logging validation passed"

tmp_gate_project="$(mktemp -d -t flutter-forge-gate.XXXXXX)"
tmp_gate_name="$(basename "$tmp_gate_project")"
mkdir -p "$tmp_gate_project/.claude/.flutter-forge/projects" "$tmp_gate_project/.flutter-forge/runtime"
printf 'project_guardrails:\n  project:\n    name: "%s"\n    root_type: "flutter_existing"\n' "$tmp_gate_name" > "$tmp_gate_project/.claude/.flutter-forge/projects/${tmp_gate_name}.project_guardrails.yaml"
scripts/ff_session.sh --project-root "$tmp_gate_project" init --track execution --phase S2 --mode 页面开发 >/dev/null
cat > "$tmp_gate_project/.flutter-forge/runtime/task_gate.json" <<'EOF'
{
  "project_root": "REPLACE_PROJECT_ROOT",
  "project_root_state": "flutter_existing",
  "forge_enabled": true,
  "mode": "页面开发",
  "confidence": "high",
  "policy": "标准",
  "matched_by": "manual",
  "should_load_guardrails": true,
  "guardrails_check": "required",
  "allow_write_without_guardrails": false,
  "checked_at": 9999999999
}
EOF
python3 - <<'PY' "$tmp_gate_project/.flutter-forge/runtime/task_gate.json" "$tmp_gate_project"
import json, sys
path, root = sys.argv[1], sys.argv[2]
data = json.load(open(path, encoding="utf-8"))
data["project_root"] = root
json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
gate_output="$(python3 scripts/gate_check.py --project-root "$tmp_gate_project" --target-path lib/features/order/detail_page.dart --mode observe)"
printf '%s\n' "$gate_output" | grep -q '"decision": "would_block"' || fail "gate_check did not report would_block before S4"
printf '%s\n' "$gate_output" | grep -q '"gate": "phase_progression"' || fail "gate_check did not report phase gate"
gate_config_output="$(python3 scripts/gate_check.py --project-root "$tmp_gate_project" --target-path pubspec.yaml --mode observe)"
printf '%s\n' "$gate_config_output" | grep -q '"decision": "would_block"' || fail "gate_check did not block project config before S4"
printf '%s\n' "$gate_config_output" | grep -q '"target_kind": "project_config"' || fail "gate_check did not classify pubspec.yaml as project_config"
scripts/ff_session.sh --project-root "$tmp_gate_project" update --phase S4 --change_contract "允许改 detail_page.dart" --confirmation_status 用户已确认 >/dev/null
gate_allow_output="$(python3 scripts/gate_check.py --project-root "$tmp_gate_project" --target-path lib/features/order/detail_page.dart --mode enforce)"
printf '%s\n' "$gate_allow_output" | grep -q '"decision": "allow"' || fail "gate_check did not allow confirmed S4 write"
gate_config_allow_output="$(python3 scripts/gate_check.py --project-root "$tmp_gate_project" --target-path pubspec.yaml --mode enforce)"
printf '%s\n' "$gate_config_allow_output" | grep -q '"decision": "allow"' || fail "gate_check did not allow confirmed project config write in S4"
scripts/ff_session.sh --project-root "$tmp_gate_project" update --confirmation_status 未确认 >/dev/null
python3 - <<'PY' "$tmp_gate_project/.flutter-forge/runtime/task_gate.json"
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["policy"] = "全自动"
json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
gate_auto_output="$(python3 scripts/gate_check.py --project-root "$tmp_gate_project" --target-path lib/features/order/detail_page.dart --mode enforce)"
printf '%s\n' "$gate_auto_output" | grep -q '"decision": "allow"' || fail "gate_check did not exempt autonomous policy"
python3 - <<'PY' "$tmp_gate_project/.flutter-forge/runtime/task_gate.json"
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["policy"] = "标准"
json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
hook_input='{"tool_name":"Write","tool_input":{"file_path":"lib/features/order/detail_page.dart"}}'
set +e
hook_output="$(printf '%s' "$hook_input" | FF_GATE_MODE=enforce bash scripts/hook_check_project_guardrails.sh "$tmp_gate_project" 2>&1)"
hook_status=$?
set -e
[ "$hook_status" -eq 2 ] || fail "hook_check_project_guardrails did not block gated write"
printf '%s\n' "$hook_output" | grep -q 'permissionDecision' || fail "hook_check_project_guardrails did not emit block payload"
controller_output="$(python3 scripts/controller.py run --project-root "$tmp_gate_project" --user-input "方案A" --target-path lib/features/order/detail_page.dart)"
printf '%s\n' "$controller_output" | grep -q '"role": "page_engineer"' || fail "controller did not choose compatible role from session phase"
printf '%s\n' "$controller_output" | grep -q '"decision": "would_block"' || fail "controller did not surface gate output"
rm -rf "$tmp_gate_project"
info "gate and controller validation passed"

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 页面工程师：轻量任务，直接执行' \
  '[f-forge] 页面工程师：已完成修改并完成基本验证' \
  | scripts/validate_output.sh --require-complete >/dev/null

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 全自动：已启用 ff-a，非阻塞缺口将采用推荐方案推进；安全、不可逆或高风险架构决策才中断确认。' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求确认' \
  '[f-forge] 需求分析师：商品详情页目标已冻结，首屏包含轮播图、价格区和底部购买栏。' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] UI 设计师：未提供设计图，自动采用推荐方案：沿用项目现有卡片列表风格。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 页面工程师：按自动冻结方案实现' \
  '[f-forge] 阶段：S5 验证中' \
  '[f-forge] 验证工程师：已覆盖首屏结构、规格联动和底部购买按钮状态。' \
  '[f-forge] 全自动摘要：本轮自动采用 2 项推荐方案：详情页卡片风格；页面级状态接入沿用项目主流方案。' \
  '[f-forge] 本轮完成：已完成自动实现和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 --expect-autonomous >/dev/null

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

if printf '%s\n' \
  '模式：页面开发' \
  '阶段：S1 需求确认' \
  '需求分析师：需求已确认' \
  '本轮完成：任务已完成' \
  | scripts/validate_output.sh --require-complete >/dev/null 2>&1; then
  fail "validate_output accepted workflow output without any [f-forge] prefix"
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

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 架构设计师：方案已冻结，继续进入实现' \
  '[f-forge] 页面工程师：改动契约：允许改动商品详情页相关文件；禁止改动全局路由表以外的业务模块；确认状态：用户已确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 阶段：S5 验证中' \
  '[f-forge] 验证工程师：已完成验证' \
  '[f-forge] 本轮完成：已完成实现和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 >/dev/null 2>&1; then
  fail "validate_output accepted page development chain without S1"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：功能开发' \
  '[f-forge] 阶段：S1 需求确认' \
  '[f-forge] 需求分析师：需求已冻结' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 架构设计师：方案已冻结' \
  '[f-forge] 页面工程师：改动契约：允许改动登录流程相关文件；禁止改动支付与埋点；确认状态：用户已确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 本轮完成：已完成实现和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 >/dev/null 2>&1; then
  fail "validate_output accepted heavy workflow without S5"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求确认' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 架构设计师：方案已冻结' \
  '[f-forge] 页面工程师：改动契约：允许改动商品详情页相关文件；禁止改动全局路由表以外的业务模块；确认状态：用户已确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 阶段：S5 验证中' \
  '[f-forge] 验证工程师：已完成验证' \
  '[f-forge] 本轮完成：已完成实现和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 >/dev/null 2>&1; then
  fail "validate_output accepted page development without S1 role result"
fi

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求确认' \
  '[f-forge] 需求分析师：需求已冻结，首屏包含轮播图、价格区和底部购买栏。' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 页面工程师：方案已确认，继续进入实现' \
  '[f-forge] 页面工程师：改动契约：允许改动商品详情页相关文件；禁止改动全局路由表以外的业务模块；确认状态：用户已确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 阶段：S5 验证中' \
  '[f-forge] 验证工程师：已完成详情页结构和底部购买栏验证。' \
  '[f-forge] 本轮完成：已完成实现和验证' \
  | scripts/validate_output.sh --require-s4 --require-complete >/dev/null

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求确认' \
  '[f-forge] 需求分析师：需求已冻结，首屏包含轮播图、价格区和底部购买栏。' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] 页面工程师：方案已确认，继续进入实现' \
  '[f-forge] 页面工程师：改动契约：允许改动商品详情页相关文件；禁止改动全局路由表以外的业务模块；确认状态：用户已确认。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 阶段：S5 验证中' \
  '[f-forge] 验证工程师：已完成详情页结构和底部购买栏验证。' \
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
  '[f-forge] 阶段：S5 验证中' \
  '[f-forge] 验证工程师：已完成头像叠放和禁用态验证。' \
  '[f-forge] 本轮完成：已完成 UI 调整和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 >/dev/null

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 页面工程师：中等任务，先扫描后执行' \
  '[f-forge] 页面工程师：扫描结论：已定位订单列表筛选逻辑。' \
  '[f-forge] 页面工程师：执行策略：只改订单筛选渲染和本地文案。' \
  '[f-forge] 页面工程师：改动契约：允许改动 order_page.dart；禁止改动路由、状态管理和接口协议；确认状态：用户已确认。' \
  '[f-forge] 页面工程师：已按 ff-fast 完成修改并完成最小验证。' \
  | scripts/validate_output.sh --require-complete --expect-fast >/dev/null 2>&1; then
  fail "validate_output accepted ff-fast task without startup log"
fi

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 全自动：已启用 ff-a，非阻塞缺口将采用推荐方案推进；安全、不可逆或高风险架构决策才中断确认。' \
  '[f-forge] 模式：页面开发' \
  '[f-forge] 阶段：S1 需求确认' \
  '[f-forge] 需求分析师：自动采用推荐方案 A。' \
  '[f-forge] 阶段：S2 方案确认' \
  '[f-forge] UI 设计师：自动采用推荐方案 B。' \
  '[f-forge] 阶段：S4 实现中' \
  '[f-forge] 阶段：S5 验证中' \
  '[f-forge] 验证工程师：已完成验证。' \
  '[f-forge] 本轮完成：已完成自动实现和验证' \
  | scripts/validate_output.sh --require-complete --require-s4 --expect-autonomous >/dev/null 2>&1; then
  fail "validate_output accepted autonomous task without autonomous summary"
fi

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 模式：启动握手' \
  '[f-forge] 主控：project_guardrails 已初始化：.claude/.flutter-forge/projects/app.project_guardrails.yaml' \
  '[f-forge] 本轮完成：已完成项目锚点初始化' \
  | scripts/validate_output.sh --require-complete >/dev/null

printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] 主控：任务描述不明确，请描述你想做什么（例如：新建页面、修改现有功能、修复 bug）。' \
  | scripts/validate_output.sh >/dev/null

if printf '%s\n' \
  '[f-forge] 进入 controller' \
  '[f-forge] project_guardrails 已初始化：.claude/.flutter-forge/projects/app.project_guardrails.yaml' \
  '[f-forge] 本轮完成：已完成项目锚点初始化' \
  | scripts/validate_output.sh --require-complete >/dev/null 2>&1; then
  fail "validate_output accepted project_guardrails status without role or mode"
fi

python3 scripts/validate_docs_sync.py

info "release validation completed"
