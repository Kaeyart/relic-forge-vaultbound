# Patch 016E — Save Load Missing Keys Fix

## Problem

Older save files do not contain the Patch 016 buildcraft keys.

`GameState.apply_save_dict()` checked `data.get("some_key", [])`, which returns the default array when the key is missing. That made the type check pass, then the code immediately accessed `data["some_key"]`, which crashes if the key is absent.

## Fix

`apply_save_dict()` now stores optional save fields in local `Variant` variables and assigns only the local value after checking its type.

Example fixed pattern:

```gdscript
var passive_atlas_allocated_value: Variant = data.get("passive_atlas_allocated", null)
if typeof(passive_atlas_allocated_value) == TYPE_ARRAY:
    passive_atlas_allocated = passive_atlas_allocated_value
```

This makes old save files compatible with the new buildcraft state.
