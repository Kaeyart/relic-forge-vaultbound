#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/combat/CombatArena.gd
grep -q '^class_name RVCombatArena$' scripts/combat/CombatArena.gd
grep -q '^extends Node2D$' scripts/combat/CombatArena.gd
grep -q 'func _rf_safe_children(root: Variant)' scripts/combat/CombatArena.gd
grep -q 'func _rf_child_count(root: Variant)' scripts/combat/CombatArena.gd
if grep -q 'func _rf_safe_children([^)]*: Node' scripts/combat/CombatArena.gd; then
  echo 'ERROR: _rf_safe_children still has a typed Node parameter.' >&2
  exit 1
fi
if grep -q 'func _rf_child_count([^)]*: Node' scripts/combat/CombatArena.gd; then
  echo 'ERROR: _rf_child_count still has a typed Node parameter.' >&2
  exit 1
fi
if [ "$(grep -c '^extends ' scripts/combat/CombatArena.gd)" -ne 1 ]; then
  echo 'ERROR: CombatArena.gd should contain exactly one top-level extends line.' >&2
  exit 1
fi

echo 'Patch 079C validation passed.'
