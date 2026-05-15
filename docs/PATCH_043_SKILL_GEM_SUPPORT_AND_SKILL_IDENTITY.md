# Patch 043 — Skill Gem Support Menu + Skill Identity Pass

This patch fixes the support-gem menu problem and gives each current active skill a clearer mechanical identity.

## Main fixes

- Uncut Support Gems now use a two-step menu:
  1. choose the target active/spirit gem;
  2. choose the compatible support effect.
- Support effects exist again and are listed from `RVSkillGemDB.SUPPORT_GEMS`.
- Reward chests have a higher uncut gem drop chance while the gem system is being tested.
- Dev Tools gem bundle grants uncut gems instead of mostly pre-cut legacy gems.

## Active skill identity

- Fireball: projectile clear, explosion, burn.
- Cleave: melee area, bleed, close-combat pressure.
- Frost Nova: area control, freeze/slow.
- Storm Lance: fast projectile, lightning chain, shock pressure.
- Void Rift: target area, pull, curse.
- Blade Trap: placed area trap, bleed, secondary trap tick with support.

## Support effects added/standardized

- Controlled Power
- Swift Cast
- Chain
- Area Expansion
- Burning
- Frostbite
- Overcharge
- Void Echo
- Trap Mechanism
- Bloodletting
- Critical Focus
- Mana Efficiency
- Split Projectile

## Test flow

1. Press K.
2. Right-click an Uncut Skill Gem and choose a skill.
3. Right-click an Uncut Support Gem.
4. Choose a target skill/spirit gem.
5. Choose a support effect.
6. Equip the active skill.
7. Enter a combat room and test behavior.
