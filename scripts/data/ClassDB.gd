class_name RVClassDB
extends RefCounted

static func default_id() -> String:
	return "sorceress"

static func ids() -> Array[String]:
	return ["sorceress", "huntress", "warrior"]

static func has_class(class_id: String) -> bool:
	return ids().has(class_id)

static func data(class_id: String) -> Dictionary:
	match class_id:
		"sorceress":
			return {
				"id": "sorceress",
				"name": "Sorceress",
				"summary": "Spell, elemental, mana, spirit, cooldown, and ailment scaling.",
				"start_zone": "sorceress_start",
				"stats": {"Maximum Mana": 20.0, "Maximum Spirit": 5.0, "Spell Damage": 8.0},
				"flags": ["class_sorceress", "spell_start"]
			}
		"huntress":
			return {
				"id": "huntress",
				"name": "Huntress",
				"summary": "Traps, crit, mobility, bleed, evasion, and ambush damage.",
				"start_zone": "huntress_start",
				"stats": {"Movement Speed": 4.0, "Critical Chance": 4.0, "Trap Damage": 8.0},
				"flags": ["class_huntress", "trap_start"]
			}
		"warrior":
			return {
				"id": "warrior",
				"name": "Warrior",
				"summary": "Life, armor, melee, physical damage, bleed, and stagger pressure.",
				"start_zone": "warrior_start",
				"stats": {"Maximum Life": 30.0, "Armor": 12.0, "Physical Damage": 8.0},
				"flags": ["class_warrior", "melee_start"]
			}
	return data(default_id())

static func display_name(class_id: String) -> String:
	return str(data(class_id).get("name", class_id.capitalize()))

static func next_id(current_id: String) -> String:
	var list: Array[String] = ids()
	var index: int = list.find(current_id)
	if index < 0:
		return list[0]
	return list[(index + 1) % list.size()]

static func class_stats(class_id: String) -> Dictionary:
	return Dictionary(data(class_id).get("stats", {})).duplicate(true)

static func class_flags(class_id: String) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in Array(data(class_id).get("flags", [])):
		result.append(str(value))
	return result
