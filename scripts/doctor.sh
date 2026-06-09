#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CHECKS='[]'

add_check() {
  local name="$1" result="$2" detail="$3"
  CHECKS="$(python3 -c "
import json, sys
checks = json.loads(sys.argv[1])
checks.append({'name': sys.argv[2], 'result': sys.argv[3], 'detail': sys.argv[4]})
print(json.dumps(checks, ensure_ascii=False))
" "$CHECKS" "$name" "$result" "$detail")"
}

# python3
if python3 --version >/dev/null 2>&1; then
  add_check "python3" "pass" "$(python3 --version 2>&1)"
else
  add_check "python3" "fail" "python3 not found"
fi

# release gate
if [[ -f VERSION && -f .skillhub.json ]]; then
  if bash scripts/validate_release.sh >/dev/null 2>&1; then
    add_check "release_gate" "pass" "VERSION and .skillhub.json valid"
  else
    add_check "release_gate" "fail" "release validation failed"
  fi
else
  add_check "release_gate" "fail" "missing VERSION or .skillhub.json"
fi

# SKILL.md
if [[ -f SKILL.md ]]; then
  add_check "skill_md" "pass" "SKILL.md exists"
else
  add_check "skill_md" "fail" "SKILL.md missing"
fi

# Flutter app check
if [[ -f pubspec.yaml && -d lib ]]; then
  add_check "flutter_app" "pass" "current directory looks like Flutter app"
else
  add_check "flutter_app" "info" "current directory is not a Flutter app"
fi

# Determine overall result
OVERALL="pass"
python3 -c "
import json, sys
checks = json.loads(sys.argv[1])
for c in checks:
    if c['result'] == 'fail':
        print('fail', end='')
        sys.exit(0)
print('pass', end='')
" "$CHECKS" >/tmp/ff_doctor_overall 2>/dev/null || true
OVERALL="$(cat /tmp/ff_doctor_overall 2>/dev/null || echo "pass")"
rm -f /tmp/ff_doctor_overall

python3 -c "
import json, sys
checks = json.loads(sys.argv[1])
result = {'result': sys.argv[2], 'checks': checks, 'check_count': len(checks)}
failed = [c for c in checks if c['result'] == 'fail']
result['failed_count'] = len(failed)
print(json.dumps(result, ensure_ascii=False))
" "$CHECKS" "$OVERALL"

if [ "$OVERALL" = "fail" ]; then
  exit 1
fi
