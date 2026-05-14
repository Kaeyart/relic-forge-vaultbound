extends CanvasLayer

# RELIC FORGE: VAULTBOUND
# Patch 007 — Persistent RPG Foundation
#
# This is the ARPG backbone:
# - persistent character level
# - persistent mastery points
# - persistent equipped gear
# - persistent backpack
# - stash
# - crafting materials
# - loadout saving/applying
# - forge recipes
#
# The design correction:
# Builds should be chosen by the player and earned over time.
# Runs should feed the permanent character journey, not randomly mutate the build for the player.

const SAVE_PATH = "user://relic_forge_vaultbound_character_save.json"

const SKILL_NAMES = ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"]

const EQUIP_SLOTS = [
	"weapon",
	"offhand",
	"head",
	"chest",
	"gloves",
	"boots",
	"amulet",
	"ring1",
	"ring2",
	"relic"
]

var game = null
var rng = RandomNumberGenerator.new()

var save_data = {}
var dirty = false
var autosave_timer = 0.0
var sync_timer = 0.0

var last_kills = 0
var last_rooms_cleared = 0
var last_depth = 0

var ui_root = null
var meta_chip = null
var panel = null
var title_label = null
var body_label = null
var footer_label = null
var current_panel = "none"

var flash_text = ""
var flash_timer = 0.0

func _ready() -> void:
	game = get_parent()
	rng.randomize()

	_load_or_create_save()
	_build_ui()
	_apply_save_to_game()
	_apply_mastery_item_to_game()

	if game != null:
		last_kills = int(game.get("kills"))
		last_rooms_cleared = int(game.get("rooms_cleared"))
		last_depth = int(game.get("run_depth"))

	set_process(true)


func _process(delta: float) -> void:
	if game == null:
		return

	_watch_run_progress()
	_apply_mastery_item_to_game()

	sync_timer += delta
	if sync_timer >= 0.75:
		sync_timer = 0.0
		_sync_from_game()

	autosave_timer += delta
	if autosave_timer >= 3.0:
		autosave_timer = 0.0
		if dirty:
			_save()

	if flash_timer > 0.0:
		flash_timer -= delta

	_update_ui()


func _unhandled_input(event) -> void:
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return

	var key = event.keycode

	if key == KEY_C:
		_toggle_panel("character")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_V:
		_toggle_panel("forge")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_L:
		_toggle_panel("loadout")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_U:
		_toggle_panel("stash")
		get_viewport().set_input_as_handled()
		return

	if key == KEY_F5:
		_sync_from_game()
		_save()
		_flash("Character saved")
		get_viewport().set_input_as_handled()
		return

	if current_panel == "none":
		return

	if key == KEY_ESCAPE:
		_toggle_panel("none")
		get_viewport().set_input_as_handled()
		return

	if current_panel == "character":
		_handle_character_keys(key)
		get_viewport().set_input_as_handled()
		return

	if current_panel == "forge":
		_handle_forge_keys(key)
		get_viewport().set_input_as_handled()
		return

	if current_panel == "loadout":
		_handle_loadout_keys(key)
		get_viewport().set_input_as_handled()
		return

	if current_panel == "stash":
		_handle_stash_keys(key)
		get_viewport().set_input_as_handled()
		return


func _load_or_create_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var txt = f.get_as_text()
		var parsed = JSON.parse_string(txt)
		if typeof(parsed) == TYPE_DICTIONARY:
			save_data = parsed
		else:
			save_data = _default_save()
	else:
		save_data = _default_save()
		dirty = true
		_save()

	_normalize_save()


func _default_save() -> Dictionary:
	return {
		"version": 7,
		"character_name": "Vaultbound",
		"character_level": 1,
		"character_xp": 0.0,
		"mastery_points": 0,
		"total_mastery_points_earned": 0,
		"materials": {
			"embers": 0,
			"shards": 0,
			"runes": 0,
			"echo_glass": 0
		},
		"mastery_alloc": {
			"ash": 0,
			"frost": 0,
			"storm": 0,
			"void": 0,
			"steel": 0,
			"trap": 0,
			"blood": 0,
			"relic": 0
		},
		"equipped": {
			"weapon": null,
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
		"loadout_skills": ["Fireball", "Cleave"],
		"unlocked_skills": ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"],
		"runs_started": 0,
		"rooms_cleared_total": 0,
		"kills_total": 0,
		"highest_depth": 0,
		"crafted_items": 0
	}


func _normalize_save() -> void:
	var base = _default_save()

	for k in base.keys():
		if not save_data.has(k):
			save_data[k] = base[k]

	for k in base["materials"].keys():
		if not save_data["materials"].has(k):
			save_data["materials"][k] = base["materials"][k]

	for k in base["mastery_alloc"].keys():
		if not save_data["mastery_alloc"].has(k):
			save_data["mastery_alloc"][k] = 0

	for slot in EQUIP_SLOTS:
		if not save_data["equipped"].has(slot):
			save_data["equipped"][slot] = null

	dirty = true


func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(save_data, "\t"))
	dirty = false


