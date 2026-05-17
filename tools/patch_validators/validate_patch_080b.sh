#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/data/CraftingCurrencyDB.gd
test -f scripts/systems/CraftingCurrencySystem.gd
grep -q "class_name RVCraftingCurrencyDB" scripts/data/CraftingCurrencyDB.gd
grep -q "class_name RVCraftingCurrencySystem" scripts/systems/CraftingCurrencySystem.gd
grep -q "RVCraftingCurrencySystem.ensure_defaults" scripts/core/GameState.gd
grep -q "RVCraftingCurrencySystem.handle_crafting_key" scripts/systems/BuildcraftSystem.gd
grep -q "Ash Temper" scripts/data/CraftingCurrencyDB.gd
grep -q "Forge Potential" scripts/systems/CraftingCurrencySystem.gd

echo "Patch 080B validation passed."
