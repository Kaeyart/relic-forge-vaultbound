class_name RVLootDropSystem
extends RefCounted

# Patch 084A: tuned drop economy for the current ARPG loop.
# Produces filterable payloads for ground loot and handles pickup storage.

const BASES: Array[Dictionary] = [
	{"base_id":"rusted_sword", "base_type":"Rusted Sword", "slot":"weapon", "tags":["weapon","attack","melee","physical"], "min_level":1, "weight":100, "implicit":{"Melee Damage":0.04}},
	{"base_id":"iron_axe", "base_type":"Iron Axe", "slot":"weapon", "tags":["weapon","attack","melee","physical","bleed"], "min_level":3, "weight":80, "implicit":{"Melee Damage":0.08}},
	{"base_id":"ember_wand", "base_type":"Ember Wand", "slot":"weapon", "tags":["weapon","spell","caster","fire"], "min_level":4, "weight":75, "implicit":{"Spell Damage":0.06,"Fire Damage":0.04}},
	{"base_id":"storm_scepter", "base_type":"Storm Scepter", "slot":"weapon", "tags":["weapon","spell","caster","lightning"], "min_level":8, "weight":55, "implicit":{"Spell Damage":0.08,"Lightning Damage":0.06}},
	{"base_id":"iron_helm", "base_type":"Iron Helm", "slot":"head", "tags":["armor","defense"], "min_level":1, "weight":90, "implicit":{"Armor":12}},
	{"base_id":"chain_chest", "base_type":"Chain Chest", "slot":"chest", "tags":["armor","defense"], "min_level":2, "weight":95, "implicit":{"Armor":24}},
	{"base_id":"trapwright_grips", "base_type":"Trapwright Grips", "slot":"gloves", "tags":["armor","trap","utility"], "min_level":5, "weight":60, "implicit":{"Trap Damage":0.05}},
	{"base_id":"runner_boots", "base_type":"Runner Boots", "slot":"boots", "tags":["armor","movement"], "min_level":4, "weight":85, "implicit":{"Movement Speed":0.03}},
	{"base_id":"opal_ring", "base_type":"Opal Ring", "slot":"ring", "tags":["jewelry","spell","elemental"], "min_level":5, "weight":70, "implicit":{"Spell Damage":0.04}},
	{"base_id":"blood_amulet", "base_type":"Blood Amulet", "slot":"amulet", "tags":["jewelry","life","damage"], "min_level":7, "weight":60, "implicit":{"Maximum Life":14}},
	{"base_id":"relic_core", "base_type":"Relic Core", "slot":"relic", "tags":["relic","utility","resource"], "min_level":10, "weight":45, "implicit":{"Cooldown Reduction":0.025}}
]

const ACTIVE_GEMS: Array[String] = ["Fireball", "Storm Lance", "Cleave", "Frost Nova", "Void Rift", "Blade Trap"]
const SUPPORT_GEMS: Array[String] = ["Fork", "Chain", "Close Combat", "Burning", "Freezing", "Echo", "Larger Area", "Extra Projectile"]
const SPIRIT_GEMS: Array[String] = ["Ember Familiar", "Ward Spirit", "Blood Pact", "Storm Sigil"]
const MAP_IDS: Array[String] = ["ash_cistern", "iron_catacomb", "forgeworks", "bastion", "sanctum", "depths", "aqueducts", "vault", "stronghold", "ossuary"]

