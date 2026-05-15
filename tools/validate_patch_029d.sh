#!/usr/bin/env bash
set -euo pipefail
cd "${RELIC_FORGE_PROJECT:-/home/kaey/Desktop/Game}"
echo "== Validate Patch 029D =="
grep -Rni "item_detail_text_with_compare\|equipped_summary_text\|EquippedNameWeapon" scripts/systems/InventorySystem.gd scripts/ui/panels/InventoryPanel.gd docs/PATCH_029D_INVENTORY_COMPARE_VISIBILITY.md
if command -v godot >/dev/null 2>&1; then
  godot --headless --path . --quit || true
elif command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path . --quit || true
else
  echo "Godot binary not found; skipping headless parse check."
fi
