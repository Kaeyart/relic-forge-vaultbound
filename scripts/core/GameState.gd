class_name RVGameState
extends RefCounted

const SAVE_VERSION: int = 80

var mode: String = "hub"
var panel_mode: String = ""
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var character_slot_id: String = "slot_0"
var character_slot_index: int = 0
var character_name: String = "Character 1"
var character_class_id: String = "sorceress"
var character_class_locked: bool = false
var ascendancy_id: String = ""
var ascendancy_points: int = 0
var ascendancy_allocated: Array[String] = []
var passive_atlas_allocated: Array[String] = ["center"]
var passive_atlas_refund_stack: Array[String] = []
var passive_atlas_cursor: int = 0
var build_stats: Dictionary = {}
var build_flags: Array[String] = []

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
var gold: int = 0
var materials: Dictionary = {
	"embers": 10,
	"shards": 5,
	"runes": 0,
	"echo_glass": 0,
	"socket_prisms": 1
}

var active_skills: Array[String] = ["Fireball", "Cleave"]
var unlocked_skills: Array[String] = ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"]
var selected_skill_index: int = 0
var skill_cooldowns: Dictionary = {}
var skill_ranks: Dictionary = {
	"Fireball": 0,
	"Cleave": 0,
	"Frost Nova": 0,
	"Storm Lance": 0,
	"Void Rift": 0,
	"Blade Trap": 0
}
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
var map_tier_filter: int = 0
var completed_maps: Dictionary = {}
var map_system_seeded: bool = false
var pending_start_activity: Dictionary = {}

var inventory_cursor: int = 0
var stash_cursor: int = 0
var stash_tab_mode: String = "items"
var stash_tabs: Dictionary = {}
var stash_purchased_tabs: Dictionary = {
	"general": true,
	"maps": true,
	"currency": true,
	"materials": true,
	"gems": false,
	"uniques": false,
	"dump": false
}
var stash_affinities_enabled: bool = true
var stash_tab_cursor: int = 0
var stash_upgrade_cost_paid: int = 0
var stash_economy_version: int = 1
var loot_pet_enabled: bool = true
var loot_pet_radius: float = 210.0
var loot_pet_collect_radius: float = 54.0
var loot_pet_attract_radius: float = 310.0
var loot_filter_preset: String = "Starter"
var loot_filter_stats: Dictionary = {}
var loot_filter_settings: Dictionary = {
	"auto_pickup_gold": true,
	"auto_pickup_shards": true,
	"auto_pickup_embers": true,
	"auto_pickup_materials": true,
	"auto_pickup_currency": true,
	"auto_pickup_maps": false,
	"auto_pickup_gems": false,
	"manual_pickup_gear": true,
	"manual_pickup_uniques": true,
	"show_hidden_auto_pickup_notice": false,
}
var loot_pickup_stats: Dictionary = {}
var equipment_cursor: int = 0

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

func init_new() -> void:
	rng.randomize()
	ensure_defaults()
	recompute_stats()
	full_restore()

func ensure_defaults() -> void:
	RVCraftingCurrencySystem.ensure_defaults(self)
	RVLootPickupAssistSystem.ensure_defaults(self)
	RVLootFilterSystem.ensure_defaults(self)
	for skill_name: String in unlocked_skills:
		if not skill_cooldowns.has(skill_name):
			skill_cooldowns[skill_name] = 0.0
		if not skill_ranks.has(skill_name):
			skill_ranks[skill_name] = 0
		if not skill_supports.has(skill_name):
			skill_supports[skill_name] = []
	if equipped.has("weapon") and typeof(equipped["weapon"]) == TYPE_DICTIONARY and equipped["weapon"].is_empty():
		equipped["weapon"] = RVItemDB.make_starter_weapon()
	_ensure_default_gems()
	_sync_active_skills_from_equipped_gems()
	if active_skills.is_empty():
		active_skills = ["Fireball"]
	selected_skill_index = clamp(selected_skill_index, 0, max(0, active_skills.size() - 1))
	inventory_cursor = clamp(inventory_cursor, 0, max(0, backpack.size() - 1))
	stash_cursor = clamp(stash_cursor, 0, max(0, stash.size() - 1))
	equipment_cursor = clamp(equipment_cursor, 0, 9)
	RVMapSystem.ensure_defaults(self)
	RVStashSystem.ensure_defaults(self)
	map_cursor = clamp(map_cursor, 0, max(0, map_stash.size() - 1))
	skill_gem_cursor = clamp(skill_gem_cursor, 0, max(0, skill_gem_inventory.size() - 1))
	support_gem_cursor = clamp(support_gem_cursor, 0, max(0, support_gem_inventory.size() - 1))
	spirit_gem_cursor = clamp(spirit_gem_cursor, 0, max(0, spirit_gem_inventory.size() - 1))
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
	max_hp = 120.0 + float(level - 1) * 5.0
	max_mana = 100.0 + float(level - 1) * 3.0
	spirit_max = 30 + int(level / 5) * 5
	build_stats = {}
	build_flags = []
	if bool(passive_nodes.get("life_1", false)):
		max_hp += 25.0
	if bool(passive_nodes.get("mana_1", false)):
		max_mana += 20.0
	var class_bundle: Dictionary = RVClassAscendancySystem.collect_stats(self)
	build_stats = Dictionary(class_bundle.get("stats", {})).duplicate(true)
	for flag_value: Variant in class_bundle.get("flags", []):
		build_flags.append(str(flag_value))
	max_hp += float(build_stats.get("Maximum Life", 0.0))
	max_mana += float(build_stats.get("Maximum Mana", 0.0))
	spirit_max += int(round(float(build_stats.get("Maximum Spirit", 0.0))))
	for slot_name: String in equipped.keys():
		var item_value: Variant = equipped[slot_name]
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_value
		var stats: Dictionary = item.get("stats", item.get("total_stats", {}))
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
	ascendancy_points = RVClassAscendancySystem.available_ascendancy_points(self)
	player_hp = min(player_hp, max_hp)
	player_mana = min(player_mana, max_mana)

