#!/usr/bin/env bash
set -euo pipefail

cd /home/kaey/Desktop/Game

echo "== Validate Patch 051 =="

test -f scenes/ui/panels/SkillGemsPanel.tscn
test -f scripts/ui/panels/SkillGemsPanel.gd
test -d assets/ui/skill_gems/patch051/slices
test -f assets/ui/skill_gems/patch051/skill_gems_patch051_manifest.json

grep -q "ActiveGemButton0" scenes/ui/panels/SkillGemsPanel.tscn
grep -q "SupportGemButton0" scenes/ui/panels/SkillGemsPanel.tscn
grep -q "SpiritGemButton0" scenes/ui/panels/SkillGemsPanel.tscn
grep -q "ChoiceButton0" scenes/ui/panels/SkillGemsPanel.tscn
grep -q "Patch 051: scene-authored" scripts/ui/panels/SkillGemsPanel.gd

if grep -q "RuntimeGemUI\|VBoxContainer.new()\|HBoxContainer.new()\|Button.new()\|Label.new()\|RichTextLabel.new()" scripts/ui/panels/SkillGemsPanel.gd; then
  echo "ERROR: SkillGemsPanel.gd still creates UI layout nodes at runtime."
  exit 1
fi

echo "Patch 051 validation passed."
