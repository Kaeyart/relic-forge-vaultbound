extends Node2D

# RELIC FORGE: VAULTBOUND
# Patch 010 — Physical Hub, No Menus
#
# Design correction:
# The hub is a physical place.
# The player should walk to things and interact with them.
# No command-center menu. No giant overlay hub screens.
#
# Activities are world objects:
# - contract gates
# - forge anvils
# - stash chest
# - armory racks
# - passive shrines
# - skill altars
# - loadout stones

const SAVE_PATH = "user://relic_forge_patch009_arpg_save.json"

const SKILLS = ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"]
const PASSIVES = ["ash", "frost", "storm", "void", "steel", "trap", "blood", "relic"]
const SLOTS = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring1", "ring2", "relic"]

var game = null
var rng = RandomNumberGenerator.new()

var save = {}
var dirty = false
var autosave_timer = 0.0

var mode = "hub"
var hub_center = Vector2(640, 370)
var current_focus = {}
var prompt_text = ""
var notice_text = ""
var notice_timer = 0.0

var last_kills = 0
var last_rooms_cleared = 0

var contracts = []
var forge_recipes = []
var hub_objects = []

var ui = null
var prompt_label = null
var status_label = null
var notice_label = null

func _ready() -> void:
	game = get_parent()
	rng.randomize()

	_disable_menu_directors()
	_load_save()
	_make_contracts()
	_make_recipes()
	_build_hub_objects()
	_build_minimal_ui()

	call_deferred("enter_hub", "Forgehold")

	set_process(true)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	if game == null:
		return

	if mode == "hub":
		_keep_hub_state()
		_update_focus()

	if mode == "combat":
		_watch_combat_rewards()
		if float(game.get("player_hp")) <= 0.0:
			_death_return_to_hub()

	autosave_timer += delta
	if autosave_timer >= 3.0:
		autosave_timer = 0.0
		if dirty:
			_save()

	if notice_timer > 0.0:
		notice_timer -= delta
		if notice_timer <= 0.0 and notice_label != null:
			notice_label.visible = false

	_update_minimal_ui()
	queue_redraw()


func _unhandled_input(event) -> void:
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return

	var key = event.keycode

	if mode == "combat":
		if key == KEY_ESCAPE:
			enter_hub("Returned to Forgehold")
			get_viewport().set_input_as_handled()
		return

	if mode != "hub":
		return

	if key == KEY_E:
		_interact_focus()
		get_viewport().set_input_as_handled()
		return

	if key == KEY_X:
		_secondary_focus()
		get_viewport().set_input_as_handled()
		return

	if key == KEY_F5:
		_save()
		_notice("Saved")
		get_viewport().set_input_as_handled()
		return


func _disable_menu_directors() -> void:
	var names = [
		"Patch006CombatBuildDirector",
		"Patch007PersistentRPGDirector",
		"Patch008HubDirector",
		"Patch009ARPGMegaDirector"
	]

	for n in names:
		var node = get_parent().get_node_or_null(n)
		if node != null:
			node.queue_free()


func _load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			save = parsed
		else:
			save = _default_save()
	else:
		save = _default_save()

	_normalize_save()
	_save()


func _default_save() -> Dictionary:
	return {
		"version": 10,
		"name": "Vaultbound",
		"level": 1,
		"xp": 0.0,
		"mastery_points": 0,
		"gold": 0,
		"materials": {
			"embers": 12,
			"shards": 6,
			"runes": 0,
			"echo_glass": 0
		},
		"equipped": {
			"weapon": _starter_item(),
			"offhand": null,
			"head": null,
			"chest": null,
			"gloves": null,
			"boots": null,
			"amulet": null,
			"ring1": null,
			"ring2": null,
			"relic": null
		},
		"backpack": [],
		"stash": [],
		"loadout": ["Fireball", "Cleave"],
		"passives": {
			"ash": 0,
			"frost": 0,
			"storm": 0,
			"void": 0,
			"steel": 0,
			"trap": 0,
			"blood": 0,
			"relic": 0
		},
		"skill_board": {
			"Fireball": 0,
			"Cleave": 0,
			"Frost Nova": 0,
			"Storm Lance": 0,
			"Void Rift": 0,
			"Blade Trap": 0
		},
		"stats": {
			"kills_total": 0,
			"rooms_total": 0,
			"runs_total": 0,
			"deaths": 0,
			"highest_contract": 1,
			"items_crafted": 0
		}
	}


func _starter_item() -> Dictionary:
	return {
		"name": "Cracked Initiate Focus",
		"slot": "weapon",
		"rarity": "Starter",
		"desc": "Starter weapon.",
		"stats": {"spell_damage": 0.04},
		"flags": []
	}


func _normalize_save() -> void:
	var base = _default_save()

	for k in base.keys():
		if not save.has(k):
			save[k] = base[k]

	for k2 in base["materials"].keys():
		if not save["materials"].has(k2):
			save["materials"][k2] = base["materials"][k2]

	for slot in SLOTS:
		if not save["equipped"].has(slot):
			save["equipped"][slot] = null

	for p in PASSIVES:
		if not save["passives"].has(p):
			save["passives"][p] = 0

	for s in SKILLS:
		if not save["skill_board"].has(s):
			save["skill_board"][s] = 0

	for stat in base["stats"].keys():
		if not save["stats"].has(stat):
			save["stats"][stat] = 0

	dirty = true


func _save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save, "\t"))
	dirty = false


func _dirty() -> void:
	dirty = true


