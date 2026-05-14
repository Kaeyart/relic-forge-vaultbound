# Relic Forge: Vaultbound — Architecture Target

## Rule

`Main.gd` is a coordinator, not the whole game.

## Current clean split

- `core/` owns state and save/load.
- `data/` owns definitions.
- `systems/` owns gameplay logic.
- `visuals/` owns drawing.
- `Main.gd` routes input and calls systems.

## Future extraction targets

- physical hub stations as actual scenes
- enemy prefabs as scenes
- projectiles as scenes or pooled draw objects
- proper HUD scene
- item tooltip scene
- room generation system
- actual asset-backed rendering instead of procedural placeholders

## Hard rule for future patches

Do not dump new systems into `Main.gd`.

Every new feature should land in the relevant system or data file.
