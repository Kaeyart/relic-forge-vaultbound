# Patch 068-071B — EnemyActor Block Repair

Fixes the remaining EnemyActor parser cascade after Patch 068-071.

The actual root error was `EnemyActor.gd` failing to parse because of an empty control block near line 278. Once `EnemyActor.gd` fails, every typed `RVEnemyActor` reference in `CombatArena.gd` also fails.

This patch:

- backs up `EnemyActor.gd` and `CombatArena.gd`
- inserts `pass` into empty GDScript control blocks in `EnemyActor.gd`
- ensures encounter compatibility fields exist: `pack_id`, `encounter_role`, `encounter_pack_type`
- ensures optional combat signals exist: `projectile_requested`, `zone_requested`, `spawn_requested`
- adds a fallback `_chain_lightning()` helper to `CombatArena.gd` only if missing

It does not touch scenes, UI, inventory, maps, skill gems, or assets.
