# Patch 050 — Skill Gems Mouse Interactions

This patch turns the Skill Gems panel into a mouse-first usable menu.

It preserves the Patch 049 sliced art path and replaces the Skill Gems panel scene/script with a functional art-aware Control scene.

## Adds / fixes

- Click active gems, support gems, and spirit gems to inspect/select them.
- Right-click Uncut Skill Gems to choose the active skill.
- Right-click Uncut Spirit Gems to choose the reservation skill.
- Right-click Uncut Support Gems to choose target and then support effect.
- Drag support gems onto active skill gems, spirit gems, or support sockets.
- Drag uncut support gems onto a target to open the support-effect choice panel for that target.
- Click support sockets to select them.
- Right-click filled support sockets to unsocket.
- Drag filled support sockets back to the support library to unsocket.
- Action buttons for equip/unequip, socket upgrades, spirit toggle, unsocket, and close.

## Important

This patch expects the Patch 049 sliced asset folder to exist:

```text
res://assets/ui/skill_gems/patch049/slices/
```

If art is missing, the panel falls back to simple dark rectangles and still remains functional.