func _build_ui() -> void:
	ui_root = Control.new()
	ui_root.name = "Patch007PersistentRPGUI"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)

	meta_chip = PanelContainer.new()
	meta_chip.name = "CharacterChip"
	meta_chip.position = Vector2(16, 16)
	meta_chip.custom_minimum_size = Vector2(330, 42)
	meta_chip.add_theme_stylebox_override("panel", _style_chip())
	ui_root.add_child(meta_chip)

	var chip_label = Label.new()
	chip_label.name = "ChipText"
	chip_label.add_theme_font_size_override("font_size", 12)
	chip_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.76))
	meta_chip.add_child(chip_label)

	panel = PanelContainer.new()
	panel.name = "PersistentRPGPanel"
	panel.position = Vector2(245, 84)
	panel.custom_minimum_size = Vector2(790, 540)
	panel.add_theme_stylebox_override("panel", _style_panel())
	panel.visible = false
	ui_root.add_child(panel)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	box.add_child(title_label)

	body_label = RichTextLabel.new()
	body_label.fit_content = false
	body_label.scroll_active = true
	body_label.bbcode_enabled = false
	body_label.custom_minimum_size = Vector2(760, 430)
	body_label.add_theme_font_size_override("normal_font_size", 13)
	body_label.add_theme_color_override("default_color", Color(0.82, 0.79, 0.72))
	box.add_child(body_label)

	footer_label = Label.new()
	footer_label.add_theme_font_size_override("font_size", 12)
	footer_label.add_theme_color_override("font_color", Color(0.68, 0.64, 0.58))
	box.add_child(footer_label)


func _style_chip() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.022, 0.022, 0.026, 0.76)
	s.border_color = Color(0.72, 0.60, 0.42, 0.26)
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s


func _style_panel() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.018, 0.018, 0.022, 0.94)
	s.border_color = Color(0.76, 0.62, 0.40, 0.38)
	s.set_border_width_all(1)
	s.set_corner_radius_all(14)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


func _toggle_panel(name: String) -> void:
	if current_panel == name or name == "none":
		current_panel = "none"
		panel.visible = false
		return

	current_panel = name
	panel.visible = true
	_update_ui()


func _update_ui() -> void:
	if ui_root == null:
		return

	var chip_label = meta_chip.get_node_or_null("ChipText")
	if chip_label != null:
		var lvl = int(save_data.get("character_level", 1))
		var xp = float(save_data.get("character_xp", 0.0))
		var next = _xp_to_next(lvl)
		var mats = save_data.get("materials", {})
		var text = "Lv " + str(lvl) + "  XP " + str(int(xp)) + "/" + str(int(next))
		text += "  ·  Embers " + str(int(mats.get("embers", 0)))
		text += "  ·  C Character  V Forge  L Loadout  U Stash"
		if flash_timer > 0.0:
			text = flash_text
		chip_label.text = text

	if not panel.visible:
		return

	if current_panel == "character":
		title_label.text = "CHARACTER / MASTERY"
		body_label.text = _character_text()
		footer_label.text = "1-8 spend mastery point · C close · F5 save"
	elif current_panel == "forge":
		title_label.text = "FORGE / CRAFTING"
		body_label.text = _forge_text()
		footer_label.text = "1-8 craft recipe · V close · F5 save"
	elif current_panel == "loadout":
		title_label.text = "LOADOUT"
		body_label.text = _loadout_text()
		footer_label.text = "1-6 toggle skills · Enter apply loadout · L close"
	elif current_panel == "stash":
		title_label.text = "STASH"
		body_label.text = _stash_text()
		footer_label.text = "T stash backpack · 1-9 withdraw item · U close"


