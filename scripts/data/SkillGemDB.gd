class_name RVSkillGemDB
extends RefCounted

const SUPPORTS = {
	"Added Fire Damage": {"tags": ["Fire", "Spell", "Attack"], "desc": "More fire damage.", "stats": {"fire_damage": 0.18}, "cost_mult": 1.10, "cooldown_mult": 1.0},
	"Added Cold Damage": {"tags": ["Cold", "Spell", "Attack"], "desc": "More cold damage.", "stats": {"cold_damage": 0.18}, "cost_mult": 1.10, "cooldown_mult": 1.0},
	"Added Lightning Damage": {"tags": ["Lightning", "Spell", "Attack"], "desc": "More lightning damage.", "stats": {"lightning_damage": 0.18}, "cost_mult": 1.10, "cooldown_mult": 1.0},
	"Multiple Projectiles": {"tags": ["Projectile"], "desc": "Projectile skills fire extra shots with less damage.", "stats": {"extra_projectiles": 2.0, "less_damage": 0.25}, "cost_mult": 1.25, "cooldown_mult": 1.0},
	"Chain": {"tags": ["Projectile", "Lightning"], "desc": "Projectiles chain to another enemy.", "stats": {"chain_count": 1.0}, "cost_mult": 1.20, "cooldown_mult": 1.05},
	"Increased Area": {"tags": ["Area"], "desc": "Area skills are larger.", "stats": {"area_size": 0.28}, "cost_mult": 1.15, "cooldown_mult": 1.0},
	"Faster Casting": {"tags": ["Spell"], "desc": "Lower cooldown, higher mana cost.", "stats": {"cooldown_reduction": 0.16}, "cost_mult": 1.18, "cooldown_mult": 0.86},
	"Bleed Support": {"tags": ["Physical", "Attack"], "desc": "Physical attacks apply bleed.", "stats": {"bleed_chance": 1.0}, "cost_mult": 1.10, "cooldown_mult": 1.0},
	"Trap Cooldown": {"tags": ["Trap"], "desc": "Traps cool down faster.", "stats": {"cooldown_reduction": 0.20}, "cost_mult": 1.0, "cooldown_mult": 0.82},
	"Mana Efficiency": {"tags": ["Fire", "Cold", "Lightning", "Void", "Physical", "Trap", "Spell", "Attack"], "desc": "Skills cost less mana.", "stats": {"mana_cost_reduction": 0.20}, "cost_mult": 0.82, "cooldown_mult": 1.0}
}

const SPIRIT_GEMS = {
	"Fire Aura": {"reservation": 20, "desc": "Reserve spirit for more fire damage.", "stats": {"fire_damage": 0.16}},
	"Cold Aura": {"reservation": 20, "desc": "Reserve spirit for more cold damage.", "stats": {"cold_damage": 0.16}},
	"Storm Aura": {"reservation": 20, "desc": "Reserve spirit for more lightning damage.", "stats": {"lightning_damage": 0.16}},
	"Void Aura": {"reservation": 25, "desc": "Reserve spirit for more void damage.", "stats": {"void_damage": 0.18}},
	"Vitality Aura": {"reservation": 30, "desc": "Reserve spirit for more maximum life.", "stats": {"max_hp": 30.0}}
}

static func support_names() -> Array:
	return SUPPORTS.keys()

static func spirit_names() -> Array:
	return SPIRIT_GEMS.keys()

static func support_data(name: String) -> Dictionary:
	return SUPPORTS.get(name, {})

static func spirit_data(name: String) -> Dictionary:
	return SPIRIT_GEMS.get(name, {})

static func support_works_with_skill(support: String, skill: String) -> bool:
	var sd: Dictionary = support_data(support)
	var skill_tags: Array = RVSkillDB.tags(skill)
	for tag in sd.get("tags", []):
		if skill_tags.has(tag):
			return true
	return false
