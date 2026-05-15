#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0

echo "== Repo hygiene checks =="

for d in .manual_backups .patch_backups backups; do
  if [ -e "$d" ]; then
    echo "WARNING: local backup folder still exists in active tree: $d"
    echo "         It is ignored now, but consider moving it to .local_project_backups/ if tracked."
  fi
done

if [ -d docs ]; then
  loose_patch_count=$(find docs -maxdepth 1 -type f -name 'PATCH_*.md' ! -name 'PATCH_047_REPO_HYGIENE_CLEANUP.md' | wc -l)
  if [ "$loose_patch_count" -gt 0 ]; then
    echo "WARNING: $loose_patch_count old patch docs still live directly under docs/. Move them to docs/patch_notes/."
  else
    echo "OK: patch docs archived"
  fi
fi

if [ -d tools ]; then
  loose_validator_count=$(find tools -maxdepth 1 -type f -name 'validate_patch_*.sh' | wc -l)
  if [ "$loose_validator_count" -gt 0 ]; then
    echo "WARNING: $loose_validator_count old patch validators still live directly under tools/. Move them to tools/patch_validators/."
  else
    echo "OK: patch validators archived"
  fi
fi

for line in '.local_project_backups/' '.manual_backups/' '.patch_backups/' 'backups/'; do
  if ! grep -qxF "$line" .gitignore; then
    echo "MISSING .gitignore entry: $line"
    fail=1
  fi
done

if [ -f VERSION.txt ]; then
  echo "VERSION: $(cat VERSION.txt)"
else
  echo "MISSING VERSION.txt"
  fail=1
fi

exit "$fail"
