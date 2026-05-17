# Patch 057A — GameRoot Map Parse Fix

Fixes a compressed GDScript line introduced during Patch 057:

```gdscript
panels.update_from_state(state) _consume_pending_map_activity()
```

into:

```gdscript
panels.update_from_state(state)
_consume_pending_map_activity()
```

No gameplay, scene, inventory, skill gem, or map-system logic is changed.
