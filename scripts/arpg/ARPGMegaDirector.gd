extends Node2D

# RELIC FORGE: VAULTBOUND
# Patch 009 — ARPG Megafoundation
#
# This director takes over the meta-game layer:
# - real hub command center
# - contract selection
# - persistent character level
# - persistent mastery board
# - persistent skill board
# - equipment / backpack / stash
# - forge crafting
# - loadout management
# - dungeon launch / death return
#
# Design correction:
# The game is not a random run-mutation toy.
# It is a persistent buildcraft ARPG where runs feed the character journey.

const SAVE_PATH = "user://relic_forge_patch009_arpg_save.json"

const SLOT_ORDER = [
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

const SKILL_LIST = [
	"Fireball",
	"Cleave",
	"Frost Nova",
	"Storm Lance",
	"Void Rift",
	"Blade Trap"
]

const PASSIVE_BRANCHES = [
	"ash",
	"frost",
	"storm",
	"void",
	"steel",
	"trap",
	"blood",
	"relic"
]

var game = null
var rng = RandomNumberGenerator.new()

var save = {}
var dirty = false
var autosave_timer = 0.0

var mode = "hub" # hub, contract, combat
var menu = "command" # command, character, inventory, stash, forge, loadout, passive, skill, contracts
var selected_contract = 0
var selected_inventory_index = 0
var selected_stash_index = 0
var selected_recipe = 0
var selected_loadout_skill = 0
var selected_passive = 0
var selected_skill_board = 0

var last_kills = 0
var last_rooms_cleared = 0
var last_player_hp = 120.0

var hub_center = Vector2(640, 365)
var ui = null
var panel = null
var title_label = null
var body_label = null
var footer_label = null
var chip_label = null
var command_row = null
var banner_label = null
var banner_timer = 0.0
var banner_text = ""

var contract_pool = [
	{
		"name": "Ash Crypt Contract",
		"tier": 1,
		"biome": "Ash Crypt",
		"reward_tags": ["Fire", "Melee", "Burn"],
		"mods": ["Ash Pools", "Low Threat"],
		"threat": 1.0,
		"length": 5,
		"desc": "Starter dungeon. Good for Ash, Steel, and early crafting materials."
	},
	{
		"name": "Bone Archive Contract",
		"tier": 2,
		"biome": "Bone Archive",
		"reward_tags": ["Cold", "Lightning", "Skill XP"],
		"mods": ["Archers", "Narrow Lanes"],
		"threat": 1.35,
		"length": 7,
		"desc": "More ranged enemies. Better skill XP and cold/lightning rewards."
	},
	{
		"name": "Void Foundry Contract",
		"tier": 3,
		"biome": "Void Foundry",
		"reward_tags": ["Void", "Trap", "Relic"],
		"mods": ["Cursed Rooms", "Elite Packs"],
		"threat": 1.75,
		"length": 9,
		"desc": "Harder rooms, better relics, more runes, and trap/void crafting fuel."
	},
	{
		"name": "Contract of the Hungry Forge",
		"tier": 4,
		"biome": "Hungry Forge",
		"reward_tags": ["Legendary", "Crafting", "High Risk"],
		"mods": ["Elite Packs", "Reduced Healing", "Loot Pressure"],
		"threat": 2.25,
		"length": 11,
		"desc": "High-risk loot run. Built for stronger persistent characters."
	}
]

var recipe_pool = [
	{
		"name": "Ashen Conductor",
		"slot": "weapon",
		"rarity": "Crafted",
		"cost": {"embers": 18, "shards": 6},
		"stats": {"fire_damage": 0.20, "lightning_damage": 0.10, "spell_damage": 0.08},
		"flags": ["fire_calls_lance", "cascade_engine"],
		"desc": "Turns Fireball into the beginning of a Fire -> Lightning chain."
	},
	{
		"name": "Frostfire Reactor",
		"slot": "relic",
		"rarity": "Crafted",
		"cost": {"embers": 12, "shards": 12, "echo_glass": 1},
		"stats": {"fire_damage": 0.12, "cold_damage": 0.18, "freeze_duration": 0.25},
		"flags": ["frostfire_steam", "nova_calls_fire"],
		"desc": "Freeze enemies, ignite them, make steam detonations."
	},
	{
		"name": "Void Trap Engine",
		"slot": "offhand",
		"rarity": "Crafted",
		"cost": {"shards": 14, "runes": 2},
		"stats": {"void_damage": 0.20, "trap_damage": 0.18, "max_mana": 18.0},
		"flags": ["trap_calls_rift", "rift_calls_trap", "rift_pull"],
		"desc": "Blade Trap and Void Rift feed each other."
	},
	{
		"name": "Butcher Moon Cleaver",
		"slot": "weapon",
		"rarity": "Crafted",
		"cost": {"embers": 16, "runes": 1},
		"stats": {"melee_damage": 0.30, "max_hp": 22.0},
		"flags": ["slash_bleed", "cleave_wave", "execute_low_hp"],
		"desc": "Cleave becomes a bleed/wave/execution build core."
	},
	{
		"name": "Storm Choir Ring",
		"slot": "ring",
		"rarity": "Crafted",
		"cost": {"shards": 12, "echo_glass": 2},
		"stats": {"lightning_damage": 0.26, "cooldown_reduction": 0.04},
		"flags": ["chain_plus", "lance_calls_nova"],
		"desc": "Lightning gets chain pressure and helps cascade builds."
	},
	{
		"name": "Blood Debt Heart",
		"slot": "chest",
		"rarity": "Crafted",
		"cost": {"embers": 14, "runes": 2},
		"stats": {"spell_damage": 0.14, "max_hp": 46.0, "max_mana": 12.0},
		"flags": ["blood_cast", "blood_orbs", "chain_mana_refund"],
		"desc": "Low-resource casting becomes a real blood-mage engine."
	},
	{
		"name": "Corpse Spark Relic",
		"slot": "relic",
		"rarity": "Crafted",
		"cost": {"embers": 10, "shards": 10, "runes": 2},
		"stats": {"lightning_damage": 0.12, "void_damage": 0.12, "global_damage": 0.07},
		"flags": ["corpse_spark", "burn_death_explode", "curse_death_burst"],
		"desc": "Kills become chain-clear fuel."
	},
	{
		"name": "Contract Eater Amulet",
		"slot": "amulet",
		"rarity": "Crafted",
		"cost": {"runes": 4, "echo_glass": 2},
		"stats": {"global_damage": 0.16, "max_hp": 26.0},
		"flags": ["contract_eater", "depth_scaling"],
		"desc": "Dangerous dungeon routes become part of your build scaling."
	}
]

func _ready() -> void:
	game = get_parent()
	rng.randomize()

	_disable_old_meta_directors()
	_load_save()
	_build_ui()
	_apply_save_to_game()

	last_kills = int(game.get("kills"))
	last_rooms_cleared = int(game.get("rooms_cleared"))
	last_player_hp = float(game.get("player_hp"))

	enter_hub("Returned to Forgehold")

	set_process(true)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	if game == null:
		return

	if mode == "hub":
		_lock_hub_state()

	if mode == "combat":
		_watch_combat_progress()
		if float(game.get("player_hp")) <= 0.0:
			_on_player_death()

	autosave_timer += delta
	if autosave_timer >= 4.0:
		autosave_timer = 0.0
		if dirty:
			_save()

	if banner_timer > 0.0:
		banner_timer -= delta
		if banner_timer <= 0.0 and banner_label != null:
			banner_label.visible = false

	_update_ui()
	queue_redraw()


func _unhandled_input(event) -> void:
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return

	var key = event.keycode

	if mode == "combat":
		if key == KEY_ESCAPE:
			enter_hub("Returned from dungeon")
			get_viewport().set_input_as_handled()
		return

	if key == KEY_ESCAPE:
		if menu == "command":
			return
		menu = "command"
		_update_ui()
		get_viewport().set_input_as_handled()
		return

	if key == KEY_C:
		menu = "character"
		get_viewport().set_input_as_handled()
		return

	if key == KEY_I:
		menu = "inventory"
		get_viewport().set_input_as_handled()
		return

	if key == KEY_U:
		menu = "stash"
		get_viewport().set_input_as_handled()
		return

	if key == KEY_V:
		menu = "forge"
		get_viewport().set_input_as_handled()
		return

	if key == KEY_L:
		menu = "loadout"
		get_viewport().set_input_as_handled()
		return

	if key == KEY_P:
		menu = "passive"
		get_viewport().set_input_as_handled()
		return

	if key == KEY_K:
		menu = "skill"
		get_viewport().set_input_as_handled()
		return

	if key == KEY_M:
		menu = "contracts"
		get_viewport().set_input_as_handled()
		return

	if key == KEY_F5:
		_save()
		_banner("Character saved")
		get_viewport().set_input_as_handled()
		return

	if menu == "command":
		_handle_command_key(key)
	elif menu == "contracts":
		_handle_contract_key(key)
	elif menu == "inventory":
		_handle_inventory_key(key)
	elif menu == "stash":
		_handle_stash_key(key)
	elif menu == "forge":
		_handle_forge_key(key)
	elif menu == "loadout":
		_handle_loadout_key(key)
	elif menu == "passive":
		_handle_passive_key(key)
	elif menu == "skill":
		_handle_skill_key(key)
	elif menu == "character":
		_handle_character_key(key)

	get_viewport().set_input_as_handled()


func _disable_old_meta_directors() -> void:
	var old_nodes = [
		"Patch006CombatBuildDirector",
		"Patch007PersistentRPGDirector",
		"Patch008HubDirector"
	]

	for node_name in old_nodes:
		var node = get_parent().get_node_or_null(node_name)
		if node != null:
			node.queue_free()


func _load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
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
		"version": 9,
		"name": "Vaultbound",
		"level": 1,
		"xp": 0.0,
		"mastery_points": 0,
		"gold": 0,
		"materials": {
			"embers": 10,
			"shards": 5,
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
		"desc": "Weak starter focus. Replace this through crafting or dungeon loot.",
		"stats": {"spell_damage": 0.03},
		"flags": []
	}


func _normalize_save() -> void:
	var base = _default_save()

	for k in base.keys():
		if not save.has(k):
			save[k] = base[k]

	for k in base["materials"].keys():
		if not save["materials"].has(k):
			save["materials"][k] = base["materials"][k]

	for slot in SLOT_ORDER:
		if not save["equipped"].has(slot):
			save["equipped"][slot] = null

	for b in PASSIVE_BRANCHES:
		if not save["passives"].has(b):
			save["passives"][b] = 0

	for s in SKILL_LIST:
		if not save["skill_board"].has(s):
			save["skill_board"][s] = 0

	for k in base["stats"].keys():
		if not save["stats"].has(k):
			save["stats"][k] = 0

	dirty = true


func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(save, "\t"))
	dirty = false


