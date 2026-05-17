#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
if grep -n 'panels.update_from_state(state).*_consume_pending_map_activity' scripts/core/GameRoot.gd; then
  echo "ERROR: compressed GameRoot map activity line still exists"
  exit 1
fi
if ! grep -q '_consume_pending_map_activity' scripts/core/GameRoot.gd; then
  echo "ERROR: _consume_pending_map_activity call missing from GameRoot.gd"
  exit 1
fi
echo "Patch 057A validation passed."
