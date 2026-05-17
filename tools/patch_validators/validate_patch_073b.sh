#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
for f in \
  scripts/data/ClassDB.gd \
  scripts/data/AscendancyDB.gd \
  scripts/data/PassiveAtlasDB.gd \
  scripts/systems/ClassAscendancySystem.gd \
  scripts/ui/panels/PassiveAtlasPanel.gd \
  scripts/systems/BuildcraftSystem.gd \
  scripts/core/GameState.gd; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done
if grep -R "func class(" scripts/data/ClassDB.gd >/dev/null 2>&1; then
  echo "Bad reserved function remains in ClassDB.gd"; exit 1
fi
if grep -n "return static func\|return func" scripts/core/GameState.gd scripts/systems/BuildcraftSystem.gd >/dev/null 2>&1; then
  echo "Compressed return/function corruption remains"; exit 1
fi
echo "Patch 073B validation passed. Reopen Godot and check the first red error if any."
