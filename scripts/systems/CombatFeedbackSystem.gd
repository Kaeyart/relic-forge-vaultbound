class_name RVCombatFeedbackSystem
extends RefCounted

# Patch 064: Godot-native combat feedback layer.
# This is intentionally lightweight: labels, lines, circles, and tweens.
# Final art/sound can replace these calls later without changing combat logic.

static func enemy_hit(arena: Node2D, root: Node2D, enemy: Node2D, amount: float, tags: Array = []) -> void:
	if enemy == null or root == null:
		return
	var pos: Vector2 = enemy.global_position
	var color: Color = _color_for_tags(tags)
	_spawn_damage_text(root, pos + Vector2(randf_range(-10.0, 10.0), -42.0), str(int(round(amount))), color)
	_spawn_impact_burst(root, pos, color, 18.0, 0.22)
	_spawn_hit_ring(root, pos, color, 18.0, 34.0, 0.18)
	if enemy.has_method("flash_hit"):
		enemy.call("flash_hit")

static func enemy_death(arena: Node2D, root: Node2D, enemy_pos: Vector2, tags: Array = []) -> void:
	if root == null:
		return
	var color: Color = _color_for_tags(tags)
	_spawn_hit_ring(root, enemy_pos, Color(color.r, color.g, color.b, 0.85), 22.0, 58.0, 0.30)
	for i: int in range(7):
		_spawn_spark(root, enemy_pos, color, randf_range(18.0, 56.0), randf_range(0.16, 0.34))

static func skill_cast_feedback(arena: Node2D, root: Node2D, skill_name: String, origin: Vector2, aim: Vector2, direction: Vector2, skill_data: Dictionary, tags: Array = []) -> void:
	if root == null:
		return
	var color: Color = _color_for_skill(skill_name, tags)
	match skill_name:
		"Fireball":
			_spawn_hit_ring(root, origin, Color(color.r, color.g, color.b, 0.45), 10.0, 26.0, 0.16)
			_spawn_line(root, origin, origin + direction.normalized() * 42.0, color, 4.0, 0.14)
		"Storm Lance":
			_spawn_line(root, origin, aim, Color(0.72, 0.92, 1.0, 0.88), 3.0, 0.16)
			_spawn_line(root, origin + Vector2(-2.0, 2.0), aim + Vector2(2.0, -2.0), Color(0.30, 0.70, 1.0, 0.55), 1.5, 0.18)
		"Frost Nova":
			_spawn_hit_ring(root, origin, Color(0.45, 0.88, 1.0, 0.60), 28.0, float(skill_data.get("radius", 130.0)), 0.24)
		"Void Rift":
			_spawn_hit_ring(root, aim, Color(0.62, 0.24, 1.0, 0.55), 16.0, float(skill_data.get("radius", 90.0)), 0.36)
			for i: int in range(6):
				var angle: float = TAU * float(i) / 6.0
				_spawn_line(root, aim + Vector2(cos(angle), sin(angle)) * 68.0, aim, Color(0.45, 0.10, 0.75, 0.45), 2.0, 0.32)
		"Cleave":
			_spawn_arc_proxy(root, origin + direction.normalized() * 38.0, direction.angle(), Color(1.0, 0.82, 0.42, 0.78), 66.0, 0.18)
		"Blade Trap":
			_spawn_hit_ring(root, aim, Color(0.95, 0.68, 0.24, 0.50), 10.0, float(skill_data.get("radius", 64.0)), 0.28)
		_:
			_spawn_hit_ring(root, origin, color, 10.0, 24.0, 0.15)

static func enemy_windup(root: Node2D, pos: Vector2, radius: float, color: Color, duration: float = 0.25) -> void:
	if root == null:
		return
	_spawn_hit_ring(root, pos, Color(color.r, color.g, color.b, 0.38), max(8.0, radius * 0.6), max(22.0, radius * 1.8), duration)

