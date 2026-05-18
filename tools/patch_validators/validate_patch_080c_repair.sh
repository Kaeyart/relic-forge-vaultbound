#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/data/LootFilterDB.gd
test -f scripts/systems/LootFilterSystem.gd
grep -q '^class_name RVLootFilterDB' scripts/data/LootFilterDB.gd
grep -q '^class_name RVLootFilterSystem' scripts/systems/LootFilterSystem.gd
grep -q 'static func update_ground_loot' scripts/systems/LootFilterSystem.gd
grep -q 'static func should_auto_pickup' scripts/systems/LootFilterSystem.gd
grep -q 'static func panel_text' scripts/systems/LootFilterSystem.gd

if grep -q 'static func _get' scripts/systems/LootFilterSystem.gd scripts/data/LootFilterDB.gd; then
	echo 'ERROR: forbidden _get helper found; would conflict with Object._get'
	exit 1
fi

echo 'Patch 080C loot filter class repair validation passed.'
