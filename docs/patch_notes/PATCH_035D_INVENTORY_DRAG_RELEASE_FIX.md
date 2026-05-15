# Patch 035D — Inventory Drag Release Fix

Fixes the inventory drag preview getting stuck when an item is dragged off its original button.

Root cause: `Button.gui_input` only receives mouse release if the cursor remains over the button. Dragging away meant `_finish_drag_drop()` never ran.

Changes:
- Adds global `_input()` release handling while dragging.
- Right click / Esc cancels drag.
- Replaces Control-safe drag preview positioning.
- Drop outside valid targets returns item to backpack and clears preview.
- Drag preview ignores mouse input so it does not block drop targets.

Does not replace `InventoryPanel.tscn`.
