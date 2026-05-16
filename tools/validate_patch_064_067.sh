#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
missing=0
for f in \
  scripts/systems/CombatFeedbackSystem.gd \
  scripts/systems/SkillBehaviorSystem.gd \
  scripts/systems/MapEncounterDirector.gd \
  scripts/systems/MapLayoutSystem.gd \
  scripts/combat/EnemyActor.gd \
  scripts/combat/CombatArena.gd \
  scripts/systems/SkillSystem.gd; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f"
    missing=1
  else
    echo "OK: $f"
  fi
done
if [[ "$missing" -ne 0 ]]; then
  exit 1
fi
grep -q "class_name RVCombatFeedbackSystem" scripts/systems/CombatFeedbackSystem.gd
grep -q "class_name RVSkillBehaviorSystem" scripts/systems/SkillBehaviorSystem.gd
grep -q "damaged" scripts/combat/EnemyActor.gd
grep -q "RVSkillBehaviorSystem.apply_identity_scaling" scripts/systems/SkillSystem.gd
echo "Patch 064-067 validation passed. Open Godot for parser validation."
