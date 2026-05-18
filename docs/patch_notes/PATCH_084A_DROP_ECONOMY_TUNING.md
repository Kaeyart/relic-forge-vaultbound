# Patch 084A — Drop Economy Tuning + Progression Sanity

Purpose: make the current ARPG loop produce visible, filterable, progression-relevant rewards before building Atlas/classes.

## Adds / Rewrites

- `scripts/systems/ProgressionRewardSystem.gd`
- `scripts/systems/LootDropSystem.gd`
- `tools/patch_validators/validate_patch_084a.sh`

## Gameplay Intent

The loop should now read as:

1. Open map.
2. Kill normal packs, elites, and boss.
3. Gain character XP.
4. Equipped skill gems gain XP.
5. Drops scale from map/enemy level.
6. Elites/bosses produce meaningful loot pressure.
7. Gems, maps, crafting currency, and flask upgrades can appear.
8. Loot filter has richer item data to evaluate.

## Drop Tuning Baseline

Normal enemies:

- Frequent gold.
- Occasional material/currency.
- Occasional gear.
- Low gem/map/flask-upgrade chances.

Elites:

- High gear chance.
- Better material chance.
- Better map/gem/flask-upgrade chance.

Bosses:

- Guaranteed gold/material pressure.
- Guaranteed equipment bundle.
- High map sustain chance.
- Meaningful gem/flask-upgrade chance.

## Itemization Rules

- Equipment item level comes from map level / activity level.
- Rarity weights change by enemy importance and map rarity.
- Normal/magic items keep higher forge-potential ranges.
- Rare items roll 4–6 affixes.
- Uniques can roll from the existing unique pool.
- Affix tags and best affix tier are included for loot-filter rules.

## Flask Drops

Patch 084A does not add a flask belt. It keeps the existing design:

- One Health Flask.
- One Mana Flask.
- Upgrade drops can improve max charges, recovery, or charge gain.

## Known Limits

- Drop rates are first-pass tuning, not final balance.
- There is no loot-simulation report yet.
- Flask upgrade pickup currently applies the upgrade immediately.
- Gem XP only targets equipped/active gems using defensive schema detection.