static func enemy_drop_payloads(state: Object, enemy: Object, activity: Dictionary = {}) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = _rng(state)
	var drops: Array[Dictionary] = []
	var level: int = _drop_level(state, enemy, activity)
	var boss: bool = _obj_bool(enemy, "is_map_boss", false)
	var elite: bool = _obj_bool(enemy, "is_elite", false)
	var kind: String = str(activity.get("kind", ""))
	var map_item: Dictionary = Dictionary(activity.get("map", {}))

	# Gold and basic resources keep the map grind flowing without forcing manual clicks.
	var gold_chance: float = 0.64
	if elite:
		gold_chance = 0.92
	if boss:
		gold_chance = 1.0
	if rng.randf() <= gold_chance:
		var gold_amount: int = _gold_amount(rng, level, elite, boss, map_item)
		drops.append(_gold_payload(gold_amount))

	var material_chance: float = 0.13 + float(level) * 0.0018
	if kind == "map":
		material_chance += 0.07
	if elite:
		material_chance += 0.18
	if boss:
		material_chance = 1.0
	if rng.randf() <= clampf(material_chance, 0.0, 1.0):
		drops.append(_material_payload(rng, level, elite, boss, map_item))

	# Equipment: normal packs sometimes drop projects; elites and bosses carry the economy.
	var equipment_rolls: int = 0
	var equipment_chance: float = 0.16 + min(0.10, float(level) * 0.0015)
	if elite:
		equipment_chance = 0.78
	if boss:
		equipment_chance = 1.0
	if rng.randf() <= equipment_chance:
		equipment_rolls = 1
	if boss:
		equipment_rolls = 2
	elif elite and rng.randf() < 0.18:
		equipment_rolls = 2
	for _i: int in range(equipment_rolls):
		var item: Dictionary = roll_equipment_drop(state, level, _rarity_for_drop(rng, elite, boss, map_item), activity)
		drops.append(_item_payload(item))

	# Gems were too invisible. They now have explicit sanity-drop pressure.
	var gem_chance: float = 0.018
	if elite:
		gem_chance = 0.085
	if boss:
		gem_chance = 0.34
	if rng.randf() <= gem_chance:
		drops.append(_item_payload(roll_skill_gem_drop(rng, level, boss)))

	# Flask upgrades are rare from packs, plausible from elites, and visible from bosses.
	var flask_chance: float = 0.006
	if elite:
		flask_chance = 0.035
	if boss:
		flask_chance = 0.18
	if rng.randf() <= flask_chance:
		drops.append(_flask_upgrade_payload(rng, level))

	# Maps should sustain mapping, but bosses/elites are the reliable source.
	var map_chance: float = 0.012
	if kind == "map":
		map_chance = 0.028
	if elite:
		map_chance += 0.07
	if boss:
		map_chance = 0.48
	if rng.randf() <= map_chance:
		drops.append(_item_payload(roll_map_drop(rng, level, map_item, boss)))

	return drops

static func pickup_payload(state: Object, payload: Dictionary) -> String:
	if state == null or payload.is_empty():
		return ""
	var kind: String = str(payload.get("kind", payload.get("type", "item")))
	match kind:
		"gold":
			var amount: int = max(1, int(payload.get("amount", 1)))
			_set_if_possible(state, "gold", int(_state_get(state, "gold", 0)) + amount)
			return "+" + str(amount) + " gold"
		"material", "currency":
			var material_id: String = str(payload.get("id", payload.get("material_id", "crafting_shards")))
			var count: int = max(1, int(payload.get("amount", 1)))
			var materials: Dictionary = Dictionary(_state_get(state, "materials", {}))
			materials[material_id] = int(materials.get(material_id, 0)) + count
			_set_if_possible(state, "materials", materials)
			return "+" + str(count) + " " + _display_id(material_id)
		"flask_upgrade":
			return _apply_flask_upgrade(state, payload)
		"item", "equipment", "gem", "map", "skill_gem":
			var item: Dictionary = Dictionary(payload.get("item", payload))
			_add_to_backpack(state, item)
			return "Picked up " + str(item.get("name", payload.get("label", "Item")))
		_:
			if payload.has("item") and typeof(payload.get("item")) == TYPE_DICTIONARY:
				var fallback_item: Dictionary = Dictionary(payload.get("item"))
				_add_to_backpack(state, fallback_item)
				return "Picked up " + str(fallback_item.get("name", "Item"))
	return ""

