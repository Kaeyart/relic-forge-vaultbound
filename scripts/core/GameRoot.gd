class_name RVGameRoot
extends Node2D
const FlaskSystemScript := preload("res://scripts/systems/FlaskSystem.gd")

@onready var hub: RVHubRoot = %Hub
@onready var combat: RVCombatArena = %Combat
@onready var player: RVPlayerActor = %Player
@onready var hud: RVGameHUD = %GameHUD
@onready var panels: RVUIPanelRoot = %UIPanelRoot

var state: RVGameState = RVGameState.new()
var autosave_timer: float = 0.0
var dev_tools_panel: Node = null
var world_camera: Camera2D = null
var loot_pickup_pet: Node2D = null
var loot_filter_panel: Node = null
var flask_hud: Node = null
var map_return_portal: Node2D = null

func _ready() -> void:
	state.init_new()
	RVSaveSystem.load_into(state)
	state.ensure_defaults()
	FlaskSystemScript.ensure_defaults(state)
	RVMapSystem.ensure_defaults(state)
	state.enter_hub()
	combat.visible = false
	hub.visible = true
	combat.combat_finished.connect(_on_combat_finished)
	combat.player_died.connect(_on_player_died)
	player.sync_from_state(state)
	set_process(true)
	set_process_unhandled_input(true)
	_install_world_camera()
	_install_dev_tools()
	_install_loot_pickup_pet()
	_install_loot_filter_panel()
	_install_flask_hud()
	_install_map_return_portal()

func _process(delta: float) -> void:
	if not state.pending_start_activity.is_empty():
		var pending_activity: Dictionary = state.pending_start_activity.duplicate(true)
		state.pending_start_activity.clear()
		state.panel_mode = ""
		_start_activity(pending_activity)
		return

	_update_player(delta)
	RVSkillSystem.update(state, delta)

	if state.mode == "hub":
		hub.update_focus(state)
		if _has_active_map_portal() and state.prompt_text == "":
			state.prompt_text = "E - Re-enter Map Portal (" + str(state.active_map_portal_entries) + " left)"
	else:
		combat.update_combat(state, player, delta)
		if combat.has_method("enforce_layout_entity_collisions"):
			combat.call("enforce_layout_entity_collisions")
		if combat.has_method("enforce_layout_projectile_collisions"):
			combat.call("enforce_layout_projectile_collisions", delta)
		RVLootPickupAssistSystem.update(state, combat, player, delta)
		if combat != null and is_instance_valid(combat) and not combat.is_queued_for_deletion():
			RVLootFilterSystem.update_ground_loot(state, combat)
		if loot_pickup_pet != null and is_instance_valid(loot_pickup_pet) and not loot_pickup_pet.is_queued_for_deletion() and loot_pickup_pet.has_method("sync_from_state"):
			loot_pickup_pet.call("sync_from_state", state, player)

	if state.notice_time > 0.0:
		state.notice_time = max(0.0, state.notice_time - delta)

	autosave_timer += delta
	if autosave_timer >= 10.0:
		autosave_timer = 0.0
		RVSaveSystem.save(state)

	hud.update_from_state(state)
	if flask_hud != null and is_instance_valid(flask_hud) and flask_hud.has_method("update_from_state"):
		flask_hud.call("update_from_state", state)
	panels.update_from_state(state)
	if loot_filter_panel != null and loot_filter_panel.has_method("update_from_state"):
		loot_filter_panel.call("update_from_state", state)
	_update_world_camera(delta)
	_sync_map_return_portal()
	_consume_pending_map_activity()

func _update_player(delta: float) -> void:
	if state.panel_mode != "":
		player.sync_from_state(state)
		return
	var move: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): move.y -= 1.0
	if Input.is_key_pressed(KEY_S): move.y += 1.0
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0
	if move.length() > 0.01:
		move = move.normalized()
	var _rf_prev_player_pos: Vector2 = state.player_pos
	state.player_pos += move * state.player_speed * delta
	if state.mode == "combat" and combat != null and combat.has_method("constrain_player_movement"):
		state.player_pos = combat.call("constrain_player_movement", _rf_prev_player_pos, state.player_pos, state.player_radius)
	elif state.mode == "combat" and combat != null and combat.has_method("constrain_player_position"):
		state.player_pos = combat.constrain_player_position(state.player_pos)
	else:
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
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT and state.mode == "combat" and state.panel_mode == "":
			if combat != null and is_instance_valid(combat) and not combat.is_queued_for_deletion():
				if combat != null and is_instance_valid(combat) and not combat.is_queued_for_deletion():
					combat.cast_selected_skill(state, get_global_mouse_position())

