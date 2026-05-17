#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/systems/CombatGeometrySystem.gd
grep -q "class_name RVCombatGeometrySystem" scripts/systems/CombatGeometrySystem.gd
grep -q "func has_line_of_sight" scripts/combat/CombatArena.gd
grep -q "func constrain_actor_position" scripts/combat/CombatArena.gd
grep -q "func enforce_layout_entity_collisions" scripts/combat/CombatArena.gd
grep -q "world_camera" scripts/core/GameRoot.gd
grep -q "_update_world_camera" scripts/core/GameRoot.gd
grep -q "RVCombatGeometrySystem" scripts/combat/CombatArena.gd

echo "Patch 079B validation passed."
