#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PANEL="scripts/ui/panels/PassiveAtlasPanel.gd"
SCENE="scenes/ui/panels/PassiveAtlasPanel.tscn"
NODE_SCRIPT="scripts/ui/components/PassiveTreeNodeButton.gd"
CONN_SCRIPT="scripts/ui/components/PassiveTreeConnectionCanvas.gd"

for f in "$PANEL" "$SCENE" "$NODE_SCRIPT" "$CONN_SCRIPT"; do
  test -f "$f" || { echo "Missing $f"; exit 1; }
done

if grep -qE 'GeneratedTreeScroll|GeneratedSummaryLabel|GeneratedDetailText|GeneratedAllocateButton|GeneratedRefundButton' "$PANEL"; then
  echo "PassiveAtlasPanel.gd still contains generated fallback layout nodes."
  exit 1
fi

if grep -qE 'ScrollContainer\.new\(|RichTextLabel\.new\(|Label\.new\(|Panel\.new\(|PanelContainer\.new\(|Button\.new\(' "$PANEL"; then
  echo "PassiveAtlasPanel.gd still creates layout controls in code."
  exit 1
fi

if ! grep -q 'TreeScroll' "$SCENE" || ! grep -q 'TreeContent' "$SCENE" || ! grep -q 'ConnectionCanvas' "$SCENE"; then
  echo "PassiveAtlasPanel.tscn does not own required tree scene nodes."
  exit 1
fi

if ! grep -q 'Right-click' "$SCENE"; then
  echo "PassiveAtlasPanel.tscn hint was not updated."
  exit 1
fi

if ! grep -q 'passive_node_secondary_pressed' "$NODE_SCRIPT"; then
  echo "PassiveTreeNodeButton.gd missing right-click signal."
  exit 1
fi

echo "Patch 085J validation passed."