func _dirty() -> void:
	dirty = true


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "Patch009ARPGUI"
	ui.layer = 95
	add_child(ui)

	chip_label = Label.new()
	chip_label.position = Vector2(16, 16)
	chip_label.custom_minimum_size = Vector2(1180, 34)
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.add_theme_font_size_override("font_size", 13)
	chip_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74))
	chip_label.add_theme_stylebox_override("normal", _chip_style())
	ui.add_child(chip_label)

	panel = PanelContainer.new()
	panel.position = Vector2(160, 70)
	panel.custom_minimum_size = Vector2(960, 590)
	panel.add_theme_stylebox_override("panel", _panel_style())
	ui.add_child(panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.74))
	vb.add_child(title_label)

	body_label = RichTextLabel.new()
	body_label.bbcode_enabled = false
	body_label.fit_content = false
	body_label.scroll_active = true
	body_label.custom_minimum_size = Vector2(928, 480)
	body_label.add_theme_font_size_override("normal_font_size", 13)
	body_label.add_theme_color_override("default_color", Color(0.84, 0.80, 0.72))
	vb.add_child(body_label)

	footer_label = Label.new()
	footer_label.add_theme_font_size_override("font_size", 12)
	footer_label.add_theme_color_override("font_color", Color(0.66, 0.62, 0.56))
	vb.add_child(footer_label)

	banner_label = Label.new()
	banner_label.position = Vector2(410, 664)
	banner_label.custom_minimum_size = Vector2(460, 32)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 14)
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.45))
	banner_label.add_theme_stylebox_override("normal", _chip_style())
	banner_label.visible = false
	ui.add_child(banner_label)


