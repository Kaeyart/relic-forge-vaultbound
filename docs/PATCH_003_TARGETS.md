# Patch 003 Targets

Patch 003 should be based on what breaks or feels weak after local testing.

Priority order:

1. Fix any Godot errors or runtime issues from Patch 002.
2. Tune dungeon pacing: room size, enemy density, trap count, reward frequency, boss depth.
3. Improve build readability: clearer damage/status text, better item comparison, panel layout.
4. Add real item comparison: equipped item vs hovered inventory item.
5. Add a stash/vendor/forge hub after the run loop is stable.
6. Split only the most stable data into Resources: SkillData, ItemData, PassiveData, RoomData.
7. Add asset support only after the build loop proves fun with procedural art.

Acceptance for Patch 003:

- One full contract route should be completable without debug features.
- The player should be able to deliberately pursue at least four archetypes.
- Items and skill-tree choices should feel like build decisions, not random clutter.
