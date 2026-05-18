#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

fail() {
  echo "[084A][FAIL] $1" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "Missing required file: $1"
}

require_file scripts/systems/ProgressionRewardSystem.gd
require_file scripts/systems/LootDropSystem.gd
require_file docs/patch_notes/PATCH_084A_DROP_ECONOMY_TUNING.md

python3 - <<'PY'
from pathlib import Path
import re, sys

checks = []
progression = Path('scripts/systems/ProgressionRewardSystem.gd').read_text()
loot = Path('scripts/systems/LootDropSystem.gd').read_text()

errors = []

def check(cond, msg):
    if not cond:
        errors.append(msg)

check('class_name RVProgressionRewardSystem' in progression, 'ProgressionRewardSystem missing class_name')
check('static func award_enemy_kill' in progression, 'ProgressionRewardSystem missing award_enemy_kill')
check('static func ensure_defaults' in progression, 'ProgressionRewardSystem missing ensure_defaults')
check('static func _get(' not in progression, 'ProgressionRewardSystem defines forbidden _get helper')
check('func _get(' not in progression, 'ProgressionRewardSystem defines forbidden _get helper')
check('class_name RVLootDropSystem' in loot, 'LootDropSystem missing class_name')
check('static func enemy_drop_payloads' in loot, 'LootDropSystem missing enemy_drop_payloads')
check('static func pickup_payload' in loot, 'LootDropSystem missing pickup_payload')
check('static func roll_equipment_drop' in loot, 'LootDropSystem missing roll_equipment_drop')
check('static func roll_skill_gem_drop' in loot, 'LootDropSystem missing roll_skill_gem_drop')
check('static func roll_map_drop' in loot, 'LootDropSystem missing roll_map_drop')
check('flask_upgrade' in loot, 'LootDropSystem missing flask upgrade drop path')
check('static func _get(' not in loot, 'LootDropSystem defines forbidden _get helper')
check('func _get(' not in loot, 'LootDropSystem defines forbidden _get helper')
check('Camera2D.clear_current' not in ''.join(p.read_text(errors='ignore') for p in Path('scripts').rglob('*.gd')), 'Invalid Camera2D.clear_current() call still present')
check('projectiles_root.add_child' not in Path('scripts/combat/CombatArena.gd').read_text(errors='ignore'), 'Unsafe projectiles_root.add_child still present')
check('enemies_root.add_child' not in Path('scripts/combat/CombatArena.gd').read_text(errors='ignore'), 'Unsafe enemies_root.add_child still present')

# Validate no duplicate function names in the two rewritten systems.
for path in [Path('scripts/systems/ProgressionRewardSystem.gd'), Path('scripts/systems/LootDropSystem.gd')]:
    text = path.read_text()
    names = re.findall(r'^\s*(?:static\s+)?func\s+([A-Za-z0-9_]+)\s*\(', text, re.M)
    dupes = sorted({n for n in names if names.count(n) > 1})
    check(not dupes, f'{path} has duplicate function declarations: {dupes}')

if errors:
    for e in errors:
        print('[084A][FAIL]', e)
    sys.exit(1)
print('[084A] Drop economy/progression sanity checks passed')
PY

if [[ -x tools/maintenance/audit_systems_083a.py ]]; then
  python3 tools/maintenance/audit_systems_083a.py --write || true
fi

echo "[084A] validator complete"
