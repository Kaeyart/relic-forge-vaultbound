class_name RVCombatArena
extends Node2D

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
var map_visual_root: Node2D = null

func start_activity(state: RVGameState, new_activity: Dictionary) -> void:
	state_ref = state
	activity = new_activity.duplicate(true)
	active = true
	_clear_children(enemies_root)
	_clear_children(projectiles_root)
	state.room_index = max(1, state.room_index)
	spawn_room(state)

func stop_activity() -> void:
	active = false
	_clear_children(enemies_root)
	_clear_children(projectiles_root)
	_set_reward_visible(false)
	_set_exit_visible(false)
	_clear_map_layout_art()
	_set_static_room_visible(true)
	_set_authored_obstacles_visible(true)
	map_layout.clear()
	if state_ref != null:
		state_ref.room_objective = ""
		state_ref.prompt_text = ""

func spawn_room(state: RVGameState) -> void:
	_clear_children(enemies_root)
	_clear_children(projectiles_root)
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
	map_layout.clear()
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
	room_clear = false
	reward_claimed = false
	_set_reward_visible(false)
	_set_exit_visible(false)
	state.room_reward_ready = false
	state.room_reward_claimed = false
	state.room_exit_ready = false
	var map_item: Dictionary = Dictionary(activity.get("map", {}))
	map_layout = RVMapLayoutSystem.generate_layout(state.rng, map_item)
	_apply_map_layout_art(map_layout)
	_set_static_room_visible(false)
	_set_authored_obstacles_visible(false)
	state.room_objective = "Clear the map and kill: " + str(map_item.get("boss_name", "Map Boss"))
	state.player_pos = Vector2(map_layout.get("start_pos", Vector2(640.0, 594.0)))
	if reward_chest != null:
		reward_chest.global_position = Vector2(map_layout.get("reward_pos", Vector2(640.0, 178.0)))
	if exit_portal != null:
		exit_portal.global_position = Vector2(map_layout.get("exit_pos", Vector2(640.0, 594.0)))
	var threat: float = float(activity.get("threat", 1.0))
	var pack_size: float = float(map_item.get("pack_size", 1.0))
	var enemy_mix: Array = Array(map_item.get("enemy_mix", ["Grunt", "Archer", "Spitter", "Brute"]))
	var enemy_index: int = 0
	for section_value: Variant in Array(map_layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		var kind: String = str(section.get("kind", "pack"))
		if kind == "start" or kind == "boss":
			continue
		var base_count: int = int(section.get("pack_count", 3))
		var count: int = max(2, int(round(float(base_count) * pack_size)))
		var center: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
		var radius: float = float(section.get("radius", 72.0))
		for i: int in range(count):
			var angle: float = state.rng.randf_range(0.0, TAU)
			var dist: float = state.rng.randf_range(10.0, max(12.0, radius - 22.0))
			var spawn_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
			var enemy_type: String = str(enemy_mix[enemy_index % max(1, enemy_mix.size())])
			var enemy_data: Dictionary = RVEnemyDB.make(enemy_type, spawn_pos, threat, enemy_index)
			_spawn_enemy(enemy_data)
			enemy_index += 1
	var boss_pos: Vector2 = Vector2(map_layout.get("boss_pos", Vector2(640.0, 152.0)))
	var boss_data: Dictionary = RVEnemyDB.make("Brute", boss_pos, threat * 2.35, 9999)
	boss_data["type"] = str(map_item.get("boss_name", "Map Boss"))
	boss_data["role"] = "brute"
	boss_data["radius"] = 34.0
	boss_data["hp"] = float(boss_data.get("hp", 200.0)) * 2.2
	boss_data["max_hp"] = boss_data["hp"]
	boss_data["is_map_boss"] = true
	_spawn_enemy(boss_data)
	state.add_notice("Map opened: " + str(map_item.get("name", "Map")))

func update_combat(state: RVGameState, player: RVPlayerActor, delta: float) -> void:
	if not active:
		return
	state.prompt_text = ""
	for enemy_node: Node in enemies_root.get_children():
		if enemy_node is RVEnemyActor:
			var enemy: RVEnemyActor = enemy_node
			enemy.update_ai(player.global_position, delta)
	for projectile_node: Node in projectiles_root.get_children():
		if projectile_node is RVProjectileActor:
			var projectile: RVProjectileActor = projectile_node
			if projectile.from_enemy:
				if projectile.global_position.distance_to(player.global_position) <= projectile.radius + state.player_radius:
					_damage_player(state, projectile.damage)
					projectile.queue_free()
			else:
				_check_projectile_enemy_hits(projectile, state)
	if enemies_root.get_child_count() == 0 and not room_clear:
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

func constrain_player_position(pos: Vector2) -> Vector2:
	if not active:
		return pos
	if str(activity.get("kind", "")) != "map" or map_layout.is_empty():
		return pos
	var constrained: Vector2 = _nearest_walkable_position(pos)
	return _push_from_map_obstacles(constrained, 18.0)

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
		var candidate: Vector2 = center + (pos - center).normalized() * radius
		if distance < 0.001:
			candidate = center
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
		state.add_notice("Map boss defeated - Reward chest available")
	else:
		state.add_notice("Room clear - Reward chest available")

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
	enemy.setup(enemy_data)
	enemy.died.connect(_on_enemy_died)
	enemy.hit_player.connect(_on_enemy_hit_player)

func _spawn_projectile(pos: Vector2, vel: Vector2, damage: float, radius: float, tags: Array, from_enemy: bool) -> void:
	if projectile_scene == null:
		push_warning("CombatArena projectile_scene is missing.")
		return
	var projectile: RVProjectileActor = projectile_scene.instantiate()
	projectiles_root.add_child(projectile)
	projectile.setup(pos, vel, damage, radius, tags, from_enemy)

func _check_projectile_enemy_hits(projectile: RVProjectileActor, state: RVGameState) -> void:
	for enemy_node: Node in enemies_root.get_children():
		if enemy_node is RVEnemyActor:
			var enemy: RVEnemyActor = enemy_node
			if projectile.global_position.distance_to(enemy.global_position) <= projectile.radius + enemy.radius:
				enemy.take_damage(projectile.damage)
				_apply_skill_statuses(enemy, projectile.tags, projectile.damage)
				if projectile.tags.has("fireball_explodes"):
					_damage_enemies_in_radius(projectile.global_position, 48.0, projectile.damage * 0.42, state, projectile.tags, enemy)
				if projectile.tags.has("lightning_chains") or projectile.tags.has("chain_plus"):
					var bonus_chain: int = 1 if projectile.tags.has("chain_plus") else 0
					_chain_lightning(enemy, projectile.damage * 0.45, 2 + bonus_chain, projectile.tags)
				projectile.queue_free()
				return

func _damage_enemies_in_radius(center: Vector2, radius: float, damage: float, state: RVGameState, tags: Array = [], excluded: RVEnemyActor = null) -> int:
	var hits: int = 0
	for enemy_node: Node in enemies_root.get_children():
		if enemy_node is RVEnemyActor:
			var enemy: RVEnemyActor = enemy_node
			if enemy == excluded:
				continue
			if center.distance_to(enemy.global_position) <= radius + enemy.radius:
				var final_damage: float = damage
				if tags.has("close_combat_bonus") and center.distance_to(enemy.global_position) <= radius * 0.50:
					final_damage *= 1.18
				enemy.take_damage(final_damage)
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

func _chain_lightning(source: RVEnemyActor, damage: float, count: int, tags: Array) -> void:
	var chained: Array[RVEnemyActor] = [source]
	var current: RVEnemyActor = source
	for i: int in range(max(0, count)):
		var best: RVEnemyActor = null
		var best_dist: float = 999999.0
		for enemy_node: Node in enemies_root.get_children():
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
		best.take_damage(damage)
		best.apply_status("shock", 2.5, 1.0)
		chained.append(best)
		current = best
		damage *= 0.72

func _damage_player(state: RVGameState, amount: float) -> void:
	if state.invuln > 0.0:
		return
	state.player_hp -= amount
	state.invuln = 0.45
	state.add_notice("-" + str(int(amount)) + " HP")
	if state.player_hp <= 0.0:
		player_died.emit()

func _on_enemy_died(enemy: RVEnemyActor) -> void:
	if state_ref != null:
		RVProgressionSystem.award_kill(state_ref)
		if str(activity.get("kind", "")) == "map" and state_ref.rng.randf() < 0.20:
			RVMapSystem.award_map_enemy_drop(state_ref, max(1, int(activity.get("threat", 1.0))))
	enemy.queue_free()

func _on_enemy_hit_player(amount: float) -> void:
	if state_ref != null:
		_damage_player(state_ref, amount)

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
		var enemy_index: int = enemies_root.get_child_count() + i
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
