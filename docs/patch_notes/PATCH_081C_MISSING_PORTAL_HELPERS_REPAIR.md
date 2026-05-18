# PATCH 081C — Missing Portal Helper Repair

Repairs a partial Patch 081A install where `GameRoot.gd` references portal helpers that were never inserted.

Adds:
- `_rf_081a_portal_to_hub()`
- `_rf_081a_reenter_active_map_portal()`
- `_rf_081a_clear_active_map_portal()`
- `_rf_081a_capture_active_map_instance()`

Also adds CombatArena snapshot/restore helpers so leaving, dying, and re-entering an active map can restore the same map instance instead of respawning all enemies from scratch.

This patch also removes the invalid `Camera2D.clear_current()` call if it is still present.
