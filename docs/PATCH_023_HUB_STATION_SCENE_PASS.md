# Patch 023 — Hub Station Scene Pass

## Purpose

This patch converts the hub station workflow into a more scene-authored setup.

The hub is now edited through:

- `res://scenes/hub/ForgeholdHub.tscn`
- `res://scenes/prefabs/hub/HubStationBase.tscn`

You can manually drag stations, visuals, labels, and collision areas in the editor.

## Important rule

Scripts do not create the hub layout.

Scripts only read station metadata and handle interaction routing.

## Active files

- `scripts/hub/HubRoot.gd`
- `scripts/hub/HubStation.gd`
- `scenes/hub/ForgeholdHub.tscn`
- `scenes/prefabs/hub/HubStationBase.tscn`

## Hub station node contract

Each station should be a `Node2D` with `RVHubStation.gd` and these optional children:

```text
Visual: Sprite2D
NameLabel: Label
InteractionArea: Area2D
  CollisionShape2D
```

The exported fields on the station define:

- station id
- station type
- display name
- activity id
- prompt text
- interaction radius
- station color
- visual texture
- visual scale

## Station types

```text
activity      -> starts a contract/activity
inventory     -> opens inventory panel
crafting      -> opens crafting panel
passive       -> opens passive atlas panel
skills        -> opens skill gems panel
stash         -> opens stash panel
character     -> opens character panel
training      -> placeholder for training dummy
none          -> decorative / unwired
```

## Manual editing workflow

Open:

```text
res://scenes/hub/ForgeholdHub.tscn
```

Move these station groups manually:

```text
Stations/ActivityGates
Stations/HubServices
```

Move individual stations manually:

```text
DungeonRun
MaterialHunt
EliteHunt
BossTrial
EndlessRift
Inventory
Crafting
Stash
PassiveAtlas
SkillGems
Character
TrainingDummy
```

## Test checklist

1. Launch.
2. Move around the hub.
3. Walk near each station.
4. Confirm the prompt updates.
5. Press E on every activity gate.
6. Press E on Inventory, Crafting, Passive Atlas, Skill Gems, Stash, Character.
7. Confirm panels open correctly.
8. Confirm station visuals can be manually moved in the scene.

## Next recommended patch

Patch 024 should focus on the combat room vertical slice:

- player spawn point
- enemy spawn points
- exit portal
- reward chest
- room objective markers
- no random hardcoded room layout
