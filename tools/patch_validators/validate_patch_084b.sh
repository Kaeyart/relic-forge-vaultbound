#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

if grep -n "int(_state_get\|int(_obj_get\|int(gem.get\|int(map_item.get" scripts/systems/ProgressionRewardSystem.gd >/tmp/rv084b_bad_int.txt; then
  echo "ERROR: fragile int(...) conversion remains in ProgressionRewardSystem.gd"
  cat /tmp/rv084b_bad_int.txt
  exit 1
fi
if grep -n "set_script(load(" scripts/systems/CombatFeedbackSystem.gd >/tmp/rv084b_bad_setscript.txt; then
  echo "ERROR: unguarded set_script(load(...)) remains in CombatFeedbackSystem.gd"
  cat /tmp/rv084b_bad_setscript.txt
  exit 1
fi
if ! grep -q "func _as_int" scripts/systems/ProgressionRewardSystem.gd; then
  echo "ERROR: ProgressionRewardSystem.gd missing _as_int helper"
  exit 1
fi

echo "Patch 084B validator passed."
