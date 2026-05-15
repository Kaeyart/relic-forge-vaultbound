class_name RVGemDB
extends RefCounted

const ACTIVE_GEMS = {
	"Fireball":{"tags":["Fire","Projectile","Spell","Hit"],"base_sockets":2,"spirit":0},
	"Cleave":{"tags":["Physical","Melee","Slash","Hit"],"base_sockets":2,"spirit":0},
	"Frost Nova":{"tags":["Cold","Area","Spell","Freeze"],"base_sockets":2,"spirit":0},
	"Storm Lance":{"tags":["Lightning","Projectile","Spell","Chain","Hit"],"base_sockets":2,"spirit":0},
	"Void Rift":{"tags":["Void","Area","Spell","Curse"],"base_sockets":2,"spirit":0},
	"Blade Trap":{"tags":["Trap","Physical","Area","Hit"],"base_sockets":2,"spirit":0}
}

const SUPPORT_GEMS = {
	"scatter":{"name":"Scatter", "tags":["Projectile"], "cost_multi":1.18, "damage_multi":0.82, "extra_projectiles":2, "desc":"Projectiles split into extra weaker shots."},
	"chain":{"name":"Chain", "tags":["Projectile","Lightning"], "cost_multi":1.22, "damage_multi":0.88, "chain_count":2, "desc":"Hits seek additional enemies."},
	"brutality":{"name":"Brutality", "tags":["Physical","Melee"], "cost_multi":1.12, "damage_multi":1.28, "desc":"More physical damage."},
	"ignite":{"name":"Ignite", "tags":["Fire","Hit"], "cost_multi":1.10, "damage_multi":1.08, "status":"burn", "desc":"Hits burn enemies."},
	"hypothermia":{"name":"Hypothermia", "tags":["Cold","Freeze"], "cost_multi":1.14, "damage_multi":1.12, "freeze_bonus":0.35, "desc":"Cold skills freeze harder."},
	"overcharge":{"name":"Overcharge", "tags":["Lightning","Spell"], "cost_multi":1.30, "damage_multi":1.34, "desc":"Much higher damage and cost."},
	"controlled_destruction":{"name":"Controlled Destruction", "tags":["Spell"], "cost_multi":1.16, "damage_multi":1.22, "desc":"More spell damage."},
	"area_echo":{"name":"Area Echo", "tags":["Area"], "cost_multi":1.25, "damage_multi":0.90, "repeat_zone":1, "desc":"Area skill echoes once."},
	"blood_price":{"name":"Blood Price", "tags":["Spell","Melee","Hit"], "cost_multi":0.70, "damage_multi":1.18, "life_cost":6.0, "desc":"Spend life to empower skills."},
	"swift_cast":{"name":"Swift Cast", "tags":["Spell","Projectile","Melee","Area"], "cost_multi":1.08, "damage_multi":0.92, "cooldown_multi":0.78, "desc":"Faster cooldown."},
	"trap_cache":{"name":"Trap Cache", "tags":["Trap"], "cost_multi":1.20, "damage_multi":1.05, "extra_trap":1, "desc":"Places an extra trap."},
	"curse_brand":{"name":"Curse Brand", "tags":["Void","Curse","Spell"], "cost_multi":1.16, "damage_multi":1.10, "curse_bonus":1, "desc":"Cursed enemies take more damage."}
}

const SPIRIT_GEMS = {
	"ember_familiar":{"name":"Ember Familiar", "reservation":20, "stats":{"fire_damage":0.16}, "flags":["spirit_ember_familiar"], "desc":"Fire casts gain ember follow-up chance."},
	"frost_guard":{"name":"Frost Guard", "reservation":25, "stats":{"max_hp":22.0,"cold_damage":0.08}, "flags":["spirit_frost_guard"], "desc":"Defense and cold control."},
	"storm_choir":{"name":"Storm Choir", "reservation":30, "stats":{"lightning_damage":0.18,"cooldown_reduction":0.04}, "flags":["spirit_storm_choir"], "desc":"Lightning chain engine."},
	"void_ward":{"name":"Void Ward", "reservation":35, "stats":{"void_damage":0.18,"max_mana":20.0}, "flags":["spirit_void_ward"], "desc":"Void scaling and mana."},
	"blood_pact":{"name":"Blood Pact", "reservation":20, "stats":{"global_damage":0.10,"max_hp":-15.0}, "flags":["spirit_blood_pact"], "desc":"Damage for safety."}
}

static func support_compatible(skill: String, support_id: String) -> bool:
	if not ACTIVE_GEMS.has(skill) or not SUPPORT_GEMS.has(support_id):
		return false
	var skill_tags: Array = ACTIVE_GEMS[skill].get("tags", [])
	var support_tags: Array = SUPPORT_GEMS[support_id].get("tags", [])
	for tag in support_tags:
		if skill_tags.has(str(tag)):
			return true
	return false

static func socket_count_for_skill(skill: String, skill_rank: int) -> int:
	var base_count: int = int(ACTIVE_GEMS.get(skill, {}).get("base_sockets", 2))
	return clamp(base_count + int(skill_rank / 3), 1, 5)

static func support_ids() -> Array:
	return SUPPORT_GEMS.keys()

static func spirit_ids() -> Array:
	return SPIRIT_GEMS.keys()
