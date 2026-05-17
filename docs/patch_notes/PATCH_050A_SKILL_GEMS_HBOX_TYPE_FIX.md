# Patch 050A — Skill Gems HBox Type Fix

Fixes a GDScript parse error introduced by Patch 050 where a variable typed as `VBoxContainer` was assigned `HBoxContainer.new()`.

The patch only changes `scripts/ui/panels/SkillGemsPanel.gd`.

It does not touch the Skill Gems scene, art assets, gem data, or gameplay systems.
