class_name RVProjectileActor
extends Node2D

@export var radius: float = 8.0
var velocity: Vector2 = Vector2.RIGHT * 520.0
var damage: float = 20.0
var lifetime: float = 1.0
var arena: RVCombatArena

func setup(p_arena: RVCombatArena, pos: Vector2, vel: Vector2, amount: float, _color: Color) -> void:
	arena = p_arena
	global_position = pos
	velocity = vel
	damage = amount

func _process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if arena == null:
		return
	for enemy in arena.enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= radius + enemy.radius:
			enemy.take_damage(damage)
			queue_free()
			return
