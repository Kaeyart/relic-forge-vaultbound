#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

missing=0
for f in \
  scripts/data/EnemyVisualProfileDB.gd \
  scripts/visuals/EnemyVisualRig.gd \
  scripts/visuals/SpellVFXSystem.gd \
  scripts/visuals/MapPropVisualSystem.gd \
  scripts/combat/EnemyActor.gd \
  scripts/combat/CombatArena.gd; do
  if [ ! -f "$f" ]; then
    echo "MISSING: $f"
    missing=1
  fi
done

if ! grep -q "EnemyVisualRig" scripts/combat/EnemyActor.gd; then
  echo "MISSING HOOK: EnemyActor does not reference EnemyVisualRig"
  missing=1
fi
if ! grep -q "SpellVFXSystem" scripts/combat/CombatArena.gd; then
  echo "MISSING HOOK: CombatArena does not reference SpellVFXSystem"
  missing=1
fi
if ! grep -q "MapPropVisualSystem" scripts/combat/CombatArena.gd; then
  echo "MISSING HOOK: CombatArena does not reference MapPropVisualSystem"
  missing=1
fi

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "Patch 059 validation passed."
