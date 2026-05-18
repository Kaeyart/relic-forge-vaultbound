#!/usr/bin/env bash
set -euo pipefail

fail=0

require_func() {
  local file="$1"
  local func="$2"
  if ! grep -q "^func ${func}(" "$file"; then
    echo "ERROR: missing ${func} in ${file}"
    fail=1
  else
    local count
    count="$(grep -c "^func ${func}(" "$file")"
    if [ "$count" -ne 1 ]; then
      echo "ERROR: expected exactly one ${func} in ${file}, found ${count}"
      fail=1
    fi
  fi
}

require_func scripts/core/GameRoot.gd _rf_081a_portal_to_hub
require_func scripts/core/GameRoot.gd _rf_081a_reenter_active_map_portal
require_func scripts/core/GameRoot.gd _rf_081a_clear_active_map_portal
require_func scripts/core/GameRoot.gd _rf_081a_capture_active_map_instance
require_func scripts/combat/CombatArena.gd capture_map_instance_snapshot
require_func scripts/combat/CombatArena.gd restore_map_instance_snapshot

if grep -q "clear_current()" scripts/combat/CombatArena.gd; then
  echo "ERROR: Camera2D.clear_current() still exists in CombatArena.gd"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "OK: Patch 081C helpers and snapshot methods are installed."
