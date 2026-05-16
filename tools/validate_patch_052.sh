#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

missing=0
for f in \
  scenes/ui/panels/SkillGemsPanel.tscn \
  scripts/ui/panels/SkillGemsPanel.gd \
  docs/PATCH_052_ORGANIZED_SKILL_GEMS_SCENE.md; do
  if [ ! -f "$f" ]; then
    echo "MISSING: $f"
    missing=1
  else
    echo "OK: $f"
  fi
done

for token in "ActiveColumn" "DetailColumn" "SupportColumn" "SpiritSection" "ChoiceSection" "ActionSection"; do
  if ! grep -q "$token" scenes/ui/panels/SkillGemsPanel.tscn; then
    echo "MISSING SCENE GROUP: $token"
    missing=1
  else
    echo "OK GROUP: $token"
  fi
done

if ! grep -q "class_name RVSkillGemsPanel" scripts/ui/panels/SkillGemsPanel.gd; then
  echo "MISSING class_name RVSkillGemsPanel"
  missing=1
fi

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "Patch 052 validation passed."
