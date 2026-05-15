#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 035E =="

grep -Rni "move_backpack_item_to_grid" scripts/systems/InventorySystem.gd scripts/ui/panels/InventoryPanel.gd >/dev/null
grep -Rni "_try_reposition_dragged_item\|_drop_cell_from_global" scripts/ui/panels/InventoryPanel.gd >/dev/null
grep -Rni "inv_x\|inv_y" scripts/ui/panels/InventoryPanel.gd scripts/systems/InventorySystem.gd >/dev/null

echo "Patch 035E files look present. Reopen Godot for parser validation."
