# New Chat Prompt for Patch 002

Use this prompt if the current chat becomes unstable:

---

We are building **RELIC FORGE: VAULTBOUND**, a top-down 2D buildcraft dungeon-crawler ARPG in Godot 4.

The game is about buildcraft first: skills, tags, loot, passive nodes, status effects, and combat interactions. Do not drift into open-world RPG, isometric roguelite, or custom sprite generation.

Patch 001 already exists as a playable single-script Godot project. It contains:

- Player movement, dash, HP/mana/cooldowns
- Four skills: Fireball, Cleave, Frost Nova, Storm Lance
- Enemies: Ash Grunt, Bone Archer, Iron Brute, Cinder Spitter, Vault Warden boss
- Loot drops and equipment slots
- Passive level-up choices
- Room clear, reward, route, boss, victory/fail loop
- Build flags: frostfire_steam, burn_death_explode, slash_bleed, cleave_wave, dash_thunder, skill_echo, corpse_spark, bone_wisp_on_kill, blood_cast, chain_plus, execute_low_hp, perfect_dodge_focus

Your job is to create Patch 002 by refactoring the prototype into a scalable Godot architecture. Preserve all working gameplay interactions. Do not add lots of new content yet.

Patch 002 should split code into Resources and managers:

- SkillDef Resource
- ItemDef Resource
- PassiveNodeDef Resource
- StatusEffectDef Resource
- BuildStats calculator
- PlayerCombat
- EnemyDirector
- LootDirector
- RunDirector
- CombatEventBus

Acceptance test: all Patch 001 interactions must still work after the refactor.

Before writing code, inspect the current files and propose a minimal file-by-file patch plan. Then produce complete replacement files or new files, not vague snippets.

---
