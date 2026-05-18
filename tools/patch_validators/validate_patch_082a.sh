#!/usr/bin/env bash
set -euo pipefail

required=(
  "scripts/systems/FlaskSystem.gd"
  "scripts/systems/ProgressionRewardSystem.gd"
  "scripts/ui/hud/FlaskHUD.gd"
  "scenes/ui/hud/FlaskHUD.tscn"
  "docs/patch_notes/PATCH_082A_PROGRESSION_DROPS_FLASK_VISIBILITY.md"
)
for f in "${required[@]}"; do
  if [ ! -f "$f" ]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
done

grep -q "RVFlaskSystem.ensure_defaults" scripts/core/GameState.gd || { echo "GameState missing RVFlaskSystem.ensure_defaults" >&2; exit 1; }
grep -q "health_flask_charges" scripts/core/GameState.gd || { echo "GameState missing health flask fields" >&2; exit 1; }
grep -q "ProgressionRewardSystemScript.award_enemy_kill" scripts/combat/CombatArena.gd || { echo "CombatArena missing progression reward hook" >&2; exit 1; }
grep -q "_install_flask_hud" scripts/core/GameRoot.gd || { echo "GameRoot missing FlaskHUD install" >&2; exit 1; }

echo "Patch 082A validation passed."
