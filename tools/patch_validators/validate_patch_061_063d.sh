#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
printf 'Validating Patch 061-063D enemy pack_id fix...\n'
grep -q 'var pack_id: String' scripts/combat/EnemyActor.gd
grep -q 'pack_id = str' scripts/combat/EnemyActor.gd
grep -q 'encounter_role' scripts/combat/EnemyActor.gd
printf 'OK: EnemyActor exposes pack metadata used by CombatArena objective tracking.\n'
