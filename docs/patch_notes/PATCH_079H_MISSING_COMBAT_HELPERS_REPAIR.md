# Patch 079H — Missing combat helper repair

Repairs missing helper functions referenced by the 079G combat/map-portal patch:

- `_rf_has_combat_los()`
- `_rf_combat_los_hit_allowed()`
- `_rf_constrain_entity_movement()`

These helpers keep player/enemy hits, projectiles, and entity movement compatible with the continuous map layout geometry system.
