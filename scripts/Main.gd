extends Node2D

var state: RVGameState = RVGameState.new()
var autosave_timer: float = 0.0

@onready var hub_root: RVHubRoot = $WorldRoot/HubRoot
@onready var combat_arena: RVCombatArena = $WorldRoot/CombatArena
@onready var player: RVPlayerController = $Player
@onready var hud: RVGameHUD = $GameHUD

func _ready() -> void:
	state.init()
	RVSaveSystem.load_into(state)
	state.init()
	hub_root.setup(state, self)
	combat_arena.setup(state, self)
	player.setup(state)
	enter_hub()
	state.add_notice("Scene-authored game loaded")
	set_process(true)
	set_process_unhandled_input(true)

func _process(delta: float) -> void:
	_update_cooldowns(delta)
	state.invuln = max(0.0, state.invuln - delta)
	state.player_mana = min(state.max_mana, state.player_mana + 12.0 * delta)
	if state.mode == "hub":
		hub_root.update_focus(player.global_position)
	else:
		combat_arena.update_arena(delta)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_cast_selected()
		if state.player_hp <= 0.0:
			state.deaths += 1
			state.add_notice("You died. Returned to Hub.")
			enter_hub()
	if state.notice_time > 0.0:
		state.notice_time = max(0.0, state.notice_time - delta)
	autosave_timer += delta
	if autosave_timer >= 10.0:
		autosave_timer = 0.0
		RVSaveSystem.save(state)
	hud.update_from_state(state)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		RVSaveSystem.save(state)

func _unhandled_input(event) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed and not key.echo:
			_handle_key(key.keycode)
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and state.mode == "combat":
			_cast_selected()

func _handle_key(keycode: int) -> void:
	if keycode >= KEY_1 and keycode <= KEY_6:
		var index: int = keycode - KEY_1
		if state.mode == "hub":
			_toggle_skill_by_index(index)
		elif index < state.active_skills.size():
			state.selected_skill = index
		return
	if keycode == KEY_Q and state.mode == "combat":
		_cycle_skill(-1)
		return
	if keycode == KEY_E:
		if state.mode == "hub":
			hub_root.interact_primary()
		else:
			_cycle_skill(1)
		return
	if keycode == KEY_X and state.mode == "hub":
		hub_root.interact_secondary()
		return
	if keycode == KEY_SPACE and state.mode == "combat":
		_cast_selected()
		return
	if keycode == KEY_ESCAPE:
		if state.panel_mode != "":
			state.panel_mode = ""
		elif state.mode == "combat":
			enter_hub()
			state.add_notice("Returned to Hub")
		return
	if keycode == KEY_P:
		state.panel_mode = "" if state.panel_mode == "passive_tree" else "passive_tree"
		return
	if keycode == KEY_K:
		state.panel_mode = "" if state.panel_mode == "skill_gems" else "skill_gems"
		return
	if keycode == KEY_C:
		state.panel_mode = "" if state.panel_mode == "crafting" else "crafting"
		return
	if keycode == KEY_F5:
		RVSaveSystem.save(state)
		state.add_notice("Saved")
		return

func start_activity(activity: Dictionary) -> void:
	state.enter_combat(activity)
	hub_root.visible = false
	combat_arena.visible = true
	player.global_position = combat_arena.get_spawn_position()
	state.player_pos = player.global_position
	combat_arena.start_activity(activity)

func enter_hub() -> void:
	state.enter_hub()
	combat_arena.clear_room()
	hub_root.visible = true
	combat_arena.visible = false
	player.global_position = hub_root.get_spawn_position()
	state.player_pos = player.global_position
	RVSaveSystem.save(state)

func _cast_selected() -> void:
	if state.active_skills.size() == 0:
		return
	state.selected_skill = clamp(state.selected_skill, 0, state.active_skills.size() - 1)
	combat_arena.cast_skill(str(state.active_skills[state.selected_skill]), get_global_mouse_position())

func _cycle_skill(direction: int) -> void:
	if state.active_skills.size() == 0:
		return
	state.selected_skill = wrapi(state.selected_skill + direction, 0, state.active_skills.size())
	state.add_notice("Selected: " + str(state.active_skills[state.selected_skill]))

func _toggle_skill_by_index(index: int) -> void:
	if index < 0 or index >= state.available_skills.size():
		return
	var skill: String = str(state.available_skills[index])
	if state.active_skills.has(skill):
		state.active_skills.erase(skill)
		state.add_notice(skill + " removed")
	else:
		if state.active_skills.size() >= 4:
			state.add_notice("Loadout limit: 4")
			return
		state.active_skills.append(skill)
		state.add_notice(skill + " added")
	if state.active_skills.size() == 0:
		state.active_skills.append("Fireball")
	state.selected_skill = clamp(state.selected_skill, 0, max(0, state.active_skills.size() - 1))

func _update_cooldowns(delta: float) -> void:
	for skill in state.skill_cooldowns.keys():
		state.skill_cooldowns[skill] = max(0.0, float(state.skill_cooldowns[skill]) - delta)
