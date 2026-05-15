class_name RVSkillGemDB
extends RefCounted

# Patch 043: Uncut gem choice database + first real skill identity pass.
# Active and spirit gems are selected from uncut gems. Support effects are also
# selected from uncut support gems, then socketed directly into a target gem.

const ACTIVE_GEMS: Dictionary = {
	"fireball": {
		"name": "Fireball",
		"skill_id": "Fireball",
		"tags": ["Fire", "Projectile", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"flags": ["fireball_explodes", "inflicts_burn"],
		"description": "Launch a burning projectile. It explodes on impact and applies Burn. Strong clear, moderate mana pressure."
	},
	"cleave": {
		"name": "Cleave",
		"skill_id": "Cleave",
		"tags": ["Physical", "Melee", "Area"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"flags": ["inflicts_bleed", "close_combat_bonus"],
		"description": "A fast frontal melee arc. Applies Bleed and rewards fighting close."
	},
	"frost_nova": {
		"name": "Frost Nova",
		"skill_id": "Frost Nova",
		"tags": ["Cold", "Area", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"flags": ["inflicts_freeze", "control_skill"],
		"description": "Release a cold burst around you. Slows/freeze-locks enemies and controls crowded rooms."
	},
	"storm_lance": {
		"name": "Storm Lance",
		"skill_id": "Storm Lance",
		"tags": ["Lightning", "Projectile", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"flags": ["lightning_chains", "shock_pressure"],
		"description": "Fire a fast piercing lightning lance. Chains to nearby enemies and pressures clustered packs."
	},
	"void_rift": {
		"name": "Void Rift",
		"skill_id": "Void Rift",
		"tags": ["Void", "Area", "Spell"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"flags": ["inflicts_curse", "rift_pull"],
		"description": "Open a rift at the cursor. It pulls enemies inward and curses them so later hits matter more."
	},
	"blade_trap": {
		"name": "Blade Trap",
		"skill_id": "Blade Trap",
		"tags": ["Trap", "Physical", "Area"],
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"flags": ["trap_arms", "inflicts_bleed"],
		"description": "Place a cutting trap at the cursor. It bleeds enemies and works well with curse/control setups."
	}
}

const SUPPORT_GEMS: Dictionary = {
	"controlled_power": {
		"name": "Controlled Power Support",
		"tags": ["Support", "Damage"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap", "Spirit", "Aura"],
		"damage_more": 0.18,
		"mana_more": 0.14,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"flags": [],
		"description": "More damage. Higher cost or reservation."
	},
	"swift_cast": {
		"name": "Swift Cast Support",
		"tags": ["Support", "Speed"],
		"compatible_tags": ["Spell", "Projectile"],
		"damage_more": -0.05,
		"mana_more": 0.08,
		"cooldown_more": -0.18,
		"spirit_more": 0.10,
		"flags": ["fast_casting"],
		"description": "Lower cooldown. Slightly less damage."
	},
	"chain": {
		"name": "Chain Support",
		"tags": ["Support", "Projectile", "Lightning"],
		"compatible_tags": ["Projectile", "Lightning"],
		"damage_more": -0.10,
		"mana_more": 0.22,
		"cooldown_more": 0.04,
		"spirit_more": 0.18,
		"chain_count": 2,
		"flags": ["chain_plus"],
		"description": "Projectile and Lightning skills chain to additional enemies."
	},
	"area_expansion": {
		"name": "Area Expansion Support",
		"tags": ["Support", "Area"],
		"compatible_tags": ["Area"],
		"damage_more": -0.07,
		"mana_more": 0.18,
		"cooldown_more": 0.06,
		"spirit_more": 0.16,
		"radius_more": 0.28,
		"flags": ["larger_area"],
		"description": "Area skills become larger and easier to use."
	},
	"burning": {
		"name": "Burning Support",
		"tags": ["Support", "Fire", "Ailment"],
		"compatible_tags": ["Fire"],
		"damage_more": 0.10,
		"mana_more": 0.10,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"status_power": 0.40,
		"flags": ["strong_burn"],
		"description": "Fire skills apply stronger Burn."
	},
	"frostbite": {
		"name": "Frostbite Support",
		"tags": ["Support", "Cold", "Control"],
		"compatible_tags": ["Cold"],
		"damage_more": 0.08,
		"mana_more": 0.12,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"status_power": 0.35,
		"flags": ["strong_freeze"],
		"description": "Cold skills freeze harder and slow longer."
	},
	"overcharge": {
		"name": "Overcharge Support",
		"tags": ["Support", "Lightning", "Proc"],
		"compatible_tags": ["Lightning"],
		"damage_more": 0.06,
		"mana_more": 0.18,
		"cooldown_more": 0.02,
		"spirit_more": 0.14,
		"chain_count": 1,
		"flags": ["shock_burst"],
		"description": "Lightning skills shock and burst into extra chain damage."
	},
	"void_echo": {
		"name": "Void Echo Support",
		"tags": ["Support", "Void", "Proc"],
		"compatible_tags": ["Void"],
		"damage_more": 0.08,
		"mana_more": 0.16,
		"cooldown_more": 0.06,
		"spirit_more": 0.14,
		"flags": ["void_echo"],
		"description": "Void skills echo for a weaker second pulse."
	},
	"trap_mechanism": {
		"name": "Trap Mechanism Support",
		"tags": ["Support", "Trap"],
		"compatible_tags": ["Trap", "Area"],
		"damage_more": 0.14,
		"mana_more": 0.16,
		"cooldown_more": 0.04,
		"spirit_more": 0.15,
		"flags": ["trap_damage", "secondary_trap_tick"],
		"description": "Trap and placed area skills gain a secondary damage tick."
	},
	"bloodletting": {
		"name": "Bloodletting Support",
		"tags": ["Support", "Physical", "Bleed"],
		"compatible_tags": ["Physical", "Melee", "Trap"],
		"damage_more": 0.10,
		"mana_more": 0.08,
		"cooldown_more": 0.00,
		"spirit_more": 0.10,
		"status_power": 0.35,
		"flags": ["strong_bleed"],
		"description": "Physical, melee, and trap skills apply stronger Bleed."
	},
	"critical_focus": {
		"name": "Critical Focus Support",
		"tags": ["Support", "Critical"],
		"compatible_tags": ["Projectile", "Melee", "Spell", "Trap"],
		"damage_more": 0.05,
		"mana_more": 0.10,
		"cooldown_more": 0.00,
		"spirit_more": 0.10,
		"crit_chance_more": 0.10,
		"flags": ["critical_focus"],
		"description": "Higher critical pressure and better proc setups."
	},
	"mana_efficiency": {
		"name": "Mana Efficiency Support",
		"tags": ["Support", "Resource"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap", "Spirit", "Aura"],
		"damage_more": -0.04,
		"mana_more": -0.22,
		"cooldown_more": 0.00,
		"spirit_more": -0.12,
		"flags": ["efficient"],
		"description": "Lower cost and reservation. Slightly less damage."
	},
	"multi_projectile": {
		"name": "Split Projectile Support",
		"tags": ["Support", "Projectile"],
		"compatible_tags": ["Projectile"],
		"damage_more": -0.18,
		"mana_more": 0.24,
		"cooldown_more": 0.02,
		"spirit_more": 0.18,
		"extra_projectiles": 2,
		"flags": ["split_projectile"],
		"description": "Projectile skills fire extra side projectiles at reduced damage."
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
		"stats": {"Mana Recovery": 0.18, "Maximum Mana": 12.0},
		"description": "Reserve Spirit to improve mana recovery and maximum mana."
	},
	"vitality": {
		"name": "Vitality",
		"effect": "Maximum Life",
		"tags": ["Spirit", "Aura", "Life"],
		"base_reservation": 15,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Maximum Life": 28.0},
		"description": "Reserve Spirit to gain maximum life."
	},
	"emberskin": {
		"name": "Emberskin",
		"effect": "Fire Damage / Burn",
		"tags": ["Spirit", "Aura", "Fire"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Fire Damage": 0.14},
		"flags": ["aura_burn_boost"],
		"description": "Reserve Spirit to improve Fire damage and Burn-oriented builds."
	},
	"storm_focus": {
		"name": "Storm Focus",
		"effect": "Lightning Damage",
		"tags": ["Spirit", "Aura", "Lightning"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Lightning Damage": 0.14},
		"flags": ["aura_chain_boost"],
		"description": "Reserve Spirit to improve Lightning damage and chain pressure."
	},
	"void_whisper": {
		"name": "Void Whisper",
		"effect": "Void Damage / Curse",
		"tags": ["Spirit", "Aura", "Void"],
		"base_reservation": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Void Damage": 0.14},
		"flags": ["aura_curse_boost"],
		"description": "Reserve Spirit to improve Void damage and curse-driven builds."
	},
	"war_banner": {
		"name": "War Banner",
		"effect": "Melee / Physical",
		"tags": ["Spirit", "Aura", "Physical", "Melee"],
		"base_reservation": 18,
		"base_sockets": 2,
		"max_sockets": 6,
		"stats": {"Physical Damage": 0.12, "Maximum Life": 10.0},
		"flags": ["aura_bleed_boost"],
		"description": "Reserve Spirit to improve close-combat and bleed-oriented builds."
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

static func compatible_support_ids_for_tags(target_tags: Array) -> Array:
	var result: Array = []
	for support_id_value: Variant in support_ids():
		var support_id: String = str(support_id_value)
		if support_compatible_with_tags(support_id, target_tags):
			result.append(support_id)
	return result
