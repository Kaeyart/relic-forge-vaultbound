#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

file="scripts/data/PassiveAtlasDB.gd"

if [ ! -f "$file" ]; then
  echo "ERROR: $file missing" >&2
  exit 1
fi

if ! grep -q 'class_name RVPassiveAtlasDB' "$file"; then
  echo "ERROR: RVPassiveAtlasDB class_name missing" >&2
  exit 1
fi

if ! grep -q 'START_NODE_ID' "$file"; then
  echo "ERROR: START_NODE_ID missing from PassiveAtlasDB" >&2
  exit 1
fi

if grep -R 'PassiveDBScript.START_NODE_ID' -n scripts/ui/panels/PassiveAtlasPanel.gd >/dev/null 2>&1; then
  if ! grep -q 'const START_NODE_ID' "$file"; then
    echo "ERROR: PassiveAtlasPanel uses START_NODE_ID but DB does not define const START_NODE_ID" >&2
    exit 1
  fi
fi

class_count=$(grep -c '^class_name RVPassiveAtlasDB' "$file" || true)
extends_count=$(grep -c '^extends ' "$file" || true)
if [ "$class_count" -ne 1 ]; then
  echo "ERROR: Expected exactly one RVPassiveAtlasDB class_name, found $class_count" >&2
  exit 1
fi
if [ "$extends_count" -lt 1 ]; then
  echo "ERROR: PassiveAtlasDB missing extends line" >&2
  exit 1
fi

if grep -R 'Camera2D\.clear_current' -n scripts >/dev/null 2>&1; then
  echo "ERROR: invalid Camera2D.clear_current() call still exists" >&2
  exit 1
fi

echo "Patch 085C validation passed."
