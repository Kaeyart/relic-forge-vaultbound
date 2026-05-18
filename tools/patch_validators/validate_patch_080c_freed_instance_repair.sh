#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

grep -q "func _rf_safe_children" scripts/combat/CombatArena.gd
grep -q "func _rf_child_count" scripts/combat/CombatArena.gd
grep -q "RVLootFilterSystem.update_ground_loot" scripts/core/GameRoot.gd
if grep -q "enemies_root.get_children()" scripts/combat/CombatArena.gd; then
  echo "Unsafe enemies_root.get_children() remains" >&2
  exit 1
fi
if grep -q "projectiles_root.get_children()" scripts/combat/CombatArena.gd; then
  echo "Unsafe projectiles_root.get_children() remains" >&2
  exit 1
fi

echo "Patch 080C freed-instance repair validation passed."