static func _spawn_damage_text(root: Node2D, pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.z_index = 900
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position", pos + Vector2(0.0, -26.0), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.34)
	tween.tween_callback(label.queue_free)

static func _spawn_impact_burst(root: Node2D, pos: Vector2, color: Color, radius: float, life: float) -> void:
	for i: int in range(5):
		_spawn_spark(root, pos, color, radius * randf_range(0.8, 1.8), life * randf_range(0.75, 1.15))

static func _spawn_spark(root: Node2D, pos: Vector2, color: Color, distance: float, life: float) -> void:
	var line := Line2D.new()
	line.width = randf_range(1.5, 3.2)
	line.default_color = color
	line.z_index = 850
	var angle: float = randf_range(0.0, TAU)
	var end: Vector2 = pos + Vector2(cos(angle), sin(angle)) * distance
	line.points = PackedVector2Array([pos, pos.lerp(end, 0.45)])
	root.add_child(line)
	var tween: Tween = line.create_tween()
	tween.tween_property(line, "points", PackedVector2Array([pos.lerp(end, 0.35), end]), life)
	tween.parallel().tween_property(line, "modulate:a", 0.0, life)
	tween.tween_callback(line.queue_free)

static func _spawn_hit_ring(root: Node2D, pos: Vector2, color: Color, from_radius: float, to_radius: float, life: float) -> void:
	var ring := Node2D.new()
	ring.z_index = 820
	ring.set_meta("from_radius", from_radius)
	ring.set_meta("to_radius", to_radius)
	ring.set_meta("color", color)
	ring.set_script(_RingDrawScript.new())
	ring.global_position = pos
	root.add_child(ring)
	var tween: Tween = ring.create_tween()
	tween.tween_method(func(v: float) -> void:
		ring.set_meta("t", v)
		ring.queue_redraw()
	, 0.0, 1.0, life)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, life)
	tween.tween_callback(ring.queue_free)

static func _spawn_line(root: Node2D, a: Vector2, b: Vector2, color: Color, width: float, life: float) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([a, b])
	line.default_color = color
	line.width = width
	line.z_index = 780
	root.add_child(line)
	var tween: Tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, life)
	tween.tween_callback(line.queue_free)

static func _spawn_arc_proxy(root: Node2D, pos: Vector2, angle: float, color: Color, radius: float, life: float) -> void:
	var line := Line2D.new()
	line.default_color = color
	line.width = 6.0
	line.z_index = 790
	var pts := PackedVector2Array()
	for i: int in range(9):
		var t: float = -0.75 + 1.5 * float(i) / 8.0
		var a: float = angle + t
		pts.append(pos + Vector2(cos(a), sin(a)) * radius)
	line.points = pts
	root.add_child(line)
	var tween: Tween = line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, life)
	tween.tween_callback(line.queue_free)

static func _color_for_skill(skill_name: String, tags: Array = []) -> Color:
	match skill_name:
		"Fireball": return Color(1.0, 0.32, 0.08, 0.90)
		"Storm Lance": return Color(0.70, 0.92, 1.0, 0.90)
		"Frost Nova": return Color(0.45, 0.88, 1.0, 0.90)
		"Void Rift": return Color(0.62, 0.24, 1.0, 0.90)
		"Cleave": return Color(1.0, 0.78, 0.42, 0.90)
		"Blade Trap": return Color(0.94, 0.68, 0.24, 0.90)
	return _color_for_tags(tags)

static func _color_for_tags(tags: Array) -> Color:
	if tags.has("Fire") or tags.has("Burn"):
		return Color(1.0, 0.34, 0.08, 0.92)
	if tags.has("Cold") or tags.has("Freeze"):
		return Color(0.52, 0.88, 1.0, 0.92)
	if tags.has("Lightning") or tags.has("Shock"):
		return Color(0.75, 0.95, 1.0, 0.92)
	if tags.has("Void") or tags.has("Curse"):
		return Color(0.72, 0.30, 1.0, 0.92)
	if tags.has("Bleed") or tags.has("Physical"):
		return Color(1.0, 0.72, 0.42, 0.92)
	return Color(0.95, 0.86, 0.62, 0.90)

class _RingDrawScript:
	extends Node2D
	func _draw() -> void:
		var t: float = float(get_meta("t", 0.0))
		var from_radius: float = float(get_meta("from_radius", 10.0))
		var to_radius: float = float(get_meta("to_radius", 32.0))
		var color: Color = Color(get_meta("color", Color.WHITE))
		var r: float = lerp(from_radius, to_radius, t)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, color, max(1.0, 4.0 * (1.0 - t)))
