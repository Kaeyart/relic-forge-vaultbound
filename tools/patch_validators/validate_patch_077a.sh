#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/systems/LootPickupAssistSystem.gd
test -f scripts/visuals/LootPickupPetVisual.gd
test -f scenes/prefabs/player/LootPickupPet.tscn
grep -q "class_name RVLootPickupAssistSystem" scripts/systems/LootPickupAssistSystem.gd
grep -q "var loot_pet_enabled" scripts/core/GameState.gd
grep -q "RVLootPickupAssistSystem.update" scripts/core/GameRoot.gd
grep -q "_install_loot_pickup_pet" scripts/core/GameRoot.gd

echo "Patch 077A validation passed."