static func roll_equipment_drop(state: Object, item_level: int, rarity: String = "", activity: Dictionary = {}) -> Dictionary:
	var rng: RandomNumberGenerator = _rng(state)
	var level: int = max(1, item_level)
	var chosen_rarity: String = rarity if rarity != "" else _rarity_for_drop(rng, false, false, Dictionary(activity.get("map", {})))
	var base: Dictionary = _pick_base(rng, level, Dictionary(activity.get("map", {})))
	if chosen_rarity == "Unique":
		var unique_item: Dictionary = _try_unique_item(rng, level)
		if not unique_item.is_empty():
			return unique_item
		chosen_rarity = "Rare"
	var prefixes: Array = []
	var suffixes: Array = []
	var existing_groups: Array[String] = []
	var affix_count: int = _affix_count_for_rarity(rng, chosen_rarity)
	for index: int in range(affix_count):
		var affix_type: String = "prefix" if prefixes.size() <= suffixes.size() else "suffix"
		if prefixes.size() >= 3:
			affix_type = "suffix"
		if suffixes.size() >= 3:
			affix_type = "prefix"
		var affix: Dictionary = RVItemAffixDB.random_affix(rng, affix_type, str(base.get("slot", "weapon")), level, existing_groups, Array(base.get("tags", [])))
		if affix.is_empty():
			continue
		existing_groups.append(str(affix.get("group", affix.get("id", ""))))
		if affix_type == "prefix":
			prefixes.append(affix)
		else:
			suffixes.append(affix)
	var implicit_stats: Dictionary = Dictionary(base.get("implicit", {}))
	var total_stats: Dictionary = _aggregate_stats(implicit_stats, prefixes, suffixes, {})
	var base_name: String = str(base.get("base_type", "Item"))
	var item_name: String = RVItemAffixDB.item_name_for(base_name, chosen_rarity, prefixes, suffixes)
	var fp_max: int = _forge_potential_max(rng, chosen_rarity, level)
	return {
		"uid": _uid("item"),
		"item_type": "equipment",
		"type": "equipment",
		"category": "gear",
		"base_id": str(base.get("base_id", "base")),
		"base_type": base_name,
		"slot": str(base.get("slot", "weapon")),
		"name": item_name,
		"rarity": chosen_rarity,
		"item_level": level,
		"required_level": max(1, min(level, int(round(float(level) * 0.82)))),
		"implicit_mods": [],
		"implicit_stats": implicit_stats,
		"prefixes": prefixes,
		"suffixes": suffixes,
		"crafted_mods": [],
		"sealed_mods": [],
		"tags": Array(base.get("tags", [])).duplicate(true),
		"affix_tags": RVItemAffixDB.affix_tags(prefixes, suffixes, []),
		"forge_potential": fp_max,
		"max_forge_potential": fp_max,
		"quality": 0,
		"corrupted": false,
		"stats": total_stats,
		"total_stats": total_stats,
		"best_affix_tier": RVItemAffixDB.best_affix_tier({"prefixes": prefixes, "suffixes": suffixes, "crafted_mods": []})
	}

static func roll_skill_gem_drop(rng: RandomNumberGenerator, item_level: int, boss: bool = false) -> Dictionary:
	var bucket_roll: float = rng.randf()
	var gem_type: String = "active"
	var name_pool: Array[String] = ACTIVE_GEMS
	if bucket_roll > 0.72 and not boss:
		gem_type = "support"
		name_pool = SUPPORT_GEMS
	elif bucket_roll > 0.86:
		gem_type = "spirit"
		name_pool = SPIRIT_GEMS
	var gem_name: String = name_pool[rng.randi_range(0, name_pool.size() - 1)]
	var gem_level: int = max(1, min(20, int(floor(float(item_level) / 10.0)) + 1))
	return {
		"uid": _uid("gem"),
		"item_type": "skill_gem",
		"category": "gem",
		"type": gem_type,
		"gem_type": gem_type,
		"name": gem_name,
		"rarity": "Gem",
		"item_level": item_level,
		"level": gem_level,
		"gem_level": gem_level,
		"xp": 0,
		"gem_xp": 0,
		"required_xp": int(round(85.0 + pow(float(gem_level), 1.55) * 35.0)),
		"tags": [gem_type, "gem"],
		"affix_tags": [gem_type, "gem"]
	}

