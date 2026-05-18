#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scenes/ui/panels/LootFilterPanel.tscn
test -f scripts/ui/panels/LootFilterPanel.gd
grep -q 'class_name RVLootFilterPanel' scripts/ui/panels/LootFilterPanel.gd
if grep -qE 'VBoxContainer|HBoxContainer|GridContainer' scenes/ui/panels/LootFilterPanel.tscn; then
  echo 'LootFilterPanel.tscn still contains layout containers; fixed-layout repair failed.' >&2
  exit 1
fi
if grep -qE '(Label|Button|Panel|VBoxContainer|HBoxContainer|GridContainer)\.new\(' scripts/ui/panels/LootFilterPanel.gd; then
  echo 'LootFilterPanel.gd creates UI controls at runtime; violates scene-authored UI.' >&2
  exit 1
fi
if grep -q '\[ON\]\|\[OFF\]' scripts/ui/panels/LootFilterPanel.gd; then
  echo 'LootFilterPanel.gd still rewrites toggle labels with dynamic prefixes.' >&2
  exit 1
fi

echo 'Patch 080F validation passed.'
