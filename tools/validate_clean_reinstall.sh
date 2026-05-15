#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Required scenes =="
for f in \
  project.godot \
  scenes/main/GameRoot.tscn \
  scenes/hub/ForgeholdHub.tscn \
  scenes/combat/CombatArena.tscn \
  scenes/ui/GameHUD.tscn \
  scenes/ui/UIPanelRoot.tscn
do
  if [ -f "$f" ]; then echo "OK $f"; else echo "MISSING $f"; fi
done

echo
echo "== Required scripts =="
for f in \
  scripts/core/GameRoot.gd \
  scripts/core/GameState.gd \
  scripts/core/SaveSystem.gd \
  scripts/data/SkillDB.gd \
  scripts/data/EnemyDB.gd \
  scripts/data/ContractDB.gd \
  scripts/data/ItemDB.gd \
  scripts/combat/CombatArena.gd \
  scripts/hub/HubRoot.gd \
  scripts/ui/GameHUD.gd \
  scripts/ui/UIPanelRoot.gd
do
  if [ -f "$f" ]; then echo "OK $f"; else echo "MISSING $f"; fi
done

echo
echo "Validation complete."