func _make_contracts() -> void:
	contracts = [
		{
			"id": "ash_crypt",
			"name": "Ash Crypt",
			"tier": 1,
			"pos": Vector2(530, 165),
			"biome": "Ash Crypt",
			"threat": 1.0,
			"length": 5,
			"color": Color(1.0, 0.34, 0.14),
			"desc": "Fire, melee, early loot."
		},
		{
			"id": "bone_archive",
			"name": "Bone Archive",
			"tier": 2,
			"pos": Vector2(640, 140),
			"biome": "Bone Archive",
			"threat": 1.35,
			"length": 7,
			"color": Color(0.90, 0.82, 0.62),
			"desc": "Cold, lightning, archers."
		},
		{
			"id": "void_foundry",
			"name": "Void Foundry",
			"tier": 3,
			"pos": Vector2(750, 165),
			"biome": "Void Foundry",
			"threat": 1.75,
			"length": 9,
			"color": Color(0.70, 0.36, 1.0),
			"desc": "Void, traps, relics."
		},
		{
			"id": "hungry_forge",
			"name": "Hungry Forge",
			"tier": 4,
			"pos": Vector2(640, 220),
			"biome": "Hungry Forge",
			"threat": 2.25,
			"length": 11,
			"color": Color(1.0, 0.62, 0.20),
			"desc": "High risk, better loot."
		}
	]


func _make_recipes() -> void:
	forge_recipes = [
		{
			"name": "Ashen Conductor",
			"slot": "weapon",
			"pos": Vector2(940, 230),
			"cost": {"embers": 18, "shards": 6},
			"stats": {"fire_damage": 0.20, "lightning_damage": 0.10, "spell_damage": 0.08},
			"flags": ["fire_calls_lance", "cascade_engine"],
			"color": Color(1.0, 0.34, 0.12),
			"desc": "Fireball begins feeding lightning chains."
		},
		{
			"name": "Frostfire Reactor",
			"slot": "relic",
			"pos": Vector2(1035, 285),
			"cost": {"embers": 12, "shards": 12, "echo_glass": 1},
			"stats": {"fire_damage": 0.12, "cold_damage": 0.18, "freeze_duration": 0.25},
			"flags": ["frostfire_steam", "nova_calls_fire"],
			"color": Color(0.42, 0.82, 1.0),
			"desc": "Freeze then ignite for steam detonations."
		},
		{
			"name": "Void Trap Engine",
			"slot": "offhand",
			"pos": Vector2(945, 345),
			"cost": {"shards": 14, "runes": 2},
			"stats": {"void_damage": 0.20, "trap_damage": 0.18, "max_mana": 18.0},
			"flags": ["trap_calls_rift", "rift_calls_trap", "rift_pull"],
			"color": Color(0.70, 0.36, 1.0),
			"desc": "Blade Trap and Void Rift feed each other."
		},
		{
			"name": "Butcher Moon Cleaver",
			"slot": "weapon",
			"pos": Vector2(1040, 400),
			"cost": {"embers": 16, "runes": 1},
			"stats": {"melee_damage": 0.30, "max_hp": 22.0},
			"flags": ["slash_bleed", "cleave_wave", "execute_low_hp"],
			"color": Color(1.0, 0.78, 0.42),
			"desc": "Cleave becomes bleed/wave execution."
		},
		{
			"name": "Storm Choir Ring",
			"slot": "ring",
			"pos": Vector2(940, 460),
			"cost": {"shards": 12, "echo_glass": 2},
			"stats": {"lightning_damage": 0.26, "cooldown_reduction": 0.04},
			"flags": ["chain_plus", "lance_calls_nova"],
			"color": Color(0.72, 0.92, 1.0),
			"desc": "Lightning chains harder."
		}
	]


func _build_hub_objects() -> void:
	hub_objects.clear()

	for c in contracts:
		hub_objects.append({
			"type": "contract",
			"name": c["name"],
			"pos": c["pos"],
			"data": c,
			"color": c["color"],
			"hint": "E start " + str(c["name"]) + " · " + str(c["desc"])
		})

	for r in forge_recipes:
		hub_objects.append({
			"type": "forge",
			"name": r["name"],
			"pos": r["pos"],
			"data": r,
			"color": r["color"],
			"hint": "E craft " + str(r["name"]) + " · cost " + _cost_line(r["cost"])
		})

	var passive_positions = [
		Vector2(250, 250),
		Vector2(330, 210),
		Vector2(410, 250),
		Vector2(250, 365),
		Vector2(410, 365),
		Vector2(250, 480),
		Vector2(330, 520),
		Vector2(410, 480)
	]

	var i = 0
	for p in PASSIVES:
		hub_objects.append({
			"type": "passive",
			"name": p.capitalize() + " Shrine",
			"pos": passive_positions[i],
			"data": p,
			"color": _passive_color(p),
			"hint": "E spend mastery in " + p.capitalize()
		})
		i += 1

	var skill_positions = [
		Vector2(535, 530),
		Vector2(610, 560),
		Vector2(685, 560),
		Vector2(760, 530),
		Vector2(575, 610),
		Vector2(725, 610)
	]

	i = 0
	for s in SKILLS:
		hub_objects.append({
			"type": "skill",
			"name": s + " Altar",
			"pos": skill_positions[i],
			"data": s,
			"color": _skill_color(s),
			"hint": "E upgrade " + s + " · X toggle loadout"
		})
		i += 1

	hub_objects.append({
		"type": "stash_deposit",
		"name": "Stash Chest",
		"pos": Vector2(640, 355),
		"data": {},
		"color": Color(0.95, 0.78, 0.34),
		"hint": "E deposit backpack into stash"
	})

	hub_objects.append({
		"type": "armory",
		"name": "Armory Rack",
		"pos": Vector2(690, 355),
		"data": {},
		"color": Color(0.86, 0.78, 0.62),
		"hint": "E equip first backpack item · X salvage first backpack item"
	})

	_refresh_dynamic_item_objects()


func _refresh_dynamic_item_objects() -> void:
	var kept = []
	for obj in hub_objects:
		if str(obj.get("type", "")) != "stash_item" and str(obj.get("type", "")) != "backpack_item":
			kept.append(obj)
	hub_objects = kept

	var stash = save["stash"]
	var backpack = save["backpack"]

	var i = 0
	while i < min(6, stash.size()):
		var item = stash[i]
		if typeof(item) == TYPE_DICTIONARY:
			var pos = Vector2(575 + float(i % 3) * 65.0, 415 + float(i / 3) * 58.0)
			hub_objects.append({
				"type": "stash_item",
				"name": str(item.get("name", "Stash Item")),
				"pos": pos,
				"data": i,
				"color": _rarity_color(str(item.get("rarity", "Magic"))),
				"hint": "E withdraw " + str(item.get("name", "item"))
			})
		i += 1

	i = 0
	while i < min(6, backpack.size()):
		var item2 = backpack[i]
		if typeof(item2) == TYPE_DICTIONARY:
			var pos2 = Vector2(745 + float(i % 3) * 65.0, 415 + float(i / 3) * 58.0)
			hub_objects.append({
				"type": "backpack_item",
				"name": str(item2.get("name", "Backpack Item")),
				"pos": pos2,
				"data": i,
				"color": _rarity_color(str(item2.get("rarity", "Magic"))),
				"hint": "E equip " + str(item2.get("name", "item")) + " · X salvage"
			})
		i += 1


