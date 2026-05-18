#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scenes/ui/panels/LootFilterPanel.tscn
test -f scripts/ui/panels/LootFilterPanel.gd
grep -q 'class_name RVLootFilterPanel' scripts/ui/panels/LootFilterPanel.gd
grep -q 'VisibilityGrid' scenes/ui/panels/LootFilterPanel.tscn
grep -q 'AutoPickupPanel' scenes/ui/panels/LootFilterPanel.tscn
grep -q 'ThresholdPanel' scenes/ui/panels/LootFilterPanel.tscn
grep -q 'BuildPanel' scenes/ui/panels/LootFilterPanel.tscn
grep -q 'KEY_L: state.toggle_panel("loot_filter")' scripts/core/GameRoot.gd
if grep -qE '(Label|Button|Panel|VBoxContainer|HBoxContainer|GridContainer)\.new\(' scripts/ui/panels/LootFilterPanel.gd; then
  echo 'LootFilterPanel.gd is creating layout controls at runtime; this violates scene-authored UI.' >&2
  exit 1
fi

echo 'Patch 080D validation passed.'
