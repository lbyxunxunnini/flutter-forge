#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  python3 -c "import json; print(json.dumps({'result': 'error', 'message': 'usage: scripts/validate_project.sh /path/to/flutter/app'}, ensure_ascii=False))" >&2
  exit 2
fi

PROJECT_ROOT="$1"
if [[ ! -d "$PROJECT_ROOT" ]]; then
  python3 -c "import json; print(json.dumps({'result': 'fail', 'message': 'project root does not exist', 'path': '$PROJECT_ROOT'}, ensure_ascii=False))"
  exit 1
fi

if [[ ! -f "$PROJECT_ROOT/pubspec.yaml" || ! -d "$PROJECT_ROOT/lib" ]]; then
  python3 -c "import json; print(json.dumps({'result': 'fail', 'message': 'not a Flutter app: missing pubspec.yaml or lib/', 'path': '$PROJECT_ROOT'}, ensure_ascii=False))"
  exit 1
fi

python3 "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/project_snapshot.py" "$PROJECT_ROOT" >/dev/null
python3 -c "import json; print(json.dumps({'result': 'pass', 'message': 'project is valid for Flutter Forge', 'path': '$PROJECT_ROOT'}, ensure_ascii=False))"
