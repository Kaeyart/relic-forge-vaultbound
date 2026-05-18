# Patch 082B — FlaskHUD `_get` Name Conflict Repair

Fixes a Godot parser error in `scripts/ui/hud/FlaskHUD.gd`:

```text
The function signature doesn't match the parent. Parent signature is "_get(StringName) -> Variant".
```

Cause: `FlaskHUD.gd` declared a helper function named `_get(state, key, fallback)`. Godot `Object` already owns the virtual method `_get(StringName) -> Variant`, so declaring another `_get` signature in a `Control`-derived script is invalid.

Fix:

- Renames helper `func _get(...)` to `func _state_get(...)`.
- Renames direct helper calls `_get(state, ...)` to `_state_get(state, ...)`.
- Adds a validator to prevent this exact regression.
