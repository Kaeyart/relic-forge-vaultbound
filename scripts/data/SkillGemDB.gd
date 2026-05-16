class_name RVSkillGemDB
extends RefCounted

# Patch 056: skill gem depth database.
# This keeps the current uncut gem flow, but gives active/support/spirit gems
# enough data for leveling, previews, compatibility, and clearer ARPG tooltips.

const GEM_MAX_LEVEL: int = 20

const ACTIVE_GEMS: Dictionary = {
	"fireball": {
		"name": "Fireball",
		"skill_id": "Fireball",
		"tags": ["Fire", "Projectile", "Spell", "Area", "Hit"],
		"primary_identity": "Projectile explosion + Burn",
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"base_damage": 24.0,
		"damage_per_level": 0.085,
		"base_mana_cost": 16.0,
		"mana_per_level": 0.035,
		"base_cooldown": 0.32,
		"base_radius": 58.0,
		"base_crit": 0.06,
		"flags": ["fireball_explodes", "inflicts_burn"],
		"description": "Launch a burning projectile that explodes on impact and applies Burn. Strong clear, moderate mana pressure."
	},
	"cleave": {
		"name": "Cleave",
		"skill_id": "Cleave",
		"tags": ["Physical", "Melee", "Area", "Attack", "Hit"],
		"primary_identity": "Melee arc + Bleed",
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"base_damage": 30.0,
		"damage_per_level": 0.08,
		"base_mana_cost": 10.0,
		"mana_per_level": 0.025,
		"base_cooldown": 0.24,
		"base_radius": 72.0,
		"base_crit": 0.07,
		"flags": ["inflicts_bleed", "close_combat_bonus"],
		"description": "A fast frontal melee arc. Applies Bleed and rewards fighting close."
	},
	"frost_nova": {
		"name": "Frost Nova",
		"skill_id": "Frost Nova",
		"tags": ["Cold", "Area", "Spell", "Control", "Hit"],
		"primary_identity": "Area control + Freeze",
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"base_damage": 18.0,
		"damage_per_level": 0.065,
		"base_mana_cost": 18.0,
		"mana_per_level": 0.03,
		"base_cooldown": 1.10,
		"base_radius": 105.0,
		"base_crit": 0.05,
		"flags": ["inflicts_freeze", "control_skill"],
		"description": "Release a cold burst around you. Slows and freezes enemies to control crowded rooms."
	},
	"storm_lance": {
		"name": "Storm Lance",
		"skill_id": "Storm Lance",
		"tags": ["Lightning", "Projectile", "Spell", "Chain", "Hit"],
		"primary_identity": "Fast lightning line + Chain pressure",
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"base_damage": 20.0,
		"damage_per_level": 0.075,
		"base_mana_cost": 14.0,
		"mana_per_level": 0.035,
		"base_cooldown": 0.22,
		"base_radius": 34.0,
		"base_crit": 0.09,
		"base_chain_count": 1,
		"flags": ["lightning_chains", "shock_pressure"],
		"description": "Fire a fast piercing lightning lance. Chains to nearby enemies and pressures clustered packs."
	},
	"void_rift": {
		"name": "Void Rift",
		"skill_id": "Void Rift",
		"tags": ["Void", "Area", "Spell", "Duration", "Curse"],
		"primary_identity": "Delayed anomaly + Pull + Curse",
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"base_damage": 22.0,
		"damage_per_level": 0.078,
		"base_mana_cost": 22.0,
		"mana_per_level": 0.035,
		"base_cooldown": 0.90,
		"base_radius": 88.0,
		"base_crit": 0.05,
		"flags": ["inflicts_curse", "rift_pull"],
		"description": "Open a rift at the cursor. It pulls enemies inward and curses them so later hits matter more."
	},
	"blade_trap": {
		"name": "Blade Trap",
		"skill_id": "Blade Trap",
		"tags": ["Trap", "Physical", "Area", "Duration", "Hit"],
		"primary_identity": "Placed trap + Bleed + Area denial",
		"base_level": 1,
		"max_level": 20,
		"base_sockets": 2,
		"max_sockets": 6,
		"base_damage": 26.0,
		"damage_per_level": 0.08,
		"base_mana_cost": 15.0,
		"mana_per_level": 0.03,
		"base_cooldown": 0.75,
		"base_radius": 62.0,
		"base_crit": 0.06,
		"flags": ["trap_arms", "inflicts_bleed"],
		"description": "Place a cutting trap at the cursor. It bleeds enemies and works well with curse/control setups."
	}
}

