#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

python3 scripts/validate_checklist.py --role requirement_analyst \
  tests/checklist_fixtures/requirement_analyst_pass.txt >/dev/null

missing_quality_tier_fixture="$(mktemp -t flutter-forge-missing-quality.XXXXXX.txt)"
cat > "$missing_quality_tier_fixture" <<'EOF'
```yaml
checklist:
  business_goal: "用户可以查看订单列表"
  scope_in:
    - "订单列表展示"
  scope_out: []
  key_branches:
    - "空数据"
  non_functional: []
  quality_anchor:
    design_intent: "简洁商务"
  rubric_items:
    - id: L1-001
      layer: functional
      level: Essential
      criterion: "订单列表正确渲染"
    - id: L2-001
      layer: robustness
      level: Pitfall
      criterion: "空数据时不白屏"
    - id: L2-002
      layer: robustness
      level: Pitfall
      criterion: "网络错误有反馈"
    - id: L3-001
      layer: ui
      level: Important
      criterion: "布局层级清晰"
    - id: L4-001
      layer: interaction
      level: Important
      criterion: "操作有反馈"
  task_semantic: page
  decision: allow
```
EOF

if python3 scripts/validate_checklist.py --role requirement_analyst "$missing_quality_tier_fixture" >/dev/null 2>&1; then
  rm -f "$missing_quality_tier_fixture"
  fail "validate_checklist accepted requirement_analyst allow checklist with missing quality_tier"
fi
rm -f "$missing_quality_tier_fixture"

missing_rubric_items_fixture="$(mktemp -t flutter-forge-missing-rubric.XXXXXX.txt)"
cat > "$missing_rubric_items_fixture" <<'EOF'
```yaml
checklist:
  business_goal: "用户可以查看订单列表"
  scope_in:
    - "订单列表展示"
  scope_out: []
  key_branches:
    - "空数据"
  non_functional: []
  quality_anchor:
    quality_tier: "polished"
  rubric_items: []
  task_semantic: page
  decision: allow
```
EOF

if python3 scripts/validate_checklist.py --role requirement_analyst "$missing_rubric_items_fixture" >/dev/null 2>&1; then
  rm -f "$missing_rubric_items_fixture"
  fail "validate_checklist accepted requirement_analyst allow checklist with missing rubric_items"
fi
rm -f "$missing_rubric_items_fixture"

info "checklist quality_tier and rubric release validation passed"
