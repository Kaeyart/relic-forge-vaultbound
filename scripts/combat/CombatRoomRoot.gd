class_name RVCombatRoomRoot
extends Node2D

@export var room_id: String = "training_room"
@export var room_name: String = "Training Room"
@export var objective_text: String = "Defeat all enemies, claim the reward chest, then use the exit portal."
@export var arena_rect: Rect2 = Rect2(60.0, 84.0, 1160.0, 566.0)

func export_room_layout() -> Dictionary:
	var player_spawn: Vector2 = Vector2(640.0, 370.0)
	var player_spawn_node: Node2D = get_node_or_null("SpawnPoints/PlayerSpawn") as Node2D
	if player_spawn_node != null:
		player_spawn = player_spawn_node.global_position

	var enemy_spawns: Array = []
	var spawn_root: Node = get_node_or_null("SpawnPoints")
	if spawn_root != null:
		for child in spawn_root.get_children():
			if child is Node2D and str(child.name).begins_with("EnemySpawn"):
				enemy_spawns.append((child as Node2D).global_position)

	var obstacles: Array = []
	var obstacle_root: Node = get_node_or_null("Obstacles")
	if obstacle_root != null:
		for child in obstacle_root.get_children():
			if child is Node2D:
				var radius_value: float = 30.0
				if child.get("radius") != null:
					radius_value = float(child.get("radius"))
				obstacles.append({"pos": (child as Node2D).global_position, "radius": radius_value})

	var reward_pos: Vector2 = Vector2(640.0, 285.0)
	var reward_node: Node2D = get_node_or_null("RewardChest") as Node2D
	if reward_node != null:
		reward_pos = reward_node.global_position

	var exit_pos: Vector2 = Vector2(640.0, 600.0)
	var exit_node: Node2D = get_node_or_null("ExitPortal") as Node2D
	if exit_node != null:
		exit_pos = exit_node.global_position

	return {
		"room_id": room_id,
		"room_name": room_name,
		"objective": objective_text,
		"arena": arena_rect,
		"player_spawn": player_spawn,
		"enemy_spawns": enemy_spawns,
		"obstacles": obstacles,
		"reward_pos": reward_pos,
		"exit_pos": exit_pos
	}
