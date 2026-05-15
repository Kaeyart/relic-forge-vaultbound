#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
missing=0
for f in \
  scripts/data/ItemBaseDB.gd \
  scripts/data/ItemAffixDB.gd \
  scripts/data/ItemDB.gd \
  scripts/systems/ItemRollSystem.gd \
  scripts/systems/ForgecraftSystem.gd \
  scripts/systems/ItemValidationSystem.gd \
  scripts/systems/BuildcraftSystem.gd \
  scripts/systems/InventorySystem.gd \
  scripts/ui/panels/CraftingPanel.gd \
  scripts/dev/lab/LabItemEvaluator.gd; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f"
    missing=1
  else
    echo "OK: $f"
  fi
done
if [[ "$missing" != "0" ]]; then
  exit 1
fi

grep -q "class_name RVForgecraftSystem" scripts/systems/ForgecraftSystem.gd
grep -q "class_name RVItemValidationSystem" scripts/systems/ItemValidationSystem.gd
grep -q "static func roll_affix" scripts/data/ItemAffixDB.gd
grep -q "static func rebuild_item" scripts/systems/ItemRollSystem.gd
grep -q "static func move_backpack_item_to_grid" scripts/systems/InventorySystem.gd
echo "Patch 037-041 validation passed. Reopen Godot for class refresh."
