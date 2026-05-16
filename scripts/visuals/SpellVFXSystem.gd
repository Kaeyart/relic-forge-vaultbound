class_name RVSpellVFXSystem
extends RefCounted

# Patch 059: reusable Godot-native prototype VFX.
# Built from Line2D, Polygon2D, and simple animated nodes. No final art required.

static func emit_skill(arena: Node2D, root: Node2D, skill_name: String, origin: Vector2, aim: Vector2, direction: Vector2, skill_data: Dictionary, tags: Array) -> void:
	if root == null:
		return
	match skill_name:
		"Cleave":
			emit_slash(root, origin + direction * 58.0, direction.angle(), float(skill_data.get("radius", 76.0)), Color(0.90, 0.84, 0.66, 0.80))
		"Frost Nova":
			emit_nova(root, origin, float(skill_data.get("radius", 145.0)), Color(0.42, 0.86, 1.0, 0.62))
		"Void Rift":
			emit_rift(root, aim, float(skill_data.get("radius", 92.0)))
		"Blade Trap":
			emit_trap(root, aim, float(skill_data.get("radius", 64.0)))
		"Storm Lance":
			emit_lance(root, origin + direction * 18.0, aim, Color(0.55, 0.92, 1.0, 0.84))
		"Fireball":
			emit_projectile_hint(root, origin + direction * 24.0, aim, Color(1.0, 0.34, 0.08, 0.74))
		_:
			emit_projectile_hint(root, origin + direction * 24.0, aim, Color(0.88, 0.78, 0.48, 0.60))

static func emit_projectile_hint(root: Node2D, from: Vector2, to: Vector2, color: Color) -> void:
	var dir := to - from
	if dir.length() <= 1.0:
		dir = Vector2.RIGHT * 120.0
	var length := min(180.0, dir.length())
	var end := from + dir.normalized() * length
	var line := Line2D.new()
	line.name = "ProjectileTrailVFX"
	line.points = PackedVector2Array([from, end])
	line.width = 9.0
	line.default_color = Color(color.r, color.g, color.b, color.a * 0.42)
	root.add_child(line)
	var core := Polygon2D.new()
	core.name = "ProjectileCoreVFX"
	core.polygon = _circle(end, 11.0, 12)
	core.color = color
	root.add_child(core)
	_fade_and_free(line, 0.22)
	_fade_and_free(core, 0.22)

static func emit_lance(root: Node2D, from: Vector2, to: Vector2, color: Color) -> void:
	var dir := to - from
	if dir.length() <= 1.0:
		dir = Vector2.RIGHT * 320.0
	var end := from + dir.normalized() * min(420.0, dir.length())
	var beam := Line2D.new()
	beam.name = "StormLanceVFX"
	beam.points = PackedVector2Array([from, end])
	beam.width = 5.0
	beam.default_color = color
	root.add_child(beam)
	var outer := Line2D.new()
	outer.name = "StormLanceOuterVFX"
	outer.points = PackedVector2Array([from, end])
	outer.width = 13.0
	outer.default_color = Color(color.r, color.g, color.b, 0.18)
	root.add_child(outer)
	_fade_and_free(beam, 0.14)
	_fade_and_free(outer, 0.18)

static func emit_slash(root: Node2D, center: Vector2, angle: float, radius: float, color: Color) -> void:
	var arc := Line2D.new()
	arc.name = "CleaveArcVFX"
	var pts := PackedVector2Array()
	for i: int in range(14):
		var t := lerp(-0.82, 0.82, float(i) / 13.0)
		var a := angle + t
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	arc.points = pts
	arc.width = 8.0
	arc.default_color = color
	root.add_child(arc)
	_fade_and_free(arc, 0.18)

static func emit_nova(root: Node2D, center: Vector2, radius: float, color: Color) -> void:
	for ring_index: int in range(2):
		var ring := Line2D.new()
		ring.name = "FrostNovaRingVFX"
		var r := radius * (0.74 + 0.20 * ring_index)
		ring.points = _closed(_circle(center, r, 48))
		ring.width = 4.0 + float(ring_index) * 2.0
		ring.default_color = Color(color.r, color.g, color.b, color.a * (0.75 - ring_index * 0.25))
		root.add_child(ring)
		_fade_and_free(ring, 0.36 + ring_index * 0.05)

static func emit_rift(root: Node2D, center: Vector2, radius: float) -> void:
	var fill := Polygon2D.new()
	fill.name = "VoidRiftFillVFX"
	fill.polygon = _wobbly_circle(center, radius, 18, 0.18)
	fill.color = Color(0.18, 0.02, 0.30, 0.34)
	root.add_child(fill)
	var rim := Line2D.new()
	rim.name = "VoidRiftRimVFX"
	rim.points = _closed(fill.polygon)
	rim.width = 5.0
	rim.default_color = Color(0.70, 0.25, 1.0, 0.62)
	root.add_child(rim)
	for i: int in range(8):
		var a := float(i) * TAU / 8.0
		var pull := Line2D.new()
		pull.name = "VoidPullLineVFX"
		pull.points = PackedVector2Array([center + Vector2(cos(a), sin(a)) * radius, center + Vector2(cos(a), sin(a)) * radius * 0.35])
		pull.width = 2.0
		pull.default_color = Color(0.75, 0.32, 1.0, 0.40)
		root.add_child(pull)
		_fade_and_free(pull, 0.45)
	_fade_and_free(fill, 0.48)
	_fade_and_free(rim, 0.48)

static func emit_trap(root: Node2D, center: Vector2, radius: float) -> void:
	var plate := Polygon2D.new()
	plate.name = "BladeTrapPlateVFX"
	plate.polygon = _circle(center, radius * 0.62, 6)
	plate.color = Color(0.10, 0.10, 0.12, 0.62)
	root.add_child(plate)
	var blade1 := Line2D.new()
	blade1.name = "BladeTrapBladeA"
	blade1.points = PackedVector2Array([center + Vector2(-radius * 0.55, 0), center + Vector2(radius * 0.55, 0)])
	blade1.width = 5.0
	blade1.default_color = Color(0.78, 0.70, 0.62, 0.78)
	root.add_child(blade1)
	var blade2 := Line2D.new()
	blade2.name = "BladeTrapBladeB"
	blade2.points = PackedVector2Array([center + Vector2(0, -radius * 0.55), center + Vector2(0, radius * 0.55)])
	blade2.width = 5.0
	blade2.default_color = Color(0.78, 0.70, 0.62, 0.78)
	root.add_child(blade2)
	_fade_and_free(plate, 0.38)
	_fade_and_free(blade1, 0.38)
	_fade_and_free(blade2, 0.38)

static func emit_enemy_windup(root: Node2D, center: Vector2, radius: float, color: Color) -> void:
	if root == null:
		return
	var ring := Line2D.new()
	ring.name = "EnemyWindupVFX"
	ring.points = _closed(_circle(center, radius, 32))
	ring.width = 3.0
	ring.default_color = color
	root.add_child(ring)
	_fade_and_free(ring, 0.32)

static func _fade_and_free(node: CanvasItem, duration: float) -> void:
	if node == null:
		return
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, duration)
	tw.tween_callback(node.queue_free)

static func _circle(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in range(max(6, sides)):
		var a := float(i) * TAU / float(max(6, sides))
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts

static func _wobbly_circle(center: Vector2, radius: float, sides: int, wobble: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in range(max(6, sides)):
		var a := float(i) * TAU / float(max(6, sides))
		var r := radius * (1.0 + sin(float(i) * 2.37) * wobble)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts

static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array(points)
	if result.size() > 0:
		result.append(result[0])
	return result
