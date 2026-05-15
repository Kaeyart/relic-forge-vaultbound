#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
for f in scripts/data/MapDB.gd scripts/systems/MapSystem.gd scripts/ui/panels/MapDevicePanel.gd scenes/ui/panels/MapDevicePanel.tscn scripts/core/GameRoot.gd scripts/ui/UIPanelRoot.gd scripts/combat/CombatArena.gd scripts/systems/ProgressionSystem.gd; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done
if grep -R "var map_stash:.* var map_cursor\|@onready var activity_panel:.* @onready\|return if RVMapSystem\|Expected" scripts/core scripts/ui scripts/combat scripts/systems 2>/dev/null; then
  echo "Possible inline parser issue remains."
  exit 1
fi
echo "Patch 045A validation passed."