func add_notice(text: String) -> void:
	notice_text = text
	notice_time = 2.2

func clear_prompt() -> void:
	focused_hub_station_id = ""
	focused_hub_station_name = ""
	prompt_text = ""

func xp_to_next() -> float:
	return 120.0 + pow(float(level), 1.35) * 80.0

func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		mastery_points += 1
		refund_points += 1
		add_notice("Level Up - Passive Point Gained")
	recompute_stats()

func get_selected_skill() -> String:
	if active_skills.is_empty():
		return ""
	selected_skill_index = clamp(selected_skill_index, 0, active_skills.size() - 1)
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
		"character_slot_id": character_slot_id,
		"character_slot_index": character_slot_index,
		"character_name": character_name,
		"character_class_id": character_class_id,
		"character_class_locked": character_class_locked,
		"ascendancy_id": ascendancy_id,
		"ascendancy_allocated": ascendancy_allocated,
		"passive_atlas_allocated": passive_atlas_allocated,
		"passive_atlas_refund_stack": passive_atlas_refund_stack,
		"passive_atlas_cursor": passive_atlas_cursor,
		"level": level,
		"xp": xp,
		"mastery_points": mastery_points,
		"refund_points": refund_points,
		"gold": gold,
		"materials": materials,
		"active_skills": active_skills,
		"unlocked_skills": unlocked_skills,
		"selected_skill_index": selected_skill_index,
		"skill_ranks": skill_ranks,
		"passive_nodes": passive_nodes,
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
		"map_stash": map_stash, "map_tier_filter": map_tier_filter, "completed_maps": completed_maps, "map_system_seeded": map_system_seeded,
		"map_cursor": map_cursor,
		"rooms_cleared": rooms_cleared,
		"kills": kills,
		"deaths": deaths,
		"inventory_cursor": inventory_cursor,
		"stash_cursor": stash_cursor,
		"stash_tab_mode": stash_tab_mode,
		"stash_tabs": stash_tabs,
		"stash_purchased_tabs": stash_purchased_tabs,
		"stash_affinities_enabled": stash_affinities_enabled,
		"stash_tab_cursor": stash_tab_cursor,
		"stash_upgrade_cost_paid": stash_upgrade_cost_paid,
		"stash_economy_version": stash_economy_version,
		"equipment_cursor": equipment_cursor,
		"loot_filter_preset": loot_filter_preset,
		"loot_filter_settings": loot_filter_settings
	}

