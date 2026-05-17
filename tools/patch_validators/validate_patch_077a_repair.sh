#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/systems/LootPickupAssistSystem.gd
test -f scripts/visuals/LootPickupPetVisual.gd
grep -q "class_name RVLootPickupAssistSystem" scripts/systems/LootPickupAssistSystem.gd
grep -q "static func ensure_defaults(state: Object)" scripts/systems/LootPickupAssistSystem.gd
grep -q "static func update(state: Object" scripts/systems/LootPickupAssistSystem.gd
grep -q "class_name RVLootPickupPetVisual" scripts/visuals/LootPickupPetVisual.gd
! grep -q "RVGameState" scripts/systems/LootPickupAssistSystem.gd
! grep -q "RVGameState" scripts/visuals/LootPickupPetVisual.gd

echo "Patch 077A repair validation passed."
