#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

missing=0
for f in \
  scripts/data/SkillGemDB.gd \
  scripts/systems/SkillGemSystem.gd \
  scripts/systems/ProgressionSystem.gd \
  scripts/ui/panels/SkillGemsPanel.gd \
  docs/PATCH_056_SKILL_GEM_DEPTH_PASS.md; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

grep -q "award_gem_xp" scripts/systems/SkillGemSystem.gd
grep -q "can_socket_support_to_target" scripts/systems/SkillGemSystem.gd
grep -q "support_preview_text" scripts/systems/SkillGemSystem.gd
grep -q "gem_detail_text" scripts/systems/SkillGemSystem.gd
grep -q "RVSkillGemSystem.award_gem_xp" scripts/systems/ProgressionSystem.gd
grep -q "Scene-authored" scripts/ui/panels/SkillGemsPanel.gd || true

echo "Patch 056 validation passed: skill gem depth files installed."
