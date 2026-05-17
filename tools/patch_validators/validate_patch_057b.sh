#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 057B =="

test -f scripts/hub/HubRoot.gd
test -f scripts/hub/HubStation.gd
test -f scripts/systems/MapSystem.gd
test -f scripts/data/MapDB.gd

grep -q 'map_device' scripts/hub/HubStation.gd
grep -q 'state.toggle_panel("map_device")' scripts/hub/HubRoot.gd
grep -q 'Station not wired yet:' scripts/hub/HubRoot.gd

echo "Hub Map Device wiring checks passed."
