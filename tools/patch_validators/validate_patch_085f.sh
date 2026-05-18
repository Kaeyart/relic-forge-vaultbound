#!/usr/bin/env bash
set -euo pipefail

cd /home/kaey/Desktop/Game

echo "Validating Patch 085F — Passive Tree Hardening"

required=(
  "scripts/data/PassiveAtlasDB.gd"
  "scripts/systems/PassiveTreeSystem.gd"
  "scripts/ui/panels/PassiveAtlasPanel.gd"
  "scripts/ui/components/PassiveTreeConnectionCanvas.gd"
  "scripts/ui/components/PassiveTreeNodeButton.gd"
  "scenes/ui/components/PassiveTreeNodeButton.tscn"
)

for f in "${required[@]}"; do
  test -f "$f" || { echo "ERROR: missing $f"; exit 1; }
done

python3 - <<'PY'
from pathlib import Path
import re, sys
errors=[]

def text(path): return Path(path).read_text()

pdb=text('scripts/data/PassiveAtlasDB.gd')
for needle in [
    'const START_NODE_ID',
    'static func nodes()',
    'static func node_by_id',
    'static func connected_ids',
    'static func node_count',
    'static func ordered_ids_for_class',
    'static func can_allocate',
]:
    if needle not in pdb:
        errors.append(f'PassiveAtlasDB missing {needle}')

pts=text('scripts/systems/PassiveTreeSystem.gd')
for needle in ['static func can_unlock', 'static func unlock_node', 'static func can_refund', 'static func refund_node', 'static func aggregate_stats']:
    if needle not in pts:
        errors.append(f'PassiveTreeSystem missing {needle}')
if 'for node: Dictionary in PassiveDBScript.nodes()' in text('scripts/ui/components/PassiveTreeConnectionCanvas.gd'):
    errors.append('Connection canvas still has typed Dictionary loop over PassiveDBScript.nodes()')

panel=text('scripts/ui/panels/PassiveAtlasPanel.gd')
if 'preload("res://scenes/ui/components/PassiveTreeNodeButton.tscn")' not in panel:
    errors.append('PassiveAtlasPanel does not preload node button scene')
if 'PassiveTreeSystemScript.unlock_node' not in panel:
    errors.append('PassiveAtlasPanel does not call PassiveTreeSystem.unlock_node')

gs=text('scripts/core/GameState.gd')
for varname in ['unlocked_passive_nodes', 'passive_stat_bonuses', 'passive_rules']:
    if gs.count(f'var {varname}:') != 1:
        errors.append(f'GameState should declare {varname} exactly once, found {gs.count(f"var {varname}:")}')
if 'RVPassiveTreeSystem.ensure_defaults(self)' not in gs:
    errors.append('GameState.ensure_defaults does not call RVPassiveTreeSystem.ensure_defaults(self)')

# Basic duplicate header guard for changed files.
for f in ['scripts/data/PassiveAtlasDB.gd','scripts/systems/PassiveTreeSystem.gd','scripts/ui/panels/PassiveAtlasPanel.gd','scripts/ui/components/PassiveTreeConnectionCanvas.gd','scripts/ui/components/PassiveTreeNodeButton.gd']:
    s=text(f)
    class_names=re.findall(r'^class_name\s+', s, re.M)
    extends=re.findall(r'^extends\s+', s, re.M)
    if len(class_names)!=1:
        errors.append(f'{f} has {len(class_names)} class_name declarations')
    if len(extends)!=1:
        errors.append(f'{f} has {len(extends)} extends declarations')

if errors:
    print('\n'.join('ERROR: '+e for e in errors))
    sys.exit(1)
print('Patch 085F validation passed.')
PY