func _character_text() -> String:
	var lines = []
	var lvl = int(save_data.get("character_level", 1))
	var xp = float(save_data.get("character_xp", 0.0))
	var next = _xp_to_next(lvl)
	var mats = save_data.get("materials", {})
	var mastery = save_data.get("mastery_alloc", {})
	var computed = _compute_mastery_item()

	lines.append("Character Level: " + str(lvl))
	lines.append("XP: " + str(int(xp)) + " / " + str(int(next)))
	lines.append("Unspent Mastery Points: " + str(int(save_data.get("mastery_points", 0))))
	lines.append("")
	lines.append("Materials")
	lines.append("  Embers: " + str(int(mats.get("embers", 0))))
	lines.append("  Shards: " + str(int(mats.get("shards", 0))))
	lines.append("  Runes: " + str(int(mats.get("runes", 0))))
	lines.append("  Echo Glass: " + str(int(mats.get("echo_glass", 0))))
	lines.append("")
	lines.append("Mastery Branches")
	lines.append("1. Ash   [" + str(int(mastery.get("ash", 0))) + "] Fire, burn, explosions, Fireball chains")
	lines.append("2. Frost [" + str(int(mastery.get("frost", 0))) + "] Freeze, Frostfire, shatter setups")
	lines.append("3. Storm [" + str(int(mastery.get("storm", 0))) + "] Chain lightning, cooldown, cascade speed")
	lines.append("4. Void  [" + str(int(mastery.get("void", 0))) + "] Rifts, curse deaths, trap gravity")
	lines.append("5. Steel [" + str(int(mastery.get("steel", 0))) + "] Cleave, bleed, melee execution")
	lines.append("6. Trap  [" + str(int(mastery.get("trap", 0))) + "] Blade Trap, poison, trap/rift loops")
	lines.append("7. Blood [" + str(int(mastery.get("blood", 0))) + "] Blood casting, low-resource aggression")
	lines.append("8. Relic [" + str(int(mastery.get("relic", 0))) + "] Global scaling, contract greed, depth scaling")
	lines.append("")
	lines.append("Permanent Character Bonuses")
	var stats = computed.get("stats", {})
	for k in stats.keys():
		lines.append("  " + str(k) + ": " + str(snapped(float(stats[k]), 0.001)))
	lines.append("")
	lines.append("Permanent Flags")
	var flags = computed.get("flags", [])
	if flags.size() == 0:
		lines.append("  none yet")
	else:
		for f in flags:
			lines.append("  " + str(f))

	return "\n".join(lines)


func _forge_text() -> String:
	var mats = save_data.get("materials", {})
	var lines = []
	lines.append("Runs now feed crafting. Crafting creates persistent gear and puts it in your backpack.")
	lines.append("")
	lines.append("Materials: Embers " + str(int(mats.get("embers", 0))) + " · Shards " + str(int(mats.get("shards", 0))) + " · Runes " + str(int(mats.get("runes", 0))) + " · Echo Glass " + str(int(mats.get("echo_glass", 0))))
	lines.append("")
	lines.append("Recipes")
	var recipes = _recipes()
	var idx = 1
	for r in recipes:
		lines.append(str(idx) + ". " + str(r.get("name", "Recipe")))
		lines.append("   Cost: " + _cost_text(r.get("cost", {})))
		lines.append("   " + str(r.get("desc", "")))
		lines.append("")
		idx += 1

	return "\n".join(lines)


func _loadout_text() -> String:
	var lines = []
	var loadout = save_data.get("loadout_skills", [])
	var unlocked = save_data.get("unlocked_skills", SKILL_NAMES)

	lines.append("Persistent skill loadout. This is the character you bring into runs.")
	lines.append("Selected: " + (", ".join(loadout) if loadout.size() > 0 else "none"))
	lines.append("")
	lines.append("Toggle skills")
	var idx = 1
	for s in SKILL_NAMES:
		var mark = "[x]" if loadout.has(s) else "[ ]"
		var lock = "" if unlocked.has(s) else " locked"
		lines.append(str(idx) + ". " + mark + " " + s + lock)
		idx += 1
	lines.append("")
	lines.append("Rule: You can carry up to 4 core skills for now. Later we can expand this with skill sockets and support gems.")
	lines.append("Press Enter to apply the loadout to the current run.")

	return "\n".join(lines)