func _build_minimal_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "Patch010PhysicalHubUI"
	ui.layer = 100
	add_child(ui)

	status_label = Label.new()
	status_label.position = Vector2(14, 14)
	status_label.custom_minimum_size = Vector2(1250, 28)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74))
	status_label.add_theme_stylebox_override("normal", _chip_style())
	ui.add_child(status_label)

	prompt_label = Label.new()
	prompt_label.position = Vector2(340, 668)
	prompt_label.custom_minimum_size = Vector2(600, 28)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.68))
	prompt_label.add_theme_stylebox_override("normal", _chip_style())
	prompt_label.visible = false
	ui.add_child(prompt_label)

	notice_label = Label.new()
	notice_label.position = Vector2(440, 50)
	notice_label.custom_minimum_size = Vector2(400, 30)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.add_theme_font_size_override("font_size", 14)
	notice_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.44))
	notice_label.add_theme_stylebox_override("normal", _chip_style())
	notice_label.visible = false
	ui.add_child(notice_label)


func _chip_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.018, 0.017, 0.020, 0.82)
	s.border_color = Color(0.70, 0.56, 0.34, 0.26)
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _update_minimal_ui() -> void:
	if status_label == null:
		return

	if mode == "hub":
		status_label.text = _hub_status_line()
	else:
		status_label.text = "Dungeon · Esc return to Forgehold · " + _character_line()

	if prompt_label != null:
		prompt_label.text = prompt_text
		prompt_label.visible = mode == "hub" and prompt_text != ""


func _hub_status_line() -> String:
	return "Forgehold · " + _character_line() + " · Walk to stations, E interact, X secondary, F5 save"


func _character_line() -> String:
	var mats = save["materials"]
	var line = "Lv " + str(int(save["level"]))
	line += " XP " + str(int(float(save["xp"]))) + "/" + str(int(_xp_to_next(int(save["level"]))))
	line += " MP " + str(int(save["mastery_points"]))
	line += " Gold " + str(int(save["gold"]))
	line += " Embers " + str(int(mats["embers"]))
	line += " Shards " + str(int(mats["shards"]))
	line += " Runes " + str(int(mats["runes"]))
	line += " Echo " + str(int(mats["echo_glass"]))
	line += " Loadout " + _join(save["loadout"])
	return line


func enter_hub(message: String) -> void:
	mode = "hub"

	_clear_runtime()
	_apply_save_to_game()
	_restore_player()

	game.set("run_state", "hub")
	game.set("choice_mode", "")
	game.set("paused_by_choice", false)
	game.set("current_room", {
		"name": "Forgehold",
		"type": "Hub",
		"biome": "Forgehold",
		"mods": [],
		"threat": 0.0,
		"elite": false,
		"treasure": false
	})
	game.set("player_pos", hub_center)

	_notice(message)
	_refresh_dynamic_item_objects()


func _keep_hub_state() -> void:
	game.set("run_state", "hub")
	game.set("choice_mode", "")
	game.set("paused_by_choice", false)

	var p = _player_pos()
	var min_x = 110.0
	var max_x = 1170.0
	var min_y = 120.0
	var max_y = 640.0
	p.x = clamp(p.x, min_x, max_x)
	p.y = clamp(p.y, min_y, max_y)
	game.set("player_pos", p)


func _update_focus() -> void:
	current_focus = {}
	prompt_text = ""

	var p = _player_pos()
	var best_dist = 99999.0
	var best = {}

	for obj in hub_objects:
		var d = p.distance_to(obj["pos"])
		if d < best_dist:
			best_dist = d
			best = obj

	if best_dist <= 52.0:
		current_focus = best
		prompt_text = str(best.get("hint", ""))


func _interact_focus() -> void:
	if current_focus.is_empty():
		return

	var type = str(current_focus.get("type", ""))

	match type:
		"contract":
			_start_contract(current_focus["data"])
		"forge":
			_craft_recipe(current_focus["data"])
		"passive":
			_spend_passive(str(current_focus["data"]))
		"skill":
			_upgrade_skill(str(current_focus["data"]))
		"stash_deposit":
			_deposit_backpack_to_stash()
		"stash_item":
			_withdraw_stash_item(int(current_focus["data"]))
		"backpack_item":
			_equip_backpack_item(int(current_focus["data"]))
		"armory":
			_equip_backpack_item(0)


func _secondary_focus() -> void:
	if current_focus.is_empty():
		return

	var type = str(current_focus.get("type", ""))

	if type == "skill":
		_toggle_loadout_skill(str(current_focus["data"]))
	elif type == "backpack_item":
		_salvage_backpack_item(int(current_focus["data"]))
	elif type == "armory":
		_salvage_backpack_item(0)


func _start_contract(contract: Dictionary) -> void:
	mode = "combat"

	save["stats"]["runs_total"] = int(save["stats"]["runs_total"]) + 1
	_dirty()

	_apply_save_to_game()
	_restore_player()
	_clear_runtime()

	game.set("run_state", "combat")
	game.set("choice_mode", "")
	game.set("paused_by_choice", false)
	game.set("run_depth", 1)
	game.set("room_index", 1)
	game.set("rooms_cleared", 0)
	game.set("kills", 0)
	game.set("player_pos", Vector2(640, 370))
	game.set("current_room", {
		"name": str(contract["name"]),
		"type": "Contract",
		"biome": str(contract["biome"]),
		"mods": [],
		"threat": float(contract["threat"]),
		"elite": false,
		"treasure": false,
		"contract_length": int(contract["length"])
	})

	_spawn_contract_room(contract)
	_notice("Entered " + str(contract["name"]))


