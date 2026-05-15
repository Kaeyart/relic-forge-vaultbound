#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 035 validation =="
test -f scenes/ui/panels/InventoryPanel.tscn
test -f scripts/ui/panels/InventoryPanel.gd

grep -q "GRID_COLUMNS" scripts/ui/panels/InventoryPanel.gd
grep -q "BackpackBoard" scenes/ui/panels/InventoryPanel.tscn
grep -q "Salvage / Destroy" scenes/ui/panels/InventoryPanel.tscn
grep -q "CandidateDetail" scenes/ui/panels/InventoryPanel.tscn
grep -q "EquippedDetail" scenes/ui/panels/InventoryPanel.tscn

echo "Patch 035 files are present. Open Godot for parser validation."
