#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

grep -q "func _rf_has_combat_los" scripts/combat/CombatArena.gd
grep -q "func _rf_enemy_has_awareness" scripts/combat/CombatArena.gd
grep -q "_rf_enemy_attack_has_los(pos, radius)" scripts/combat/CombatArena.gd
grep -q "_rf_area_damage_has_los(center, enemy.global_position, tags)" scripts/combat/CombatArena.gd
grep -q "hit_player.connect(_on_enemy_hit_player.bind(enemy))" scripts/combat/CombatArena.gd
if grep -q "enemy.hit_player.connect(_on_enemy_hit_player)" scripts/combat/CombatArena.gd; then
  echo "Unsafe enemy hit_player connection remains" >&2
  exit 1
fi

echo "Patch 079F validation passed."
