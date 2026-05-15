#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

required=(
  "scripts/systems/MapLayoutSystem.gd"
  "scripts/combat/CombatArena.gd"
  "docs/PATCH_046_NON_RECTANGULAR_MAP_LAYOUTS.md"
)

for f in "${required[@]}"; do
  if [ ! -f "$f" ]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
done

grep -q "class_name RVMapLayoutSystem" scripts/systems/MapLayoutSystem.gd
grep -q "generate_layout" scripts/systems/MapLayoutSystem.gd
grep -q "constrain_player_position" scripts/combat/CombatArena.gd
grep -q "RuntimeMapLayoutArt" scripts/combat/CombatArena.gd

echo "Patch 046 validation passed."
