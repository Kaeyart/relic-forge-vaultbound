#!/usr/bin/env bash
set -euo pipefail

cd /home/kaey/Desktop/Game

echo "== Validate Patch 068-071A =="

if [ ! -f scripts/combat/EnemyActor.gd ]; then
  echo "FAIL: scripts/combat/EnemyActor.gd missing"
  exit 1
fi

grep -q "class_name RVEnemyActor" scripts/combat/EnemyActor.gd || {
  echo "FAIL: EnemyActor.gd missing class_name RVEnemyActor"
  exit 1
}

grep -q 'var pack_id: String = ""' scripts/combat/EnemyActor.gd || {
  echo "FAIL: EnemyActor.gd missing pack_id compatibility field"
  exit 1
}

python3 - <<'PY'
from pathlib import Path
import re, sys

path = Path("scripts/combat/EnemyActor.gd")
lines = path.read_text(encoding="utf-8").splitlines()

prefixes = ("if ", "elif ", "else:", "for ", "while ", "match ", "func ", "static func ")

def indent_width(s):
    w=0
    for ch in s:
        if ch == "\t": w += 4
        elif ch == " ": w += 1
        else: break
    return w

bad = []
for i, line in enumerate(lines):
    stripped = line.strip()
    if not stripped.endswith(":"):
        continue
    if not any(stripped.startswith(p) for p in prefixes):
        continue
    cur = indent_width(line)
    j = i + 1
    nxt = None
    while j < len(lines):
        s = lines[j].strip()
        if s == "" or s.startswith("#"):
            j += 1
            continue
        nxt = lines[j]
        break
    if nxt is None or indent_width(nxt) <= cur:
        bad.append(i + 1)

if bad:
    print("FAIL: possible empty executable blocks still present at lines:", bad[:20])
    sys.exit(1)
print("OK: no obvious empty executable GDScript blocks in EnemyActor.gd")
PY

echo "Patch 068-071A validation passed."