static func roll_map_drop(rng: RandomNumberGenerator, item_level: int, source_map: Dictionary = {}, boss: bool = false) -> Dictionary:
	var source_tier: int = max(1, int(source_map.get("tier", source_map.get("map_tier", max(1, int(round(float(item_level) / 5.0)))))))
	var tier_delta: int = 0
	if boss and rng.randf() < 0.32:
		tier_delta = 1
	elif rng.randf() < 0.10:
		tier_delta = -1
	var tier: int = clampi(source_tier + tier_delta, 1, 16)
	var map_id: String = MAP_IDS[rng.randi_range(0, MAP_IDS.size() - 1)]
	var map_name: String = _display_id(map_id) + " Map"
	var rarity: String = "Normal"
	var roll: float = rng.randf()
	if roll < 0.08:
		rarity = "Rare"
	elif roll < 0.28:
		rarity = "Magic"
	return {
		"uid": _uid("map"),
		"item_type": "map",
		"type": "map",
		"category": "map",
		"map_id": map_id,
		"name": "T" + str(tier) + " " + map_name,
		"rarity": rarity,
		"tier": tier,
		"map_tier": tier,
		"map_level": 1 + tier * 4,
		"area_level": 1 + tier * 4,
		"item_level": max(item_level, 1 + tier * 4),
		"completed": false,
		"tags": ["map", map_id],
		"affix_tags": ["map", map_id]
	}