func _panel_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.014, 0.014, 0.017, 0.97)
	s.border_color = Color(0.72, 0.58, 0.36, 0.45)
	s.set_border_width_all(1)
	s.set_corner_radius_all(16)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 16
	s.content_margin_bottom = 16
	return s


func _chip_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.020, 0.020, 0.024, 0.86)
	s.border_color = Color(0.70, 0.56, 0.34, 0.28)
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s


func _update_ui() -> void:
	if chip_label == null:
		return

	chip_label.text = _top_chip()

	if mode == "combat":
		panel.visible = false
		return

	panel.visible = true

	if menu == "command":
		title_label.text = "FORGEHOLD HUB"
		body_label.text = _command_text()
		footer_label.text = "M contracts · I inventory · V forge · P passives · K skills · L loadout · U stash · C character"
	elif menu == "contracts":
		title_label.text = "DUNGEON CONTRACTS"
		body_label.text = _contracts_text()
		footer_label.text = "Up/Down select · Enter start contract · Esc hub"
	elif menu == "inventory":
		title_label.text = "INVENTORY / EQUIPMENT"
		body_label.text = _inventory_text()
		footer_label.text = "Up/Down select backpack · Enter equip · X salvage · Esc hub"
	elif menu == "stash":
		title_label.text = "STASH"
		body_label.text = _stash_text()
		footer_label.text = "Up/Down select stash · Enter withdraw · T deposit backpack · Esc hub"
	elif menu == "forge":
		title_label.text = "FORGE / CRAFTING"
		body_label.text = _forge_text()
		footer_label.text = "Up/Down select recipe · Enter craft · Esc hub"
	elif menu == "loadout":
		title_label.text = "LOADOUT"
		body_label.text = _loadout_text()
		footer_label.text = "1-6 toggle skill · Enter apply · max 4 skills · Esc hub"
	elif menu == "passive":
		title_label.text = "PASSIVE BOARD"
		body_label.text = _passive_text()
		footer_label.text = "Up/Down branch · Enter spend point · R refund all · Esc hub"
	elif menu == "skill":
		title_label.text = "SKILL BOARD"
		body_label.text = _skill_text()
		footer_label.text = "Up/Down skill · Enter upgrade selected skill · R reset skill board · Esc hub"
	elif menu == "character":
		title_label.text = "CHARACTER SHEET"
		body_label.text = _character_text()
		footer_label.text = "F5 save · Esc hub"


func _top_chip() -> String:
	var mats = save["materials"]
	var text = "Lv " + str(int(save["level"]))
	text += "  XP " + str(int(float(save["xp"]))) + "/" + str(int(_xp_to_next(int(save["level"]))))
	text += "  MP " + str(int(save["mastery_points"]))
	text += "  Gold " + str(int(save["gold"]))
	text += "  Embers " + str(int(mats["embers"]))
	text += "  Shards " + str(int(mats["shards"]))
	text += "  Runes " + str(int(mats["runes"]))
	text += "  Echo " + str(int(mats["echo_glass"]))
	return text


func _command_text() -> String:
	var lines = []
	lines.append("This is now the main ARPG command layer. You should prepare here, then enter dungeons.")
	lines.append("")
	lines.append("Activities")
	lines.append("M  Dungeon Contracts — choose the run you want.")
	lines.append("I  Inventory — equip, compare, salvage.")
	lines.append("V  Forge — craft build-defining gear.")
	lines.append("P  Passive Board — permanent account/character power.")
	lines.append("K  Skill Board — improve individual skills.")
	lines.append("L  Loadout — choose the skills you bring into runs.")
	lines.append("U  Stash — store long-term items.")
	lines.append("C  Character Sheet — inspect totals and build flags.")
	lines.append("")
	lines.append("Current Loadout: " + _join_array(save["loadout"]))
	lines.append("")
	lines.append("Equipped Build Engines")
	var flags = _collect_all_flags()
	if flags.size() == 0:
		lines.append("  none yet")
	else:
		for f in flags:
			lines.append("  " + str(f))
	lines.append("")
	lines.append("The next design push after this is item depth: affixes, tiers, uniques, sockets, and better comparison.")

	return "\n".join(lines)


func _contracts_text() -> String:
	var lines = []
	lines.append("Contracts are your run activities. Higher tiers give better rewards and more danger.")
	lines.append("")
	var i = 0
	for c in contract_pool:
		var mark = ">> " if i == selected_contract else "   "
		lines.append(mark + str(c["name"]) + "  Tier " + str(c["tier"]))
		lines.append("    " + str(c["desc"]))
		lines.append("    Biome: " + str(c["biome"]) + " · Threat: " + str(c["threat"]) + " · Length: " + str(c["length"]))
		lines.append("    Rewards: " + _join_array(c["reward_tags"]) + " · Mods: " + _join_array(c["mods"]))
		lines.append("")
		i += 1

	return "\n".join(lines)


