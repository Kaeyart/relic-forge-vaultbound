# Patch 055 — Skill Gems Remove Runtime Socket Art

This is a script-only cleanup for the scene-authored Skill Gems panel.

## Problem

The hand-authored scene already contains socket artwork, but `SkillGemsPanel.gd` was still assigning large sliced PNGs to the socket `Button.icon` fields at runtime. Godot rendered those images at their raw size, creating the large overlapping socket/ring cluster near the selected gem area.

## Fix

`_refresh_socket_buttons()` now treats `SocketButton0..5` as transparent click/drop targets only.

The script no longer injects socket PNG art into the buttons. It keeps:

- click socket selection
- right-click unsocket
- support gem drop targets
- tooltips for filled/empty/locked sockets

## Scene-authored rule

Socket visuals should be placed and adjusted in `res://scenes/ui/panels/SkillGemsPanel.tscn`.

The script should update data and interactions only; it should not generate or resize visual socket art at runtime.