func _handle_key(keycode: int) -> void:
	if keycode == KEY_F10:
		_toggle_dev_tools()
		return
	if state.panel_mode == "":
		if keycode == KEY_Z and state.mode == "combat":
			if FlaskSystemScript.use_health(state):
				player.sync_from_state(state)
			return
		if keycode == KEY_X and state.mode == "combat":
			if FlaskSystemScript.use_mana(state):
				player.sync_from_state(state)
			return
		if keycode == KEY_T:
			if state.mode == "combat":
				_rf_081a_portal_to_hub()
			elif state.mode == "hub":
				_rf_081a_reenter_active_map_portal()
			return
	if state.panel_mode != "":
		if keycode == KEY_ESCAPE:
			state.panel_mode = ""
			return
		if RVMapSystem.handle_panel_key(state, keycode):
			RVSaveSystem.save(state)
			return
		if RVSkillGemSystem.handle_panel_key(state, keycode):
			RVSaveSystem.save(state)
			return
		if RVInventorySystem.handle_panel_key(state, keycode):
			RVSaveSystem.save(state)
			return
		if RVBuildcraftSystem.handle_key(state, keycode):
			RVSaveSystem.save(state)
			return
	if keycode >= KEY_1 and keycode <= KEY_6:
		var index: int = keycode - KEY_1
		if state.mode == "hub":
			if index < state.skill_gem_inventory.size():
				state.skill_gem_cursor = index
				RVSkillGemSystem.toggle_selected_active_gem_equipped(state)
		else:
			if index < state.active_skills.size():
				state.selected_skill_index = index
		return
	match keycode:
		KEY_E:
			if state.mode == "hub":
				if _try_enter_active_map_portal():
					return
				var activity: Dictionary = hub.interact_primary(state)
				if not activity.is_empty():
					_start_activity(activity)
				RVSaveSystem.save(state)
			elif state.mode == "combat":
				combat.interact(state)
				RVSaveSystem.save(state)
		KEY_X:
			if state.mode == "hub" and hub.has_method("interact_secondary"):
				hub.call("interact_secondary", state)
				RVSaveSystem.save(state)
		KEY_I: state.toggle_panel("inventory")
		KEY_C: state.toggle_panel("crafting")
		KEY_P: state.toggle_panel("passive_atlas")
		KEY_K: state.toggle_panel("skill_gems")
		KEY_B: state.toggle_panel("stash")
		KEY_M: state.toggle_panel("activities")
		KEY_N: state.toggle_panel("map_device")
		KEY_L: state.toggle_panel("loot_filter")
		KEY_TAB: state.toggle_panel("character")
		KEY_SPACE:
			if state.mode == "combat" and combat != null and is_instance_valid(combat) and not combat.is_queued_for_deletion(): combat.cast_selected_skill(state, get_global_mouse_position())
		KEY_Q:
			if state.mode == "combat" and state.active_skills.size() > 0:
				state.selected_skill_index = wrapi(state.selected_skill_index - 1, 0, state.active_skills.size())
		KEY_R:
			if state.mode == "combat" and state.active_skills.size() > 0:
				state.selected_skill_index = wrapi(state.selected_skill_index + 1, 0, state.active_skills.size())
		KEY_F:
			if state.panel_mode == "crafting": RVBuildcraftSystem.handle_crafting_key(state, KEY_F)
		KEY_ESCAPE:
			if state.mode == "combat": _return_to_hub("Returned to hub")
			else: state.panel_mode = ""
		KEY_F5:
			RVSaveSystem.save(state)
			state.add_notice("Saved")

func _consume_pending_map_activity() -> void:
	if state.pending_start_activity.is_empty():
		return

	var activity: Dictionary = state.pending_start_activity.duplicate(true)
	state.pending_start_activity.clear()
	state.panel_mode = ""
	_start_activity(activity)
	
