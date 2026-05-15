#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
[ -f scenes/ui/panels/InventoryPanel.tscn ]
[ -f scripts/ui/panels/InventoryPanel.gd ]
grep -q 'columns = 7' scenes/ui/panels/InventoryPanel.tscn
grep -q 'BackpackSlot48' scenes/ui/panels/InventoryPanel.tscn
grep -q '_compact_item_marker' scripts/ui/panels/InventoryPanel.gd
echo 'Patch 029B validation passed.'
