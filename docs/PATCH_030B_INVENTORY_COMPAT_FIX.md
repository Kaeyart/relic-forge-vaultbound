# Patch 030B — Inventory Compatibility Fix

Patch 030 reworked itemization and replaced `InventorySystem.gd`, but the clickable inventory UI still depends on public helper functions from Patch 029D.

This patch restores those public helper names without removing the new itemization logic:

- `item_detail_text_with_compare(state, item)`
- `comparison_target_for_item(state, item)`
- `equipped_short_label(state, slot_name)`
- `normalize_slot(slot_name)`

It also makes equipment slot selection tolerant of scene-authored slot names like `SlotWeapon`, `SlotHelmet`, `MainHand`, `LeftRing`, and so on.

## Why this exists

The inventory scene is now manually authored. Scripts must support flexible node names and should not force old layout assumptions.
