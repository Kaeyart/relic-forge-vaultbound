class_name RVCombatArena
extends Node2D

var state: RVGameState
var main: Node
var enemies: Array = []
var enemy_scene: PackedScene = preload("res://scenes/prefabs/enemies/EnemyActor.tscn")
var projectile_scene: PackedScene = preload("res://scenes/prefabs/projectiles/ProjectileActor.tscn")
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var spawn_root: Node2D = $SpawnPoints
@onready var enemy_root: Node2D = $Enemies
@onready var projectile_root: Node2D = $Projectiles

func setup(p_state: RVGameState, p_main: Node) -> void:
	state = p_state
	main = p_main

func get_spawn_position() -> Vector2:
	return player_spawn.global_position

func start_activity(activity: Dictionary) -> void:
	clear_room()
	spawn_wave(activity)

func clear_room() -> void:
	for e in enemies:
		if is_instance_valid(e): e.queue_free()
	enemies.clear()
	for child in projectile_root.get_children():
		child.queue_free()

func spawn_wave(activity: Dictionary) -> void:
	var threat: float = float(activity.get("threat", 1.0))
	var tier: int = int(activity.get("tier", 1))
	var markers: Array = spawn_root.get_children()
	var count: int = min(markers.size(), 4 + tier * 2)
	for i in range(count):
		var enemy: RVEnemyActor = enemy_scene.instantiate()
		enemy_root.add_child(enemy)
		enemy.global_position = markers[i].global_position
		if tier >= 3 and i % 5 == 0:
			enemy.max_life = 150.0
			enemy.damage = 22.0
			enemy.move_speed = 48.0
			enemy.radius = 24.0
		enemy.setup(state, threat)
		enemy.died.connect(_on_enemy_died)
		enemies.append(enemy)

func update_arena(_delta: float) -> void:
	if state == null or state.mode != "combat":
		return
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	if enemies.size() == 0:
		state.rooms_cleared += 1
		state.run_depth += 1
		state.add_xp(45.0 + float(state.run_depth) * 5.0)
		state.gold += 10 + state.run_depth * 2
		state.materials["shards"] = int(state.materials.get("shards", 0)) + 1
		state.add_notice("Room Cleared")
		spawn_wave(state.current_activity)

func cast_skill(skill: String, aim: Vector2) -> void:
	var data: Dictionary = RVSkillDB.data(skill)
	if data.is_empty(): return
	var cd: float = float(state.skill_cooldowns.get(skill, 0.0))
	if cd > 0.0: return
	var cost: float = float(data.get("cost", 10.0))
	if state.player_mana < cost:
		state.add_notice("Not enough Mana")
		return
	state.player_mana -= cost
	state.skill_cooldowns[skill] = float(data.get("cooldown", 0.5))
	var dir: Vector2 = aim - state.player_pos
	if dir.length() < 0.01: dir = Vector2.RIGHT
	else: dir = dir.normalized()
	if skill == "Cleave" or skill == "Frost Nova" or skill == "Void Rift" or skill == "Blade Trap":
		var radius: float = 80.0
		if skill == "Frost Nova": radius = 145.0
		if skill == "Void Rift": radius = 100.0
		var center: Vector2 = aim if skill != "Frost Nova" else state.player_pos
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(center) <= radius:
				enemy.take_damage(float(data.get("damage", 20.0)))
		return
	var projectile: RVProjectileActor = projectile_scene.instantiate()
	projectile_root.add_child(projectile)
	projectile.setup(self, state.player_pos + dir * 26.0, dir * 620.0, float(data.get("damage", 20.0)), RVSkillDB.color(skill))

func _on_enemy_died(enemy: RVEnemyActor) -> void:
	state.kills += 1
	state.add_xp(10.0 + float(state.run_depth))
	state.gold += 2 + state.run_depth
	if state.rng.randf() < 0.20:
		state.materials["embers"] = int(state.materials.get("embers", 0)) + 1
	enemies.erase(enemy)
