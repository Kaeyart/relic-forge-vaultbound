#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 027 validation =="
for f in \
  scenes/ui/panels/InventoryPanel.tscn \
  scenes/ui/panels/StashPanel.tscn \
  scripts/ui/panels/InventoryPanel.gd \
  scripts/ui/panels/StashPanel.gd \
  scripts/systems/InventorySystem.gd
 do
  test -f "$f" || { echo "Missing $f"; exit 1; }
  echo "OK $f"
 done

grep -Rni "BackpackSlot00\|EquipmentGrid\|StashSlot00\|RVInventorySystem.handle_panel_key" scenes scripts | head -80
