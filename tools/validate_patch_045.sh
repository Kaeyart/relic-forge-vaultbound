#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
for f in scripts/data/MapDB.gd scripts/systems/MapSystem.gd scripts/ui/panels/MapDevicePanel.gd scenes/ui/panels/MapDevicePanel.tscn scripts/core/GameState.gd scripts/core/GameRoot.gd scripts/combat/CombatArena.gd; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done
grep -R "map_device" scripts/core/GameRoot.gd scripts/ui/UIPanelRoot.gd scenes/ui/UIPanelRoot.tscn >/dev/null
echo "Patch 045 validation passed."
