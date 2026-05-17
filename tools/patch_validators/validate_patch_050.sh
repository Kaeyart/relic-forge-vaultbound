#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 050 validation =="

test -f scripts/ui/panels/SkillGemsPanel.gd
test -f scenes/ui/panels/SkillGemsPanel.tscn

grep -q "Patch 050" scripts/ui/panels/SkillGemsPanel.gd
grep -q "_begin_drag" scripts/ui/panels/SkillGemsPanel.gd
grep -q "_finish_drag" scripts/ui/panels/SkillGemsPanel.gd
grep -q "_drop_support_onto_target" scripts/ui/panels/SkillGemsPanel.gd
grep -q "_unsocket_support" scripts/ui/panels/SkillGemsPanel.gd

echo "Skill Gems panel script contains mouse/drag/drop support."

if [ -d assets/ui/skill_gems/patch049/slices ]; then
  echo "Patch049 art slices found."
else
  echo "WARNING: patch049 art slices not found. Panel will run with fallback rectangles."
fi

echo "Patch 050 validation passed."
