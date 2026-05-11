#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_ROOT="${1:-$HOME/.cc-switch/skills}"
TARGET_SKILL_DIR="$TARGET_ROOT/flutter-forge"

mkdir -p "$TARGET_ROOT"
rm -rf "$TARGET_SKILL_DIR"
mkdir -p "$TARGET_SKILL_DIR"
cp -R "$SCRIPT_DIR/." "$TARGET_SKILL_DIR/"
rm -rf "$TARGET_SKILL_DIR/.git"

echo "Installed flutter-forge to: $TARGET_SKILL_DIR"
