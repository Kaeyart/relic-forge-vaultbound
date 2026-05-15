#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

missing=0
for f in \
  scripts/data/SkillGemDB.gd \
  scripts/systems/SkillGemSystem.gd \
  scripts/ui/panels/SkillGemsPanel.gd \
  scenes/ui/panels/SkillGemsPanel.tscn \
  docs/PATCH_042_UNCUT_GEM_MENU_REWORK.md; do
  if [ ! -f "$f" ]; then
    echo "MISSING: $f"
    missing=1
  else
    echo "OK: $f"
  fi
done

if ! grep -R "Uncut Skill Gem" scripts/data/SkillGemDB.gd scripts/systems/SkillGemSystem.gd scripts/ui/panels/SkillGemsPanel.gd >/dev/null; then
  echo "MISSING: uncut skill gem text"
  missing=1
fi

if ! grep -R "class_name RVSkillGemSystem" scripts/systems/SkillGemSystem.gd >/dev/null; then
  echo "MISSING: RVSkillGemSystem class"
  missing=1
fi

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "Patch 042 validation passed."
