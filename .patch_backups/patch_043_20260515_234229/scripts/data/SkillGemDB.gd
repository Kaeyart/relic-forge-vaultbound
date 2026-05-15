class_name RVSkillGemDB
extends RefCounted

# Relic Forge: Vaultbound
# Patch 042: Uncut gem crafting model.
# Design shape:
# - uncut active gems drop as white craftable skill gems
# - uncut support gems drop as white craftable support gems
# - uncut spirit gems drop as white craftable reservation gems
# - active/spirit gems start with 2 support sockets and can reach 6
# - supports socket into active or spirit gems; spirit supports increase reservation

const ACTIVE_GEMS: Dictionary = {
	"fireball": {
		"name": "Fireball",
		"skill_id": "Fireball",
		"tags": ["Fire", "Projectile", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Launch a burning projectile. Clear, direct, and easy to build around."
	},
	"cleave": {
		"name": "Cleave",
		"skill_id": "Cleave",
		"tags": ["Physical", "Melee", "Area"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Swing in a wide arc. A simple melee core that can become bleed, fire, or proc based."
	},
	"frost_nova": {
		"name": "Frost Nova",
		"skill_id": "Frost Nova",
		"tags": ["Cold", "Area", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Release a freezing burst around you. Strong control and area identity."
	},
	"storm_lance": {
		"name": "Storm Lance",
		"skill_id": "Storm Lance",
		"tags": ["Lightning", "Projectile", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Fire a fast lightning lance. Designed for chaining, crit, and overload builds."
	},
	"void_rift": {
		"name": "Void Rift",
		"skill_id": "Void Rift",
		"tags": ["Void", "Area", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Open a damaging rift at the target point. Built for curse, pull, and delayed damage."
	},
	"blade_trap": {
		"name": "Blade Trap",
		"skill_id": "Blade Trap",
		"tags": ["Trap", "Physical", "Area"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Place a trap that cuts enemies in an area. Built for setup, mechanical control, and trap chains."
	}
}

const SUPPORT_GEMS: Dictionary = {
	"controlled_power": {
		"name": "Controlled Power Support",
		"tags": ["Support", "Damage"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap"],
		"damage_more": 0.18,
		"mana_more": 0.14,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"description": "More damage, higher cost. Clean raw power."
	},
	"efficient_casting": {
		"name": "Efficiency Support",
		"tags": ["Support", "Resource"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap", "Aura", "Spirit"],
		"damage_more": -0.04,
		"mana_more": -0.18,
		"cooldown_more": 0.00,
		"spirit_more": -0.10,
		"description": "Lower cost/reservation, slightly less damage."
	},
	"area_expansion": {
		"name": "Area Expansion Support",
		"tags": ["Support", "Area"],
		"compatible_tags": ["Area", "Aura", "Spirit"],
		"damage_more": -0.08,
		"mana_more": 0.18,
		"cooldown_more": 0.08,
		"spirit_more": 0.16,
		"radius_more": 0.25,
		"description": "Area effects become larger."
	},
	"chain_reaction": {
		"name": "Chain Reaction Support",
		"tags": ["Support", "Projectile", "Proc"],
		"compatible_tags": ["Projectile", "Lightning", "Fire", "Spell"],
		"damage_more": -0.12,
		"mana_more": 0.22,
		"cooldown_more": 0.04,
		"spirit_more": 0.18,
		"flags": ["chain_plus"],
		"description": "Projectile skills gain chain/proc pressure."
	},
	"critical_focus": {
		"name": "Critical Focus Support",
		"tags": ["Support", "Critical"],
		"compatible_tags": ["Projectile", "Melee", "Spell", "Trap"],
		"damage_more": 0.10,
		"mana_more": 0.12,
		"cooldown_more": 0.00,
		"spirit_more": 0.14,
		"stats": {"Critical Chance": 0.04},
		"description": "Adds critical scaling pressure."
	},
	"mana_efficiency": {
		"name": "Mana Efficiency Support",
		"tags": ["Support", "Mana"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap", "Aura", "Spirit"],
		"damage_more": -0.08,
		"mana_more": -0.25,
		"cooldown_more": 0.00,
		"spirit_more": -0.12,
		"description": "Reduces mana pressure and reservation."
	},
	"burning": {
		"name": "Burning Support",
		"tags": ["Support", "Fire", "Burn"],
		"compatible_tags": ["Fire"],
		"damage_more": 0.12,
		"mana_more": 0.10,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"flags": ["burning_hits"],
		"description": "Fire skills hit harder and burn better."
	},
	"frostbite": {
		"name": "Frostbite Support",
		"tags": ["Support", "Cold", "Freeze"],
		"compatible_tags": ["Cold"],
		"damage_more": 0.10,
		"mana_more": 0.12,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"flags": ["strong_freeze"],
		"description": "Cold skills gain stronger freeze pressure."
	},
	"trap_mechanism": {
		"name": "Trap Mechanism Support",
		"tags": ["Support", "Trap"],
		"compatible_tags": ["Trap", "Area"],
		"damage_more": 0.14,
		"mana_more": 0.16,
		"cooldown_more": 0.04,
		"spirit_more": 0.15,
		"flags": ["trap_damage"],
		"description": "Improves trap and placed-area skills."
	},
	"void_tether": {
		"name": "Void Tether Support",
		"tags": ["Support", "Void", "Curse"],
		"compatible_tags": ["Void", "Area", "Spell"],
		"damage_more": 0.11,
		"mana_more": 0.14,
		"cooldown_more": 0.04,
		"spirit_more": 0.15,
		"flags": ["void_curse_pressure"],
		"description": "Void skills gain stronger curse/control identity."
	},
	"brutality": {
		"name": "Brutality Support",
		"tags": ["Support", "Physical", "Melee"],
		"compatible_tags": ["Physical", "Melee"],
		"damage_more": 0.20,
		"mana_more": 0.15,
		"cooldown_more": 0.03,
		"spirit_more": 0.12,
		"description": "Physical and melee skills gain direct impact."
	},
	"overload": {
		"name": "Overload Support",
		"tags": ["Support", "Lightning", "Proc"],
		"compatible_tags": ["Lightning"],
		"damage_more": 0.09,
		"mana_more": 0.20,
		"cooldown_more": 0.02,
		"spirit_more": 0.16,
		"flags": ["overload_proc"],
		"description": "Lightning skills gain high proc pressure."
	}
}

const SPIRIT_GEMS: Dictionary = {
	"clarity": {
		"name": "Clarity",
		"effect": "Mana Recovery",
		"tags": ["Spirit", "Aura", "Mana"],
		"base_reservation": 10,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Mana Recovery": 0.18},
		"description": "Reserve spirit to improve mana recovery."
	},
	"vitality": {
		"name": "Vitality",
		"effect": "Maximum Life",
		"tags": ["Spirit", "Aura", "Life"],
		"base_reservation": 15,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Maximum Life": 25.0},
		"description": "Reserve spirit to gain maximum life."
	},
	"emberskin": {
		"name": "Emberskin",
		"effect": "Fire Damage",
		"tags": ["Spirit", "Aura", "Fire"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Fire Damage": 0.14},
		"description": "Reserve spirit to improve fire damage."
	},
	"storm_focus": {
		"name": "Storm Focus",
		"effect": "Lightning Damage",
		"tags": ["Spirit", "Aura", "Lightning"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Lightning Damage": 0.14},
		"description": "Reserve spirit to improve lightning damage."
	},
	"void_whisper": {
		"name": "Void Whisper",
		"effect": "Void Damage",
		"tags": ["Spirit", "Aura", "Void"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Void Damage": 0.14},
		"description": "Reserve spirit to improve void damage."
	},
	"war_banner": {
		"name": "War Banner",
		"effect": "Physical Damage",
		"tags": ["Spirit", "Aura", "Physical", "Melee"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Physical Damage": 0.12, "Global Damage": 0.04},
		"description": "Reserve spirit to improve physical pressure."
	}
}

static func active_ids() -> Array:
	return ACTIVE_GEMS.keys()

static func support_ids() -> Array:
	return SUPPORT_GEMS.keys()

static func spirit_ids() -> Array:
	return SPIRIT_GEMS.keys()

static func active_data(gem_id: String) -> Dictionary:
	return ACTIVE_GEMS.get(gem_id, {})

static func support_data(gem_id: String) -> Dictionary:
	return SUPPORT_GEMS.get(gem_id, {})

static func spirit_data(gem_id: String) -> Dictionary:
	return SPIRIT_GEMS.get(gem_id, {})

static func support_compatible_with_tags(support_id: String, target_tags: Array) -> bool:
	var support: Dictionary = support_data(support_id)
	if support.is_empty():
		return false
	var compatible_tags: Array = support.get("compatible_tags", [])
	for tag_value: Variant in target_tags:
		if compatible_tags.has(str(tag_value)):
			return true
	return false

static func name_for_active(gem_id: String) -> String:
	return str(active_data(gem_id).get("name", gem_id.capitalize()))

static func name_for_support(gem_id: String) -> String:
	return str(support_data(gem_id).get("name", gem_id.capitalize()))

static func name_for_spirit(gem_id: String) -> String:
	return str(spirit_data(gem_id).get("name", gem_id.capitalize()))
