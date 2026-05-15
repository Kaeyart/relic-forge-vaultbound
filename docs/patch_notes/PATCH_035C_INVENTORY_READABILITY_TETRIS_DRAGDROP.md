# Patch 035C — Inventory Readability + Tetris Drag/Drop

This patch keeps the authored `InventoryPanel.tscn` layout and upgrades the runtime behavior.

## Goals

- Stop long item names leaking into backpack cells.
- Stop equipment slots from becoming unreadable text blocks.
- Keep action buttons visible and state-driven.
- Show selected item details and equipped comparison in a concise panel.
- Add a runtime tetris-style backpack overlay using variable item dimensions.
- Add basic mouse drag from backpack items onto equipment slots, Equip, Stash, or Destroy/Salvage.

## Notes

The tetris layer is runtime-generated from the existing `BackpackGrid` node. The authored scene remains the placement source. This avoids replacing the manually-authored UI.

This is not yet a full persistent manual placement inventory. Items are auto-packed into tetris shapes every update. Persistent drag-to-rearrange can come later once the interaction layer is stable.
