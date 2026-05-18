#!/usr/bin/env bash
set -euo pipefail

TARGET="scripts/ui/hud/FlaskHUD.gd"

if [ ! -f "$TARGET" ]; then
  echo "[082B validator] ERROR: Missing $TARGET" >&2
  exit 1
fi

if grep -nE '^func[[:space:]]+_get[[:space:]]*\(' "$TARGET" >/tmp/082b_flaskhud_get_hits.txt; then
  echo "[082B validator] ERROR: FlaskHUD.gd still declares func _get(...), which conflicts with Godot Object._get." >&2
  cat /tmp/082b_flaskhud_get_hits.txt >&2
  exit 1
fi

if grep -nE '(^|[^A-Za-z0-9_\.])_get[[:space:]]*\([[:space:]]*state[[:space:]]*,' "$TARGET" >/tmp/082b_flaskhud_call_hits.txt; then
  echo "[082B validator] ERROR: FlaskHUD.gd still calls the old _get(state, ...) helper." >&2
  cat /tmp/082b_flaskhud_call_hits.txt >&2
  exit 1
fi

if ! grep -nE '^func[[:space:]]+_state_get[[:space:]]*\(' "$TARGET" >/dev/null; then
  echo "[082B validator] ERROR: FlaskHUD.gd does not define _state_get(...)." >&2
  exit 1
fi

echo "[082B validator] OK: FlaskHUD helper renamed to _state_get."
