class_name RVCombatArena
extends Node2D

const CombatGeometrySystemScript := preload("res://scripts/systems/CombatGeometrySystem.gd")

const RVLootDropActorScript := preload("res://scripts/combat/LootDropActor.gd")
const RVFloatingCombatTextSystemScript := preload("res://scripts/systems/FloatingCombatTextSystem.gd")
const RVLootDropSystemScript := preload("res://scripts/systems/LootDropSystem.gd")
const SpellVFXSystemScript := preload("res://scripts/visuals/SpellVFXSystem.gd")
const CombatFeedbackSystemScript := preload("res://scripts/systems/CombatFeedbackSystem.gd")
const MapPropVisualSystemScript := preload("res://scripts/visuals/MapPropVisualSystem.gd")

const MapLayoutSystemScript := preload("res://scripts/systems/MapLayoutSystem.gd")
const MapEncounterDirectorScript := preload("res://scripts/systems/MapEncounterDirector.gd")
const CombatJuiceSystemScript := preload("res://scripts/systems/CombatJuiceSystem.gd")
const CombatStatusComboSystemScript := preload("res://scripts/systems/CombatStatusComboSystem.gd")
const CombatPackAISystemScript := preload("res://scripts/systems/CombatPackAISystem.gd")
const BossPhaseDirectorScript := preload("res://scripts/systems/BossPhaseDirector.gd")

signal combat_finished
signal player_died

@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene

@onready var spawn_points_root: Node2D = $SpawnPoints
@onready var enemies_root: Node2D = $Enemies
@onready var projectiles_root: Node2D = $Projectiles
@onready var obstacles_root: Node2D = $Obstacles
@onready var reward_chest: Node2D = $RewardChest
@onready var exit_portal: Node2D = $ExitPortal

var active: bool = false
var activity: Dictionary = {}
var state_ref: RVGameState = null
var room_clear: bool = false
var reward_claimed: bool = false
var map_layout: Dictionary = {}
var encounter_plan: Dictionary = {}
var map_visual_root: Node2D = null
var vfx_root: Node2D = null
var runtime_map_camera: Camera2D = null
var enemy_zones: Array[Dictionary] = []
var map_pack_total: int = 0
var map_pack_cleared: int = 0
var map_boss_alive: bool = false


func _rf_feedback_root() -> Node2D:
	if has_method("_ensure_vfx_root"):
		var value: Variant = call("_ensure_vfx_root")
		if value is Node2D:
			return value as Node2D
	return self

func _rf_enemy_last_tags(enemy: Node) -> Array:
	if enemy == null:
		return []
	var value: Variant = enemy.get("last_damage_tags")
	if typeof(value) == TYPE_ARRAY:
		return Array(value)
	return []

func start_activity(state: RVGameState, new_activity: Dictionary) -> void:
	state_ref = state
	activity = new_activity.duplicate(true)
	active = true
	_clear_children(enemies_root)
	_clear_children(projectiles_root)
	_clear_runtime_vfx()
	enemy_zones.clear()
	state.room_index = max(1, state.room_index)
	spawn_room(state)

func stop_activity() -> void:
	if runtime_map_camera != null and is_instance_valid(runtime_map_camera):
		runtime_map_camera.clear_current()
		runtime_map_camera.enabled = false
	active = false
	_clear_children(enemies_root)
	_clear_children(projectiles_root)
	enemy_zones.clear()
	_set_reward_visible(false)
	_set_exit_visible(false)
	_clear_map_layout_art()
	_set_static_room_visible(true)
	_set_authored_obstacles_visible(true)
	map_layout.clear()
	encounter_plan.clear()
	map_pack_total = 0
	map_pack_cleared = 0
	map_boss_alive = false
	if state_ref != null:
		state_ref.room_objective = ""
		state_ref.prompt_text = ""

func spawn_room(state: RVGameState) -> void:
	_clear_children(enemies_root)
	_clear_children(projectiles_root)
	enemy_zones.clear()
	room_clear = false
	reward_claimed = false
	_set_reward_visible(false)
	_set_exit_visible(false)
	state.room_reward_ready = false
	state.room_reward_claimed = false
	state.room_exit_ready = false
	state.room_objective = "Defeat all enemies."
	if str(activity.get("kind", "")) == "map":
		_spawn_map_room(state)
		return
	_spawn_standard_room(state)

func _spawn_standard_room(state: RVGameState) -> void:
	map_layout.clear()
	encounter_plan.clear()
	_clear_map_layout_art()
	_set_static_room_visible(true)
	_set_authored_obstacles_visible(true)
	var player_spawn: Marker2D = spawn_points_root.get_node_or_null("PlayerSpawn") as Marker2D
	if player_spawn != null:
		state.player_pos = player_spawn.global_position
	var threat: float = float(activity.get("threat", 1.0)) + float(state.room_index - 1) * 0.08
	var count: int = 4 + int(state.room_index * 1.5)
	var spawn_points: Array[Node] = _enemy_spawn_points()
	for index: int in range(count):
		var spawn_pos: Vector2 = Vector2(640.0, 360.0)
		if spawn_points.size() > 0:
			var marker: Node2D = spawn_points[index % spawn_points.size()] as Node2D
			spawn_pos = marker.global_position
		var enemy_type: String = "Grunt"
		if state.room_index >= 2 and index % 4 == 1:
			enemy_type = "Archer"
		elif state.room_index >= 3 and index % 4 == 2:
			enemy_type = "Spitter"
		elif state.room_index >= 4 and index % 5 == 0:
			enemy_type = "Brute"
		var enemy_data: Dictionary = RVEnemyDB.make(enemy_type, spawn_pos, threat, index)
		_spawn_enemy(enemy_data)
	state.add_notice("Room " + str(state.room_index) + " - Clear enemies")

func _spawn_map_room(state: RVGameState) -> void:
	_clear_children(enemies_root)
	_clear_children(projectiles_root)
	enemy_zones.clear()
	room_clear = false
	reward_claimed = false
	_set_reward_visible(false)
	_set_exit_visible(false)
	state.room_reward_ready = false
	state.room_reward_claimed = false
	state.room_exit_ready = false
	var map_item: Dictionary = Dictionary(activity.get("map", {}))
	map_layout = MapLayoutSystemScript.generate_layout(state.rng, map_item)
	encounter_plan = MapEncounterDirectorScript.build_plan(state.rng, map_item, map_layout)
	_apply_map_layout_art(map_layout)
	_set_static_room_visible(false)
	_set_authored_obstacles_visible(false)
	state.player_pos = Vector2(map_layout.get("start_pos", Vector2(640.0, 594.0)))
	_ensure_runtime_map_camera()
	_update_runtime_map_camera(state.player_pos)
	if reward_chest != null:
		reward_chest.global_position = Vector2(map_layout.get("reward_pos", Vector2(640.0, 178.0)))
	if exit_portal != null:
		exit_portal.global_position = Vector2(map_layout.get("exit_pos", Vector2(640.0, 594.0)))
	_spawn_encounter_plan(state, map_item)
	_update_map_objective(state)
	state.add_notice("Map opened: " + str(map_item.get("name", "Map")))

