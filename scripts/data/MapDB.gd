class_name RVMapDB
extends RefCounted

const MAP_TEMPLATES: Array[Dictionary] = [
	{"id":"ash_cistern","name":"Ash Cistern","area_name":"Cistern of Ash","layout_id":"ash_cistern_winding","biome":"Ash Intake","boss_name":"Cinder Warden","boss_id":"cinder_warden","enemy_mix":["Grunt","Archer","Spitter"],"pack_size":1.08,"threat":1.0,"mods":["Smoldering halls","Extra fire packs"],"description":"A furnace-drain route with winding ash chambers and a cinder boss."},
	{"id":"iron_catacomb","name":"Iron Catacomb","area_name":"Catacomb of Chains","layout_id":"iron_catacomb_branching","biome":"Iron Catacombs","boss_name":"Chain Brute","boss_id":"chain_brute","enemy_mix":["Grunt","Brute","Archer"],"pack_size":1.18,"threat":1.12,"mods":["Armored enemies","More melee pressure"],"description":"A chained burial route built around bruisers, choke points, and side chambers."},
	{"id":"void_chapel","name":"Void Chapel","area_name":"Chapel of the Hollow Star","layout_id":"void_chapel_loop","biome":"Void Chapel","boss_name":"Abyss Deacon","boss_id":"abyss_deacon","enemy_mix":["Spitter","Archer","Grunt"],"pack_size":1.05,"threat":1.26,"mods":["Void casters","Higher gem chance"],"description":"A caster-heavy chapel map for testing ranged pressure, Void builds, and gem rewards."},
	{"id":"storm_foundry","name":"Storm Foundry","area_name":"Foundry of Charged Steel","layout_id":"storm_foundry_forked","biome":"Storm Foundry","boss_name":"Stormforged Behemoth","boss_id":"stormforged_behemoth","enemy_mix":["Archer","Brute","Spitter","Grunt"],"pack_size":1.28,"threat":1.36,"mods":["Large packs","Boss has heavy pressure"],"description":"A denser foundry route for testing clear speed, elite pressure, and boss loot."}
]

const MAP_RARITY_WEIGHTS: Dictionary = {"Normal":52,"Magic":34,"Rare":14}

static func template_by_id(template_id: String) -> Dictionary:
	for template: Dictionary in MAP_TEMPLATES:
		if str(template.get("id", "")) == template_id:
			return template.duplicate(true)
	return MAP_TEMPLATES[0].duplicate(true)

static func roll_template(rng: RandomNumberGenerator, forced_id: String = "") -> Dictionary:
	if forced_id != "":
		return template_by_id(forced_id)
	return MAP_TEMPLATES[rng.randi_range(0, MAP_TEMPLATES.size() - 1)].duplicate(true)

static func _roll_rarity(rng: RandomNumberGenerator) -> String:
	var total_weight: int = 0
	for value: Variant in MAP_RARITY_WEIGHTS.values():
		total_weight += int(value)
	var roll: int = rng.randi_range(1, max(1, total_weight))
	var running: int = 0
	for key: Variant in MAP_RARITY_WEIGHTS.keys():
		running += int(MAP_RARITY_WEIGHTS[key])
		if roll <= running:
			return str(key)
	return "Normal"

static func make_map(rng: RandomNumberGenerator, map_level: int = 1, forced_id: String = "") -> Dictionary:
	var template: Dictionary = roll_template(rng, forced_id)
	var level: int = max(1, map_level)
	var tier: int = clampi(int(ceil(float(level) / 8.0)), 1, 16)
	var rarity: String = _roll_rarity(rng)
	var threat: float = float(template.get("threat", 1.0)) + float(tier) * 0.045
	var pack_size: float = float(template.get("pack_size", 1.0))
	var mods: Array = Array(template.get("mods", [])).duplicate(true)
	var reward_bonus: float = 1.0
	var boss_bonus_drops: int = 0
	if rarity == "Magic":
		mods.append("Magic map: +12% monster pack size")
		mods.append("Magic map: +10% item quantity")
		pack_size += 0.12
		reward_bonus += 0.10
	elif rarity == "Rare":
		mods.append("Rare map: +22% monster pack size")
		mods.append("Rare map: boss drops +1 item")
		mods.append("Rare map: higher map sustain chance")
		pack_size += 0.22
		threat += 0.18
		reward_bonus += 0.22
		boss_bonus_drops = 1
	return {"uid":"map_" + str(Time.get_ticks_msec()) + "_" + str(rng.randi()),"type":"map","slot":"map","base_type":"Map","id":str(template.get("id","map")),"name":rarity + " " + str(template.get("name","Map")),"rarity":rarity,"map_level":level,"tier":tier,"area_name":str(template.get("area_name","Unknown Area")),"layout_id":str(template.get("layout_id", template.get("id", "map"))),"biome":str(template.get("biome","Unknown")),"boss_name":str(template.get("boss_name","Map Boss")),"boss_id":str(template.get("boss_id","map_boss")),"enemy_mix":Array(template.get("enemy_mix", ["Grunt"])).duplicate(true),"pack_size":pack_size,"threat":threat,"reward_bonus":reward_bonus,"boss_bonus_drops":boss_bonus_drops,"rooms":1,"mods":mods,"description":str(template.get("description","A map.")),"inv_w":2,"inv_h":2}
