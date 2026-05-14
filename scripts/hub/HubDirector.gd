extends Node2D

# RELIC FORGE: VAULTBOUND
# Patch 008 — Hub + Activity Loop
#
# Goal:
# Stop making the player live in overlays during combat.
# The hub is now the activity layer:
# - choose dungeon
# - inspect inventory
# - craft
# - stash
# - loadout
# - character/mastery
# - skill tree / passive tree
#
# Combat should be fighting.
# Build planning belongs in the hub.

var game = null
var persistent = null

var hub_active = false
var current_menu = "none"
var selected_station = -1
var flash_text = ""
var flash_timer = 0.0

var hub_center = Vector2(640, 365)

var stations = [
	{
		"id": "gate",
		"name": "Dungeon Gate",
		"key": "E",
		"pos": Vector2(640, 190),
		"desc": "Start a dungeon run with your current character loadout."
	},
	{
		"id": "character",
		"name": "Character",
		"key": "C",
		"pos": Vector2(300, 295),
		"desc": "View permanent character level, materials, and mastery."
	},
	{
		"id": "passive",
		"name": "Passive Tree",
		"key": "P",
		"pos": Vector2(430, 470),
		"desc": "Spend permanent mastery points into build-defining branches."
	},
	{
		"id": "skilltree",
		"name": "Skill Tree",
		"key": "K",
		"pos": Vector2(640, 535),
		"desc": "Inspect skill XP, owned nodes, and skill identity."
	},
	{
		"id": "loadout",
		"name": "Loadout",
		"key": "L",
		"pos": Vector2(850, 470),
		"desc": "Choose the core skills you bring into dungeon runs."
	},
	{
		"id": "forge",
		"name": "Forge",
		"key": "V",
		"pos": Vector2(980, 295),
		"desc": "Craft persistent gear from dungeon materials."
	},
	{
		"id": "stash",
		"name": "Stash",
		"key": "U",
		"pos": Vector2(640, 325),
		"desc": "Store and withdraw persistent loot."
	}
]

var ui_root = null
var menu_panel = null
var title_label = null
var body_label = null
var footer_label = null
var prompt_label = null
var flash_label = null


func _ready() -> void:
	game = get_parent()
	persistent = game.get_node_or_null("Patch007PersistentRPGDirector")

	_build_ui()
	call_deferred("enter_hub", "Forgehold Hub")

	set_process(true)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	if game == null:
		return

	if _should_respawn_to_hub():
		enter_hub("You died. Returned to the Forgehold.")

	if hub_active:
		_update_station_selection()
		_force_hub_state()
		queue_redraw()

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash_label != null:
			flash_label.visible = false

	_update_menu_text()


func _unhandled_input(event) -> void:
	if game == null:
		return

	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return

	var key = event.keycode

	if not hub_active:
		return

	if current_menu != "none":
		if key == KEY_ESCAPE:
			_close_menu()
			get_viewport().set_input_as_handled()
			return

		_handle_menu_key(key)
		get_viewport().set_input_as_handled()
		return

	if key == KEY_E:
		_activate_selected_station()
		get_viewport().set_input_as_handled()
		return

	if key == KEY_C:
		_open_menu("character")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_P:
		_open_menu("passive")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_K:
		_open_menu("skilltree")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_L:
		_open_menu("loadout")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_V:
		_open_menu("forge")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_U:
		_open_menu("stash")
		get_viewport().set_input_as_handled()
		return


func enter_hub(message = "Forgehold Hub") -> void:
	hub_active = true
	current_menu = "none"

	_clear_dungeon_runtime()
	_restore_player()
	_force_hub_state()

	if menu_panel != null:
		menu_panel.visible = false

	_flash(message)


