#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
printf '== Patch 035C validation ==\n'
test -f scripts/ui/panels/InventoryPanel.gd
test -f scripts/systems/InventorySystem.gd
grep -q "RuntimeTetrisBackpackLayer" scripts/ui/panels/InventoryPanel.gd
grep -q "equip_backpack_item_to_slot" scripts/systems/InventorySystem.gd
grep -q "item_grid_size" scripts/systems/InventorySystem.gd
printf 'Patch 035C files are present. Open Godot to validate script parsing.\n'
