#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
required=(
  scripts/core/GameState.gd
  scripts/core/SaveSystem.gd
  scripts/data/ClassDB.gd
  scripts/data/AscendancyDB.gd
  scripts/data/PassiveAtlasDB.gd
  scripts/systems/ClassAscendancySystem.gd
  scripts/systems/BuildcraftSystem.gd
  scripts/ui/panels/PassiveAtlasPanel.gd
)
for f in "${required[@]}"; do
  test -f "$f" || { echo "MISSING: $f"; exit 1; }
done
python3 - <<'PY'
from pathlib import Path
for f in [
 'scripts/core/GameState.gd',
 'scripts/core/SaveSystem.gd',
 'scripts/data/ClassDB.gd',
 'scripts/data/AscendancyDB.gd',
 'scripts/data/PassiveAtlasDB.gd',
 'scripts/systems/ClassAscendancySystem.gd',
 'scripts/systems/BuildcraftSystem.gd',
 'scripts/ui/panels/PassiveAtlasPanel.gd',
]:
    text=Path(f).read_text()
    if ' return var ' in text or ' static func ' in text and text.count('\n') < 3:
        print('Suspicious compressed syntax:', f)
        raise SystemExit(1)
print('Patch 074 file sanity checks passed.')
PY