func _start_activity(activity: Dictionary) -> void:
	var start_activity: Dictionary = activity.duplicate(true)
	if str(start_activity.get("kind", "")) == "map":
		if bool(start_activity.get("resume_active_portal", false)):
			if state.active_map_portal_entries <= 0:
				state.add_notice("No map portal entries remain")
				_rf_081a_clear_active_map_portal()
				return
			state.active_map_portal_entries -= 1
			state.active_map_portals_remaining = state.active_map_portal_entries
			if not state.active_map_instance.is_empty():
				start_activity["resume_snapshot"] = state.active_map_instance.duplicate(true)
			state.add_notice("Re-entered map - portals left: " + str(state.active_map_portal_entries))
		else:
			state.active_map_portal_activity = start_activity.duplicate(true)
			state.active_map_instance.clear()
			state.active_map_portal_max_entries = 6
			state.active_map_portal_entries = 5
			state.active_map_portals_remaining = 5
			state.add_notice("Map opened - portals left: 5")
	state.enter_combat(start_activity)
	hub.visible = false
	combat.visible = true
	combat.start_activity(state, start_activity)
	player.sync_from_state(state)

func _return_to_hub(message: String) -> void:
	if combat != null and is_instance_valid(combat):
		combat.stop_activity()
	state.enter_hub()
	RVMapSystem.ensure_defaults(state)
	FlaskSystemScript.refill_all(state)
	combat.visible = false
	hub.visible = true
	player.sync_from_state(state)
	state.add_notice(message)
	RVSaveSystem.save(state)

func _on_combat_finished() -> void:
	if str(state.current_activity.get("kind", "")) == "map":
		_rf_081a_clear_active_map_portal()
		_return_to_hub("Map complete")
		return
	_return_to_hub("Activity complete")

func _on_player_died() -> void:
	if str(state.current_activity.get("kind", "")) == "map":
		if state.active_map_portal_entries > 0:
			_rf_081a_capture_active_map_instance()
			_return_to_hub("You died - map portal remains (" + str(state.active_map_portal_entries) + " left)")
		else:
			_rf_081a_clear_active_map_portal()
			_return_to_hub("You died - map failed")
		return
	_return_to_hub("You died")

func _install_dev_tools() -> void:
	if dev_tools_panel != null:
		return
	var scene_path: String = "res://scenes/ui/dev/DevToolsPanel.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("Dev tools scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	dev_tools_panel = packed.instantiate()
	add_child(dev_tools_panel)
	if dev_tools_panel.has_method("bind"):
		dev_tools_panel.call("bind", self, state, combat, hub, player, hud, panels)


func _install_loot_pickup_pet() -> void:
	if loot_pickup_pet != null:
		return
	var scene_path: String = "res://scenes/prefabs/player/LootPickupPet.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("Loot pickup pet scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	loot_pickup_pet = packed.instantiate() as Node2D
	add_child(loot_pickup_pet)
	if loot_pickup_pet != null and is_instance_valid(loot_pickup_pet) and not loot_pickup_pet.is_queued_for_deletion() and loot_pickup_pet.has_method("sync_from_state"):
		loot_pickup_pet.call("sync_from_state", state, player)


func _install_loot_filter_panel() -> void:
	if loot_filter_panel != null and is_instance_valid(loot_filter_panel):
		return
	var scene_path: String = "res://scenes/ui/panels/LootFilterPanel.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("Loot filter panel scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	loot_filter_panel = packed.instantiate()
	add_child(loot_filter_panel)
	if loot_filter_panel.has_method("update_from_state"):
		loot_filter_panel.call("update_from_state", state)


func _install_flask_hud() -> void:
	if flask_hud != null and is_instance_valid(flask_hud):
		return
	var scene_path: String = "res://scenes/ui/hud/FlaskHUD.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("Flask HUD scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	flask_hud = packed.instantiate()
	add_child(flask_hud)
	if flask_hud.has_method("update_from_state"):
		flask_hud.call("update_from_state", state)

func _toggle_dev_tools() -> void:
	if dev_tools_panel == null:
		_install_dev_tools()
	_install_loot_pickup_pet()
	if dev_tools_panel != null and dev_tools_panel.has_method("toggle_panel"):
		dev_tools_panel.call("toggle_panel")

func dev_start_activity(activity: Dictionary) -> void:
	_start_activity(activity)

