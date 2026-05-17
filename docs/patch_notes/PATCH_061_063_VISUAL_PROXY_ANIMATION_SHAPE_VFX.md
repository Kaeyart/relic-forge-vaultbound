# Patch 061-063 — Visual Proxy Animation + Shape Kit + Spell VFX Library

This patch combines three visual proxy passes without using Blender or final sprite sheets.

## Included

- Patch 061: Visual proxy animation/readability pass
- Patch 062: Enemy shape kit
- Patch 063: Spell VFX library

## Files

- `scripts/data/EnemyShapeKitDB.gd`
- `scripts/visuals/EnemyVisualRig.gd`
- `scripts/visuals/VisualProxyVFXNode.gd`
- `scripts/visuals/SpellVFXSystem.gd`
- `scripts/combat/EnemyActor.gd`

## What changes

- Enemies are no longer drawn as basic circles.
- EnemyActor keeps the same public API used by CombatArena.
- Enemies get animated Godot-native silhouette rigs.
- Enemy roles have distinct silhouette recipes.
- Enemy visuals respond to idle/move/windup/attack/recover/hit/death.
- Spell casts and impacts get layered proxy VFX.
- Fireball, Storm Lance, Frost Nova, Void Rift, Cleave, and Blade Trap get distinct visual recipes.

## Notes

This is still Tier-1 visual proxy art, not final production art. The purpose is readability and identity while the final enemy/sprite pipeline is developed later.
