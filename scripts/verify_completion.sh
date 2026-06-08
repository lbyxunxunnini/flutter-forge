#!/usr/bin/env bash
# verify_completion.sh — 综合验证任务完成度
#
# 用法: scripts/verify_completion.sh <project_root> [--task-type <type>] [--changed-files <file1,file2>]
#
# 输出 JSON:
#   verified           : bool — 是否通过综合验证
#   tests_passed       : bool — 测试是否通过
#   test_count         : int  — 测试总数
#   test_passed_count  : int  — 通过数
#   test_failed_count  : int  — 失败数
#   test_failures      : list — 失败测试详情
#   session_valid      : bool — session 是否合法
#   session_errors     : list — session 错误详情
#   output_valid       : bool — 输出格式是否合法
#   issues             : list — 综合问题列表
#   test_debt          : list — 测试债务

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"
shift || true

TASK_TYPE=""
CHANGED_FILES=""

while [ $# -gt 0 ]; do
  case "$1" in
    --task-type) TASK_TYPE="$2"; shift 2 ;;
    --changed-files) CHANGED_FILES="$2"; shift 2 ;;
    *) shift ;;
  esac
done

ISSUES="[]"
TEST_DEBT="[]"
TESTS_PASSED="true"
TEST_COUNT=0
TEST_PASSED_COUNT=0
TEST_FAILED_COUNT=0
TEST_FAILURES="[]"
SESSION_VALID="true"
SESSION_ERRORS="[]"
OUTPUT_VALID="true"

# --- 1. 运行 Flutter 测试 ---
run_flutter_tests() {
  if [ ! -f "$PROJECT_ROOT/pubspec.yaml" ]; then
    TESTS_PASSED="skipped"
    return 0
  fi

  local test_output
  local test_exit=0
  test_output="$(cd "$PROJECT_ROOT" && flutter test --machine 2>&1)" || test_exit=$?

  if [ $test_exit -ne 0 ]; then
    TESTS_PASSED="false"
    # Parse test output for failures
    TEST_FAILURES="$(printf '%s' "$test_output" | python3 -c "
import sys, json
failures = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        event = json.loads(line)
        if event.get('type') == 'testDone' and event.get('result') == 'error':
            failures.append({
                'test': event.get('testID', 'unknown'),
                'result': event.get('result', 'error'),
            })
    except json.JSONDecodeError:
        pass
print(json.dumps(failures, ensure_ascii=False))
" 2>/dev/null || echo "[]")"
    TEST_FAILED_COUNT="$(python3 -c "import json,sys; print(len(json.loads(sys.argv[1])))" "$TEST_FAILURES")"
  else
    TESTS_PASSED="true"
    # Parse test count
    local test_summary
    test_summary="$(printf '%s' "$test_output" | tail -5)"
    TEST_COUNT="$(echo "$test_summary" | grep -oE '[0-9]+ test' | head -1 | grep -oE '[0-9]+' || echo "0")"
    TEST_PASSED_COUNT="$TEST_COUNT"
  fi
}

# --- 2. 验证 session ---
validate_session() {
  local session_out
  session_out="$(bash "$SCRIPT_DIR/ff_session.sh" --project-root "$PROJECT_ROOT" validate 2>&1)" || true
  local result_field
  result_field="$(printf '%s' "$session_out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('result', d.get('status', 'unknown')))" 2>/dev/null || echo "unknown")"
  if [ "$result_field" = "pass" ]; then
    SESSION_VALID="true"
  elif [ "$result_field" = "no_session" ]; then
    SESSION_VALID="true"  # No session is not an error
  else
    SESSION_VALID="false"
    SESSION_ERRORS="$(printf '%s' "$session_out" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(json.dumps(d.get('errors', []), ensure_ascii=False))
except:
    print('[]')
" 2>/dev/null || echo "[]")"
  fi
}

# --- 3. 综合判断 ---
compile_results() {
  local verified="true"

  if [ "$TESTS_PASSED" = "false" ]; then
    verified="false"
    ISSUES="$(python3 -c "
import json, sys
issues = json.loads(sys.argv[1])
issues.append('tests_failed')
print(json.dumps(issues, ensure_ascii=False))
" "$ISSUES")"
  fi

  if [ "$SESSION_VALID" = "false" ]; then
    verified="false"
    ISSUES="$(python3 -c "
import json, sys
issues = json.loads(sys.argv[1])
issues.append('session_invalid')
print(json.dumps(issues, ensure_ascii=False))
" "$ISSUES")"
  fi

  # Check for test debt
  if [ "$TASK_TYPE" = "功能开发" ] || [ "$TASK_TYPE" = "页面开发" ]; then
    if [ "$TESTS_PASSED" = "skipped" ]; then
      TEST_DEBT='["heavy_task_no_tests"]'
      verified="false"
      ISSUES="$(python3 -c "
import json, sys
issues = json.loads(sys.argv[1])
issues.append('test_debt_heavy_task')
print(json.dumps(issues, ensure_ascii=False))
" "$ISSUES")"
    fi
  fi

  python3 -c "
import json
print(json.dumps({
    'verified': '$verified' == 'true',
    'tests_passed': '$TESTS_PASSED',
    'test_count': int('$TEST_COUNT'),
    'test_passed_count': int('$TEST_PASSED_COUNT'),
    'test_failed_count': int('$TEST_FAILED_COUNT'),
    'test_failures': json.loads('$TEST_FAILURES'),
    'session_valid': '$SESSION_VALID' == 'true',
    'session_errors': json.loads('$SESSION_ERRORS'),
    'output_valid': '$OUTPUT_VALID' == 'true',
    'issues': json.loads('$ISSUES'),
    'test_debt': json.loads('$TEST_DEBT'),
}, ensure_ascii=False, indent=2))
"
}

run_flutter_tests
validate_session
compile_results
