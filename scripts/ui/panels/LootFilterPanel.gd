class_name RVLootFilterPanel
extends Control

const PRESETS: Array[String] = ["Show All", "Starter", "Strict", "Crafting", "Maps", "Build Filter"]
const BUILD_TAGS: Array[String] = ["fire", "cold", "lightning", "physical", "bleed", "void", "spell", "attack", "life", "defense", "mana", "spirit"]

@onready var preset_label: Label = get_node_or_null("%PresetLabel") as Label
@onready var summary_label: Label = get_node_or_null("%SummaryLabel") as Label
@onready var affix_tier_label: Label = get_node_or_null("%AffixTierLabel") as Label
@onready var forge_potential_label: Label = get_node_or_null("%ForgePotentialLabel") as Label
@onready var build_tag_button: Button = get_node_or_null("%BuildTagButton") as Button
@onready var require_build_tag_button: Button = get_node_or_null("%RequireBuildTagButton") as Button
@onready var close_button: Button = get_node_or_null("%CloseButton") as Button
@onready var footer_close_button: Button = get_node_or_null("%FooterCloseButton") as Button

@onready var show_normal_button: Button = get_node_or_null("%ShowNormalButton") as Button
@onready var show_magic_button: Button = get_node_or_null("%ShowMagicButton") as Button
@onready var show_rare_button: Button = get_node_or_null("%ShowRareButton") as Button
@onready var show_unique_button: Button = get_node_or_null("%ShowUniqueButton") as Button
@onready var show_maps_button: Button = get_node_or_null("%ShowMapsButton") as Button
@onready var show_gems_button: Button = get_node_or_null("%ShowGemsButton") as Button
@onready var show_currency_button: Button = get_node_or_null("%ShowCurrencyButton") as Button
@onready var show_materials_button: Button = get_node_or_null("%ShowMaterialsButton") as Button
@onready var show_crafting_bases_button: Button = get_node_or_null("%ShowCraftingBasesButton") as Button
@onready var show_hidden_button: Button = get_node_or_null("%ShowHiddenButton") as Button

@onready var auto_currency_button: Button = get_node_or_null("%AutoCurrencyButton") as Button
@onready var auto_materials_button: Button = get_node_or_null("%AutoMaterialsButton") as Button
@onready var auto_maps_button: Button = get_node_or_null("%AutoMapsButton") as Button
@onready var auto_gems_button: Button = get_node_or_null("%AutoGemsButton") as Button

@onready var preset_prev_button: Button = get_node_or_null("%PresetPrevButton") as Button
@onready var preset_next_button: Button = get_node_or_null("%PresetNextButton") as Button
@onready var reset_preset_button: Button = get_node_or_null("%ResetPresetButton") as Button
@onready var affix_tier_down_button: Button = get_node_or_null("%AffixTierDownButton") as Button
@onready var affix_tier_up_button: Button = get_node_or_null("%AffixTierUpButton") as Button
@onready var forge_potential_down_button: Button = get_node_or_null("%ForgePotentialDownButton") as Button
@onready var forge_potential_up_button: Button = get_node_or_null("%ForgePotentialUpButton") as Button

var current_state: RVGameState = null
var toggle_buttons: Dictionary = {}

func _ready() -> void:
	visible = false
	toggle_buttons = {
		"show_normal": show_normal_button,
		"show_magic": show_magic_button,
		"show_rare": show_rare_button,
		"show_uniques": show_unique_button,
		"show_maps": show_maps_button,
		"show_gems": show_gems_button,
		"show_currency": show_currency_button,
		"show_materials": show_materials_button,
		"show_crafting_bases": show_crafting_bases_button,
		"show_hidden_auto_pickup_notice": show_hidden_button,
		"auto_pickup_currency": auto_currency_button,
		"auto_pickup_materials": auto_materials_button,
		"auto_pickup_maps": auto_maps_button,
		"auto_pickup_gems": auto_gems_button,
	}
	_freeze_button_layouts()
	_bind(close_button, _on_close_pressed)
	_bind(footer_close_button, _on_close_pressed)
	_bind(preset_prev_button, _on_preset_prev_pressed)
	_bind(preset_next_button, _on_preset_next_pressed)
	_bind(reset_preset_button, _on_apply_preset_pressed)
	_bind(affix_tier_down_button, _on_affix_tier_down_pressed)
	_bind(affix_tier_up_button, _on_affix_tier_up_pressed)
	_bind(forge_potential_down_button, _on_forge_potential_down_pressed)
	_bind(forge_potential_up_button, _on_forge_potential_up_pressed)
	_bind(build_tag_button, _on_build_tag_pressed)
	_bind(require_build_tag_button, _on_require_build_tag_pressed)
	for key: String in toggle_buttons.keys():
		_bind(toggle_buttons[key] as Button, _on_toggle_pressed.bind(key))

func update_from_state(state: RVGameState) -> void:
	current_state = state
	_ensure_defaults(state)
	_render(state)

