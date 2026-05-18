#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 tools/maintenance/audit_scene_authorship_085k.py
if grep -R "res://scenes/ui/panels/LootFilterPanel.tscn\|res://scenes/ui/hud/FlaskHUD.tscn" -n scripts/core/GameRoot.gd >/tmp/rv085l_gameroot_ui_refs.txt 2>/dev/null; then
  cat /tmp/rv085l_gameroot_ui_refs.txt
  echo "GameRoot still directly references UI panel/HUD scenes." >&2
  exit 1
fi
grep -q "res://scenes/ui/hud/FlaskHUD.tscn" scenes/ui/GameHUD.tscn
grep -q "res://scenes/ui/panels/LootFilterPanel.tscn" scenes/ui/UIPanelRoot.tscn
