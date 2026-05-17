# Patch 077A — Loot Pickup Pet + Auto Pickup Rules

Adds a first-pass loot pickup assistant so the player does not manually click basic resources.

## Adds
- `RVLootPickupAssistSystem`
- `LootPickupPet.tscn`
- `RVLootPickupPetVisual`
- GameState loot pickup/filter defaults
- GameRoot update hook

## Behavior
The pet scans combat loot actors and auto-collects eligible drops in range.

Auto-pickup defaults:
- Gold: ON
- Shards: ON
- Embers: ON
- Materials: ON
- Currency-like drops: ON
- Maps: OFF by default
- Gems: OFF by default
- Gear/manual item decisions: OFF by default

## Design rule
The pet removes friction from non-decision loot. Decision loot remains manual until Loot Filter V1.