func _stash_text() -> String:
	var lines = []
	var backpack = save_data.get("backpack", [])
	var stash = save_data.get("stash", [])

	lines.append("Backpack: " + str(backpack.size()) + " items")
	lines.append("Stash: " + str(stash.size()) + " items")
	lines.append("")
	lines.append("Press T to move the current backpack into the stash.")
	lines.append("")
	lines.append("Stash Items")
	if stash.size() == 0:
		lines.append("  empty")
	else:
		var idx = 1
		for item in stash:
			if typeof(item) == TYPE_DICTIONARY:
				lines.append(str(idx) + ". " + str(item.get("name", "Item")) + " [" + str(item.get("rarity", "")) + "]")
				lines.append("   " + str(item.get("desc", "")))
				idx += 1
				if idx > 9:
					lines.append("...")
					break

	return "\n".join(lines)


func _handle_character_keys(key: int) -> void:
	var index = _number_index(key)
	if index < 1 or index > 8:
		return

	if int(save_data.get("mastery_points", 0)) <= 0:
		_flash("No mastery points")
		return

	var branches = ["ash", "frost", "storm", "void", "steel", "trap", "blood", "relic"]
	var branch = branches[index - 1]
	var mastery = save_data.get("mastery_alloc", {})
	mastery[branch] = int(mastery.get(branch, 0)) + 1
	save_data["mastery_alloc"] = mastery
	save_data["mastery_points"] = int(save_data.get("mastery_points", 0)) - 1

	_apply_mastery_item_to_game()
	_flash("Mastery added: " + branch.capitalize())
	_dirty_save()


func _handle_forge_keys(key: int) -> void:
	var index = _number_index(key)
	var recipes = _recipes()

	if index < 1 or index > recipes.size():
		return

	var recipe = recipes[index - 1]
	if not _can_pay(recipe.get("cost", {})):
		_flash("Not enough materials")
		return

	_pay(recipe.get("cost", {}))
	var item = _craft_item(recipe)
	var backpack = save_data.get("backpack", [])
	backpack.append(item)
	save_data["backpack"] = backpack
	save_data["crafted_items"] = int(save_data.get("crafted_items", 0)) + 1

	_push_backpack_to_game()
	_flash("Crafted: " + str(item.get("name", "Item")))
	_dirty_save()


func _handle_loadout_keys(key: int) -> void:
	if key == KEY_ENTER or key == KEY_KP_ENTER:
		_apply_loadout_to_game()
		_flash("Loadout applied")
		_dirty_save()
		return

	var index = _number_index(key)
	if index < 1 or index > SKILL_NAMES.size():
		return

	var skill = SKILL_NAMES[index - 1]
	var unlocked = save_data.get("unlocked_skills", SKILL_NAMES)
	if not unlocked.has(skill):
		_flash("Skill locked")
		return

	var loadout = save_data.get("loadout_skills", [])
	if loadout.has(skill):
		loadout.erase(skill)
	else:
		if loadout.size() >= 4:
			_flash("Loadout limit: 4 skills")
			return
		loadout.append(skill)

	save_data["loadout_skills"] = loadout
	_flash("Loadout changed")
	_dirty_save()


func _handle_stash_keys(key: int) -> void:
	if key == KEY_T:
		var backpack = save_data.get("backpack", [])
		var stash = save_data.get("stash", [])

		for item in backpack:
			stash.append(item)

		backpack.clear()

		save_data["backpack"] = backpack
		save_data["stash"] = stash
		_push_backpack_to_game()
		_flash("Backpack moved to stash")
		_dirty_save()
		return

	var index = _number_index(key)
	if index < 1:
		return

	var stash = save_data.get("stash", [])
	if index > stash.size():
		return

	var item = stash[index - 1]
	stash.remove_at(index - 1)

	var backpack2 = save_data.get("backpack", [])
	backpack2.append(item)

	save_data["stash"] = stash
	save_data["backpack"] = backpack2
	_push_backpack_to_game()
	_flash("Withdrew item")
	_dirty_save()


func _number_index(key: int) -> int:
	if key >= KEY_1 and key <= KEY_9:
		return key - KEY_1 + 1
	if key >= KEY_KP_1 and key <= KEY_KP_9:
		return key - KEY_KP_1 + 1
	return -1


