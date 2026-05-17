# Patch 068-071 — Combat Juice + Pack AI + Status Combos + Boss Phases

This patch combines the next four combat passes into one install:

- Patch 068 — Combat Juice + Control Pass
- Patch 069 — Pack AI + Crowd Steering
- Patch 070 — Status + Combo System
- Patch 071 — Boss Fight Pass

## Adds

- `scripts/systems/CombatJuiceSystem.gd`
- `scripts/systems/CombatStatusComboSystem.gd`
- `scripts/systems/CombatPackAISystem.gd`
- `scripts/systems/BossPhaseDirector.gd`
- `scripts/systems/CombatAudioProxySystem.gd`

## Main behavior changes

- light/heavy hit stop
- controlled screen shake
- enemy hit flash hooks
- enemy poise and stagger
- enemy crowd separation
- ranged/caster/caller spacing behavior
- skill-tag combo identity
- burn/freeze/shock/curse/bleed status reinforcement
- combo reactions: Overload, Shatter, Trap Detonation, Bloodburn
- boss phase feedback and phase pressure spawns
- player damage feedback

## Test checklist

1. Run a map.
2. Hit small enemies and check hit pause / impact feedback.
3. Kill enemies and check death burst feedback.
4. Fight packs and check whether enemies separate more cleanly.
5. Cast Fireball, Storm Lance, Frost Nova, Void Rift, Cleave, and Blade Trap.
6. Confirm statuses are visible/meaningful.
7. Fight the map boss and confirm phase callouts / phase pressure.
8. Confirm map completion and reward chest still work.

## Notes

This is still Tier-1 prototype combat presentation. It does not add final sprite art or sound assets. It adds the combat-feel infrastructure we need before final art.
