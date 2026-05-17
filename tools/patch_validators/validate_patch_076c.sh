#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scenes/ui/panels/MapDevicePanel.tscn
test -f scripts/ui/panels/MapDevicePanel.gd

grep -q 'visible = false' scenes/ui/panels/MapDevicePanel.tscn
grep -q 'self_modulate = Color(1, 1, 1, 0.82)' scenes/ui/panels/MapDevicePanel.tscn
grep -q '_set_visible(map_card_frame_art, false)' scripts/ui/panels/MapDevicePanel.gd
grep -q '_set_visible(map_card_frame_art, true)' scripts/ui/panels/MapDevicePanel.gd

echo "Patch 076C validation passed."
