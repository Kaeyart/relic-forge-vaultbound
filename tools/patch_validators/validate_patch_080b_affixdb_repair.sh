#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

grep -q "static func max_tier_for_affix" scripts/data/ItemAffixDB.gd
grep -q "static func next_tier_affix" scripts/data/ItemAffixDB.gd
grep -q "static func roll_affix" scripts/data/ItemAffixDB.gd
grep -q "_compat_fallback_affix_defs" scripts/data/ItemAffixDB.gd

echo "Patch 080B AffixDB repair validation passed."
