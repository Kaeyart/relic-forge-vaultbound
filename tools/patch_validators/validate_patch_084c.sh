#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail=0

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "[084C][ERROR] missing $1"
    fail=1
  else
    echo "[084C][OK] $1"
  fi
}

require_file "scripts/ui/panels/CraftingPanel.gd"
require_file "scenes/ui/panels/CraftingPanel.tscn"
require_file "docs/patch_notes/PATCH_084C_CRAFTING_UI_UX.md"

if grep -qE '^func[[:space:]]+_get\(' scripts/ui/panels/CraftingPanel.gd; then
  echo "[084C][ERROR] CraftingPanel.gd defines forbidden _get(...) helper"
  fail=1
else
  echo "[084C][OK] no forbidden _get helper"
fi

if grep -qE '(Button|Label|Panel|RichTextLabel|ProgressBar)\.new\(' scripts/ui/panels/CraftingPanel.gd; then
  echo "[084C][ERROR] CraftingPanel.gd creates layout controls in code"
  fail=1
else
  echo "[084C][OK] no script-created UI layout controls"
fi

for node in SelectedItemTitle SelectedItemMeta SelectedItemDetails ForgePotentialBar PrefixList SuffixList CraftedList CurrencySummary AshTemperButton VaultAlchemyButton RegalEmberButton ChaosCrucibleButton ExaltedShardButton ScouringAshButton EssenceBrandButton ForgeSealButton; do
  if ! grep -q "name=\"$node\"\|name = \"$node\"" scenes/ui/panels/CraftingPanel.tscn; then
    echo "[084C][ERROR] missing scene node $node"
    fail=1
  fi
done

if ! grep -q 'class_name RVCraftingPanel' scripts/ui/panels/CraftingPanel.gd; then
  echo "[084C][ERROR] missing class_name RVCraftingPanel"
  fail=1
fi

if ! grep -q 'extends RVUIPanelBase' scripts/ui/panels/CraftingPanel.gd; then
  echo "[084C][ERROR] CraftingPanel should extend RVUIPanelBase"
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "[084C] validation failed"
  exit 1
fi

echo "[084C] validation passed"
