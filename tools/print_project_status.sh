#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== VERSION =="
cat VERSION.txt 2>/dev/null || echo "missing VERSION.txt"

echo

echo "== MAIN SCENE =="
grep 'run/main_scene' project.godot 2>/dev/null || echo "missing project.godot main scene"

echo

echo "== ACTIVE DOCS =="
ls -1 docs/CURRENT_STATUS.md docs/PRODUCTION_BASELINE.md docs/CLEANUP_RULES.md docs/ROADMAP_047_060.md 2>/dev/null || true

echo

echo "== ACTIVE SCENES =="
ls -1 scenes/main/GameRoot.tscn scenes/hub/ForgeholdHub.tscn scenes/combat/CombatArena.tscn scenes/ui/UIPanelRoot.tscn 2>/dev/null || true

echo

echo "== GIT STATUS =="
git status --short
