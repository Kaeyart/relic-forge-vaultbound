class_name RVDevToolsPanel
extends CanvasLayer

var game_root: Node = null
var current_state: RVGameState = null
var combat_ref: Node = null
var hub_ref: Node = null
var player_ref: Node = null
var hud_ref: Node = null
var panels_ref: Node = null

@onready var status_label: Label = %StatusLabel
@onready var report_label: Label = %ReportLabel

func _ready() -> void:
	visible = false
	_connect_button("CloseButton", _on_close)
	_connect_button("HealButton", _on_heal)
	_connect_button("LevelButton", _on_level)
	_connect_button("XPButton", _on_xp)
	_connect_button("MaterialsButton", _on_materials)
	_connect_button("GoldButton", _on_gold)
	_connect_button("SocketPrismButton", _on_socket_prisms)
	_connect_button("SaveButton", _on_save)
	_connect_button("MagicWeaponButton", _on_magic_weapon)
	_connect_button("RareArmorButton", _on_rare_armor)
	_connect_button("RareRingButton", _on_rare_ring)
	_connect_button("UniqueButton", _on_unique)
	_connect_button("BundleButton", _on_bundle)
	_connect_button("ClearBackpackButton", _on_clear_backpack)
	_connect_button("GemBundleButton", _on_gem_bundle)
	_connect_button("SocketUpgradeButton", _on_socket_upgrade)
	_connect_button("ResetGemsButton", _on_reset_gems)
	_connect_button("DevRoomButton", _on_dev_room)
	_connect_button("StressRoomButton", _on_stress_room)
	_connect_button("SpawnGruntButton", _on_spawn_grunt)
	_connect_button("SpawnArcherButton", _on_spawn_archer)
	_connect_button("SpawnSpitterButton", _on_spawn_spitter)
	_connect_button("SpawnBruteButton", _on_spawn_brute)
	_connect_button("ClearEnemiesButton", _on_clear_enemies)
	_connect_button("ForceRewardButton", _on_force_reward)
	_connect_button("ReturnHubButton", _on_return_hub)
	_connect_button("TelemetryStartButton", _on_telemetry_start)
	_connect_button("TelemetrySaveButton", _on_telemetry_save)
	_connect_button("LabFireballButton", _on_lab_fireball)
	_connect_button("LabVoidTrapButton", _on_lab_void_trap)
	_connect_button("LabNewPlayerButton", _on_lab_new_player)
	_connect_button("LabMatrixButton", _on_lab_matrix)
	_connect_button("LabLootAuditButton", _on_lab_loot_audit)
	_connect_button("LabSaveReportButton", _on_lab_save_report)
	_connect_button("LabClearReportButton", _on_lab_clear_report)
	_refresh_status()

func bind(root: Node, state: RVGameState, combat: Node, hub: Node, player: Node, hud: Node, panels: Node) -> void:
	game_root = root
	current_state = state
	combat_ref = combat
	hub_ref = hub
	player_ref = player
	hud_ref = hud
	panels_ref = panels
	_refresh_status()

func toggle_panel() -> void:
	visible = not visible
	_refresh_status()

func open_panel() -> void:
	visible = true
	_refresh_status()

func close_panel() -> void:
	visible = false

func _connect_button(node_name: String, callable: Callable) -> void:
	var button: Button = find_child(node_name, true, false) as Button
	if button != null and not button.pressed.is_connected(callable):
		button.pressed.connect(callable)

func _refresh_status() -> void:
	if status_label == null:
		return
	if current_state == null:
		status_label.text = "Dev Tools: no state bound"
		return
	status_label.text = "Mode: %s | Level: %s | Backpack: %s | Gems: %s/%s/%s | Telemetry: %s events" % [
		current_state.mode,
		str(current_state.level),
		str(current_state.backpack.size()),
		str(current_state.skill_gem_inventory.size()),
		str(current_state.support_gem_inventory.size()),
		str(current_state.spirit_gem_inventory.size()),
		str(RVTelemetryLogger.event_count())
	]
	if report_label != null and RVBuildcraftObservatory.latest_report_text != "":
		report_label.text = RVBuildcraftObservatory.latest_report_text.left(6000)

func _after_action() -> void:
	if current_state != null:
		if current_state.has_method("ensure_defaults"):
			current_state.call("ensure_defaults")
		if current_state.has_method("recompute_stats"):
			current_state.call("recompute_stats")
	if hud_ref != null and hud_ref.has_method("update_from_state"):
		hud_ref.call("update_from_state", current_state)
	if panels_ref != null and panels_ref.has_method("update_from_state"):
		panels_ref.call("update_from_state", current_state)
	_refresh_status()

func _on_close() -> void:
	close_panel()

func _on_heal() -> void:
	RVDevToolSystem.heal_and_refill(current_state)
	RVTelemetryLogger.log_event("DevHeal", {})
	_after_action()

func _on_level() -> void:
	RVDevToolSystem.grant_level(current_state, 1)
	RVTelemetryLogger.log_event("DevGrantLevel", {"amount": 1})
	_after_action()

func _on_xp() -> void:
	RVDevToolSystem.grant_xp(current_state, 1500.0)
	RVTelemetryLogger.log_event("DevGrantXP", {"amount": 1500})
	_after_action()

func _on_materials() -> void:
	RVDevToolSystem.grant_materials(current_state, 50)
	_after_action()

func _on_gold() -> void:
	RVDevToolSystem.grant_gold(current_state, 25000)
	_after_action()

func _on_socket_prisms() -> void:
	RVDevToolSystem.grant_socket_prisms(current_state, 5)
	_after_action()

