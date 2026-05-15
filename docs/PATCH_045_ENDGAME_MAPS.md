# Patch 045 — Endgame Maps + Map Device

Adds a first endgame map loop:

Hub → Map Device → select map → run map → clear packs → kill boss → claim boss loot → return hub → inventory/stash → run again.

## Controls

- `N`: open Map Device panel from the hub.
- In Map Device: `W/S` selects maps, `Enter` or `R` runs selected map, `G` adds a dev map.

## Scene-authored station

A prefab exists at `res://scenes/prefabs/hub/MapDeviceStation.tscn`. Drag it into `ForgeholdHub.tscn` tomorrow and place it manually. The shortcut works now even before placing the station.

## First-pass limitations

Enemy drops currently go directly into backpack/map stash as notices. Fully visible ground item pickup piles should be a later combat-loot presentation pass.
