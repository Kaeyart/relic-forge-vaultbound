#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
missing=0
for f in scripts/combat/CombatArena.gd scripts/combat/LootDropActor.gd scripts/systems/LootDropSystem.gd scripts/systems/FloatingCombatTextSystem.gd; do
  if [ ! -f "$f" ]; then
    echo "MISSING: $f"
    missing=1
  fi
done
for fn in _rf_ensure_combat_layers _rf_update_ground_loot _rf_prepare_enemy_visual_layer _rf_spawn_damage_number _rf_drop_enemy_loot _rf_pickup_loot_drop; do
  if ! grep -q "func $fn" scripts/combat/CombatArena.gd; then
    echo "MISSING FUNC: $fn"
    missing=1
  fi
done
if grep -q 'panels.update_from_state(state) _consume_pending_map_activity()' scripts/combat/CombatArena.gd; then
  echo "BAD INLINE STATEMENT FOUND"
  missing=1
fi
if [ "$missing" -ne 0 ]; then
  exit 1
fi
echo "Patch 072B files and helpers are present. Reopen Godot to let scripts reparse."
