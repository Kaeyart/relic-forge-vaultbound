#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

echo "== Validate Patch 048 =="

need_file() {
  if [ ! -f "$1" ]; then
    echo "MISSING: $1" >&2
    exit 1
  fi
  echo "OK: $1"
}

need_dir() {
  if [ ! -d "$1" ]; then
    echo "MISSING DIR: $1" >&2
    exit 1
  fi
  echo "OK: $1"
}

need_dir assets/ui/skill_gems/patch048/source
need_dir assets/ui/skill_gems/patch048/slices
need_file assets/ui/skill_gems/patch048/skill_gems_patch048_manifest.json
need_file assets/ui/skill_gems/patch048/skill_gems_patch048_slice_contact_sheet.png
need_file scenes/ui/panels/SkillGemsPanelArtSkin.tscn
need_file scenes/ui/panels/SkillGemsPanel_ArtPreview.tscn
need_file docs/PATCH_048_SKILL_GEMS_ART_SCENE.md

slice_count=$(find assets/ui/skill_gems/patch048/slices -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')
echo "Slice count: $slice_count"
if [ "$slice_count" -lt 60 ]; then
  echo "Expected at least 60 slices." >&2
  exit 1
fi

if [ -f scenes/ui/panels/SkillGemsPanel.tscn ]; then
  if grep -q 'SkillGemsPanelArtSkin.tscn' scenes/ui/panels/SkillGemsPanel.tscn; then
    echo "OK: SkillGemsPanel.tscn references ArtSkin."
  else
    echo "WARNING: SkillGemsPanel.tscn does not reference ArtSkin. ArtPreview still exists."
  fi
fi

echo "Patch 048 validation passed."
