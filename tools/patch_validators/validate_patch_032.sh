#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 032 validation =="
for f in \
  scenes/ui/dev/DevToolsPanel.tscn \
  scripts/ui/dev/DevToolsPanel.gd \
  scripts/dev/DevToolSystem.gd \
  docs/PATCH_032_DEV_TOOLS_CREATIVE_MODE.md; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
  echo "ok $f"
done

grep -Rni "_toggle_dev_tools\|dev_start_activity\|dev_return_to_hub" scripts/core/GameRoot.gd

grep -Rni "dev_spawn_enemy\|dev_clear_enemies\|dev_force_reward" scripts/combat/CombatArena.gd

echo "Patch 032 files present. Open Godot and press F10 in game."
