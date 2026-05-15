# Patch 029D — Inventory Compare + Equipped Visibility

This is a minor inventory usability patch after the first art/layout pass.

## Changes

- Backpack item details now compare against the currently equipped item in the matching slot.
- Clicking an equipment slot now shows that equipped item's details even when the backpack has items.
- Equipment buttons remain mostly art-safe: they show only a small rarity diamond when occupied instead of dumping item names into the slot.
- The character summary now lists all equipped items so the player can see what they are wearing even before item icons exist.
- Equipment slot detection is more flexible and supports manually renamed/reparented scene nodes.
- Optional per-slot equipped-name labels are supported if the scene later adds labels named like `EquippedNameWeapon`, `EquippedNameHelmet`, etc.

## Important scene-authored rule

The script still does not own equipment-slot placement. Slot layout belongs in `InventoryPanel.tscn`.

## Optional label naming

If you want visible item-name labels beside slots, add Label nodes with these names:

- `EquippedNameWeapon`
- `EquippedNameHelmet`
- `EquippedNameChest`
- `EquippedNameGloves`
- `EquippedNameBoots`
- `EquippedNameAmulet`
- `EquippedNameRing1`
- `EquippedNameRing2`
- `EquippedNameRelic`
- `EquippedNameOffhand`

The script will update their text without moving them.
