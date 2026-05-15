#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 035B validation =="
test -f scripts/ui/panels/InventoryPanel.gd
grep -q "Patch 035B" scripts/ui/panels/InventoryPanel.gd
grep -q "func _on_equip_pressed" scripts/ui/panels/InventoryPanel.gd
grep -q "func _item_detail_text_with_compare" scripts/ui/panels/InventoryPanel.gd
if grep -q "RVInventorySystem.has_method" scripts/ui/panels/InventoryPanel.gd; then
  echo "Bad static has_method call still present."
  exit 1
fi

echo "OK: InventoryPanel.gd safe interaction patch is installed."
