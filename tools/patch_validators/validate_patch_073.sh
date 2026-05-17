#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 073 =="
missing=0
for f in \
  scripts/data/ClassDB.gd \
  scripts/data/AscendancyDB.gd \
  scripts/data/PassiveAtlasDB.gd \
  scripts/systems/ClassAscendancySystem.gd \
  scripts/ui/panels/PassiveAtlasPanel.gd; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f"
    missing=1
  else
    echo "OK: $f"
  fi
done

if [[ $missing -ne 0 ]]; then
  exit 1
fi

grep -q "character_class_id" scripts/core/GameState.gd || { echo "GameState missing character_class_id"; exit 1; }
grep -q "ascendancy_id" scripts/core/GameState.gd || { echo "GameState missing ascendancy_id"; exit 1; }
grep -q "passive_atlas_allocated" scripts/core/GameState.gd || { echo "GameState missing passive_atlas_allocated"; exit 1; }
grep -q "RVClassAscendancySystem.apply_bonuses" scripts/core/GameState.gd || { echo "GameState missing class/atlas bonus hook"; exit 1; }
grep -q "RVClassAscendancySystem.handle_panel_key" scripts/systems/BuildcraftSystem.gd || { echo "BuildcraftSystem passive key handler not routed"; exit 1; }

echo "Patch 073 validation passed."
