# Patch 027 — Clickable Inventory + Equipment UI

## Purpose

Patch 026 made inventory functional through keyboard selection. Patch 027 makes the inventory usable as an actual ARPG screen.

The new inventory layout follows the uploaded sketch:

- equipment slots close to the character area
- backpack grid directly under/near the equipment area
- item detail panel on the right
- clickable slot actions

## Scene-authored rule

The layout is in `.tscn` scenes. The scripts only populate data and respond to clicked nodes.

Do not hardcode UI positions in gameplay scripts.

## Updated scenes

- `res://scenes/ui/panels/InventoryPanel.tscn`
- `res://scenes/ui/panels/CharacterPanel.tscn`
- `res://scenes/ui/panels/StashPanel.tscn`

## Updated scripts

- `res://scripts/ui/panels/InventoryPanel.gd`
- `res://scripts/ui/panels/CharacterPanel.gd`
- `res://scripts/ui/panels/StashPanel.gd`
- `res://scripts/systems/InventorySystem.gd`
- `res://scripts/core/GameState.gd`
- `res://scripts/core/GameRoot.gd`

## Controls

Inventory:

- click backpack slot: select item
- click equipment slot: select equipped item
- Equip Selected: equips selected backpack item
- Stash Selected: sends selected backpack item to stash
- Salvage Selected: salvages selected backpack item
- Unequip Selected: unequips selected gear slot

Stash:

- click stash slot: select item
- Withdraw Selected: moves selected stash item to backpack
- Deposit All Backpack: sends all backpack items to stash

Keyboard controls from Patch 026 still work.