func _start_dungeon_run() -> void:
	hub_active = false
	current_menu = "none"

	if menu_panel != null:
		menu_panel.visible = false

	_apply_persistent_loadout()

	game.set("run_state", "combat")
	game.set("choice_mode", "")
	game.set("paused_by_choice", false)
	game.set("run_depth", 1)
	game.set("room_index", 1)
	game.set("rooms_cleared", 0)
	game.set("kills", 0)
	game.set("current_room", {
		"name": "Ash Crypt Entry",
		"type": "Combat",
		"biome": "Ash Crypt",
		"mods": [],
		"threat": 1.0,
		"elite": false,
		"treasure": false
	})

	game.set("player_pos", Vector2(640, 370))

	_clear_dungeon_runtime()
	_spawn_starter_combat_room()

	_flash("Dungeon started")


func _force_hub_state() -> void:
	game.set("run_state", "hub")
	game.set("choice_mode", "")
	game.set("paused_by_choice", false)
	game.set("current_room", {
		"name": "Forgehold Hub",
		"type": "Hub",
		"biome": "Forgehold",
		"mods": [],
		"threat": 0.0,
		"elite": false,
		"treasure": false
	})

	game.set("player_pos", hub_center)


func _clear_dungeon_runtime() -> void:
	_set_array("enemies", [])
	_set_array("projectiles", [])
	_set_array("enemy_projectiles", [])
	_set_array("zones", [])
	_set_array("traps", [])
	_set_array("chests", [])
	_set_array("loot", [])
	_set_array("floating_text", [])
	_set_array("minions", [])
	_set_array("delayed_casts", [])
	_set_array("obstacles", [])
	_set_array("room_decor", [])


func _restore_player() -> void:
	var max_hp = 120.0
	var max_mana = 100.0

	if game.has_method("build_stats"):
		var stats = game.call("build_stats")
		if typeof(stats) == TYPE_DICTIONARY:
			max_hp = max(1.0, float(stats.get("max_hp", 120.0)))
			max_mana = max(1.0, float(stats.get("max_mana", 100.0)))

	game.set("player_hp", max_hp)
	game.set("player_mana", max_mana)
	game.set("dash_time", 0.0)
	game.set("dash_cooldown", 0.0)
	game.set("invuln_time", 0.0)


func _spawn_starter_combat_room() -> void:
	var enemies = []
	var center = Vector2(640, 370)

	enemies.append(_enemy("Ash Grunt", center + Vector2(-230, -110), 62.0, 16.0, 82.0, 11.0, "chaser"))
	enemies.append(_enemy("Ash Grunt", center + Vector2(210, -85), 62.0, 16.0, 82.0, 11.0, "chaser"))
	enemies.append(_enemy("Bone Archer", center + Vector2(-250, 125), 48.0, 14.0, 58.0, 9.0, "shooter"))
	enemies.append(_enemy("Cinder Spitter", center + Vector2(245, 120), 66.0, 15.0, 52.0, 10.0, "spitter"))

	game.set("enemies", enemies)

	var obstacles = []
	obstacles.append({"pos": center + Vector2(-120, 0), "radius": 28.0})
	obstacles.append({"pos": center + Vector2(120, 0), "radius": 28.0})
	obstacles.append({"pos": center + Vector2(0, -150), "radius": 24.0})
	game.set("obstacles", obstacles)


func _enemy(name: String, pos: Vector2, hp: float, radius: float, speed: float, damage: float, role: String) -> Dictionary:
	return {
		"name": name,
		"type": name,
		"pos": pos,
		"hp": hp,
		"max_hp": hp,
		"radius": radius,
		"speed": speed,
		"damage": damage,
		"role": role,
		"xp": 20.0,
		"attack_cd": 0.0,
		"shoot_cd": 0.0,
		"status": {},
		"color": _enemy_color(name)
	}


func _enemy_color(name: String) -> Color:
	if name.find("Bone") != -1:
		return Color(0.82, 0.77, 0.62)
	if name.find("Cinder") != -1:
		return Color(0.95, 0.48, 0.12)
	if name.find("Iron") != -1:
		return Color(0.42, 0.45, 0.49)
	return Color(0.72, 0.25, 0.15)


func _should_respawn_to_hub() -> bool:
	if not hub_active and float(game.get("player_hp")) <= 0.0:
		return true
	if str(game.get("run_state")) == "game_over":
		return true
	return false


func _set_array(name: String, value: Array) -> void:
	game.set(name, value)