func _spawn_encounter_plan(state: RVGameState, map_item: Dictionary) -> void:
	map_pack_total = int(encounter_plan.get("objective_total_packs", 0))
	map_pack_cleared = 0
	var enemy_index: int = 0
	var threat: float = float(activity.get("threat", float(map_item.get("threat", 1.0))))
	for pack_value: Variant in Array(encounter_plan.get("packs", [])):
		var pack: Dictionary = Dictionary(pack_value)
		var pack_id: String = str(pack.get("id", "pack"))
		var center: Vector2 = Vector2(pack.get("center", Vector2.ZERO))
		var wake_radius: float = float(pack.get("wake_radius", 220.0))
		var leash_radius: float = float(pack.get("leash_radius", 280.0))
		for enemy_value: Variant in Array(pack.get("enemies", [])):
			var enemy_info: Dictionary = Dictionary(enemy_value)
			var enemy_type: String = str(enemy_info.get("enemy_type", "Grunt"))
			var spawn_pos: Vector2 = Vector2(enemy_info.get("pos", center))
			var enemy_data: Dictionary
			if bool(enemy_info.get("is_elite", false)):
				enemy_data = RVEnemyDB.make_elite(enemy_type, spawn_pos, threat, enemy_index, pack_id)
			else:
				enemy_data = RVEnemyDB.make(enemy_type, spawn_pos, threat, enemy_index)
			enemy_data["pack_id"] = pack_id
			enemy_data["wake_radius"] = wake_radius
			enemy_data["leash_center"] = center
			enemy_data["leash_radius"] = leash_radius
			_spawn_enemy(enemy_data)
			enemy_index += 1
	var boss_info: Dictionary = Dictionary(encounter_plan.get("boss", {}))
	var boss_pos: Vector2 = Vector2(boss_info.get("pos", map_layout.get("boss_pos", Vector2(640.0, 152.0))))
	var boss_data: Dictionary = RVEnemyDB.make_boss(map_item, boss_pos, threat * 1.35)
	boss_data["wake_radius"] = float(boss_info.get("wake_radius", 540.0))
	boss_data["leash_center"] = Vector2(boss_info.get("leash_center", boss_pos))
	boss_data["leash_radius"] = float(boss_info.get("leash_radius", 360.0))
	map_boss_alive = true
	_spawn_enemy(boss_data)

func update_combat(state: RVGameState, player: RVPlayerActor, delta: float) -> void:
	_rf_ensure_combat_layers()
	if not active:
		return
	_rf_update_ground_loot()
	state.prompt_text = ""
	_update_enemy_zones(state, player, delta)
	for enemy_node: Node in _rf_safe_children(enemies_root):
		if not is_instance_valid(enemy_node) or enemy_node.is_queued_for_deletion():
			continue
		if enemy_node is RVEnemyActor:
			var enemy: RVEnemyActor = enemy_node
			CombatPackAISystemScript.apply_context(enemy, enemies_root, player.global_position, delta)
			enemy.update_ai(player.global_position, delta)
	for projectile_node: Node in _rf_safe_children(projectiles_root):
		if not is_instance_valid(projectile_node) or projectile_node.is_queued_for_deletion():
			continue
		if projectile_node is RVProjectileActor:
			var projectile: RVProjectileActor = projectile_node
			if projectile.from_enemy:
				if projectile.global_position.distance_to(player.global_position) <= projectile.radius + state.player_radius:
					_damage_player(state, projectile.damage)
					projectile.queue_free()
			else:
				_check_projectile_enemy_hits(projectile, state)
	if str(activity.get("kind", "")) == "map":
		_update_map_objective(state)
	if _rf_child_count(enemies_root) == 0 and not room_clear:
		_on_room_clear(state)
	_update_room_interaction_prompt(state)

func interact(state: RVGameState) -> void:
	if not active:
		return
	if state.room_reward_ready and not state.room_reward_claimed:
		if state.player_pos.distance_to(reward_chest.global_position) <= 82.0:
			if str(activity.get("kind", "")) == "map":
				RVMapSystem.award_map_boss_loot(state, Dictionary(activity.get("map", {})))
			else:
				RVProgressionSystem.award_room(state)
			state.room_reward_ready = false
			state.room_reward_claimed = true
			state.room_exit_ready = true
			reward_claimed = true
			_set_reward_visible(false)
			_set_exit_visible(true)
			state.room_objective = "Use the exit portal."
			state.add_notice("Reward claimed - Exit portal opened")
			return
		state.add_notice("Move closer to the reward chest")
		return
	if state.room_exit_ready:
		if state.player_pos.distance_to(exit_portal.global_position) <= 92.0:
			var max_rooms: int = int(activity.get("rooms", 1))
			if state.room_index >= max_rooms:
				combat_finished.emit()
			else:
				state.room_index += 1
				spawn_room(state)
			return
		state.add_notice("Move closer to the exit portal")
		return
	state.add_notice("Clear the room first")

