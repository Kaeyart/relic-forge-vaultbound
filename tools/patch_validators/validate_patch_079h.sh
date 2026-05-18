#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

grep -q "func _rf_has_combat_los" scripts/combat/CombatArena.gd
grep -q "func _rf_combat_los_hit_allowed" scripts/combat/CombatArena.gd
grep -q "func _rf_constrain_entity_movement" scripts/combat/CombatArena.gd
python3 - <<'PY'
from pathlib import Path
s = Path('scripts/combat/CombatArena.gd').read_text()
assert s.count('class_name RVCombatArena') == 1, 'CombatArena has duplicate class_name RVCombatArena'
# Only count top-level extends lines.
extends_lines = [line for line in s.splitlines() if line.strip().startswith('extends ')]
assert len(extends_lines) == 1 and extends_lines[0].strip() == 'extends Node2D', f'Bad extends lines: {extends_lines}'
PY

echo "Patch 079H validation passed."
