#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

python3 - <<'PY'
from pathlib import Path
import re

p = Path("scripts/core/GameRoot.gd")
s = p.read_text()

required = [
    "Patch 085U: hard movement restore",
    "func _rf_085u_gameplay_input_allowed()",
    "func _rf_085u_repair_input_state()",
    "func _rf_085u_emergency_unlock()",
    "KEY_F8",
    "constrain_player_movement",
]
missing = [x for x in required if x not in s]
if missing:
    raise SystemExit("Patch 085U missing markers: " + ", ".join(missing))

if 'if state.panel_mode != "":\n\t\tplayer.sync_from_state(state)\n\t\treturn' in s:
    raise SystemExit("Old hard panel_mode movement lock still exists in GameRoot.gd")

if re.search(r'mouse_filter\s*=', s):
    raise SystemExit("GameRoot.gd still has raw mouse_filter assignment")

print("Patch 085U validator passed.")
PY
