#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

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
# Parse JSON output
printf '%s\n' "$resume_check_output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('status')=='resume_match', f'expected resume_match, got {d}'" || fail "ff_session did not detect resume match"
printf '%s\n' "$resume_check_output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('phase')=='S2', f'expected S2, got {d.get(\"phase\")}'" || fail "ff_session resume did not keep phase"
scripts/ff_session.sh --project-root "$tmp_resume_project" save-resume \
  --waiting_state artifact \
  --expected_input screenshot \
  --pending_question "请补充当前 UI 截图" \
  --task_object "订单详情页" \
  --resume_keys "订单详情页,截图" >/dev/null
artifact_resume_output="$(scripts/ff_session.sh --project-root "$tmp_resume_project" check-resume --user-input "" --has-attachment true)"
printf '%s\n' "$artifact_resume_output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('status')=='resume_match', f'expected resume_match, got {d}'" || fail "ff_session did not detect attachment-only resume"
printf '%s\n' "$artifact_resume_output" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('reason')=='artifact_reply', f'expected artifact_reply, got {d.get(\"reason\")}'" || fail "ff_session attachment resume reason mismatch"
scripts/ff_session.sh --project-root "$tmp_resume_project" consume-resume --user-input "方案A" >/dev/null
grep -q '^- 等待状态：none' "$tmp_resume_project/.claude/.flutter-forge/session.md" || fail "ff_session did not clear waiting_state after consume-resume"
grep -q '\[f-forge\] 主控：等待，等待用户确认改动契约' "$tmp_resume_project/.flutter-forge/runtime/session_events.log" || fail "ff_session did not append waiting event"
grep -q '\[f-forge\] 主控：恢复等待，已消费用户补充输入，继续当前阶段。' "$tmp_resume_project/.flutter-forge/runtime/session_events.log" || fail "ff_session did not append resume-consumed event"
rm -rf "$tmp_resume_project"
info "session resume and event logging validation passed"

tmp_prompt_project="$(mktemp -d -t flutter-forge-prompt.XXXXXX)"
scripts/ff_session.sh --project-root "$tmp_prompt_project" init --track execution --phase S5 --mode 页面开发 >/dev/null
summary_file="$tmp_prompt_project/summary.md"
cat > "$summary_file" <<'EOF'
需求冻结摘要包:
- 目标: 商品详情页
rubric_items:
- id: UNIQUE-RUBRIC-999
  criterion: verify unique business rule
previous_scores:
- SCORE-HISTORY-SECRET
page_engineer_checklist:
- SELF-CHECK-SECRET
implementation_thoughts:
- IMPLEMENTATION-THOUGHT-SECRET
code_files:
- lib/unique_product_page.dart
EOF
scripts/ff_session.sh --project-root "$tmp_prompt_project" update \
  --summary_package "$summary_file" \
  --current_work_unit "商品详情页" \
  --work_unit_status 待验证 \
  --verification_status 验证中 >/dev/null
verify_prompt_output="$(python3 scripts/controller.py generate-agent-prompt --project-root "$tmp_prompt_project" --role verify_agent --user-input "继续验证商品详情页")"
printf '%s\n' "$verify_prompt_output" | grep -q 'UNIQUE-RUBRIC-999' || fail "controller prompt did not include Rubric items for verify_agent"
printf '%s\n' "$verify_prompt_output" | grep -q 'SCORE-HISTORY-SECRET' || fail "controller prompt did not include score history for verify_agent"
printf '%s\n' "$verify_prompt_output" | grep -q 'lib/unique_product_page.dart' || fail "controller prompt did not include code files for verify_agent"
if printf '%s\n' "$verify_prompt_output" | grep -q 'SELF-CHECK-SECRET'; then
  fail "controller prompt leaked page_engineer self-check to verify_agent"
fi
if printf '%s\n' "$verify_prompt_output" | grep -q 'IMPLEMENTATION-THOUGHT-SECRET'; then
  fail "controller prompt leaked implementation thoughts to verify_agent"
fi
page_prompt_output="$(python3 scripts/controller.py generate-agent-prompt --project-root "$tmp_prompt_project" --role page_engineer --user-input "继续实现商品详情页")"
if printf '%s\n' "$page_prompt_output" | grep -q 'UNIQUE-RUBRIC-999'; then
  fail "controller prompt leaked concrete Rubric items to page_engineer"
fi
if printf '%s\n' "$page_prompt_output" | grep -q 'SCORE-HISTORY-SECRET'; then
  fail "controller prompt leaked score history to page_engineer"
fi
printf '%s\n' "$page_prompt_output" | grep -q 'lib/unique_product_page.dart' || fail "controller prompt stripped non-sensitive summary context from page_engineer"
rm -rf "$tmp_prompt_project"
info "controller prompt summary package filtering validation passed"

tmp_iteration_project="$(mktemp -d -t flutter-forge-iteration.XXXXXX)"
tmp_iteration_name="$(basename "$tmp_iteration_project")"
mkdir -p "$tmp_iteration_project/.claude/.flutter-forge/projects"
printf 'project_guardrails:\n  project:\n    name: "%s"\n    root_type: "flutter_existing"\n' "$tmp_iteration_name" > "$tmp_iteration_project/.claude/.flutter-forge/projects/${tmp_iteration_name}.project_guardrails.yaml"
scripts/ff_session.sh --project-root "$tmp_iteration_project" init --track execution --phase S5 --mode 页面开发 >/dev/null

force_back_output="$(scripts/ff_session.sh --project-root "$tmp_iteration_project" iteration-update --round-score 3.50 --essential-pass-rate 0.8 --pitfall-violations 0 --score-threshold 4.0 --max-rounds 5)"
printf '%s\n' "$force_back_output" | grep -q 'decision_hint: force_back_to_implementation' || fail "ff_session did not emit force_back_to_implementation for failed essential pass rate"

scripts/ff_session.sh --project-root "$tmp_iteration_project" reset >/dev/null
scripts/ff_session.sh --project-root "$tmp_iteration_project" init --track execution --phase S5 --mode 页面开发 >/dev/null
scripts/ff_session.sh --project-root "$tmp_iteration_project" iteration-update --round-score 3.80 --essential-pass-rate 1.0 --pitfall-violations 0 --score-threshold 4.0 --max-rounds 5 >/dev/null
scripts/ff_session.sh --project-root "$tmp_iteration_project" iteration-update --round-score 3.85 --essential-pass-rate 1.0 --pitfall-violations 0 --score-threshold 4.0 --max-rounds 5 >/dev/null
marginal_stall_output="$(scripts/ff_session.sh --project-root "$tmp_iteration_project" iteration-update --round-score 3.89 --essential-pass-rate 1.0 --pitfall-violations 0 --score-threshold 4.0 --max-rounds 5)"
printf '%s\n' "$marginal_stall_output" | grep -q 'decision_hint: marginal_stall' || fail "ff_session did not emit marginal_stall for repeated low marginal improvement"
grep -q '^- 迭代退出原因：marginal_stall' "$tmp_iteration_project/.claude/.flutter-forge/session.md" || fail "ff_session did not persist marginal_stall exit reason"

rm -rf "$tmp_iteration_project"
info "iteration decision hint validation passed"
