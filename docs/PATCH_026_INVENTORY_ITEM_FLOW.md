# Patch 026 — Inventory + Item Flow Vertical Slice

## Purpose

This patch turns the first ARPG reward loop into something readable:

Hub → Activity → Combat Room → Reward Chest → Backpack → Inventory → Equip / Stash / Salvage → Save.

## Added

- `scripts/systems/InventorySystem.gd`
- Functional Inventory panel text and controls
- Functional Character panel text and controls
- Functional Stash panel text and controls
- Item equip / unequip / stash / withdraw / salvage actions
- Selection cursors for backpack, gear, and stash
- GameRoot routing for panel key input

## Controls

### Inventory Panel

- `W/S` or arrow keys: select backpack item
- `Enter` / `E`: equip selected item
- `B`: move selected item to stash
- `X` / `Delete`: salvage selected item
- `Tab`: character panel
- `Esc`: close panel

### Character Panel

- `W/S` or arrow keys: select gear slot
- `Enter` / `E` / `X`: unequip selected gear
- `I` / `Tab`: inventory panel
- `Esc`: close panel

### Stash Panel

- `W/S` or arrow keys: select stash item
- `Enter` / `E`: withdraw selected item
- `X`: deposit all backpack items
- `I` / `B`: inventory panel
- `Esc`: close panel

## Notes

This is not the final grid UI. It is the functional item-flow spine. The panel scenes remain scene-authored and can later replace text lists with dragged slot nodes and UI art.
