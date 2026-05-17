#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
fail=0
check_file() {
  if [ ! -f "$1" ]; then
    echo "MISSING: $1"
    fail=1
  else
    echo "OK: $1"
  fi
}
check_file scripts/data/PassiveAtlasDB.gd
check_file docs/PATCH_076_PASSIVE_ATLAS_POWER_IDENTITY.md
if ! grep -q 'class_name RVPassiveAtlasDB' scripts/data/PassiveAtlasDB.gd; then
  echo 'ERROR: PassiveAtlasDB class_name missing'
  fail=1
fi
for fn in 'node(' 'node_data(' 'ordered_ids_for_class(' 'can_allocate(' 'node_summary('; do
  if ! grep -q "static func $fn" scripts/data/PassiveAtlasDB.gd; then
    echo "ERROR: missing static func $fn"
    fail=1
  fi
done
if ! grep -q 'NODES_PER_REGION: int = 300' scripts/data/PassiveAtlasDB.gd; then
  echo 'ERROR: expected 300 nodes per class region'
  fail=1
fi
if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo 'Patch 076 validation passed.'
