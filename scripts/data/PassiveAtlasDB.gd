class_name RVPassiveAtlasDB
extends RefCounted

static func all_nodes() -> Dictionary:
	return {
		"center": _node("center", "Vaultbound Core", "Travel", "Shared center node.", {}, [], []),
		"life_core": _node("life_core", "Life Core", "Small", "+Maximum Life.", {"Maximum Life": 18.0}, [], ["center"]),
		"mana_core": _node("mana_core", "Mana Core", "Small", "+Maximum Mana.", {"Maximum Mana": 15.0}, [], ["center"]),
		"resist_core": _node("resist_core", "Warded Flesh", "Small", "+All Resistances.", {"All Resistance": 6.0}, [], ["center"]),
		"gem_growth": _node("gem_growth", "Gem Practice", "Notable", "Gems gain more experience.", {"Gem XP Gain": 10.0}, ["gem_xp_bonus"], ["center"]),
		"forge_touch": _node("forge_touch", "Careful Forging", "Notable", "Items retain more forging potential.", {"Forge Potential Bonus": 5.0}, ["forge_careful"], ["center"]),
		"sorc_start": _node("sorc_start", "Sorceress Start", "Travel", "Spell starting path.", {"Spell Damage": 5.0}, ["sorceress_path"], ["center"]),
		"sorc_fire": _node("sorc_fire", "Burning Projectiles", "Notable", "Fire projectile skills burn harder.", {"Fire Damage": 12.0, "Burn Damage": 12.0}, ["burning_projectiles"], ["sorc_start"]),
		"sorc_storm": _node("sorc_storm", "Conductive Mind", "Notable", "Lightning skills chain and shock better.", {"Lightning Damage": 12.0, "Shock Effect": 10.0}, ["conductive_mind"], ["sorc_start"]),
		"sorc_void": _node("sorc_void", "Rift Gravity", "Notable", "Void Rift gains stronger pull and curse pressure.", {"Void Damage": 12.0, "Curse Effect": 10.0}, ["rift_gravity"], ["sorc_start"]),
		"sorc_keystone": _node("sorc_keystone", "Glass Storm", "Keystone", "Lightning chains more, but casting makes you vulnerable.", {"Lightning Damage": 20.0}, ["keystone_glass_storm"], ["sorc_storm"]),
		"hunt_start": _node("hunt_start", "Huntress Start", "Travel", "Trap and crit starting path.", {"Trap Damage": 5.0}, ["huntress_path"], ["center"]),
		"hunt_trap": _node("hunt_trap", "Trap Preparation", "Notable", "Traps arm faster and hit harder.", {"Trap Damage": 12.0, "Cooldown Recovery": 6.0}, ["trap_preparation"], ["hunt_start"]),
		"hunt_bleed": _node("hunt_bleed", "Blood Edge", "Notable", "Bleed and crit scaling for fast kills.", {"Bleed Damage": 12.0, "Critical Chance": 5.0}, ["blood_edge"], ["hunt_start"]),
		"hunt_void": _node("hunt_void", "Marked Rift", "Notable", "Cursed and marked enemies take more trap damage.", {"Void Damage": 8.0, "Trap Damage": 8.0}, ["marked_rift"], ["hunt_start"]),
		"hunt_keystone": _node("hunt_keystone", "Ambush Engine", "Keystone", "First hits against cursed enemies are stronger.", {"Critical Damage": 20.0}, ["keystone_ambush_engine"], ["hunt_void"]),
		"war_start": _node("war_start", "Warrior Start", "Travel", "Melee and armor starting path.", {"Physical Damage": 5.0}, ["warrior_path"], ["center"]),
		"war_life": _node("war_life", "Iron Blood", "Notable", "More life and armor.", {"Maximum Life": 25.0, "Armor": 10.0}, ["iron_blood"], ["war_start"]),
		"war_bleed": _node("war_bleed", "Open Wounds", "Notable", "Melee hits inflict stronger bleed.", {"Bleed Damage": 12.0, "Physical Damage": 8.0}, ["open_wounds"], ["war_start"]),
		"war_stagger": _node("war_stagger", "Breaker Stance", "Notable", "Heavy hits stagger enemies harder.", {"Stagger Damage": 16.0}, ["breaker_stance"], ["war_start"]),
		"war_keystone": _node("war_keystone", "Blood Price", "Keystone", "When mana is empty, melee skills can spend life.", {"Life Leech": 4.0}, ["keystone_blood_price"], ["war_bleed"])
	}

static func _node(id_value: String, name_value: String, type_value: String, text_value: String, stats_value: Dictionary, flags_value: Array, req_value: Array) -> Dictionary:
	return {
		"id": id_value,
		"name": name_value,
		"type": type_value,
		"description": text_value,
		"stats": stats_value,
		"flags": flags_value,
		"requires": req_value
	}

static func node_ids_for_class(class_id: String) -> Array[String]:
	var result: Array[String] = ["center", "life_core", "mana_core", "resist_core", "gem_growth", "forge_touch"]
	match class_id:
		"sorceress":
			result.append_array(["sorc_start", "sorc_fire", "sorc_storm", "sorc_void", "sorc_keystone"])
		"huntress":
			result.append_array(["hunt_start", "hunt_trap", "hunt_bleed", "hunt_void", "hunt_keystone"])
		"warrior":
			result.append_array(["war_start", "war_life", "war_bleed", "war_stagger", "war_keystone"])
	return result

static func node_data(node_id: String) -> Dictionary:
	return Dictionary(all_nodes().get(node_id, {})).duplicate(true)

static func can_allocate(state: RVGameState, node_id: String) -> bool:
	if state.passive_atlas_allocated.has(node_id):
		return false
	if node_id == "center":
		return true
	var data: Dictionary = node_data(node_id)
	if data.is_empty():
		return false
	for required_value: Variant in Array(data.get("requires", [])):
		if state.passive_atlas_allocated.has(str(required_value)):
			return true
	return Array(data.get("requires", [])).is_empty()

static func selected_node_id(state: RVGameState) -> String:
	var ids_for_tree: Array[String] = node_ids_for_class(state.class_id)
	if ids_for_tree.is_empty():
		return "center"
	state.passive_atlas_cursor = clamp(state.passive_atlas_cursor, 0, ids_for_tree.size() - 1)
	return ids_for_tree[state.passive_atlas_cursor]
