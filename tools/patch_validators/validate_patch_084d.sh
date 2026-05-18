#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[084D] ERROR: $*" >&2; exit 1; }
ok() { echo "[084D] OK: $*"; }

[ -f scripts/ui/panels/CraftingPanel.gd ] || fail "CraftingPanel.gd missing"
[ -f scenes/ui/panels/CraftingPanel.tscn ] || fail "CraftingPanel.tscn missing"
[ -f scripts/ui/controls/CraftingItemDragButton.gd ] || fail "CraftingItemDragButton.gd missing"
[ -f scripts/ui/controls/CraftingTargetDropZone.gd ] || fail "CraftingTargetDropZone.gd missing"

grep -q 'class_name RVCraftingPanel' scripts/ui/panels/CraftingPanel.gd || fail "CraftingPanel global class missing"
grep -q 'class_name RVCraftingItemDragButton' scripts/ui/controls/CraftingItemDragButton.gd || fail "drag button global class missing"
grep -q 'class_name RVCraftingTargetDropZone' scripts/ui/controls/CraftingTargetDropZone.gd || fail "drop zone global class missing"

grep -q 'TargetDropZone' scenes/ui/panels/CraftingPanel.tscn || fail "TargetDropZone missing from scene"
grep -q 'BackpackSlot16' scenes/ui/panels/CraftingPanel.tscn || fail "Backpack slot grid incomplete"
grep -q 'MaterialsLabel' scenes/ui/panels/CraftingPanel.tscn || fail "MaterialsLabel missing"
grep -q 'AshTemperButton' scenes/ui/panels/CraftingPanel.tscn || fail "crafting verb buttons missing"

if grep -qE 'Button\.new\(|Label\.new\(|Panel\.new\(|VBoxContainer\.new\(|HBoxContainer\.new\(|GridContainer\.new\(' scripts/ui/panels/CraftingPanel.gd; then
  fail "CraftingPanel.gd creates layout controls in code"
fi

if grep -q 'func _get(' scripts/ui/panels/CraftingPanel.gd; then
  fail "CraftingPanel.gd declares Object._get conflict"
fi

ok "scene-authored crafting table drag/drop UI installed"