func cast_selected_skill(state: RVGameState, aim: Vector2) -> void:
	var skill_name: String = state.get_selected_skill()
	if skill_name == "":
		return
	if not RVSkillSystem.can_cast(state, skill_name):
		return
	var skill_data: Dictionary = RVSkillSystem.pay_cost(state, skill_name)
	var direction: Vector2 = aim - state.player_pos
	if direction.length() < 0.01:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()
	var damage: float = RVSkillSystem.skill_damage(state, skill_name)
	var tags: Array = Array(skill_data.get("tags", [])).duplicate(true)
	var flags: Array = Array(skill_data.get("flags", [])).duplicate(true)
	for flag_value: Variant in flags:
		if not tags.has(str(flag_value)):
			tags.append(str(flag_value))
	_emit_skill_proxy_vfx(skill_name, state.player_pos, aim, direction, skill_data, tags)
	RVSpellVFXSystem.spawn_skill_cast(self, skill_name, state.player_pos, aim, tags)
	tags = CombatStatusComboSystemScript.augment_skill_tags(skill_name, tags)
	CombatJuiceSystemScript.skill_cast_feedback(self, _rf_feedback_root(), skill_name, state.player_pos, tags)
	match skill_name:
		"Cleave":
			var center: Vector2 = state.player_pos + direction * 64.0
			_damage_enemies_in_radius(center, float(skill_data.get("radius", 76.0)), damage, state, tags)
		"Frost Nova":
			_damage_enemies_in_radius(state.player_pos, float(skill_data.get("radius", 145.0)), damage, state, tags)
		"Void Rift":
			_damage_enemies_in_radius(aim, float(skill_data.get("radius", 92.0)), damage, state, tags)
			if tags.has("void_echo"):
				_damage_enemies_in_radius(aim, float(skill_data.get("radius", 92.0)) * 0.68, damage * 0.42, state, tags)
		"Blade Trap":
			_damage_enemies_in_radius(aim, float(skill_data.get("radius", 64.0)), damage, state, tags)
			if tags.has("secondary_trap_tick"):
				_damage_enemies_in_radius(aim, float(skill_data.get("radius", 64.0)) * 0.82, damage * 0.48, state, tags)
		_:
			var speed: float = float(skill_data.get("speed", 540.0))
			var radius: float = float(skill_data.get("radius", 8.0))
			_spawn_projectile(state.player_pos + direction * 24.0, direction * speed, damage, radius, tags, false)
			var extra_projectiles: int = int(skill_data.get("extra_projectiles", 0))
			if extra_projectiles > 0:
				var angles: Array = [-0.24, 0.24, -0.42, 0.42]
				for i: int in range(min(extra_projectiles, angles.size())):
					var side_dir: Vector2 = direction.rotated(float(angles[i]))
					_spawn_projectile(state.player_pos + side_dir * 24.0, side_dir * speed, damage * 0.58, radius, tags, false)

func _update_enemy_zones(state: RVGameState, player: RVPlayerActor, delta: float) -> void:
	for i: int in range(enemy_zones.size() - 1, -1, -1):
		var zone: Dictionary = enemy_zones[i]
		zone["time"] = float(zone.get("time", 0.0)) - delta
		zone["duration"] = float(zone.get("duration", 0.0)) - delta
		if float(zone.get("time", 0.0)) <= 0.0 and not bool(zone.get("triggered", false)):
			zone["triggered"] = true
			if player.global_position.distance_to(Vector2(zone.get("pos", Vector2.ZERO))) <= float(zone.get("radius", 40.0)) + state.player_radius:
				_damage_player(state, float(zone.get("damage", 1.0)))
		if float(zone.get("duration", 0.0)) <= -0.05:
			enemy_zones.remove_at(i)
		else:
			enemy_zones[i] = zone
	queue_redraw()

