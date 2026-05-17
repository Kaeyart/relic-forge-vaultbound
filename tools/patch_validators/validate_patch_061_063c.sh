#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== validate patch 061-063C =="

grep -q 'signal projectile_requested' scripts/combat/EnemyActor.gd
grep -q 'signal zone_requested' scripts/combat/EnemyActor.gd
grep -q 'signal spawn_requested' scripts/combat/EnemyActor.gd
grep -q 'has_signal("projectile_requested")' scripts/combat/CombatArena.gd
grep -q 'has_signal("zone_requested")' scripts/combat/CombatArena.gd
grep -q 'has_signal("spawn_requested")' scripts/combat/CombatArena.gd

echo "Patch 061-063C validation passed."
