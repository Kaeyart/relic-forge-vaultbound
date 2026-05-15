class_name RVEnemyActor
extends Node2D

signal died(enemy: RVEnemyActor)
signal hit_player(amount: float)

var enemy_id: String = ""
var enemy_type: String = "Grunt"
var role: String = "chaser"
var hp: float = 50.0
var max_hp: float = 50.0
var speed: float = 80.0
var damage: float = 8.0
var radius: float = 15.0
var cooldown: float = 0.0
var enemy_color: Color = Color(0.75, 0.22, 0.14)

func setup(data: Dictionary) -> void:
	enemy_id = str(data.get("id", "enemy"))
	enemy_type = str(data.get("type", "Grunt"))
	role = str(data.get("role", "chaser"))
	global_position = data.get("pos", global_position)
	hp = float(data.get("hp", hp))
	max_hp = float(data.get("max_hp", hp))
	speed = float(data.get("speed", speed))
	damage = float(data.get("damage", damage))
	radius = float(data.get("radius", radius))
	enemy_color = data.get("color", enemy_color)
	queue_redraw()


func update_ai(player_pos: Vector2, delta: float) -> void:
	if hp <= 0.0:
		return

	cooldown = max(0.0, cooldown - delta)
	var direction: Vector2 = player_pos - global_position
	var distance: float = direction.length()

	if distance > 0.01:
		direction = direction / distance
	else:
		direction = Vector2.ZERO

	if role == "shooter":
		if distance < 250.0:
			global_position -= direction * speed * 0.65 * delta
		elif distance > 360.0:
			global_position += direction * speed * delta
	else:
		global_position += direction * speed * delta

	if distance <= radius + 18.0 and cooldown <= 0.0:
		hit_player.emit(damage)
		cooldown = 0.75

	queue_redraw()


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit(self)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(5.0, 9.0), radius * 1.12, Color(0.0, 0.0, 0.0, 0.34))
	if role == "brute":
		var points: PackedVector2Array = PackedVector2Array()
		for index: int in range(6):
			var angle: float = PI / 6.0 + float(index) * TAU / 6.0
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		draw_polygon(points, PackedColorArray([Color(0.030, 0.032, 0.038)]))
		var closed: PackedVector2Array = PackedVector2Array(points)
		closed.append(points[0])
		draw_polyline(closed, enemy_color, 2.0)
	else:
		draw_circle(Vector2.ZERO, radius, Color(0.030, 0.030, 0.036))
		draw_circle(Vector2.ZERO, radius * 0.68, enemy_color)

	var pct: float = clamp(hp / max(1.0, max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0, 4.0)), Color(0.08, 0.03, 0.03, 0.80), true)
	draw_rect(Rect2(Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0 * pct, 4.0)), Color(0.90, 0.18, 0.12), true)
