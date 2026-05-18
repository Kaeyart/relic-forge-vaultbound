#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 085R =="

if grep -RInE '^\s*mouse_filter\s*=' scripts/ui/UIPanelRoot.gd scripts/ui/GameHUD.gd 2>/dev/null; then
  echo "ERROR: Found bare mouse_filter assignment in UI root scripts. Use descendant Control-only assignment." >&2
  exit 1
fi

if grep -RInE 'self\s+is\s+Control|as\s+Control' scripts/core/GameRoot.gd 2>/dev/null | grep -E 'panels|hud'; then
  echo "ERROR: Found unsafe GameRoot Control casts/checks for panels/hud." >&2
  exit 1
fi

if ! grep -q 'func _rf_085n_sync_input_ownership(state: Object) -> void:' scripts/ui/UIPanelRoot.gd; then
  echo "ERROR: Missing parse-safe _rf_085n_sync_input_ownership in UIPanelRoot.gd" >&2
  exit 1
fi

if ! grep -q '_rf_085n_apply_mouse_filter_to_controls' scripts/ui/UIPanelRoot.gd; then
  echo "ERROR: Missing descendant Control mouse filter helper in UIPanelRoot.gd" >&2
  exit 1
fi

echo "Patch 085R validation passed."