static func _try_unique_item(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var unique_def: Dictionary = RVItemAffixDB.random_unique_for_level(rng, level)
	if unique_def.is_empty():
		return {}
	var stats: Dictionary = Dictionary(unique_def.get("stats", {}))
	return {
		"uid": _uid("unique"),
		"item_type": "equipment",
		"type": "equipment",
		"category": "gear",
		"base_id": str(unique_def.get("base_id", "unique_base")),
		"base_type": str(unique_def.get("base_id", "Unique Base")).capitalize(),
		"slot": "weapon",
		"name": str(unique_def.get("name", "Unique Item")),
		"rarity": "Unique",
		"item_level": level,
		"required_level": int(unique_def.get("required_level", 1)),
		"stats": stats,
		"total_stats": stats,
		"unique_effects": Array(unique_def.get("unique_effects", [])),
		"build_flags": Array(unique_def.get("build_flags", [])),
		"description": str(unique_def.get("description", "")),
		"forge_potential": 0,
		"max_forge_potential": 0,
		"tags": ["unique"],
		"affix_tags": ["unique"]
	}

static func _drop_level(state: Object, enemy: Object, activity: Dictionary) -> int:
	var map_item: Dictionary = Dictionary(activity.get("map", {}))
	if not map_item.is_empty():
		return max(1, int(map_item.get("map_level", map_item.get("area_level", map_item.get("item_level", _state_get(state, "level", 1))))))
	var enemy_level: int = int(_obj_get(enemy, "level", 0))
	if enemy_level > 0:
		return enemy_level
	return max(1, int(_state_get(state, "level", 1)))

static func _rarity_for_drop(rng: RandomNumberGenerator, elite: bool, boss: bool, map_item: Dictionary) -> String:
	var rare_bonus: float = 0.0
	var unique_bonus: float = 0.0
	var map_rarity: String = str(map_item.get("rarity", "Normal"))
	if map_rarity == "Magic":
		rare_bonus += 0.035
	elif map_rarity == "Rare":
		rare_bonus += 0.080
		unique_bonus += 0.006
	elif map_rarity == "Unique":
		rare_bonus += 0.120
		unique_bonus += 0.012
	var roll: float = rng.randf()
	if boss:
		if roll < 0.060 + unique_bonus:
			return "Unique"
		if roll < 0.760 + rare_bonus:
			return "Rare"
		return "Magic"
	if elite:
		if roll < 0.018 + unique_bonus:
			return "Unique"
		if roll < 0.460 + rare_bonus:
			return "Rare"
		if roll < 0.890:
			return "Magic"
		return "Normal"
	if roll < 0.004 + unique_bonus:
		return "Unique"
	if roll < 0.105 + rare_bonus:
		return "Rare"
	if roll < 0.565:
		return "Magic"
	return "Normal"

static func _affix_count_for_rarity(rng: RandomNumberGenerator, rarity: String) -> int:
	match rarity:
		"Normal": return 0
		"Magic": return 1 + (1 if rng.randf() < 0.45 else 0)
		"Rare": return rng.randi_range(4, 6)
	return 0

static func _pick_base(rng: RandomNumberGenerator, level: int, map_item: Dictionary = {}) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for base: Dictionary in BASES:
		if int(base.get("min_level", 1)) <= level:
			candidates.append(base)
	if candidates.is_empty():
		candidates.append(BASES[0])
	var total: int = 0
	for candidate: Dictionary in candidates:
		total += max(1, int(candidate.get("weight", 1)))
	var roll: int = rng.randi_range(1, max(1, total))
	var running: int = 0
	for candidate2: Dictionary in candidates:
		running += max(1, int(candidate2.get("weight", 1)))
		if roll <= running:
			return candidate2.duplicate(true)
	return candidates[0].duplicate(true)

static func _forge_potential_max(rng: RandomNumberGenerator, rarity: String, level: int) -> int:
	var level_bonus: int = int(clamp(float(level) * 0.12, 0.0, 10.0))
	match rarity:
		"Normal": return rng.randi_range(30, 46) + level_bonus
		"Magic": return rng.randi_range(24, 40) + level_bonus
		"Rare": return rng.randi_range(14, 30) + int(level_bonus * 0.7)
	return 0

static func _gold_amount(rng: RandomNumberGenerator, level: int, elite: bool, boss: bool, map_item: Dictionary) -> int:
	var base: int = rng.randi_range(4, 10) + int(level * 0.55)
	if elite:
		base *= rng.randi_range(3, 5)
	if boss:
		base *= rng.randi_range(9, 14)
	var rarity: String = str(map_item.get("rarity", "Normal"))
	if rarity == "Rare":
		base = int(round(float(base) * 1.25))
	elif rarity == "Unique":
		base = int(round(float(base) * 1.40))
	return max(1, base)

static func _material_payload(rng: RandomNumberGenerator, level: int, elite: bool, boss: bool, map_item: Dictionary) -> Dictionary:
	var ids: Array[String] = ["crafting_shards", "rune_etches", "scouring_ash", "essence_dust"]
	if level >= 12:
		ids.append("regal_embers")
	if level >= 24:
		ids.append("chaos_embers")
	if boss or level >= 35:
		ids.append("exalted_shards")
	var id: String = ids[rng.randi_range(0, ids.size() - 1)]
	var amount: int = 1
	if boss:
		amount = rng.randi_range(2, 5)
	elif elite:
		amount = rng.randi_range(1, 3)
	return {"kind":"material", "type":"material", "item_type":"material", "id":id, "name":_display_id(id), "label":str(amount) + " " + _display_id(id), "amount":amount, "auto_pickup":true, "rarity":"Currency", "affix_tags":["currency","crafting"]}

static func _flask_upgrade_payload(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var flask_type: String = "health" if rng.randf() < 0.52 else "mana"
	var upgrade_pool: Array[String] = ["max_charges", "recovery", "charge_gain"]
	var upgrade: String = upgrade_pool[rng.randi_range(0, upgrade_pool.size() - 1)]
	var name: String = ("Health" if flask_type == "health" else "Mana") + " Flask " + _display_id(upgrade)
	return {"kind":"flask_upgrade", "type":"flask_upgrade", "item_type":"flask_upgrade", "flask_type":flask_type, "upgrade":upgrade, "amount":1, "item_level":level, "name":name, "label":name, "rarity":"Magic", "auto_pickup":false, "affix_tags":["flask", flask_type, upgrade]}

static func _apply_flask_upgrade(state: Object, payload: Dictionary) -> String:
	var flask_type: String = str(payload.get("flask_type", "health"))
	var upgrade: String = str(payload.get("upgrade", "max_charges"))
	var prefix: String = flask_type + "_flask_"
	match upgrade:
		"max_charges":
			var max_key: String = prefix + "max_charges"
			var max_charges: int = int(_state_get(state, max_key, 3)) + 1
			_set_if_possible(state, max_key, max_charges)
			_set_if_possible(state, prefix + "charges", max_charges)
			return _display_id(flask_type) + " Flask gained +1 max charge"
		"recovery":
			var recovery_key: String = prefix + "recovery"
			_set_if_possible(state, recovery_key, float(_state_get(state, recovery_key, 0.35)) + 0.08)
			return _display_id(flask_type) + " Flask recovery improved"
		"charge_gain":
			var gain_key: String = "flask_charge_gain_bonus"
			_set_if_possible(state, gain_key, float(_state_get(state, gain_key, 0.0)) + 0.08)
			return "Flask charge gain improved"
	return "Flask upgraded"

static func _gold_payload(amount: int) -> Dictionary:
	return {"kind":"gold", "type":"gold", "item_type":"gold", "name":"Gold", "label":str(amount) + " Gold", "amount":amount, "auto_pickup":true, "rarity":"Currency", "affix_tags":["gold","currency"]}

static func _item_payload(item: Dictionary) -> Dictionary:
	var kind: String = str(item.get("item_type", item.get("type", "item")))
	return {"kind":"item", "type":kind, "item_type":kind, "item":item, "name":str(item.get("name", "Item")), "label":str(item.get("name", "Item")), "rarity":str(item.get("rarity", "Normal")), "item_level":int(item.get("item_level", 1)), "auto_pickup":false, "affix_tags":Array(item.get("affix_tags", item.get("tags", [])))}

static func _add_to_backpack(state: Object, item: Dictionary) -> void:
	var backpack: Array = Array(_state_get(state, "backpack", []))
	backpack.append(item)
	_set_if_possible(state, "backpack", backpack)

static func _aggregate_stats(base_stats: Dictionary, prefixes: Array, suffixes: Array, extra_stats: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	_add_stats(result, base_stats)
	for affix_value: Variant in prefixes + suffixes:
		if typeof(affix_value) == TYPE_DICTIONARY:
			_add_stats(result, Dictionary(affix_value).get("stats", {}))
	_add_stats(result, extra_stats)
	return result

static func _add_stats(target: Dictionary, source: Dictionary) -> void:
	for key_value: Variant in source.keys():
		var key: String = str(key_value)
		target[key] = float(target.get(key, 0.0)) + float(source[key_value])

static func _rng(state: Object) -> RandomNumberGenerator:
	var value: Variant = _state_get(state, "rng", null)
	if value is RandomNumberGenerator:
		return value as RandomNumberGenerator
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng

static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value

static func _set_if_possible(state: Object, key: String, value: Variant) -> void:
	if state != null:
		state.set(key, value)

static func _obj_get(obj: Object, key: String, fallback: Variant = null) -> Variant:
	if obj == null:
		return fallback
	var value: Variant = obj.get(key)
	return fallback if value == null else value

static func _obj_bool(obj: Object, key: String, fallback: bool = false) -> bool:
	return bool(_obj_get(obj, key, fallback))

static func _display_id(id: String) -> String:
	var text: String = id.replace("_", " ")
	return text.capitalize()

static func _uid(prefix: String) -> String:
	return prefix + "_" + str(Time.get_ticks_msec()) + "_" + str(randi())
