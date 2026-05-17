# Patch 049 — Skill Gems Usable Art Scene

This patch converts the Skill Gems panel from an art preview/still skin into a usable, scene-backed UI.

## What it does

- Installs the sliced Skill Gems art under `assets/ui/skill_gems/patch049/`.
- Replaces `scenes/ui/panels/SkillGemsPanel.tscn` with a real Control scene composed from TextureRects, labels, scroll containers, buttons, and data containers.
- Replaces `scripts/ui/panels/SkillGemsPanel.gd` with an art-aware version that preserves the functional uncut gem flow from Patch 043.
- Keeps right-click behavior for Uncut Skill, Support, and Spirit gems.
- Keeps active gem equip/unequip, socketing, unsocketing, adding sockets, and spirit toggling.
- Adds a usable choice modal for cutting gems and choosing support targets/effects.

## Scene structure

The scene now includes:

- `ActiveGemList`
- `SupportGemList`
- `SpiritGemList`
- `DetailLabel`
- `SocketRow`
- `ChoicePanel`
- `ChoiceBox`
- `SummaryLabel`
- `SpiritLabel`
- action buttons using the same unique names expected by the script

This means the scene is no longer just a still art layer. It is a usable Godot UI scene with real interactable controls over sliced art assets.

## Test checklist

1. Press `K` or open the Skill Gems panel.
2. Confirm the art-backed panel appears.
3. Click active gems on the left.
4. Click support gems on the right.
5. Right-click an Uncut Skill Gem and choose an active skill.
6. Right-click an Uncut Support Gem, choose target, then choose support effect.
7. Right-click an Uncut Spirit Gem and choose reservation skill.
8. Use Equip, Socket, Socket Spirit, Unsocket, + Socket, and Toggle Spirit.
9. Confirm the socket row updates.

## Notes

This patch intentionally does not touch `SkillGemDB.gd`, `SkillGemSystem.gd`, or combat logic. It is a presentation and panel-usability pass.
