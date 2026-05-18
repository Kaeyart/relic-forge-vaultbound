#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

FILE="scripts/ui/components/PassiveTreeConnectionCanvas.gd"
test -f "$FILE"

if grep -nE 'for +node *: *Dictionary +in +PassiveDBScript\.nodes\(' "$FILE"; then
  echo "085E validation failed: PassiveTreeConnectionCanvas still has typed Dictionary iteration over PassiveDBScript.nodes()." >&2
  exit 1
fi

if ! grep -q 'func _node_data_from_value' "$FILE"; then
  echo "085E validation failed: missing node value normalization helper." >&2
  exit 1
fi

if ! grep -q 'PassiveDBScript.node_by_id' "$FILE"; then
  echo "085E validation failed: node_by_id compatibility lookup missing." >&2
  exit 1
fi

if ! grep -q 'PassiveDBScript.connected_ids' "$FILE"; then
  echo "085E validation failed: connected_ids lookup missing." >&2
  exit 1
fi

echo "Patch 085E validation passed."
