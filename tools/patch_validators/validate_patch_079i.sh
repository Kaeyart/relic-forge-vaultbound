#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

grep -q '"Storm Lance"' scripts/combat/CombatArena.gd
grep -q 'func _damage_enemies_along_lance' scripts/combat/CombatArena.gd
grep -q 'func _rf_combat_los_hit_allowed' scripts/combat/CombatArena.gd
! grep -q '_rf_has_combat_los(projectile.global_position, enemy.global_position, projectile.radius + enemy.radius)' scripts/combat/CombatArena.gd

echo 'Patch 079I validation passed.'
