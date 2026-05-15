#!/usr/bin/env bash
set -euo pipefail

cd /home/kaey/Desktop/Game

fail=0

check_file() {
  if [ ! -f "$1" ]; then
    echo "MISSING: $1"
    fail=1
  else
    echo "OK: $1"
  fi
}

check_no_file() {
  if [ -f "$1" ]; then
    echo "SHOULD BE ARCHIVED, STILL ACTIVE: $1"
    fail=1
  else
    echo "OK archived/not active: $1"
  fi
}

echo "== Active boot config =="
grep -n 'run/main_scene="res://scenes/main/GameRoot.tscn"' project.godot || fail=1
grep -n 'config/name="Relic Forge Vaultbound"' project.godot || fail=1

echo
echo "== Active spine files =="
check_file scenes/main/GameRoot.tscn
check_file scripts/core/GameRoot.gd
check_file scenes/hub/ForgeholdHub.tscn
check_file scenes/combat/CombatArena.tscn
check_file scenes/ui/GameHUD.tscn
check_file scenes/ui/UIPanelRoot.tscn
check_file scenes/prefabs/player/Player.tscn
check_file scenes/prefabs/enemies/EnemyActor.tscn
check_file scenes/prefabs/projectiles/ProjectileActor.tscn

echo
echo "== Old boot files should not exist at active paths =="
check_no_file scenes/Main.tscn
check_no_file scripts/Main.gd

echo
echo "== Legacy archive should exist =="
check_file scenes/legacy/patch003/Main.tscn
check_file scripts/legacy/patch003/Main.gd

echo
if [ "$fail" -ne 0 ]; then
  echo "Patch 025 validation FAILED."
  exit 1
fi

echo "Patch 025 validation OK."
