#!/usr/bin/env bash
set -euo pipefail

fail() { echo "ERROR: $1" >&2; exit 1; }

[ -f scripts/systems/MapInstancePersistenceSystem.gd ] || fail "missing MapInstancePersistenceSystem.gd"
[ -f scripts/systems/CombatRootSystem.gd ] || fail "missing CombatRootSystem.gd"

grep -q '^class_name RVMapInstancePersistenceSystem' scripts/systems/MapInstancePersistenceSystem.gd || fail "MapInstancePersistenceSystem missing class_name"
grep -q '^class_name RVCombatRootSystem' scripts/systems/CombatRootSystem.gd || fail "CombatRootSystem missing class_name"
grep -q '^extends RefCounted' scripts/systems/MapInstancePersistenceSystem.gd || fail "MapInstancePersistenceSystem must extend RefCounted"
grep -q '^extends RefCounted' scripts/systems/CombatRootSystem.gd || fail "CombatRootSystem must extend RefCounted"

if grep -q 'func _get' scripts/systems/MapInstancePersistenceSystem.gd; then
  fail "MapInstancePersistenceSystem still declares _get(), which conflicts with Object._get"
fi
if grep -q 'RVCombatRootSystem\.' scripts/systems/MapInstancePersistenceSystem.gd; then
  fail "MapInstancePersistenceSystem still directly references RVCombatRootSystem; use preload alias"
fi
grep -q 'CombatRootSystemScript := preload' scripts/systems/MapInstancePersistenceSystem.gd || fail "MapInstancePersistenceSystem missing CombatRootSystemScript preload"
grep -q 'CombatRootSystemScript.safe_children' scripts/systems/MapInstancePersistenceSystem.gd || fail "MapInstancePersistenceSystem not using preload alias safe_children"

if grep -q 'Camera2D.clear_current' scripts/combat/CombatArena.gd; then
  fail "CombatArena still references Camera2D.clear_current()"
fi

if command -v python3 >/dev/null 2>&1; then
python3 - <<'PY'
from pathlib import Path
for path in [Path('scripts/systems/MapInstancePersistenceSystem.gd'), Path('scripts/systems/CombatRootSystem.gd')]:
    text = path.read_text()
    if text.count('class_name ') != 1:
        raise SystemExit(f"ERROR: {path} has duplicate class_name declarations")
    if text.count('extends RefCounted') != 1:
        raise SystemExit(f"ERROR: {path} has duplicate/missing extends RefCounted")
print('Patch 083D validator passed')
PY
fi
