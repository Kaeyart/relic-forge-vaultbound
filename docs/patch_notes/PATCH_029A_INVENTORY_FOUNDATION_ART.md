# Patch 029A — Inventory Foundation Art Assets

This patch installs the first real Variation-5 inventory art foundation.

## Purpose

The chosen target direction is the Variation-5 style:

- left: character and equipment
- center: selected item detail card
- right: backpack grid
- bottom: actions/resources
- dark forged ARPG styling
- scene-authored layout, not hardcoded UI positioning

## Installed assets

Assets are installed under:

`res://assets/ui/patch029a_inventory_foundation/`

The patch includes:

- original cleaned source sheets
- sliced panel frames
- sliced inventory/equipment slot states
- sliced button/tab/search/filter assets
- sliced cursor assets
- sliced rarity borders and small UI chips
- JSON manifest with asset names, categories, and crop boxes

## Scene update

The patch replaces:

`res://scenes/ui/panels/InventoryPanel.tscn`

with a prepared scene using the new art as editable `TextureRect` nodes.

The functional node names are preserved:

- `%BackpackGrid`
- `%EquipmentGrid`
- `%DetailLabel`
- `%CharacterSummary`
- `%MaterialsLabel`
- `%EquipButton`
- `%StashButton`
- `%SalvageButton`
- `%UnequipButton`
- `%CloseButton`

So the existing inventory script should keep working.

## Manual Godot work after install

Open:

`res://scenes/ui/panels/InventoryPanel.tscn`

Then manually adjust:

- `ScreenBackdrop`
- `TopNavigationArt`
- `CharacterPanelArt`
- `ItemDetailPanelArt`
- `BackpackPanelArt`
- `StatsPanelArt`
- `ResourceStripArt`
- `EquipmentGrid`
- `BackpackGrid`
- action buttons

This patch gives you the art pieces and a first authored layout. It is not meant to be the final composition.
