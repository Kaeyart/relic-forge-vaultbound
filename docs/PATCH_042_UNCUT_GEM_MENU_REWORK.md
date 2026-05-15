# Patch 042 — Uncut Gem Menu Rework

This patch reworks the skill gem flow into a white/uncut gem crafting model.

## Core behavior

- Active skill gems can drop as `Uncut Skill Gem`.
- Spirit reservation gems can drop as `Uncut Spirit Gem`.
- Support gems can drop as `Uncut Support Gem`.
- Right-click an uncut active gem to choose which active skill it becomes.
- Right-click an uncut spirit gem to choose which reservation effect it becomes.
- Right-click a support gem to choose a target active/spirit gem, then choose the support type if the support is still uncut.
- Active and spirit gems start with 2 support sockets.
- Socket Prisms can raise active/spirit socket capacity up to 6.
- Supports socketed into spirit gems increase reservation through `spirit_more`.

## Menu controls

Open with `K`.

- Left click a gem to select it.
- Right click an uncut active/spirit gem to engrave it.
- Right click a support gem to socket it.
- Use the bottom buttons for Equip Skill, Enable Spirit, Remove Last Support, and Use Socket Prism.

## Drop behavior

Room rewards now use `RVSkillGemSystem.award_random_gem_drop()`, which awards uncut active/support/spirit gems.
The patch also raises the progression gem-drop chance where the old exact reward code is present.

## Files

- `scripts/data/SkillGemDB.gd`
- `scripts/systems/SkillGemSystem.gd`
- `scripts/ui/panels/SkillGemsPanel.gd`
- `scenes/ui/panels/SkillGemsPanel.tscn`
