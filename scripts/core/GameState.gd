class_name RVGameState
extends RefCounted

const SAVE_VERSION: int = 73

var mode: String = "hub"
var panel_mode: String = ""
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var combat_room_layout: Dictionary = {}
var room_objective: String = ""
var room_reward_ready: bool = false
var room_reward_claimed: bool = false
var room_exit_ready: bool = false
var reward_pos: Vector2 = Vector2(640.0, 285.0)
var exit_pos: Vector2 = Vector2(640.0, 600.0)

var player_pos: Vector2 = Vector2(640.0, 360.0)
var player_radius: float = 15.0
var player_speed: float = 245.0
var player_hp: float = 120.0
var player_mana: float = 100.0
var max_hp: float = 120.0
var max_mana: float = 100.0
var spirit_max: int = 30
var spirit_reserved: int = 0
var invuln: float = 0.0

var level: int = 1
var xp: float = 0.0
var mastery_points: int = 0
var refund_points: int = 0
var ascendancy_points: int = 0
var gold: int = 0

var materials: Dictionary = {
	"embers": 10,
	"shards": 5,
	"runes": 0,
	"echo_glass": 0,
	"socket_prisms": 1,
	"fire_shards": 0,
	"cold_shards": 0,
	"lightning_shards": 0,
	"void_shards": 0,
	"physical_shards": 0,
	"life_shards": 0,
	"mana_shards": 0
}
var crafting_shards: Dictionary = {}
var glyph_counts: Dictionary = {}
var rune_counts: Dictionary = {}

var class_id: String = "sorceress"
var ascendancy_id: String = ""
var passive_atlas_allocated: Array[String] = ["center"]
var passive_atlas_refund_stack: Array[String] = []
var passive_atlas_cursor: int = 0
var ascendancy_allocated: Array[String] = []
var ascendancy_refund_stack: Array[String] = []
var ascendancy_cursor: int = 0

var build_stats: Dictionary = {}
var build_flags: Array[String] = []

var active_skills: Array[String] = ["Fireball", "Cleave"]
var unlocked_skills: Array[String] = ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"]
var selected_skill_index: int = 0
var selected_skill: int = 0
var skill_cooldowns: Dictionary = {}
var skill_ranks: Dictionary = {
	"Fireball": 0,
	"Cleave": 0,
	"Frost Nova": 0,
	"Storm Lance": 0,
	"Void Rift": 0,
	"Blade Trap": 0
}

# Legacy starter passive compatibility. The new atlas uses passive_atlas_allocated.
var passive_nodes: Dictionary = {
	"life_1": false,
	"mana_1": false,
	"fire_1": false,
	"cold_1": false,
	"lightning_1": false,
	"void_1": false,
	"melee_1": false,
	"trap_1": false
}
var passives: Dictionary = {}
var skill_supports: Dictionary = {
	"Fireball": [],
	"Cleave": [],
	"Frost Nova": [],
	"Storm Lance": [],
	"Void Rift": [],
	"Blade Trap": []
}

var skill_gem_inventory: Array[Dictionary] = []
var support_gem_inventory: Array[Dictionary] = []
var spirit_gem_inventory: Array[Dictionary] = []
var skill_gem_cursor: int = 0
var support_gem_cursor: int = 0
var spirit_gem_cursor: int = 0
var socket_cursor: int = 0
var gem_uid_counter: int = 1

# Older gem/socket compatibility keys used by previous patches.
var skill_gem_sockets: Dictionary = {}
var spirit_gems_enabled: Dictionary = {}
var gem_board_skill_cursor: int = 0
var gem_board_support_cursor: int = 0
var spirit_cursor: int = 0

var equipped: Dictionary = {
	"weapon": {},
	"offhand": {},
	"head": {},
	"chest": {},
	"gloves": {},
	"boots": {},
	"amulet": {},
	"ring1": {},
	"ring2": {},
	"relic": {}
}
var backpack: Array[Dictionary] = []
var stash: Array[Dictionary] = []
var map_stash: Array[Dictionary] = []
var map_cursor: int = 0
var pending_start_activity: Dictionary = {}

var inventory_cursor: int = 0
var stash_cursor: int = 0
var equipment_cursor: int = 0
var forge_focus_index: int = 0
var forge_affix_cursor: int = 0

