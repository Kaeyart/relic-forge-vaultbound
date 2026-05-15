class_name RVItemAffixDB
extends RefCounted

# Patch 036: Original Relic Forge affix pools.
# System shape: prefix/suffix, slot/base legality, item-level tiers, family blocking, weighted rolls.
# Content is original to Relic Forge, not copied from any external ARPG table.

const PREFIXES: Array[Dictionary] = [
	{
		"id": "phys_damage", "name": "Butcher's", "type": "prefix", "family": "major_damage", "weight": 950,
		"tags": ["Physical", "Damage", "Melee"], "allowed_slots": ["weapon", "amulet", "ring", "gloves"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Physical Damage": [4.0, 8.0]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Physical Damage": [9.0, 16.0]}},
			{"tier": 3, "min_ilvl": 16, "weight": 700, "stats": {"Physical Damage": [17.0, 28.0]}},
			{"tier": 4, "min_ilvl": 28, "weight": 500, "stats": {"Physical Damage": [29.0, 46.0]}},
			{"tier": 5, "min_ilvl": 42, "weight": 320, "stats": {"Physical Damage": [47.0, 72.0]}},
			{"tier": 6, "min_ilvl": 58, "weight": 180, "stats": {"Physical Damage": [73.0, 108.0]}}
		]
	},
	{
		"id": "fire_damage", "name": "Scorching", "type": "prefix", "family": "major_damage", "weight": 900,
		"tags": ["Fire", "Damage"], "allowed_slots": ["weapon", "offhand", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Fire Damage": [0.04, 0.08]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Fire Damage": [0.09, 0.15]}},
			{"tier": 3, "min_ilvl": 16, "weight": 680, "stats": {"Fire Damage": [0.16, 0.24]}},
			{"tier": 4, "min_ilvl": 28, "weight": 450, "stats": {"Fire Damage": [0.25, 0.36]}},
			{"tier": 5, "min_ilvl": 42, "weight": 280, "stats": {"Fire Damage": [0.37, 0.52]}},
			{"tier": 6, "min_ilvl": 58, "weight": 150, "stats": {"Fire Damage": [0.53, 0.72]}}
		]
	},
	{
		"id": "cold_damage", "name": "Glacial", "type": "prefix", "family": "major_damage", "weight": 900,
		"tags": ["Cold", "Damage"], "allowed_slots": ["weapon", "offhand", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Cold Damage": [0.04, 0.08]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Cold Damage": [0.09, 0.15]}},
			{"tier": 3, "min_ilvl": 16, "weight": 680, "stats": {"Cold Damage": [0.16, 0.24]}},
			{"tier": 4, "min_ilvl": 28, "weight": 450, "stats": {"Cold Damage": [0.25, 0.36]}},
			{"tier": 5, "min_ilvl": 42, "weight": 280, "stats": {"Cold Damage": [0.37, 0.52]}},
			{"tier": 6, "min_ilvl": 58, "weight": 150, "stats": {"Cold Damage": [0.53, 0.72]}}
		]
	},
	{
		"id": "lightning_damage", "name": "Charged", "type": "prefix", "family": "major_damage", "weight": 900,
		"tags": ["Lightning", "Damage"], "allowed_slots": ["weapon", "offhand", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Lightning Damage": [0.04, 0.08]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Lightning Damage": [0.09, 0.15]}},
			{"tier": 3, "min_ilvl": 16, "weight": 680, "stats": {"Lightning Damage": [0.16, 0.24]}},
			{"tier": 4, "min_ilvl": 28, "weight": 450, "stats": {"Lightning Damage": [0.25, 0.36]}},
			{"tier": 5, "min_ilvl": 42, "weight": 280, "stats": {"Lightning Damage": [0.37, 0.52]}},
			{"tier": 6, "min_ilvl": 58, "weight": 150, "stats": {"Lightning Damage": [0.53, 0.72]}}
		]
	},
	{
		"id": "void_damage", "name": "Hollow", "type": "prefix", "family": "major_damage", "weight": 850,
		"tags": ["Void", "Damage"], "allowed_slots": ["weapon", "offhand", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Void Damage": [0.04, 0.08]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Void Damage": [0.09, 0.15]}},
			{"tier": 3, "min_ilvl": 16, "weight": 680, "stats": {"Void Damage": [0.16, 0.24]}},
			{"tier": 4, "min_ilvl": 28, "weight": 450, "stats": {"Void Damage": [0.25, 0.36]}},
			{"tier": 5, "min_ilvl": 42, "weight": 280, "stats": {"Void Damage": [0.37, 0.52]}},
			{"tier": 6, "min_ilvl": 58, "weight": 150, "stats": {"Void Damage": [0.53, 0.72]}}
		]
	},
	{
		"id": "spell_damage", "name": "Arcane", "type": "prefix", "family": "spell_power", "weight": 850,
		"tags": ["Spell", "Damage", "Mana"], "allowed_slots": ["weapon", "offhand", "head", "chest", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Spell Damage": [0.04, 0.08], "Maximum Mana": [3.0, 6.0]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Spell Damage": [0.09, 0.14], "Maximum Mana": [7.0, 12.0]}},
			{"tier": 3, "min_ilvl": 16, "weight": 680, "stats": {"Spell Damage": [0.15, 0.22], "Maximum Mana": [13.0, 20.0]}},
			{"tier": 4, "min_ilvl": 28, "weight": 450, "stats": {"Spell Damage": [0.23, 0.32], "Maximum Mana": [21.0, 32.0]}},
			{"tier": 5, "min_ilvl": 42, "weight": 260, "stats": {"Spell Damage": [0.33, 0.46], "Maximum Mana": [33.0, 48.0]}}
		]
	},
	{
		"id": "trap_damage", "name": "Trapwright's", "type": "prefix", "family": "trap_power", "weight": 700,
		"tags": ["Trap", "Damage"], "allowed_slots": ["weapon", "offhand", "gloves", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Trap Damage": [0.05, 0.09]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Trap Damage": [0.10, 0.16]}},
			{"tier": 3, "min_ilvl": 16, "weight": 650, "stats": {"Trap Damage": [0.17, 0.26]}},
			{"tier": 4, "min_ilvl": 28, "weight": 420, "stats": {"Trap Damage": [0.27, 0.40]}},
			{"tier": 5, "min_ilvl": 42, "weight": 250, "stats": {"Trap Damage": [0.41, 0.58]}}
		]
	},
	{
		"id": "life", "name": "Vital", "type": "prefix", "family": "life", "weight": 1000,
		"tags": ["Life", "Defense"], "allowed_slots": ["head", "chest", "gloves", "boots", "ring", "amulet", "offhand"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Maximum Life": [8.0, 16.0]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Maximum Life": [17.0, 30.0]}},
			{"tier": 3, "min_ilvl": 16, "weight": 700, "stats": {"Maximum Life": [31.0, 50.0]}},
			{"tier": 4, "min_ilvl": 28, "weight": 480, "stats": {"Maximum Life": [51.0, 82.0]}},
			{"tier": 5, "min_ilvl": 42, "weight": 300, "stats": {"Maximum Life": [83.0, 126.0]}},
			{"tier": 6, "min_ilvl": 58, "weight": 180, "stats": {"Maximum Life": [127.0, 185.0]}}
		]
	},
	{
		"id": "armor", "name": "Guarded", "type": "prefix", "family": "armor", "weight": 950,
		"tags": ["Armor", "Defense"], "allowed_slots": ["head", "chest", "gloves", "boots", "offhand"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Armor": [8.0, 18.0]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Armor": [19.0, 36.0]}},
			{"tier": 3, "min_ilvl": 16, "weight": 700, "stats": {"Armor": [37.0, 66.0]}},
			{"tier": 4, "min_ilvl": 28, "weight": 480, "stats": {"Armor": [67.0, 108.0]}},
			{"tier": 5, "min_ilvl": 42, "weight": 300, "stats": {"Armor": [109.0, 165.0]}}
		]
	},
	{
		"id": "spirit", "name": "Commanding", "type": "prefix", "family": "spirit", "weight": 520,
		"tags": ["Spirit", "Resource"], "allowed_slots": ["head", "chest", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 8, "weight": 850, "stats": {"Maximum Spirit": [2.0, 4.0]}},
			{"tier": 2, "min_ilvl": 18, "weight": 650, "stats": {"Maximum Spirit": [5.0, 8.0]}},
			{"tier": 3, "min_ilvl": 34, "weight": 420, "stats": {"Maximum Spirit": [9.0, 13.0]}},
			{"tier": 4, "min_ilvl": 52, "weight": 220, "stats": {"Maximum Spirit": [14.0, 20.0]}}
		]
	},
	{
		"id": "skill_fireball", "name": "Pyromancer's", "type": "prefix", "family": "skill_level", "weight": 260,
		"tags": ["Fire", "Skill", "Fireball"], "allowed_slots": ["weapon", "offhand", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 18, "weight": 600, "stats": {"Fireball Level": [1.0, 1.0]}},
			{"tier": 2, "min_ilvl": 46, "weight": 220, "stats": {"Fireball Level": [2.0, 2.0]}}
		]
	},
	{
		"id": "skill_void_rift", "name": "Rift-Sung", "type": "prefix", "family": "skill_level", "weight": 240,
		"tags": ["Void", "Skill", "Void Rift"], "allowed_slots": ["offhand", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 18, "weight": 600, "stats": {"Void Rift Level": [1.0, 1.0]}},
			{"tier": 2, "min_ilvl": 46, "weight": 220, "stats": {"Void Rift Level": [2.0, 2.0]}}
		]
	},
	{
		"id": "skill_blade_trap", "name": "Mechanist's", "type": "prefix", "family": "skill_level", "weight": 240,
		"tags": ["Trap", "Skill", "Blade Trap"], "allowed_slots": ["gloves", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 18, "weight": 600, "stats": {"Blade Trap Level": [1.0, 1.0]}},
			{"tier": 2, "min_ilvl": 46, "weight": 220, "stats": {"Blade Trap Level": [2.0, 2.0]}}
		]
	}
]

