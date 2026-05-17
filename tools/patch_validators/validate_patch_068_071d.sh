#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 068-071D =="
FILE="scripts/combat/EnemyActor.gd"
test -f "$FILE"

for needle in \
  "var aggro_range" \
  "var attack_range" \
  "var windup" \
  "var recovery" \
  "var ai_timer" \
  "var pack_id" \
  "var encounter_role" \
  "var encounter_pack_type"; do
  if ! grep -q "$needle" "$FILE"; then
    echo "Missing required field: $needle"
    exit 1
  fi
done

python3 - <<'PY'
from pathlib import Path
text = Path('/home/kaey/Desktop/Game/scripts/combat/EnemyActor.gd').read_text()
for name in ['aggro_range','attack_range','windup','recovery','ai_timer','pack_id','encounter_role','encounter_pack_type']:
    count = text.count('var ' + name)
    if count > 1:
        raise SystemExit(f'Duplicate class var candidate found for {name}: {count}')
print('EnemyActor required fields present with no obvious duplicates.')
PY

echo "Patch 068-071D validation passed."
