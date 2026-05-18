#!/usr/bin/env bash
set -euo pipefail

cd /home/kaey/Desktop/Game

echo "Validating Patch 085M — GameRoot FlaskHUD scene-owner repair"

if grep -n "flask_hud" scripts/core/GameRoot.gd >/tmp/rv_085m_flask_refs.txt 2>/dev/null; then
  echo "ERROR: GameRoot.gd still references flask_hud:"
  cat /tmp/rv_085m_flask_refs.txt
  exit 1
fi

if grep -n "FlaskHUD.tscn" scripts/core/GameRoot.gd >/tmp/rv_085m_flask_scene_refs.txt 2>/dev/null; then
  echo "ERROR: GameRoot.gd still directly loads FlaskHUD.tscn:"
  cat /tmp/rv_085m_flask_scene_refs.txt
  exit 1
fi

if grep -n "_install_flask_hud" scripts/core/GameRoot.gd >/tmp/rv_085m_flask_install_refs.txt 2>/dev/null; then
  echo "ERROR: GameRoot.gd still has _install_flask_hud references:"
  cat /tmp/rv_085m_flask_install_refs.txt
  exit 1
fi

# Confirm the scene-owned direction at least has files present.
if [ ! -f scenes/ui/hud/FlaskHUD.tscn ]; then
  echo "ERROR: scenes/ui/hud/FlaskHUD.tscn is missing."
  exit 1
fi

if [ ! -f scripts/ui/GameHUD.gd ]; then
  echo "ERROR: scripts/ui/GameHUD.gd is missing."
  exit 1
fi

echo "Patch 085M validation passed."
