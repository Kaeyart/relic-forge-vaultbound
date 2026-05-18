#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
python3 - <<'PY'
from pathlib import Path
import re
s = Path('scripts/core/GameState.gd').read_text()
required = [
    'var active_map_portal_activity: Dictionary',
    'var active_map_portal_entries: int',
    'var active_map_portal_max_entries: int',
    'var active_map_portals_remaining: int',
    'func _sync_active_map_portal_state() -> void:',
]
missing = [x for x in required if x not in s]
if missing:
    raise SystemExit('Patch 079L validation failed. Missing: ' + ', '.join(missing))
for name in ['active_map_portal_entries', 'active_map_portal_max_entries', 'active_map_portal_activity']:
    if not re.search(r'^\s*var\s+' + name + r'\b', s, re.M):
        raise SystemExit(f'{name} is not declared')
print('Patch 079L validator OK')
PY
