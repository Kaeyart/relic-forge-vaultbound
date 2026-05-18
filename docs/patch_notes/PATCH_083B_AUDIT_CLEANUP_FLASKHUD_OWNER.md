# Patch 083B — Audit Cleanup + FlaskHUD Scene Ownership Repair

Purpose:

- Make the stabilization audit inspect active project files instead of historical backup directories.
- Prevent false duplicate `class_name` errors from `.patch*` / `.local_project_backups` folders.
- Keep backup folders useful without letting them poison the systems report.
- Ensure `GameHUD.tscn` scene-owns `FlaskHUD.tscn` if the flask HUD scene exists.
- Keep the scene-authored UI rule intact.

This patch does not add gameplay.

It replaces `tools/maintenance/audit_systems_083a.py` with an active-project-only audit and writes a fresh `docs/SYSTEMS_STATUS.md`.

It also installs `tools/patchers/repair_flaskhud_scene_owner_083b.py`, which checks:

- `scenes/ui/hud/FlaskHUD.tscn`
- `scenes/ui/GameHUD.tscn`
- `scripts/ui/GameHUD.gd`

and patches scene ownership if needed.
