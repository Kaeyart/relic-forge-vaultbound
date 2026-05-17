#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
missing=0
for f in \
  scripts/data/EnemyShapeKitDB.gd \
  scripts/visuals/EnemyVisualRig.gd \
  scripts/visuals/VisualProxyVFXNode.gd \
  scripts/visuals/SpellVFXSystem.gd \
  scripts/combat/EnemyActor.gd; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f"
    missing=1
  else
    echo "OK: $f"
  fi
done
if [[ $missing -ne 0 ]]; then
  exit 1
fi

grep -q "class_name RVEnemyShapeKitDB" scripts/data/EnemyShapeKitDB.gd
grep -q "class_name RVEnemyVisualRig" scripts/visuals/EnemyVisualRig.gd
grep -q "class_name RVVisualProxyVFXNode" scripts/visuals/VisualProxyVFXNode.gd
grep -q "class_name RVSpellVFXSystem" scripts/visuals/SpellVFXSystem.gd
grep -q "class_name RVEnemyActor" scripts/combat/EnemyActor.gd

echo "Patch 061-063 validation passed."
