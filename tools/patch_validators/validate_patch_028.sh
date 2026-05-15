#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 028 validation =="
for f in \
  scripts/data/SkillGemDB.gd \
  scripts/systems/SkillGemSystem.gd \
  scripts/systems/SkillSystem.gd \
  scripts/systems/ProgressionSystem.gd \
  scripts/core/GameState.gd \
  scripts/core/GameRoot.gd \
  scripts/ui/panels/SkillGemsPanel.gd \
  scenes/ui/panels/SkillGemsPanel.tscn \
  docs/PATCH_028_SKILL_GEM_SYSTEM.md
 do
  test -f "$f" && echo "OK $f" || { echo "MISSING $f"; exit 1; }
done

grep -Rni "class_name RVSkillGemSystem\|class_name RVSkillGemDB\|skill_gem_inventory\|spirit_gem_inventory" scripts | head -60