func _inventory_text() -> String:
	var lines = []
	lines.append("Equipment")
	lines.append("")
	for slot in SLOT_ORDER:
		var item = save["equipped"].get(slot)
		if typeof(item) == TYPE_DICTIONARY:
			lines.append(_slot_label(slot) + ": " + _item_line(item))
			lines.append("    " + _item_stats_line(item))
		else:
			lines.append(_slot_label(slot) + ": empty")
	lines.append("")
	lines.append("Backpack")
	var bp = save["backpack"]
	if bp.size() == 0:
		lines.append("  empty")
	else:
		var i = 0
		for item2 in bp:
			var mark = ">> " if i == selected_inventory_index else "   "
			lines.append(mark + str(i + 1) + ". " + _item_line(item2))
			lines.append("      " + str(item2.get("desc", "")))
			lines.append("      " + _item_stats_line(item2))
			i += 1

	return "\n".join(lines)


func _stash_text() -> String:
	var lines = []
	lines.append("Backpack: " + str(save["backpack"].size()) + " items")
	lines.append("Stash: " + str(save["stash"].size()) + " items")
	lines.append("")
	lines.append("Stash Items")
	if save["stash"].size() == 0:
		lines.append("  empty")
	else:
		var i = 0
		for item in save["stash"]:
			var mark = ">> " if i == selected_stash_index else "   "
			lines.append(mark + str(i + 1) + ". " + _item_line(item))
			lines.append("      " + _item_stats_line(item))
			i += 1
	return "\n".join(lines)


func _forge_text() -> String:
	var lines = []
	lines.append("Crafted gear is persistent. This is where the build journey starts becoming deliberate.")
	lines.append("")
	lines.append("Materials: " + _materials_line())
	lines.append("")
	var i = 0
	for r in recipe_pool:
		var mark = ">> " if i == selected_recipe else "   "
		lines.append(mark + str(i + 1) + ". " + str(r["name"]) + " [" + str(r["slot"]) + "]")
		lines.append("      Cost: " + _cost_line(r["cost"]))
		lines.append("      " + str(r["desc"]))
		lines.append("      Flags: " + _join_array(r["flags"]))
		lines.append("")
		i += 1
	return "\n".join(lines)


func _loadout_text() -> String:
	var lines = []
	lines.append("Choose the skills this character brings into dungeons.")
	lines.append("Current: " + _join_array(save["loadout"]))
	lines.append("")
	var i = 0
	for s in SKILL_LIST:
		var checked = "[x]" if save["loadout"].has(s) else "[ ]"
		lines.append(str(i + 1) + ". " + checked + " " + s)
		i += 1
	lines.append("")
	lines.append("Current max: 4 skills. This will later become a socket/support system.")
	return "\n".join(lines)


func _passive_text() -> String:
	var lines = []
	lines.append("Permanent passive board. These points define long-term build identity.")
	lines.append("Unspent Mastery Points: " + str(int(save["mastery_points"])))
	lines.append("")
	var i = 0
	for b in PASSIVE_BRANCHES:
		var mark = ">> " if i == selected_passive else "   "
		var p = int(save["passives"].get(b, 0))
		lines.append(mark + str(i + 1) + ". " + b.capitalize() + " [" + str(p) + "]")
		lines.append("      " + _passive_desc(b, p))
		i += 1
	lines.append("")
	lines.append("Milestones at 2 / 4 / 7 points unlock real build flags.")
	return "\n".join(lines)


func _skill_text() -> String:
	var lines = []
	lines.append("Persistent skill board. This is separate from temporary run skill XP.")
	lines.append("")
	var i = 0
	for s in SKILL_LIST:
		var mark = ">> " if i == selected_skill_board else "   "
		var rank = int(save["skill_board"].get(s, 0))
		lines.append(mark + str(i + 1) + ". " + s + "  Rank " + str(rank))
		lines.append("      " + _skill_rank_desc(s, rank))
		i += 1
	lines.append("")
	lines.append("Each rank costs increasing gold/materials and adds permanent skill identity.")
	return "\n".join(lines)


func _character_text() -> String:
	var lines = []
	lines.append("Name: " + str(save["name"]))
	lines.append("Level: " + str(int(save["level"])))
	lines.append("XP: " + str(int(float(save["xp"]))) + " / " + str(int(_xp_to_next(int(save["level"])))))
	lines.append("Gold: " + str(int(save["gold"])))
	lines.append("")
	lines.append("Totals")
	for k in save["stats"].keys():
		lines.append("  " + str(k) + ": " + str(save["stats"][k]))
	lines.append("")
	lines.append("Computed Character Stats")
	var stats = _computed_character_stats()
	for k2 in stats.keys():
		lines.append("  " + str(k2) + ": " + str(snapped(float(stats[k2]), 0.001)))
	lines.append("")
	lines.append("Active Build Flags")
	var flags = _collect_all_flags()
	if flags.size() == 0:
		lines.append("  none")
	else:
		for f in flags:
			lines.append("  " + str(f))
	return "\n".join(lines)


func _handle_command_key(key: int) -> void:
	if key == KEY_ENTER or key == KEY_KP_ENTER:
		menu = "contracts"


func _handle_contract_key(key: int) -> void:
	if key == KEY_UP:
		selected_contract = max(0, selected_contract - 1)
	elif key == KEY_DOWN:
		selected_contract = min(contract_pool.size() - 1, selected_contract + 1)
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_start_contract(contract_pool[selected_contract])


func _handle_inventory_key(key: int) -> void:
	var bp = save["backpack"]
	if key == KEY_UP:
		selected_inventory_index = max(0, selected_inventory_index - 1)
	elif key == KEY_DOWN:
		selected_inventory_index = min(max(0, bp.size() - 1), selected_inventory_index + 1)
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_equip_selected_backpack_item()
	elif key == KEY_X:
		_salvage_selected_backpack_item()


func _handle_stash_key(key: int) -> void:
	var stash = save["stash"]
	if key == KEY_UP:
		selected_stash_index = max(0, selected_stash_index - 1)
	elif key == KEY_DOWN:
		selected_stash_index = min(max(0, stash.size() - 1), selected_stash_index + 1)
	elif key == KEY_T:
		for item in save["backpack"]:
			save["stash"].append(item)
		save["backpack"].clear()
		selected_inventory_index = 0
		_banner("Backpack deposited")
		_dirty()
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		if stash.size() > 0 and selected_stash_index < stash.size():
			var item = stash[selected_stash_index]
			stash.remove_at(selected_stash_index)
			save["backpack"].append(item)
			selected_stash_index = clamp(selected_stash_index, 0, max(0, stash.size() - 1))
			_banner("Item withdrawn")
			_dirty()


