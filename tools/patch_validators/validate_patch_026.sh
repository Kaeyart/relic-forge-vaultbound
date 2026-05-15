#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 026 validation =="
for f in \
  scripts/systems/InventorySystem.gd \
  scripts/core/GameRoot.gd \
  scripts/core/GameState.gd \
  scripts/ui/panels/InventoryPanel.gd \
  scripts/ui/panels/CharacterPanel.gd \
  scripts/ui/panels/StashPanel.gd \
  docs/PATCH_026_INVENTORY_ITEM_FLOW.md
 do
  if [ -f "$f" ]; then
    echo "OK $f"
  else
    echo "MISSING $f"
    exit 1
  fi
 done

grep -Rni "RVInventorySystem" scripts/core/GameRoot.gd scripts/ui/panels scripts/systems/InventorySystem.gd | head -40
