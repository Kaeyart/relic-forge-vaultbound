#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/visuals/MapDeviceArtSkin.gd
grep -q "class_name RVMapDeviceArtSkin" scripts/visuals/MapDeviceArtSkin.gd

test -f assets/ui/map_device/map_card_frame_common.png
test -f assets/ui/map_device/map_slot_empty.png
test -f assets/ui/buttons/button_activate_idle.png
test -f assets/ui/buttons/stash_tab_button_selected.png
test -f assets/items/maps/map_icon_ash_cistern.png
test -f assets/items/maps/map_icon_ossuary.png
test -f assets/ui/rewards/reward_icon_currency.png
test -f assets/_source_sheets/map_art_pass_076a/SLICE_MANIFEST.json

grep -q "RVMapDeviceArtSkin.ensure_skin(self)" scripts/ui/panels/MapDevicePanel.gd
grep -q "RVMapDeviceArtSkin.render_empty(self)" scripts/ui/panels/MapDevicePanel.gd
grep -q "RVMapDeviceArtSkin.render_map(self, map_item" scripts/ui/panels/MapDevicePanel.gd

echo "Patch 076A art integration validation passed."
