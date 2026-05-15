class_name RVItemBaseDB
extends RefCounted

# Patch 037-041: base items are explicit build objects.
# They define slot, implicit identity, inventory footprint, and level gating.
# Affix legality lives in RVItemAffixDB.

const BASES: Dictionary = {
	"rusted_sword": {"id":"rusted_sword", "name":"Rusted Sword", "slot":"weapon", "base_type":"Sword", "item_class":"Weapon", "min_level":1, "tags":["Weapon","Melee","Physical","Bleed"], "implicit_stats":{"Physical Damage":6.0}, "dimensions":[1,3]},
	"iron_axe": {"id":"iron_axe", "name":"Iron Axe", "slot":"weapon", "base_type":"Axe", "item_class":"Weapon", "min_level":1, "tags":["Weapon","Melee","Physical","Critical"], "implicit_stats":{"Physical Damage":8.0,"Critical Damage":0.04}, "dimensions":[2,3]},
	"war_mace": {"id":"war_mace", "name":"War Mace", "slot":"weapon", "base_type":"Mace", "item_class":"Weapon", "min_level":4, "tags":["Weapon","Melee","Physical","Stun"], "implicit_stats":{"Physical Damage":10.0,"Stun Power":0.08}, "dimensions":[2,3]},
	"ember_wand": {"id":"ember_wand", "name":"Ember Wand", "slot":"weapon", "base_type":"Wand", "item_class":"Weapon", "min_level":1, "tags":["Weapon","Spell","Fire","Projectile"], "implicit_stats":{"Spell Damage":0.06,"Fire Damage":0.05}, "dimensions":[1,3]},
	"frost_scepter": {"id":"frost_scepter", "name":"Frost Scepter", "slot":"weapon", "base_type":"Scepter", "item_class":"Weapon", "min_level":6, "tags":["Weapon","Spell","Cold","Control"], "implicit_stats":{"Spell Damage":0.05,"Cold Damage":0.06}, "dimensions":[1,3]},
	"storm_rod": {"id":"storm_rod", "name":"Storm Rod", "slot":"weapon", "base_type":"Rod", "item_class":"Weapon", "min_level":8, "tags":["Weapon","Spell","Lightning","Chain"], "implicit_stats":{"Lightning Damage":0.07,"Cast Speed":0.03}, "dimensions":[1,3]},
	"void_censer": {"id":"void_censer", "name":"Void Censer", "slot":"weapon", "base_type":"Censer", "item_class":"Weapon", "min_level":10, "tags":["Weapon","Spell","Void","Curse"], "implicit_stats":{"Void Damage":0.07,"Curse Effect":0.04}, "dimensions":[2,2]},
	"storm_focus": {"id":"storm_focus", "name":"Storm Focus", "slot":"offhand", "base_type":"Focus", "item_class":"Offhand", "min_level":1, "tags":["Offhand","Spell","Lightning","Resource"], "implicit_stats":{"Spell Damage":0.05,"Maximum Mana":8.0}, "dimensions":[2,2]},
	"ember_focus": {"id":"ember_focus", "name":"Ember Focus", "slot":"offhand", "base_type":"Focus", "item_class":"Offhand", "min_level":5, "tags":["Offhand","Spell","Fire","Burn"], "implicit_stats":{"Fire Damage":0.06,"Ignite Chance":0.04}, "dimensions":[2,2]},
	"rift_focus": {"id":"rift_focus", "name":"Rift Focus", "slot":"offhand", "base_type":"Focus", "item_class":"Offhand", "min_level":8, "tags":["Offhand","Spell","Void","Cooldown"], "implicit_stats":{"Void Damage":0.06,"Cooldown Reduction":0.03}, "dimensions":[2,2]},
	"warden_shield": {"id":"warden_shield", "name":"Warden Shield", "slot":"offhand", "base_type":"Shield", "item_class":"Offhand", "min_level":1, "tags":["Offhand","Defense","Armor","Life"], "implicit_stats":{"Armor":18.0,"Maximum Life":10.0}, "dimensions":[2,2]},
	"iron_helm": {"id":"iron_helm", "name":"Iron Helm", "slot":"head", "base_type":"Helmet", "item_class":"Armor", "armor_class":"Heavy", "min_level":1, "tags":["Armor","Defense"], "implicit_stats":{"Armor":14.0}, "dimensions":[2,2]},
	"leather_hood": {"id":"leather_hood", "name":"Leather Hood", "slot":"head", "base_type":"Hood", "item_class":"Armor", "armor_class":"Light", "min_level":1, "tags":["Armor","Evasion","Mana"], "implicit_stats":{"Armor":7.0,"Maximum Mana":6.0}, "dimensions":[2,2]},
	"seer_mask": {"id":"seer_mask", "name":"Seer Mask", "slot":"head", "base_type":"Mask", "item_class":"Armor", "armor_class":"Cloth", "min_level":12, "tags":["Armor","Spell","Spirit"], "implicit_stats":{"Maximum Spirit":3.0,"Maximum Mana":8.0}, "dimensions":[2,2]},
	"plate_chest": {"id":"plate_chest", "name":"Plate Chest", "slot":"chest", "base_type":"Chest", "item_class":"Armor", "armor_class":"Heavy", "min_level":1, "tags":["Armor","Defense","Life"], "implicit_stats":{"Armor":34.0,"Maximum Life":14.0}, "dimensions":[2,3]},
	"chain_chest": {"id":"chain_chest", "name":"Chain Chest", "slot":"chest", "base_type":"Chest", "item_class":"Armor", "armor_class":"Medium", "min_level":5, "tags":["Armor","Defense","Resistance"], "implicit_stats":{"Armor":25.0,"All Resistance":0.04}, "dimensions":[2,3]},
	"silk_robes": {"id":"silk_robes", "name":"Silk Robes", "slot":"chest", "base_type":"Robe", "item_class":"Armor", "armor_class":"Cloth", "min_level":1, "tags":["Armor","Spell","Mana"], "implicit_stats":{"Armor":12.0,"Maximum Mana":16.0}, "dimensions":[2,3]},
	"work_gloves": {"id":"work_gloves", "name":"Work Gloves", "slot":"gloves", "base_type":"Gloves", "item_class":"Armor", "min_level":1, "tags":["Armor"], "implicit_stats":{"Armor":9.0}, "dimensions":[2,2]},
	"trapwright_grips": {"id":"trapwright_grips", "name":"Trapwright Grips", "slot":"gloves", "base_type":"Gloves", "item_class":"Armor", "min_level":8, "tags":["Armor","Trap"], "implicit_stats":{"Trap Damage":0.05,"Armor":8.0}, "dimensions":[2,2]},
	"ember_gloves": {"id":"ember_gloves", "name":"Ember Gloves", "slot":"gloves", "base_type":"Gloves", "item_class":"Armor", "min_level":10, "tags":["Armor","Fire","Burn"], "implicit_stats":{"Ignite Chance":0.04,"Armor":8.0}, "dimensions":[2,2]},
	"travel_boots": {"id":"travel_boots", "name":"Travel Boots", "slot":"boots", "base_type":"Boots", "item_class":"Armor", "min_level":1, "tags":["Armor","Movement"], "implicit_stats":{"Movement Speed":0.04,"Armor":8.0}, "dimensions":[2,2]},
	"rift_boots": {"id":"rift_boots", "name":"Rift Boots", "slot":"boots", "base_type":"Boots", "item_class":"Armor", "min_level":12, "tags":["Armor","Movement","Void"], "implicit_stats":{"Movement Speed":0.05,"Void Resistance":0.06}, "dimensions":[2,2]},
	"bronze_ring": {"id":"bronze_ring", "name":"Bronze Ring", "slot":"ring", "base_type":"Ring", "item_class":"Jewelry", "min_level":1, "tags":["Jewelry","Life"], "implicit_stats":{"Maximum Life":8.0}, "dimensions":[1,1]},
	"opal_ring": {"id":"opal_ring", "name":"Opal Ring", "slot":"ring", "base_type":"Ring", "item_class":"Jewelry", "min_level":8, "tags":["Jewelry","Spell"], "implicit_stats":{"Spell Damage":0.04}, "dimensions":[1,1]},
	"blood_ring": {"id":"blood_ring", "name":"Blood Ring", "slot":"ring", "base_type":"Ring", "item_class":"Jewelry", "min_level":12, "tags":["Jewelry","Bleed","Life"], "implicit_stats":{"Bleed Damage":0.06,"Maximum Life":6.0}, "dimensions":[1,1]},
	"bone_amulet": {"id":"bone_amulet", "name":"Bone Amulet", "slot":"amulet", "base_type":"Amulet", "item_class":"Jewelry", "min_level":1, "tags":["Jewelry"], "implicit_stats":{"Global Damage":0.03}, "dimensions":[1,1]},
	"choir_amulet": {"id":"choir_amulet", "name":"Choir Amulet", "slot":"amulet", "base_type":"Amulet", "item_class":"Jewelry", "min_level":16, "tags":["Jewelry","Spirit","Proc"], "implicit_stats":{"Maximum Spirit":4.0,"Proc Chance":0.02}, "dimensions":[1,1]},
	"relic_core": {"id":"relic_core", "name":"Relic Core", "slot":"relic", "base_type":"Relic", "item_class":"Relic", "min_level":1, "tags":["Relic","Spirit"], "implicit_stats":{"Maximum Spirit":4.0}, "dimensions":[2,2]},
	"cascade_relic": {"id":"cascade_relic", "name":"Cascade Relic", "slot":"relic", "base_type":"Relic", "item_class":"Relic", "min_level":18, "tags":["Relic","Proc","Chain"], "implicit_stats":{"Proc Chance":0.03,"Cooldown Reduction":0.02}, "dimensions":[2,2]}
}