var current_activity: Dictionary = {}
var room_index: int = 0
var rooms_cleared: int = 0
var kills: int = 0
var deaths: int = 0

var focused_hub_station_id: String = ""
var focused_hub_station_name: String = ""
var prompt_text: String = ""
var notice_text: String = ""
var notice_time: float = 0.0

# Legacy aliases still referenced by older UI scripts.
var prompt: String = ""
var notice: String = ""

func init() -> void:
	init_new()

func init_new() -> void:
	rng.randomize()
	ensure_defaults()
	recompute_stats()
	full_restore()

func ensure_defaults() -> void:
	if class_id == "":
		class_id = "sorceress"
	if not passive_atlas_allocated.has("center"):
		passive_atlas_allocated.insert(0, "center")
	for skill_name: String in unlocked_skills:
		if not skill_cooldowns.has(skill_name):
			skill_cooldowns[skill_name] = 0.0
		if not skill_ranks.has(skill_name):
			skill_ranks[skill_name] = 0
		if not skill_supports.has(skill_name):
			skill_supports[skill_name] = []
	if equipped.has("weapon") and typeof(equipped["weapon"]) == TYPE_DICTIONARY and Dictionary(equipped["weapon"]).is_empty():
		if Engine.has_singleton("__never__"):
			pass
		else:
			equipped["weapon"] = RVItemDB.make_starter_weapon()
	_ensure_default_gems()
	_sync_active_skills_from_equipped_gems()
	if active_skills.is_empty():
		active_skills = ["Fireball"]
	selected_skill_index = clamp(selected_skill_index, 0, max(0, active_skills.size() - 1))
	selected_skill = selected_skill_index
	inventory_cursor = clamp(inventory_cursor, 0, max(0, backpack.size() - 1))
	stash_cursor = clamp(stash_cursor, 0, max(0, stash.size() - 1))
	equipment_cursor = clamp(equipment_cursor, 0, 9)
	map_cursor = clamp(map_cursor, 0, max(0, map_stash.size() - 1))
	skill_gem_cursor = clamp(skill_gem_cursor, 0, max(0, skill_gem_inventory.size() - 1))
	support_gem_cursor = clamp(support_gem_cursor, 0, max(0, support_gem_inventory.size() - 1))
	spirit_gem_cursor = clamp(spirit_gem_cursor, 0, max(0, spirit_gem_inventory.size() - 1))
	passive_atlas_cursor = clamp(passive_atlas_cursor, 0, max(0, RVPassiveAtlasDB.node_ids_for_class(class_id).size() - 1))
	if ascendancy_id != "":
		ascendancy_cursor = clamp(ascendancy_cursor, 0, max(0, RVAscendancyDB.node_ids(ascendancy_id).size() - 1))
	RVMapSystem.ensure_defaults(self)
	RVClassAscendancySystem.ensure_defaults(self)
	_recompute_spirit_reserved()

func _ensure_default_gems() -> void:
	if skill_gem_inventory.is_empty():
		skill_gem_inventory.append(_make_active_gem("fireball", 1, true))
		skill_gem_inventory.append(_make_active_gem("cleave", 1, true))
		skill_gem_inventory.append(_make_active_gem("frost_nova", 1, false))
		skill_gem_inventory.append(_make_active_gem("storm_lance", 1, false))
	if support_gem_inventory.is_empty():
		support_gem_inventory.append(_make_support_gem("controlled_power", 1))
		support_gem_inventory.append(_make_support_gem("efficient_casting", 1))
		support_gem_inventory.append(_make_support_gem("area_expansion", 1))
	if spirit_gem_inventory.is_empty():
		spirit_gem_inventory.append(_make_spirit_gem("clarity", 1, false))
		spirit_gem_inventory.append(_make_spirit_gem("vitality", 1, false))

func _next_gem_uid(prefix: String) -> String:
	var uid: String = prefix + "_" + str(gem_uid_counter)
	gem_uid_counter += 1
	return uid

func _make_active_gem(gem_id: String, gem_level: int, equipped_now: bool) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.active_data(gem_id)
	return {
		"uid": _next_gem_uid("active"),
		"type": "active",
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"skill_id": str(data.get("skill_id", data.get("name", gem_id))),
		"level": gem_level,
		"xp": 0.0,
		"max_support_sockets": int(data.get("base_sockets", 2)),
		"supports": [],
		"equipped": equipped_now
	}