func _apply_persistent_loadout() -> void:
	persistent = game.get_node_or_null("Patch007PersistentRPGDirector")
	if persistent != null and persistent.has_method("_apply_loadout_to_game"):
		persistent.call("_apply_loadout_to_game")
		return

	var active = game.get("active_skills")
	if typeof(active) != TYPE_ARRAY or active.size() == 0:
		game.set("active_skills", ["Fireball", "Cleave"])
		game.set("selected_skill", 0)


func _update_station_selection() -> void:
	var player_pos = _player_pos()
	var best = -1
	var best_dist = 999999.0

	var i = 0
	for station in stations:
		var d = player_pos.distance_to(station["pos"])
		if d < best_dist:
			best_dist = d
			best = i
		i += 1

	if best_dist <= 95.0:
		selected_station = best
		if prompt_label != null:
			var s = stations[selected_station]
			prompt_label.text = "E  " + str(s["name"]) + "  ·  " + str(s["desc"])
			prompt_label.visible = true
	else:
		selected_station = -1
		if prompt_label != null:
			prompt_label.visible = false


func _activate_selected_station() -> void:
	if selected_station < 0 or selected_station >= stations.size():
		return

	var station = stations[selected_station]
	var id = str(station["id"])

	if id == "gate":
		_start_dungeon_run()
	else:
		_open_menu(id)


func _open_menu(name: String) -> void:
	current_menu = name
	if menu_panel != null:
		menu_panel.visible = true
	_update_menu_text()


func _close_menu() -> void:
	current_menu = "none"
	if menu_panel != null:
		menu_panel.visible = false


func _handle_menu_key(key: int) -> void:
	if current_menu == "forge":
		_forward_to_persistent("_handle_forge_keys", key)
		return

	if current_menu == "passive" or current_menu == "character":
		_forward_to_persistent("_handle_character_keys", key)
		return

	if current_menu == "loadout":
		_forward_to_persistent("_handle_loadout_keys", key)
		return

	if current_menu == "stash":
		_forward_to_persistent("_handle_stash_keys", key)
		return

	if current_menu == "inventory":
		_handle_inventory_key(key)
		return

	if current_menu == "skilltree":
		_handle_skilltree_key(key)
		return


func _forward_to_persistent(method: String, key: int) -> void:
	persistent = game.get_node_or_null("Patch007PersistentRPGDirector")
	if persistent != null and persistent.has_method(method):
		persistent.call(method, key)
		_flash("Updated")
	else:
		_flash("Persistent RPG director not available")


func _handle_inventory_key(key: int) -> void:
	var idx = _number_index(key)
	if idx < 1:
		return

	var inventory = game.get("inventory")
	if typeof(inventory) != TYPE_ARRAY:
		return
	if idx > inventory.size():
		return

	var item = inventory[idx - 1]
	if typeof(item) != TYPE_DICTIONARY:
		return

	var equipped = game.get("equipped")
	if typeof(equipped) != TYPE_DICTIONARY:
		return

	var slot = str(item.get("slot", "relic"))
	if slot == "ring":
		if equipped.get("ring1") == null:
			slot = "ring1"
		else:
			slot = "ring2"

	if not equipped.has(slot):
		slot = "relic"

	var old = equipped.get(slot)
	equipped[slot] = item
	inventory.remove_at(idx - 1)

	if old != null:
		inventory.append(old)

	game.set("equipped", equipped)
	game.set("inventory", inventory)

	_flash("Equipped " + str(item.get("name", "item")))


func _handle_skilltree_key(key: int) -> void:
	# This hub menu is intentionally inspect-first for now.
	# The old skill tree key handling still exists in Main, but Patch 008 moves
	# planning into the hub before we redesign skill nodes properly.
	if key == KEY_O:
		if game.has_method("respec_all"):
			game.call("respec_all")
		_flash("Skill respec requested")
		return

	_flash("Skill tree spending redesign comes next")


func _number_index(key: int) -> int:
	if key >= KEY_1 and key <= KEY_9:
		return key - KEY_1 + 1
	if key >= KEY_KP_1 and key <= KEY_KP_9:
		return key - KEY_KP_1 + 1
	return -1


