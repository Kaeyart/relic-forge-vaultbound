#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

fail() { echo "ERROR: $*" >&2; exit 1; }

[ -f scripts/systems/PassiveBuildApplicationSystem.gd ] || fail "Missing PassiveBuildApplicationSystem.gd"
grep -q "class_name RVPassiveBuildApplicationSystem" scripts/systems/PassiveBuildApplicationSystem.gd || fail "PassiveBuildApplicationSystem has no class_name"

grep -q "PassiveBuildApplicationSystemScript" scripts/core/GameState.gd || fail "GameState does not preload/use PassiveBuildApplicationSystemScript"
grep -q "PATCH_085Q_PASSIVE_BUILD_MERGE" scripts/core/GameState.gd || fail "GameState missing passive build merge marker"
grep -q "PATCH_085Q_DERIVED_PLAYER_STATS" scripts/core/GameState.gd || fail "GameState missing derived passive stats marker"
grep -q "PATCH_085Q_ITEM_STATS_MERGE" scripts/core/GameState.gd || fail "GameState missing item stats merge marker"

grep -q "PassiveBuildApplicationSystemScript" scripts/combat/CombatArena.gd || fail "CombatArena does not preload/use PassiveBuildApplicationSystemScript"
grep -q "PATCH_085Q_DAMAGE_TAG_APPLICATION" scripts/combat/CombatArena.gd || fail "CombatArena missing damage/tag application marker"

if grep -R "func _get(state" -n scripts/systems scripts/ui scripts/core 2>/dev/null; then
  fail "Found forbidden custom _get(state...) helper"
fi

if grep -R "clear_current()" -n scripts scenes 2>/dev/null; then
  fail "Found invalid Camera2D.clear_current() call"
fi

echo "OK: Patch 085Q passive stat application validation passed."
