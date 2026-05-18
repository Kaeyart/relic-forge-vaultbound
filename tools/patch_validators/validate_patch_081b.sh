#!/usr/bin/env bash
set -euo pipefail
cd "${PROJECT_ROOT:-/home/kaey/Desktop/Game}"
FILE="scripts/core/GameState.gd"
for name in active_map_portal_activity active_map_portal_entries active_map_portal_max_entries active_map_portals_remaining; do
  count=$(grep -cE "^var[[:space:]]+$name[[:space:]]*:" "$FILE" || true)
  if [[ "$count" != "1" ]]; then
    echo "ERROR: Expected exactly one declaration for $name, found $count" >&2
    exit 1
  fi
done
if ! grep -q "active_map_portal_entries = clampi" "$FILE"; then
  echo "ERROR: active_map_portal_entries ensure_defaults sync missing" >&2
  exit 1
fi
echo "Patch 081B validator passed."