func _handle_forge_key(key: int) -> void:
	if key == KEY_UP:
		selected_recipe = max(0, selected_recipe - 1)
	elif key == KEY_DOWN:
		selected_recipe = min(recipe_pool.size() - 1, selected_recipe + 1)
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_craft_selected_recipe()


func _handle_loadout_key(key: int) -> void:
	var index = _number_key_index(key)
	if index >= 0 and index < SKILL_LIST.size():
		var skill = SKILL_LIST[index]
		if save["loadout"].has(skill):
			save["loadout"].erase(skill)
		else:
			if save["loadout"].size() >= 4:
				_banner("Loadout limit: 4")
				return
			save["loadout"].append(skill)
		_dirty()
		_banner("Loadout changed")
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_apply_save_to_game()
		_banner("Loadout applied")


func _handle_passive_key(key: int) -> void:
	if key == KEY_UP:
		selected_passive = max(0, selected_passive - 1)
	elif key == KEY_DOWN:
		selected_passive = min(PASSIVE_BRANCHES.size() - 1, selected_passive + 1)
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_spend_passive_point()
	elif key == KEY_R:
		var spent = 0
		for b in PASSIVE_BRANCHES:
			spent += int(save["passives"][b])
			save["passives"][b] = 0
		save["mastery_points"] = int(save["mastery_points"]) + spent
		_banner("Passives refunded")
		_dirty()


func _handle_skill_key(key: int) -> void:
	if key == KEY_UP:
		selected_skill_board = max(0, selected_skill_board - 1)
	elif key == KEY_DOWN:
		selected_skill_board = min(SKILL_LIST.size() - 1, selected_skill_board + 1)
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		_upgrade_selected_skill()
	elif key == KEY_R:
		var refund_gold = 0
		for s in SKILL_LIST:
			refund_gold += int(save["skill_board"][s]) * 25
			save["skill_board"][s] = 0
		save["gold"] = int(save["gold"]) + refund_gold
		_banner("Skill board reset")
		_dirty()


func _handle_character_key(key: int) -> void:
	pass


func _number_key_index(key: int) -> int:
	if key >= KEY_1 and key <= KEY_9:
		return key - KEY_1
	if key >= KEY_KP_1 and key <= KEY_KP_9:
		return key - KEY_KP_1
	return -1


func _start_contract(contract: Dictionary) -> void:
	mode = "combat"
	menu = "command"
	panel.visible = false

	save["stats"]["runs_total"] = int(save["stats"]["runs_total"]) + 1
	_dirty()

	_apply_save_to_game()

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
		"mods": contract["mods"],
		"threat": float(contract["threat"]),
		"elite": false,
		"treasure": false,
		"contract_length": int(contract["length"])
	})

	_clear_runtime()
	_spawn_contract_room(contract)

	_banner("Contract started")


func _spawn_contract_room(contract: Dictionary) -> void:
	var threat = float(contract["threat"])
	var tier = int(contract["tier"])
	var center = Vector2(640, 370)
	var enemies = []

	var count = 4 + tier * 2
	var i = 0
	while i < count:
		var ang = float(i) * TAU / float(count)
		var dist = 180.0 + 35.0 * float(i % 3)
		var pos = center + Vector2(cos(ang), sin(ang)) * dist

		var name = "Ash Grunt"
		var role = "chaser"
		var hp = 58.0 * threat
		var radius = 16.0
		var speed = 78.0
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
			hp = 145.0 * threat
			radius = 24.0
			speed = 46.0
			damage = 21.0 * threat

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


func _watch_combat_progress() -> void:
	var kills = int(game.get("kills"))
	if kills > last_kills:
		var gain = kills - last_kills
		var i = 0
		while i < gain:
			_award_kill()
			i += 1
	last_kills = kills

	var rooms = int(game.get("rooms_cleared"))
	if rooms > last_rooms_cleared:
		var gain_rooms = rooms - last_rooms_cleared
		var r = 0
		while r < gain_rooms:
			_award_room_clear()
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

	if rng.randf() < 0.10:
		save["backpack"].append(_generate_drop(depth))

	_dirty()


func _award_room_clear() -> void:
	var depth = max(1, int(game.get("run_depth")))
	_add_xp(45.0 + float(depth) * 7.0)
	save["gold"] = int(save["gold"]) + 12 + depth * 3

	var mats = save["materials"]
	mats["shards"] = int(mats["shards"]) + 3
	if depth % 3 == 0:
		mats["runes"] = int(mats["runes"]) + 1
	if depth % 5 == 0:
		mats["echo_glass"] = int(mats["echo_glass"]) + 1

	save["stats"]["rooms_total"] = int(save["stats"]["rooms_total"]) + 1

	var item = _generate_drop(depth)
	save["backpack"].append(item)
	_banner("Room cleared: loot saved")

	_dirty()


func _add_xp(amount: float) -> void:
	save["xp"] = float(save["xp"]) + amount
	var lvl = int(save["level"])

	while float(save["xp"]) >= _xp_to_next(lvl):
		save["xp"] = float(save["xp"]) - _xp_to_next(lvl)
		lvl += 1
		save["mastery_points"] = int(save["mastery_points"]) + 1
		_banner("LEVEL UP — Mastery point gained")

	save["level"] = lvl
	_dirty()


func _xp_to_next(level: int) -> float:
	return 160.0 + pow(float(level), 1.35) * 70.0


