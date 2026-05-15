#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="/home/kaey/Desktop/Game"
cd "$PROJECT_DIR"

echo "== Patch 036 validation =="
for f in \
  scripts/data/ItemBaseDB.gd \
  scripts/data/ItemAffixDB.gd \
  scripts/data/ItemDB.gd \
  scripts/systems/ItemRollSystem.gd \
  docs/PATCH_036_AFFIX_POOL_REWORK.md; do
  if [[ ! -f "$f" ]]; then
    echo "Missing: $f"
    exit 1
  fi
  echo "Found: $f"
done

grep -R "class_name RVItemBaseDB" scripts/data/ItemBaseDB.gd >/dev/null
grep -R "class_name RVItemAffixDB" scripts/data/ItemAffixDB.gd >/dev/null
grep -R "class_name RVItemRollSystem" scripts/systems/ItemRollSystem.gd >/dev/null
grep -R "class_name RVItemDB" scripts/data/ItemDB.gd >/dev/null

grep -R "generate_drop" scripts/data/ItemDB.gd >/dev/null
grep -R "roll_item" scripts/systems/ItemRollSystem.gd >/dev/null
grep -R "prefix" scripts/data/ItemAffixDB.gd >/dev/null
grep -R "suffix" scripts/data/ItemAffixDB.gd >/dev/null

echo "Patch 036 files are present. Open Godot to complete parser validation."
