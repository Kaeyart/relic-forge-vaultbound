#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/combat/CombatArena.gd
test "$(grep -c '^class_name RVCombatArena$' scripts/combat/CombatArena.gd)" -eq 1
test "$(grep -c '^extends ' scripts/combat/CombatArena.gd)" -eq 1
head -n 2 scripts/combat/CombatArena.gd | grep -q $'class_name RVCombatArena\nextends Node2D'

echo "Patch 079B CombatArena global class repair validation passed."