func dev_return_to_hub(message: String = "Dev: returned to hub") -> void:
	_return_to_hub(message)


func _current_combat_is_map() -> bool:
	if combat != null and is_instance_valid(combat):
		var combat_activity: Variant = combat.get("activity")
		if typeof(combat_activity) == TYPE_DICTIONARY and str(Dictionary(combat_activity).get("kind", "")) == "map":
			return true
	return str(state.current_activity.get("kind", "")) == "map"

func _has_active_map_portal() -> bool:
	return typeof(state.active_map_portal_activity) == TYPE_DICTIONARY and not state.active_map_portal_activity.is_empty() and int(state.active_map_portal_entries) > 0

func _open_new_map_portal(activity: Dictionary) -> void:
	var stored: Dictionary = activity.duplicate(true)
	stored.erase("_rv_reentering_portal")
	var max_entries: int = max(1, int(stored.get("map_portal_max_entries", 6)))
	state.active_map_portal_max_entries = max_entries
	state.active_map_portal_entries = max(0, max_entries - 1)
	state.active_map_portal_activity = stored
	activity["map_portal_entries_remaining"] = state.active_map_portal_entries
	state.add_notice("Map opened - " + str(state.active_map_portal_entries) + " portals remain")

func _try_reenter_active_map_portal() -> bool:
	if not _has_active_map_portal():
		return false
	state.active_map_portal_entries = max(0, int(state.active_map_portal_entries) - 1)
	var activity: Dictionary = state.active_map_portal_activity.duplicate(true)
	activity["_rv_reentering_portal"] = true
	activity["map_portal_entries_remaining"] = state.active_map_portal_entries
	_start_activity(activity)
	state.add_notice("Entered map - " + str(state.active_map_portal_entries) + " portals remain")
	if state.active_map_portal_entries <= 0:
		# Keep the current combat instance alive; clear the stored re-entry only if the player dies again.
		state.active_map_portal_activity = activity.duplicate(true)
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		RVSaveSystem.save(state)


func _install_world_camera() -> void:
	if world_camera != null and is_instance_valid(world_camera):
		return
	world_camera = Camera2D.new()
	world_camera.name = "WorldCombatCamera"
	world_camera.enabled = false
	world_camera.position_smoothing_enabled = true
	world_camera.position_smoothing_speed = 9.0
	world_camera.zoom = Vector2.ONE
	add_child(world_camera)

func _update_world_camera(delta: float) -> void:
	if world_camera == null or not is_instance_valid(world_camera):
		_install_world_camera()
	if world_camera == null:
		return
	if state.mode != "combat":
		world_camera.enabled = false
		return
	world_camera.enabled = true
	world_camera.make_current()
	var target: Vector2 = state.player_pos
	if world_camera.global_position == Vector2.ZERO:
		world_camera.global_position = target
	else:
		world_camera.global_position = world_camera.global_position.lerp(target, clampf(delta * 10.0, 0.0, 1.0))
	if combat != null and combat.has_method("get_combat_bounds"):
		var bounds_value: Variant = combat.call("get_combat_bounds")
		if typeof(bounds_value) == TYPE_RECT2:
			var bounds: Rect2 = bounds_value
			world_camera.limit_left = int(floor(bounds.position.x - 96.0))
			world_camera.limit_top = int(floor(bounds.position.y - 96.0))
			world_camera.limit_right = int(ceil(bounds.position.x + bounds.size.x + 96.0))
			world_camera.limit_bottom = int(ceil(bounds.position.y + bounds.size.y + 96.0))


func _install_map_return_portal() -> void:
	if map_return_portal != null and is_instance_valid(map_return_portal):
		return
	var scene_path: String = "res://scenes/prefabs/hub/MapReturnPortal.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("Map return portal scene missing: " + scene_path)
		return
	var packed: PackedScene = load(scene_path)
	map_return_portal = packed.instantiate() as Node2D
	add_child(map_return_portal)
	map_return_portal.global_position = state.active_map_portal_pos
	map_return_portal.visible = false

