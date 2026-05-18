# Patch 083C — CombatArena Decomposition Prep

This patch does not add gameplay. It extracts the safest parts of `CombatArena.gd` into small systems while preserving the old helper function names and call sites.

## Added

- `scripts/systems/CombatRootSystem.gd`
- `scripts/systems/MapInstancePersistenceSystem.gd`
- `scripts/systems/CombatProjectileCollisionSystem.gd`
- `scripts/systems/CombatRewardExitSystem.gd`
- `tools/patch_validators/validate_patch_083c.sh`

## Changed

`CombatArena.gd` now delegates root/layer helper functions to `RVCombatRootSystem`:

- `_rf_live_node2d()`
- `_rf_named_node2d()`
- `_rf_ensure_combat_layers()`
- `_rf_loot_root()`
- `_clear_children()`
- `_rf_safe_children()`
- `_rf_child_count()`

## Intent

The goal is to reduce future patch risk. `CombatArena.gd` can keep its current behavior, but root lifecycle, layer ownership, child iteration, map snapshotting, projectile collision, and reward/exit helpers now have dedicated extraction targets.

## Non-goals

- No new classes/passives.
- No map layout changes.
- No drop-rate tuning.
- No enemy AI rewrite.
- No visual art changes.