const SUFFIXES: Array[Dictionary] = [
	{
		"id": "fire_res", "name": "of Flameward", "type": "suffix", "family": "resistance", "weight": 950,
		"tags": ["Fire", "Resistance"], "allowed_slots": ["head", "chest", "gloves", "boots", "ring", "amulet", "offhand"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Fire Resistance": [0.08, 0.16]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Fire Resistance": [0.17, 0.28]}},
			{"tier": 3, "min_ilvl": 18, "weight": 650, "stats": {"Fire Resistance": [0.29, 0.42]}},
			{"tier": 4, "min_ilvl": 34, "weight": 420, "stats": {"Fire Resistance": [0.43, 0.58]}},
			{"tier": 5, "min_ilvl": 52, "weight": 220, "stats": {"Fire Resistance": [0.59, 0.76]}}
		]
	},
	{
		"id": "cold_res", "name": "of Frostward", "type": "suffix", "family": "resistance", "weight": 950,
		"tags": ["Cold", "Resistance"], "allowed_slots": ["head", "chest", "gloves", "boots", "ring", "amulet", "offhand"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Cold Resistance": [0.08, 0.16]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Cold Resistance": [0.17, 0.28]}},
			{"tier": 3, "min_ilvl": 18, "weight": 650, "stats": {"Cold Resistance": [0.29, 0.42]}},
			{"tier": 4, "min_ilvl": 34, "weight": 420, "stats": {"Cold Resistance": [0.43, 0.58]}},
			{"tier": 5, "min_ilvl": 52, "weight": 220, "stats": {"Cold Resistance": [0.59, 0.76]}}
		]
	},
	{
		"id": "lightning_res", "name": "of Stormward", "type": "suffix", "family": "resistance", "weight": 950,
		"tags": ["Lightning", "Resistance"], "allowed_slots": ["head", "chest", "gloves", "boots", "ring", "amulet", "offhand"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Lightning Resistance": [0.08, 0.16]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Lightning Resistance": [0.17, 0.28]}},
			{"tier": 3, "min_ilvl": 18, "weight": 650, "stats": {"Lightning Resistance": [0.29, 0.42]}},
			{"tier": 4, "min_ilvl": 34, "weight": 420, "stats": {"Lightning Resistance": [0.43, 0.58]}},
			{"tier": 5, "min_ilvl": 52, "weight": 220, "stats": {"Lightning Resistance": [0.59, 0.76]}}
		]
	},
	{
		"id": "void_res", "name": "of the Abyss", "type": "suffix", "family": "resistance", "weight": 820,
		"tags": ["Void", "Resistance"], "allowed_slots": ["head", "chest", "gloves", "boots", "ring", "amulet", "offhand"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Void Resistance": [0.08, 0.16]}},
			{"tier": 2, "min_ilvl": 8, "weight": 850, "stats": {"Void Resistance": [0.17, 0.28]}},
			{"tier": 3, "min_ilvl": 18, "weight": 650, "stats": {"Void Resistance": [0.29, 0.42]}},
			{"tier": 4, "min_ilvl": 34, "weight": 420, "stats": {"Void Resistance": [0.43, 0.58]}},
			{"tier": 5, "min_ilvl": 52, "weight": 220, "stats": {"Void Resistance": [0.59, 0.76]}}
		]
	},
	{
		"id": "speed", "name": "of Haste", "type": "suffix", "family": "speed", "weight": 760,
		"tags": ["Speed"], "allowed_slots": ["weapon", "gloves", "boots", "ring", "amulet"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Attack Speed": [0.03, 0.06], "Cast Speed": [0.03, 0.06]}},
			{"tier": 2, "min_ilvl": 10, "weight": 800, "stats": {"Attack Speed": [0.07, 0.11], "Cast Speed": [0.07, 0.11]}},
			{"tier": 3, "min_ilvl": 24, "weight": 550, "stats": {"Attack Speed": [0.12, 0.17], "Cast Speed": [0.12, 0.17]}},
			{"tier": 4, "min_ilvl": 44, "weight": 280, "stats": {"Attack Speed": [0.18, 0.25], "Cast Speed": [0.18, 0.25]}}
		]
	},
	{
		"id": "cooldown", "name": "of Focus", "type": "suffix", "family": "cooldown", "weight": 720,
		"tags": ["Cooldown", "Utility"], "allowed_slots": ["offhand", "head", "gloves", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Cooldown Reduction": [0.03, 0.06]}},
			{"tier": 2, "min_ilvl": 12, "weight": 750, "stats": {"Cooldown Reduction": [0.07, 0.11]}},
			{"tier": 3, "min_ilvl": 28, "weight": 460, "stats": {"Cooldown Reduction": [0.12, 0.17]}},
			{"tier": 4, "min_ilvl": 48, "weight": 240, "stats": {"Cooldown Reduction": [0.18, 0.24]}}
		]
	},
	{
		"id": "crit", "name": "of Precision", "type": "suffix", "family": "critical", "weight": 700,
		"tags": ["Critical"], "allowed_slots": ["weapon", "gloves", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Critical Chance": [0.03, 0.06], "Critical Damage": [0.06, 0.12]}},
			{"tier": 2, "min_ilvl": 10, "weight": 800, "stats": {"Critical Chance": [0.07, 0.10], "Critical Damage": [0.13, 0.22]}},
			{"tier": 3, "min_ilvl": 24, "weight": 550, "stats": {"Critical Chance": [0.11, 0.15], "Critical Damage": [0.23, 0.36]}},
			{"tier": 4, "min_ilvl": 44, "weight": 280, "stats": {"Critical Chance": [0.16, 0.22], "Critical Damage": [0.37, 0.55]}}
		]
	},
	{
		"id": "mana_recovery", "name": "of Recovery", "type": "suffix", "family": "recovery", "weight": 820,
		"tags": ["Mana", "Recovery", "Resource"], "allowed_slots": ["offhand", "head", "chest", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Mana Recovery": [0.04, 0.08]}},
			{"tier": 2, "min_ilvl": 10, "weight": 800, "stats": {"Mana Recovery": [0.09, 0.15]}},
			{"tier": 3, "min_ilvl": 24, "weight": 550, "stats": {"Mana Recovery": [0.16, 0.24]}},
			{"tier": 4, "min_ilvl": 44, "weight": 280, "stats": {"Mana Recovery": [0.25, 0.36]}}
		]
	},
	{
		"id": "movement", "name": "of Swiftness", "type": "suffix", "family": "movement", "weight": 680,
		"tags": ["Movement", "Speed"], "allowed_slots": ["boots", "amulet"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 1, "weight": 1000, "stats": {"Movement Speed": [0.04, 0.07]}},
			{"tier": 2, "min_ilvl": 12, "weight": 780, "stats": {"Movement Speed": [0.08, 0.12]}},
			{"tier": 3, "min_ilvl": 30, "weight": 420, "stats": {"Movement Speed": [0.13, 0.18]}}
		]
	},
	{
		"id": "ailment_fire", "name": "of Cinders", "type": "suffix", "family": "ailment", "weight": 520,
		"tags": ["Fire", "Burn", "Status"], "allowed_slots": ["weapon", "offhand", "gloves", "ring", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 10, "weight": 900, "stats": {"Ignite Chance": [0.06, 0.10], "Burn Damage": [0.05, 0.09]}},
			{"tier": 2, "min_ilvl": 26, "weight": 520, "stats": {"Ignite Chance": [0.11, 0.17], "Burn Damage": [0.10, 0.18]}},
			{"tier": 3, "min_ilvl": 46, "weight": 260, "stats": {"Ignite Chance": [0.18, 0.26], "Burn Damage": [0.19, 0.30]}}
		]
	},
	{
		"id": "proc_chance", "name": "of Echoes", "type": "suffix", "family": "proc", "weight": 360,
		"tags": ["Proc", "Chain"], "allowed_slots": ["weapon", "offhand", "amulet", "relic"], "allowed_base_types": [],
		"tiers": [
			{"tier": 1, "min_ilvl": 18, "weight": 700, "stats": {"Proc Chance": [0.02, 0.04]}},
			{"tier": 2, "min_ilvl": 38, "weight": 360, "stats": {"Proc Chance": [0.05, 0.08]}},
			{"tier": 3, "min_ilvl": 62, "weight": 150, "stats": {"Proc Chance": [0.09, 0.13]}}
		]
	}
]

