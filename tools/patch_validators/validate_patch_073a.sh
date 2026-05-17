#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
required=(
  scripts/data/ClassDB.gd
  scripts/data/AscendancyDB.gd
  scripts/data/PassiveAtlasDB.gd
  scripts/systems/ClassAscendancySystem.gd
  scripts/ui/panels/PassiveAtlasPanel.gd
)
for f in "${required[@]}"; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done
if grep -R "func class(" scripts/data/ClassDB.gd >/dev/null 2>&1; then
  echo "Bad reserved function name in ClassDB.gd"
  exit 1
fi
if grep -R "return static func" scripts/systems/BuildcraftSystem.gd >/dev/null 2>&1; then
  echo "BuildcraftSystem still has return static func corruption"
  exit 1
fi
if grep -nE ' var character_class| character_class =| var ascendancy_id| ascendancy_id =' scripts/core/GameState.gd | grep -v '^$' >/tmp/patch073a_gamestate_hits.txt; then
  true
fi
echo "Patch 073A validation passed. Reopen Godot to confirm parser cache."
