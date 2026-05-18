# Patch 085K — Scene Authorship Audit

Purpose: enforce the Relic Forge UI production rule that persistent UI layout belongs in `.tscn` scenes, not scripts.

Adds:

- `tools/maintenance/audit_scene_authorship_085k.py`
- `tools/patch_validators/validate_patch_085k.sh`
- `docs/SCENE_AUTHORSHIP_STATUS.md` generated on install

Checks:

- UI panel/HUD scripts creating persistent layout nodes with `.new()`
- generated/fallback UI names such as `GeneratedTreeScroll`
- `GameRoot.gd` directly loading UI panel/HUD scenes
- Control-derived UI scripts that are not scene-owned by any `.tscn`
- `GameHUD.tscn` scene-owning `FlaskHUD.tscn`
- `UIPanelRoot.tscn` scene-owning major panel scenes

Allowed:

- temporary drag previews
- reusable component scenes instantiated into scene-owned containers
- data-driven passive tree node buttons inside the scene-owned passive tree content layer

This patch does not change gameplay.
