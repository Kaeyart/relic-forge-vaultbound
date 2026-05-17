#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/data/ItemBaseDB.gd
test -f scripts/data/ItemAffixDB.gd
test -f scripts/systems/ItemRollSystem.gd
test -f scripts/systems/ItemizationSystem.gd

grep -q "class_name RVItemBaseDB" scripts/data/ItemBaseDB.gd
grep -q "class_name RVItemAffixDB" scripts/data/ItemAffixDB.gd
grep -q "class_name RVItemRollSystem" scripts/systems/ItemRollSystem.gd
grep -q "class_name RVItemizationSystem" scripts/systems/ItemizationSystem.gd
grep -q "forge_potential" scripts/systems/ItemizationSystem.gd
grep -q "prefixes" scripts/systems/ItemRollSystem.gd
grep -q "suffixes" scripts/systems/ItemRollSystem.gd
grep -q "RVItemRollSystem.generate_drop" scripts/data/ItemDB.gd

echo "Patch 080A validation passed."
