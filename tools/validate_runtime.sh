#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
check_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "MISSING FILE: $path"
    fail=1
  else
    echo "OK: $path"
  fi
}

check_dir() {
  local path="$1"
  if [ ! -d "$path" ]; then
    echo "MISSING DIR: $path"
    fail=1
  else
    echo "OK: $path"
  fi
}

echo "== Runtime spine =="
check_file project.godot
check_file scenes/main/GameRoot.tscn
check_file scripts/core/GameRoot.gd
check_file scripts/core/GameState.gd
check_file scripts/core/SaveSystem.gd
check_file scenes/hub/ForgeholdHub.tscn
check_file scenes/combat/CombatArena.tscn
check_file scenes/ui/GameHUD.tscn
check_file scenes/ui/UIPanelRoot.tscn
check_dir scripts/data
check_dir scripts/systems
check_dir scripts/ui
check_dir scripts/dev

if ! grep -q 'run/main_scene="res://scenes/main/GameRoot.tscn"' project.godot; then
  echo "BAD MAIN SCENE: project.godot should boot scenes/main/GameRoot.tscn"
  fail=1
else
  echo "OK: project.godot main scene"
fi

exit "$fail"
