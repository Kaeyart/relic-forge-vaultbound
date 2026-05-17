# Patch 075C — Map items click/drag + stash map tab

Maps are now treated as first-class physical item dictionaries in the backpack/stash pipeline.

## Added
- `RVMapItemSystem` shared helper for map-item normalization, labels, colors, detail text, and transfer operations.
- Inventory map item presentation: map-specific tooltip/detail text, 1x1 grid sizing, map color, map compact label.
- Inventory action routing: selected/dragged maps use `Store in Map Tab` instead of general stash.
- Stash tabs: Items tab and Maps tab using the existing `StashGrid`.
- Clickable map tab entries, tier filter controls, withdraw-to-backpack, and basic drag interactions.

## Controls
- Inventory: click map item to inspect, drag inside backpack, drag/click Store in Map Tab.
- Stash: click Items/Maps tab buttons.
- Stash Maps tab: click map to select, withdraw to backpack, use tier arrows, drag map to Withdraw.
