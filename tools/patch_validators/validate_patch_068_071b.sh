#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 068-071B =="
[ -f scripts/combat/EnemyActor.gd ] || { echo "Missing EnemyActor.gd"; exit 1; }
[ -f scripts/combat/CombatArena.gd ] || { echo "Missing CombatArena.gd"; exit 1; }

grep -q "class_name RVEnemyActor" scripts/combat/EnemyActor.gd || { echo "EnemyActor.gd missing class_name RVEnemyActor"; exit 1; }
grep -q "var pack_id: String" scripts/combat/EnemyActor.gd || { echo "EnemyActor.gd missing pack_id field"; exit 1; }
grep -q "signal projectile_requested" scripts/combat/EnemyActor.gd || { echo "EnemyActor.gd missing projectile_requested signal"; exit 1; }
grep -q "func _chain_lightning" scripts/combat/CombatArena.gd || { echo "CombatArena.gd missing _chain_lightning"; exit 1; }

python3 - <<'PY'
from pathlib import Path
p = Path('scripts/combat/EnemyActor.gd')
lines = p.read_text().splitlines()
block_prefixes = ('if ', 'elif ', 'else:', 'for ', 'while ', 'match ', 'func ', 'class ')
def indent(s): return len(s) - len(s.lstrip(' \t'))
def is_block(s):
    t=s.strip()
    return t.endswith(':') and (t.startswith('else:') or any(t.startswith(x) for x in block_prefixes if x!='else:'))
errors=[]
for i,line in enumerate(lines):
    if not is_block(line): continue
    cur=indent(line)
    j=i+1
    while j<len(lines) and (lines[j].strip()=='' or lines[j].lstrip().startswith('#')): j+=1
    if j>=len(lines) or indent(lines[j])<=cur:
        errors.append((i+1,line))
if errors:
    print('Empty block candidates remain:')
    for n,l in errors[:20]: print(n, l)
    raise SystemExit(1)
print('EnemyActor.gd empty-block scan OK')
PY

echo "Validation OK. Reopen Godot."
