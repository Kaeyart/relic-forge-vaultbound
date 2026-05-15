# Relic Forge: Vaultbound

Scene-authored Godot 4.6 buildcraft dungeon-crawler ARPG prototype.

## Current target loop

Hub → Map Device / activity gate → generated map or combat room → clear monster packs → kill boss / open reward chest → loot → inventory / stash / crafting / skill gems → repeat.

## Active boot scene

```text
res://scenes/main/GameRoot.tscn
```

This is the intended runtime entry point.

## Scene-authored rule

UI and hub/combat layout belong in `.tscn` scenes. Scripts update state, text, visibility, and gameplay data. Scripts should not hardcode screen UI layout positions except for temporary debug overlays or runtime-generated testing visuals.

## Active scene spine

```text
scenes/main/GameRoot.tscn
scenes/hub/ForgeholdHub.tscn
scenes/combat/CombatArena.tscn
scenes/prefabs/player/Player.tscn
scenes/prefabs/enemies/EnemyActor.tscn
scenes/prefabs/projectiles/ProjectileActor.tscn
scenes/ui/GameHUD.tscn
scenes/ui/UIPanelRoot.tscn
scenes/ui/panels/*.tscn
```

## Active script spine

```text
scripts/core/GameRoot.gd      coordinator
scripts/core/GameState.gd     runtime and persistent state
scripts/core/SaveSystem.gd    save/load
scripts/data/                 databases and definitions
scripts/systems/              gameplay systems
scripts/hub/                  hub station behavior
scripts/combat/               combat room and actor behavior
scripts/player/               player actor/controller
scripts/ui/                   UI scene scripts
scripts/dev/                  dev tools and Buildcraft Observatory
```

## Current docs

```text
docs/CURRENT_STATUS.md
docs/PRODUCTION_BASELINE.md
docs/CLEANUP_RULES.md
docs/ROADMAP_047_060.md
docs/ACTIVE_SCENE_SPINE.md
```

Historical patch notes live in:

```text
docs/patch_notes/
```

Historical patch validators live in:

```text
tools/patch_validators/
```

## Validation

```bash
cd /home/kaey/Desktop/Game
tools/validate_all.sh
```

## Legacy

Old one-file Patch 003 runtime files are kept only as reference under:

```text
scenes/legacy/patch003/
scripts/legacy/patch003/
```