func _nearest_walkable_position(pos: Vector2) -> Vector2:
	var best: Vector2 = pos
	var best_distance: float = INF
	for section_value: Variant in Array(map_layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		var center: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
		var radius: float = float(section.get("radius", 72.0))
		var distance: float = pos.distance_to(center)
		if distance <= radius:
			return pos
		var candidate: Vector2 = center + (pos - center).normalized() * radius if distance > 0.001 else center
		var candidate_distance: float = pos.distance_to(candidate)
		if candidate_distance < best_distance:
			best_distance = candidate_distance
			best = candidate
	var width: float = float(map_layout.get("corridor_width", 72.0)) * 0.5
	for edge_value: Variant in Array(map_layout.get("edges", [])):
		var edge: Array = Array(edge_value)
		if edge.size() < 2:
			continue
		var a: Vector2 = _layout_section_pos(str(edge[0]))
		var b: Vector2 = _layout_section_pos(str(edge[1]))
		var closest: Vector2 = _closest_point_on_segment(pos, a, b)
		var distance_to_edge: float = pos.distance_to(closest)
		if distance_to_edge <= width:
			return pos
		var candidate_edge: Vector2 = closest
		if distance_to_edge > 0.001:
			candidate_edge += (pos - closest).normalized() * width
		if distance_to_edge < best_distance:
			best_distance = distance_to_edge
			best = candidate_edge
	return best

func _push_from_map_obstacles(pos: Vector2, radius: float) -> Vector2:
	var out: Vector2 = pos
	for obstacle_value: Variant in Array(map_layout.get("obstacles", [])):
		var obstacle: Dictionary = Dictionary(obstacle_value)
		var center: Vector2 = Vector2(obstacle.get("pos", Vector2.ZERO))
		var obstacle_radius: float = float(obstacle.get("radius", 28.0))
		var delta: Vector2 = out - center
		var distance: float = delta.length()
		var min_distance: float = obstacle_radius + radius
		if distance < min_distance:
			if distance <= 0.001:
				delta = Vector2.RIGHT
			else:
				delta = delta / distance
			out = center + delta * min_distance
	return out

func _closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab: Vector2 = b - a
	var denom: float = ab.length_squared()
	if denom <= 0.001:
		return a
	var t: float = clamp((p - a).dot(ab) / denom, 0.0, 1.0)
	return a + ab * t

func _layout_section_pos(id: String) -> Vector2:
	for section_value: Variant in Array(map_layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		if str(section.get("id", "")) == id:
			return Vector2(section.get("pos", Vector2.ZERO))
	return Vector2.ZERO

func _apply_map_layout_art(layout: Dictionary) -> void:
	_clear_map_layout_art()
	map_visual_root = Node2D.new()
	map_visual_root.name = "RuntimeMapLayoutArt"
	add_child(map_visual_root)
	move_child(map_visual_root, 1)
	_draw_map_corridors(layout)
	_draw_map_sections(layout)
	_draw_map_obstacles(layout)
	_decorate_runtime_map_props(layout)

func _draw_map_sections(layout: Dictionary) -> void:
	if map_visual_root == null:
		return
	for section_value: Variant in Array(layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		var poly: Polygon2D = Polygon2D.new()
		var center: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
		var radius: float = float(section.get("radius", 78.0))
		poly.polygon = _rough_circle_polygon(center, radius, 12)
		var kind: String = str(section.get("kind", "pack"))
		if kind == "boss":
			poly.color = Color(0.085, 0.030, 0.030, 1.0)
		elif kind == "elite":
			poly.color = Color(0.080, 0.052, 0.030, 1.0)
		elif kind == "side":
			poly.color = Color(0.038, 0.035, 0.030, 1.0)
		else:
			poly.color = Color(0.045, 0.032, 0.024, 1.0)
		map_visual_root.add_child(poly)
		var border: Line2D = Line2D.new()
		border.points = _closed_polygon(poly.polygon)
		border.width = 3.0
		border.default_color = Color(0.68, 0.38, 0.18, 0.58)
		map_visual_root.add_child(border)

func _draw_map_corridors(layout: Dictionary) -> void:
	if map_visual_root == null:
		return
	var width: float = float(layout.get("corridor_width", 72.0))
	for edge_value: Variant in Array(layout.get("edges", [])):
		var edge: Array = Array(edge_value)
		if edge.size() < 2:
			continue
		var a: Vector2 = _layout_section_pos(str(edge[0]))
		var b: Vector2 = _layout_section_pos(str(edge[1]))
		var corridor: Line2D = Line2D.new()
		corridor.points = PackedVector2Array([a, b])
		corridor.width = width
		corridor.default_color = Color(0.042, 0.030, 0.023, 1.0)
		map_visual_root.add_child(corridor)
		var edge_line: Line2D = Line2D.new()
		edge_line.points = PackedVector2Array([a, b])
		edge_line.width = 4.0
		edge_line.default_color = Color(0.42, 0.25, 0.13, 0.45)
		map_visual_root.add_child(edge_line)

func _draw_map_obstacles(layout: Dictionary) -> void:
	if map_visual_root == null:
		return
	for obstacle_value: Variant in Array(layout.get("obstacles", [])):
		var obstacle: Dictionary = Dictionary(obstacle_value)
		var center: Vector2 = Vector2(obstacle.get("pos", Vector2.ZERO))
		var radius: float = float(obstacle.get("radius", 30.0))
		var poly: Polygon2D = Polygon2D.new()
		poly.polygon = _rough_circle_polygon(center, radius, 7)
		poly.color = Color(0.115, 0.090, 0.070, 1.0)
		map_visual_root.add_child(poly)
		var border: Line2D = Line2D.new()
		border.points = _closed_polygon(poly.polygon)
		border.width = 2.0
		border.default_color = Color(0.16, 0.12, 0.09, 0.92)
		map_visual_root.add_child(border)

func _rough_circle_polygon(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var safe_sides: int = max(5, sides)
	for index: int in range(safe_sides):
		var angle: float = float(index) * TAU / float(safe_sides)
		var wobble: float = 0.88 + 0.18 * sin(float(index) * 2.17 + radius * 0.03)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * wobble)
	return points

func _closed_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array(points)
	if result.size() > 0:
		result.append(result[0])
	return result

func _draw() -> void:
	for zone: Dictionary in enemy_zones:
		var pos: Vector2 = Vector2(zone.get("pos", Vector2.ZERO))
		var radius: float = float(zone.get("radius", 40.0))
		var color: Color = zone.get("color", Color(1.0, 0.2, 0.05, 0.28))
		var triggered: bool = bool(zone.get("triggered", false))
		draw_arc(pos, radius, 0.0, TAU, 40, color if not triggered else Color(color.r, color.g, color.b, 0.62), 3.0)
		if triggered:
			draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.10))

func _clear_map_layout_art() -> void:
	if map_visual_root != null and is_instance_valid(map_visual_root):
		map_visual_root.queue_free()
	map_visual_root = null

func _set_static_room_visible(value: bool) -> void:
	var floor_node: Node = get_node_or_null("Floor")
	if floor_node is CanvasItem:
		(floor_node as CanvasItem).visible = value
	var border_node: Node = get_node_or_null("RoomBorder")
	if border_node is CanvasItem:
		(border_node as CanvasItem).visible = value

func _set_authored_obstacles_visible(value: bool) -> void:
	if obstacles_root == null:
		return
	for child: Node in obstacles_root.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = value

func _on_room_clear(state: RVGameState) -> void:
	room_clear = true
	state.room_reward_ready = true
	state.room_reward_claimed = false
	state.room_exit_ready = false
	state.room_objective = "Open the reward chest."
	_set_reward_visible(true)
	_set_exit_visible(false)
	if str(activity.get("kind", "")) == "map":
		state.add_notice("Map cleared - boss reward available")
	else:
		state.add_notice("Room clear - Reward chest available")

func _update_map_objective(state: RVGameState) -> void:
	var alive_by_pack: Dictionary = {}
	var boss_alive: bool = false
	for enemy_node: Node in _rf_safe_children(enemies_root):
		if not is_instance_valid(enemy_node) or enemy_node.is_queued_for_deletion():
			continue
		if enemy_node is RVEnemyActor:
			var enemy: RVEnemyActor = enemy_node
			if enemy.is_map_boss:
				boss_alive = true
			elif enemy.pack_id != "":
				alive_by_pack[enemy.pack_id] = true
	var cleared: int = 0
	for pack_value: Variant in Array(encounter_plan.get("packs", [])):
		var pack: Dictionary = Dictionary(pack_value)
		if not alive_by_pack.has(str(pack.get("id", ""))):
			cleared += 1
	map_pack_cleared = cleared
	map_boss_alive = boss_alive
	if not room_clear:
		state.room_objective = "Clear packs " + str(map_pack_cleared) + "/" + str(max(1, map_pack_total)) + " · Kill boss: " + ("alive" if map_boss_alive else "defeated")

func _update_room_interaction_prompt(state: RVGameState) -> void:
	if state.room_reward_ready and not state.room_reward_claimed:
		if state.player_pos.distance_to(reward_chest.global_position) <= 82.0:
			state.prompt_text = "E - Open Reward Chest"
			return
	if state.room_exit_ready:
		if state.player_pos.distance_to(exit_portal.global_position) <= 92.0:
			var max_rooms: int = int(activity.get("rooms", 1))
			if state.room_index >= max_rooms:
				state.prompt_text = "E - Return to Hub"
			else:
				state.prompt_text = "E - Enter Next Room"

func _enemy_spawn_points() -> Array[Node]:
	var result: Array[Node] = []
	for child: Node in spawn_points_root.get_children():
		if child is Marker2D and not str(child.name).begins_with("PlayerSpawn"):
			result.append(child)
	return result

func _spawn_enemy(enemy_data: Dictionary) -> void:
	if enemy_scene == null:
		push_warning("CombatArena enemy_scene is missing.")
		return
	var enemy: RVEnemyActor = enemy_scene.instantiate()
	enemies_root.add_child(enemy)
	_rf_prepare_enemy_visual_layer(enemy)
	enemy.setup(enemy_data)
	enemy.died.connect(_on_enemy_died)
	enemy.hit_player.connect(_on_enemy_hit_player)
	if enemy.has_signal("damaged"):
		enemy.damaged.connect(_on_enemy_damaged)
	if enemy.has_signal("projectile_requested"):
		enemy.projectile_requested.connect(_on_enemy_projectile_requested)
	if enemy.has_signal("zone_requested"):
		enemy.zone_requested.connect(_on_enemy_zone_requested)
	if enemy.has_signal("spawn_requested"):
		enemy.spawn_requested.connect(_on_enemy_spawn_requested)

func _spawn_projectile(pos: Vector2, vel: Vector2, damage: float, radius: float, tags: Array, from_enemy: bool) -> void:
	if projectile_scene == null:
		push_warning("CombatArena projectile_scene is missing.")
		return
	var projectile: RVProjectileActor = projectile_scene.instantiate()
	projectiles_root.add_child(projectile)
	projectile.setup(pos, vel, damage, radius, tags, from_enemy)

func _check_projectile_enemy_hits(projectile: RVProjectileActor, state: RVGameState) -> void:
	for enemy_node: Node in _rf_safe_children(enemies_root):
		if not is_instance_valid(enemy_node) or enemy_node.is_queued_for_deletion():
			continue
		if enemy_node is RVEnemyActor:
			var enemy: RVEnemyActor = enemy_node
			if projectile.global_position.distance_to(enemy.global_position) <= projectile.radius + enemy.radius:
				var projectile_damage: float = CombatStatusComboSystemScript.modify_damage_for_enemy(enemy, projectile.tags, projectile.damage)
				enemy.take_damage(projectile_damage, projectile.tags, "projectile")
				_rf_spawn_damage_number(enemy.global_position, projectile_damage, projectile.tags)
				_apply_skill_statuses(enemy, projectile.tags, projectile_damage)
				if projectile.tags.has("fireball_explodes"):
					_damage_enemies_in_radius(projectile.global_position, 48.0, projectile.damage * 0.42, state, projectile.tags, enemy)
				if projectile.tags.has("lightning_chains") or projectile.tags.has("chain_plus"):
					var bonus_chain: int = 1 if projectile.tags.has("chain_plus") else 0
					_chain_lightning(enemy, projectile.damage * 0.45, 2 + bonus_chain, projectile.tags)
				projectile.queue_free()
				return

func _damage_enemies_in_radius(center: Vector2, radius: float, damage: float, state: RVGameState, tags: Array = [], excluded: RVEnemyActor = null) -> int:
	var hits: int = 0
	for enemy_node: Node in _rf_safe_children(enemies_root):
		if not is_instance_valid(enemy_node) or enemy_node.is_queued_for_deletion():
			continue
		if enemy_node is RVEnemyActor:
			var enemy: RVEnemyActor = enemy_node
			if enemy == excluded:
				continue
			if center.distance_to(enemy.global_position) <= radius + enemy.radius:
				var final_damage: float = damage
				if tags.has("close_combat_bonus") and center.distance_to(enemy.global_position) <= radius * 0.50:
					final_damage *= 1.18
				final_damage = CombatStatusComboSystemScript.modify_damage_for_enemy(enemy, tags, final_damage)
				enemy.take_damage(final_damage, tags, "area")
				_rf_spawn_damage_number(enemy.global_position, final_damage, tags)
				_apply_skill_statuses(enemy, tags, final_damage)
				if tags.has("rift_pull"):
					enemy.pull_toward(center, 34.0)
				hits += 1
	return hits

func _apply_skill_statuses(enemy: RVEnemyActor, tags: Array, damage: float) -> void:
	var status_power: float = 1.0
	if tags.has("strong_burn") or tags.has("aura_burn_boost"):
		status_power += 0.35
	if tags.has("strong_freeze"):
		status_power += 0.25
	if tags.has("strong_bleed") or tags.has("aura_bleed_boost"):
		status_power += 0.35
	if tags.has("inflicts_burn") or (tags.has("Fire") and tags.has("strong_burn")):
		enemy.apply_status("burn", 3.6, max(1.0, damage * 0.025 * status_power))
	if tags.has("inflicts_bleed") or tags.has("Bleed"):
		enemy.apply_status("bleed", 4.4, max(1.0, damage * 0.022 * status_power))
	if tags.has("inflicts_freeze") or (tags.has("Cold") and tags.has("strong_freeze")):
		enemy.apply_status("freeze", 2.0 + status_power * 0.55, status_power)
	if tags.has("inflicts_curse") or (tags.has("Void") and tags.has("void_echo")):
		enemy.apply_status("curse", 5.0, status_power)
	if tags.has("shock_pressure") or tags.has("shock_burst"):
		enemy.apply_status("shock", 3.0, status_power)
	CombatStatusComboSystemScript.apply_statuses_and_combos(self, state_ref, enemy, tags, damage)

func _damage_player(state: RVGameState, amount: float) -> void:
	if state.invuln > 0.0:
		return
	state.player_hp -= amount
	state.invuln = 0.45
	state.add_notice("-" + str(int(amount)) + " HP")
	CombatJuiceSystemScript.player_damage_feedback(self, _rf_feedback_root(), state.player_pos, amount)
	if state.player_hp <= 0.0:
		player_died.emit()

func _on_enemy_died(enemy: RVEnemyActor) -> void:
	var death_root: Node2D = _ensure_vfx_root() if has_method("_ensure_vfx_root") else self
	CombatFeedbackSystemScript.enemy_death(self, death_root, enemy.global_position, [])
	if state_ref != null:
		RVProgressionSystem.award_kill(state_ref)
		if str(activity.get("kind", "")) == "map":
			var depth: int = max(1, int(Dictionary(activity.get("map", {})).get("map_level", state_ref.level)))
			var drop_chance: float = 0.09 if enemy.is_elite else 0.045
			if enemy.is_map_boss:
				map_boss_alive = false
			elif state_ref.rng.randf() < drop_chance:
				RVMapSystem.award_map_enemy_drop(state_ref, depth)
		CombatJuiceSystemScript.enemy_kill_feedback(self, _rf_feedback_root(), enemy.global_position, _rf_enemy_last_tags(enemy))
	CombatStatusComboSystemScript.on_enemy_killed(self, state_ref, enemy, _rf_enemy_last_tags(enemy))
	_rf_drop_enemy_loot(enemy)
	enemy.queue_free()

func _on_enemy_hit_player(amount: float) -> void:
	if state_ref != null:
		_damage_player(state_ref, amount)

func _on_enemy_projectile_requested(pos: Vector2, vel: Vector2, damage: float, radius: float, tags: Array) -> void:
	_spawn_projectile(pos, vel, damage, radius, tags, true)

func _on_enemy_zone_requested(pos: Vector2, radius: float, delay: float, duration: float, damage: float, tags: Array, color: Color) -> void:
	enemy_zones.append({
		"pos": pos,
		"radius": radius,
		"time": delay,
		"duration": delay + duration,
		"damage": damage,
		"tags": tags,
		"color": color,
		"triggered": false
	})

func _on_enemy_spawn_requested(enemy_type: String, pos: Vector2, count: int) -> void:
	if state_ref == null:
		return
	for i: int in range(max(1, count)):
		var offset: Vector2 = Vector2(28.0, 0.0).rotated(float(i) * TAU / float(max(1, count)))
		var enemy_data: Dictionary = RVEnemyDB.make(enemy_type, pos + offset, float(activity.get("threat", 1.0)), _rf_child_count(enemies_root) + i)
		enemy_data["wake_radius"] = 999.0
		enemy_data["pack_id"] = "summoned"
		_spawn_enemy(enemy_data)

func _set_reward_visible(value: bool) -> void:
	if reward_chest != null:
		reward_chest.visible = value

func _set_exit_visible(value: bool) -> void:
	if exit_portal != null:
		exit_portal.visible = value

func _clear_children(root: Node) -> void:
	for child: Node in root.get_children():
		child.queue_free()

func dev_spawn_enemy(enemy_type: String, count: int = 1) -> void:
	if state_ref == null:
		return
	var safe_count: int = max(1, count)
	for i: int in range(safe_count):
		var offset: Vector2 = Vector2(80.0 + float(i * 28), 0.0).rotated(float(i) * 0.65)
		var spawn_pos: Vector2 = state_ref.player_pos + offset
		var enemy_index: int = _rf_child_count(enemies_root) + i
		var enemy_data: Dictionary = RVEnemyDB.make(enemy_type, spawn_pos, 1.0, enemy_index)
		_spawn_enemy(enemy_data)
	state_ref.add_notice("Dev: spawned " + str(safe_count) + " " + enemy_type)

func dev_clear_enemies() -> void:
	_clear_children(enemies_root)
	if state_ref != null:
		state_ref.add_notice("Dev: enemies cleared")

func dev_force_reward() -> void:
	if state_ref == null:
		return
	room_clear = true
	reward_claimed = false
	state_ref.room_reward_ready = true
	state_ref.room_reward_claimed = false
	state_ref.room_exit_ready = false
	state_ref.room_objective = "Open the reward chest."
	_set_reward_visible(true)
	_set_exit_visible(false)
	state_ref.add_notice("Dev: reward chest forced")

func _ensure_vfx_root() -> Node2D:
	if vfx_root != null and is_instance_valid(vfx_root):
		return vfx_root
	vfx_root = Node2D.new()
	vfx_root.name = "RuntimeSpellVFX"
	vfx_root.z_index = 50
	add_child(vfx_root)
	return vfx_root

func _emit_skill_proxy_vfx(skill_name: String, origin: Vector2, aim: Vector2, direction: Vector2, skill_data: Dictionary, tags: Array) -> void:
	var root: Node2D = _ensure_vfx_root()
	SpellVFXSystemScript.emit_skill(self, root, skill_name, origin, aim, direction, skill_data, tags)
	CombatFeedbackSystemScript.skill_cast_feedback(self, root, skill_name, origin, aim, direction, skill_data, tags)

func _decorate_runtime_map_props(layout: Dictionary) -> void:
	if map_visual_root == null:
		return
	MapPropVisualSystemScript.decorate(map_visual_root, layout, Dictionary(activity.get("map", {})))

func _clear_runtime_vfx() -> void:
	if vfx_root != null and is_instance_valid(vfx_root):
		vfx_root.queue_free()
	vfx_root = null


func _on_enemy_damaged(enemy: RVEnemyActor, amount: float, tags: Array = []) -> void:
	CombatJuiceSystemScript.enemy_hit_feedback(self, _rf_feedback_root(), enemy, amount, tags)
	var root: Node2D = _ensure_vfx_root() if has_method("_ensure_vfx_root") else self
	CombatFeedbackSystemScript.enemy_hit(self, root, enemy, amount, tags)


func _on_enemy_phase_changed(enemy: RVEnemyActor, phase: int) -> void:
	BossPhaseDirectorScript.on_phase_changed(self, state_ref, enemy, phase)


func _chain_lightning(source: RVEnemyActor, damage: float, count: int, tags: Array) -> void:
	var chained: Array[RVEnemyActor] = [source]
	var current: RVEnemyActor = source
	for i: int in range(max(0, count)):
		var best: RVEnemyActor = null
		var best_dist: float = 999999.0
		for enemy_node: Node in _rf_safe_children(enemies_root):
			if not is_instance_valid(enemy_node) or enemy_node.is_queued_for_deletion():
				continue
			if enemy_node is RVEnemyActor:
					var enemy: RVEnemyActor = enemy_node
					if chained.has(enemy):
						continue
					var dist: float = current.global_position.distance_to(enemy.global_position)
					if dist < best_dist and dist <= 220.0:
						best = enemy
						best_dist = dist
			if best == null:
				return
			best.take_damage(damage, tags, "chain")
			_rf_spawn_damage_number(best.global_position, damage, tags)
			if best.has_method("apply_status"):
				best.apply_status("shock", 2.5, 1.0)
			chained.append(best)
			current = best
			damage *= 0.72

# -----------------------------------------------------------------------------
# Patch 072B: Safe ground-loot helper block.
# Avoids global-class type annotations so CombatArena can parse even if Godot's
# class cache has not refreshed after installing new scripts.
# -----------------------------------------------------------------------------
func _rf_ensure_combat_layers() -> void:
	_rf_named_node2d("MapGroundLayer", -100)
	_rf_named_node2d("MapDressingLayer", -50)
	_rf_named_node2d("GroundTelegraphLayer", -20)
	_rf_named_node2d("GroundLootLayer", 8)
	_rf_named_node2d("FloatingCombatTextLayer", 120)
	if enemies_root != null:
		enemies_root.z_as_relative = false
		enemies_root.z_index = 20
	var projectile_root: Node2D = get_node_or_null("ProjectilesRoot") as Node2D
	if projectile_root != null:
		projectile_root.z_as_relative = false
		projectile_root.z_index = 40

func _rf_named_node2d(node_name: String, z: int) -> Node2D:
	var node: Node2D = get_node_or_null(node_name) as Node2D
	if node == null:
		node = Node2D.new()
		node.name = node_name
		add_child(node)
	node.z_as_relative = false
	node.z_index = z
	return node

func _rf_loot_root() -> Node2D:
	return _rf_named_node2d("GroundLootLayer", 8)

func _rf_prepare_enemy_visual_layer(enemy: Node2D) -> void:
	if enemy == null:
		return
	enemy.z_as_relative = false
	enemy.z_index = 20
	for child: Node in enemy.get_children():
		if child is CanvasItem:
			var canvas_child: CanvasItem = child as CanvasItem
			canvas_child.z_as_relative = true

func _rf_spawn_damage_number(pos: Vector2, amount: float, tags: Array = []) -> void:
	if RVFloatingCombatTextSystemScript != null:
		RVFloatingCombatTextSystemScript.spawn_damage(_rf_feedback_root(), pos, amount, tags, false)

func _rf_spawn_combat_callout(pos: Vector2, label_text: String, color: Color = Color(1.0, 0.82, 0.32)) -> void:
	if RVFloatingCombatTextSystemScript != null:
		RVFloatingCombatTextSystemScript.spawn_callout(_rf_feedback_root(), pos, label_text, color)

func _rf_drop_enemy_loot(enemy: Node) -> void:
	if state_ref == null or enemy == null:
		return
	var payloads: Array[Dictionary] = RVLootDropSystemScript.enemy_drop_payloads(state_ref, enemy, activity)
	if payloads.is_empty():
		return
	var root: Node2D = _rf_loot_root()
	var base_pos: Vector2 = Vector2.ZERO
	if enemy is Node2D:
		base_pos = (enemy as Node2D).global_position
	var count: int = payloads.size()
	for i: int in range(count):
		var angle: float = TAU * float(i) / max(1.0, float(count))
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * (18.0 + 7.0 * float(i % 3))
		_rf_spawn_ground_loot(payloads[i], base_pos + offset)
	if bool(enemy.get("is_map_boss")):
		_rf_spawn_combat_callout(base_pos, "BOSS LOOT", Color(1.0, 0.62, 0.18))
		_rf_hide_map_reward_chest_if_any()

func _rf_spawn_ground_loot(payload: Dictionary, pos: Vector2) -> void:
	var drop: Node = RVLootDropActorScript.new()
	_rf_loot_root().add_child(drop)
	if drop is Node2D:
		(drop as Node2D).global_position = pos
	if drop.has_method("setup"):
		drop.call("setup", payload)
	if drop.has_signal("picked_up"):
		drop.connect("picked_up", Callable(self, "_rf_pickup_loot_drop"))

func _rf_update_ground_loot() -> void:
	if state_ref == null:
		return
	var wants_pickup: bool = Input.is_key_pressed(KEY_E)
	var mouse_pickup: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not wants_pickup and not mouse_pickup:
		return
	var best: Node = null
	var best_dist: float = 999999.0
	var root: Node2D = _rf_loot_root()
	var mouse_pos: Vector2 = get_global_mouse_position()
	for child: Node in root.get_children():
		if not child.has_method("pick_up"):
			continue
		if not (child is Node2D):
			continue
		var drop_node: Node2D = child as Node2D
		var dist: float = drop_node.global_position.distance_to(state_ref.player_pos)
		if mouse_pickup and drop_node.global_position.distance_to(mouse_pos) <= 42.0:
			dist = 0.0
		if dist < best_dist and dist <= 48.0:
			best = child
			best_dist = dist
	if best != null:
		best.call("pick_up")

func _rf_pickup_loot_drop(drop: Node) -> void:
	if drop == null or state_ref == null:
		return
	var payload: Dictionary = {}
	if drop.get("payload") != null:
		payload = Dictionary(drop.get("payload"))
	var msg: String = RVLootDropSystemScript.pickup_payload(state_ref, payload)
	if msg != "":
		state_ref.add_notice(msg)
		var pos: Vector2 = Vector2.ZERO
		if drop is Node2D:
			pos = (drop as Node2D).global_position
		RVFloatingCombatTextSystemScript.spawn_callout(_rf_feedback_root(), pos, msg, Color(0.90, 0.84, 0.58), 12)

func _rf_hide_map_reward_chest_if_any() -> void:
	if str(activity.get("kind", "")) != "map":
		return
	for node: Node in get_tree().get_nodes_in_group("reward_chest"):
		if node is CanvasItem:
			(node as CanvasItem).visible = false
	for child: Node in get_children():
		if child.name.to_lower().find("chest") >= 0 and child is CanvasItem:
			(child as CanvasItem).visible = false


func _ensure_runtime_map_camera() -> void:
	if runtime_map_camera == null or not is_instance_valid(runtime_map_camera):
		runtime_map_camera = Camera2D.new()
		runtime_map_camera.name = "RuntimeMapCamera"
		runtime_map_camera.position_smoothing_enabled = true
		runtime_map_camera.position_smoothing_speed = 8.0
		add_child(runtime_map_camera)
	if not map_layout.is_empty() and map_layout.has("bounds"):
		var bounds_value: Variant = map_layout.get("bounds")
		if typeof(bounds_value) == TYPE_RECT2:
			var bounds: Rect2 = bounds_value
			runtime_map_camera.limit_left = int(floor(bounds.position.x - 140.0))
			runtime_map_camera.limit_top = int(floor(bounds.position.y - 110.0))
			runtime_map_camera.limit_right = int(ceil(bounds.position.x + bounds.size.x + 140.0))
			runtime_map_camera.limit_bottom = int(ceil(bounds.position.y + bounds.size.y + 110.0))
	runtime_map_camera.enabled = true
	runtime_map_camera.make_current()

func _update_runtime_map_camera(target: Vector2) -> void:
	if runtime_map_camera == null or not is_instance_valid(runtime_map_camera):
		return
	if str(activity.get("kind", "")) != "map":
		return
	runtime_map_camera.global_position = target

func get_current_map_layout() -> Dictionary:
	var value: Variant = get("map_layout")
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value)
	return {}