func _generate_drop(depth: int) -> Dictionary:
	var slots = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]
	var slot = slots[rng.randi_range(0, slots.size() - 1)]
	var rarity_roll = rng.randf()
	var rarity = "Magic"
	if rarity_roll > 0.94:
		rarity = "Legendary"
	elif rarity_roll > 0.72:
		rarity = "Rare"

	var family = rng.randi_range(0, 7)
	var name = ""
	var stats = {}
	var flags = []
	var desc = ""

	if family == 0:
		name = "Ash"
		stats = {"fire_damage": 0.08 + depth * 0.006}
		flags = ["fire_calls_lance"] if rarity == "Legendary" else []
		desc = "Fire scaling gear."
	elif family == 1:
		name = "Frost"
		stats = {"cold_damage": 0.08 + depth * 0.006, "freeze_duration": 0.04}
		flags = ["frostfire_steam"] if rarity == "Legendary" else []
		desc = "Cold and freeze setup gear."
	elif family == 2:
		name = "Storm"
		stats = {"lightning_damage": 0.08 + depth * 0.006, "cooldown_reduction": 0.01}
		flags = ["chain_plus"] if rarity != "Magic" else []
		desc = "Lightning and cooldown gear."
	elif family == 3:
		name = "Void"
		stats = {"void_damage": 0.08 + depth * 0.006, "max_mana": 5.0 + depth}
		flags = ["rift_pull"] if rarity != "Magic" else []
		desc = "Void and mana gear."
	elif family == 4:
		name = "Butcher"
		stats = {"melee_damage": 0.09 + depth * 0.006, "max_hp": 5.0 + depth}
		flags = ["slash_bleed"] if rarity != "Magic" else []
		desc = "Melee and bleed gear."
	elif family == 5:
		name = "Trapwright"
		stats = {"trap_damage": 0.10 + depth * 0.006}
		flags = ["double_trap"] if rarity != "Magic" else []
		desc = "Trap scaling gear."
	elif family == 6:
		name = "Blood"
		stats = {"spell_damage": 0.06 + depth * 0.005, "max_hp": 8.0 + depth}
		flags = ["blood_cast"] if rarity == "Legendary" else []
		desc = "Risk/reward caster gear."
	else:
		name = "Relic-Bound"
		stats = {"global_damage": 0.04 + depth * 0.004}
		flags = ["contract_eater"] if rarity == "Legendary" else []
		desc = "Global build scaling gear."

	var final_name = rarity + " " + name + " " + _slot_label(slot)

	if rarity == "Rare":
		stats["max_mana"] = float(stats.get("max_mana", 0.0)) + 8.0 + depth
	if rarity == "Legendary":
		stats["global_damage"] = float(stats.get("global_damage", 0.0)) + 0.08
		flags.append("cascade_engine")

	return {
		"name": final_name,
		"slot": slot,
		"rarity": rarity,
		"desc": desc + " Dropped at depth " + str(depth) + ".",
		"stats": stats,
		"flags": flags,
		"drop_depth": depth
	}


func _craft_selected_recipe() -> void:
	var recipe = recipe_pool[selected_recipe]
	if not _can_pay(recipe["cost"]):
		_banner("Not enough materials")
		return

	_pay(recipe["cost"])
	var item = _crafted_item(recipe)
	save["backpack"].append(item)
	save["stats"]["items_crafted"] = int(save["stats"]["items_crafted"]) + 1
	_banner("Crafted: " + str(item["name"]))
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
		"rarity": str(recipe["rarity"]),
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


func _equip_selected_backpack_item() -> void:
	var bp = save["backpack"]
	if bp.size() <= 0:
		return
	selected_inventory_index = clamp(selected_inventory_index, 0, bp.size() - 1)

	var item = bp[selected_inventory_index]
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
	bp.remove_at(selected_inventory_index)

	if old != null:
		bp.append(old)

	selected_inventory_index = clamp(selected_inventory_index, 0, max(0, bp.size() - 1))
	_apply_save_to_game()
	_banner("Equipped: " + str(item.get("name", "item")))
	_dirty()


func _salvage_selected_backpack_item() -> void:
	var bp = save["backpack"]
	if bp.size() <= 0:
		return

	selected_inventory_index = clamp(selected_inventory_index, 0, bp.size() - 1)
	var item = bp[selected_inventory_index]
	bp.remove_at(selected_inventory_index)

	var mats = save["materials"]
	var rarity = str(item.get("rarity", "Magic"))
	mats["embers"] = int(mats["embers"]) + 3
	mats["shards"] = int(mats["shards"]) + 1

	if rarity == "Rare":
		mats["shards"] = int(mats["shards"]) + 3
	if rarity == "Legendary":
		mats["runes"] = int(mats["runes"]) + 1
		mats["echo_glass"] = int(mats["echo_glass"]) + 1

	selected_inventory_index = clamp(selected_inventory_index, 0, max(0, bp.size() - 1))
	_banner("Item salvaged")
	_dirty()


func _spend_passive_point() -> void:
	if int(save["mastery_points"]) <= 0:
		_banner("No mastery points")
		return

	var branch = PASSIVE_BRANCHES[selected_passive]
	save["passives"][branch] = int(save["passives"].get(branch, 0)) + 1
	save["mastery_points"] = int(save["mastery_points"]) - 1
	_apply_save_to_game()
	_banner("Passive gained: " + branch.capitalize())
	_dirty()


func _upgrade_selected_skill() -> void:
	var skill = SKILL_LIST[selected_skill_board]
	var rank = int(save["skill_board"].get(skill, 0))
	var cost_gold = 60 + rank * 45
	var cost_shards = 2 + rank

	if int(save["gold"]) < cost_gold:
		_banner("Not enough gold")
		return

	if int(save["materials"]["shards"]) < cost_shards:
		_banner("Not enough shards")
		return

	save["gold"] = int(save["gold"]) - cost_gold
	save["materials"]["shards"] = int(save["materials"]["shards"]) - cost_shards
	save["skill_board"][skill] = rank + 1

	_apply_save_to_game()
	_banner(skill + " upgraded")
	_dirty()


