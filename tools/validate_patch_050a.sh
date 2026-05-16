#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo '== Validate Patch 050A =='
if [ ! -f scripts/ui/panels/SkillGemsPanel.gd ]; then
  echo 'Missing scripts/ui/panels/SkillGemsPanel.gd' >&2
  exit 1
fi

if grep -nE ':[[:space:]]*VBoxContainer[[:space:]]*=[[:space:]]*HBoxContainer\.new\(\)' scripts/ui/panels/SkillGemsPanel.gd; then
  echo 'Still has VBoxContainer = HBoxContainer.new() mismatch.' >&2
  exit 1
fi

echo 'No VBox/HBox static type mismatch found.'
echo 'Open Godot to confirm full script parse.'
