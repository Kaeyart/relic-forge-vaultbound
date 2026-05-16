#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

required=(
  "assets/ui/skill_gems/patch049/slices/sg_01_00_main_window_panel.png"
  "assets/ui/skill_gems/patch049/slices/sg_01_07_list_panel.png"
  "assets/ui/skill_gems/patch049/slices/sg_01_08_socket_row_frame.png"
  "assets/ui/skill_gems/patch049/slices/sg_02_10_socket_empty_small.png"
  "assets/ui/skill_gems/patch049/slices/sg_02_11_socket_filled_red_small.png"
  "assets/ui/skill_gems/patch049/slices/sg_02_12_socket_locked_small.png"
  "assets/ui/skill_gems/patch049/skill_gems_patch049_manifest.json"
  "scenes/ui/panels/SkillGemsPanel.tscn"
  "scripts/ui/panels/SkillGemsPanel.gd"
)

for path in "${required[@]}"; do
  if [ ! -f "$path" ]; then
    echo "MISSING: $path"
    exit 1
  fi
done

grep -q "ActiveGemList" scenes/ui/panels/SkillGemsPanel.tscn || { echo "SkillGemsPanel.tscn missing ActiveGemList"; exit 1; }
grep -q "SupportGemList" scenes/ui/panels/SkillGemsPanel.tscn || { echo "SkillGemsPanel.tscn missing SupportGemList"; exit 1; }
grep -q "ChoicePanel" scenes/ui/panels/SkillGemsPanel.tscn || { echo "SkillGemsPanel.tscn missing ChoicePanel"; exit 1; }
grep -q "patch049" scenes/ui/panels/SkillGemsPanel.tscn || { echo "SkillGemsPanel.tscn does not reference patch049 assets"; exit 1; }
grep -q "cut_uncut_support_gem_for_target" scripts/ui/panels/SkillGemsPanel.gd || { echo "SkillGemsPanel.gd missing support effect flow"; exit 1; }

echo "Patch 049 validation passed."
