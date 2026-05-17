# Patch 047 — Repo Hygiene + Production Baseline Cleanup

Patch 047 is a cleanup patch. It does not add gameplay.

## Goals

- Clean up patch debris.
- Keep active docs visible.
- Move historical patch notes into an archive folder.
- Move patch-specific validation scripts into an archive folder.
- Ignore local backup folders going forward.
- Update `VERSION.txt`.
- Add consolidated validation scripts.
- Add production baseline and cleanup rules.

## What changed

```text
VERSION.txt
.gitignore
docs/CURRENT_STATUS.md
docs/ROADMAP_047_060.md
docs/CLEANUP_RULES.md
docs/PRODUCTION_BASELINE.md
docs/PATCH_047_REPO_HYGIENE_CLEANUP.md
docs/patch_notes/README.md
tools/validate_all.sh
tools/validate_runtime.sh
tools/validate_repo_hygiene.sh
tools/print_project_status.sh
```

Historical files moved:

```text
docs/PATCH_*.md → docs/patch_notes/
tools/validate_patch_*.sh → tools/patch_validators/
```

Local backup clutter moved out of the active tree when present:

```text
.manual_backups/
.patch_backups/
backups/
```

Those folders are preserved locally under `.local_project_backups/patch047_*` and ignored going forward.

## Not changed

- No gameplay systems were changed.
- No inventory, skill, map, combat, item, or crafting logic was changed.
- No manually authored scenes were replaced.

## After install

Run:

```bash
cd /home/kaey/Desktop/Game
tools/validate_all.sh
git status
```

Then review changes and commit.
