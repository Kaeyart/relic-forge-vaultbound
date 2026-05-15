#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
SCRIPT="scripts/ui/panels/InventoryPanel.gd"
grep -q "func _input(event: InputEvent)" "$SCRIPT"
grep -q "func _cancel_drag" "$SCRIPT"
grep -q "Item returned to backpack" "$SCRIPT"
grep -q "mouse_filter = Control.MOUSE_FILTER_IGNORE" "$SCRIPT"
echo "Patch 035D validation passed."
