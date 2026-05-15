# Relic Forge: Vaultbound

Clean scene-authored Godot 4.6 baseline for a buildcraft dungeon-crawler ARPG.

## Current target loop

Hub → choose an activity gate → combat room → clear enemies → open reward chest → exit/return → manage inventory/crafting/passives/skills → repeat.

## Active boot scene

`res://scenes/main/GameRoot.tscn`

This is the only intended runtime entry point.

## Scene-authored rule

UI and hub/combat layout belong in `.tscn` scenes. Scripts update state, text, visibility, and gameplay data. Scripts should not hardcode screen UI layout positions unless they are temporary debug helpers.

## Active scene spine

- `scenes/main/GameRoot.tscn` — root scene that instances the game pieces.
- `scenes/hub/ForgeholdHub.tscn` — manually authored hub stations.
- `scenes/combat/CombatArena.tscn` — manually authored combat room layout.
- `scenes/prefabs/player/Player.tscn` — player actor.
- `scenes/prefabs/enemies/EnemyActor.tscn` — enemy actor prefab.
- `scenes/prefabs/projectiles/ProjectileActor.tscn` — projectile actor prefab.
- `scenes/ui/GameHUD.tscn` — scene-authored HUD.
- `scenes/ui/UIPanelRoot.tscn` — system panel root.
- `scenes/ui/panels/*.tscn` — inventory, crafting, passives, skill gems, character, stash, activities.

## Active script spine

- `scripts/core/GameRoot.gd` — coordinator.
- `scripts/core/GameState.gd` — runtime and persistent state.
- `scripts/core/SaveSystem.gd` — save/load.
- `scripts/hub/` — hub station behavior.
- `scripts/combat/` — combat actor/room behavior.
- `scripts/player/` — player controller.
- `scripts/ui/` — scene-authored UI scripts.
- `scripts/data/` — databases.
- `scripts/systems/` — gameplay systems.

## Legacy

Old one-file Patch 003 runtime files have been moved under:

- `scenes/legacy/patch003/`
- `scripts/legacy/patch003/`

They are kept only as historical reference and should not be used as active runtime files.
