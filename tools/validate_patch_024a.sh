#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 024A validation =="
for f in \
  scripts/core/GameRoot.gd \
  scripts/core/GameState.gd \
  scripts/combat/CombatArena.gd \
  scripts/combat/CombatObstacle.gd \
  scenes/combat/CombatArena.tscn \
  scripts/ui/GameHUD.gd \
  scenes/ui/GameHUD.tscn
 do
  test -f "$f" && echo "OK $f" || { echo "MISSING $f"; exit 1; }
done

grep -Rni "room_objective\|room_reward_ready\|RewardChest\|ExitPortal\|func interact" scripts/core scripts/combat scenes/combat scripts/ui scenes/ui | head -120
