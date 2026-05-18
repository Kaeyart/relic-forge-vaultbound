#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "Validating Patch 083B..."

test -f tools/maintenance/audit_systems_083a.py
test -f tools/patchers/repair_flaskhud_scene_owner_083b.py
test -f docs/patch_notes/PATCH_083B_AUDIT_CLEANUP_FLASKHUD_OWNER.md

python3 tools/maintenance/audit_systems_083a.py --strict --write docs/SYSTEMS_STATUS.md

if [ -f scenes/ui/hud/FlaskHUD.tscn ]; then
  grep -q "FlaskHUD.tscn" scenes/ui/GameHUD.tscn
fi

if grep -R "RVMapDeviceArtSkin" -n scripts scenes 2>/dev/null; then
  echo "ERROR: stale RVMapDeviceArtSkin references remain."
  exit 1
fi

if grep -R "clear_current()" -n scripts scenes 2>/dev/null; then
  echo "ERROR: invalid Camera2D.clear_current() references remain."
  exit 1
fi

echo "Patch 083B validation passed."
