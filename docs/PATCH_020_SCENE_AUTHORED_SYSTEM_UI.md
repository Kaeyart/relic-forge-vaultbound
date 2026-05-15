# Patch 020 — Scene-Authored System UI

This patch adds real Godot scene files for the major non-combat UI panels. The goal is to stop drawing menus from code and let the UI be authored in the Godot editor.

The code updates data. The scene controls layout.

## New editable scenes

Open these directly in Godot and drag things by hand:

- `res://scenes/ui/UIPanelRoot.tscn`
- `res://scenes/ui/panels/InventoryPanel.tscn`
- `res://scenes/ui/panels/CraftingPanel.tscn`
- `res://scenes/ui/panels/PassiveAtlasPanel.tscn`
- `res://scenes/ui/panels/SkillGemsPanel.tscn`
- `res://scenes/ui/panels/CharacterPanel.tscn`
- `res://scenes/ui/panels/StashPanel.tscn`
- `res://scenes/ui/panels/ActivityPanel.tscn`

## Hotkeys

Handled by `UIPanelRoot.gd` using `_input`:

- `I`: Inventory
- `C`: Crafting
- `P`: Passive Atlas
- `K`: Skill Gems
- `Tab`: Character
- `B`: Stash
- `M`: Activities / game modes
- `Esc`: close open panel

## Scene authoring rule

Scripts only fill text/list content and toggle panel visibility. Sizes, positions, and art placement are owned by the `.tscn` files.

## Manual art workflow

Replace placeholder `ColorRect` nodes with `TextureRect` or `NinePatchRect` nodes using your sliced UI assets. Keep node names stable so future code can target them.
