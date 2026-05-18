#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

fail() { echo "[085I] ERROR: $*" >&2; exit 1; }

[[ -f scripts/ui/panels/PassiveAtlasPanel.gd ]] || fail "Missing PassiveAtlasPanel.gd"
[[ -f scripts/ui/components/PassiveTreeNodeButton.gd ]] || fail "Missing PassiveTreeNodeButton.gd"
[[ -f scenes/ui/components/PassiveTreeNodeButton.tscn ]] || fail "Missing PassiveTreeNodeButton.tscn"

grep -q "func _on_tree_scroll_gui_input" scripts/ui/panels/PassiveAtlasPanel.gd || fail "Passive panel lacks mouse pan handler"
grep -q "Left-click is now inspection/highlight only" scripts/ui/panels/PassiveAtlasPanel.gd || fail "Passive panel left-click behavior was not patched"
grep -q "Right-click immediately spends" scripts/ui/panels/PassiveAtlasPanel.gd || fail "Passive panel right-click allocation behavior missing"
grep -q "passive_node_secondary_pressed" scripts/ui/components/PassiveTreeNodeButton.gd || fail "Passive node button lacks right-click signal"
grep -q "MOUSE_BUTTON_RIGHT" scripts/ui/components/PassiveTreeNodeButton.gd || fail "Passive node button lacks right-click handling"

if grep -q "PassiveTreeSystemScript.has_method" scripts/ui/panels/PassiveAtlasPanel.gd; then
	fail "Invalid preload has_method call returned"
fi
if grep -q "self is PanelContainer\|self as PanelContainer" scripts/ui/panels/PassiveAtlasPanel.gd; then
	fail "Invalid PanelContainer cast returned"
fi

# Godot parse sanity via existing project validator when available.
if [[ -x tools/validate_all.sh ]]; then
	tools/validate_all.sh
fi

echo "[085I] OK"