func get_combat_bounds() -> Rect2:
	return RVCombatGeometrySystem.layout_bounds(get_current_map_layout())

func constrain_player_position(pos: Vector2) -> Vector2:
	return RVCombatGeometrySystem.constrain_point(get_current_map_layout(), pos, 18.0)

func constrain_actor_position(pos: Vector2, radius: float = 16.0) -> Vector2:
	return RVCombatGeometrySystem.constrain_point(get_current_map_layout(), pos, radius)

func has_line_of_sight(from_pos: Vector2, to_pos: Vector2, padding: float = 10.0) -> bool:
	return RVCombatGeometrySystem.has_line_of_sight(get_current_map_layout(), from_pos, to_pos, padding)

func resolve_projectile_segment(previous_pos: Vector2, current_pos: Vector2, velocity: Vector2, radius: float = 5.0, bounces_remaining: int = 0) -> Dictionary:
	return RVCombatGeometrySystem.resolve_projectile_segment(get_current_map_layout(), previous_pos, current_pos, velocity, radius, bounces_remaining)

func enforce_layout_entity_collisions() -> void:
	var layout: Dictionary = get_current_map_layout()
	if layout.is_empty():
		return
	var enemies: Array[Node2D] = []
	_collect_layout_enemy_nodes(self, enemies)
	for enemy: Node2D in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var radius: float = 16.0
		var radius_value: Variant = enemy.get("radius")
		if typeof(radius_value) == TYPE_FLOAT or typeof(radius_value) == TYPE_INT:
			radius = max(10.0, float(radius_value))
		enemy.global_position = RVCombatGeometrySystem.constrain_point(layout, enemy.global_position, radius)