func _spawn_contract_room(contract: Dictionary) -> void:
	var enemies = []
	var center = Vector2(640, 370)
	var tier = int(contract["tier"])
	var threat = float(contract["threat"])
	var count = 4 + tier * 2

	var i = 0
	while i < count:
		var angle = TAU * float(i) / float(count)
		var pos = center + Vector2(cos(angle), sin(angle)) * (175.0 + float(i % 3) * 34.0)

		var name = "Ash Grunt"
		var role = "chaser"
		var hp = 58.0 * threat
		var radius = 16.0
		var speed = 80.0
		var damage = 10.0 * threat

		if tier >= 2 and i % 4 == 1:
			name = "Bone Archer"
			role = "shooter"
			hp = 48.0 * threat
			radius = 14.0
			speed = 58.0
			damage = 9.0 * threat
		elif tier >= 2 and i % 4 == 2:
			name = "Cinder Spitter"
			role = "spitter"
			hp = 66.0 * threat
			radius = 15.0
			speed = 52.0
			damage = 11.0 * threat
		elif tier >= 3 and i % 5 == 0:
			name = "Iron Brute"
			role = "brute"
			hp = 150.0 * threat
			radius = 24.0
			speed = 46.0
			damage = 22.0 * threat

		enemies.append(_enemy(name, pos, hp, radius, speed, damage, role))
		i += 1

	game.set("enemies", enemies)

	var obstacles = []
	obstacles.append({"pos": center + Vector2(-150, -40), "radius": 30.0})
	obstacles.append({"pos": center + Vector2(150, 40), "radius": 30.0})
	obstacles.append({"pos": center + Vector2(0, -155), "radius": 26.0})
	obstacles.append({"pos": center + Vector2(0, 155), "radius": 26.0})
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


func _watch_combat_rewards() -> void:
	var kills = int(game.get("kills"))
	if kills > last_kills:
		var gained = kills - last_kills
		var i = 0
		while i < gained:
			_award_kill()
			i += 1
	last_kills = kills

	var rooms = int(game.get("rooms_cleared"))
	if rooms > last_rooms_cleared:
		var gained_rooms = rooms - last_rooms_cleared
		var r = 0
		while r < gained_rooms:
			_award_room()
			r += 1
	last_rooms_cleared = rooms


func _award_kill() -> void:
	var depth = max(1, int(game.get("run_depth")))
	_add_xp(10.0 + float(depth) * 2.0)
	save["gold"] = int(save["gold"]) + 2 + depth

	var mats = save["materials"]
	mats["embers"] = int(mats["embers"]) + 1
	if rng.randf() < 0.16:
		mats["shards"] = int(mats["shards"]) + 1
	if rng.randf() < 0.045:
		mats["runes"] = int(mats["runes"]) + 1

	save["stats"]["kills_total"] = int(save["stats"]["kills_total"]) + 1

	if rng.randf() < 0.12:
		save["backpack"].append(_generate_drop(depth))
		_notice("Loot added to backpack")

	_dirty()


func _award_room() -> void:
	var depth = max(1, int(game.get("run_depth")))
	_add_xp(45.0 + float(depth) * 7.0)
	save["gold"] = int(save["gold"]) + 12 + depth * 3

	var mats = save["materials"]
	mats["shards"] = int(mats["shards"]) + 3
	if depth % 3 == 0:
		mats["runes"] = int(mats["runes"]) + 1
	if depth % 5 == 0:
		mats["echo_glass"] = int(mats["echo_glass"]) + 1

	save["backpack"].append(_generate_drop(depth))
	save["stats"]["rooms_total"] = int(save["stats"]["rooms_total"]) + 1
	_notice("Room reward added to backpack")
	_dirty()


func _add_xp(amount: float) -> void:
	save["xp"] = float(save["xp"]) + amount
	var level = int(save["level"])

	while float(save["xp"]) >= _xp_to_next(level):
		save["xp"] = float(save["xp"]) - _xp_to_next(level)
		level += 1
		save["mastery_points"] = int(save["mastery_points"]) + 1
		_notice("LEVEL UP · Mastery point gained")

	save["level"] = level
	_dirty()


func _xp_to_next(level: int) -> float:
	return 160.0 + pow(float(level), 1.35) * 70.0


func _generate_drop(depth: int) -> Dictionary:
	var slots = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]
	var slot = slots[rng.randi_range(0, slots.size() - 1)]

	var rarity = "Magic"
	var roll = rng.randf()
	if roll > 0.94:
		rarity = "Legendary"
	elif roll > 0.72:
		rarity = "Rare"

	var family = rng.randi_range(0, 7)
	var name = ""
	var stats = {}
	var flags = []
	var desc = ""

	if family == 0:
		name = "Ash"
		stats = {"fire_damage": 0.08 + depth * 0.006}
		if rarity == "Legendary":
			flags.append("fire_calls_lance")
		desc = "Fire scaling gear."
	elif family == 1:
		name = "Frost"
		stats = {"cold_damage": 0.08 + depth * 0.006, "freeze_duration": 0.04}
		if rarity == "Legendary":
			flags.append("frostfire_steam")
		desc = "Cold and freeze setup gear."
	elif family == 2:
		name = "Storm"
		stats = {"lightning_damage": 0.08 + depth * 0.006, "cooldown_reduction": 0.01}
		if rarity != "Magic":
			flags.append("chain_plus")
		desc = "Lightning and cooldown gear."
	elif family == 3:
		name = "Void"
		stats = {"void_damage": 0.08 + depth * 0.006, "max_mana": 5.0 + depth}
		if rarity != "Magic":
			flags.append("rift_pull")
		desc = "Void and mana gear."
	elif family == 4:
		name = "Butcher"
		stats = {"melee_damage": 0.09 + depth * 0.006, "max_hp": 5.0 + depth}
		if rarity != "Magic":
			flags.append("slash_bleed")
		desc = "Melee and bleed gear."
	elif family == 5:
		name = "Trapwright"
		stats = {"trap_damage": 0.10 + depth * 0.006}
		if rarity != "Magic":
			flags.append("double_trap")
		desc = "Trap scaling gear."
	elif family == 6:
		name = "Blood"
		stats = {"spell_damage": 0.06 + depth * 0.005, "max_hp": 8.0 + depth}
		if rarity == "Legendary":
			flags.append("blood_cast")
		desc = "Risk/reward caster gear."
	else:
		name = "Relic-Bound"
		stats = {"global_damage": 0.04 + depth * 0.004}
		if rarity == "Legendary":
			flags.append("contract_eater")
		desc = "Global build scaling gear."

	if rarity == "Rare":
		stats["max_mana"] = float(stats.get("max_mana", 0.0)) + 8.0 + depth
	if rarity == "Legendary":
		stats["global_damage"] = float(stats.get("global_damage", 0.0)) + 0.08
		flags.append("cascade_engine")

	return {
		"name": rarity + " " + name + " " + _slot_label(slot),
		"slot": slot,
		"rarity": rarity,
		"desc": desc + " Dropped at depth " + str(depth) + ".",
		"stats": stats,
		"flags": flags,
		"drop_depth": depth
	}


