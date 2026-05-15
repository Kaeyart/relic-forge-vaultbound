# Patch 035E — Inventory Persistent Reposition

This patch completes the missing interaction from the runtime tetris inventory pass.

It does **not** replace `InventoryPanel.tscn`.

## What it adds

- Backpack items store `inv_x` / `inv_y` grid positions directly on the item dictionary.
- Newly dropped items are auto-packed into the first available grid space.
- Existing positioned items keep their positions across UI refreshes and saves.
- Dragging a backpack item onto an empty valid backpack grid cell moves it there.
- Dragging onto an occupied or invalid cell returns the item and shows a notice.
- Dragging onto equipment/action buttons still works.

## Limitations

This is still not final inventory polish. It supports persistent repositioning, but it does not yet support rotation, item swapping, or drag-to-stash-grid placement.

## Test

1. Open Inventory with `I`.
2. Drag a backpack item to an empty grid space.
3. Release.
4. Confirm the item moves there.
5. Close/reopen Inventory.
6. Confirm the item remains in the new position.
7. Drag an item onto an occupied cell.
8. Confirm it refuses and returns.
9. Drag an item onto a matching equipment slot.
10. Confirm it equips.