func enforce_layout_projectile_collisions(delta: float) -> void:
	var layout: Dictionary = get_current_map_layout()
	if layout.is_empty():
		return
	var projectiles: Array[Node2D] = []
	_collect_layout_projectile_nodes(self, projectiles)
	for projectile: Node2D in projectiles:
		if projectile == null or not is_instance_valid(projectile):
			continue
		var current_pos: Vector2 = projectile.global_position
		var previous_pos: Vector2 = current_pos
		if projectile.has_meta("rv_prev_projectile_pos"):
			previous_pos = Vector2(projectile.get_meta("rv_prev_projectile_pos"))
		else:
			previous_pos = current_pos - _projectile_velocity(projectile) * max(delta, 0.001)
		var velocity: Vector2 = _projectile_velocity(projectile)
		var radius: float = _projectile_radius(projectile)
		var bounces: int = _projectile_bounces(projectile)
		var result: Dictionary = RVCombatGeometrySystem.resolve_projectile_segment(layout, previous_pos, current_pos, velocity, radius, bounces)
		if bool(result.get("hit", false)):
			if bool(result.get("expired", false)):
				if projectile.has_method("expire"):
					projectile.call("expire")
				else:
					projectile.queue_free()
			else:
				projectile.global_position = Vector2(result.get("position", current_pos))
				_set_projectile_velocity(projectile, Vector2(result.get("velocity", velocity)))
				_set_projectile_bounces(projectile, int(result.get("bounces_remaining", max(0, bounces - 1))))
		if is_instance_valid(projectile):
			projectile.set_meta("rv_prev_projectile_pos", projectile.global_position)

