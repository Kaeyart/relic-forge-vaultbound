#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
required=(
  "scripts/systems/FloatingCombatTextSystem.gd"
  "scripts/systems/LootDropSystem.gd"
  "scripts/combat/LootDropActor.gd"
  "docs/PATCH_072_GROUND_LOOT_DAMAGE_NUMBERS.md"
)
for f in "${required[@]}"; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done
grep -q "_rf_spawn_damage_number" scripts/combat/CombatArena.gd || { echo "CombatArena missing damage number hook"; exit 1; }
grep -q "_rf_drop_enemy_loot" scripts/combat/CombatArena.gd || { echo "CombatArena missing enemy loot hook"; exit 1; }
grep -q "_rf_update_ground_loot" scripts/combat/CombatArena.gd || { echo "CombatArena missing ground loot update hook"; exit 1; }
echo "Patch 072 validation passed."
