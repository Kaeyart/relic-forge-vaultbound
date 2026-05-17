#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo '== Validate Patch 072C =='
python3 - <<'PY'
from pathlib import Path
import re, sys
path = Path('scripts/combat/CombatArena.gd')
if not path.exists():
    print('ERROR: missing scripts/combat/CombatArena.gd')
    sys.exit(1)
text = path.read_text(encoding='utf-8')
funcs = re.findall(r'^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', text, flags=re.M)
seen = set()
dups = []
for name in funcs:
    if name in seen:
        dups.append(name)
    else:
        seen.add(name)
if dups:
    print('ERROR: duplicate top-level functions remain:', sorted(set(dups)))
    sys.exit(1)
required = [
    '_rf_feedback_root',
    '_rf_ensure_combat_layers',
    '_rf_update_ground_loot',
    '_rf_spawn_damage_number',
    '_rf_drop_enemy_loot',
]
missing = [name for name in required if not re.search(r'^func\s+' + re.escape(name) + r'\s*\(', text, flags=re.M)]
if missing:
    print('WARNING: expected Patch 072 helper functions not found:', missing)
    print('This may be okay if the current CombatArena uses different helper names, but Godot should be reopened and checked.')
else:
    print('Required Patch 072 helper functions present.')
print('No duplicate top-level functions in CombatArena.gd.')
PY

echo 'Validation complete. Reopen Godot to force script reparse.'
