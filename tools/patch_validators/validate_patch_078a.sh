#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/systems/StashSystem.gd
grep -q "class_name RVStashSystem" scripts/systems/StashSystem.gd
grep -q "RVStashSystem.ensure_defaults" scripts/core/GameState.gd
grep -q "stash_tabs" scripts/core/GameState.gd
grep -q "CurrencyTabButton" scenes/ui/panels/StashPanel.tscn
grep -q "GemsTabButton" scenes/ui/panels/StashPanel.tscn
grep -q "BuyTabButton" scenes/ui/panels/StashPanel.tscn
grep -q "Deposit by Affinity" scripts/ui/panels/StashPanel.gd
grep -q "RVStashSystem" scripts/ui/panels/StashPanel.gd
if grep -R "RVMapDeviceArtSkin" scripts/ui/panels/StashPanel.gd scripts/ui/panels/InventoryPanel.gd scripts/ui/panels/MapDevicePanel.gd >/dev/null 2>&1; then
  echo "ERROR: stale RVMapDeviceArtSkin reference found" >&2
  exit 1
fi

echo "Patch 078A validation passed."