func _make_support_gem(gem_id: String, gem_level: int) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.support_data(gem_id)
	return {
		"uid": _next_gem_uid("support"),
		"type": "support",
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"level": gem_level,
		"xp": 0.0
	}

func _make_spirit_gem(gem_id: String, gem_level: int, enabled_now: bool) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.spirit_data(gem_id)
	return {
		"uid": _next_gem_uid("spirit"),
		"type": "spirit",
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"level": gem_level,
		"xp": 0.0,
		"max_support_sockets": int(data.get("base_sockets", 2)),
		"supports": [],
		"enabled": enabled_now
	}

func _sync_active_skills_from_equipped_gems() -> void:
	active_skills.clear()
	unlocked_skills.clear()
	for gem: Dictionary in skill_gem_inventory:
		var skill_id: String = str(gem.get("skill_id", ""))
		if skill_id != "" and not unlocked_skills.has(skill_id):
			unlocked_skills.append(skill_id)
		if bool(gem.get("equipped", false)) and skill_id != "" and not active_skills.has(skill_id):
			active_skills.append(skill_id)
	if active_skills.is_empty() and not skill_gem_inventory.is_empty():
		skill_gem_inventory[0]["equipped"] = true
		active_skills.append(str(skill_gem_inventory[0].get("skill_id", "Fireball")))

func _recompute_spirit_reserved() -> void:
	spirit_reserved = 0
	for gem: Dictionary in spirit_gem_inventory:
		if not bool(gem.get("enabled", false)):
			continue
		var data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
		var reservation: float = float(data.get("base_reservation", 0))
		var supports: Array = gem.get("supports", [])
		for support_id_value: Variant in supports:
			var support_data: Dictionary = RVSkillGemDB.support_data(str(support_id_value))
			reservation *= 1.0 + float(support_data.get("spirit_more", 0.0))
		spirit_reserved += int(ceil(reservation))

func full_restore() -> void:
	recompute_stats()
	player_hp = max_hp
	player_mana = max_mana
	invuln = 0.0

func recompute_stats() -> void:
	build_stats.clear()
	build_flags.clear()
	max_hp = 120.0 + float(level - 1) * 5.0
	max_mana = 100.0 + float(level - 1) * 3.0
	spirit_max = 30 + int(level / 5) * 5
	if bool(passive_nodes.get("life_1", false)):
		max_hp += 25.0
	if bool(passive_nodes.get("mana_1", false)):
		max_mana += 20.0
	var class_stats: Dictionary = RVClassAscendancySystem.collect_stats(self)
	for stat_key: Variant in class_stats.keys():
		build_stats[str(stat_key)] = float(build_stats.get(str(stat_key), 0.0)) + float(class_stats[stat_key])
	max_hp += float(build_stats.get("Maximum Life", 0.0))
	max_mana += float(build_stats.get("Maximum Mana", 0.0))
	spirit_max += int(round(float(build_stats.get("Maximum Spirit", 0.0))))
	for flag_value: Variant in RVClassAscendancySystem.collect_flags(self):
		var flag: String = str(flag_value)
		if flag != "" and not build_flags.has(flag):
			build_flags.append(flag)
	for slot_name: String in equipped.keys():
		var item_value: Variant = equipped[slot_name]
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_value
		var stats: Dictionary = item.get("total_stats", item.get("stats", {}))
		max_hp += float(stats.get("Maximum Life", 0.0))
		max_mana += float(stats.get("Maximum Mana", 0.0))
		spirit_max += int(round(float(stats.get("Maximum Spirit", 0.0))))
	for spirit_gem: Dictionary in spirit_gem_inventory:
		if not bool(spirit_gem.get("enabled", false)):
			continue
		var spirit_data: Dictionary = RVSkillGemDB.spirit_data(str(spirit_gem.get("gem_id", "")))
		var spirit_stats: Dictionary = spirit_data.get("stats", {})
		max_hp += float(spirit_stats.get("Maximum Life", 0.0))
		max_mana += float(spirit_stats.get("Maximum Mana", 0.0))
	_recompute_spirit_reserved()
	player_hp = min(player_hp, max_hp)
	player_mana = min(player_mana, max_mana)

