# Patch 059 — Visual Proxy Kit

This patch moves combat visuals from Tier 0 debug circles toward Tier 1 readable prototype art.

It adds:

- `scripts/data/EnemyVisualProfileDB.gd`
- `scripts/visuals/EnemyVisualRig.gd`
- `scripts/visuals/SpellVFXSystem.gd`
- `scripts/visuals/MapPropVisualSystem.gd`

It patches:

- `scripts/combat/EnemyActor.gd`
- `scripts/combat/CombatArena.gd`

## Goal

The game should no longer read as circles and rectangles during combat. Enemies are still not final art, but each role now has a deliberate silhouette:

- Ash Grunt: jagged melee humanoid
- Cinder Lunger: thin forward charge silhouette
- Ember Spitter: hunched ranged throat silhouette
- Chain Binder: tall caster/support with chain halo
- Hound: low rushing silhouette
- Knight: armored guard silhouette
- Brute: large furnace slam silhouette
- Bell Caller: summoner / priority target silhouette
- Boss: larger multi-part silhouette

Spells now emit readable proxy VFX:

- Fireball: projectile trail/core
- Storm Lance: lightning lance line
- Frost Nova: cold expanding rings
- Void Rift: dark rift/pull lines
- Cleave: slash arc
- Blade Trap: trap plate/blade cross

Runtime maps get quick proxy dressing:

- braziers near start
- floor cracks in pack rooms
- rubble in side rooms
- chain posts in elite areas
- boss altar / boss gate
- exit portal proxy ring

## Notes

This is not final production art. It is a Godot-native visual proxy layer meant to make gameplay readable while final sprites/rigs are developed later.

If a visual looks wrong, the intended workflow is to tweak the profile in `EnemyVisualProfileDB.gd`, not to return to circles.
