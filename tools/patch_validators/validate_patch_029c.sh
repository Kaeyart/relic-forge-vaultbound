#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
printf "== Patch 029C validation ==\n"
grep -Rni "button.text = RVInventorySystem._slot_label\|button.text = .*Empty\|EquipmentSlots" scripts/ui/panels/InventoryPanel.gd || true
printf "Open Godot, press I, and verify equipment slot buttons no longer display labels or abbreviations.\n"