const UNIQUES: Array[Dictionary] = [
	{
		"id": "nightfall_reaver", "name": "Nightfall Reaver", "base_id": "ember_wand", "min_level": 12,
		"stats": {"Fire Damage": 0.18, "Void Damage": 0.16, "Critical Chance": 0.06},
		"build_flags": ["fireball_void_conversion", "fireball_can_echo_void_rift"],
		"unique_effects": ["Fireball also counts as Void.", "Critical Fireball hits can echo a small Void Rift."],
		"tags": ["Unique", "Fire", "Void", "Projectile", "Conversion", "Proc"],
		"description": "A build engine for Fire/Void hybrid casters."
	},
	{
		"id": "furnace_crown", "name": "Furnace Crown", "base_id": "iron_helm", "min_level": 10,
		"stats": {"Armor": 36.0, "Maximum Life": 24.0, "Fire Damage": 0.12},
		"build_flags": ["cleave_fire_conversion", "cleave_larger_area"],
		"unique_effects": ["Cleave gains Fire scaling.", "Cleave area is increased."],
		"tags": ["Unique", "Fire", "Physical", "Melee", "Area", "Conversion"],
		"description": "Turns a melee core into a burning area build."
	},
	{
		"id": "trapdoor_grips", "name": "Trapdoor Grips", "base_id": "trapwright_grips", "min_level": 14,
		"stats": {"Trap Damage": 0.18, "Void Damage": 0.12, "Cooldown Reduction": 0.05},
		"build_flags": ["blade_trap_void_conversion", "trap_rift_echo"],
		"unique_effects": ["Blade Trap gains Void scaling.", "Blade Trap can echo a tiny Void Rift."],
		"tags": ["Unique", "Trap", "Void", "Proc", "Conversion"],
		"description": "A trap item that opens the floor into the abyss."
	},
	{
		"id": "riftwalker_boots", "name": "Riftwalker Boots", "base_id": "travel_boots", "min_level": 16,
		"stats": {"Movement Speed": 0.10, "Void Damage": 0.10, "Maximum Mana": 18.0},
		"build_flags": ["void_rift_larger", "void_rift_cheaper"],
		"unique_effects": ["Void Rift is larger.", "Void Rift costs less mana."],
		"tags": ["Unique", "Void", "Movement", "Mana"],
		"description": "Movement gear for a rift-control build."
	},
	{
		"id": "stormglass_ring", "name": "Stormglass Ring", "base_id": "opal_ring", "min_level": 16,
		"stats": {"Lightning Damage": 0.14, "Cold Damage": 0.10, "Maximum Mana": 12.0},
		"build_flags": ["storm_lance_cold_conversion", "storm_lance_extra_radius"],
		"unique_effects": ["Storm Lance also counts as Cold.", "Storm Lance explosions are wider."],
		"tags": ["Unique", "Lightning", "Cold", "Spell", "Projectile", "Conversion"],
		"description": "A ring for storm/cold hybrid lancers."
	},
	{
		"id": "choir_prism", "name": "Choir Prism", "base_id": "relic_core", "min_level": 22,
		"stats": {"Maximum Spirit": 8.0, "Proc Chance": 0.05, "Cooldown Reduction": 0.04},
		"build_flags": ["active_skill_choir", "spirit_support_bonus"],
		"unique_effects": ["Active skills gain a small chance to echo another equipped skill.", "Spirit gems gain increased effect."],
		"tags": ["Unique", "Spirit", "Proc", "Chain"],
		"description": "A relic for players who want skills to call other skills."
	}
]

