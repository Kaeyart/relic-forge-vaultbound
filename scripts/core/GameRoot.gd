extends Node2D

@onready var hub: RVHubRoot = %Hub
@onready var combat: RVCombatArena = %Combat
@onready var player: RVPlayerActor = %Player
@onready var hud: RVGameHUD = %GameHUD
@onready var panels: RVUIPanelRoot = %UIPanelRoot

var state: RVGameState = RVGameState.new()
var autosave_timer: float = 0.0

func _ready() -> void:
	state.init_new()
	RVSaveSystem.load_into(state)
	state.ensure_defaults()
	state.enter_hub()

	combat.visible = false
	hub.visible = true

	combat.combat_finished.connect(_on_combat_finished)
	combat.player_died.connect(_on_player_died)

	player.sync_from_state(state)

	set_process(true)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	_update_player(delta)
	RVSkillSystem.update(state, delta)

	if state.mode == "hub":
		hub.update_focus(state)
	else:
		combat.update_combat(state, player, delta)

	if state.notice_time > 0.0:
		state.notice_time = max(0.0, state.notice_time - delta)

	autosave_timer += delta
	if autosave_timer >= 10.0:
		autosave_timer = 0.0
		RVSaveSystem.save(state)

	hud.update_from_state(state)
	panels.update_from_state(state)


func _update_player(delta: float) -> void:
	var move: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		move.y += 1.0
	if Input.is_key_pressed(KEY_A):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move.x += 1.0

	if move.length() > 0.01:
		move = move.normalized()
		state.player_pos += move * state.player_speed * delta

	state.player_pos.x = clamp(state.player_pos.x, 80.0, 1200.0)
	state.player_pos.y = clamp(state.player_pos.y, 95.0, 620.0)

	state.invuln = max(0.0, state.invuln - delta)
	state.player_mana = min(state.max_mana, state.player_mana + 14.0 * delta)

	player.sync_from_state(state)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo:
			_handle_key(key_event.keycode)

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT and state.mode == "combat":
			combat.cast_selected_skill(state, get_global_mouse_position())


func _handle_key(keycode: int) -> void:
	if state.panel_mode != "":
		if keycode == KEY_ESCAPE:
			state.panel_mode = ""
			return
		if RVBuildcraftSystem.handle_key(state, keycode):
			RVSaveSystem.save(state)
			return

	if keycode >= KEY_1 and keycode <= KEY_6:
		var index: int = keycode - KEY_1
		if state.mode == "hub":
			var skill_names: Array = RVSkillDB.names()
			if index < skill_names.size():
				RVSkillSystem.toggle_skill_loadout(state, str(skill_names[index]))
		else:
			if index < state.active_skills.size():
				state.selected_skill_index = index
		return

	match keycode:
		KEY_E:
			if state.mode == "hub":
				var activity: Dictionary = hub.interact_primary(state)
				if not activity.is_empty():
					_start_activity(activity)
			elif state.mode == "combat":
				combat.interact(state)
		KEY_X:
			if state.mode == "hub" and hub.has_method("interact_secondary"):
				hub.call("interact_secondary", state)
		KEY_I:
			state.toggle_panel("inventory")
		KEY_C:
			state.toggle_panel("crafting")
		KEY_P:
			state.toggle_panel("passive_atlas")
		KEY_K:
			state.toggle_panel("skill_gems")
		KEY_B:
			state.toggle_panel("stash")
		KEY_M:
			state.toggle_panel("activities")
		KEY_TAB:
			state.toggle_panel("character")
		KEY_SPACE:
			if state.mode == "combat":
				combat.cast_selected_skill(state, get_global_mouse_position())
		KEY_Q:
			if state.mode == "combat" and state.active_skills.size() > 0:
				state.selected_skill_index = wrapi(state.selected_skill_index - 1, 0, state.active_skills.size())
		KEY_R:
			if state.mode == "combat" and state.active_skills.size() > 0:
				state.selected_skill_index = wrapi(state.selected_skill_index + 1, 0, state.active_skills.size())
		KEY_F:
			if state.panel_mode == "crafting":
				RVBuildcraftSystem.handle_crafting_key(state, KEY_F)
		KEY_ESCAPE:
			if state.mode == "combat":
				_return_to_hub("Returned to hub")
			else:
				state.panel_mode = ""
		KEY_F5:
			RVSaveSystem.save(state)
			state.add_notice("Saved")


func _start_activity(activity: Dictionary) -> void:
	state.enter_combat(activity)
	hub.visible = false
	combat.visible = true
	combat.start_activity(state, activity)
	player.sync_from_state(state)


func _return_to_hub(message: String) -> void:
	combat.stop_activity()
	state.enter_hub()
	combat.visible = false
	hub.visible = true
	player.sync_from_state(state)
	state.add_notice(message)
	RVSaveSystem.save(state)


func _on_combat_finished() -> void:
	_return_to_hub("Activity complete")


func _on_player_died() -> void:
	_return_to_hub("You died")
