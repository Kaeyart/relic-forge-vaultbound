#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/data/LootFilterDB.gd
test -f scripts/systems/LootFilterSystem.gd
test -f scripts/ui/panels/LootFilterPanel.gd
test -f scenes/ui/panels/LootFilterPanel.tscn
grep -q "class_name RVLootFilterDB" scripts/data/LootFilterDB.gd
grep -q "class_name RVLootFilterSystem" scripts/systems/LootFilterSystem.gd
grep -q "class_name RVLootFilterPanel" scripts/ui/panels/LootFilterPanel.gd
grep -q "toggle_panel(\"loot_filter\")" scripts/core/GameRoot.gd
grep -q "loot_filter_settings" scripts/core/GameState.gd
grep -q "RVLootFilterSystem.update_ground_loot" scripts/core/GameRoot.gd

echo "Patch 080C validation passed."
