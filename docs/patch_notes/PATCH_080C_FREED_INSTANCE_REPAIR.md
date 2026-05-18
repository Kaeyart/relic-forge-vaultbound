# Patch 080C Repair — Loot filter freed-instance guard

Fixes a runtime crash where the loot filter/combat update pipeline could call `get_children()` on a node that had already been freed or queued for deletion.

## Changes
- Adds safe child iteration helpers to `CombatArena.gd`.
- Reorders `update_combat()` so inactive combat arenas do not scan combat/loot roots.
- Skips queued-for-deletion enemy/projectile children.
- Guards `RVLootFilterSystem.update_ground_loot()` against invalid combat instances.
- Guards the `GameRoot.gd` loot-filter update call.
