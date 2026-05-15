#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Relic Forge validate_all =="

tools/validate_runtime.sh
tools/validate_repo_hygiene.sh

echo "== Key project tree =="
find scenes scripts data docs tools -maxdepth 2 -type d 2>/dev/null | sort | sed 's/^/DIR  /'

echo "== Git status summary =="
git status --short || true

echo "validate_all complete. Open Godot and press Play for runtime confirmation."
