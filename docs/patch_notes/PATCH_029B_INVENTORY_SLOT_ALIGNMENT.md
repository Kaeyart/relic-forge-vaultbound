# Patch 029B — Inventory Slot Alignment

Purpose: fix the first visible scene-authored inventory issue after Patch 029A.

Changes:
- Aligns `BackpackGrid` to the baked backpack grid art.
- Changes backpack grid from oversized text buttons to 7-column art-aligned click targets.
- Rebuilds 49 backpack slot buttons to match the visible grid capacity.
- Removes noisy `Empty` labels from empty slots.
- Keeps filled items as tiny temporary two-letter markers until real item icons are integrated.
- Adds tooltips for filled item slots.
- Adds an authoring note so the grid can be moved together if the art moves.

Current target geometry:
- BackpackGrid: x 856, y 182
- Columns: 7
- Slot size: 40 x 42
- Gaps: 4 px

If you move `BackpackPanelArt`, move `BackpackGrid` with it.
