# Patch 084D — Crafting Table Drag + Material Drawer

## Purpose

Makes crafting usable from inside the crafting table instead of forcing the player to jump between backpack, material view, and crafting hotkeys.

## Adds

- `scripts/ui/controls/CraftingItemDragButton.gd`
- `scripts/ui/controls/CraftingTargetDropZone.gd`
- scene-authored `scenes/ui/panels/CraftingPanel.tscn`
- rebuilt `scripts/ui/panels/CraftingPanel.gd`

## Features

- Backpack item rows inside the crafting table.
- Drag backpack item rows into the target forge slot.
- Click backpack item rows as a fallback targeting method.
- Selected crafting target card with rarity, slot, item level, required level, forge potential, stats, prefixes, suffixes, and crafted mods.
- Material/currency drawer inside the crafting table.
- Crafting verb buttons for existing currency verbs:
  - Ash Temper
  - Vault Alchemy
  - Regal Ember
  - Chaos Crucible
  - Exalted Shard
  - Scouring Ash
  - Essence Brand
  - Forge Seal
- Buttons route into the existing `RVBuildcraftSystem.handle_crafting_key()` flow.

## Production Rule

The UI layout is scene-authored. The script does not create layout controls. It only binds state, handles drag/drop data, and calls existing crafting systems.
