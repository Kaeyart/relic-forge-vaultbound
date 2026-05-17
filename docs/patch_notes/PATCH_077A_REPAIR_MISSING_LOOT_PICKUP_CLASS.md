# Patch 077A Repair — Missing Loot Pickup Assist Class

Fixes parser errors where `GameRoot.gd` and `GameState.gd` reference `RVLootPickupAssistSystem`, but the global class is missing or failed to parse.

The repair rewrites:
- `scripts/systems/LootPickupAssistSystem.gd`
- `scripts/visuals/LootPickupPetVisual.gd`

Both are kept parse-safe by avoiding a circular `RVGameState` type annotation.
