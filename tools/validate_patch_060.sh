#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 060 =="

required=(
  scripts/data/EnemyVisualProfileDB.gd
  scripts/visuals/EnemyVisualRig.gd
  scripts/visuals/SpellVFXSystem.gd
  scripts/visuals/MapPropVisualSystem.gd
  docs/PATCH_060_VISUAL_PROXY_PLUS.md
)

for f in "${required[@]}"; do
  test -f "$f" || { echo "Missing: $f"; exit 1; }
done

grep -q "class_name RVEnemyVisualProfileDB" scripts/data/EnemyVisualProfileDB.gd
grep -q "class_name RVEnemyVisualRig" scripts/visuals/EnemyVisualRig.gd
grep -q "class_name RVSpellVFXSystem" scripts/visuals/SpellVFXSystem.gd
grep -q "class_name RVMapPropVisualSystem" scripts/visuals/MapPropVisualSystem.gd

echo "Patch 060 files installed. Open Godot for parser validation."
