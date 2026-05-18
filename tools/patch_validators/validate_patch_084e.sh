#!/usr/bin/env bash
set -euo pipefail

fail=0

if [ ! -f scripts/ui/panels/CraftingItemDragButton.gd ]; then
  echo "ERROR: missing scripts/ui/panels/CraftingItemDragButton.gd" >&2
  fail=1
fi

if ! grep -q "class_name RVCraftingItemDragButton" scripts/ui/panels/CraftingItemDragButton.gd 2>/dev/null; then
  echo "ERROR: CraftingItemDragButton.gd does not declare class_name RVCraftingItemDragButton" >&2
  fail=1
fi

if grep -q 'RVItemDB\.has_method("normalize_item")' scripts/ui/panels/CraftingPanel.gd; then
  echo "ERROR: CraftingPanel.gd still calls RVItemDB.has_method(\"normalize_item\")" >&2
  fail=1
fi

# Guard against the recurring Object._get override parser issue in this panel stack.
if grep -R "^func _get(state" -n scripts/ui/panels scripts/ui/hud scripts/systems 2>/dev/null; then
  echo "ERROR: found custom _get(state, ...) helper; rename to _state_get" >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "Patch 084E validator passed."
