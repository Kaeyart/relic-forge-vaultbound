#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 031 validation =="
for f in \
  scripts/data/ItemAffixDB.gd \
  scripts/data/ItemDB.gd \
  scripts/systems/InventorySystem.gd \
  scripts/systems/SkillSystem.gd \
  scripts/ui/panels/InventoryPanel.gd \
  docs/DESIGN_ITEMIZATION_JOURNEY.md \
  docs/DESIGN_COMBAT_BUILDS.md \
  docs/DESIGN_PROGRESSION_MASTERY.md; do
  test -f "$f" || { echo "missing: $f"; exit 1; }
  echo "ok: $f"
done

grep -Rni "class_name RVItemAffixDB\|random_affix\|forge_potential\|prefixes\|suffixes\|unique_effects" scripts/data scripts/systems | head -80

echo "Validation complete. Open Godot for parser validation."
