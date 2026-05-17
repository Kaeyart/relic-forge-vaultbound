#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
missing=0
for f in \
  scripts/systems/CombatJuiceSystem.gd \
  scripts/systems/CombatStatusComboSystem.gd \
  scripts/systems/CombatPackAISystem.gd \
  scripts/systems/BossPhaseDirector.gd \
  scripts/systems/CombatAudioProxySystem.gd \
  scripts/combat/CombatArena.gd \
  scripts/combat/EnemyActor.gd; do
  if [ ! -f "$f" ]; then
    echo "MISSING: $f"
    missing=1
  fi
done
if [ "$missing" -ne 0 ]; then
  exit 1
fi

grep -q "class_name RVCombatJuiceSystem" scripts/systems/CombatJuiceSystem.gd
grep -q "class_name RVCombatStatusComboSystem" scripts/systems/CombatStatusComboSystem.gd
grep -q "class_name RVCombatPackAISystem" scripts/systems/CombatPackAISystem.gd
grep -q "class_name RVBossPhaseDirector" scripts/systems/BossPhaseDirector.gd
grep -q "CombatJuiceSystemScript" scripts/combat/CombatArena.gd
grep -q "CombatStatusComboSystemScript" scripts/combat/CombatArena.gd
grep -q "CombatPackAISystemScript" scripts/combat/CombatArena.gd
grep -q "max_poise" scripts/combat/EnemyActor.gd
grep -q "apply_stagger" scripts/combat/EnemyActor.gd

echo "Patch 068-071 validation passed."