func _build_ui() -> void:
	ui_root = CanvasLayer.new()
	ui_root.name = "Patch008HubUI"
	ui_root.layer = 80
	add_child(ui_root)

	menu_panel = PanelContainer.new()
	menu_panel.name = "HubActivityPanel"
	menu_panel.position = Vector2(220, 70)
	menu_panel.custom_minimum_size = Vector2(840, 560)
	menu_panel.add_theme_stylebox_override("panel", _style_panel())
	menu_panel.visible = false
	ui_root.add_child(menu_panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	menu_panel.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.72))
	box.add_child(title_label)

	body_label = RichTextLabel.new()
	body_label.fit_content = false
	body_label.scroll_active = true
	body_label.bbcode_enabled = false
	body_label.custom_minimum_size = Vector2(808, 448)
	body_label.add_theme_font_size_override("normal_font_size", 13)
	body_label.add_theme_color_override("default_color", Color(0.82, 0.79, 0.72))
	box.add_child(body_label)

	footer_label = Label.new()
	footer_label.add_theme_font_size_override("font_size", 12)
	footer_label.add_theme_color_override("font_color", Color(0.68, 0.64, 0.58))
	box.add_child(footer_label)

	prompt_label = Label.new()
	prompt_label.position = Vector2(390, 670)
	prompt_label.custom_minimum_size = Vector2(500, 28)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.70))
	prompt_label.add_theme_stylebox_override("normal", _style_chip())
	prompt_label.visible = false
	ui_root.add_child(prompt_label)

	flash_label = Label.new()
	flash_label.position = Vector2(440, 36)
	flash_label.custom_minimum_size = Vector2(400, 30)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash_label.add_theme_font_size_override("font_size", 14)
	flash_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.44))
	flash_label.add_theme_stylebox_override("normal", _style_chip())
	flash_label.visible = false
	ui_root.add_child(flash_label)


func _style_panel() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.018, 0.017, 0.020, 0.96)
	s.border_color = Color(0.76, 0.61, 0.38, 0.42)
	s.set_border_width_all(1)
	s.set_corner_radius_all(14)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s


func _style_chip() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.025, 0.024, 0.028, 0.84)
	s.border_color = Color(0.72, 0.58, 0.35, 0.30)
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _update_menu_text() -> void:
	if current_menu == "none" or menu_panel == null or not menu_panel.visible:
		return

	if current_menu == "character":
		title_label.text = "CHARACTER"
		body_label.text = _character_text()
		footer_label.text = "1-8 spend mastery points · Esc close"
	elif current_menu == "passive":
		title_label.text = "PASSIVE TREE / MASTERY"
		body_label.text = _passive_text()
		footer_label.text = "1-8 spend mastery points · Esc close"
	elif current_menu == "forge":
		title_label.text = "FORGE"
		body_label.text = _forge_text()
		footer_label.text = "1-8 craft item · Esc close"
	elif current_menu == "stash":
		title_label.text = "STASH"
		body_label.text = _stash_text()
		footer_label.text = "T stash backpack · 1-9 withdraw · Esc close"
	elif current_menu == "loadout":
		title_label.text = "LOADOUT"
		body_label.text = _loadout_text()
		footer_label.text = "1-6 toggle skills · Enter apply · Esc close"
	elif current_menu == "skilltree":
		title_label.text = "SKILL TREE"
		body_label.text = _skilltree_text()
		footer_label.text = "O respec request · spending redesign next · Esc close"
	elif current_menu == "inventory":
		title_label.text = "INVENTORY / EQUIPMENT"
		body_label.text = _inventory_text()
		footer_label.text = "1-9 equip backpack item · Esc close"


