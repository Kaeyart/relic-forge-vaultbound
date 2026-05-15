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
var statuses: Dictionary = {}
var dot_tick: float = 0.0

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
	statuses.clear()
	queue_redraw()

func _process(delta: float) -> void:
	_update_statuses(delta)

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
	var speed_mult: float = 1.0
	if has_status("freeze"):
		speed_mult *= 0.30
	if has_status("shock"):
		speed_mult *= 0.86
	if has_status("curse"):
		speed_mult *= 0.92
	var actual_speed: float = speed * speed_mult
	if role == "shooter":
		if distance < 250.0:
			global_position -= direction * actual_speed * 0.65 * delta
		elif distance > 360.0:
			global_position += direction * actual_speed * delta
	else:
		global_position += direction * actual_speed * delta
	if distance <= radius + 18.0 and cooldown <= 0.0:
		hit_player.emit(damage)
		cooldown = 0.75
	queue_redraw()

func take_damage(amount: float) -> void:
	var final_amount: float = amount
	if has_status("curse"):
		final_amount *= 1.16
	if has_status("shock"):
		final_amount *= 1.08
	hp -= final_amount
	if hp <= 0.0:
		died.emit(self)
	queue_redraw()

func apply_status(status_id: String, duration: float, power: float = 1.0) -> void:
	if status_id == "":
		return
	var current: Dictionary = statuses.get(status_id, {})
	current["time"] = max(float(current.get("time", 0.0)), duration)
	current["power"] = max(float(current.get("power", 0.0)), power)
	statuses[status_id] = current
	queue_redraw()

func has_status(status_id: String) -> bool:
	if not statuses.has(status_id):
		return false
	return float(Dictionary(statuses[status_id]).get("time", 0.0)) > 0.0

func pull_toward(center: Vector2, amount: float) -> void:
	var direction: Vector2 = center - global_position
	if direction.length() <= 0.01:
		return
	global_position += direction.normalized() * amount

func _update_statuses(delta: float) -> void:
	if statuses.is_empty():
		return
	dot_tick -= delta
	var do_dot: bool = false
	if dot_tick <= 0.0:
		dot_tick = 0.35
		do_dot = true
	var to_remove: Array[String] = []
	for status_id: Variant in statuses.keys():
		var status: Dictionary = statuses[status_id]
		status["time"] = max(0.0, float(status.get("time", 0.0)) - delta)
		if do_dot:
			var power: float = float(status.get("power", 1.0))
			match str(status_id):
				"burn": hp -= 1.8 * power
				"bleed": hp -= 1.3 * power
		if float(status.get("time", 0.0)) <= 0.0:
			to_remove.append(str(status_id))
		else:
			statuses[status_id] = status
	for status_name: String in to_remove:
		statuses.erase(status_name)
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
	_draw_status_rings()
	var pct: float = clamp(hp / max(1.0, max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0, 4.0)), Color(0.08, 0.03, 0.03, 0.80), true)
	draw_rect(Rect2(Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0 * pct, 4.0)), Color(0.90, 0.18, 0.12), true)

func _draw_status_rings() -> void:
	var ring_radius: float = radius + 4.0
	if has_status("burn"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(1.0, 0.28, 0.05, 0.75), 2.0)
		ring_radius += 3.0
	if has_status("freeze"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.45, 0.85, 1.0, 0.72), 2.0)
		ring_radius += 3.0
	if has_status("curse"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.70, 0.26, 1.0, 0.72), 2.0)
		ring_radius += 3.0
	if has_status("bleed"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.72, 0.02, 0.02, 0.72), 2.0)
		ring_radius += 3.0
	if has_status("shock"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.75, 0.95, 1.0, 0.72), 2.0)