func _recipes() -> Array:
	return [
		{
			"name": "Ashen Conductor Weapon",
			"slot": "weapon",
			"desc": "Fireball begins feeding Storm Lance and cascade-style spell chains.",
			"cost": {"embers": 14, "shards": 5},
			"stats": {"fire_damage": 0.18, "lightning_damage": 0.12, "spell_damage": 0.08},
			"flags": ["fire_calls_lance", "cascade_engine"]
		},
		{
			"name": "Frostfire Reactor Relic",
			"slot": "relic",
			"desc": "Freeze then ignite enemies for Frostfire steam detonations.",
			"cost": {"embers": 9, "shards": 9, "echo_glass": 1},
			"stats": {"fire_damage": 0.12, "cold_damage": 0.16, "freeze_duration": 0.25},
			"flags": ["frostfire_steam", "nova_calls_fire"]
		},
		{
			"name": "Void Trap Engine",
			"slot": "offhand",
			"desc": "Void Rift and Blade Trap begin calling each other.",
			"cost": {"shards": 12, "runes": 2},
			"stats": {"void_damage": 0.18, "trap_damage": 0.18, "max_mana": 16.0},
			"flags": ["trap_calls_rift", "rift_calls_trap", "rift_pull"]
		},
		{
			"name": "Butcher's Cleaver",
			"slot": "weapon",
			"desc": "Cleave becomes a real build core with bleed and blood waves.",
			"cost": {"embers": 12, "runes": 1},
			"stats": {"melee_damage": 0.28, "max_hp": 18.0},
			"flags": ["slash_bleed", "cleave_wave", "execute_low_hp"]
		},
		{
			"name": "Storm Choir Ring",
			"slot": "ring",
			"desc": "Lightning chains harder and helps late-run cascade engines.",
			"cost": {"shards": 8, "echo_glass": 2},
			"stats": {"lightning_damage": 0.24, "cooldown_reduction": 0.04},
			"flags": ["chain_plus", "lance_calls_nova"]
		},
		{
			"name": "Blood Debt Heart",
			"slot": "chest",
			"desc": "Low-resource casting becomes an aggressive blood-mage engine.",
			"cost": {"embers": 10, "runes": 2},
			"stats": {"spell_damage": 0.12, "max_hp": 42.0, "max_mana": 10.0},
			"flags": ["blood_cast", "blood_orbs", "chain_mana_refund"]
		},
		{
			"name": "Corpse Spark Relic",
			"slot": "relic",
			"desc": "Kills become room-clear fuel through sparks and death bursts.",
			"cost": {"embers": 7, "shards": 7, "runes": 1},
			"stats": {"lightning_damage": 0.10, "void_damage": 0.10, "global_damage": 0.06},
			"flags": ["corpse_spark", "burn_death_explode", "curse_death_burst"]
		},
		{
			"name": "Contract Eater Amulet",
			"slot": "amulet",
			"desc": "Dangerous dungeon routes become part of the build.",
			"cost": {"runes": 3, "echo_glass": 2},
			"stats": {"global_damage": 0.14, "max_hp": 20.0},
			"flags": ["contract_eater", "depth_scaling"]
		}
	]


func _craft_item(recipe: Dictionary) -> Dictionary:
	var mats = save_data.get("materials", {})
	var level = int(save_data.get("character_level", 1))
	var power = 1.0 + float(level) * 0.018

	var stats = {}
	for k in recipe.get("stats", {}).keys():
		stats[k] = float(recipe["stats"][k]) * power

	var item = {
		"name": str(recipe.get("name", "Crafted Item")) + " +" + str(max(1, level / 4)),
		"slot": str(recipe.get("slot", "relic")),
		"rarity": "Crafted",
		"desc": str(recipe.get("desc", "")) + " Crafted at character level " + str(level) + ".",
		"stats": stats,
		"flags": recipe.get("flags", []).duplicate(true),
		"crafted_level": level
	}

	return item


func _can_pay(cost: Dictionary) -> bool:
	var mats = save_data.get("materials", {})
	for k in cost.keys():
		if int(mats.get(k, 0)) < int(cost[k]):
			return false
	return true


func _pay(cost: Dictionary) -> void:
	var mats = save_data.get("materials", {})
	for k in cost.keys():
		mats[k] = int(mats.get(k, 0)) - int(cost[k])
	save_data["materials"] = mats


func _cost_text(cost: Dictionary) -> String:
	var arr = []
	for k in cost.keys():
		arr.append(str(k) + " " + str(int(cost[k])))
	return ", ".join(arr)


