class_name RVProjectileActor
extends Node2D

var velocity: Vector2 = Vector2.RIGHT * 500.0
var damage: float = 10.0
var radius: float = 7.0
var lifetime: float = 0.8
var from_enemy: bool = false
var tags: Array = []
var projectile_color: Color = Color(1.0, 0.65, 0.25)

func setup(pos: Vector2, vel: Vector2, amount: float, projectile_radius: float, tag_list: Array, enemy_owned: bool) -> void:
	global_position = pos
	velocity = vel
	damage = amount
	radius = projectile_radius
	tags = tag_list.duplicate(true)
	from_enemy = enemy_owned
	projectile_color = _color_from_tags(tags)
	queue_redraw()


func _process(delta: float) -> void:
	lifetime -= delta
	global_position += velocity * delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 2.0, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.18))
	draw_circle(Vector2.ZERO, radius, projectile_color)


func _color_from_tags(tag_list: Array) -> Color:
	if tag_list.has("Fire"):
		return Color(1.0, 0.34, 0.10)
	if tag_list.has("Cold"):
		return Color(0.44, 0.82, 1.0)
	if tag_list.has("Lightning"):
		return Color(0.72, 0.92, 1.0)
	if tag_list.has("Void"):
		return Color(0.68, 0.34, 1.0)
	if tag_list.has("Trap"):
		return Color(0.94, 0.70, 0.28)
	return Color(1.0, 0.78, 0.42)
