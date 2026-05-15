# Patch 035 — Inventory Usability + Tetris Item Grid

This patch replaces the current inventory panel with a clearer, mouse-first inventory scene.

## Goals

- Make Equip / Unequip / Stash / Salvage buttons clearly visible.
- Make equipped items visible directly on gear buttons.
- Show selected backpack item and currently equipped comparison side by side.
- Display backpack items as variable-size, classic ARPG/Tetris-style shapes.
- Keep the screen layout scene-authored in `InventoryPanel.tscn`.

## Important limitation

This patch implements a variable-shape **display and selection layer** over the current backpack array. It does not yet implement true drag/drop manual placement or persistent per-item grid coordinates. That should be a later inventory patch after this usability pass is stable.

## Controls

- `I` opens Inventory.
- Click backpack item to inspect/compare.
- Click equipped gear to inspect/unequip.
- `Equip Selected` equips selected backpack item.
- `Stash Selected` moves selected backpack item to stash.
- `Salvage / Destroy` salvages selected backpack item into materials.
- `Unequip Gear` moves selected equipped item back to backpack.

## Item shape rules

- Weapons: tall or large depending on base/name.
- Chest armor: 2x3.
- Helmet/gloves/boots/relic/offhand: 2x2.
- Rings/amulets: 1x1.

True item icon art and persistent drag/drop grid coordinates are future work.
