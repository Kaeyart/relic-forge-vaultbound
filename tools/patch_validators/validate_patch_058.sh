#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 058 =="
required=(
  "scripts/systems/MapEncounterDirector.gd"
  "scripts/systems/MapLayoutSystem.gd"
  "scripts/data/EnemyDB.gd"
  "scripts/combat/EnemyActor.gd"
  "scripts/combat/CombatArena.gd"
)
for f in "${required[@]}"; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
  echo "OK $f"
done

grep -q "class_name RVMapEncounterDirector" scripts/systems/MapEncounterDirector.gd
grep -q "signal zone_requested" scripts/combat/EnemyActor.gd
grep -q "MapEncounterDirectorScript" scripts/combat/CombatArena.gd
grep -q "boss_gate" scripts/systems/MapLayoutSystem.gd
grep -q "Lunger" scripts/data/EnemyDB.gd

echo "Patch 058 file checks passed. Open Godot for parser/runtime validation."