func _craft_recipe(recipe: Dictionary) -> void:
	if not _can_pay(recipe["cost"]):
		_notice("Not enough materials")
		return

	_pay(recipe["cost"])
	var item = _crafted_item(recipe)
	save["backpack"].append(item)
	save["stats"]["items_crafted"] = int(save["stats"]["items_crafted"]) + 1
	_notice("Crafted " + str(item["name"]))
	_refresh_dynamic_item_objects()
	_dirty()


func _crafted_item(recipe: Dictionary) -> Dictionary:
	var level = int(save["level"])
	var power = 1.0 + float(level) * 0.025
	var stats = {}

	for k in recipe["stats"].keys():
		stats[k] = float(recipe["stats"][k]) * power

	return {
		"name": str(recipe["name"]) + " +" + str(max(1, level / 3)),
		"slot": str(recipe["slot"]),
		"rarity": "Crafted",
		"desc": str(recipe["desc"]) + " Crafted at level " + str(level) + ".",
		"stats": stats,
		"flags": recipe["flags"].duplicate(true),
		"crafted_level": level
	}


func _can_pay(cost: Dictionary) -> bool:
	for k in cost.keys():
		if int(save["materials"].get(k, 0)) < int(cost[k]):
			return false
	return true


func _pay(cost: Dictionary) -> void:
	for k in cost.keys():
		save["materials"][k] = int(save["materials"].get(k, 0)) - int(cost[k])


func _spend_passive(branch: String) -> void:
	if int(save["mastery_points"]) <= 0:
		_notice("No mastery points")
		return

	save["passives"][branch] = int(save["passives"].get(branch, 0)) + 1
	save["mastery_points"] = int(save["mastery_points"]) - 1
	_apply_save_to_game()
	_notice(branch.capitalize() + " mastery gained")
	_dirty()


func _upgrade_skill(skill: String) -> void:
	var rank = int(save["skill_board"].get(skill, 0))
	var gold_cost = 60 + rank * 45
	var shard_cost = 2 + rank

	if int(save["gold"]) < gold_cost:
		_notice("Need " + str(gold_cost) + " gold")
		return

	if int(save["materials"]["shards"]) < shard_cost:
		_notice("Need " + str(shard_cost) + " shards")
		return

	save["gold"] = int(save["gold"]) - gold_cost
	save["materials"]["shards"] = int(save["materials"]["shards"]) - shard_cost
	save["skill_board"][skill] = rank + 1
	_apply_save_to_game()
	_notice(skill + " upgraded")
	_dirty()


func _toggle_loadout_skill(skill: String) -> void:
	if save["loadout"].has(skill):
		save["loadout"].erase(skill)
		_notice(skill + " removed from loadout")
	else:
		if save["loadout"].size() >= 4:
			_notice("Loadout limit: 4")
			return
		save["loadout"].append(skill)
		_notice(skill + " added to loadout")

	_apply_save_to_game()
	_dirty()


func _deposit_backpack_to_stash() -> void:
	for item in save["backpack"]:
		save["stash"].append(item)

	save["backpack"].clear()
	_refresh_dynamic_item_objects()
	_notice("Backpack deposited into stash")
	_dirty()


func _withdraw_stash_item(index: int) -> void:
	if index < 0 or index >= save["stash"].size():
		return

	var item = save["stash"][index]
	save["stash"].remove_at(index)
	save["backpack"].append(item)
	_refresh_dynamic_item_objects()
	_notice("Withdrew " + str(item.get("name", "item")))
	_dirty()


func _equip_backpack_item(index: int) -> void:
	if index < 0 or index >= save["backpack"].size():
		_notice("Backpack empty")
		return

	var item = save["backpack"][index]
	if typeof(item) != TYPE_DICTIONARY:
		return

	var slot = str(item.get("slot", "relic"))
	if slot == "ring":
		if save["equipped"].get("ring1") == null:
			slot = "ring1"
		else:
			slot = "ring2"

	if not save["equipped"].has(slot):
		slot = "relic"

	var old = save["equipped"].get(slot)
	save["equipped"][slot] = item
	save["backpack"].remove_at(index)

	if old != null:
		save["backpack"].append(old)

	_apply_save_to_game()
	_refresh_dynamic_item_objects()
	_notice("Equipped " + str(item.get("name", "item")))
	_dirty()


func _salvage_backpack_item(index: int) -> void:
	if index < 0 or index >= save["backpack"].size():
		_notice("No backpack item")
		return

	var item = save["backpack"][index]
	save["backpack"].remove_at(index)

	var rarity = str(item.get("rarity", "Magic"))
	save["materials"]["embers"] = int(save["materials"]["embers"]) + 3
	save["materials"]["shards"] = int(save["materials"]["shards"]) + 1

	if rarity == "Rare":
		save["materials"]["shards"] = int(save["materials"]["shards"]) + 3
	if rarity == "Legendary" or rarity == "Crafted":
		save["materials"]["runes"] = int(save["materials"]["runes"]) + 1
		save["materials"]["echo_glass"] = int(save["materials"]["echo_glass"]) + 1

	_refresh_dynamic_item_objects()
	_notice("Salvaged " + str(item.get("name", "item")))
	_dirty()


