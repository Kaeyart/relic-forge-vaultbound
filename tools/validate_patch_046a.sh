#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 046A =="
test -f scripts/systems/MapLayoutSystem.gd
grep -q "class_name RVMapLayoutSystem" scripts/systems/MapLayoutSystem.gd
grep -q "MapLayoutSystemScript" scripts/combat/CombatArena.gd || grep -q "RVMapLayoutSystem" scripts/combat/CombatArena.gd

echo "Map layout class/preload fix is present. Now reopen Godot and test a map run."
