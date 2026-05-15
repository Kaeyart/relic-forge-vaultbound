# Patch 033C — Simulation Lab Foundation

This patch replaces the toy simulation buttons with a metrics-driven simulation lab.

The goal is not fake player quotes. The goal is automated design diagnostics based on the current loot and build systems.

## Adds

```text
scripts/dev/sim/SimProfileDB.gd
scripts/dev/sim/SimItemScorer.gd
scripts/dev/sim/SimulationLab.gd
scripts/ui/dev/DevToolsPanel.gd
scenes/ui/dev/DevToolsPanel.tscn
```

## Simulation profiles

- New Player
- Fire Caster
- Melee Warrior
- Void Trapper
- Collector / Crafter
- Unique Hunter

Each profile has desired tags, desired stats, slot preferences, and scoring weights.

## What it measures

- useful drop rate
- upgrade rate
- salvage pressure
- unique / archetype hits
- average forge potential
- build tag coverage
- build coherence
- slot upgrade distribution
- loot audit rarity spread
- malformed / suspicious item count

## Buttons

Open Dev Tools with `F10`.

Simulation Lab buttons:

- Profile Sim 100 Runs
- Profile Sim 1000 Runs
- Loot Audit 5000 Drops
- Loot Audit 10000 Drops
- Save Report
- Clear Report

Reports are also saved to:

```text
user://simulation_reports/latest_simulation_report.txt
user://simulation_reports/latest_simulation_report.json
```

## Design rule

The simulator calls the current `RVItemDB.generate_drop(state, depth)` path. It does not maintain a separate fake loot table. If the item system changes, the simulator reports change with it.
