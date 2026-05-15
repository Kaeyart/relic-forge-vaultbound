#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 029E validation =="
grep -Rni "static func select_stash_index" scripts/systems/InventorySystem.gd
grep -Rni "select_stash_index" scripts/ui/panels/StashPanel.gd scripts/systems/InventorySystem.gd

echo "OK: stash select helper is present."
