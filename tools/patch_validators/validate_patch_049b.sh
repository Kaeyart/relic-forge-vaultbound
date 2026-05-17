#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
SCRIPT="scripts/ui/panels/SkillGemsPanel.gd"
fail=0
if [[ ! -f "$SCRIPT" ]]; then
  echo "FAIL: $SCRIPT missing"; exit 1
fi
if grep -Eq 'preload\("res://assets/ui/skill_gems/patch049/slices/sg_02_1(0|1|2)_.*\.png"\)' "$SCRIPT"; then
  echo "FAIL: socket PNGs are still parse-time preloaded"; fail=1
else
  echo "OK: socket PNGs are not parse-time preloaded"
fi
if grep -q 'func _safe_texture(path: String) -> Texture2D:' "$SCRIPT"; then
  echo "OK: runtime texture loader present"
else
  echo "FAIL: runtime texture loader missing"; fail=1
fi
if grep -q 'TEX_SOCKET_EMPTY_PATH' "$SCRIPT" && grep -q 'TEX_SOCKET_FILLED_PATH' "$SCRIPT" && grep -q 'TEX_SOCKET_LOCKED_PATH' "$SCRIPT"; then
  echo "OK: socket texture paths present"
else
  echo "FAIL: socket texture path constants missing"; fail=1
fi
for f in \
  assets/ui/skill_gems/patch049/slices/sg_02_10_socket_empty_small.png \
  assets/ui/skill_gems/patch049/slices/sg_02_11_socket_filled_red_small.png \
  assets/ui/skill_gems/patch049/slices/sg_02_12_socket_locked_small.png; do
  if [[ ! -f "$f" ]]; then
    echo "WARN: missing $f — open Godot after Patch 049 import, or reinstall Patch 049 assets"
  else
    echo "OK: $f"
  fi
done
exit $fail
