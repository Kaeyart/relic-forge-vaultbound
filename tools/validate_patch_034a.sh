#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== PATCH 034A VALIDATION =="
for f in \
  scripts/dev/lab/TelemetryLogger.gd \
  scripts/dev/lab/LabProfileDB.gd \
  scripts/dev/lab/LabScenarioDB.gd \
  scripts/dev/lab/LabCharacterState.gd \
  scripts/dev/lab/LabItemEvaluator.gd \
  scripts/dev/lab/LabDecisionEngine.gd \
  scripts/dev/lab/LabBuildCoherenceEvaluator.gd \
  scripts/dev/lab/LabCombatProxyEvaluator.gd \
  scripts/dev/lab/LabWarningEngine.gd \
  scripts/dev/lab/LabJourneySimulator.gd \
  scripts/dev/lab/LabReportWriter.gd \
  scripts/dev/lab/BuildcraftObservatory.gd \
  scripts/ui/dev/DevToolsPanel.gd \
  scenes/ui/dev/DevToolsPanel.tscn \
  data/dev/lab/profiles/fireball_ignite.json \
  data/dev/lab/scenarios/fireball_30_room_journey.json; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done

grep -R "class_name RVBuildcraftObservatory" -n scripts/dev/lab/BuildcraftObservatory.gd
grep -R "LabFireballButton" -n scenes/ui/dev/DevToolsPanel.tscn scripts/ui/dev/DevToolsPanel.gd
grep -R "KEY_F10\|_install_dev_tools\|dev_tools_panel" -n scripts/core/GameRoot.gd || true

echo "Patch 034A files present. Open Godot to complete parse validation."
