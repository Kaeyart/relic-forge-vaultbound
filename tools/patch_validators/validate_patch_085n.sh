#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

python3 - <<'PY'
from pathlib import Path
s = Path('scripts/core/GameRoot.gd').read_text()
assert 'func _rf_restore_gameplay_input_after_load()' in s, 'missing GameRoot transient input repair helper'
assert 'func _rf_update_ui_input_ownership()' in s, 'missing GameRoot UI input ownership helper'
assert 'KEY_F8' in s, 'missing F8 emergency input unlock'
assert 'flask_hud' not in s, 'stale flask_hud reference remains in GameRoot.gd'
assert 'loot_filter_panel' not in s, 'stale loot_filter_panel reference remains in GameRoot.gd'

u = Path('scripts/ui/UIPanelRoot.gd').read_text()
assert '_rf_085n_sync_input_ownership' in u, 'missing UIPanelRoot input ownership guard'
print('Patch 085N validation passed')
PY