func _apply_save_to_game() -> void:
	game.set("equipped", save["equipped"].duplicate(true))
	game.set("inventory", save["backpack"].duplicate(true))
	game.set("active_skills", save["loadout"].duplicate(true))
	game.set("selected_skill", 0)
	_install_progression_soul()


func _install_progression_soul() -> void:
	var equipped = game.get("equipped")
	if typeof(equipped) != TYPE_DICTIONARY:
		return

	equipped["soul"] = {
		"name": "Character Progression Soul",
		"slot": "soul",
		"rarity": "Permanent",
		"desc": "Permanent character/passive/skill-board power.",
		"stats": _computed_stats(),
		"flags": _computed_flags()
	}

	game.set("equipped", equipped)


func _computed_stats() -> Dictionary:
	var stats = {
		"max_hp": float(int(save["level"]) - 1) * 5.0,
		"max_mana": float(int(save["level"]) - 1) * 2.0,
		"global_damage": min(0.50, float(int(save["level"]) - 1) * 0.006)
	}

	var p = save["passives"]
	_add_stat(stats, "fire_damage", int(p["ash"]) * 0.055)
	_add_stat(stats, "cold_damage", int(p["frost"]) * 0.055)
	_add_stat(stats, "lightning_damage", int(p["storm"]) * 0.055)
	_add_stat(stats, "void_damage", int(p["void"]) * 0.055)
	_add_stat(stats, "melee_damage", int(p["steel"]) * 0.060)
	_add_stat(stats, "trap_damage", int(p["trap"]) * 0.060)
	_add_stat(stats, "spell_damage", int(p["blood"]) * 0.040)
	_add_stat(stats, "global_damage", int(p["relic"]) * 0.025)

	var b = save["skill_board"]
	_add_stat(stats, "fire_damage", int(b["Fireball"]) * 0.035)
	_add_stat(stats, "melee_damage", int(b["Cleave"]) * 0.035)
	_add_stat(stats, "cold_damage", int(b["Frost Nova"]) * 0.035)
	_add_stat(stats, "lightning_damage", int(b["Storm Lance"]) * 0.035)
	_add_stat(stats, "void_damage", int(b["Void Rift"]) * 0.035)
	_add_stat(stats, "trap_damage", int(b["Blade Trap"]) * 0.035)

	return stats


func _add_stat(stats: Dictionary, key: String, value: float) -> void:
	if not stats.has(key):
		stats[key] = 0.0
	stats[key] = float(stats[key]) + value


func _computed_flags() -> Array:
	var flags = []
	var p = save["passives"]

	_add_flag_at(flags, p, "ash", 2, "fire_calls_lance")
	_add_flag_at(flags, p, "ash", 4, "burn_death_explode")
	_add_flag_at(flags, p, "frost", 2, "nova_calls_fire")
	_add_flag_at(flags, p, "frost", 4, "frostfire_steam")
	_add_flag_at(flags, p, "storm", 2, "chain_plus")
	_add_flag_at(flags, p, "storm", 5, "lance_calls_nova")
	_add_flag_at(flags, p, "void", 2, "rift_pull")
	_add_flag_at(flags, p, "void", 4, "rift_calls_trap")
	_add_flag_at(flags, p, "steel", 2, "slash_bleed")
	_add_flag_at(flags, p, "steel", 4, "cleave_wave")
	_add_flag_at(flags, p, "trap", 2, "double_trap")
	_add_flag_at(flags, p, "trap", 4, "trap_calls_rift")
	_add_flag_at(flags, p, "blood", 2, "blood_cast")
	_add_flag_at(flags, p, "blood", 4, "blood_orbs")
	_add_flag_at(flags, p, "relic", 2, "contract_eater")
	_add_flag_at(flags, p, "relic", 4, "depth_scaling")

	var board = save["skill_board"]
	if int(board["Fireball"]) >= 3:
		_add_unique(flags, "fire_calls_lance")
	if int(board["Frost Nova"]) >= 3:
		_add_unique(flags, "frostfire_steam")
	if int(board["Storm Lance"]) >= 3:
		_add_unique(flags, "chain_plus")
	if int(board["Void Rift"]) >= 3:
		_add_unique(flags, "rift_calls_trap")
	if int(board["Blade Trap"]) >= 3:
		_add_unique(flags, "trap_calls_rift")
	if int(board["Cleave"]) >= 3:
		_add_unique(flags, "cleave_wave")

	for slot in save["equipped"].keys():
		var item = save["equipped"][slot]
		if typeof(item) == TYPE_DICTIONARY:
			for f in item.get("flags", []):
				_add_unique(flags, str(f))

	return flags


func _add_flag_at(flags: Array, p: Dictionary, branch: String, threshold: int, flag: String) -> void:
	if int(p.get(branch, 0)) >= threshold:
		_add_unique(flags, flag)


func _add_unique(flags: Array, value: String) -> void:
	if not flags.has(value):
		flags.append(value)


func _restore_player() -> void:
	var hp = 120.0 + float(int(save["level"]) - 1) * 5.0
	var mana = 100.0 + float(int(save["level"]) - 1) * 2.0

	var stats = _computed_stats()
	hp += float(stats.get("max_hp", 0.0))
	mana += float(stats.get("max_mana", 0.0))

	game.set("player_hp", hp)
	game.set("player_mana", mana)
	game.set("dash_time", 0.0)
	game.set("dash_cooldown", 0.0)
	game.set("invuln_time", 0.0)


func _death_return_to_hub() -> void:
	save["stats"]["deaths"] = int(save["stats"]["deaths"]) + 1
	_dirty()
	enter_hub("You died. Progress saved.")


func _clear_runtime() -> void:
	game.set("enemies", [])
	game.set("projectiles", [])
	game.set("enemy_projectiles", [])
	game.set("zones", [])
	game.set("loot", [])
	game.set("traps", [])
	game.set("chests", [])
	game.set("floating_text", [])
	game.set("minions", [])
	game.set("delayed_casts", [])


