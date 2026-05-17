#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scenes/ui/panels/MapDevicePanel.tscn
test -f scripts/ui/panels/MapDevicePanel.gd
test -f assets/ui/map_device/map_device_panel_frame.png
test -f assets/ui/map_device/map_card_frame_common.png
test -f assets/ui/map_device/map_slot_empty.png
test -f assets/items/maps/map_icon_ash_cistern.png
test -f assets/ui/rewards/reward_icon_currency.png

grep -q 'MainFrameArt' scenes/ui/panels/MapDevicePanel.tscn
grep -q 'MapCardFrameArt' scenes/ui/panels/MapDevicePanel.tscn
grep -q 'MapSlotEmptyArt' scenes/ui/panels/MapDevicePanel.tscn
grep -q 'MapIconArt' scenes/ui/panels/MapDevicePanel.tscn
grep -q 'CompletedBadgeArt' scenes/ui/panels/MapDevicePanel.tscn
grep -q 'theme_override_styles/normal = SubResource("StyleBoxTexture_activate_idle")' scenes/ui/panels/MapDevicePanel.tscn

grep -q '@export var card_frame_common' scripts/ui/panels/MapDevicePanel.gd
grep -q 'func _map_icon_for' scripts/ui/panels/MapDevicePanel.gd

if grep -R "MapDeviceArtSkin" scenes/ui/panels/MapDevicePanel.tscn scripts/ui/panels/MapDevicePanel.gd 2>/dev/null; then
  echo "MapDeviceArtSkin is still referenced by the Map Device panel; 076B should be scene-authored." >&2
  exit 1
fi

echo "Patch 076B validation passed."
