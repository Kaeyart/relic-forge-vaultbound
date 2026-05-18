#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f scripts/systems/FlaskSystem.gd ]]; then
  echo "ERROR: scripts/systems/FlaskSystem.gd missing" >&2
  exit 1
fi

COUNT=$(grep -c "static func on_enemy_killed" scripts/systems/FlaskSystem.gd || true)
if [[ "$COUNT" -ne 1 ]]; then
  echo "ERROR: expected exactly one static func on_enemy_killed in FlaskSystem.gd; found $COUNT" >&2
  exit 1
fi

if grep -q "func _get(state" scripts/systems/FlaskSystem.gd; then
  echo "ERROR: FlaskSystem.gd contains Object virtual _get override risk" >&2
  exit 1
fi

if ! grep -q "FlaskSystemScript.on_enemy_killed" scripts/combat/CombatArena.gd; then
  echo "WARNING: CombatArena.gd does not call FlaskSystemScript.on_enemy_killed; validator continuing."
fi

echo "Patch 082C validator passed."
