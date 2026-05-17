#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
missing=0
for f in \
  scripts/visuals/EnemyVisualRig.gd \
  docs/PATCH_061_063A_ENEMY_VISUAL_RIG_PARSE_FIX.md; do
  if [ ! -f "$f" ]; then
    echo "Missing: $f"
    missing=1
  fi
done
if grep -q 'if visual_state == "windup" else' scripts/visuals/EnemyVisualRig.gd; then
  echo "Unsafe nested ternary still present"
  missing=1
fi
if grep -q 'bool(profile.get("role_marker"' scripts/visuals/EnemyVisualRig.gd; then
  echo "Bad boss marker comparison still present"
  missing=1
fi
if [ "$missing" -ne 0 ]; then
  exit 1
fi
echo "Patch 061-063A validation passed."
