# Patch 084E — Crafting Drag Parse Repair

Fixes parser errors introduced by the crafting drag/material-drawer patch.

## Fixes

- Adds `scripts/ui/panels/CraftingItemDragButton.gd` with `class_name RVCraftingItemDragButton`.
- Removes invalid `RVItemDB.has_method("normalize_item")` direct class call from `CraftingPanel.gd`.
- Keeps the crafting panel scene-authored; this patch only repairs state-binding/row behavior.

## Install

```bash
cd /home/kaey/Downloads
rm -rf patch_084e_crafting_drag_parse_repair
unzip -o patch_084e_crafting_drag_parse_repair.zip -d /home/kaey/Downloads

cd /home/kaey/Desktop/Game
bash /home/kaey/Downloads/patch_084e_crafting_drag_parse_repair/install_patch_084e.sh

tools/patch_validators/validate_patch_084e.sh
tools/validate_all.sh
git status
```
