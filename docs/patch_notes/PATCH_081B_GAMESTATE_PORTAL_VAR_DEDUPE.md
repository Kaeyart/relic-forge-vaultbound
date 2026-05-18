# Patch 081B — GameState Active Map Portal Var Dedupe

Repairs duplicate `active_map_portal_*` declarations in `scripts/core/GameState.gd` after the 079L / 081A patch overlap.

Keeps exactly one canonical block:

```gdscript
var active_map_portal_activity: Dictionary = {}
var active_map_portal_entries: int = 0
var active_map_portal_max_entries: int = 6
var active_map_portals_remaining: int = 0
```

This is a parser repair only. It does not alter flask behavior or map portal behavior.