func _sync_map_return_portal() -> void:
	if map_return_portal == null or not is_instance_valid(map_return_portal):
		_install_map_return_portal()
	if map_return_portal == null:
		return
	var enabled: bool = state.mode == "hub" and state.active_map_portals_remaining > 0 and not state.active_map_portal_activity.is_empty()
	map_return_portal.global_position = state.active_map_portal_pos
	if map_return_portal.has_method("set_portal_state"):
		map_return_portal.call("set_portal_state", enabled, state.active_map_portals_remaining)
	else:
		map_return_portal.visible = enabled
	if enabled and state.player_pos.distance_to(state.active_map_portal_pos) <= 96.0:
		state.prompt_text = "E - Re-enter Map (" + str(state.active_map_portals_remaining) + " portals)"

func _try_enter_active_map_portal() -> bool:
	if state.active_map_portals_remaining <= 0 or state.active_map_portal_activity.is_empty():
		return false
	if state.player_pos.distance_to(state.active_map_portal_pos) > 110.0:
		return false
	var activity: Dictionary = state.active_map_portal_activity.duplicate(true)
	state.add_notice("Re-entering map - " + str(max(0, state.active_map_portals_remaining - 1)) + " portals remain after entry")
	_start_activity(activity)
	return true

func _prepare_map_portals_for_activity(activity: Dictionary) -> void:
	if not _is_map_activity(activity):
		return
	var incoming_uid: String = _activity_map_uid(activity)
	var existing_uid: String = _activity_map_uid(state.active_map_portal_activity)
	if incoming_uid == "" or existing_uid == "" or incoming_uid != existing_uid or state.active_map_portals_remaining <= 0:
		state.active_map_portal_activity = activity.duplicate(true)
		state.active_map_portals_remaining = 6
	# Every entry consumes one portal, including the first entry.
	state.active_map_portals_remaining = max(0, state.active_map_portals_remaining - 1)
	state.active_map_portal_activity = activity.duplicate(true)

func _return_to_hub_after_map_death() -> void:
	combat.stop_activity()
	state.enter_hub()
	RVMapSystem.ensure_defaults(state)
	combat.visible = false
	hub.visible = true
	player.sync_from_state(state)
	if state.active_map_portals_remaining > 0 and not state.active_map_portal_activity.is_empty():
		state.add_notice("You died - map portal remains (" + str(state.active_map_portals_remaining) + ")")
	else:
		_clear_active_map_portal()
		state.add_notice("Map failed - no portals remain")
	RVSaveSystem.save(state)

func _is_map_activity(activity: Dictionary) -> bool:
	return str(activity.get("kind", "")) == "map"

func _activity_map_uid(activity: Dictionary) -> String:
	if activity.is_empty():
		return ""
	var map_value: Variant = activity.get("map", {})
	if typeof(map_value) != TYPE_DICTIONARY:
		return str(activity.get("uid", activity.get("id", "")))
	var map_item: Dictionary = Dictionary(map_value)
	return str(map_item.get("uid", map_item.get("completion_key", map_item.get("id", ""))))

func _clear_active_map_portal() -> void:
	if state != null:
		state.active_map_portal_activity.clear()
		state.active_map_portals_remaining = 0
	var portal_value: Variant = get("map_return_portal")
	if portal_value != null and is_instance_valid(portal_value):
		var portal: Node = portal_value as Node
		if portal != null:
			if portal.has_method("set_portal_state"):
				portal.call("set_portal_state", false, 0)
			elif portal is CanvasItem:
				(portal as CanvasItem).visible = false

# -----------------------------------------------------------------------------
# Patch 081C: missing map portal helper repair.
# 081A wired these calls into input/death/completion flow, but some installs lost
# the helper bodies. Keep this block local and conservative.
# -----------------------------------------------------------------------------

func _rf_081a_portal_entries() -> int:
	var entries: int = int(state.get("active_map_portal_entries"))
	var remaining_alias: int = int(state.get("active_map_portals_remaining"))
	return max(entries, remaining_alias)

func _rf_081a_set_portal_entries(value: int) -> void:
	var clamped: int = max(0, value)
	state.set("active_map_portal_entries", clamped)
	state.set("active_map_portals_remaining", clamped)

func _rf_081a_active_portal_activity() -> Dictionary:
	var value: Variant = state.get("active_map_portal_activity")
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value)
	return {}

