class_name RVAscendancyDB
extends RefCounted

const ASCENDANCIES: Dictionary = {
	"ember_savant": {
		"id": "ember_savant",
		"class_id": "sorceress",
		"name": "Ember Savant",
		"description": "Fire, burn, explosions, and Fireball scaling.",
		"nodes": ["ember_savant_1", "ember_savant_2", "ember_savant_3", "ember_savant_4"]
	},
	"storm_oracle": {
		"id": "storm_oracle",
		"class_id": "sorceress",
		"name": "Storm Oracle",
		"description": "Lightning chains, shock pressure, cast speed, and overload.",
		"nodes": ["storm_oracle_1", "storm_oracle_2", "storm_oracle_3", "storm_oracle_4"]
	},
	"void_arcanist": {
		"id": "void_arcanist",
		"class_id": "sorceress",
		"name": "Void Arcanist",
		"description": "Void rifts, curses, delayed pulses, and spirit manipulation.",
		"nodes": ["void_arcanist_1", "void_arcanist_2", "void_arcanist_3", "void_arcanist_4"]
	},
	"trapwright": {
		"id": "trapwright",
		"class_id": "huntress",
		"name": "Trapwright",
		"description": "Trap count, trigger radius, repeats, and trap cooldown recovery.",
		"nodes": ["trapwright_1", "trapwright_2", "trapwright_3", "trapwright_4"]
	},
	"bloodstalker": {
		"id": "bloodstalker",
		"class_id": "huntress",
		"name": "Bloodstalker",
		"description": "Bleed, crit, execute damage, and fast movement after kills.",
		"nodes": ["bloodstalker_1", "bloodstalker_2", "bloodstalker_3", "bloodstalker_4"]
	},
	"rift_poacher": {
		"id": "rift_poacher",
		"class_id": "huntress",
		"name": "Rift Poacher",
		"description": "Void/trap hybrid damage, marked prey, and ambush scaling.",
		"nodes": ["rift_poacher_1", "rift_poacher_2", "rift_poacher_3", "rift_poacher_4"]
	},
	"ironbreaker": {
		"id": "ironbreaker",
		"class_id": "warrior",
		"name": "Ironbreaker",
		"description": "Armor, stagger, heavy hits, and boss pressure.",
		"nodes": ["ironbreaker_1", "ironbreaker_2", "ironbreaker_3", "ironbreaker_4"]
	},
	"bloodbound": {
		"id": "bloodbound",
		"class_id": "warrior",
		"name": "Bloodbound",
		"description": "Bleed, leech, low-life rage, and kill chains.",
		"nodes": ["bloodbound_1", "bloodbound_2", "bloodbound_3", "bloodbound_4"]
	},
	"forgeguard": {
		"id": "forgeguard",
		"class_id": "warrior",
		"name": "Forgeguard",
		"description": "Fire/physical hybrid pressure, forge bonuses, and defensive spirit.",
		"nodes": ["forgeguard_1", "forgeguard_2", "forgeguard_3", "forgeguard_4"]
	}
}

const ASCENDANCY_POINT_LEVELS: Array[int] = [20, 30, 40, 50]

static func ids_for_class(class_id: String) -> Array[String]:
	var result: Array[String] = []
	for id_value: String in ASCENDANCIES.keys():
		var data: Dictionary = ASCENDANCIES[id_value]
		if str(data.get("class_id", "")) == class_id:
			result.append(id_value)
	return result

static func data(ascendancy_id: String) -> Dictionary:
	return Dictionary(ASCENDANCIES.get(ascendancy_id, {})).duplicate(true)

static func name_for(ascendancy_id: String) -> String:
	if ascendancy_id == "":
		return "None"
	return str(data(ascendancy_id).get("name", ascendancy_id.capitalize()))

static func belongs_to_class(ascendancy_id: String, class_id: String) -> bool:
	var data_value: Dictionary = data(ascendancy_id)
	return not data_value.is_empty() and str(data_value.get("class_id", "")) == class_id

static func first_for_class(class_id: String) -> String:
	var values: Array[String] = ids_for_class(class_id)
	return "" if values.is_empty() else values[0]

static func next_for_class(class_id: String, current_id: String) -> String:
	var values: Array[String] = ids_for_class(class_id)
	if values.is_empty():
		return ""
	var index: int = values.find(current_id)
	if index < 0:
		return values[0]
	return values[(index + 1) % values.size()]

static func earned_points_for_level(level: int) -> int:
	var points: int = 0
	for threshold: int in ASCENDANCY_POINT_LEVELS:
		if level >= threshold:
			points += 1
	return points

static func nodes_for(ascendancy_id: String) -> Array[String]:
	var raw: Array = data(ascendancy_id).get("nodes", [])
	var result: Array[String] = []
	for value: Variant in raw:
		result.append(str(value))
	return result