func handle_panel_key(state: RVGameState, keycode: int) -> bool:
	current_state = state
	_ensure_defaults(state)
	match keycode:
		KEY_P:
			_cycle_preset(1)
			return true
		KEY_O:
			_cycle_preset(-1)
			return true
		KEY_1:
			_toggle("show_normal")
			return true
		KEY_2:
			_toggle("show_magic")
			return true
		KEY_3:
			_toggle("show_rare")
			return true
		KEY_4:
			_toggle("show_uniques")
			return true
		KEY_5:
			_toggle("show_maps")
			return true
		KEY_6:
			_toggle("show_gems")
			return true
		KEY_7:
			_toggle("show_crafting_bases")
			return true
		KEY_8:
			_toggle("auto_pickup_currency")
			return true
		KEY_9:
			_toggle("auto_pickup_materials")
			return true
		KEY_0:
			_toggle("auto_pickup_maps")
			return true
		KEY_Q:
			_adjust_int("min_affix_tier", -1, 1, 5)
			return true
		KEY_E:
			_adjust_int("min_affix_tier", 1, 1, 5)
			return true
		KEY_Z:
			_adjust_int("min_forge_potential", -5, 0, 80)
			return true
		KEY_X:
			_adjust_int("min_forge_potential", 5, 0, 80)
			return true
		KEY_C:
			_cycle_build_tag()
			return true
		KEY_V:
			_toggle("require_build_tag")
			return true
	return false

func _freeze_button_layouts() -> void:
	for button: Button in _all_buttons():
		if button == null:
			continue
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = 0
		button.size_flags_vertical = 0
		button.clip_text = true

func _all_buttons() -> Array[Button]:
	return [preset_prev_button, preset_next_button, close_button, footer_close_button, reset_preset_button, affix_tier_down_button, affix_tier_up_button, forge_potential_down_button, forge_potential_up_button, build_tag_button, require_build_tag_button, show_normal_button, show_magic_button, show_rare_button, show_unique_button, show_maps_button, show_gems_button, show_currency_button, show_materials_button, show_crafting_bases_button, show_hidden_button, auto_currency_button, auto_materials_button, auto_maps_button, auto_gems_button]

func _bind(button: Button, callback: Callable) -> void:
	if button != null and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _ensure_defaults(state: RVGameState) -> void:
	if state == null:
		return
	if str(state.get("loot_filter_preset")) == "" or not PRESETS.has(str(state.get("loot_filter_preset"))):
		state.set("loot_filter_preset", "Starter")
	var settings: Dictionary = _settings(state)
	var defaults: Dictionary = _default_settings()
	for key: String in defaults.keys():
		if not settings.has(key):
			settings[key] = defaults[key]
	state.set("loot_filter_settings", settings)

func _default_settings() -> Dictionary:
	return {
		"show_normal": true,
		"show_magic": true,
		"show_rare": true,
		"show_uniques": true,
		"show_maps": true,
		"show_gems": true,
		"show_currency": true,
		"show_materials": true,
		"show_crafting_bases": true,
		"show_hidden_auto_pickup_notice": false,
		"auto_pickup_currency": true,
		"auto_pickup_materials": true,
		"auto_pickup_maps": false,
		"auto_pickup_gems": false,
		"min_affix_tier": 3,
		"min_forge_potential": 25,
		"build_tag": "fire",
		"require_build_tag": false,
	}

func _settings(state: RVGameState) -> Dictionary:
	var value: Variant = state.get("loot_filter_settings")
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value).duplicate(true)
	return _default_settings()

func _set_settings(state: RVGameState, settings: Dictionary) -> void:
	state.set("loot_filter_settings", settings)

func _render(state: RVGameState) -> void:
	var settings: Dictionary = _settings(state)
	if preset_label != null:
		preset_label.text = str(state.get("loot_filter_preset"))
	for key: String in toggle_buttons.keys():
		_update_toggle_button(toggle_buttons[key] as Button, bool(settings.get(key, false)))
	if affix_tier_label != null:
		affix_tier_label.text = "Highlight Affix Tier: T" + str(int(settings.get("min_affix_tier", 3))) + "+"
	if forge_potential_label != null:
		forge_potential_label.text = "Highlight Forge Potential: " + str(int(settings.get("min_forge_potential", 25))) + "+"
	if build_tag_button != null:
		build_tag_button.text = "Tag: " + str(settings.get("build_tag", "fire"))
	if require_build_tag_button != null:
		require_build_tag_button.text = "Require Tag"
		_update_toggle_button(require_build_tag_button, bool(settings.get("require_build_tag", false)))
	if summary_label != null:
		summary_label.text = _summary_text(state, settings)

func _update_toggle_button(button: Button, enabled: bool) -> void:
	if button == null:
		return
	# Absolute scene layout: never move, resize, or rewrite labels with variable-length prefixes.
	button.modulate = Color(1.0, 1.0, 1.0, 1.0) if enabled else Color(0.48, 0.48, 0.48, 1.0)
	button.tooltip_text = "Enabled" if enabled else "Disabled"