func apply_save_dict(data: Dictionary) -> void:
	character_slot_id = str(data.get("character_slot_id", character_slot_id))
	character_slot_index = int(data.get("character_slot_index", character_slot_index))
	character_name = str(data.get("character_name", character_name))
	character_class_id = str(data.get("character_class_id", character_class_id))
	character_class_locked = bool(data.get("character_class_locked", character_class_locked))
	ascendancy_id = str(data.get("ascendancy_id", ascendancy_id))
	if typeof(data.get("ascendancy_allocated", [])) == TYPE_ARRAY:
		ascendancy_allocated.clear()
		for value: Variant in data.get("ascendancy_allocated", []):
			ascendancy_allocated.append(str(value))
	if typeof(data.get("passive_atlas_allocated", [])) == TYPE_ARRAY:
		passive_atlas_allocated.clear()
		for passive_value: Variant in data.get("passive_atlas_allocated", []):
			passive_atlas_allocated.append(str(passive_value))
	if typeof(data.get("passive_atlas_refund_stack", [])) == TYPE_ARRAY:
		passive_atlas_refund_stack.clear()
		for refund_value: Variant in data.get("passive_atlas_refund_stack", []):
			passive_atlas_refund_stack.append(str(refund_value))
	passive_atlas_cursor = int(data.get("passive_atlas_cursor", passive_atlas_cursor))
	level = int(data.get("level", level))
	xp = float(data.get("xp", xp))
	mastery_points = int(data.get("mastery_points", mastery_points))
	refund_points = int(data.get("refund_points", refund_points))
	gold = int(data.get("gold", gold))
	if typeof(data.get("materials", {})) == TYPE_DICTIONARY:
		materials.merge(data.get("materials", {}), true)
	if typeof(data.get("active_skills", [])) == TYPE_ARRAY:
		active_skills.clear()
		for active_value: Variant in data.get("active_skills", []):
			active_skills.append(str(active_value))
	if typeof(data.get("unlocked_skills", [])) == TYPE_ARRAY:
		unlocked_skills.clear()
		for unlocked_value: Variant in data.get("unlocked_skills", []):
			unlocked_skills.append(str(unlocked_value))
	selected_skill_index = int(data.get("selected_skill_index", selected_skill_index))
	if typeof(data.get("skill_ranks", {})) == TYPE_DICTIONARY:
		skill_ranks.merge(data.get("skill_ranks", {}), true)
	if typeof(data.get("passive_nodes", {})) == TYPE_DICTIONARY:
		passive_nodes.merge(data.get("passive_nodes", {}), true)
	if typeof(data.get("skill_supports", {})) == TYPE_DICTIONARY:
		skill_supports.merge(data.get("skill_supports", {}), true)
	if typeof(data.get("skill_gem_inventory", [])) == TYPE_ARRAY:
		skill_gem_inventory.clear()
		for gem_value: Variant in data.get("skill_gem_inventory", []):
			if typeof(gem_value) == TYPE_DICTIONARY:
				skill_gem_inventory.append(gem_value)
	if typeof(data.get("support_gem_inventory", [])) == TYPE_ARRAY:
		support_gem_inventory.clear()
		for support_value: Variant in data.get("support_gem_inventory", []):
			if typeof(support_value) == TYPE_DICTIONARY:
				support_gem_inventory.append(support_value)
	if typeof(data.get("spirit_gem_inventory", [])) == TYPE_ARRAY:
		spirit_gem_inventory.clear()
		for spirit_value: Variant in data.get("spirit_gem_inventory", []):
			if typeof(spirit_value) == TYPE_DICTIONARY:
				spirit_gem_inventory.append(spirit_value)
	skill_gem_cursor = int(data.get("skill_gem_cursor", skill_gem_cursor))
	support_gem_cursor = int(data.get("support_gem_cursor", support_gem_cursor))
	spirit_gem_cursor = int(data.get("spirit_gem_cursor", spirit_gem_cursor))
	socket_cursor = int(data.get("socket_cursor", socket_cursor))
	gem_uid_counter = int(data.get("gem_uid_counter", gem_uid_counter))
	if typeof(data.get("equipped", {})) == TYPE_DICTIONARY:
		equipped.merge(data.get("equipped", {}), true)
	if typeof(data.get("backpack", [])) == TYPE_ARRAY:
		backpack.clear()
		for item_value: Variant in data.get("backpack", []):
			if typeof(item_value) == TYPE_DICTIONARY:
				backpack.append(item_value)
	if typeof(data.get("stash", [])) == TYPE_ARRAY:
		stash.clear()
		for stash_value: Variant in data.get("stash", []):
			if typeof(stash_value) == TYPE_DICTIONARY:
				stash.append(stash_value)
	if typeof(data.get("map_stash", [])) == TYPE_ARRAY:
		map_stash.clear()
		for map_value: Variant in data.get("map_stash", []):
			if typeof(map_value) == TYPE_DICTIONARY:
				map_stash.append(map_value)
	map_cursor = int(data.get("map_cursor", map_cursor))
	map_tier_filter = int(data.get("map_tier_filter", map_tier_filter))
	completed_maps = Dictionary(data.get("completed_maps", completed_maps))
	map_system_seeded = bool(data.get("map_system_seeded", map_system_seeded))
	rooms_cleared = int(data.get("rooms_cleared", rooms_cleared))
	kills = int(data.get("kills", kills))
	deaths = int(data.get("deaths", deaths))
	inventory_cursor = int(data.get("inventory_cursor", inventory_cursor))
	stash_cursor = int(data.get("stash_cursor", stash_cursor))
	stash_tab_mode = str(data.get("stash_tab_mode", stash_tab_mode))
	stash_tabs = Dictionary(data.get("stash_tabs", stash_tabs))
	stash_purchased_tabs = Dictionary(data.get("stash_purchased_tabs", stash_purchased_tabs))
	stash_affinities_enabled = bool(data.get("stash_affinities_enabled", stash_affinities_enabled))
	stash_tab_cursor = int(data.get("stash_tab_cursor", stash_tab_cursor))
	stash_upgrade_cost_paid = int(data.get("stash_upgrade_cost_paid", stash_upgrade_cost_paid))
	stash_economy_version = int(data.get("stash_economy_version", stash_economy_version))
	equipment_cursor = int(data.get("equipment_cursor", equipment_cursor))
	loot_filter_preset = str(data.get("loot_filter_preset", loot_filter_preset))
	if typeof(data.get("loot_filter_settings", {})) == TYPE_DICTIONARY:
		loot_filter_settings.merge(data.get("loot_filter_settings", {}), true)
	ensure_defaults()
	recompute_stats()
