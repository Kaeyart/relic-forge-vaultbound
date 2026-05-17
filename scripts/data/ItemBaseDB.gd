class_name RVItemBaseDB
extends RefCounted

const SLOT_ORDER: Array[String] = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]

const BASE_ITEMS: Dictionary = {
	"rusted_sword": {"name":"Rusted Sword", "slot":"weapon", "base_type":"Sword", "item_class":"One-Handed Sword", "min_level":1, "drop_weight":80, "dimensions":[2,3], "tags":["weapon","melee","attack","physical"], "implicit_stats":{"Melee Damage":0.06}},
	"iron_axe": {"name":"Iron Axe", "slot":"weapon", "base_type":"Axe", "item_class":"One-Handed Axe", "min_level":2, "drop_weight":70, "dimensions":[2,3], "tags":["weapon","melee","attack","physical","bleed"], "implicit_stats":{"Melee Damage":0.08}},
	"ember_wand": {"name":"Ember Wand", "slot":"weapon", "base_type":"Wand", "item_class":"Wand", "min_level":1, "drop_weight":75, "dimensions":[1,3], "tags":["weapon","spell","fire","caster"], "implicit_stats":{"Spell Damage":0.06,"Fire Damage":0.04}},
	"storm_focus": {"name":"Storm Focus", "slot":"offhand", "base_type":"Focus", "item_class":"Focus", "min_level":3, "drop_weight":55, "dimensions":[2,2], "tags":["offhand","spell","lightning","caster"], "implicit_stats":{"Spell Damage":0.05,"Lightning Damage":0.05}},
	"warden_shield": {"name":"Warden Shield", "slot":"offhand", "base_type":"Shield", "item_class":"Shield", "min_level":2, "drop_weight":58, "dimensions":[2,3], "tags":["offhand","defense","armor","block"], "implicit_stats":{"Armor":12.0,"Maximum Life":10.0}},
	"iron_helm": {"name":"Iron Helm", "slot":"head", "base_type":"Heavy Helmet", "item_class":"Helmet", "armor_class":"Heavy", "min_level":3, "drop_weight":70, "dimensions":[2,2], "tags":["armor","defense","heavy"], "implicit_stats":{"Armor":14.0}},
	"silk_robes": {"name":"Silk Robes", "slot":"chest", "base_type":"Caster Armor", "item_class":"Body Armor", "armor_class":"Caster", "min_level":4, "drop_weight":64, "dimensions":[2,3], "tags":["armor","spell","mana","caster"], "implicit_stats":{"Maximum Mana":18.0,"Spell Damage":0.03}},
	"plate_chest": {"name":"Plate Chest", "slot":"chest", "base_type":"Heavy Armor", "item_class":"Body Armor", "armor_class":"Heavy", "min_level":5, "drop_weight":62, "dimensions":[2,3], "tags":["armor","defense","heavy"], "implicit_stats":{"Armor":34.0}},
	"trapwright_grips": {"name":"Trapwright Grips", "slot":"gloves", "base_type":"Trap Gloves", "item_class":"Gloves", "min_level":8, "drop_weight":48, "dimensions":[2,2], "tags":["armor","trap","cooldown"], "implicit_stats":{"Trap Damage":0.05}},
	"travel_boots": {"name":"Travel Boots", "slot":"boots", "base_type":"Boots", "item_class":"Boots", "min_level":1, "drop_weight":76, "dimensions":[2,2], "tags":["armor","movement"], "implicit_stats":{"Movement Speed":0.03}},
	"opal_ring": {"name":"Opal Ring", "slot":"ring", "base_type":"Caster Ring", "item_class":"Ring", "min_level":6, "drop_weight":54, "dimensions":[1,1], "tags":["jewelry","spell","caster"], "implicit_stats":{"Spell Damage":0.04}},
	"bone_amulet": {"name":"Bone Amulet", "slot":"amulet", "base_type":"Amulet", "item_class":"Amulet", "min_level":1, "drop_weight":64, "dimensions":[1,1], "tags":["jewelry","damage"], "implicit_stats":{"Global Damage":0.03}},
	"relic_core": {"name":"Relic Core", "slot":"relic", "base_type":"Relic", "item_class":"Relic", "min_level":1, "drop_weight":58, "dimensions":[1,2], "tags":["relic","spirit"], "implicit_stats":{"Maximum Spirit":5.0}},
	"fractured_lantern": {"name":"Fractured Lantern", "slot":"relic", "base_type":"Lantern", "item_class":"Relic", "min_level":15, "drop_weight":34, "dimensions":[1,2], "tags":["relic","fire","void","spirit"], "implicit_stats":{"Maximum Spirit":7.0,"Fire Damage":0.04,"Void Damage":0.04}}
}

static func base_ids() -> Array:
	return BASE_ITEMS.keys()

static func get_base(base_id: String) -> Dictionary:
	return base_item(base_id)

static func base_item(base_id: String) -> Dictionary:
	var selected_id: String = base_id
	if not BASE_ITEMS.has(selected_id):
		selected_id = "rusted_sword"
	var result: Dictionary = Dictionary(BASE_ITEMS[selected_id]).duplicate(true)
	result["base_id"] = selected_id
	return result

static func random_base_for_level(rng: RandomNumberGenerator, item_level: int, preferred_slot: String = "", required_tags: Array = []) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for base_id_value: Variant in BASE_ITEMS.keys():
		var base: Dictionary = base_item(str(base_id_value))
		if int(base.get("min_level", 1)) > item_level:
			continue
		if preferred_slot != "" and str(base.get("slot", "")) != _normalize_slot(preferred_slot):
			continue
		if not _has_required_tags(Array(base.get("tags", [])), required_tags):
			continue
		candidates.append(base)
	if candidates.is_empty():
		return base_item("rusted_sword")
	return _weighted_pick_base(rng, candidates)

static func dimensions_for_item(item: Dictionary) -> Vector2i:
	var dimensions: Array = Array(item.get("dimensions", []))
	if dimensions.size() >= 2:
		return Vector2i(max(1, int(dimensions[0])), max(1, int(dimensions[1])))
	match str(item.get("slot", "")):
		"weapon": return Vector2i(2, 3)
		"chest": return Vector2i(2, 3)
		"offhand": return Vector2i(2, 2)
		"head", "gloves", "boots": return Vector2i(2, 2)
		"amulet", "ring": return Vector2i(1, 1)
		"relic": return Vector2i(1, 2)
	return Vector2i(1, 1)

static func _normalize_slot(slot: String) -> String:
	match slot:
		"ring1", "ring2": return "ring"
		"helmet": return "head"
		"armor": return "chest"
		_: return slot

static func _has_required_tags(base_tags: Array, required_tags: Array) -> bool:
	for tag_value: Variant in required_tags:
		var required: String = str(tag_value).to_lower()
		if required == "":
			continue
		var found: bool = false
		for base_tag_value: Variant in base_tags:
			if str(base_tag_value).to_lower() == required:
				found = true
				break
		if not found:
			return false
	return true

static func _weighted_pick_base(rng: RandomNumberGenerator, candidates: Array[Dictionary]) -> Dictionary:
	var total: int = 0
	for candidate: Dictionary in candidates:
		total += max(1, int(candidate.get("drop_weight", 1)))
	var roll: int = rng.randi_range(1, max(1, total))
	var running: int = 0
	for candidate2: Dictionary in candidates:
		running += max(1, int(candidate2.get("drop_weight", 1)))
		if roll <= running:
			return candidate2.duplicate(true)
	return candidates[0].duplicate(true)
