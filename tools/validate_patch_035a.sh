#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
echo "== Patch 035A validation =="
grep -Rni "RVInventorySystem.has_method" scripts/ui/panels/InventoryPanel.gd && { echo "Invalid static has_method remains"; exit 1; } || true
grep -Rni "static func equipped_item_for_item" scripts/systems/InventorySystem.gd >/dev/null
grep -Rni "static func normalize_slot" scripts/systems/InventorySystem.gd >/dev/null
echo "Patch 035A text validation passed."
