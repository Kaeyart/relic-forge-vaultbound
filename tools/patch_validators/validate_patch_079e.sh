#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/combat/CombatArena.gd
grep -q '^class_name RVCombatArena$' scripts/combat/CombatArena.gd
grep -q '^extends Node2D$' scripts/combat/CombatArena.gd
grep -q 'func _rf_live_projectiles_root()' scripts/combat/CombatArena.gd
grep -q 'func _rf_live_enemies_root()' scripts/combat/CombatArena.gd
if grep -q 'projectiles_root.add_child(projectile)' scripts/combat/CombatArena.gd; then
  echo 'Unsafe direct projectiles_root.add_child(projectile) still exists.' >&2
  exit 1
fi
if grep -q 'enemies_root.add_child(enemy)' scripts/combat/CombatArena.gd; then
  echo 'Unsafe direct enemies_root.add_child(enemy) still exists.' >&2
  exit 1
fi
grep -q 'func _clear_children(root: Variant)' scripts/combat/CombatArena.gd

echo 'Patch 079E validation passed.'
