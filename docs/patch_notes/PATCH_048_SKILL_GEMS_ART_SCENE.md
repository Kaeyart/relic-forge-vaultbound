# Patch 048 — Skill Gems Art Scene

This patch slices the cleaned Skill Gems UI sheets into production assets and installs a scene-authored art skin for the Skill Gems panel.

## Adds

- `assets/ui/skill_gems/patch048/source/`
- `assets/ui/skill_gems/patch048/slices/`
- `assets/ui/skill_gems/patch048/skill_gems_patch048_manifest.json`
- `assets/ui/skill_gems/patch048/skill_gems_patch048_slice_contact_sheet.png`
- `scenes/ui/panels/SkillGemsPanelArtSkin.tscn`
- `scenes/ui/panels/SkillGemsPanel_ArtPreview.tscn`

## Integration behavior

The installer does not rewrite `SkillGemsPanel.gd` and does not delete the existing functional panel. It adds `SkillGemsPanelArtSkin.tscn` as the first child of the current `SkillGemsPanel.tscn`, so your existing functional controls remain on top.

If the art is hidden by an old opaque background node, open `SkillGemsPanel.tscn`, move `ArtSkin` just above that background, or hide the old background node manually.

## Design rule

The art layer should stay mostly decorative. Logic remains in `SkillGemsPanel.gd`; layout remains scene-authored in Godot.
