#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail=0

if grep -n "RVCraftingItemDragButton" scripts/ui/panels/CraftingPanel.gd >/tmp/084f_drag_refs.txt 2>/dev/null; then
  echo "ERROR: CraftingPanel.gd still hard-references RVCraftingItemDragButton:" >&2
  cat /tmp/084f_drag_refs.txt >&2
  fail=1
fi

if grep -n "RVItemDB\.has_method" scripts/ui/panels/CraftingPanel.gd >/tmp/084f_itemdb_hasmethod.txt 2>/dev/null; then
  echo "ERROR: CraftingPanel.gd still calls RVItemDB.has_method:" >&2
  cat /tmp/084f_itemdb_hasmethod.txt >&2
  fail=1
fi

if [ ! -f scripts/ui/panels/CraftingItemDragButton.gd ]; then
  echo "ERROR: CraftingItemDragButton.gd is missing." >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "Patch 084F validator passed."
