#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 044 validation =="
test -f scripts/ui/panels/InventoryPanel.gd
grep -q "InventoryRichDetail" scripts/ui/panels/InventoryPanel.gd
grep -q "RuntimeTetrisLayer" scripts/ui/panels/InventoryPanel.gd
grep -q "COMPARED AGAINST" scripts/ui/panels/InventoryPanel.gd
grep -q "GAINS" scripts/ui/panels/InventoryPanel.gd
grep -q "LOSSES" scripts/ui/panels/InventoryPanel.gd

echo "Patch 044 files are present. Open Godot for parser validation."