func _watch_run_progress() -> void:
	var kills = int(game.get("kills"))
	if kills > last_kills:
		var gained = kills - last_kills
		var i = 0
		while i < gained:
			_award_kill_progress()
			i += 1
	last_kills = kills

	var rooms = int(game.get("rooms_cleared"))
	if rooms > last_rooms_cleared:
		var gained_rooms = rooms - last_rooms_cleared
		var r = 0
		while r < gained_rooms:
			_award_room_progress()
			r += 1
	last_rooms_cleared = rooms

	var depth = int(game.get("run_depth"))
	if depth > int(save_data.get("highest_depth", 0)):
		save_data["highest_depth"] = depth
		dirty = true
	last_depth = depth


func _award_kill_progress() -> void:
	var depth = max(1, int(game.get("run_depth")))
	var xp_gain = 6.0 + float(depth) * 1.5
	_add_character_xp(xp_gain)

	var mats = save_data.get("materials", {})
	mats["embers"] = int(mats.get("embers", 0)) + 1

	if rng.randf() < 0.12:
		mats["shards"] = int(mats.get("shards", 0)) + 1

	if rng.randf() < 0.035:
		mats["runes"] = int(mats.get("runes", 0)) + 1

	save_data["materials"] = mats
	save_data["kills_total"] = int(save_data.get("kills_total", 0)) + 1
	dirty = true


func _award_room_progress() -> void:
	var depth = max(1, int(game.get("run_depth")))
	var xp_gain = 28.0 + float(depth) * 5.0
	_add_character_xp(xp_gain)

	var mats = save_data.get("materials", {})
	mats["shards"] = int(mats.get("shards", 0)) + 3

	if depth % 3 == 0:
		mats["runes"] = int(mats.get("runes", 0)) + 1

	if depth % 5 == 0:
		mats["echo_glass"] = int(mats.get("echo_glass", 0)) + 1

	save_data["materials"] = mats
	save_data["rooms_cleared_total"] = int(save_data.get("rooms_cleared_total", 0)) + 1
	_flash("Room progress saved")
	dirty = true


func _add_character_xp(amount: float) -> void:
	var lvl = int(save_data.get("character_level", 1))
	var xp = float(save_data.get("character_xp", 0.0)) + amount

	while xp >= _xp_to_next(lvl):
		xp -= _xp_to_next(lvl)
		lvl += 1
		save_data["mastery_points"] = int(save_data.get("mastery_points", 0)) + 1
		save_data["total_mastery_points_earned"] = int(save_data.get("total_mastery_points_earned", 0)) + 1
		_flash("LEVEL UP — Mastery point gained")

	save_data["character_level"] = lvl
	save_data["character_xp"] = xp
	dirty = true


func _xp_to_next(level: int) -> float:
	return 120.0 + pow(float(level), 1.35) * 58.0


func _compute_mastery_item() -> Dictionary:
	var level = int(save_data.get("character_level", 1))
	var mastery = save_data.get("mastery_alloc", {})

	var stats = {
		"max_hp": float(level - 1) * 4.0,
		"max_mana": float(level - 1) * 2.0,
		"global_damage": min(0.35, float(level - 1) * 0.006)
	}
	var flags = []

	_add_mastery(stats, flags, "ash", mastery, {
		"fire_damage": 0.06,
		"burn_power": 0.025
	}, {
		2: "fire_calls_lance",
		4: "burn_death_explode",
		7: "cascade_engine"
	})

	_add_mastery(stats, flags, "frost", mastery, {
		"cold_damage": 0.06,
		"freeze_duration": 0.04
	}, {
		2: "nova_calls_fire",
		4: "shatter_lightning",
		7: "frostfire_steam"
	})

	_add_mastery(stats, flags, "storm", mastery, {
		"lightning_damage": 0.06,
		"cooldown_reduction": 0.012
	}, {
		2: "chain_plus",
		5: "lance_calls_nova",
		8: "fivefold_cascade"
	})

	_add_mastery(stats, flags, "void", mastery, {
		"void_damage": 0.06,
		"max_mana": 3.0
	}, {
		2: "rift_pull",
		4: "rift_calls_trap",
		7: "curse_death_burst"
	})

	_add_mastery(stats, flags, "steel", mastery, {
		"melee_damage": 0.065,
		"max_hp": 5.0
	}, {
		2: "slash_bleed",
		4: "cleave_wave",
		7: "execute_low_hp"
	})

	_add_mastery(stats, flags, "trap", mastery, {
		"trap_damage": 0.07,
		"cooldown_reduction": 0.006
	}, {
		2: "double_trap",
		4: "trap_calls_rift",
		7: "trap_poison"
	})

	_add_mastery(stats, flags, "blood", mastery, {
		"spell_damage": 0.045,
		"max_hp": 4.0
	}, {
		2: "blood_cast",
		4: "blood_orbs",
		7: "chain_mana_refund"
	})

	_add_mastery(stats, flags, "relic", mastery, {
		"global_damage": 0.028,
		"cooldown_reduction": 0.008
	}, {
		2: "contract_eater",
		4: "depth_scaling",
		8: "cascade_engine"
	})

	return {
		"stats": stats,
		"flags": flags
	}


