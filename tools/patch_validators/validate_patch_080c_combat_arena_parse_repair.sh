#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

python3 - <<'PY'
from pathlib import Path
import re
p = Path("scripts/combat/CombatArena.gd")
s = p.read_text().replace("\r\n", "\n").replace("\r", "\n")
lines = s.split("\n")
# Ignore leading blanks for check.
while lines and lines[0].strip() == "":
    lines.pop(0)
assert len(lines) >= 2, "CombatArena.gd is too short"
assert lines[0].strip() == "class_name RVCombatArena", f"Bad first line: {lines[0]!r}"
assert lines[1].strip() == "extends Node2D", f"Bad second line: {lines[1]!r}"
for i, line in enumerate(lines[2:], start=3):
    stripped = line.strip()
    if stripped == "class_name RVCombatArena":
        raise AssertionError(f"Duplicate class_name RVCombatArena at line {i}")
    if re.match(r"^extends\s+.+$", stripped) and not line.startswith(("\t", " ")):
        raise AssertionError(f"Misplaced top-level extends at line {i}: {line!r}")
print("CombatArena global class header is clean.")
PY

grep -q "class_name RVCombatArena" scripts/combat/CombatArena.gd
echo "Patch 080C CombatArena parse repair validation passed."
