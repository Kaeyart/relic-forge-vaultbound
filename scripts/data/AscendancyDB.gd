class_name RVAscendancyDB
extends RefCounted

static func ids_for_class(class_id: String) -> Array[String]:
	match class_id:
		"sorceress":
			return ["ember_savant", "storm_oracle", "void_arcanist"]
		"huntress":
			return ["trapwright", "bloodstalker", "rift_poacher"]
		"warrior":
			return ["ironbreaker", "bloodbound", "forgeguard"]
	return []

static func first_for_class(class_id: String) -> String:
	var list: Array[String] = ids_for_class(class_id)
	return "" if list.is_empty() else list[0]

static func next_for_class(class_id: String, current_id: String) -> String:
	var list: Array[String] = ids_for_class(class_id)
	if list.is_empty():
		return ""
	var index: int = list.find(current_id)
	if index < 0:
		return list[0]
	return list[(index + 1) % list.size()]

static func data(ascendancy_id: String) -> Dictionary:
	match ascendancy_id:
		"ember_savant":
			return _make("ember_savant", "Ember Savant", "sorceress", "Burn, Fireball, explosions, and ignite spread.", {"Fire Damage": 14.0, "Burn Damage": 18.0}, ["asc_ember_savant", "fire_burn_engine"])
		"storm_oracle":
			return _make("storm_oracle", "Storm Oracle", "sorceress", "Lightning chains, shock, cast speed, and overloads.", {"Lightning Damage": 14.0, "Cast Speed": 6.0}, ["asc_storm_oracle", "storm_chain_engine"])
		"void_arcanist":
			return _make("void_arcanist", "Void Arcanist", "sorceress", "Void rifts, curses, delayed pulses, and spirit manipulation.", {"Void Damage": 14.0, "Curse Effect": 10.0, "Maximum Spirit": 5.0}, ["asc_void_arcanist", "void_curse_engine"])
		"trapwright":
			return _make("trapwright", "Trapwright", "huntress", "Trap count, trigger radius, arming speed, and cooldown recovery.", {"Trap Damage": 16.0, "Cooldown Recovery": 6.0}, ["asc_trapwright", "trap_engine"])
		"bloodstalker":
			return _make("bloodstalker", "Bloodstalker", "huntress", "Bleed, crit, execute damage, and speed after kills.", {"Bleed Damage": 14.0, "Critical Chance": 6.0}, ["asc_bloodstalker", "bleed_execute_engine"])
		"rift_poacher":
			return _make("rift_poacher", "Rift Poacher", "huntress", "Void/trap hybrid, cursed prey, marks, and ambush damage.", {"Void Damage": 10.0, "Trap Damage": 10.0}, ["asc_rift_poacher", "void_trap_engine"])
		"ironbreaker":
			return _make("ironbreaker", "Ironbreaker", "warrior", "Armor, stagger, heavy hits, and boss pressure.", {"Armor": 20.0, "Stagger Damage": 16.0}, ["asc_ironbreaker", "stagger_engine"])
		"bloodbound":
			return _make("bloodbound", "Bloodbound", "warrior", "Bleed, leech, rage, and kill chains.", {"Maximum Life": 22.0, "Bleed Damage": 14.0}, ["asc_bloodbound", "leech_bleed_engine"])
		"forgeguard":
			return _make("forgeguard", "Forgeguard", "warrior", "Fire/physical hybrid, forge bonuses, and defensive spirit.", {"Fire Damage": 8.0, "Physical Damage": 8.0, "Maximum Spirit": 5.0}, ["asc_forgeguard", "fire_physical_engine"])
	return {}

static func _make(id_value: String, name_value: String, class_value: String, summary_value: String, stats_value: Dictionary, flags_value: Array) -> Dictionary:
	return {
		"id": id_value,
		"name": name_value,
		"class_id": class_value,
		"summary": summary_value,
		"stats": stats_value,
		"flags": flags_value
	}

static func display_name(ascendancy_id: String) -> String:
	if ascendancy_id == "":
		return "No Ascendancy"
	return str(data(ascendancy_id).get("name", ascendancy_id.capitalize()))

static func node_ids(ascendancy_id: String) -> Array[String]:
	if ascendancy_id == "":
		return []
	return [ascendancy_id + "_a", ascendancy_id + "_b", ascendancy_id + "_c", ascendancy_id + "_d"]

static func node_data(node_id: String) -> Dictionary:
	var asc_id: String = ""
	var suffix: String = ""
	for id_value: String in ["ember_savant", "storm_oracle", "void_arcanist", "trapwright", "bloodstalker", "rift_poacher", "ironbreaker", "bloodbound", "forgeguard"]:
		if node_id.begins_with(id_value):
			asc_id = id_value
			suffix = node_id.trim_prefix(id_value + "_")
			break
	var asc: Dictionary = data(asc_id)
	if asc.is_empty():
		return {}
	var base_name: String = str(asc.get("name", "Ascendancy"))
	match suffix:
		"a":
			return {"id": node_id, "name": base_name + " I", "stats": asc.get("stats", {}), "flags": [str(asc_id) + "_1"], "cost": 1}
		"b":
			return {"id": node_id, "name": base_name + " II", "stats": asc.get("stats", {}), "flags": [str(asc_id) + "_2"], "cost": 1}
		"c":
			return {"id": node_id, "name": base_name + " Keystone", "stats": {}, "flags": asc.get("flags", []), "cost": 2}
		"d":
			return {"id": node_id, "name": base_name + " Mastery", "stats": asc.get("stats", {}), "flags": [str(asc_id) + "_mastery"], "cost": 2}
	return {}
