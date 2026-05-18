# Patch 082A — Progression, Drops, and Flask Visibility Foundation

Adds a small scene-authored HUD widget for level/XP/passive points and the two-flask setup.

## Adds

- `scripts/systems/FlaskSystem.gd`
- `scripts/systems/ProgressionRewardSystem.gd`
- `scripts/ui/hud/FlaskHUD.gd`
- `scenes/ui/hud/FlaskHUD.tscn`

## Gameplay

- Z uses the health flask.
- X uses the mana flask.
- Both flasks have charges and recovery values.
- Kills refill flask charges gradually.
- Returning to hub refills flasks.
- Enemy kills award character XP.
- Equipped active gems and enabled spirit gems gain XP from kills.
- Elites/bosses have higher chances to prove drops are alive.
- Flask upgrade items can drop into backpack.
- Higher-level map monsters produce higher-level supplemental item drops.

## Notes

This does not create a full flask crafting/belt system. It keeps the design strict: one health flask, one mana flask.