func _character_text() -> String:
	var save = _save_data()
	if save.is_empty():
		return "No persistent character save found."

	var lines = []
	lines.append("This is your permanent character. Dungeon runs feed this progression.")
	lines.append("")
	lines.append("Level: " + str(int(save.get("character_level", 1))))
	lines.append("XP: " + str(int(float(save.get("character_xp", 0.0)))))
	lines.append("Mastery Points: " + str(int(save.get("mastery_points", 0))))
	lines.append("Highest Depth: " + str(int(save.get("highest_depth", 0))))
	lines.append("Kills Total: " + str(int(save.get("kills_total", 0))))
	lines.append("Rooms Cleared Total: " + str(int(save.get("rooms_cleared_total", 0))))
	lines.append("")
	lines.append("Press P / Passive Tree to spend points.")

	return "\n".join(lines)


func _passive_text() -> String:
	var save = _save_data()
	var mastery = save.get("mastery_alloc", {}) if not save.is_empty() else {}
	var points = int(save.get("mastery_points", 0)) if not save.is_empty() else 0

	var lines = []
	lines.append("Permanent passive tree. This is the long-term build identity.")
	lines.append("Unspent points: " + str(points))
	lines.append("")
	lines.append("1. Ash   [" + str(int(mastery.get("ash", 0))) + "] Fireball, burn, explosions, Fire -> Lightning chains")
	lines.append("2. Frost [" + str(int(mastery.get("frost", 0))) + "] Freeze, Frostfire, shatter setups")
	lines.append("3. Storm [" + str(int(mastery.get("storm", 0))) + "] Chain lightning, cooldown, cascade speed")
	lines.append("4. Void  [" + str(int(mastery.get("void", 0))) + "] Rifts, curses, death bursts, trap gravity")
	lines.append("5. Steel [" + str(int(mastery.get("steel", 0))) + "] Cleave, bleed, melee execution")
	lines.append("6. Trap  [" + str(int(mastery.get("trap", 0))) + "] Blade Trap, poison, trap/rift loops")
	lines.append("7. Blood [" + str(int(mastery.get("blood", 0))) + "] Blood casting, low-resource aggression")
	lines.append("8. Relic [" + str(int(mastery.get("relic", 0))) + "] Global scaling, contract greed, depth scaling")
	lines.append("")
	lines.append("This is not final visual layout yet, but it is now a hub activity instead of a combat overlay.")

	return "\n".join(lines)


func _forge_text() -> String:
	var save = _save_data()
	var mats = save.get("materials", {}) if not save.is_empty() else {}

	var lines = []
	lines.append("Craft persistent gear. Crafted items go to your backpack and stay across runs.")
	lines.append("")
	lines.append("Materials")
	lines.append("Embers: " + str(int(mats.get("embers", 0))))
	lines.append("Shards: " + str(int(mats.get("shards", 0))))
	lines.append("Runes: " + str(int(mats.get("runes", 0))))
	lines.append("Echo Glass: " + str(int(mats.get("echo_glass", 0))))
	lines.append("")
	lines.append("Recipes are handled by Patch 007. Press number keys to craft.")
	lines.append("")
	lines.append("1. Ashen Conductor Weapon")
	lines.append("2. Frostfire Reactor Relic")
	lines.append("3. Void Trap Engine")
	lines.append("4. Butcher's Cleaver")
	lines.append("5. Storm Choir Ring")
	lines.append("6. Blood Debt Heart")
	lines.append("7. Corpse Spark Relic")
	lines.append("8. Contract Eater Amulet")

	return "\n".join(lines)


func _stash_text() -> String:
	var save = _save_data()
	var stash = save.get("stash", []) if not save.is_empty() else []
	var backpack = game.get("inventory")
	if typeof(backpack) != TYPE_ARRAY:
		backpack = []

	var lines = []
	lines.append("Backpack: " + str(backpack.size()) + " items")
	lines.append("Stash: " + str(stash.size()) + " items")
	lines.append("")
	lines.append("Backpack")
	if backpack.size() == 0:
		lines.append("  empty")
	else:
		var idx = 1
		for item in backpack:
			if typeof(item) == TYPE_DICTIONARY:
				lines.append("  " + str(idx) + ". " + str(item.get("name", "Item")) + " [" + str(item.get("rarity", "")) + "]")
				idx += 1
				if idx > 9:
					lines.append("  ...")
					break

	lines.append("")
	lines.append("Stash")
	if stash.size() == 0:
		lines.append("  empty")
	else:
		var sidx = 1
		for item2 in stash:
			if typeof(item2) == TYPE_DICTIONARY:
				lines.append("  " + str(sidx) + ". " + str(item2.get("name", "Item")) + " [" + str(item2.get("rarity", "")) + "]")
				sidx += 1
				if sidx > 9:
					lines.append("  ...")
					break

	return "\n".join(lines)


