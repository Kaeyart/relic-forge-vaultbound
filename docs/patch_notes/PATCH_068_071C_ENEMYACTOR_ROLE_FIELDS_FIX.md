# Patch 068-071C — EnemyActor Role Fields Fix

Fixes a parser error caused by Patch 068-071 role tuning code referencing combat timing fields that were not declared in `EnemyActor.gd`.

Adds safe compatibility fields if missing:

- `aggro_range`
- `attack_range`
- `windup`
- `recovery`
- `pack_id`
- `encounter_role`
- `encounter_pack_type`

Also allows `setup(enemy_data)` to receive optional tuning values from enemy data where available.