func _rf_081a_capture_active_map_instance() -> void:
	if state == null:
		return
	if state.mode != "combat":
		return
	var base_activity: Dictionary = {}
	var current_value: Variant = state.get("current_activity")
	if typeof(current_value) == TYPE_DICTIONARY:
		base_activity = Dictionary(current_value).duplicate(true)
	if base_activity.is_empty() and combat != null and is_instance_valid(combat):
		var combat_activity_value: Variant = combat.get("activity")
		if typeof(combat_activity_value) == TYPE_DICTIONARY:
			base_activity = Dictionary(combat_activity_value).duplicate(true)
	if str(base_activity.get("kind", "")) != "map":
		return
	var snapshot: Dictionary = {}
	if combat != null and is_instance_valid(combat) and not combat.is_queued_for_deletion() and combat.has_method("capture_map_instance_snapshot"):
		var snapshot_value: Variant = combat.call("capture_map_instance_snapshot")
		if typeof(snapshot_value) == TYPE_DICTIONARY:
			snapshot = Dictionary(snapshot_value).duplicate(true)
	if not snapshot.is_empty():
		base_activity["snapshot"] = snapshot
	state.set("active_map_portal_activity", base_activity)
	_rf_081a_set_portal_entries(_rf_081a_portal_entries())
	_rf_081a_update_active_map_portal_visual()

func _rf_081a_portal_to_hub() -> void:
	if state == null:
		return
	if state.mode != "combat":
		state.add_notice("Portal can only be opened inside a map")
		return
	_rf_081a_capture_active_map_instance()
	if _rf_081a_active_portal_activity().is_empty():
		state.add_notice("No active map portal to preserve")
		return
	if combat != null and is_instance_valid(combat) and not combat.is_queued_for_deletion():
		combat.stop_activity()
	state.enter_hub()
	RVMapSystem.ensure_defaults(state)
	if combat != null and is_instance_valid(combat):
		combat.visible = false
	if hub != null and is_instance_valid(hub):
		hub.visible = true
	player.sync_from_state(state)
	_rf_081a_update_active_map_portal_visual()
	state.add_notice("Returned to hub - map portal preserved (" + str(_rf_081a_portal_entries()) + " entries)")
	RVSaveSystem.save(state)

func _rf_081a_reenter_active_map_portal() -> void:
	if state == null:
		return
	var activity: Dictionary = _rf_081a_active_portal_activity()
	if activity.is_empty():
		state.add_notice("No active map portal")
		return
	var entries: int = _rf_081a_portal_entries()
	if entries <= 0:
		_rf_081a_clear_active_map_portal()
		state.add_notice("No map portal entries remaining")
		return
	entries -= 1
	_rf_081a_set_portal_entries(entries)
	var snapshot: Dictionary = {}
	if typeof(activity.get("snapshot", {})) == TYPE_DICTIONARY:
		snapshot = Dictionary(activity.get("snapshot", {})).duplicate(true)
	var launch_activity: Dictionary = activity.duplicate(true)
	launch_activity.erase("snapshot")
	state.enter_combat(launch_activity)
	if hub != null and is_instance_valid(hub):
		hub.visible = false
	if combat != null and is_instance_valid(combat):
		combat.visible = true
		if not snapshot.is_empty() and combat.has_method("restore_map_instance_snapshot"):
			combat.call("restore_map_instance_snapshot", state, snapshot)
		else:
			combat.start_activity(state, launch_activity)
	player.sync_from_state(state)
	_rf_081a_update_active_map_portal_visual()
	state.add_notice("Entered map portal - " + str(entries) + " entries remain")
	RVSaveSystem.save(state)

func _rf_081a_clear_active_map_portal() -> void:
	if state == null:
		return
	state.set("active_map_portal_activity", {})
	_rf_081a_set_portal_entries(0)
	_rf_081a_update_active_map_portal_visual()

func _rf_081a_update_active_map_portal_visual() -> void:
	var portal_value: Variant = get("map_return_portal")
	var enabled: bool = not _rf_081a_active_portal_activity().is_empty() and _rf_081a_portal_entries() > 0
	if portal_value != null and is_instance_valid(portal_value):
		var portal_node: Node = portal_value as Node
		if portal_node != null and portal_node.has_method("set_portal_state"):
			portal_node.call("set_portal_state", enabled, _rf_081a_portal_entries())
		elif portal_node is CanvasItem:
			(portal_node as CanvasItem).visible = enabled
