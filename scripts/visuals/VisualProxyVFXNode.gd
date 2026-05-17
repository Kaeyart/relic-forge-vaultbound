class_name RVVisualProxyVFXNode
extends Node2D

# Patch 061-063: self-drawing transient 2D VFX node for proxy spell art.

var kind: String = "impact"
var lifetime: float = 0.45
var age: float = 0.0
var start_pos: Vector2 = Vector2.ZERO
var end_pos: Vector2 = Vector2.ZERO
var radius: float = 64.0
var color_a: Color = Color.WHITE
var color_b: Color = Color(1.0, 1.0, 1.0, 0.0)
var tags: Array = []
var direction: Vector2 = Vector2.RIGHT
var seed_offset: float = 0.0

func configure(data: Dictionary) -> void:
	kind = str(data.get("kind", kind))
	lifetime = float(data.get("lifetime", lifetime))
	global_position = data.get("pos", global_position)
	start_pos = data.get("start", global_position)
	end_pos = data.get("end", global_position)
	radius = float(data.get("radius", radius))
	color_a = data.get("color_a", color_a)
	color_b = data.get("color_b", color_b)
	tags = data.get("tags", []).duplicate(true)
	direction = data.get("direction", direction)
	if direction.length() <= 0.001:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	seed_offset = float(randi() % 1000) * 0.017
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t: float = clamp(age / max(0.001, lifetime), 0.0, 1.0)
	match kind:
		"fireball_cast":
			_draw_cast_burst(t, Color(1.0, 0.36, 0.08, 0.82), Color(1.0, 0.78, 0.28, 0.28))
		"fireball_impact":
			_draw_fire_impact(t)
		"storm_lance":
			_draw_beam(t, Color(0.55, 0.90, 1.0, 0.92), Color(0.88, 1.0, 1.0, 0.22))
		"storm_impact":
			_draw_spark_impact(t)
		"frost_nova":
			_draw_nova(t, Color(0.55, 0.88, 1.0, 0.82), Color(0.86, 0.97, 1.0, 0.18))
		"void_rift":
			_draw_void_rift(t)
		"cleave_arc":
			_draw_cleave(t)
		"blade_trap":
			_draw_trap(t)
		"hit_spark":
			_draw_hit_spark(t)
		_:
			_draw_generic_impact(t)

func _draw_cast_burst(t: float, c1: Color, c2: Color) -> void:
	var r: float = radius * (0.35 + t * 0.72)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(c1.r, c1.g, c1.b, (1.0 - t) * c1.a), 3.0)
	draw_circle(Vector2.ZERO, radius * 0.22 * (1.0 - t * 0.25), Color(c2.r, c2.g, c2.b, (1.0 - t) * 0.65))
	for i: int in range(8):
		var a: float = seed_offset + float(i) * TAU / 8.0
		var p1: Vector2 = Vector2(cos(a), sin(a)) * r * 0.20
		var p2: Vector2 = Vector2(cos(a), sin(a)) * r
		draw_line(p1, p2, Color(c1.r, c1.g, c1.b, (1.0 - t) * 0.55), 2.0)

func _draw_fire_impact(t: float) -> void:
	_draw_cast_burst(t, Color(1.0, 0.24, 0.04, 0.86), Color(1.0, 0.70, 0.22, 0.30))
	for i: int in range(10):
		var a: float = seed_offset + float(i) * TAU / 10.0 + t * 0.8
		var r1: float = radius * (0.15 + t * 0.58)
		var p: Vector2 = Vector2(cos(a), sin(a)) * r1
		draw_circle(p, max(1.5, 4.0 * (1.0 - t)), Color(1.0, 0.52, 0.12, (1.0 - t) * 0.70))

func _draw_beam(t: float, c1: Color, c2: Color) -> void:
	var local_end: Vector2 = end_pos - start_pos
	if local_end.length() <= 0.001:
		local_end = direction * radius * 3.0
	var pulse: float = sin((t + seed_offset) * TAU * 6.0) * 0.5 + 0.5
	draw_line(Vector2.ZERO, local_end, Color(c2.r, c2.g, c2.b, (1.0 - t) * 0.36), 10.0 + pulse * 3.0)
	draw_line(Vector2.ZERO, local_end, Color(c1.r, c1.g, c1.b, (1.0 - t) * 0.92), 3.0)
	for i: int in range(6):
		var f: float = float(i) / 5.0
		var base: Vector2 = local_end * f
		var off: Vector2 = local_end.normalized().orthogonal() * sin(seed_offset + t * 18.0 + f * 9.0) * 16.0
		draw_line(base, base + off, Color(0.90, 1.0, 1.0, (1.0 - t) * 0.55), 2.0)

func _draw_spark_impact(t: float) -> void:
	for i: int in range(12):
		var a: float = seed_offset + float(i) * TAU / 12.0
		var p2: Vector2 = Vector2(cos(a), sin(a)) * radius * (0.20 + t * 0.65)
		draw_line(Vector2.ZERO, p2, Color(0.72, 0.94, 1.0, (1.0 - t) * 0.82), 2.0)
	draw_circle(Vector2.ZERO, radius * 0.18 * (1.0 - t), Color(0.90, 1.0, 1.0, (1.0 - t) * 0.8))

