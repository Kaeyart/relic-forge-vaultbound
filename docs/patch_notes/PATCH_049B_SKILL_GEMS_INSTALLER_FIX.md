# Patch 049B — Skill Gems Installer + Runtime Texture Fix

Repairs the Patch 049A installer path bug and reapplies the runtime texture-loading fix for `SkillGemsPanel.gd`.

The failed 049A installer changed directory into the Godot project before copying its own docs/tools payload, so `./docs/...` resolved to the project folder instead of the patch folder.

This patch:

- preserves the patch package directory before changing into the project
- removes parse-time PNG `preload()` calls for the three socket textures
- loads socket textures at runtime through `ResourceLoader.load()`
- installs validation docs/tools correctly

Files touched:

- `scripts/ui/panels/SkillGemsPanel.gd`
- `docs/PATCH_049B_SKILL_GEMS_INSTALLER_FIX.md`
- `tools/validate_patch_049b.sh`
