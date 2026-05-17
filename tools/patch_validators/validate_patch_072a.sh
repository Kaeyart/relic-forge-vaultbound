#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
printf 'Patch 072A validation\n'
test -f scripts/systems/LootDropSystem.gd
test -f scripts/combat/LootDropActor.gd
test -f scripts/systems/FloatingCombatTextSystem.gd
grep -q 'func _rf_ensure_combat_layers' scripts/combat/CombatArena.gd
grep -q 'func _rf_update_ground_loot' scripts/combat/CombatArena.gd
grep -q 'func _rf_drop_enemy_loot' scripts/combat/CombatArena.gd
grep -q 'RVItemDB.generate_drop(state, depth)' scripts/systems/LootDropSystem.gd
grep -q 'RVMapDB.make_map(rng, depth)' scripts/systems/LootDropSystem.gd
grep -q 'RVSkillGemSystem._make_uncut' scripts/systems/LootDropSystem.gd
printf 'OK: Patch 072A files and compatibility hooks are present.\n'
