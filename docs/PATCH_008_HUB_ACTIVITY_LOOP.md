# Patch 008 — Hub + Activity Loop

## Goal

The game now needs a proper ARPG structure:

Hub -> choose activity -> manage character/build -> enter dungeon -> die/return -> hub.

Menus should not live on top of combat. Combat should be readable and active. Build planning should happen in the hub.

## Added

- Hub state
- Spatial hub stations
- Dungeon Gate
- Character station
- Passive Tree station
- Skill Tree station
- Loadout station
- Forge station
- Stash station
- Inventory handling
- Death returns to hub
- Dungeon start from hub
- Hub-only activity panels

## Controls in hub

- `E`: interact with nearby station
- `C`: Character
- `P`: Passive Tree / Mastery
- `K`: Skill Tree
- `L`: Loadout
- `V`: Forge
- `U`: Stash
- `Esc`: close menu

## Design intent

The player should spend time in a place, not in random overlays.

The hub is where RPG planning happens.

The dungeon is where combat and loot happen.

## Known next work

Patch 009 should improve itemization and loot:

- better affix tiers
- better item comparison
- crafting instability
- unique items
- target farming
- equipment sockets
- proper skill-tree node board
