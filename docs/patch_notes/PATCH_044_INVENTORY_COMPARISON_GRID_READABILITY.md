# Patch 044 — Inventory Comparison + Grid Readability

This patch preserves the existing scene-authored InventoryPanel.tscn and replaces only the panel controller script.

Goals:
- keep the authored UI scene intact;
- stop long item names from leaking into grid/equipment slots;
- show selected item and comparison target explicitly;
- color-code gains and losses in the detail panel;
- make action buttons state-driven and readable;
- add runtime grid-snapped tetris-style item blocks;
- allow dragging backpack items to new grid cells, equipment, stash, or salvage;
- keep equipped item visibility in the character summary and equipment tooltips.

Notes:
- This does not generate final item icon art.
- This does not replace the inventory scene layout.
- Persistent item positions are stored as `inv_x`, `inv_y`, `inv_w`, and `inv_h` inside item dictionaries.
