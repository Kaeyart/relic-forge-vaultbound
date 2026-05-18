# Patch 085M — GameRoot FlaskHUD Scene-Owner Repair

## Problem

Patch 085L moved FlaskHUD ownership into the HUD scene, but stale `flask_hud` references remained inside `scripts/core/GameRoot.gd`.

That caused parser errors like:

```text
Identifier "flask_hud" not declared in the current scope.
```

## Fix

- Removes stale `flask_hud` references from `GameRoot.gd`.
- Removes any direct `FlaskHUD.tscn` loading from `GameRoot.gd`.
- Removes stale `_install_flask_hud` call/function blocks if present.
- Keeps FlaskHUD owned by `GameHUD.tscn` / `GameHUD.gd`.

## Rule

`GameRoot.gd` should not own persistent HUD layout. It should update game flow only. HUD subcomponents belong under scene-authored HUD scenes.