func _on_save() -> void:
	if current_state != null:
		RVSaveSystem.save(current_state)
		current_state.add_notice("Dev: saved")
	_after_action()

func _on_magic_weapon() -> void:
	RVDevToolSystem.grant_test_item(current_state, "Magic", "weapon")
	_after_action()

func _on_rare_armor() -> void:
	RVDevToolSystem.grant_test_item(current_state, "Rare", "chest")
	_after_action()

func _on_rare_ring() -> void:
	RVDevToolSystem.grant_test_item(current_state, "Rare", "ring")
	_after_action()

func _on_unique() -> void:
	RVDevToolSystem.grant_test_item(current_state, "Unique", "relic")
	_after_action()

func _on_bundle() -> void:
	RVDevToolSystem.grant_item_bundle(current_state)
	_after_action()

func _on_clear_backpack() -> void:
	RVDevToolSystem.clear_backpack(current_state)
	_after_action()

func _on_gem_bundle() -> void:
	RVDevToolSystem.grant_all_gems(current_state)
	_after_action()

func _on_socket_upgrade() -> void:
	RVDevToolSystem.improve_all_socket_caps(current_state)
	_after_action()

func _on_reset_gems() -> void:
	RVDevToolSystem.reset_gem_setup(current_state)
	_after_action()

func _on_dev_room() -> void:
	_start_dev_activity(RVDevToolSystem.make_dev_activity())

func _on_stress_room() -> void:
	_start_dev_activity(RVDevToolSystem.make_stress_activity())

func _start_dev_activity(activity: Dictionary) -> void:
	close_panel()
	RVTelemetryLogger.log_event("DevActivityStarted", activity)
	if game_root != null and game_root.has_method("dev_start_activity"):
		game_root.call("dev_start_activity", activity)
	elif game_root != null and game_root.has_method("_start_activity"):
		game_root.call("_start_activity", activity)
	_after_action()

func _on_spawn_grunt() -> void:
	_dev_spawn_enemy("Grunt")

func _on_spawn_archer() -> void:
	_dev_spawn_enemy("Archer")

func _on_spawn_spitter() -> void:
	_dev_spawn_enemy("Spitter")

func _on_spawn_brute() -> void:
	_dev_spawn_enemy("Brute")

func _dev_spawn_enemy(enemy_type: String) -> void:
	if combat_ref != null and combat_ref.has_method("dev_spawn_enemy"):
		combat_ref.call("dev_spawn_enemy", enemy_type, 1)
	if current_state != null:
		current_state.add_notice("Dev: spawned " + enemy_type)
	RVTelemetryLogger.log_event("DevEnemySpawned", {"enemy_type": enemy_type})
	_after_action()

func _on_clear_enemies() -> void:
	if combat_ref != null and combat_ref.has_method("dev_clear_enemies"):
		combat_ref.call("dev_clear_enemies")
	RVTelemetryLogger.log_event("DevClearEnemies", {})
	_after_action()

func _on_force_reward() -> void:
	if combat_ref != null and combat_ref.has_method("dev_force_reward"):
		combat_ref.call("dev_force_reward")
	RVTelemetryLogger.log_event("DevForceReward", {})
	_after_action()

func _on_return_hub() -> void:
	close_panel()
	if game_root != null and game_root.has_method("dev_return_to_hub"):
		game_root.call("dev_return_to_hub", "Dev: returned to hub")
	elif current_state != null:
		current_state.enter_hub()
	RVTelemetryLogger.log_event("DevReturnHub", {})
	_after_action()

func _on_telemetry_start() -> void:
	RVTelemetryLogger.start_session("manual_playtest")
	if current_state != null:
		current_state.add_notice("Telemetry started")
	_after_action()

func _on_telemetry_save() -> void:
	var path: String = RVBuildcraftObservatory.save_telemetry()
	if current_state != null:
		current_state.add_notice("Telemetry saved")
	if report_label != null:
		report_label.text = "Telemetry saved:\n" + path + "\n\n" + RVTelemetryLogger.summary_text()
	_after_action()

func _on_lab_fireball() -> void:
	_run_lab("fireball_ignite", "fireball_30_room_journey", 250)

func _on_lab_void_trap() -> void:
	_run_lab("void_trapper", "void_trapper_30_room_journey", 250)

func _on_lab_new_player() -> void:
	_run_lab("new_player", "new_player_first_12_rooms", 250)

func _on_lab_matrix() -> void:
	if current_state == null: return
	RVBuildcraftObservatory.run_quick_matrix(current_state, 150)
	_refresh_status()

func _on_lab_loot_audit() -> void:
	_run_lab("wiki_goblin", "loot_audit_10000", 250)

func _on_lab_save_report() -> void:
	var result: Dictionary = RVBuildcraftObservatory.save_latest()
	if report_label != null:
		report_label.text = "Saved Buildcraft Observatory report:\n" + JSON.stringify(result, "\t") + "\n\n" + RVBuildcraftObservatory.latest_report_text.left(5000)
	if current_state != null:
		current_state.add_notice("Lab report saved")
	_after_action()

func _on_lab_clear_report() -> void:
	RVBuildcraftObservatory.clear_latest()
	if report_label != null:
		report_label.text = RVBuildcraftObservatory.latest_report_text
	_after_action()

func _run_lab(profile_id: String, scenario_id: String, runs: int) -> void:
	if current_state == null:
		return
	RVBuildcraftObservatory.run_scenario(current_state, profile_id, scenario_id, runs, 0)
	_refresh_status()