func _apply_save_to_game() -> void:
	game.set("equipped", save["equipped"].duplicate(true))
	game.set("inventory", save["backpack"].duplicate(true))
	game.set("active_skills", save["loadout"].duplicate(true))
	game.set("selected_skill", 0)

	var max_hp = 120.0 + float(int(save["level"]) - 1) * 5.0
	var max_mana = 100.0 + float(int(save["level"]) - 1) * 2.0
	game.set("player_hp", max_hp)
	game.set("player_mana", max_mana)

	_install_character_soul_item()


func _install_character_soul_item() -> void:
	var equipped = game.get("equipped")
	if typeof(equipped) != TYPE_DICTIONARY:
		return

	equipped["soul"] = {
		"name": "Character Progression Soul",
		"slot": "soul",
		"rarity": "Permanent",
		"desc": "Permanent Patch 009 character, passive, and skill-board power.",
		"stats": _computed_character_stats(),
		"flags": _collect_progression_flags()
	}

	game.set("equipped", equipped)


func _computed_character_stats() -> Dictionary:
	var stats = {
		"max_hp": float(int(save["level"]) - 1) * 5.0,
		"max_mana": float(int(save["level"]) - 1) * 2.0,
		"global_damage": min(0.50, float(int(save["level"]) - 1) * 0.006)
	}

	var passives = save["passives"]
	_add_stat(stats, "fire_damage", int(passives["ash"]) * 0.055)
	_add_stat(stats, "cold_damage", int(passives["frost"]) * 0.055)
	_add_stat(stats, "lightning_damage", int(passives["storm"]) * 0.055)
	_add_stat(stats, "void_damage", int(passives["void"]) * 0.055)
	_add_stat(stats, "melee_damage", int(passives["steel"]) * 0.060)
	_add_stat(stats, "trap_damage", int(passives["trap"]) * 0.060)
	_add_stat(stats, "spell_damage", int(passives["blood"]) * 0.040)
	_add_stat(stats, "global_damage", int(passives["relic"]) * 0.025)

	var board = save["skill_board"]
	_add_stat(stats, "fire_damage", int(board["Fireball"]) * 0.035)
	_add_stat(stats, "melee_damage", int(board["Cleave"]) * 0.035)
	_add_stat(stats, "cold_damage", int(board["Frost Nova"]) * 0.035)
	_add_stat(stats, "lightning_damage", int(board["Storm Lance"]) * 0.035)
	_add_stat(stats, "void_damage", int(board["Void Rift"]) * 0.035)
	_add_stat(stats, "trap_damage", int(board["Blade Trap"]) * 0.035)

	return stats


func _add_stat(stats: Dictionary, key: String, amount: float) -> void:
	if not stats.has(key):
		stats[key] = 0.0
	stats[key] = float(stats[key]) + amount


func _collect_progression_flags() -> Array:
	var flags = []
	var p = save["passives"]
	_add_flag_threshold(flags, p, "ash", 2, "fire_calls_lance")
	_add_flag_threshold(flags, p, "ash", 4, "burn_death_explode")
	_add_flag_threshold(flags, p, "frost", 2, "nova_calls_fire")
	_add_flag_threshold(flags, p, "frost", 4, "frostfire_steam")
	_add_flag_threshold(flags, p, "storm", 2, "chain_plus")
	_add_flag_threshold(flags, p, "storm", 5, "lance_calls_nova")
	_add_flag_threshold(flags, p, "void", 2, "rift_pull")
	_add_flag_threshold(flags, p, "void", 4, "rift_calls_trap")
	_add_flag_threshold(flags, p, "steel", 2, "slash_bleed")
	_add_flag_threshold(flags, p, "steel", 4, "cleave_wave")
	_add_flag_threshold(flags, p, "trap", 2, "double_trap")
	_add_flag_threshold(flags, p, "trap", 4, "trap_calls_rift")
	_add_flag_threshold(flags, p, "blood", 2, "blood_cast")
	_add_flag_threshold(flags, p, "blood", 4, "blood_orbs")
	_add_flag_threshold(flags, p, "relic", 2, "contract_eater")
	_add_flag_threshold(flags, p, "relic", 4, "depth_scaling")

	var board = save["skill_board"]
	if int(board["Fireball"]) >= 3:
		_add_unique_flag(flags, "fire_calls_lance")
	if int(board["Frost Nova"]) >= 3:
		_add_unique_flag(flags, "frostfire_steam")
	if int(board["Storm Lance"]) >= 3:
		_add_unique_flag(flags, "chain_plus")
	if int(board["Void Rift"]) >= 3:
		_add_unique_flag(flags, "rift_calls_trap")
	if int(board["Blade Trap"]) >= 3:
		_add_unique_flag(flags, "trap_calls_rift")
	if int(board["Cleave"]) >= 3:
		_add_unique_flag(flags, "cleave_wave")

	return flags


func _collect_all_flags() -> Array:
	var flags = _collect_progression_flags()

	for slot in save["equipped"].keys():
		var item = save["equipped"][slot]
		if typeof(item) == TYPE_DICTIONARY:
			for f in item.get("flags", []):
				_add_unique_flag(flags, str(f))

	return flags


func _add_flag_threshold(flags: Array, p: Dictionary, branch: String, threshold: int, flag: String) -> void:
	if int(p.get(branch, 0)) >= threshold:
		_add_unique_flag(flags, flag)


func _add_unique_flag(flags: Array, flag: String) -> void:
	if not flags.has(flag):
		flags.append(flag)


func _on_player_death() -> void:
	save["stats"]["deaths"] = int(save["stats"]["deaths"]) + 1
	_dirty()
	enter_hub("You died. Loot, XP, and materials were saved.")


func enter_hub(message: String) -> void:
	mode = "hub"
	menu = "command"
	_clear_runtime()
	_apply_save_to_game()

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

	_banner(message)


func _lock_hub_state() -> void:
	game.set("run_state", "hub")
	game.set("choice_mode", "")
	game.set("paused_by_choice", false)
	game.set("player_pos", hub_center)


