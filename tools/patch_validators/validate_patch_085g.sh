#!/usr/bin/env bash
set -euo pipefail

cd /home/kaey/Desktop/Game

fail() {
  echo "[085G] ERROR: $1" >&2
  exit 1
}

[[ -f scripts/ui/panels/PassiveAtlasPanel.gd ]] || fail "PassiveAtlasPanel.gd missing"
[[ -f scripts/ui/components/PassiveTreeNodeButton.gd ]] || fail "PassiveTreeNodeButton.gd missing"
[[ -f scripts/ui/components/PassiveTreeConnectionCanvas.gd ]] || fail "PassiveTreeConnectionCanvas.gd missing"
[[ -f scenes/ui/components/PassiveTreeNodeButton.tscn ]] || fail "PassiveTreeNodeButton.tscn missing"

grep -q "GeneratedTreeScroll" scripts/ui/panels/PassiveAtlasPanel.gd || fail "PassiveAtlasPanel does not install visible generated tree scroll"
grep -q "_rebuild_tree" scripts/ui/panels/PassiveAtlasPanel.gd || fail "PassiveAtlasPanel missing tree rebuild"
grep -q "passive_node_pressed" scripts/ui/components/PassiveTreeNodeButton.gd || fail "Node button signal missing"
grep -q "draw_line" scripts/ui/components/PassiveTreeConnectionCanvas.gd || fail "Connection canvas does not draw connections"

if grep -R "for node: Dictionary in PassiveDBScript.nodes" -n scripts/ui/components scripts/ui/panels >/dev/null 2>&1; then
  fail "Typed Dictionary loop over PassiveDBScript.nodes() still exists"
fi

if grep -R "RVMapDeviceArtSkin" -n scripts scenes >/dev/null 2>&1; then
  fail "Stale RVMapDeviceArtSkin reference exists"
fi

if grep -R "clear_current()" -n scripts >/dev/null 2>&1; then
  fail "Invalid Camera2D.clear_current() call exists"
fi

echo "[085G] Passive tree visibility repair validator passed."
