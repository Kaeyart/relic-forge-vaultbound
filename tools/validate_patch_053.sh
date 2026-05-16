#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 053: Skill Gems Art Layout =="

required=(
  "assets/ui/skill_gems/patch053/slices/sg_01_00_main_window_panel.png"
  "assets/ui/skill_gems/patch053/slices/sg_01_07_list_panel.png"
  "assets/ui/skill_gems/patch053/slices/sg_02_10_socket_empty_small.png"
  "assets/ui/skill_gems/patch053/slices/sg_02_11_socket_filled_red_small.png"
  "assets/ui/skill_gems/patch053/slices/sg_02_12_socket_locked_small.png"
  "assets/ui/skill_gems/patch053/source/skill_gems_sheet_01.png"
  "assets/ui/skill_gems/patch053/skill_gems_patch053_manifest.json"
  "scenes/ui/panels/SkillGemsPanel.tscn"
  "scripts/ui/panels/SkillGemsPanel.gd"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing: $f" >&2
    exit 1
  fi
done

grep -q "patch053" scripts/ui/panels/SkillGemsPanel.gd
grep -q "ActiveColumn" scenes/ui/panels/SkillGemsPanel.tscn
grep -q "SupportColumn" scenes/ui/panels/SkillGemsPanel.tscn
grep -q "SpiritSection" scenes/ui/panels/SkillGemsPanel.tscn
grep -q "ChoiceButton17" scenes/ui/panels/SkillGemsPanel.tscn

echo "Patch 053 files present. Open Godot and test the Skill Gems panel."
