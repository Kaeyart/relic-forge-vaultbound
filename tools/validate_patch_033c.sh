#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 033B validation =="
for f in \
  scripts/dev/sim/SimProfileDB.gd \
  scripts/dev/sim/SimItemScorer.gd \
  scripts/dev/sim/SimulationLab.gd \
  scripts/ui/dev/DevToolsPanel.gd \
  scenes/ui/dev/DevToolsPanel.tscn \
  docs/PATCH_033B_SIMULATION_LAB_FOUNDATION.md; do
  test -f "$f" || { echo "missing $f"; exit 1; }
  echo "ok $f"
done

grep -R "SimQuickButton\|LootAuditButton\|SimReportText" scenes/ui/dev/DevToolsPanel.tscn scripts/ui/dev/DevToolsPanel.gd >/dev/null

grep -R "class_name RVSimulationLab\|class_name RVSimItemScorer\|class_name RVSimProfileDB" scripts/dev/sim >/dev/null

echo "Patch 033B files exist. Open Godot to complete parser validation."
