class_name RVSimProfileDB
extends RefCounted

static func profiles() -> Array:
	return [
		{
			"id": "new_player",
			"name": "New Player",
			"description": "Equips obvious upgrades: life, damage, armor, and clear rarity gains.",
			"desired_tags": ["Life", "Damage", "Armor", "Mana", "Resistance"],
			"desired_stats": ["Maximum Life", "Maximum Mana", "Global Damage", "Spell Damage", "Melee Damage", "Armor", "All Resistance"],
			"slot_focus": {},
			"weights": {"rarity": 0.55, "power": 1.0, "tags": 0.65, "potential": 0.22, "unique": 0.85, "coherence": 0.55}
		},
		{
			"id": "fire_caster",
			"name": "Fire Caster",
			"description": "Wants Fireball, spell scaling, ignite/burn, area, mana, and cast speed.",
			"desired_tags": ["Fire", "Spell", "Burn", "Area", "Projectile", "Mana", "Cooldown"],
			"desired_stats": ["Fire Damage", "Spell Damage", "Burn Damage", "Area Damage", "Projectile Damage", "Maximum Mana", "Cooldown Reduction"],
			"slot_focus": {"weapon": 1.25, "offhand": 1.15, "amulet": 1.10, "ring": 1.05, "relic": 1.10},
			"weights": {"rarity": 0.35, "power": 0.85, "tags": 1.25, "potential": 0.25, "unique": 1.25, "coherence": 1.15}
		},
		{
			"id": "melee_warrior",
			"name": "Melee Warrior",
			"description": "Wants Physical damage, weapon power, attack scaling, life, armor, bleed, and crit.",
			"desired_tags": ["Physical", "Melee", "Attack", "Bleed", "Critical", "Life", "Armor"],
			"desired_stats": ["Melee Damage", "Physical Damage", "Attack Speed", "Critical Chance", "Critical Damage", "Maximum Life", "Armor"],
			"slot_focus": {"weapon": 1.55, "gloves": 1.10, "chest": 1.10, "boots": 1.05, "relic": 1.05},
			"weights": {"rarity": 0.38, "power": 1.15, "tags": 1.05, "potential": 0.20, "unique": 1.10, "coherence": 0.95}
		},
		{
			"id": "void_trapper",
			"name": "Void Trapper",
			"description": "Wants Void Rift, Blade Trap, curse effects, area control, cooldowns, and proc chains.",
			"desired_tags": ["Void", "Trap", "Curse", "Area", "Cooldown", "Proc", "Chain"],
			"desired_stats": ["Void Damage", "Trap Damage", "Curse Effect", "Area Damage", "Cooldown Reduction", "Global Damage", "Maximum Mana"],
			"slot_focus": {"gloves": 1.35, "offhand": 1.25, "relic": 1.20, "ring": 1.10, "amulet": 1.10},
			"weights": {"rarity": 0.32, "power": 0.85, "tags": 1.45, "potential": 0.28, "unique": 1.35, "coherence": 1.30}
		},
		{
			"id": "collector_crafter",
			"name": "Collector / Crafter",
			"description": "Keeps imperfect high-potential bases, cares about affix pools and salvage value.",
			"desired_tags": ["Potential", "Crafting", "Affix", "Shard", "Rare", "Unique"],
			"desired_stats": ["Forge Potential", "Maximum Life", "Maximum Mana", "Global Damage", "Cooldown Reduction"],
			"slot_focus": {},
			"weights": {"rarity": 0.48, "power": 0.45, "tags": 0.65, "potential": 1.25, "unique": 1.10, "coherence": 0.75}
		},
		{
			"id": "unique_hunter",
			"name": "Unique Hunter",
			"description": "Mostly cares about build-changing uniques and archetype-enabling flags.",
			"desired_tags": ["Unique", "Conversion", "Proc", "Spirit", "Chain", "Archetype", "Skill Change"],
			"desired_stats": ["Global Damage", "Maximum Spirit", "Cooldown Reduction"],
			"slot_focus": {},
			"weights": {"rarity": 0.25, "power": 0.35, "tags": 1.05, "potential": 0.05, "unique": 2.10, "coherence": 1.25}
		}
	]

static func profile_by_id(profile_id: String) -> Dictionary:
	for profile in profiles():
		if str(profile.get("id", "")) == profile_id:
			return profile
	return profiles()[0]
