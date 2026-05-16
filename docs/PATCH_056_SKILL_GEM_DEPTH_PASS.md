# Patch 056 — Skill Gem Functionality Depth Pass

This patch deepens the existing skill gem system without replacing the manually authored SkillGemsPanel scene.

## Added

- Gem XP and leveling.
- Equipped active gems gain XP from kills/room clears.
- Enabled spirit gems gain XP from room progress.
- Uncut gems do not gain XP until cut.
- Stricter support socket validation.
- Duplicate supports are blocked.
- Support compatibility uses target tags.
- Support previews explain cost/damage/cooldown/reservation changes.
- Spirit support previews show projected reservation.
- Active gem detail text now shows current modified stats.
- Spirit gem detail text shows live reservation.
- Support gem detail text shows compatible tags and mechanical deltas.
- Support drag/click feedback highlights valid/invalid targets.
- Action buttons update their labels based on selected gem state.
- Scene-authored socket visuals remain untouched; script keeps socket buttons as click/drop targets only.

## Touched Files

- `scripts/data/SkillGemDB.gd`
- `scripts/systems/SkillGemSystem.gd`
- `scripts/systems/ProgressionSystem.gd`
- `scripts/ui/panels/SkillGemsPanel.gd`

## Not Touched

- `scenes/ui/panels/SkillGemsPanel.tscn`
- sliced skill gem UI art
- inventory scenes
- map scenes

## Test Checklist

1. Open the Skill Gems panel.
2. Select an active gem and check the detail text.
3. Select a support gem and check the preview against the current target.
4. Try socketing a valid support.
5. Try socketing a duplicate support; it should refuse.
6. Try socketing an incompatible support; it should refuse.
7. Enable a spirit gem and check spirit reservation.
8. Add a support to a spirit gem and check projected reservation.
9. Clear a room and confirm equipped/enabled gems gain XP.
10. Confirm the manually placed scene art remains intact.
