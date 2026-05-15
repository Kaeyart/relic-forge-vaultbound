#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 032A validation =="
for f in \
  scenes/ui/dev/DevToolsPanel.tscn \
  scripts/ui/dev/DevToolsPanel.gd \
  scripts/dev/DevToolSystem.gd \
  docs/PATCH_032A_DEV_TOOLS_PARSE_FIX.md; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
  echo "ok $f"
done

grep -n "var dev_tools_panel" scripts/core/GameRoot.gd
grep -n "_install_dev_tools" scripts/core/GameRoot.gd
grep -n "KEY_F10" scripts/core/GameRoot.gd
grep -n "dev_spawn_enemy\|dev_clear_enemies\|dev_force_reward" scripts/combat/CombatArena.gd

if grep -n "autosave_timer: float = 0.0 var" scripts/core/GameRoot.gd; then
  echo "ERROR: inline variable declaration still present"
  exit 1
fi
if grep -n "set_process_unhandled_input(true) _install_dev_tools" scripts/core/GameRoot.gd; then
  echo "ERROR: inline _install_dev_tools call still present"
  exit 1
fi
if grep -n "func _handle_key(keycode: int) -> void: if" scripts/core/GameRoot.gd; then
  echo "ERROR: inline _handle_key body still present"
  exit 1
fi

echo "Patch 032A files and GameRoot repairs are present. Open Godot and press F10."
