# Patch 085S — UIPanelRoot Input Parse Hard Repair

Purpose: remove residual `mouse_filter` input-ownership repair code that was inserted into UI scripts whose roots are not guaranteed to extend `Control`.

Fixes:

- Removes stale `_rf_085n_sync_input_ownership()` and `_rf_085n_apply_mouse_filter_to_controls()` helper blocks from `UIPanelRoot.gd`, `GameHUD.gd`, and `GameRoot.gd` if present.
- Removes bare/root-level `mouse_filter = ...` assignments that cause parse errors on non-`Control` roots.
- Removes impossible `panels is Control` / `hud is Control` casts from `GameRoot.gd`.
- Clears stale `state.panel_mode` once during boot so saved invisible panels do not soft-lock player movement after scene ownership changes.

This patch does not change gameplay or UI layout ownership.
