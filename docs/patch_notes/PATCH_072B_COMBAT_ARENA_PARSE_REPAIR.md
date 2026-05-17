# Patch 072B — CombatArena Parse Repair

Repairs Patch 072/072A integration by replacing the ground-loot helper block with a safer version that avoids global-class type annotations in `CombatArena.gd`.

Also reinstalls known-good versions of:

- `scripts/combat/LootDropActor.gd`
- `scripts/systems/FloatingCombatTextSystem.gd`
- `scripts/systems/LootDropSystem.gd`

This keeps ground loot, damage numbers, and render-layer ordering while reducing parser dependency on Godot's class cache.