func _loadout_text() -> String:
	var save = _save_data()
	var loadout = save.get("loadout_skills", []) if not save.is_empty() else game.get("active_skills")

	var lines = []
	lines.append("Choose the core skills your permanent character brings into dungeons.")
	lines.append("Current: " + (", ".join(loadout) if typeof(loadout) == TYPE_ARRAY and loadout.size() > 0 else "none"))
	lines.append("")
	lines.append("1. Fireball")
	lines.append("2. Cleave")
	lines.append("3. Frost Nova")
	lines.append("4. Storm Lance")
	lines.append("5. Void Rift")
	lines.append("6. Blade Trap")
	lines.append("")
	lines.append("Limit is currently 4 core skills. Press Enter to apply.")

	return "\n".join(lines)


func _skilltree_text() -> String:
	var active = game.get("active_skills")
	if typeof(active) != TYPE_ARRAY:
		active = []

	var lines = []
	lines.append("Skill Tree")
	lines.append("")
	lines.append("This needs a full visual node-board pass next.")
	lines.append("For now, this hub screen shows skill progression without blocking combat.")
	lines.append("")

	for skill in active:
		var s = str(skill)
		var points = 0
		var xp = 0.0
		var next = 55.0
		var owned = []

		var skill_points = game.get("skill_points")
		if typeof(skill_points) == TYPE_DICTIONARY:
			points = int(skill_points.get(s, 0))

		var skill_xp = game.get("skill_xp")
		if typeof(skill_xp) == TYPE_DICTIONARY:
			xp = float(skill_xp.get(s, 0.0))

		var skill_xp_next = game.get("skill_xp_next")
		if typeof(skill_xp_next) == TYPE_DICTIONARY:
			next = float(skill_xp_next.get(s, 55.0))

		var owned_skill_nodes = game.get("owned_skill_nodes")
		if typeof(owned_skill_nodes) == TYPE_DICTIONARY:
			owned = owned_skill_nodes.get(s, [])

		lines.append(s)
		lines.append("  Points: " + str(points) + "  XP: " + str(int(xp)) + "/" + str(int(next)))
		lines.append("  Nodes: " + (", ".join(owned) if typeof(owned) == TYPE_ARRAY and owned.size() > 0 else "none"))
		lines.append("")

	return "\n".join(lines)


func _inventory_text() -> String:
	var equipped = game.get("equipped")
	var inventory = game.get("inventory")

	if typeof(equipped) != TYPE_DICTIONARY:
		equipped = {}
	if typeof(inventory) != TYPE_ARRAY:
		inventory = []

	var lines = []
	lines.append("Equipment")
	for slot in equipped.keys():
		var item = equipped.get(slot)
		if typeof(item) == TYPE_DICTIONARY:
			lines.append("  " + str(slot) + ": " + str(item.get("name", "Item")))
		else:
			lines.append("  " + str(slot) + ": empty")

	lines.append("")
	lines.append("Backpack")
	if inventory.size() == 0:
		lines.append("  empty")
	else:
		var idx = 1
		for item2 in inventory:
			if typeof(item2) == TYPE_DICTIONARY:
				lines.append(str(idx) + ". " + str(item2.get("name", "Item")) + " [" + str(item2.get("rarity", "")) + "]")
				lines.append("   " + str(item2.get("desc", "")))
				idx += 1
				if idx > 9:
					lines.append("...")
					break

	return "\n".join(lines)


func _save_data() -> Dictionary:
	persistent = game.get_node_or_null("Patch007PersistentRPGDirector")
	if persistent != null and persistent.has_method("get_save_data"):
		var s = persistent.call("get_save_data")
		if typeof(s) == TYPE_DICTIONARY:
			return s
	return {}


