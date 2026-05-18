# Patch 079K — Clear Active Map Portal Deduplication

Repairs a parser error caused by duplicate `func _clear_active_map_portal() -> void:` declarations in `scripts/core/GameRoot.gd`.

## Changes

- Backs up `scripts/core/GameRoot.gd`.
- Removes all existing `_clear_active_map_portal()` blocks.
- Installs one canonical parse-safe implementation.
- Adds a validator that fails if the duplicate returns.
- Checks that the invalid `Camera2D.clear_current()` call is no longer present.

## Install

```bash
cd /home/kaey/Desktop/Game
bash /home/kaey/Downloads/patch_079k_clear_active_map_portal_dedupe/install_patch_079k.sh
tools/patch_validators/validate_patch_079k.sh
tools/validate_all.sh
git status
```
