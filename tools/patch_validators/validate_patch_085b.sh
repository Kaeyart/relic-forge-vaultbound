#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
FILE="scripts/data/PassiveAtlasDB.gd"
[ -f "$FILE" ] || { echo "Missing $FILE"; exit 1; }
grep -q "class_name RVPassiveAtlasDB" "$FILE" || { echo "Missing RVPassiveAtlasDB class_name"; exit 1; }
grep -q "static func ordered_ids_for_class" "$FILE" || { echo "Missing ordered_ids_for_class"; exit 1; }
grep -q "static func can_allocate" "$FILE" || { echo "Missing can_allocate"; exit 1; }
grep -q "static func node" "$FILE" || { echo "Missing node"; exit 1; }
grep -q "start_sorceress" "$FILE" || { echo "Missing sorceress start node"; exit 1; }
grep -q "fire_keystone_01" "$FILE" || { echo "Missing keystone content"; exit 1; }
if grep -R "Camera2D.clear_current" -n scripts >/tmp/rv_clear_current_hits.txt; then
  cat /tmp/rv_clear_current_hits.txt
  echo "Invalid Camera2D.clear_current call remains"
  exit 1
fi
printf 'Patch 085B validation passed.\n'
