#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="${PROJECT_DIR:-/home/kaey/Desktop/Game}"

echo "== Validate Patch 029A =="
test -f "$PROJECT_DIR/project.godot"
test -f "$PROJECT_DIR/scenes/ui/panels/InventoryPanel.tscn"
test -f "$PROJECT_DIR/scripts/ui/RVCursorSystem.gd"
test -f "$PROJECT_DIR/assets/ui/patch029a_inventory_foundation/ui_patch029a_manifest.json"

echo "-- asset counts --"
find "$PROJECT_DIR/assets/ui/patch029a_inventory_foundation/slices" -type f -name "*.png" | wc -l

echo "-- key scene nodes --"
grep -q "BackpackGrid" "$PROJECT_DIR/scenes/ui/panels/InventoryPanel.tscn"
grep -q "EquipmentGrid" "$PROJECT_DIR/scenes/ui/panels/InventoryPanel.tscn"
grep -q "DetailLabel" "$PROJECT_DIR/scenes/ui/panels/InventoryPanel.tscn"
grep -q "ScreenBackdrop" "$PROJECT_DIR/scenes/ui/panels/InventoryPanel.tscn"

echo "Patch 029A validation passed."
