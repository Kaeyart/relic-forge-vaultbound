#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
fail=0
check_file() { [ -f "$1" ] || { echo "Missing: $1"; fail=1; }; }
check_grep() { grep -q "$2" "$1" || { echo "Missing pattern $2 in $1"; fail=1; }; }
check_file scripts/data/MapDB.gd
check_file scripts/systems/MapSystem.gd
check_file scripts/ui/panels/MapDevicePanel.gd
check_file scenes/ui/panels/MapDevicePanel.tscn
check_file scenes/prefabs/hub/MapDeviceStation.tscn
check_file assets/hub/stations/station_map_device.svg
check_grep scripts/hub/HubStation.gd 'map_device'
check_grep scripts/hub/HubRoot.gd 'toggle_panel("map_device")'
check_grep scripts/core/GameRoot.gd 'RVMapSystem.handle_panel_key'
check_grep scripts/core/GameRoot.gd '_consume_pending_map_activity'
check_grep scenes/hub/ForgeholdHub.tscn 'station_id = "map_device"'
check_grep scripts/systems/MapSystem.gd 'prepare_selected_map_activity'
check_grep scripts/systems/MapSystem.gd 'award_map_boss_loot'
if [ "$fail" -ne 0 ]; then echo "Patch 057 validation failed."; exit 1; fi
echo "Patch 057 validation passed."