func add_notice(text: String) -> void:
	notice_text = text
	notice = text
	notice_time = 2.2

func clear_prompt() -> void:
	focused_hub_station_id = ""
	focused_hub_station_name = ""
	prompt_text = ""
	prompt = ""

func set_prompt(text: String) -> void:
	prompt_text = text
	prompt = text

func xp_to_next() -> float:
	return 120.0 + pow(float(level), 1.35) * 80.0

func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		mastery_points += 1
		refund_points += 1
		if level in [10, 15, 25, 40, 60]:
			ascendancy_points += 2
		add_notice("Level Up - Mastery Point Gained")
	recompute_stats()

func get_selected_skill() -> String:
	if active_skills.is_empty():
		return ""
	selected_skill_index = clamp(selected_skill_index, 0, active_skills.size() - 1)
	selected_skill = selected_skill_index
	return str(active_skills[selected_skill_index])

func enter_hub() -> void:
	room_objective = ""
	room_reward_ready = false
	room_reward_claimed = false
	room_exit_ready = false
	mode = "hub"
	current_activity = {}
	room_index = 0
	player_pos = Vector2(640.0, 360.0)
	full_restore()
	clear_prompt()

func enter_combat(activity: Dictionary) -> void:
	room_objective = "Defeat all enemies."
	room_reward_ready = false
	room_reward_claimed = false
	room_exit_ready = false
	mode = "combat"
	current_activity = activity.duplicate(true)
	room_index = 1
	player_pos = Vector2(640.0, 360.0)
	full_restore()
	clear_prompt()

func toggle_panel(mode_name: String) -> void:
	if panel_mode == mode_name:
		panel_mode = ""
	else:
		panel_mode = mode_name

func to_save_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"level": level,
		"xp": xp,
		"mastery_points": mastery_points,
		"refund_points": refund_points,
		"ascendancy_points": ascendancy_points,
		"gold": gold,
		"materials": materials,
		"crafting_shards": crafting_shards,
		"glyph_counts": glyph_counts,
		"rune_counts": rune_counts,
		"class_id": class_id,
		"ascendancy_id": ascendancy_id,
		"passive_atlas_allocated": passive_atlas_allocated,
		"passive_atlas_refund_stack": passive_atlas_refund_stack,
		"passive_atlas_cursor": passive_atlas_cursor,
		"ascendancy_allocated": ascendancy_allocated,
		"ascendancy_refund_stack": ascendancy_refund_stack,
		"ascendancy_cursor": ascendancy_cursor,
		"build_stats": build_stats,
		"build_flags": build_flags,
		"active_skills": active_skills,
		"unlocked_skills": unlocked_skills,
		"selected_skill_index": selected_skill_index,
		"skill_ranks": skill_ranks,
		"passive_nodes": passive_nodes,
		"passives": passives,
		"skill_supports": skill_supports,
		"skill_gem_inventory": skill_gem_inventory,
		"support_gem_inventory": support_gem_inventory,
		"spirit_gem_inventory": spirit_gem_inventory,
		"skill_gem_cursor": skill_gem_cursor,
		"support_gem_cursor": support_gem_cursor,
		"spirit_gem_cursor": spirit_gem_cursor,
		"socket_cursor": socket_cursor,
		"gem_uid_counter": gem_uid_counter,
		"equipped": equipped,
		"backpack": backpack,
		"stash": stash,
		"map_stash": map_stash,
		"map_cursor": map_cursor,
		"rooms_cleared": rooms_cleared,
		"kills": kills,
		"deaths": deaths,
		"inventory_cursor": inventory_cursor,
		"stash_cursor": stash_cursor,
		"equipment_cursor": equipment_cursor,
		"forge_focus_index": forge_focus_index,
		"forge_affix_cursor": forge_affix_cursor
	}

