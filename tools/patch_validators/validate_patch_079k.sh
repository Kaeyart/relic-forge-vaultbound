#!/usr/bin/env bash
set -euo pipefail

if [ ! -f "project.godot" ]; then
  echo "ERROR: Run validator from the Godot project root."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
import re

p = Path("scripts/core/GameRoot.gd")
if not p.exists():
    raise SystemExit("ERROR: missing scripts/core/GameRoot.gd")

s = p.read_text()
count = len(re.findall(r"(?m)^func\s+_clear_active_map_portal\s*\(", s))
if count != 1:
    raise SystemExit(f"ERROR: expected exactly one _clear_active_map_portal(), found {count}")

combat = Path("scripts/combat/CombatArena.gd")
if combat.exists() and "runtime_map_camera.clear_current()" in combat.read_text():
    raise SystemExit("ERROR: invalid Camera2D.clear_current() call still present in CombatArena.gd")

print("Patch 079K validation passed.")
PY
