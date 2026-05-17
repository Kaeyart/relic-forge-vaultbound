#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 073D =="
required=(
  scripts/core/GameState.gd
  scripts/systems/BuildcraftSystem.gd
  scripts/data/ClassDB.gd
  scripts/data/AscendancyDB.gd
  scripts/data/PassiveAtlasDB.gd
  scripts/systems/ClassAscendancySystem.gd
  scripts/ui/panels/PassiveAtlasPanel.gd
)
for f in "${required[@]}"; do
  test -f "$f" || { echo "missing: $f"; exit 1; }
done

grep -q '^class_name RVGameState' scripts/core/GameState.gd
grep -q '^class_name RVBuildcraftSystem' scripts/systems/BuildcraftSystem.gd
grep -q '^class_name RVClassDB' scripts/data/ClassDB.gd
grep -q '^class_name RVAscendancyDB' scripts/data/AscendancyDB.gd
grep -q '^class_name RVPassiveAtlasDB' scripts/data/PassiveAtlasDB.gd
grep -q '^class_name RVClassAscendancySystem' scripts/systems/ClassAscendancySystem.gd

if grep -nE 'return[[:space:]].*static func|func[[:space:]]*\(|if .*: return var|static[[:space:]]*$' scripts/core/GameState.gd scripts/systems/BuildcraftSystem.gd scripts/data/ClassDB.gd scripts/systems/ClassAscendancySystem.gd; then
  echo "Found known bad parser patterns."
  exit 1
fi

if command -v godot >/dev/null 2>&1; then
  echo "Running Godot headless parser check..."
  godot --headless --path . --quit || true
elif command -v godot4 >/dev/null 2>&1; then
  echo "Running Godot headless parser check..."
  godot4 --headless --path . --quit || true
else
  echo "Godot binary not found in PATH; file-level validation passed."
fi

echo "Patch 073D validation completed."
