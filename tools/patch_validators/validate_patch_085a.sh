#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
need_files=(
  scripts/data/PassiveAtlasDB.gd
  scripts/systems/PassiveTreeSystem.gd
  scripts/ui/panels/PassiveAtlasPanel.gd
  scripts/ui/components/PassiveTreeNodeButton.gd
  scripts/ui/components/PassiveTreeConnectionCanvas.gd
  scenes/ui/panels/PassiveAtlasPanel.tscn
  scenes/ui/components/PassiveTreeNodeButton.tscn
)
for f in "${need_files[@]}"; do
  if [ ! -f "$f" ]; then
    echo "ERROR missing $f"
    fail=1
  fi
done

if ! grep -q 'class_name RVPassiveTreeSystem' scripts/systems/PassiveTreeSystem.gd; then
  echo "ERROR PassiveTreeSystem class_name missing"
  fail=1
fi
if ! grep -q 'class_name RVPassiveAtlasPanel' scripts/ui/panels/PassiveAtlasPanel.gd; then
  echo "ERROR PassiveAtlasPanel class_name missing"
  fail=1
fi
if ! grep -q 'var unlocked_passive_nodes' scripts/core/GameState.gd; then
  echo "ERROR GameState missing unlocked_passive_nodes"
  fail=1
fi
if grep -R 'func _get(state' scripts/ui scripts/systems scripts/data >/dev/null 2>&1; then
  echo "ERROR invalid custom _get(state...) helper found"
  grep -R 'func _get(state' scripts/ui scripts/systems scripts/data || true
  fail=1
fi
if grep -R 'Camera2D.clear_current\|clear_current()' scripts >/dev/null 2>&1; then
  echo "ERROR Camera2D.clear_current still referenced"
  grep -R 'clear_current()' scripts || true
  fail=1
fi
if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "Patch 085A validation passed."