func _player_pos() -> Vector2:
	var p = game.get("player_pos")
	if typeof(p) == TYPE_VECTOR2:
		return p
	return hub_center


func _notice(text: String) -> void:
	notice_text = text
	notice_timer = 2.4
	if notice_label != null:
		notice_label.text = text
		notice_label.visible = true


func _draw() -> void:
	if mode != "hub":
		return

	_draw_hub_floor()
	_draw_hub_objects()
	_draw_player_marker()


func _draw_hub_floor() -> void:
	var rect = Rect2(Vector2(60, 84), Vector2(1160, 566))
	draw_rect(rect, Color(0.014, 0.013, 0.016, 0.96), true)
	draw_rect(rect, Color(0.70, 0.54, 0.30, 0.22), false, 2.0)

	draw_arc(hub_center, 260, -PI, PI, 128, Color(0.85, 0.62, 0.34, 0.09), 2.0)
	draw_arc(hub_center, 160, -PI, PI, 128, Color(0.85, 0.62, 0.34, 0.12), 2.0)
	draw_arc(hub_center, 80, -PI, PI, 128, Color(0.85, 0.62, 0.34, 0.08), 2.0)

	_draw_zone_label(Vector2(640, 95), "CONTRACT GATES", Color(0.90, 0.58, 1.0))
	_draw_zone_label(Vector2(990, 185), "FORGE", Color(1.0, 0.48, 0.18))
	_draw_zone_label(Vector2(330, 185), "MASTERY SHRINES", Color(0.74, 0.62, 1.0))
	_draw_zone_label(Vector2(650, 500), "SKILL ALTARS", Color(0.56, 1.0, 0.76))
	_draw_zone_label(Vector2(690, 395), "STASH / ARMORY", Color(0.95, 0.78, 0.34))


func _draw_hub_objects() -> void:
	var focus_pos = Vector2(-999, -999)
	if not current_focus.is_empty():
		focus_pos = current_focus["pos"]

	for obj in hub_objects:
		var pos = obj["pos"]
		var col = obj["color"]
		var type = str(obj["type"])
		var selected = pos.distance_to(focus_pos) < 1.0
		var r = 30.0 if selected else 24.0

		if type == "contract":
			_draw_gate(pos, r, col, selected)
		elif type == "forge":
			_draw_anvil(pos, r, col, selected)
		elif type == "passive":
			_draw_shrine(pos, r, col, selected)
		elif type == "skill":
			_draw_skill_altar(pos, r, col, selected, str(obj["data"]))
		elif type == "stash_deposit":
			_draw_chest(pos, r, col, selected)
		elif type == "armory":
			_draw_rack(pos, r, col, selected)
		elif type == "stash_item" or type == "backpack_item":
			_draw_item_pedestal(pos, r, col, selected)
		else:
			_draw_orb(pos, r, col, selected)

		_draw_name(pos + Vector2(0, r + 22), str(obj["name"]), col, selected)


func _draw_gate(pos: Vector2, r: float, col: Color, selected: bool) -> void:
	draw_circle(pos + Vector2(5, 8), r + 8, Color(0, 0, 0, 0.30))
	draw_arc(pos, r + 10, -PI, PI, 64, Color(col.r, col.g, col.b, 0.55 if selected else 0.28), 4.0)
	draw_arc(pos, r, -PI, PI, 64, Color(col.r, col.g, col.b, 0.36), 2.0)
	draw_line(pos + Vector2(-r * 0.6, r * 0.5), pos + Vector2(0, -r * 0.75), Color(col.r, col.g, col.b, 0.70), 3.0)
	draw_line(pos + Vector2(r * 0.6, r * 0.5), pos + Vector2(0, -r * 0.75), Color(col.r, col.g, col.b, 0.70), 3.0)


func _draw_anvil(pos: Vector2, r: float, col: Color, selected: bool) -> void:
	draw_circle(pos + Vector2(5, 8), r + 5, Color(0, 0, 0, 0.30))
	draw_rect(Rect2(pos - Vector2(r * 0.65, r * 0.35), Vector2(r * 1.3, r * 0.7)), Color(0.035, 0.032, 0.034, 0.94), true)
	draw_rect(Rect2(pos - Vector2(r * 0.65, r * 0.35), Vector2(r * 1.3, r * 0.7)), Color(col.r, col.g, col.b, 0.70 if selected else 0.38), false, 3.0)
	draw_line(pos + Vector2(-r, -r * 0.7), pos + Vector2(r, -r * 0.7), Color(col.r, col.g, col.b, 0.22), 4.0)


func _draw_shrine(pos: Vector2, r: float, col: Color, selected: bool) -> void:
	draw_circle(pos + Vector2(5, 8), r + 5, Color(0, 0, 0, 0.30))
	var pts = PackedVector2Array([pos + Vector2(0, -r), pos + Vector2(r * 0.75, 0), pos + Vector2(0, r), pos + Vector2(-r * 0.75, 0)])
	draw_polygon(pts, PackedColorArray([Color(0.030, 0.028, 0.034, 0.96)]))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(col.r, col.g, col.b, 0.82 if selected else 0.42), 3.0)
	draw_circle(pos, r * 0.24, Color(col.r, col.g, col.b, 0.70))


func _draw_skill_altar(pos: Vector2, r: float, col: Color, selected: bool, skill: String) -> void:
	draw_circle(pos + Vector2(5, 8), r + 5, Color(0, 0, 0, 0.30))
	draw_circle(pos, r, Color(0.030, 0.028, 0.034, 0.96))
	draw_arc(pos, r + 4, -PI, PI, 64, Color(col.r, col.g, col.b, 0.76 if selected else 0.36), 3.0)

	var active = save["loadout"].has(skill)
	if active:
		draw_circle(pos, r * 0.38, Color(col.r, col.g, col.b, 0.82))
	else:
		draw_circle(pos, r * 0.25, Color(col.r, col.g, col.b, 0.34))


