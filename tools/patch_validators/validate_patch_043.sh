#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
required=(
  scripts/data/SkillGemDB.gd
  scripts/data/SkillDB.gd
  scripts/systems/SkillGemSystem.gd
  scripts/systems/SkillSystem.gd
  scripts/ui/panels/SkillGemsPanel.gd
  scripts/combat/CombatArena.gd
  scripts/combat/EnemyActor.gd
  scripts/systems/ProgressionSystem.gd
  scripts/dev/DevToolSystem.gd
)
for f in "${required[@]}"; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done

grep -R "cut_uncut_support_gem_for_target" scripts/systems/SkillGemSystem.gd scripts/ui/panels/SkillGemsPanel.gd >/dev/null
grep -R "Overcharge Support\|Void Echo Support\|Bloodletting Support" scripts/data/SkillGemDB.gd >/dev/null
grep -R "inflicts_burn\|lightning_chains\|rift_pull" scripts/data/SkillDB.gd scripts/combat/CombatArena.gd >/dev/null

echo "Patch 043 validation passed."
