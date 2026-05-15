# Patch 034A — Buildcraft Observatory

This patch replaces the shallow simulation idea with the first serious internal design laboratory.

## Adds

- Data-driven virtual player profiles in `data/dev/lab/profiles/`.
- Data-driven simulation scenarios in `data/dev/lab/scenarios/`.
- Real gameplay telemetry logger.
- Buildcraft journey simulator.
- Item decision engine.
- Build coherence evaluator.
- Combat proxy evaluator.
- Warning/recommendation engine.
- Text and JSON report export.
- F10 Dev Tools integration.

## Dev Tools buttons

Open with `F10`.

New Observatory tools:

- Start Telemetry
- Save Telemetry
- Lab: New Player
- Lab: Fireball Journey
- Lab: Void Trap Journey
- Lab: Profile Matrix
- Lab: Loot Audit
- Save Lab Report
- Clear Lab Report

Reports save to:

`user://buildcraft_observatory/latest/`

Globalized Linux path is usually:

`~/.local/share/godot/app_userdata/Relic Forge Vaultbound/buildcraft_observatory/latest/`

## Design intent

This tool should not fake player quotes. It should run deterministic build journeys and show measurable failure points:

- upgrade cadence
- dry streaks
- confusing item rate
- build coherence
- archetype hit rate
- salvage pressure
- rough combat proxy
- actionable warnings

Future patches can add crafting path simulation, counterfactual experiments, richer scenario editing, and graph/report UI.