func _add_mastery(stats: Dictionary, flags: Array, key: String, mastery: Dictionary, stat_per_point: Dictionary, unlocks: Dictionary) -> void:
	var points = int(mastery.get(key, 0))

	for stat_name in stat_per_point.keys():
		if not stats.has(stat_name):
			stats[stat_name] = 0.0
		stats[stat_name] = float(stats[stat_name]) + float(stat_per_point[stat_name]) * float(points)

	for threshold in unlocks.keys():
		if points >= int(threshold):
			var flag = str(unlocks[threshold])
			if not flags.has(flag):
				flags.append(flag)


func _apply_mastery_item_to_game() -> void:
	if game == null:
		return

	var equipped = game.get("equipped")
	if typeof(equipped) != TYPE_DICTIONARY:
		return

	var computed = _compute_mastery_item()
	equipped["soul"] = {
		"name": "Persistent Character Mastery",
		"slot": "soul",
		"rarity": "Permanent",
		"desc": "Permanent character level and mastery bonuses from Patch 007.",
		"stats": computed.get("stats", {}),
		"flags": computed.get("flags", [])
	}

	game.set("equipped", equipped)


func _apply_save_to_game() -> void:
	if game == null:
		return

	var equipped = save_data.get("equipped", {}).duplicate(true)
	for slot in EQUIP_SLOTS:
		if not equipped.has(slot):
			equipped[slot] = null
	game.set("equipped", equipped)

	_push_backpack_to_game()
	_apply_loadout_to_game()
	_apply_mastery_item_to_game()


func _push_backpack_to_game() -> void:
	if game == null:
		return

	var backpack = save_data.get("backpack", [])
	game.set("inventory", backpack.duplicate(true))


func _apply_loadout_to_game() -> void:
	if game == null:
		return

	var loadout = save_data.get("loadout_skills", [])
	var cleaned = []

	for skill in loadout:
		var s = str(skill)
		if SKILL_NAMES.has(s) and not cleaned.has(s):
			cleaned.append(s)

	if cleaned.size() <= 0:
		cleaned = ["Fireball", "Cleave"]

	game.set("active_skills", cleaned)
	game.set("selected_skill", 0)

	# If the old draft state is still active, this turns the saved loadout into the character's start kit.
	if game.get("starter_picks_remaining") != null:
		game.set("starter_picks_remaining", 0)
	if game.get("skill_draft_choices") != null:
		game.set("skill_draft_choices", [])
	if game.get("paused_by_choice") != null:
		game.set("paused_by_choice", false)


func _sync_from_game() -> void:
	if game == null:
		return

	var equipped = game.get("equipped")
	if typeof(equipped) == TYPE_DICTIONARY:
		var clean_equipped = {}
		for slot in EQUIP_SLOTS:
			clean_equipped[slot] = equipped.get(slot, null)
		save_data["equipped"] = clean_equipped

	var inventory = game.get("inventory")
	if typeof(inventory) == TYPE_ARRAY:
		save_data["backpack"] = inventory.duplicate(true)

	var active_skills = game.get("active_skills")
	if typeof(active_skills) == TYPE_ARRAY and active_skills.size() > 0:
		var clean_loadout = []
		for s in active_skills:
			if SKILL_NAMES.has(str(s)) and not clean_loadout.has(str(s)):
				clean_loadout.append(str(s))
		save_data["loadout_skills"] = clean_loadout

	dirty = true


func _dirty_save() -> void:
	dirty = true
	_save()
	_update_ui()


func _flash(text: String) -> void:
	flash_text = text
	flash_timer = 2.2


func get_save_data() -> Dictionary:
	return save_data
