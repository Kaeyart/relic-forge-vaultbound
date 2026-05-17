#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

grep -q '^class_name RVCombatArena$' scripts/combat/CombatArena.gd
EXTENDS_COUNT=$(head -n 24 scripts/combat/CombatArena.gd | grep -c '^extends ' || true)
if [ "$EXTENDS_COUNT" -ne 1 ]; then
  echo "ERROR: expected exactly one extends line in the first 24 lines of CombatArena.gd, found $EXTENDS_COUNT"
  head -n 24 scripts/combat/CombatArena.gd
  exit 1
fi

echo "Patch 079B arena header repair validation passed."
