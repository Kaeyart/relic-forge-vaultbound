#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/systems/ItemizationSystem.gd
test -f scripts/systems/CraftingCurrencySystem.gd
grep -q "class_name RVItemizationSystem" scripts/systems/ItemizationSystem.gd
grep -q "class_name RVCraftingCurrencySystem" scripts/systems/CraftingCurrencySystem.gd
grep -q "static func normalize_item" scripts/systems/ItemizationSystem.gd
grep -q "static func handle_crafting_key" scripts/systems/CraftingCurrencySystem.gd
grep -q "static func crafting_hint_text" scripts/systems/CraftingCurrencySystem.gd

echo "Patch 080B repair validation passed."
