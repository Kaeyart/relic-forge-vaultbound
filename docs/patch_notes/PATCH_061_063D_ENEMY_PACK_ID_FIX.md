# Patch 061-063D — Enemy Pack ID Compatibility Fix

Fixes a runtime crash in map objective tracking:

```text
Invalid access to property or key 'pack_id' on RVEnemyActor
```

Cause: `CombatArena.gd` expects spawned enemies to expose encounter metadata such as `pack_id`, but the current `EnemyActor.gd` did not declare that property.

Changes:

- Adds `pack_id`, `encounter_role`, and `encounter_pack_type` to `EnemyActor.gd`.
- Populates them from `enemy_data` in `setup()`.
- Does not touch scenes, art, skill gems, inventory, map layout, or VFX.

Validate:

```bash
cd /home/kaey/Desktop/Game
tools/validate_patch_061_063d.sh
```