func _summary_text(state: RVGameState, settings: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Preset: " + str(state.get("loot_filter_preset")))
	lines.append("Visible rarities: " + _onoff_list(settings, ["show_normal", "show_magic", "show_rare", "show_uniques"]))
	lines.append("Special categories: " + _onoff_list(settings, ["show_maps", "show_gems", "show_currency", "show_materials", "show_crafting_bases"]))
	lines.append("Auto pickup: " + _onoff_list(settings, ["auto_pickup_currency", "auto_pickup_materials", "auto_pickup_maps", "auto_pickup_gems"]))
	lines.append("Highlights: affix tier T" + str(settings.get("min_affix_tier", 3)) + "+, forge potential " + str(settings.get("min_forge_potential", 25)) + "+")
	lines.append("Build tag: " + str(settings.get("build_tag", "fire")) + (" required" if bool(settings.get("require_build_tag", false)) else " highlighted"))
	return "\n".join(lines)

func _onoff_list(settings: Dictionary, keys: Array[String]) -> String:
	var out: Array[String] = []
	for key: String in keys:
		if bool(settings.get(key, false)):
			out.append(key.replace("show_", "").replace("auto_pickup_", ""))
	return ", ".join(out) if not out.is_empty() else "none"

func _on_toggle_pressed(key: String) -> void:
	_toggle(key)

func _toggle(key: String) -> void:
	if current_state == null:
		return
	var settings: Dictionary = _settings(current_state)
	settings[key] = not bool(settings.get(key, false))
	_set_settings(current_state, settings)
	_render(current_state)

func _adjust_int(key: String, delta: int, min_value: int, max_value: int) -> void:
	if current_state == null:
		return
	var settings: Dictionary = _settings(current_state)
	settings[key] = clampi(int(settings.get(key, min_value)) + delta, min_value, max_value)
	_set_settings(current_state, settings)
	_render(current_state)

func _cycle_preset(delta: int) -> void:
	if current_state == null:
		return
	var current: String = str(current_state.get("loot_filter_preset"))
	var index: int = PRESETS.find(current)
	if index < 0:
		index = 0
	index = wrapi(index + delta, 0, PRESETS.size())
	current_state.set("loot_filter_preset", PRESETS[index])
	_apply_preset(PRESETS[index])

func _apply_preset(preset: String) -> void:
	if current_state == null:
		return
	var settings: Dictionary = _default_settings()
	match preset:
		"Show All":
			settings["show_normal"] = true
			settings["show_magic"] = true
			settings["min_affix_tier"] = 5
			settings["min_forge_potential"] = 0
		"Starter":
			settings["show_normal"] = true
			settings["show_magic"] = true
			settings["show_rare"] = true
			settings["min_affix_tier"] = 4
			settings["min_forge_potential"] = 15
		"Strict":
			settings["show_normal"] = false
			settings["show_magic"] = false
			settings["show_rare"] = true
			settings["show_crafting_bases"] = false
			settings["min_affix_tier"] = 2
			settings["min_forge_potential"] = 30
		"Crafting":
			settings["show_normal"] = true
			settings["show_magic"] = true
			settings["show_rare"] = true
			settings["show_crafting_bases"] = true
			settings["min_affix_tier"] = 3
			settings["min_forge_potential"] = 25
		"Maps":
			settings["show_normal"] = false
			settings["show_magic"] = false
			settings["show_rare"] = false
			settings["show_maps"] = true
			settings["auto_pickup_maps"] = false
		"Build Filter":
			settings["show_normal"] = false
			settings["show_magic"] = true
			settings["show_rare"] = true
			settings["require_build_tag"] = true
			settings["min_affix_tier"] = 3
	current_state.set("loot_filter_preset", preset)
	_set_settings(current_state, settings)
	_render(current_state)

func _cycle_build_tag() -> void:
	if current_state == null:
		return
	var settings: Dictionary = _settings(current_state)
	var current: String = str(settings.get("build_tag", "fire"))
	var index: int = BUILD_TAGS.find(current)
	if index < 0:
		index = 0
	settings["build_tag"] = BUILD_TAGS[wrapi(index + 1, 0, BUILD_TAGS.size())]
	_set_settings(current_state, settings)
	_render(current_state)

func _on_preset_prev_pressed() -> void:
	_cycle_preset(-1)

func _on_preset_next_pressed() -> void:
	_cycle_preset(1)

func _on_apply_preset_pressed() -> void:
	if current_state != null:
		_apply_preset(str(current_state.get("loot_filter_preset")))

func _on_affix_tier_down_pressed() -> void:
	_adjust_int("min_affix_tier", -1, 1, 5)

func _on_affix_tier_up_pressed() -> void:
	_adjust_int("min_affix_tier", 1, 1, 5)

func _on_forge_potential_down_pressed() -> void:
	_adjust_int("min_forge_potential", -5, 0, 80)

func _on_forge_potential_up_pressed() -> void:
	_adjust_int("min_forge_potential", 5, 0, 80)

func _on_build_tag_pressed() -> void:
	_cycle_build_tag()

func _on_require_build_tag_pressed() -> void:
	_toggle("require_build_tag")

func _on_close_pressed() -> void:
	if current_state != null:
		current_state.panel_mode = ""
	visible = false
