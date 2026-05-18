# Patch 085L — Scene Authorship Cleanup

This patch enforces the UI production rule: persistent UI layout belongs to `.tscn` scenes. Scripts may bind state, connect signals, and populate data-driven components into scene-owned containers.

## Changes

- GameRoot no longer directly owns LootFilterPanel or FlaskHUD.
- GameHUD.tscn scene-owns FlaskHUD.tscn.
- UIPanelRoot.tscn scene-owns LootFilterPanel.tscn.
- GameHUD.gd updates its scene-owned FlaskHUD.
- UIPanelRoot.gd updates its scene-owned LootFilterPanel.
- Scene-authorship audit now ignores backup folders, base UI scripts, reusable component scripts, and temporary drag previews.
- Remaining data-driven UI generation is reported as warnings for panel-specific cleanup.

## Remaining follow-up

Inventory, stash, map device, and skill-gem panels still have some data-driven row/control generation. That is acceptable short-term if those controls live inside scene-owned containers, but each panel should eventually get a small reusable row/button component scene.