static func base_item(base_id: String) -> Dictionary:
	return RVItemBaseDB.get_base(base_id)

static func random_base_for_level(rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	return RVItemBaseDB.random_base_for_level(rng, item_level)

static func all_affixes(affix_type: String) -> Array[Dictionary]:
	var source: Array[Dictionary] = PREFIXES if affix_type == "prefix" else SUFFIXES
	var result: Array[Dictionary] = []
	for affix: Dictionary in source:
		result.append(affix.duplicate(true))
	return result

static func random_affix(rng: RandomNumberGenerator, affix_type: String, slot: String, item_level: int, existing_ids: Array = []) -> Dictionary:
	var base: Dictionary = {"slot": slot, "base_type": "", "tags": []}
	var used_families: Array[String] = []
	for id_value: Variant in existing_ids:
		var affix_def: Dictionary = affix_def_by_id(str(id_value))
		var family: String = str(affix_def.get("family", ""))
		if family != "" and not used_families.has(family):
			used_families.append(family)
	return roll_affix(rng, affix_type, base, item_level, used_families)

static func roll_affix(rng: RandomNumberGenerator, affix_type: String, base: Dictionary, item_level: int, used_families: Array[String]) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var total_weight: int = 0
	for affix_def: Dictionary in all_affixes(affix_type):
		if not _affix_allowed_on_base(affix_def, base, item_level, used_families):
			continue
		var weight: int = int(affix_def.get("weight", 100))
		if weight <= 0:
			continue
		candidates.append(affix_def)
		total_weight += weight
	if candidates.is_empty() or total_weight <= 0:
		return {}
	var roll: int = rng.randi_range(1, total_weight)
	var cursor: int = 0
	for candidate: Dictionary in candidates:
		cursor += int(candidate.get("weight", 100))
		if roll <= cursor:
			return materialize_affix(candidate, affix_type, item_level, rng)
	return materialize_affix(candidates[0], affix_type, item_level, rng)

static func materialize_affix(definition: Dictionary, affix_type: String = "", item_level: int = 1, rng_value: Variant = null) -> Dictionary:
	var chosen_type: String = affix_type
	if chosen_type == "":
		chosen_type = str(definition.get("type", "prefix"))
	var tier_data: Dictionary = _choose_tier(definition, item_level, rng_value)
	var rolled_stats: Dictionary = {}
	var primary_stat: String = str(definition.get("stat", ""))
	var primary_value: float = 0.0
	var stats: Dictionary = tier_data.get("stats", definition.get("stats", {}))
	for stat_key_value: Variant in stats.keys():
		var stat_name: String = str(stat_key_value)
		var range_value: Variant = stats[stat_key_value]
		var rolled: float = _roll_range(range_value, rng_value)
		rolled_stats[stat_name] = rolled
		if primary_stat == "":
			primary_stat = stat_name
			primary_value = rolled
	if primary_stat != "" and primary_value == 0.0 and rolled_stats.has(primary_stat):
		primary_value = float(rolled_stats[primary_stat])
	return {
		"id": str(definition.get("id", "affix")),
		"name": str(definition.get("name", "Affix")),
		"type": chosen_type,
		"family": str(definition.get("family", str(definition.get("id", "affix")))),
		"tier": int(tier_data.get("tier", 1)),
		"min_ilvl": int(tier_data.get("min_ilvl", 1)),
		"stat": primary_stat,
		"value": primary_value,
		"stats": rolled_stats,
		"tags": definition.get("tags", []).duplicate(true),
		"craft_tags": definition.get("craft_tags", definition.get("tags", [])).duplicate(true)
	}

static func affix_def_by_id(id: String) -> Dictionary:
	for affix: Dictionary in PREFIXES:
		if str(affix.get("id", "")) == id:
			return affix.duplicate(true)
	for affix: Dictionary in SUFFIXES:
		if str(affix.get("id", "")) == id:
			return affix.duplicate(true)
	return {}

static func aggregate_stats(implicit_stats: Dictionary, prefixes: Array, suffixes: Array, extra_stats: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	_add_stats_into(result, implicit_stats)
	for affix_value: Variant in prefixes:
		if typeof(affix_value) == TYPE_DICTIONARY:
			_add_stats_into(result, Dictionary(affix_value).get("stats", {}))
	for affix_value: Variant in suffixes:
		if typeof(affix_value) == TYPE_DICTIONARY:
			_add_stats_into(result, Dictionary(affix_value).get("stats", {}))
	_add_stats_into(result, extra_stats)
	return result

static func affix_names(prefixes: Array, suffixes: Array) -> Array[String]:
	var result: Array[String] = []
	for affix_value: Variant in prefixes:
		if typeof(affix_value) == TYPE_DICTIONARY:
			result.append(str(Dictionary(affix_value).get("name", "Prefix")))
	for affix_value: Variant in suffixes:
		if typeof(affix_value) == TYPE_DICTIONARY:
			result.append(str(Dictionary(affix_value).get("name", "Suffix")))
	return result

static func item_name_for(base_name: String, rarity: String, prefixes: Array, suffixes: Array) -> String:
	if rarity == "Normal":
		return base_name
	var prefix_name: String = ""
	var suffix_name: String = ""
	if not prefixes.is_empty() and typeof(prefixes[0]) == TYPE_DICTIONARY:
		prefix_name = str(Dictionary(prefixes[0]).get("name", ""))
	if not suffixes.is_empty() and typeof(suffixes[0]) == TYPE_DICTIONARY:
		suffix_name = str(Dictionary(suffixes[0]).get("name", ""))
	var name: String = base_name
	if prefix_name != "":
		name = prefix_name + " " + name
	if suffix_name != "":
		name += " " + suffix_name
	return name

static func random_unique_for_level(rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for unique_template: Dictionary in UNIQUES:
		if int(unique_template.get("min_level", 1)) <= item_level:
			candidates.append(unique_template)
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

static func _affix_allowed_on_base(affix_def: Dictionary, base: Dictionary, item_level: int, used_families: Array[String]) -> bool:
	var family: String = str(affix_def.get("family", ""))
	if family != "" and used_families.has(family) and not bool(affix_def.get("allow_duplicate_family", false)):
		return false
	var tiers: Array = affix_def.get("tiers", [])
	var has_eligible_tier: bool = false
	for tier_value: Variant in tiers:
		if typeof(tier_value) == TYPE_DICTIONARY and int(Dictionary(tier_value).get("min_ilvl", 1)) <= item_level:
			has_eligible_tier = true
			break
	if not has_eligible_tier:
		return false
	var slot: String = str(base.get("slot", ""))
	var allowed_slots: Array = affix_def.get("allowed_slots", [])
	if not allowed_slots.is_empty() and not allowed_slots.has(slot):
		return false
	var base_type: String = str(base.get("base_type", ""))
	var allowed_base_types: Array = affix_def.get("allowed_base_types", [])
	if not allowed_base_types.is_empty() and not allowed_base_types.has(base_type):
		return false
	return true

static func _choose_tier(definition: Dictionary, item_level: int, rng_value: Variant) -> Dictionary:
	var eligible: Array[Dictionary] = []
	var total_weight: int = 0
	for tier_value: Variant in definition.get("tiers", []):
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var tier_data: Dictionary = Dictionary(tier_value)
		if int(tier_data.get("min_ilvl", 1)) > item_level:
			continue
		eligible.append(tier_data)
		total_weight += int(tier_data.get("weight", 100))
	if eligible.is_empty():
		return {"tier": 1, "min_ilvl": 1, "stats": definition.get("stats", {})}
	if not (rng_value is RandomNumberGenerator):
		return eligible[eligible.size() - 1].duplicate(true)
	var rng: RandomNumberGenerator = rng_value as RandomNumberGenerator
	var roll: int = rng.randi_range(1, max(1, total_weight))
	var cursor: int = 0
	for tier_data: Dictionary in eligible:
		cursor += int(tier_data.get("weight", 100))
		if roll <= cursor:
			return tier_data.duplicate(true)
	return eligible[0].duplicate(true)

static func _roll_range(range_value: Variant, rng_value: Variant) -> float:
	if typeof(range_value) == TYPE_ARRAY:
		var arr: Array = Array(range_value)
		if arr.size() >= 2:
			var lo: float = float(arr[0])
			var hi: float = float(arr[1])
			if rng_value is RandomNumberGenerator:
				var rng: RandomNumberGenerator = rng_value as RandomNumberGenerator
				return rng.randf_range(lo, hi)
			return (lo + hi) * 0.5
	return float(range_value)

static func _add_stats_into(target: Dictionary, source: Dictionary) -> void:
	for key_value: Variant in source.keys():
		var key: String = str(key_value)
		target[key] = float(target.get(key, 0.0)) + float(source[key_value])