func _draw_chest(pos: Vector2, r: float, col: Color, selected: bool) -> void:
	draw_circle(pos + Vector2(5, 8), r + 5, Color(0, 0, 0, 0.30))
	draw_rect(Rect2(pos - Vector2(r * 0.7, r * 0.45), Vector2(r * 1.4, r * 0.9)), Color(0.035, 0.030, 0.024, 0.96), true)
	draw_rect(Rect2(pos - Vector2(r * 0.7, r * 0.45), Vector2(r * 1.4, r * 0.9)), Color(col.r, col.g, col.b, 0.78 if selected else 0.42), false, 3.0)
	draw_line(pos + Vector2(-r * 0.55, 0), pos + Vector2(r * 0.55, 0), Color(col.r, col.g, col.b, 0.45), 2.0)


func _draw_rack(pos: Vector2, r: float, col: Color, selected: bool) -> void:
	draw_circle(pos + Vector2(5, 8), r + 5, Color(0, 0, 0, 0.30))
	draw_line(pos + Vector2(-r * 0.7, r * 0.6), pos + Vector2(-r * 0.2, -r * 0.7), Color(col.r, col.g, col.b, 0.75 if selected else 0.40), 4.0)
	draw_line(pos + Vector2(r * 0.7, r * 0.6), pos + Vector2(r * 0.2, -r * 0.7), Color(col.r, col.g, col.b, 0.75 if selected else 0.40), 4.0)
	draw_line(pos + Vector2(-r * 0.9, r * 0.6), pos + Vector2(r * 0.9, r * 0.6), Color(col.r, col.g, col.b, 0.42), 3.0)


func _draw_item_pedestal(pos: Vector2, r: float, col: Color, selected: bool) -> void:
	draw_circle(pos + Vector2(5, 8), r + 4, Color(0, 0, 0, 0.30))
	draw_circle(pos, r * 0.65, Color(0.030, 0.028, 0.034, 0.96))
	draw_arc(pos, r, -PI, PI, 48, Color(col.r, col.g, col.b, 0.78 if selected else 0.38), 3.0)
	draw_circle(pos, r * 0.22, Color(col.r, col.g, col.b, 0.82))


func _draw_orb(pos: Vector2, r: float, col: Color, selected: bool) -> void:
	draw_circle(pos, r, Color(col.r, col.g, col.b, 0.26))
	draw_arc(pos, r + 4, -PI, PI, 48, Color(col.r, col.g, col.b, 0.74 if selected else 0.34), 3.0)


func _draw_player_marker() -> void:
	var p = _player_pos()
	draw_circle(p + Vector2(4, 8), 18.0, Color(0, 0, 0, 0.32))
	draw_circle(p, 16.0, Color(0.92, 0.84, 0.68, 0.96))
	draw_arc(p, 23.0, -PI, PI, 48, Color(1.0, 0.78, 0.38, 0.45), 2.0)


func _draw_zone_label(pos: Vector2, text: String, col: Color) -> void:
	var font = ThemeDB.fallback_font
	var size_font = 12
	var s = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font)
	draw_string(font, pos - Vector2(s.x * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font, Color(col.r, col.g, col.b, 0.65))


func _draw_name(pos: Vector2, text: String, col: Color, selected: bool) -> void:
	var font = ThemeDB.fallback_font
	var size_font = 11 if selected else 10
	var s = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font)
	var rect = Rect2(pos - Vector2(s.x * 0.5 + 6, 10), Vector2(s.x + 12, 18))
	draw_rect(rect, Color(0.016, 0.015, 0.018, 0.72), true)
	draw_rect(rect, Color(col.r, col.g, col.b, 0.34 if selected else 0.16), false, 1.0)
	draw_string(font, pos + Vector2(-s.x * 0.5, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font, Color(0.92, 0.86, 0.72, 0.94))


func _passive_color(p: String) -> Color:
	match p:
		"ash":
			return Color(1.0, 0.34, 0.12)
		"frost":
			return Color(0.42, 0.82, 1.0)
		"storm":
			return Color(0.72, 0.92, 1.0)
		"void":
			return Color(0.70, 0.36, 1.0)
		"steel":
			return Color(0.88, 0.80, 0.62)
		"trap":
			return Color(0.95, 0.72, 0.30)
		"blood":
			return Color(1.0, 0.22, 0.18)
		"relic":
			return Color(0.90, 0.70, 0.36)
	return Color(0.90, 0.84, 0.70)


func _skill_color(skill: String) -> Color:
	if skill == "Fireball":
		return Color(1.0, 0.34, 0.12)
	if skill == "Cleave":
		return Color(1.0, 0.80, 0.48)
	if skill == "Frost Nova":
		return Color(0.42, 0.82, 1.0)
	if skill == "Storm Lance":
		return Color(0.72, 0.92, 1.0)
	if skill == "Void Rift":
		return Color(0.70, 0.36, 1.0)
	if skill == "Blade Trap":
		return Color(0.95, 0.72, 0.30)
	return Color(0.90, 0.84, 0.70)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Magic":
			return Color(0.42, 0.72, 1.0)
		"Rare":
			return Color(1.0, 0.82, 0.32)
		"Legendary":
			return Color(1.0, 0.44, 0.14)
		"Crafted":
			return Color(0.90, 0.36, 1.0)
	return Color(0.84, 0.82, 0.74)


func _slot_label(slot: String) -> String:
	match slot:
		"weapon":
			return "Weapon"
		"offhand":
			return "Offhand"
		"head":
			return "Head"
		"chest":
			return "Chest"
		"gloves":
			return "Gloves"
		"boots":
			return "Boots"
		"amulet":
			return "Amulet"
		"ring":
			return "Ring"
		"ring1":
			return "Ring 1"
		"ring2":
			return "Ring 2"
		"relic":
			return "Relic"
	return slot.capitalize()


func _cost_line(cost: Dictionary) -> String:
	var parts = []
	for k in cost.keys():
		parts.append(str(k) + " " + str(int(cost[k])))
	return _join(parts)


func _join(arr) -> String:
	if typeof(arr) != TYPE_ARRAY:
		return str(arr)
	if arr.size() == 0:
		return "none"

	var parts = []
	for x in arr:
		parts.append(str(x))
	return ", ".join(parts)
