#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

python3 - <<'PY'
from pathlib import Path
import re, sys
p = Path('scripts/data/PassiveAtlasDB.gd')
s = p.read_text()
errors = []
for fn in ['node_by_id', 'connected_ids', 'node_count', 'node', 'ordered_ids_for_class', 'can_allocate']:
    if re.search(r'^static\s+func\s+' + re.escape(fn) + r'\s*\(', s, flags=re.M) is None:
        errors.append(f'Missing RVPassiveAtlasDB.{fn}()')
if s.count('class_name RVPassiveAtlasDB') != 1:
    errors.append('PassiveAtlasDB has duplicate/missing class_name header')
if 'START_NODE_ID' not in s:
    errors.append('PassiveAtlasDB missing START_NODE_ID compatibility constant')
if errors:
    for e in errors:
        print('ERROR:', e)
    sys.exit(1)
print('Patch 085D validator passed')
PY