const SUPPORT_GEMS: Dictionary = {
	"controlled_power": {
		"name": "Controlled Power Support",
		"short_name": "Ctrl Power",
		"tags": ["Support", "Damage"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap", "Spirit", "Aura"],
		"requires_any_tag": true,
		"damage_more": 0.18,
		"mana_more": 0.14,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"flags": [],
		"preview_lines": ["More damage", "Higher cost or reservation"],
		"description": "More damage. Higher cost or reservation."
	},
	"swift_cast": {
		"name": "Swift Cast Support",
		"short_name": "Swift Cast",
		"tags": ["Support", "Speed"],
		"compatible_tags": ["Spell", "Projectile"],
		"requires_any_tag": true,
		"damage_more": -0.05,
		"mana_more": 0.08,
		"cooldown_more": -0.18,
		"spirit_more": 0.10,
		"flags": ["fast_casting"],
		"preview_lines": ["Lower cooldown", "Slightly less hit damage"],
		"description": "Lower cooldown. Slightly less damage."
	},
	"chain": {
		"name": "Chain Support",
		"short_name": "Chain",
		"tags": ["Support", "Projectile", "Lightning"],
		"compatible_tags": ["Projectile", "Lightning", "Chain"],
		"requires_any_tag": true,
		"damage_more": -0.10,
		"mana_more": 0.22,
		"cooldown_more": 0.04,
		"spirit_more": 0.18,
		"chain_count": 2,
		"flags": ["chain_plus"],
		"preview_lines": ["+2 Chain", "Less direct hit damage", "Higher mana cost"],
		"description": "Projectile and Lightning skills chain to additional enemies."
	},
	"area_expansion": {
		"name": "Area Expansion Support",
		"short_name": "Area+",
		"tags": ["Support", "Area"],
		"compatible_tags": ["Area"],
		"requires_any_tag": true,
		"damage_more": -0.07,
		"mana_more": 0.18,
		"cooldown_more": 0.06,
		"spirit_more": 0.16,
		"radius_more": 0.28,
		"flags": ["larger_area"],
		"preview_lines": ["Larger area", "Slight damage penalty"],
		"description": "Area skills become larger and easier to use."
	},
	"burning": {
		"name": "Burning Support",
		"short_name": "Burning",
		"tags": ["Support", "Fire", "Ailment"],
		"compatible_tags": ["Fire"],
		"requires_any_tag": true,
		"damage_more": 0.10,
		"mana_more": 0.10,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"status_power": 0.40,
		"flags": ["strong_burn"],
		"preview_lines": ["Stronger Burn", "More Fire pressure"],
		"description": "Fire skills apply stronger Burn."
	},
	"frostbite": {
		"name": "Frostbite Support",
		"short_name": "Frostbite",
		"tags": ["Support", "Cold", "Control"],
		"compatible_tags": ["Cold"],
		"requires_any_tag": true,
		"damage_more": 0.08,
		"mana_more": 0.12,
		"cooldown_more": 0.00,
		"spirit_more": 0.12,
		"status_power": 0.35,
		"flags": ["strong_freeze"],
		"preview_lines": ["Stronger Freeze", "Longer slow control"],
		"description": "Cold skills freeze harder and slow longer."
	},
	"overcharge": {
		"name": "Overcharge Support",
		"short_name": "Overcharge",
		"tags": ["Support", "Lightning", "Proc"],
		"compatible_tags": ["Lightning"],
		"requires_any_tag": true,
		"damage_more": 0.06,
		"mana_more": 0.18,
		"cooldown_more": 0.02,
		"spirit_more": 0.14,
		"chain_count": 1,
		"flags": ["shock_burst"],
		"preview_lines": ["Shock burst", "+1 Chain", "Higher cost"],
		"description": "Lightning skills shock and burst into extra chain damage."
	},
	"void_echo": {
		"name": "Void Echo Support",
		"short_name": "Void Echo",
		"tags": ["Support", "Void", "Proc"],
		"compatible_tags": ["Void"],
		"requires_any_tag": true,
		"damage_more": 0.08,
		"mana_more": 0.16,
		"cooldown_more": 0.06,
		"spirit_more": 0.14,
		"flags": ["void_echo"],
		"preview_lines": ["Second weaker pulse", "Better curse pressure"],
		"description": "Void skills echo for a weaker second pulse."
	},
	"trap_mechanism": {
		"name": "Trap Mechanism Support",
		"short_name": "Trap Mech",
		"tags": ["Support", "Trap"],
		"compatible_tags": ["Trap", "Area"],
		"requires_any_tag": true,
		"damage_more": 0.14,
		"mana_more": 0.16,
		"cooldown_more": 0.04,
		"spirit_more": 0.15,
		"flags": ["trap_damage", "secondary_trap_tick"],
		"preview_lines": ["Secondary damage tick", "Better placed area damage"],
		"description": "Trap and placed area skills gain a secondary damage tick."
	},
	"bloodletting": {
		"name": "Bloodletting Support",
		"short_name": "Bleed",
		"tags": ["Support", "Physical", "Bleed"],
		"compatible_tags": ["Physical", "Melee", "Trap"],
		"requires_any_tag": true,
		"damage_more": 0.10,
		"mana_more": 0.08,
		"cooldown_more": 0.00,
		"spirit_more": 0.10,
		"status_power": 0.35,
		"flags": ["strong_bleed"],
		"preview_lines": ["Stronger Bleed", "Improves physical damage identity"],
		"description": "Physical, melee, and trap skills apply stronger Bleed."
	},
	"critical_focus": {
		"name": "Critical Focus Support",
		"short_name": "Crit Focus",
		"tags": ["Support", "Critical"],
		"compatible_tags": ["Projectile", "Melee", "Spell", "Trap", "Hit"],
		"requires_any_tag": true,
		"damage_more": 0.05,
		"mana_more": 0.10,
		"cooldown_more": 0.00,
		"spirit_more": 0.10,
		"crit_chance_more": 0.10,
		"flags": ["critical_focus"],
		"preview_lines": ["Higher critical chance", "Better proc setups"],
		"description": "Higher critical pressure and better proc setups."
	},
	"mana_efficiency": {
		"name": "Mana Efficiency Support",
		"short_name": "Efficient",
		"tags": ["Support", "Resource"],
		"compatible_tags": ["Spell", "Projectile", "Area", "Melee", "Trap", "Spirit", "Aura"],
		"requires_any_tag": true,
		"damage_more": -0.04,
		"mana_more": -0.22,
		"cooldown_more": 0.00,
		"spirit_more": -0.12,
		"flags": ["efficient"],
		"preview_lines": ["Lower cost/reservation", "Slightly less damage"],
		"description": "Lower cost and reservation. Slightly less damage."
	},
	"multi_projectile": {
		"name": "Split Projectile Support",
		"short_name": "Split",
		"tags": ["Support", "Projectile"],
		"compatible_tags": ["Projectile"],
		"requires_any_tag": true,
		"damage_more": -0.18,
		"mana_more": 0.24,
		"cooldown_more": 0.02,
		"spirit_more": 0.18,
		"extra_projectiles": 2,
		"flags": ["split_projectile"],
		"preview_lines": ["+2 Projectiles", "Reduced hit damage", "Higher cost"],
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
