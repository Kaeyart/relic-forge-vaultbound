# Patch 035B — Safe Inventory Interaction Upgrade

This patch restores inventory usability without replacing the manually authored `InventoryPanel.tscn`.

It only replaces `scripts/ui/panels/InventoryPanel.gd`.

## Goals

- Preserve existing scene layout and art.
- Keep all UI placement scene-authored.
- Make current backpack slots, equipment slots, and action buttons functional.
- Show equipped item names in equipment buttons.
- Show selected backpack item details and comparison against currently equipped item.
- Show selected equipped item details when a gear slot is clicked.
- Make Equip / Stash / Destroy / Unequip / Close buttons visible and functional.

## Notes

This is not the final Tetris inventory. It is a safe usability repair for the current authored scene.
