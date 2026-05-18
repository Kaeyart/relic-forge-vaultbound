#!/usr/bin/env bash
set -euo pipefail

required=(
  "scripts/systems/FlaskSystem.gd"
  "scripts/core/GameState.gd"
  "scripts/core/GameRoot.gd"
  "scripts/combat/CombatArena.gd"
)

for f in "${required[@]}"; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done

grep -q "class_name RVFlaskSystem" scripts/systems/FlaskSystem.gd || { echo "FlaskSystem class missing"; exit 1; }
grep -q "health_flask_charges" scripts/core/GameState.gd || { echo "GameState flask fields missing"; exit 1; }
grep -q "active_map_instance" scripts/core/GameState.gd || { echo "GameState active map instance field missing"; exit 1; }
grep -q "_rf_081a_portal_to_hub" scripts/core/GameRoot.gd || { echo "GameRoot portal helper missing"; exit 1; }
grep -q "capture_map_instance_state" scripts/combat/CombatArena.gd || { echo "CombatArena capture helper missing"; exit 1; }
grep -q "_rf_081a_restore_map_instance" scripts/combat/CombatArena.gd || { echo "CombatArena restore helper missing"; exit 1; }

if grep -q "runtime_map_camera.clear_current()" scripts/combat/CombatArena.gd; then
  echo "Invalid Camera2D.clear_current call remains"
  exit 1
fi

echo "Patch 081A validator passed."
