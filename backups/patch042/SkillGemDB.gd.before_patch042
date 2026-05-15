class_name RVSkillGemDB
extends RefCounted

# Original ARPG-style gem database for Relic Forge.
# Three gem types:
# - active skill gems: grant usable skills and can hold support gems
# - support gems: modify active/spirit gems when socketed
# - spirit gems: reserve spirit for passive effects and can also hold supports

const ACTIVE_GEMS: Dictionary = {
	"fireball": {
		"name": "Fireball",
		"skill_id": "Fireball",
		"tags": ["Fire", "Projectile", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Launch a burning projectile."
	},
	"cleave": {
		"name": "Cleave",
		"skill_id": "Cleave",
		"tags": ["Physical", "Melee", "Area"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Swing in a wide arc."
	},
	"frost_nova": {
		"name": "Frost Nova",
		"skill_id": "Frost Nova",
		"tags": ["Cold", "Area", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Release a freezing burst around you."
	},
	"storm_lance": {
		"name": "Storm Lance",
		"skill_id": "Storm Lance",
		"tags": ["Lightning", "Projectile", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Fire a fast piercing lightning lance."
	},
	"void_rift": {
		"name": "Void Rift",
		"skill_id": "Void Rift",
		"tags": ["Void", "Area", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Open a damaging rift at the target point."
	},
	"blade_trap": {
		"name": "Blade Trap",
		"skill_id": "Blade Trap",
		"tags": ["Trap", "Physical", "Area"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"description": "Place a trap that cuts enemies in an area."
	}
}

const SUPPORT_GEMS: Dictionary = {
	"controlled_power": {
		"name": "Controlled Power Support",
		"tags": ["Support"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap"],
		"damage_more": 0.18,
		"mana_more": 0.14,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"description": "More damage, higher cost."
	},
	"swift_cast": {
		"name": "Swift Cast Support",
		"tags": ["Support", "Spell"],
		"compatible_tags": ["Spell"],
		"damage_more": -0.06,
		"mana_more": 0.08,
		"cooldown_more": -0.16,
		"spirit_more": 0.10,
		"description": "Lower cooldown, slightly less damage."
	},
	"chain": {
		"name": "Chain Support",
		"tags": ["Support", "Projectile"],
		"compatible_tags": ["Projectile"],
		"damage_more": -0.12,
		"mana_more": 0.22,
		"cooldown_more": 0.04,
		"spirit_more": 0.18,
		"flags": ["chain_plus"],
		"description": "Projectile skills gain chaining potential."
	},
	"area_expansion": {
		"name": "Area Expansion Support",
		"tags": ["Support", "Area"],
		"compatible_tags": ["Area"],
		"damage_more": -0.08,
		"mana_more": 0.18,
		"cooldown_more": 0.08,
		"spirit_more": 0.16,
		"radius_more": 0.25,
		"description": "Area skills become larger."
	},
	"burning": {
		"name": "Burning Support",
		"tags": ["Support", "Fire"],
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
		"tags": ["Support", "Cold"],
		"compatible_tags": ["Cold"],
		"damage_more": 0.10,
		"mana_more": 0.12,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"flags": ["strong_freeze"],
		"description": "Cold skills gain stronger freeze pressure."
	},
	"efficient_casting": {
		"name": "Efficiency Support",
		"tags": ["Support"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap"],
		"damage_more": -0.04,
		"mana_more": -0.18,
		"cooldown_more": 0.00,
		"spirit_more": -0.10,
		"description": "Lower cost and reservation, slightly less damage."
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
		"description": "Improves trap and placed area skills."
	}
}

const SPIRIT_GEMS: Dictionary = {
	"clarity": {
		"name": "Clarity Spirit Gem",
		"effect": "Mana Recovery",
		"tags": ["Spirit", "Aura", "Mana"],
		"base_reservation": 10,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Mana Recovery": 0.18},
		"description": "Reserve spirit to improve mana recovery."
	},
	"vitality": {
		"name": "Vitality Spirit Gem",
		"effect": "Maximum Life",
		"tags": ["Spirit", "Aura", "Life"],
		"base_reservation": 15,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Maximum Life": 25.0},
		"description": "Reserve spirit to gain maximum life."
	},
	"herald_of_ash": {
		"name": "Herald of Ash Spirit Gem",
		"effect": "Fire Damage",
		"tags": ["Spirit", "Aura", "Fire"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Fire Damage": 0.14},
		"description": "Reserve spirit to improve fire damage."
	},
	"storm_focus": {
		"name": "Storm Focus Spirit Gem",
		"effect": "Lightning Damage",
		"tags": ["Spirit", "Aura", "Lightning"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Lightning Damage": 0.14},
		"description": "Reserve spirit to improve lightning damage."
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
	for tag: Variant in target_tags:
		if compatible_tags.has(str(tag)):
			return true
	return false
