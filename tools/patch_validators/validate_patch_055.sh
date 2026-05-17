#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
SCRIPT="scripts/ui/panels/SkillGemsPanel.gd"
[ -f "$SCRIPT" ] || { echo "Missing $SCRIPT" >&2; exit 1; }
python3 - <<'PY'
from pathlib import Path
p = Path('scripts/ui/panels/SkillGemsPanel.gd')
text = p.read_text()
start = text.find('func _refresh_socket_buttons() -> void:')
end = text.find('\nfunc ', start + 1)
if start == -1 or end == -1:
    raise SystemExit('FAIL: _refresh_socket_buttons() not found or malformed')
block = text[start:end]
bad = ['button.icon = socket_empty_texture', 'button.icon = socket_filled_texture', 'button.icon = socket_locked_texture']
for b in bad:
    if b in block:
        raise SystemExit(f'FAIL: runtime socket icon assignment still present: {b}')
required = ['button.icon = null', 'button.text = ""', 'button.flat = true', 'transparent click/drop targets']
for r in required:
    if r not in block:
        raise SystemExit(f'FAIL: expected marker missing: {r}')
print('PASS: SkillGemsPanel socket buttons are scene-authored click targets now.')
PY