func _player_pos() -> Vector2:
	var p = game.get("player_pos")
	if typeof(p) == TYPE_VECTOR2:
		return p
	return hub_center


func _flash(text: String) -> void:
	flash_text = text
	flash_timer = 2.0
	if flash_label != null:
		flash_label.text = text
		flash_label.visible = true


func _draw() -> void:
	if not hub_active:
		return

	_draw_hub_floor()
	_draw_stations()
	_draw_player_marker()


func _draw_hub_floor() -> void:
	draw_rect(Rect2(Vector2(60, 84), Vector2(1160, 566)), Color(0.020, 0.019, 0.022, 0.90), true)
	draw_rect(Rect2(Vector2(60, 84), Vector2(1160, 566)), Color(0.75, 0.58, 0.34, 0.22), false, 2.0)

	var ring_color = Color(0.75, 0.58, 0.34, 0.12)
	draw_arc(hub_center, 220, -PI, PI, 96, ring_color, 2.0)
	draw_arc(hub_center, 135, -PI, PI, 96, ring_color, 2.0)

	draw_line(Vector2(640, 210), Vector2(640, 520), Color(0.75, 0.58, 0.34, 0.08), 3.0)
	draw_line(Vector2(335, 325), Vector2(945, 325), Color(0.75, 0.58, 0.34, 0.08), 3.0)


func _draw_stations() -> void:
	var i = 0
	for station in stations:
		var pos = station["pos"]
		var selected = i == selected_station
		var radius = 34.0 if selected else 28.0
		var col = _station_color(str(station["id"]))

		draw_circle(pos + Vector2(6, 8), radius, Color(0.0, 0.0, 0.0, 0.30))
		draw_circle(pos, radius, Color(0.035, 0.032, 0.036, 0.96))
		draw_arc(pos, radius + 4.0, -PI, PI, 64, Color(col.r, col.g, col.b, 0.75 if selected else 0.38), 3.0)
		draw_circle(pos, radius * 0.42, Color(col.r, col.g, col.b, 0.72 if selected else 0.48))

		_draw_station_label(pos + Vector2(0, radius + 24), str(station["name"]), selected, col)
		i += 1


func _draw_player_marker() -> void:
	var pos = _player_pos()
	draw_circle(pos + Vector2(4, 7), 18.0, Color(0, 0, 0, 0.32))
	draw_circle(pos, 16.0, Color(0.92, 0.84, 0.68, 0.96))
	draw_arc(pos, 23.0, -PI, PI, 48, Color(1.0, 0.78, 0.38, 0.45), 2.0)


func _draw_station_label(pos: Vector2, text_value: String, selected: bool, col: Color) -> void:
	var font = ThemeDB.fallback_font
	var size_font = 12 if selected else 10
	var text_size = font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font)
	var rect = Rect2(pos - Vector2(text_size.x * 0.5 + 8, 12), Vector2(text_size.x + 16, 22))

	draw_rect(rect, Color(0.016, 0.015, 0.018, 0.78), true)
	draw_rect(rect, Color(col.r, col.g, col.b, 0.35 if selected else 0.18), false, 1.0)
	draw_string(font, pos + Vector2(-text_size.x * 0.5, 4), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font, Color(0.94, 0.88, 0.74, 0.96))


func _station_color(id: String) -> Color:
	match id:
		"gate":
			return Color(0.90, 0.38, 1.0, 0.95)
		"forge":
			return Color(1.0, 0.48, 0.16, 0.95)
		"stash":
			return Color(0.94, 0.78, 0.35, 0.95)
		"loadout":
			return Color(0.52, 0.82, 1.0, 0.95)
		"character":
			return Color(0.90, 0.82, 0.62, 0.95)
		"skilltree":
			return Color(0.58, 1.0, 0.72, 0.95)
		"passive":
			return Color(0.72, 0.58, 1.0, 0.95)
		_:
			return Color(0.90, 0.84, 0.70, 0.95)