func _collect_layout_enemy_nodes(root: Node, out: Array[Node2D]) -> void:
	for child: Node in root.get_children():
		if child is Node2D:
			var node2d: Node2D = child as Node2D
			if _looks_like_enemy_node(node2d):
				out.append(node2d)
		_collect_layout_enemy_nodes(child, out)

func _looks_like_enemy_node(node: Node) -> bool:
	var lower_name: String = node.name.to_lower()
	if lower_name.contains("enemy") or lower_name.contains("grunt") or lower_name.contains("wretch") or lower_name.contains("imp") or lower_name.contains("boss"):
		return true
	var script: Script = node.get_script() as Script
	if script != null and script.resource_path.to_lower().ends_with("enemyactor.gd"):
		return true
	return node.has_method("take_damage") and (node.has_method("update_actor") or node.has_method("update_enemy") or node.has_method("update_combat"))

func _collect_layout_projectile_nodes(root: Node, out: Array[Node2D]) -> void:
	for child: Node in root.get_children():
		if child is Node2D:
			var node2d: Node2D = child as Node2D
			if _looks_like_projectile_node(node2d):
				out.append(node2d)
		_collect_layout_projectile_nodes(child, out)

func _looks_like_projectile_node(node: Node) -> bool:
	var lower_name: String = node.name.to_lower()
	if lower_name.contains("projectile") or lower_name.contains("bolt") or lower_name.contains("missile"):
		return true
	var script: Script = node.get_script() as Script
	if script != null:
		var path: String = script.resource_path.to_lower()
		if path.contains("projectile") or path.contains("visualproxyvfxnode"):
			return true
	var velocity_value: Variant = node.get("velocity")
	return typeof(velocity_value) == TYPE_VECTOR2 and lower_name.contains("vfx")

