#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ ! -f tools/maintenance/audit_systems_083a.py ]; then
  echo "[083A] Missing tools/maintenance/audit_systems_083a.py" >&2
  exit 1
fi

python3 tools/maintenance/audit_systems_083a.py --strict --write-doc docs/SYSTEMS_STATUS.md

if [ ! -f docs/SYSTEMS_STATUS.md ]; then
  echo "[083A] Missing docs/SYSTEMS_STATUS.md" >&2
  exit 1
fi

if grep -R "RVMapDeviceArtSkin" -n scripts scenes 2>/dev/null; then
  echo "[083A] Stale RVMapDeviceArtSkin reference found." >&2
  exit 1
fi

if grep -R "\.clear_current()" -n scripts scenes 2>/dev/null; then
  echo "[083A] Invalid clear_current() call found." >&2
  exit 1
fi

if grep -R "func _get(state:" -n scripts 2>/dev/null; then
  echo "[083A] Invalid custom _get(state, ...) helper found. Rename to _state_get." >&2
  exit 1
fi

if grep -R -E "(enemies_root|projectiles_root|spawn_points_root|obstacles_root)\.add_child\(" -n scripts/combat 2>/dev/null; then
  echo "[083A] Unsafe add_child on cached combat root found." >&2
  exit 1
fi

if [ -f scenes/ui/hud/FlaskHUD.tscn ] && [ -f scenes/ui/GameHUD.tscn ]; then
  if ! grep -q "FlaskHUD" scenes/ui/GameHUD.tscn; then
    echo "[083A] FlaskHUD scene exists but GameHUD.tscn does not own/instance it." >&2
    exit 1
  fi
fi

echo "[083A] Systems stabilization audit passed."