func _draw_nova(t: float, c1: Color, c2: Color) -> void:
	for ring: int in range(3):
		var rr: float = radius * (0.26 + t * (0.72 + float(ring) * 0.12))
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 48, Color(c1.r, c1.g, c1.b, (1.0 - t) * (0.70 - float(ring) * 0.13)), 2.0)
	for i: int in range(14):
		var a: float = seed_offset + float(i) * TAU / 14.0
		var p: Vector2 = Vector2(cos(a), sin(a)) * radius * (0.28 + t * 0.62)
		var q: Vector2 = p + Vector2(cos(a), sin(a)) * 8.0
		draw_line(p, q, Color(0.86, 0.98, 1.0, (1.0 - t) * 0.72), 2.0)

func _draw_void_rift(t: float) -> void:
	var r: float = radius * (0.58 + sin(t * TAU) * 0.08)
	draw_circle(Vector2.ZERO, r, Color(0.08, 0.02, 0.12, 0.42 * (1.0 - t * 0.25)))
	draw_arc(Vector2.ZERO, r * (0.80 + t * 0.20), t * TAU, t * TAU + TAU * 0.78, 36, Color(0.75, 0.25, 1.0, (1.0 - t) * 0.82), 3.0)
	for i: int in range(10):
		var a: float = seed_offset + float(i) * TAU / 10.0 + t * 2.0
		var p1: Vector2 = Vector2(cos(a), sin(a)) * r * 1.10
		var p2: Vector2 = Vector2(cos(a), sin(a)) * r * 0.28
		draw_line(p1, p2, Color(0.55, 0.08, 0.90, (1.0 - t) * 0.52), 1.6)

func _draw_cleave(t: float) -> void:
	var start: float = -0.70 + t * 0.30
	var finish: float = 0.92 + t * 0.28
	var r: float = radius * (0.72 + t * 0.18)
	draw_arc(Vector2.ZERO, r, start, finish, 28, Color(1.0, 0.88, 0.62, (1.0 - t) * 0.80), 6.0)
	draw_arc(Vector2.ZERO, r * 0.78, start + 0.08, finish - 0.08, 28, Color(0.95, 0.15, 0.06, (1.0 - t) * 0.34), 3.0)

func _draw_trap(t: float) -> void:
	var r: float = radius * 0.58
	for i: int in range(6):
		var a1: float = float(i) * TAU / 6.0 + t * 1.8
		var a2: float = float(i + 1) * TAU / 6.0 + t * 1.8
		draw_line(Vector2(cos(a1), sin(a1)) * r, Vector2(cos(a2), sin(a2)) * r, Color(0.90, 0.78, 0.58, (1.0 - t) * 0.78), 2.0)
	for i2: int in range(3):
		var a: float = t * TAU * 3.5 + float(i2) * TAU / 3.0
		draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * r * 1.25, Color(0.92, 0.92, 0.90, (1.0 - t) * 0.68), 2.5)

func _draw_hit_spark(t: float) -> void:
	for i: int in range(7):
		var a: float = seed_offset + float(i) * TAU / 7.0
		var p: Vector2 = Vector2(cos(a), sin(a)) * radius * (0.20 + t * 0.65)
		draw_line(Vector2.ZERO, p, Color(1.0, 0.92, 0.70, (1.0 - t) * 0.82), 2.2)

func _draw_generic_impact(t: float) -> void:
	draw_arc(Vector2.ZERO, radius * (0.20 + t * 0.60), 0.0, TAU, 24, Color(color_a.r, color_a.g, color_a.b, (1.0 - t) * color_a.a), 2.0)


func _rv_find_combat_arena() -> Node:
	var current: Node = self
	while current != null:
		if current.has_method("resolve_projectile_segment"):
			return current
		current = current.get_parent()
	return null

func _rv_apply_projectile_collision(previous_pos: Vector2, current_pos: Vector2, delta: float) -> bool:
	var arena: Node = _rv_find_combat_arena()
	if arena == null or not arena.has_method("resolve_projectile_segment"):
		return false
	var velocity_value: Variant = get("velocity")
	var velocity: Vector2 = Vector2.ZERO
	if typeof(velocity_value) == TYPE_VECTOR2:
		velocity = Vector2(velocity_value)
	elif delta > 0.0:
		velocity = (current_pos - previous_pos) / delta
	var bounces: int = 0
	for key: String in ["bounces_remaining", "remaining_bounces", "bounce_count", "bounces"]:
		var bounce_value: Variant = get(key)
		if typeof(bounce_value) == TYPE_INT or typeof(bounce_value) == TYPE_FLOAT:
			bounces = int(bounce_value)
			break
	var result: Dictionary = Dictionary(arena.call("resolve_projectile_segment", previous_pos, current_pos, velocity, 5.0, bounces))
	if not bool(result.get("hit", false)):
		return false
	if bool(result.get("expired", false)):
		queue_free()
		return true
	global_position = Vector2(result.get("position", current_pos))
	if get("velocity") != null:
		set("velocity", Vector2(result.get("velocity", velocity)))
	for key: String in ["bounces_remaining", "remaining_bounces", "bounce_count", "bounces"]:
		if get(key) != null:
			set(key, int(result.get("bounces_remaining", 0)))
			break
	return true
