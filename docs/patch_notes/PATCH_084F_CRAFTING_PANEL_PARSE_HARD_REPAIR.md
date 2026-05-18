# Patch 084F — Crafting Panel Parse Hard Repair

This repair removes parse-time dependency on `RVCraftingItemDragButton` from `CraftingPanel.gd`.

The drag button class may still exist and be used by scene/script instances, but `CraftingPanel.gd` now treats those controls as generic `Button` nodes to avoid Godot global-class registration timing failures.

It also removes invalid `RVItemDB.has_method(...)` class-level calls and uses `RVItemDB.normalize_item(item)` directly.
