# Patch 068-071D — EnemyActor Missing Combat Fields Fix

Fixes parser errors caused by Patch 068-071 role/combat tuning code referencing fields that were not declared in the current local `EnemyActor.gd`.

Adds missing class-scope compatibility fields only if absent:

```gdscript
var aggro_range: float = 360.0
var attack_range: float = 72.0
var windup: float = 0.35
var recovery: float = 0.75
var ai_timer: float = 0.0
var pack_id: String = ""
var encounter_role: String = ""
var encounter_pack_type: String = ""
```

Does not touch scenes, maps, inventory, skill gems UI, or visual assets.