static func get_base(base_id: String) -> Dictionary:
	if BASES.has(base_id):
		return Dictionary(BASES[base_id]).duplicate(true)
	return Dictionary(BASES["rusted_sword"]).duplicate(true)

static func all_base_ids() -> Array[String]:
	var ids: Array[String] = []
	for key_value: Variant in BASES.keys():
		ids.append(str(key_value))
	return ids

static func bases_for_level(item_level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key_value: Variant in BASES.keys():
		var base: Dictionary = Dictionary(BASES[key_value])
		if int(base.get("min_level", 1)) <= item_level:
			result.append(base.duplicate(true))
	return result

static func random_base_for_level(rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	var candidates: Array[Dictionary] = bases_for_level(item_level)
	if candidates.is_empty():
		return get_base("rusted_sword")
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

static func random_base_for_slot(rng: RandomNumberGenerator, item_level: int, slot: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for base: Dictionary in bases_for_level(item_level):
		if str(base.get("slot", "")) == slot:
			candidates.append(base)
	if candidates.is_empty():
		return random_base_for_level(rng, item_level)
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

static func dimensions_for_item(item: Dictionary) -> Vector2i:
	var dimensions: Array = item.get("dimensions", [])
	if dimensions.size() >= 2:
		return Vector2i(max(1, int(dimensions[0])), max(1, int(dimensions[1])))
	var base_id: String = str(item.get("base_id", ""))
	if base_id != "" and BASES.has(base_id):
		var base: Dictionary = Dictionary(BASES[base_id])
		var base_dimensions: Array = base.get("dimensions", [1, 1])
		return Vector2i(max(1, int(base_dimensions[0])), max(1, int(base_dimensions[1])))
	return Vector2i(1, 1)
