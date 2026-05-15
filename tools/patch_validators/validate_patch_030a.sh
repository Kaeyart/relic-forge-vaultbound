#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Patch 030A validation =="
echo "Checking for malformed Maximum Mana / Maximum Spirit statement..."
if grep -Rni 'Maximum Mana", 0.0)).*spirit_max' scripts/core/GameState.gd; then
  echo "ERROR: malformed one-line mana/spirit statement still exists."
  exit 1
fi

echo "Checking that Maximum Spirit item stat handling exists..."
grep -n 'Maximum Spirit' scripts/core/GameState.gd || {
  echo "ERROR: Maximum Spirit handling not found in GameState.gd"
  exit 1
}

echo "Showing GameState context around spirit handling:"
grep -n -C 3 'Maximum Spirit' scripts/core/GameState.gd || true

echo "Patch 030A validation passed."
