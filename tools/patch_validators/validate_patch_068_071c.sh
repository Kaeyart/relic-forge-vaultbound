#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 068-071C =="
FILE="scripts/combat/EnemyActor.gd"
[[ -f "$FILE" ]] || { echo "Missing $FILE"; exit 1; }

for token in "var aggro_range" "var attack_range" "var windup" "var recovery" "func _apply_combat_role_tuning"; do
  grep -q "$token" "$FILE" || { echo "Missing token: $token"; exit 1; }
done

python3 - <<'PY'
from pathlib import Path
text = Path('scripts/combat/EnemyActor.gd').read_text().splitlines()
for i,l in enumerate(text, start=1):
    if 'if ' in l and l.rstrip().endswith(':'):
        # Best-effort empty-block detector; not full parser.
        indent = len(l) - len(l.lstrip('\t '))
        j = i
        while j < len(text) and text[j].strip() == '':
            j += 1
        if j < len(text):
            nxt = text[j]
            nindent = len(nxt) - len(nxt.lstrip('\t '))
            if nindent <= indent and not nxt.lstrip().startswith(('elif ', 'else:')):
                raise SystemExit(f'Possible empty if block around line {i}')
print('EnemyActor role fields present; no obvious empty if blocks.')
PY

echo "OK"
