#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/systems/MapItemSystem.gd
grep -q "class_name RVMapItemSystem" scripts/systems/MapItemSystem.gd
grep -q "Store in Map Tab" scripts/ui/panels/InventoryPanel.gd
grep -q "GeneralTabButton" scenes/ui/panels/StashPanel.tscn
grep -q "MapsTabButton" scenes/ui/panels/StashPanel.tscn
grep -q "RVMapItemSystem" scripts/ui/panels/StashPanel.gd

echo "Patch 075C validation passed."
