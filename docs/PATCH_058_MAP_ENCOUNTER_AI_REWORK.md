# Patch 058 — Map Encounter + Enemy AI Rework

This patch makes endgame maps play less like rectangular enemy dumps and more like ARPG map encounters.

## Adds / replaces

- `scripts/systems/MapEncounterDirector.gd`
- `scripts/systems/MapLayoutSystem.gd`
- `scripts/data/EnemyDB.gd`
- `scripts/combat/EnemyActor.gd`
- `scripts/combat/CombatArena.gd`

## Main changes

- Map layouts now include more explicit encounter sections: start, pack rooms, side rooms, elite rooms, boss gate, boss arena.
- Map runs spawn designed packs instead of loose random enemies.
- Packs use composition roles: pressure, ranged, caster, hound rush, guard, elite, and boss guard.
- Enemies now use simple state-machine AI: idle, aggro, windup, recover, special.
- Enemy attacks have windups and recovery windows instead of instant touch damage.
- Bosses now have phase behavior based on health.
- Boss phases add cleaves, zone attacks, charges, and summons.
- Map objectives now show pack progress and boss state.
- Enemy warning zones are drawn and damage the player after a delay.
- Elite enemies and map bosses get stronger visual rings.

## Test flow

1. Launch the game.
2. Walk to the physical Map Device.
3. Press E.
4. Add or select a map.
5. Run it.
6. Clear packs.
7. Fight the boss.
8. Open boss reward chest.
9. Return hub.

## Expected feel

A map should now have a readable rhythm:

Start → pack rooms → side/elite encounters → boss guard → boss phase fight → reward → exit.

This patch does not add final enemy art. It focuses on behavior, pacing, and encounter structure.
