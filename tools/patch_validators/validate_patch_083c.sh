#!/usr/bin/env bash
set -euo pipefail

fail() { echo "ERROR: $1" >&2; exit 1; }

[ -f scripts/systems/CombatRootSystem.gd ] || fail "Missing CombatRootSystem.gd"
[ -f scripts/systems/MapInstancePersistenceSystem.gd ] || fail "Missing MapInstancePersistenceSystem.gd"
[ -f scripts/systems/CombatProjectileCollisionSystem.gd ] || fail "Missing CombatProjectileCollisionSystem.gd"
[ -f scripts/systems/CombatRewardExitSystem.gd ] || fail "Missing CombatRewardExitSystem.gd"
[ -f scripts/combat/CombatArena.gd ] || fail "Missing CombatArena.gd"

grep -q "class_name RVCombatRootSystem" scripts/systems/CombatRootSystem.gd || fail "CombatRootSystem missing class_name"
grep -q "class_name RVMapInstancePersistenceSystem" scripts/systems/MapInstancePersistenceSystem.gd || fail "MapInstancePersistenceSystem missing class_name"
grep -q "class_name RVCombatProjectileCollisionSystem" scripts/systems/CombatProjectileCollisionSystem.gd || fail "CombatProjectileCollisionSystem missing class_name"
grep -q "class_name RVCombatRewardExitSystem" scripts/systems/CombatRewardExitSystem.gd || fail "CombatRewardExitSystem missing class_name"

grep -q "CombatRootSystemScript" scripts/combat/CombatArena.gd || fail "CombatArena does not preload/use CombatRootSystemScript"
grep -q "func _rf_safe_children(root: Variant)" scripts/combat/CombatArena.gd || fail "CombatArena _rf_safe_children must accept Variant"
grep -q "CombatRootSystemScript.safe_children" scripts/combat/CombatArena.gd || fail "CombatArena _rf_safe_children does not delegate"
grep -q "CombatRootSystemScript.clear_children" scripts/combat/CombatArena.gd || fail "CombatArena _clear_children does not delegate"
grep -q "CombatRootSystemScript.live_node2d" scripts/combat/CombatArena.gd || fail "CombatArena _rf_live_node2d does not delegate"

python3 - <<'PY'
from pathlib import Path
import re, sys
p = Path('scripts/combat/CombatArena.gd')
s = p.read_text()
errors = []
if s.count('class_name RVCombatArena') != 1:
    errors.append('CombatArena has duplicate/missing class_name RVCombatArena')
if len(re.findall(r'^extends\s+', s, re.M)) != 1:
    errors.append('CombatArena has duplicate/missing extends line')
if 'Camera2D.clear_current' in s or '.clear_current()' in s:
    errors.append('CombatArena still calls Camera2D.clear_current()')
if re.search(r'projectiles_root\.add_child\s*\(', s):
    errors.append('Unsafe projectiles_root.add_child remains')
if re.search(r'enemies_root\.add_child\s*\(', s):
    errors.append('Unsafe enemies_root.add_child remains')
if re.search(r'func\s+_get\s*\([^\n]*state\s*:', s):
    errors.append('Custom _get(state, ...) helper found')
for name in ['_rf_live_node2d','_rf_named_node2d','_rf_ensure_combat_layers','_rf_loot_root','_clear_children','_rf_safe_children','_rf_child_count']:
    if len(re.findall(r'^func\s+'+re.escape(name)+r'\s*\(', s, re.M)) != 1:
        errors.append(f'Expected exactly one {name} function')
if errors:
    for e in errors:
        print('ERROR:', e, file=sys.stderr)
    sys.exit(1)
print('Patch 083C validation passed')
PY
