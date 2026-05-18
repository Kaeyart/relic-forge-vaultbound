#!/usr/bin/env bash
set -euo pipefail

fail=0
need() {
  local file="$1" pattern="$2" msg="$3"
  if ! grep -qE "$pattern" "$file"; then
    echo "FAIL: $msg" >&2
    fail=1
  fi
}
forbid() {
  local file="$1" pattern="$2" msg="$3"
  if grep -qE "$pattern" "$file"; then
    echo "FAIL: $msg" >&2
    fail=1
  fi
}

need scripts/combat/CombatArena.gd '^class_name RVCombatArena$' 'CombatArena global class missing'
need scripts/combat/CombatArena.gd '^extends Node2D$' 'CombatArena extends missing'
forbid scripts/combat/CombatArena.gd 'clear_current\(' 'Camera2D.clear_current must not be used'
need scripts/combat/CombatArena.gd 'func constrain_actor_movement\(' 'constrain_actor_movement missing'
need scripts/combat/CombatArena.gd '_rf_constrain_entity_movement\(enemy_previous_pos' 'enemy segment collision not wired'
need scripts/combat/EnemyActor.gd 'func _rv_constrain_movement\(' 'EnemyActor movement constraint helper missing'
need scripts/combat/EnemyActor.gd 'global_position = _rv_constrain_movement' 'EnemyActor _move/pull should constrain movement'
need scripts/core/GameState.gd 'active_map_portal_activity' 'GameState active map portal state missing'
need scripts/core/GameRoot.gd 'func _try_reenter_active_map_portal\(' 'GameRoot map portal re-entry helper missing'
need scripts/core/GameRoot.gd 'func _open_new_map_portal\(' 'GameRoot map portal open helper missing'

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "Patch 079J validator passed."
