# Cleanup Rules

These rules exist because the project is now large enough that patch debris can damage development speed.

## Hard rules

1. The active boot scene is `res://scenes/main/GameRoot.tscn`.
2. UI layout belongs in `.tscn` scenes, not hardcoded script positions.
3. Scripts may update text, data, state, visibility, and runtime overlays.
4. Do not replace manually authored scenes unless the user explicitly asks for a scene replacement.
5. Prefer behavior patches over scene rewrites for UI fixes.
6. Every major patch needs a restore point or commit before install.
7. Every patch should have a validation script or be covered by `tools/validate_all.sh`.
8. Root-level one-off patch scripts should not stay in the active repo.
9. Local backup folders should stay ignored and outside the tracked tree.
10. If a patch breaks parser loading, fix parser errors before adding features.

## Active folders

```text
assets/      production assets and imported art
scenes/      authored Godot scenes
scripts/     runtime code
data/        data files for dev/lab/scenarios when used
docs/        active docs and patch notes
tools/       reusable validation/maintenance scripts
```

## Archive folders

```text
docs/patch_notes/        historical patch notes
tools/patch_validators/  historical one-patch validators
scripts/legacy/          old runtime code kept for reference
scenes/legacy/           old runtime scenes kept for reference
```

## Do not track

```text
.local_project_backups/
.manual_backups/
.patch_backups/
backups/
*.zip
*.tmp
*.bak
```

## Before every new patch

```bash
cd /home/kaey/Desktop/Game
git status
```

If the current project works:

```bash
git add .
git commit -m "checkpoint before next patch"
git push
```

## After every patch

```bash
cd /home/kaey/Desktop/Game
tools/validate_all.sh
```

Then test in Godot.