func _materials_line() -> String:
	var m = save["materials"]
	return "Embers " + str(int(m["embers"])) + " · Shards " + str(int(m["shards"])) + " · Runes " + str(int(m["runes"])) + " · Echo Glass " + str(int(m["echo_glass"]))


func _cost_line(cost: Dictionary) -> String:
	var parts = []
	for k in cost.keys():
		parts.append(str(k) + " " + str(int(cost[k])))
	return _join_array(parts)


func _item_line(item: Dictionary) -> String:
	return str(item.get("name", "Item")) + " [" + str(item.get("rarity", "")) + "]"


func _item_stats_line(item: Dictionary) -> String:
	var parts = []
	var stats = item.get("stats", {})
	for k in stats.keys():
		parts.append(str(k) + " " + str(snapped(float(stats[k]), 0.001)))
	var flags = item.get("flags", [])
	if flags.size() > 0:
		parts.append("flags: " + _join_array(flags))
	if parts.size() == 0:
		return "no stats"
	return _join_array(parts)


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
		"ring1":
			return "Ring 1"
		"ring2":
			return "Ring 2"
		"relic":
			return "Relic"
		"ring":
			return "Ring"
		_:
			return slot.capitalize()


func _passive_desc(branch: String, points: int) -> String:
	var milestone = ""
	if points < 2:
		milestone = "Next milestone at 2."
	elif points < 4:
		milestone = "Next milestone at 4."
	elif points < 7:
		milestone = "Next milestone at 7."
	else:
		milestone = "High investment branch."

	match branch:
		"ash":
			return "Fireball, burn, corpse explosions, Fire -> Lightning chains. " + milestone
		"frost":
			return "Freeze, Frostfire steam, shatter setups. " + milestone
		"storm":
			return "Lightning, chain count, cooldown, cascade speed. " + milestone
		"void":
			return "Void Rift, curses, death bursts, trap gravity. " + milestone
		"steel":
			return "Cleave, bleed, melee execution, blood waves. " + milestone
		"trap":
			return "Blade Trap, poison, double traps, rift loops. " + milestone
		"blood":
			return "Blood casting, low-resource power, orb engines. " + milestone
		"relic":
			return "Global scaling, contract greed, depth scaling. " + milestone
	return milestone


func _skill_rank_desc(skill: String, rank: int) -> String:
	if skill == "Fireball":
		return "Permanent fire scaling. Rank 3 supports Fire -> Lightning chains."
	if skill == "Cleave":
		return "Permanent melee scaling. Rank 3 supports cleave waves."
	if skill == "Frost Nova":
		return "Permanent cold scaling. Rank 3 supports Frostfire detonations."
	if skill == "Storm Lance":
		return "Permanent lightning scaling. Rank 3 supports extra chain logic."
	if skill == "Void Rift":
		return "Permanent void scaling. Rank 3 supports trap/rift loops."
	if skill == "Blade Trap":
		return "Permanent trap scaling. Rank 3 supports trap/rift loops."
	return "Permanent skill scaling."


func _join_array(arr) -> String:
	if typeof(arr) != TYPE_ARRAY:
		return str(arr)
	if arr.size() == 0:
		return "none"

	var parts = []
	for x in arr:
		parts.append(str(x))
	return ", ".join(parts)


func _banner(text: String) -> void:
	banner_text = text
	banner_timer = 2.4
	if banner_label != null:
		banner_label.text = text
		banner_label.visible = true


func _draw() -> void:
	if mode != "hub":
		return

	_draw_hub()


func _draw_hub() -> void:
	var rect = Rect2(Vector2(60, 84), Vector2(1160, 566))
	draw_rect(rect, Color(0.014, 0.013, 0.016, 0.96), true)
	draw_rect(rect, Color(0.70, 0.54, 0.30, 0.22), false, 2.0)

	var c = hub_center
	draw_arc(c, 220, -PI, PI, 96, Color(0.85, 0.62, 0.34, 0.12), 2.0)
	draw_arc(c, 135, -PI, PI, 96, Color(0.85, 0.62, 0.34, 0.12), 2.0)

	var station_data = [
		["M", "Contracts", Vector2(640, 170), Color(0.88, 0.38, 1.0)],
		["I", "Inventory", Vector2(280, 310), Color(0.85, 0.72, 0.44)],
		["V", "Forge", Vector2(1000, 310), Color(1.0, 0.42, 0.16)],
		["P", "Passives", Vector2(400, 500), Color(0.70, 0.58, 1.0)],
		["K", "Skills", Vector2(640, 545), Color(0.50, 0.92, 0.70)],
		["L", "Loadout", Vector2(880, 500), Color(0.48, 0.82, 1.0)],
		["U", "Stash", Vector2(640, 335), Color(0.95, 0.78, 0.34)]
	]

	for s in station_data:
		_draw_station(str(s[0]), str(s[1]), s[2], s[3])

	draw_circle(c + Vector2(4, 8), 18.0, Color(0, 0, 0, 0.32))
	draw_circle(c, 16.0, Color(0.92, 0.84, 0.68, 0.96))
	draw_arc(c, 23.0, -PI, PI, 48, Color(1.0, 0.78, 0.38, 0.45), 2.0)


func _draw_station(key_text: String, name_text: String, pos: Vector2, color: Color) -> void:
	draw_circle(pos + Vector2(5, 8), 32.0, Color(0, 0, 0, 0.30))
	draw_circle(pos, 28.0, Color(0.030, 0.028, 0.032, 0.94))
	draw_arc(pos, 34.0, -PI, PI, 64, Color(color.r, color.g, color.b, 0.55), 3.0)
	draw_circle(pos, 11.0, Color(color.r, color.g, color.b, 0.68))

	var font = ThemeDB.fallback_font
	var txt = key_text + "  " + name_text
	var size_txt = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	var p = pos + Vector2(-size_txt.x * 0.5, 52)
	draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.92, 0.86, 0.72, 0.95))
