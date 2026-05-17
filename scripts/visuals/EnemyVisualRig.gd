class_name RVEnemyVisualRig
extends Node2D

# Patch 061-063A: parser-safe animated enemy visual proxy rig.
# This file intentionally avoids nested ternaries and unsafe Variant typed assignments.

var enemy_type: String = "Grunt"
var role: String = "chaser"
var radius: float = 16.0
var profile: Dictionary = {}
var visual_state: String = "idle"
var move_direction: Vector2 = Vector2.RIGHT
var time: float = 0.0
var hit_flash: float = 0.0
var death_t: float = 0.0
var is_dead: bool = false
var elite: bool = false
var boss: bool = false
var hp_ratio: float = 1.0

func configure(new_enemy_type: String, new_role: String, new_radius: float, fallback_color: Color = Color(0.75, 0.22, 0.14)) -> void:
	enemy_type = new_enemy_type
	role = new_role
	radius = max(8.0, new_radius)
	profile = RVEnemyShapeKitDB.profile(enemy_type, role)
	if fallback_color != Color(0.75, 0.22, 0.14):
		profile["accent"] = fallback_color
	elite = str(enemy_type).to_lower().find("elite") >= 0
	var marker: String = str(profile.get("role_marker", ""))
	boss = marker == "boss" or str(role).to_lower() == "boss" or str(enemy_type).to_lower().find("boss") >= 0
	queue_redraw()

func set_visual_state(new_state: String, velocity: Vector2 = Vector2.ZERO) -> void:
	visual_state = new_state
	if velocity.length() > 0.01:
		move_direction = velocity.normalized()
	queue_redraw()

func set_hp_ratio(value: float) -> void:
	hp_ratio = clamp(value, 0.0, 1.0)
	queue_redraw()

func pulse_hit() -> void:
	hit_flash = 0.16
	queue_redraw()

func play_death() -> void:
	is_dead = true
	death_t = 0.001
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta)
	if is_dead:
		death_t = min(1.0, death_t + delta * 3.0)
	queue_redraw()

func _draw() -> void:
	if profile.is_empty():
		profile = RVEnemyShapeKitDB.profile(enemy_type, role)

	var scale_profile: float = float(profile.get("scale", 1.0))
	var r: float = radius * scale_profile
	var alpha: float = 1.0 - death_t
	if alpha <= 0.02:
		return

	var bob: float = _state_bob()
	if is_dead:
		bob += death_t * 8.0

	_draw_shadow(r, alpha)

	var shape: String = str(profile.get("shape", "grunt"))
	match shape:
		"lunger":
			_draw_lunger(r, bob, alpha)
		"spitter":
			_draw_spitter(r, bob, alpha)
		"binder":
			_draw_binder(r, bob, alpha)
		"brute":
			_draw_brute(r, bob, alpha)
		"caller":
			_draw_caller(r, bob, alpha)
		"knight":
			_draw_knight(r, bob, alpha)
		"boss":
			_draw_boss(r, bob, alpha)
		_:
			_draw_grunt(r, bob, alpha)

	_draw_role_marker(r, alpha)
	_draw_state_telegraph(r, alpha)
	if hit_flash > 0.0:
		_draw_hit_flash(r)
	if elite or boss:
		_draw_elite_ring(r, alpha)

func _state_bob() -> float:
	if visual_state == "idle":
		return sin(time * 2.7) * 0.6
	if visual_state == "windup":
		return -2.0 + sin(time * 12.0) * 0.7
	if visual_state == "attack":
		return 2.5
	if visual_state == "recover":
		return 0.8
	return sin(time * 6.0) * 1.2

func _c(name: String, fallback: Color = Color(1.0, 1.0, 1.0, 1.0), alpha_mul: float = 1.0) -> Color:
	var value: Variant = profile.get(name, fallback)
	var c: Color = fallback
	if typeof(value) == TYPE_COLOR:
		c = value
	c.a *= alpha_mul
	return c

func _poly(points: Array, color: Color, offset: Vector2 = Vector2.ZERO, rot: float = 0.0, sx: float = 1.0, sy: float = 1.0) -> void:
	var arr: PackedVector2Array = PackedVector2Array()
	for p_value: Variant in points:
		if typeof(p_value) != TYPE_VECTOR2:
			continue
		var p: Vector2 = p_value
		var q: Vector2 = Vector2(p.x * sx, p.y * sy).rotated(rot) + offset
		arr.append(q)
	if arr.size() < 3:
		return
	draw_colored_polygon(arr, color)
	var closed: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in arr:
		closed.append(point)
	closed.append(arr[0])
	draw_polyline(closed, _c("outline", Color(0.0, 0.0, 0.0, 1.0), color.a), float(profile.get("outline_width", 2.0)))

