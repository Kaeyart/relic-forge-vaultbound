extends Node2D

# Relic Forge: Vaultbound
# Patch 014 clean architecture coordinator.
#
# This file should stay small.
# Game logic lives in scripts/core, scripts/data, scripts/systems, scripts/visuals.

var state: RVGameState = RVGameState.new()
var textures: Dictionary = {}

func _ready() -> void:
	state.init()
	RVSaveSystem.load_into(state)
	state.init()

	RVHubSystem.rebuild_objects(state)
	state.enter_hub()
	state.add_notice("Forgehold loaded")

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
		if index < state.active_skills.size():
			state.selected_skill = index
		return

	if keycode == KEY_SPACE and state.mode == "combat":
		RVSkillSystem.cast_selected(state, get_global_mouse_position())
		return

	if keycode == KEY_E and state.mode == "hub":
		RVHubSystem.interact_primary(state)
		return

	if keycode == KEY_X and state.mode == "hub":
		RVHubSystem.interact_secondary(state)
		return

	if keycode == KEY_ESCAPE:
		if state.mode == "combat":
			state.enter_hub()
			state.add_notice("Returned to Forgehold")
		return

	if keycode == KEY_F5:
		RVSaveSystem.save(state)
		state.add_notice("Saved")
		return


func _draw() -> void:
	RVRenderSystem.draw_world(self, state, textures)