func apply_save_dict(data: Dictionary) -> void:
	level = int(data.get("level", level))
	xp = float(data.get("xp", xp))
	mastery_points = int(data.get("mastery_points", mastery_points))
	refund_points = int(data.get("refund_points", refund_points))
	ascendancy_points = int(data.get("ascendancy_points", ascendancy_points))
	gold = int(data.get("gold", gold))
	class_id = str(data.get("class_id", class_id))
	ascendancy_id = str(data.get("ascendancy_id", ascendancy_id))
	_merge_dict_from_save(data, "materials", materials)
	_merge_dict_from_save(data, "crafting_shards", crafting_shards)
	_merge_dict_from_save(data, "glyph_counts", glyph_counts)
	_merge_dict_from_save(data, "rune_counts", rune_counts)
	_read_string_array(data, "active_skills", active_skills)
	_read_string_array(data, "unlocked_skills", unlocked_skills)
	selected_skill_index = int(data.get("selected_skill_index", selected_skill_index))
	selected_skill = selected_skill_index
	_merge_dict_from_save(data, "skill_ranks", skill_ranks)
	_merge_dict_from_save(data, "passive_nodes", passive_nodes)
	_merge_dict_from_save(data, "passives", passives)
	_merge_dict_from_save(data, "skill_supports", skill_supports)
	_read_dict_array(data, "skill_gem_inventory", skill_gem_inventory)
	_read_dict_array(data, "support_gem_inventory", support_gem_inventory)
	_read_dict_array(data, "spirit_gem_inventory", spirit_gem_inventory)
	skill_gem_cursor = int(data.get("skill_gem_cursor", skill_gem_cursor))
	support_gem_cursor = int(data.get("support_gem_cursor", support_gem_cursor))
	spirit_gem_cursor = int(data.get("spirit_gem_cursor", spirit_gem_cursor))
	socket_cursor = int(data.get("socket_cursor", socket_cursor))
	gem_uid_counter = int(data.get("gem_uid_counter", gem_uid_counter))
	if typeof(data.get("equipped", {})) == TYPE_DICTIONARY:
		equipped.merge(data.get("equipped", {}), true)
	_read_dict_array(data, "backpack", backpack)
	_read_dict_array(data, "stash", stash)
	_read_dict_array(data, "map_stash", map_stash)
	map_cursor = int(data.get("map_cursor", map_cursor))
	rooms_cleared = int(data.get("rooms_cleared", rooms_cleared))
	kills = int(data.get("kills", kills))
	deaths = int(data.get("deaths", deaths))
	inventory_cursor = int(data.get("inventory_cursor", inventory_cursor))
	stash_cursor = int(data.get("stash_cursor", stash_cursor))
	equipment_cursor = int(data.get("equipment_cursor", equipment_cursor))
	forge_focus_index = int(data.get("forge_focus_index", forge_focus_index))
	forge_affix_cursor = int(data.get("forge_affix_cursor", forge_affix_cursor))
	_read_string_array(data, "passive_atlas_allocated", passive_atlas_allocated)
	_read_string_array(data, "passive_atlas_refund_stack", passive_atlas_refund_stack)
	passive_atlas_cursor = int(data.get("passive_atlas_cursor", passive_atlas_cursor))
	_read_string_array(data, "ascendancy_allocated", ascendancy_allocated)
	_read_string_array(data, "ascendancy_refund_stack", ascendancy_refund_stack)
	ascendancy_cursor = int(data.get("ascendancy_cursor", ascendancy_cursor))
	if typeof(data.get("build_stats", {})) == TYPE_DICTIONARY:
		build_stats = Dictionary(data.get("build_stats", {})).duplicate(true)
	_read_string_array(data, "build_flags", build_flags)
	ensure_defaults()
	recompute_stats()

func _merge_dict_from_save(data: Dictionary, key: String, target: Dictionary) -> void:
	if typeof(data.get(key, {})) == TYPE_DICTIONARY:
		target.merge(data.get(key, {}), true)

func _read_string_array(data: Dictionary, key: String, target: Array[String]) -> void:
	if typeof(data.get(key, [])) != TYPE_ARRAY:
		return
	target.clear()
	for value: Variant in data.get(key, []):
		target.append(str(value))

func _read_dict_array(data: Dictionary, key: String, target: Array[Dictionary]) -> void:
	if typeof(data.get(key, [])) != TYPE_ARRAY:
		return
	target.clear()
	for value: Variant in data.get(key, []):
		if typeof(value) == TYPE_DICTIONARY:
			target.append(Dictionary(value))
