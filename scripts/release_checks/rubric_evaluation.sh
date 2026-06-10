#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

valid_code_review_only_fixture="$(mktemp -t flutter-forge-rubric-eval-valid.XXXXXX.txt)"
cat > "$valid_code_review_only_fixture" <<'EOF'
```yaml
rubric_evaluation:
  total_score: 4.10
  layer_scores:
    functional: 4.5
    robustness: 4.0
    ui: 3.8
    interaction: 4.0
  essential_pass_rate: 1.0
  pitfall_violations: 0
  details:
    - id: L1-001
      result: PASS
      score: 5
      evidence: "列表数据渲染条数与 mock 数据一致"
    - id: L3-001
      result: WARN
      score: 4
      verification_method: code_review_only
      evidence: "未进行视觉验证；基于代码审查确认使用约束布局且未发现固定宽度"
      limitation: "无截图或设备运行证据，不能背书最终视觉观感"
    - id: L4-001
      result: PASS
      score: 4
      verification_method: code_review_only
      evidence: "未进行交互验证；基于代码审查确认按钮 loading 态阻断重复提交"
      limitation: "无真实点击或录屏证据，不能背书动画流畅度"
```
EOF

python3 scripts/validate_rubric_evaluation.py "$valid_code_review_only_fixture" >/dev/null
rm -f "$valid_code_review_only_fixture"

missing_verification_method_fixture="$(mktemp -t flutter-forge-rubric-eval-missing-method.XXXXXX.txt)"
cat > "$missing_verification_method_fixture" <<'EOF'
```yaml
rubric_evaluation:
  total_score: 4.10
  layer_scores:
    functional: 4.5
    robustness: 4.0
    ui: 3.8
    interaction: 4.0
  essential_pass_rate: 1.0
  pitfall_violations: 0
  details:
    - id: L3-001
      result: PASS
      score: 4
      evidence: "布局看起来合理"
```
EOF

if python3 scripts/validate_rubric_evaluation.py "$missing_verification_method_fixture" >/dev/null 2>&1; then
  rm -f "$missing_verification_method_fixture"
  fail "validate_rubric_evaluation accepted L3 detail with missing verification_method"
fi
rm -f "$missing_verification_method_fixture"

missing_limitation_fixture="$(mktemp -t flutter-forge-rubric-eval-missing-limitation.XXXXXX.txt)"
cat > "$missing_limitation_fixture" <<'EOF'
```yaml
rubric_evaluation:
  total_score: 4.10
  layer_scores:
    functional: 4.5
    robustness: 4.0
    ui: 3.8
    interaction: 4.0
  essential_pass_rate: 1.0
  pitfall_violations: 0
  details:
    - id: L4-001
      result: PASS
      score: 4
      verification_method: code_review_only
      evidence: "交互反馈合理"
```
EOF

if python3 scripts/validate_rubric_evaluation.py "$missing_limitation_fixture" >/dev/null 2>&1; then
  rm -f "$missing_limitation_fixture"
  fail "validate_rubric_evaluation accepted code_review_only without evidence limitation"
fi
rm -f "$missing_limitation_fixture"

info "rubric_evaluation code_review_only release validation passed"
