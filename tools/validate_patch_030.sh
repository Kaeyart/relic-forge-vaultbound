#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 030 validation =="

test -f scripts/data/ItemAffixDB.gd
grep -q "class_name RVItemAffixDB" scripts/data/ItemAffixDB.gd
grep -q "const PREFIXES" scripts/data/ItemAffixDB.gd
grep -q "const SUFFIXES" scripts/data/ItemAffixDB.gd
grep -q "UNIQUE_ITEMS" scripts/data/ItemDB.gd
grep -q "generate_drop" scripts/data/ItemDB.gd
grep -q "item_compare_text" scripts/systems/InventorySystem.gd
grep -q "effective_skill_data" scripts/systems/SkillSystem.gd

echo "Patch 030 files are present. Open Godot to catch parser errors."