func _draw_shadow(r: float, alpha: float) -> void:
	var shadow_scale: Vector2 = Vector2(1.2, 0.38)
	var shadow_value: Variant = profile.get("shadow_scale", shadow_scale)
	if typeof(shadow_value) == TYPE_VECTOR2:
		shadow_scale = shadow_value
	var w: float = r * shadow_scale.x * (1.0 - death_t * 0.35)
	var h: float = r * shadow_scale.y * (1.0 - death_t * 0.50)
	_draw_ellipse(Rect2(Vector2(-w, r * 0.44 - h * 0.5), Vector2(w * 2.0, h)), Color(0.0, 0.0, 0.0, 0.34 * alpha))

func _draw_ellipse(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = rect.position + rect.size * 0.5
	for i: int in range(28):
		var a: float = float(i) * TAU / 28.0
		points.append(center + Vector2(cos(a) * rect.size.x * 0.5, sin(a) * rect.size.y * 0.5))
	draw_colored_polygon(points, color)

func _draw_grunt(r: float, bob: float, alpha: float) -> void:
	var body: Array = [Vector2(-0.55, 0.40), Vector2(-0.72, -0.20), Vector2(-0.25, -0.72), Vector2(0.42, -0.54), Vector2(0.66, 0.22), Vector2(0.18, 0.62)]
	_poly(_scale(body, r), _c("body", Color(0.28, 0.28, 0.30), alpha), Vector2(0.0, bob))
	_poly(_scale([Vector2(-0.22, -0.80), Vector2(0.24, -0.76), Vector2(0.34, -0.40), Vector2(-0.14, -0.32)], r), _c("mid", Color(0.50, 0.50, 0.52), alpha), Vector2(0.0, bob))
	_poly(_scale([Vector2(0.50, -0.18), Vector2(1.10, -0.34), Vector2(0.86, 0.10), Vector2(0.52, 0.24)], r), _c("accent", Color(1.0, 0.45, 0.08), alpha), Vector2(0.0, bob))
	draw_circle(Vector2(0.0, bob), r * 0.16, _c("accent", Color(1.0, 0.45, 0.08), 0.72 * alpha))

func _draw_lunger(r: float, bob: float, alpha: float) -> void:
	var lean: float = 0.0
	if visual_state == "windup":
		lean = 0.18
	elif visual_state == "attack":
		lean = -0.10
	_poly(_scale([Vector2(-0.88, 0.36), Vector2(-0.52, -0.40), Vector2(0.25, -0.54), Vector2(0.96, 0.02), Vector2(0.22, 0.46)], r), _c("body", Color(0.28, 0.28, 0.30), alpha), Vector2(0.0, bob), lean)
	_poly(_scale([Vector2(0.42, -0.12), Vector2(1.36, -0.04), Vector2(0.42, 0.08)], r), _c("accent", Color(1.0, 0.82, 0.20), alpha), Vector2(0.0, bob), lean)
	draw_line(Vector2(-r * 0.7, bob + r * 0.32), Vector2(r * 1.2, bob + r * 0.04), _c("accent", Color(1.0, 0.82, 0.20), 0.72 * alpha), 3.0)

func _draw_spitter(r: float, bob: float, alpha: float) -> void:
	_poly(_scale([Vector2(-0.78, 0.44), Vector2(-0.60, -0.26), Vector2(0.06, -0.58), Vector2(0.74, -0.22), Vector2(0.66, 0.48), Vector2(-0.10, 0.68)], r), _c("body", Color(0.28, 0.28, 0.30), alpha), Vector2(0.0, bob))
	draw_circle(Vector2(r * 0.28, bob - r * 0.20), r * 0.34, _c("mid", Color(1.0, 0.45, 0.08), 0.86 * alpha))
	draw_circle(Vector2(r * 0.45, bob - r * 0.24), r * 0.13, _c("accent", Color(1.0, 0.82, 0.20), alpha))
	for i: int in range(3):
		draw_line(Vector2(-r * 0.34 + float(i) * r * 0.18, bob + r * 0.28), Vector2(-r * 0.50 + float(i) * r * 0.18, bob + r * 0.58), _c("outline", Color.BLACK, alpha), 2.0)

func _draw_binder(r: float, bob: float, alpha: float) -> void:
	_poly(_scale([Vector2(-0.38, 0.64), Vector2(-0.50, -0.54), Vector2(0.0, -1.0), Vector2(0.50, -0.54), Vector2(0.38, 0.64)], r), _c("body", Color(0.58, 0.24, 0.88), alpha), Vector2(0.0, bob))
	draw_arc(Vector2(0.0, bob - r * 0.58), r * 0.58, 0.12 + time, TAU - 0.12 + time, 32, _c("accent", Color(0.58, 0.24, 0.88), 0.76 * alpha), 2.0)
	draw_line(Vector2(-r * 0.76, bob + r * 0.28), Vector2(r * 0.72, bob - r * 0.32), _c("mid", Color(0.58, 0.24, 0.88), alpha), 3.0)
	for i: int in range(4):
		var a: float = time + float(i) * TAU / 4.0
		draw_circle(Vector2(cos(a), sin(a)) * r * 0.56 + Vector2(0.0, bob - r * 0.58), r * 0.05, _c("accent", Color(0.58, 0.24, 0.88), alpha))

func _draw_brute(r: float, bob: float, alpha: float) -> void:
	_poly(_scale([Vector2(-0.88, 0.42), Vector2(-0.72, -0.66), Vector2(0.0, -0.92), Vector2(0.80, -0.60), Vector2(0.92, 0.44), Vector2(0.30, 0.74), Vector2(-0.42, 0.70)], r), _c("body", Color(0.28, 0.28, 0.30), alpha), Vector2(0.0, bob))
	draw_rect(Rect2(Vector2(-r * 0.36, bob - r * 0.28), Vector2(r * 0.72, r * 0.48)), _c("mid", Color(0.95, 0.12, 0.06), 0.92 * alpha), true)
	draw_line(Vector2(-r * 0.95, bob + r * 0.08), Vector2(-r * 1.32, bob + r * 0.42), _c("accent", Color(1.0, 0.45, 0.08), alpha), 5.0)
	draw_line(Vector2(r * 0.92, bob + r * 0.08), Vector2(r * 1.28, bob + r * 0.42), _c("accent", Color(1.0, 0.45, 0.08), alpha), 5.0)

func _draw_caller(r: float, bob: float, alpha: float) -> void:
	_poly(_scale([Vector2(-0.44, 0.62), Vector2(-0.34, -0.58), Vector2(0.0, -0.96), Vector2(0.34, -0.58), Vector2(0.44, 0.62)], r), _c("body", Color(0.34, 0.22, 0.14), alpha), Vector2(0.0, bob))
	_poly(_scale([Vector2(-0.52, -0.28), Vector2(0.52, -0.28), Vector2(0.34, 0.18), Vector2(-0.34, 0.18)], r), _c("mid", Color(0.86, 0.55, 0.18), 0.72 * alpha), Vector2(0.0, bob))
	draw_arc(Vector2(0.0, bob - r * 0.95), r * 0.40, 0.0, TAU, 28, _c("accent", Color(1.0, 0.74, 0.18), 0.82 * alpha), 3.0)
	draw_line(Vector2(0.0, bob - r * 0.56), Vector2(0.0, bob + r * 0.52), _c("accent", Color(1.0, 0.74, 0.18), alpha), 3.0)

func _draw_knight(r: float, bob: float, alpha: float) -> void:
	_poly(_scale([Vector2(-0.58, 0.48), Vector2(-0.48, -0.58), Vector2(0.0, -0.88), Vector2(0.48, -0.58), Vector2(0.58, 0.48), Vector2(0.0, 0.76)], r), _c("body", Color(0.30, 0.34, 0.38), alpha), Vector2(0.0, bob))
	_poly(_scale([Vector2(-0.32, -0.26), Vector2(0.34, -0.26), Vector2(0.22, 0.28), Vector2(-0.22, 0.28)], r), _c("mid", Color(0.50, 0.50, 0.52), alpha), Vector2(0.0, bob))
	draw_line(Vector2(r * 0.62, bob - r * 0.42), Vector2(r * 1.12, bob + r * 0.50), _c("accent", Color(0.86, 0.76, 0.58), alpha), 4.0)
	draw_line(Vector2(-r * 0.60, bob + r * 0.28), Vector2(-r * 0.96, bob - r * 0.18), _c("mid", Color(0.50, 0.50, 0.52), alpha), 4.0)

func _draw_boss(r: float, bob: float, alpha: float) -> void:
	_draw_brute(r, bob, alpha)
	draw_arc(Vector2(0.0, bob), r * (1.15 + sin(time * 2.0) * 0.04), 0.0, TAU, 48, _c("accent", Color(0.95, 0.12, 0.06), 0.42 * alpha), 4.0)
	for i: int in range(6):
		var a: float = float(i) * TAU / 6.0 + time * 0.35
		var p1: Vector2 = Vector2(cos(a), sin(a)) * r * 1.18 + Vector2(0.0, bob)
		var p2: Vector2 = Vector2(cos(a), sin(a)) * r * 1.45 + Vector2(0.0, bob)
		draw_line(p1, p2, _c("accent", Color(0.95, 0.12, 0.06), 0.72 * alpha), 3.0)

func _draw_state_telegraph(r: float, alpha: float) -> void:
	if visual_state == "windup":
		var pulse: float = 0.55 + sin(time * 16.0) * 0.18
		draw_arc(Vector2.ZERO, r * (1.10 + pulse * 0.20), 0.0, TAU, 36, _c("telegraph", Color(1.0, 0.45, 0.08), alpha * 0.90), 4.0)
		var dir: Vector2 = _safe_move_dir()
		draw_line(Vector2.ZERO, dir * r * 1.55, _c("telegraph", Color(1.0, 0.45, 0.08), alpha * 0.72), 3.0)
	elif visual_state == "attack":
		var dir2: Vector2 = _safe_move_dir()
		draw_line(-dir2 * r * 0.25, dir2 * r * 1.35, _c("accent", Color.WHITE, alpha * 0.75), 4.0)

func _safe_move_dir() -> Vector2:
	if move_direction.length() > 0.01:
		return move_direction.normalized()
	return Vector2.RIGHT

func _draw_role_marker(r: float, alpha: float) -> void:
	var marker: String = str(profile.get("role_marker", ""))
	var y: float = -r * 1.38
	match marker:
		"charge":
			_poly([Vector2(-5, y + 5), Vector2(0, y - 6), Vector2(5, y + 5)], _c("accent", Color(1.0, 0.82, 0.20), 0.78 * alpha))
		"ranged":
			draw_arc(Vector2(0.0, y), 7.0, -0.4, PI + 0.4, 18, _c("accent", Color(1.0, 0.82, 0.20), 0.78 * alpha), 2.0)
		"caster":
			draw_arc(Vector2(0.0, y), 7.0, 0.0, TAU, 20, _c("accent", Color(0.58, 0.24, 0.88), 0.78 * alpha), 2.0)
		"summon":
			draw_line(Vector2(-6, y + 5), Vector2(6, y + 5), _c("accent", Color(1.0, 0.74, 0.18), 0.78 * alpha), 2.0)
			draw_arc(Vector2(0.0, y), 6.0, 0.0, TAU, 18, _c("accent", Color(1.0, 0.74, 0.18), 0.78 * alpha), 2.0)
		"boss":
			draw_arc(Vector2(0.0, y), 9.0, 0.0, TAU, 24, _c("accent", Color(0.95, 0.12, 0.06), 0.92 * alpha), 2.8)
		_:
			draw_line(Vector2(-5, y + 5), Vector2(5, y - 5), _c("accent", Color(1.0, 0.45, 0.08), 0.55 * alpha), 2.0)

func _draw_elite_ring(r: float, alpha: float) -> void:
	var c: Color = _c("accent", Color(1.0, 0.74, 0.18), 0.46 * alpha)
	draw_arc(Vector2.ZERO, r * (1.25 + sin(time * 3.0) * 0.03), 0.0, TAU, 48, c, 3.0)

func _draw_hit_flash(r: float) -> void:
	var a: float = clamp(hit_flash / 0.16, 0.0, 1.0)
	draw_circle(Vector2.ZERO, r * 0.90, Color(1.0, 0.96, 0.82, a * 0.38))

func _scale(points: Array, amount: float) -> Array:
	var result: Array = []
	for p_value: Variant in points:
		if typeof(p_value) == TYPE_VECTOR2:
			var p: Vector2 = p_value
			result.append(p * amount)
	return result
