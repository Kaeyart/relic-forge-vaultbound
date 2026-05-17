#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

required=(
  scripts/core/GameState.gd
  scripts/data/ClassDB.gd
  scripts/data/AscendancyDB.gd
  scripts/data/PassiveAtlasDB.gd
  scripts/systems/ClassAscendancySystem.gd
  scripts/systems/BuildcraftSystem.gd
  scripts/ui/panels/PassiveAtlasPanel.gd
)

for f in "${required[@]}"; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done

grep -q "class_name RVGameState" scripts/core/GameState.gd
grep -q "class_name RVClassDB" scripts/data/ClassDB.gd
grep -q "class_name RVClassAscendancySystem" scripts/systems/ClassAscendancySystem.gd
grep -q "static func handle_key" scripts/systems/BuildcraftSystem.gd

echo "Patch 073C files installed. Open Godot to complete parser validation."
