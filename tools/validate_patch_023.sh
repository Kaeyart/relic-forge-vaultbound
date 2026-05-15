#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 023 validation =="

for f in \
  scripts/hub/HubRoot.gd \
  scripts/hub/HubStation.gd \
  scenes/hub/ForgeholdHub.tscn \
  scenes/prefabs/hub/HubStationBase.tscn \
  docs/PATCH_023_HUB_STATION_SCENE_PASS.md
 do
  if [ -f "$f" ]; then
    echo "OK $f"
  else
    echo "MISSING $f"
    exit 1
  fi
 done

echo
 grep -Rni "class_name RVHubStation\|class_name RVHubRoot\|station_type\|activity_id" scripts/hub scenes/hub scenes/prefabs/hub | head -80

echo
 git diff --stat