func _projectile_velocity(node: Node) -> Vector2:
	var velocity_value: Variant = node.get("velocity")
	if typeof(velocity_value) == TYPE_VECTOR2:
		return Vector2(velocity_value)
	var direction_value: Variant = node.get("direction")
	var speed_value: Variant = node.get("speed")
	if typeof(direction_value) == TYPE_VECTOR2 and (typeof(speed_value) == TYPE_FLOAT or typeof(speed_value) == TYPE_INT):
		return Vector2(direction_value).normalized() * float(speed_value)
	return Vector2.ZERO

func _set_projectile_velocity(node: Node, velocity: Vector2) -> void:
	if node.get("velocity") != null:
		node.set("velocity", velocity)
	if node.get("direction") != null and velocity.length_squared() > 0.001:
		node.set("direction", velocity.normalized())
	if node.get("speed") != null:
		node.set("speed", velocity.length())

func _projectile_radius(node: Node) -> float:
	for key: String in ["collision_radius", "radius", "hit_radius"]:
		var value: Variant = node.get(key)
		if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
			return max(2.0, float(value))
	return 5.0

func _projectile_bounces(node: Node) -> int:
	for key: String in ["bounces_remaining", "remaining_bounces", "bounce_count", "bounces"]:
		var value: Variant = node.get(key)
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			return int(value)
	return 0

func _set_projectile_bounces(node: Node, bounces: int) -> void:
	for key: String in ["bounces_remaining", "remaining_bounces", "bounce_count", "bounces"]:
		if node.get(key) != null:
			node.set(key, bounces)
			return


func _rf_node_alive(node: Node) -> bool:
	return node != null and is_instance_valid(node) and not node.is_queued_for_deletion()

func _rf_safe_children(node: Node) -> Array:
	if not _rf_node_alive(node):
		return []
	return node.get_children()

func _rf_child_count(node: Node) -> int:
	if not _rf_node_alive(node):
		return 0
	return node.get_child_count()
