extends Node2D

const PATCH015B_ALL_SKILLS = ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"]

# Relic Forge: Vaultbound
# Patch 014 clean architecture coordinator.
#
# This file should stay small.
# Game logic lives in scripts/core, scripts/data, scripts/systems, scripts/visuals.

var state: RVGameState = RVGameState.new()
var textures: Dictionary = {}
var autosave_timer: float = 0.0

func _ready() -> void:
	state.init()
	RVSaveSystem.load_into(state)
	state.init()
	_load_patch015a_ui_textures()

	RVHubSystem.rebuild_objects(state)
	state.enter_hub()
	state.add_notice("Forgehold loaded")
	_save_now(false)

	set_process(true)
	set_process_unhandled_input(true)

func _process(delta: float) -> void:
	RVPlayerSystem.update(state, delta)
	RVSkillSystem.update(state, delta)

	if state.mode == "hub":
		RVHubSystem.update_focus(state)
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			RVSkillSystem.cast_selected(state, get_global_mouse_position())
		RVCombatSystem.update(state, delta)

	if state.notice_time > 0.0:
		state.notice_time = max(0.0, state.notice_time - delta)

	autosave_timer += delta
	if autosave_timer >= 10.0:
		autosave_timer = 0.0
		_save_now(false)

	queue_redraw()

func _unhandled_input(event) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo:
			_handle_key(key.keycode)

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and state.mode == "combat":
			RVSkillSystem.cast_selected(state, get_global_mouse_position())

func _handle_key(keycode: int) -> void:
	if keycode >= KEY_1 and keycode <= KEY_6:
		var index: int = keycode - KEY_1
		if state.mode == "hub":
			_toggle_skill_from_index(index)
		else:
			if index < state.active_skills.size():
				state.selected_skill = index
		return

	if keycode == KEY_Q and state.mode == "combat":
		_cycle_selected_skill(-1)
		return

	if keycode == KEY_E and state.mode == "combat":
		_cycle_selected_skill(1)
		return

	if keycode == KEY_SPACE and state.mode == "combat":
		RVSkillSystem.cast_selected(state, get_global_mouse_position())
		return

	if keycode == KEY_E and state.mode == "hub":
		RVHubSystem.interact_primary(state)
		_save_now(false)
		return

	if keycode == KEY_X and state.mode == "hub":
		RVHubSystem.interact_secondary(state)
		_save_now(false)
		return

	if keycode == KEY_ESCAPE:
		if state.mode == "combat":
			state.enter_hub()
			state.add_notice("Returned to Forgehold")
			_save_now(false)
		return

	if keycode == KEY_F5:
		_save_now(true)
		return

func _draw() -> void:
	RVRenderSystem.draw_world(self, state, textures)

func _load_patch015a_ui_textures() -> void:
	var paths: Dictionary = {
		"ui_skill_slot_empty": "res://assets/ui/patch015a/slices/normalized/ui_skill_slot_empty.png",
		"ui_skill_slot_selected": "res://assets/ui/patch015a/slices/normalized/ui_skill_slot_selected.png",
		"ui_inventory_slot": "res://assets/ui/patch015a/slices/normalized/ui_inventory_slot.png",
		"ui_equipped_item_slot": "res://assets/ui/patch015a/slices/normalized/ui_equipped_item_slot.png",
		"ui_material_chip": "res://assets/ui/patch015a/slices/normalized/ui_material_chip.png",
		"ui_passive_node_circle": "res://assets/ui/patch015a/slices/normalized/ui_passive_node_circle.png",
		"ui_health_bar_frame": "res://assets/ui/patch015a/slices/normalized/ui_health_bar_frame.png",
		"ui_mana_bar_frame": "res://assets/ui/patch015a/slices/normalized/ui_mana_bar_frame.png",
		"ui_tooltip_panel_large": "res://assets/ui/patch015a/slices/normalized/ui_tooltip_panel_large.png",
		"ui_notice_banner": "res://assets/ui/patch015a/slices/normalized/ui_notice_banner.png",
		"ui_vertical_card_panel": "res://assets/ui/patch015a/slices/normalized/ui_vertical_card_panel.png",
		"ui_main_window_panel": "res://assets/ui/patch015a/slices/normalized/ui_main_window_panel.png"
	}

	for key in paths.keys():
		if ResourceLoader.exists(paths[key]):
			var tex: Texture2D = load(paths[key])
			if tex != null:
				textures[key] = tex

func _toggle_skill_from_index(index: int) -> void:
	if index < 0 or index >= PATCH015B_ALL_SKILLS.size():
		return

	var skill: String = str(PATCH015B_ALL_SKILLS[index])

	if state.active_skills.has(skill):
		if state.active_skills.size() <= 1:
			state.add_notice("Keep at least one skill equipped")
			return
		state.active_skills.erase(skill)
		state.add_notice(skill + " removed from loadout")
	else:
		if state.active_skills.size() >= 4:
			state.add_notice("Loadout limit: 4 skills")
			return
		state.active_skills.append(skill)
		state.add_notice(skill + " added to loadout")

	state.selected_skill = clamp(state.selected_skill, 0, state.active_skills.size() - 1)
	_save_now(false)


func _cycle_selected_skill(direction: int) -> void:
	if state.active_skills.size() <= 0:
		return

	state.selected_skill = (state.selected_skill + direction) % state.active_skills.size()
	if state.selected_skill < 0:
		state.selected_skill = state.active_skills.size() - 1


func _save_now(show_notice: bool) -> void:
	RVSaveSystem.save(state)
	if show_notice:
		state.add_notice("Saved")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		RVSaveSystem.save(state)
