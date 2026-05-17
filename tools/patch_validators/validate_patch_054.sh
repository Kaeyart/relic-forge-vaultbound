#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 054: Skill Gems clean layout =="

test -f scenes/ui/panels/SkillGemsPanel.tscn
test -f scripts/ui/panels/SkillGemsPanel.gd
test -f assets/ui/skill_gems/patch054/slices/sg_01_00_main_window_panel.png
test -f assets/ui/skill_gems/patch054/slices/sg_02_10_socket_empty_small.png
test -f assets/ui/skill_gems/patch054/slices/sg_02_11_socket_filled_red_small.png
test -f assets/ui/skill_gems/patch054/slices/sg_02_12_socket_locked_small.png

grep -q 'patch054' scripts/ui/panels/SkillGemsPanel.gd
grep -q 'ActiveColumn' scenes/ui/panels/SkillGemsPanel.tscn
grep -q 'DetailColumn' scenes/ui/panels/SkillGemsPanel.tscn
grep -q 'SupportColumn' scenes/ui/panels/SkillGemsPanel.tscn
grep -q 'SpiritSection' scenes/ui/panels/SkillGemsPanel.tscn
grep -q 'ChoiceSection' scenes/ui/panels/SkillGemsPanel.tscn
for name in DetailLabel ChoiceTitle SpiritMeterLabel HelpLabel FeaturedTitle FeaturedTags FeaturedGemIcon DragLayer CloseButton EquipSkillButton AddSkillSocketButton AddSpiritSocketButton EnableSpiritButton UnsocketButton; do
  grep -q "name="$name"" scenes/ui/panels/SkillGemsPanel.tscn || { echo "missing node $name"; exit 1; }
done
for i in $(seq 0 7); do grep -q "name="ActiveGemButton$i"" scenes/ui/panels/SkillGemsPanel.tscn || exit 1; done
for i in $(seq 0 15); do grep -q "name="SupportGemButton$i"" scenes/ui/panels/SkillGemsPanel.tscn || exit 1; done
for i in $(seq 0 5); do grep -q "name="SpiritGemButton$i"" scenes/ui/panels/SkillGemsPanel.tscn || exit 1; done
for i in $(seq 0 5); do grep -q "name="SocketButton$i"" scenes/ui/panels/SkillGemsPanel.tscn || exit 1; done

echo "Patch 054 validation OK."
