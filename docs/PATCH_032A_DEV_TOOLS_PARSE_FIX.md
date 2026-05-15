# Patch 032A — Dev Tools Parse Fix

## Purpose

Patch 032's installer inserted several `GameRoot.gd` statements on the same line. Godot/GDScript requires those declarations and calls to be on separate lines.

This patch repairs the malformed `GameRoot.gd` edits and keeps the developer/creative-mode panel.

## Fixes

- Splits `autosave_timer` and `dev_tools_panel` onto separate variable declarations.
- Splits `_install_dev_tools()` onto its own line in `_ready()`.
- Converts the F10 handler into proper multi-line GDScript.
- Reinstalls the dev tool scripts and panel scene.
- Re-adds combat debug helpers if missing.
- Adds safer null guards in dev helper methods.

## Hotkey

`F10` toggles the Dev Tools panel.
