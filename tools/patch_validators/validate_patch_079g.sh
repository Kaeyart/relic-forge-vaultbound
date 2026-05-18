#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/visuals/MapReturnPortalVisual.gd
test -f scenes/prefabs/hub/MapReturnPortal.tscn
grep -q "active_map_portals_remaining" scripts/core/GameState.gd
grep -q "_try_enter_active_map_portal" scripts/core/GameRoot.gd
grep -q "constrain_player_movement" scripts/combat/CombatArena.gd
grep -q "_rf_constrain_entity_movement" scripts/combat/CombatArena.gd
grep -q "_rf_live_projectiles_root().add_child(projectile)" scripts/combat/CombatArena.gd
if grep -q "projectiles_root.add_child(projectile)" scripts/combat/CombatArena.gd; then
  echo "Unsafe projectiles_root.add_child(projectile) still exists" >&2
  exit 1
fi
if grep -q "enemies_root.add_child(enemy)" scripts/combat/CombatArena.gd; then
  echo "Unsafe enemies_root.add_child(enemy) still exists" >&2
  exit 1
fi

echo "Patch 079G validation passed."
