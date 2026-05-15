#!/usr/bin/env bash
set -euo pipefail
cd "${RELIC_FORGE_PROJECT:-/home/kaey/Desktop/Game}"

echo "== Validate Patch 030B =="
grep -q "item_detail_text_with_compare" scripts/systems/InventorySystem.gd
grep -q "equipped_short_label" scripts/systems/InventorySystem.gd
grep -q "normalize_slot" scripts/systems/InventorySystem.gd
grep -q "comparison_target_for_item" scripts/systems/InventorySystem.gd

echo "Inventory compatibility helpers are present."
if command -v godot >/dev/null 2>&1; then
  godot --headless --path . --quit || true
elif command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path . --quit || true
else
  echo "Godot binary not found; skipping headless parse check."
fi
