class_name RVSpellVFXSystem
extends RefCounted

# Patch 060: more readable Godot-native prototype spell VFX.
# Uses CanvasItem primitives only: Line2D + Polygon2D + tweens.

static func emit_skill(arena: Node2D, root: Node2D, skill_name: String, origin: Vector2, aim: Vector2, direction: Vector2, skill_data: Dictionary, tags: Array) -> void:
	if root == null:
		return
	var dir: Vector2 = direction.normalized() if direction.length() > 0.1 else (aim - origin).normalized()
	if dir.length() <= 0.1:
		dir = Vector2.RIGHT
	match skill_name:
		"Cleave":
			emit_cleave(root, origin + dir * 50.0, dir.angle(), float(skill_data.get("radius", 76.0)))
		"Frost Nova":
			emit_frost_nova(root, origin, float(skill_data.get("radius", 145.0)))
		"Void Rift":
			emit_void_rift(root, aim, float(skill_data.get("radius", 92.0)))
		"Blade Trap":
			emit_blade_trap(root, aim, float(skill_data.get("radius", 64.0)))
		"Storm Lance":
			emit_storm_lance(root, origin + dir * 18.0, aim)
		"Fireball":
			emit_fireball_cast(root, origin + dir * 24.0, aim)
		_:
			emit_projectile_hint(root, origin + dir * 24.0, aim, Color(0.88, 0.78, 0.48, 0.62))

static func emit_fireball_cast(root: Node2D, from: Vector2, to: Vector2) -> void:
	var color: Color = Color(1.0, 0.32, 0.06, 0.80)
	var dir: Vector2 = to - from
	if dir.length() <= 1.0:
		dir = Vector2.RIGHT * 160.0
	var end: Vector2 = from + dir.normalized() * min(190.0, dir.length())
	_emit_trail(root, from, end, color, 12.0, 0.24)
	_add_poly(root, "FireballCore", _circle(end, 12.0, 16), color, 35, 0.26)
	_add_poly(root, "FireballImpactRing", _circle(end, 31.0, 28), Color(1.0, 0.22, 0.04, 0.18), 31, 0.22, true)
	for i: int in range(8):
		var a: float = float(i) * TAU / 8.0
		_emit_line(root, "FireEmber", end + Vector2(cos(a), sin(a)) * 8.0, end + Vector2(cos(a), sin(a)) * 34.0, Color(1.0, 0.55, 0.10, 0.55), 2.0, 0.22)

static func emit_storm_lance(root: Node2D, from: Vector2, to: Vector2) -> void:
	var dir: Vector2 = to - from
	if dir.length() <= 1.0:
		dir = Vector2.RIGHT * 360.0
	var end: Vector2 = from + dir.normalized() * min(440.0, dir.length())
	_emit_line(root, "StormLanceOuter", from, end, Color(0.45, 0.90, 1.0, 0.20), 18.0, 0.16)
	_emit_line(root, "StormLanceCore", from, end, Color(0.75, 0.98, 1.0, 0.92), 4.5, 0.13)
	var normal: Vector2 = dir.normalized().orthogonal()
	for i: int in range(4):
		var t: float = float(i + 1) / 5.0
		var p: Vector2 = from.lerp(end, t)
		var jitter: float = 16.0 if i % 2 == 0 else -16.0
		_emit_line(root, "StormFork", p, p + normal * jitter, Color(0.55, 0.90, 1.0, 0.62), 2.4, 0.15)
	_add_poly(root, "StormImpact", _circle(end, 15.0, 10), Color(0.75, 0.98, 1.0, 0.55), 34, 0.16)

static func emit_cleave(root: Node2D, center: Vector2, angle: float, radius: float) -> void:
	var arc: Line2D = Line2D.new()
	arc.name = "CleaveMainArc"
	arc.z_index = 35
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(18):
		var t: float = -0.88 + 1.76 * float(i) / 17.0
		var a: float = angle + t
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	arc.points = pts
	arc.width = 9.0
	arc.default_color = Color(0.90, 0.82, 0.62, 0.78)
	root.add_child(arc)
	_fade_and_free(arc, 0.18)
	var blood: Line2D = Line2D.new()
	blood.name = "CleaveBleedEdge"
	blood.z_index = 36
	blood.points = pts
	blood.width = 3.0
	blood.default_color = Color(0.85, 0.04, 0.02, 0.74)
	root.add_child(blood)
	_fade_and_free(blood, 0.24)

static func emit_frost_nova(root: Node2D, center: Vector2, radius: float) -> void:
	for ring_index: int in range(3):
		var r: float = radius * (0.42 + float(ring_index) * 0.24)
		var ring: Line2D = Line2D.new()
		ring.name = "FrostNovaRing"
		ring.z_index = 30 + ring_index
		ring.points = _closed(_circle(center, r, 44))
		ring.width = 4.0 - float(ring_index) * 0.7
		ring.default_color = Color(0.50, 0.90, 1.0, 0.46 - float(ring_index) * 0.08)
		root.add_child(ring)
		_fade_and_free(ring, 0.30 + float(ring_index) * 0.05)
	for i: int in range(12):
		var a: float = float(i) * TAU / 12.0
		var start: Vector2 = center + Vector2(cos(a), sin(a)) * radius * 0.25
		var end: Vector2 = center + Vector2(cos(a), sin(a)) * radius * 0.82
		_emit_line(root, "FrostShard", start, end, Color(0.72, 0.96, 1.0, 0.46), 2.0, 0.32)

static func emit_void_rift(root: Node2D, center: Vector2, radius: float) -> void:
	_add_poly(root, "VoidRiftCore", _wobbly_circle(center, radius * 0.58, 32, 0.15), Color(0.24, 0.02, 0.34, 0.44), 20, 0.55)
	var ring: Line2D = Line2D.new()
	ring.name = "VoidRiftOuterRing"
	ring.z_index = 28
	ring.points = _closed(_wobbly_circle(center, radius, 42, 0.12))
	ring.width = 5.0
	ring.default_color = Color(0.68, 0.24, 1.0, 0.58)
	root.add_child(ring)
	_fade_and_free(ring, 0.60)
	for i: int in range(10):
		var a: float = float(i) * TAU / 10.0
		var outer: Vector2 = center + Vector2(cos(a), sin(a)) * radius
		var inner: Vector2 = center + Vector2(cos(a + 0.18), sin(a + 0.18)) * radius * 0.30
		_emit_line(root, "VoidPullLine", outer, inner, Color(0.72, 0.28, 1.0, 0.35), 2.0, 0.52)

static func emit_blade_trap(root: Node2D, center: Vector2, radius: float) -> void:
	_add_poly(root, "TrapPlate", _circle(center, radius * 0.48, 6), Color(0.12, 0.12, 0.13, 0.65), 24, 0.70, true)
	var ring: Line2D = Line2D.new()
	ring.name = "TrapRuneRing"
	ring.z_index = 29
	ring.points = _closed(_circle(center, radius * 0.78, 6))
	ring.width = 3.0
	ring.default_color = Color(0.95, 0.72, 0.32, 0.54)
	root.add_child(ring)
	_fade_and_free(ring, 0.70)
	for i: int in range(3):
		var a: float = float(i) * TAU / 3.0
		_emit_line(root, "TrapBlade", center - Vector2(cos(a), sin(a)) * radius * 0.42, center + Vector2(cos(a), sin(a)) * radius * 0.42, Color(0.88, 0.82, 0.66, 0.68), 4.0, 0.42)

static func emit_projectile_hint(root: Node2D, from: Vector2, to: Vector2, color: Color) -> void:
	var dir: Vector2 = to - from
	if dir.length() <= 1.0:
		dir = Vector2.RIGHT * 120.0
	var end: Vector2 = from + dir.normalized() * min(180.0, dir.length())
	_emit_trail(root, from, end, color, 9.0, 0.22)
	_add_poly(root, "ProjectileCore", _circle(end, 10.0, 12), color, 33, 0.22)

static func _emit_trail(root: Node2D, from: Vector2, to: Vector2, color: Color, width: float, life: float) -> void:
	_emit_line(root, "TrailOuter", from, to, Color(color.r, color.g, color.b, color.a * 0.25), width * 1.8, life)
	_emit_line(root, "TrailCore", from, to, color, width * 0.55, life * 0.82)

static func _emit_line(root: Node2D, name: String, a: Vector2, b: Vector2, color: Color, width: float, life: float) -> void:
	var line: Line2D = Line2D.new()
	line.name = name
	line.z_index = 40
	line.points = PackedVector2Array([a, b])
	line.width = width
	line.default_color = color
	root.add_child(line)
	_fade_and_free(line, life)

static func _add_poly(root: Node2D, name: String, points: PackedVector2Array, color: Color, z: int, life: float, outline: bool = false) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.name = name
	poly.z_index = z
	poly.polygon = points
	poly.color = color
	root.add_child(poly)
	_fade_and_free(poly, life)
	if outline:
		var line: Line2D = Line2D.new()
		line.name = name + "Outline"
		line.z_index = z + 1
		line.points = _closed(points)
		line.width = 2.4
		line.default_color = Color(color.r * 1.35, color.g * 1.35, color.b * 1.35, min(0.85, color.a * 2.0))
		root.add_child(line)
		_fade_and_free(line, life)

static func _fade_and_free(node: CanvasItem, duration: float) -> void:
	if node == null:
		return
	var tree: SceneTree = node.get_tree()
	if tree == null:
		node.queue_free()
		return
	var tw: Tween = tree.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, max(0.03, duration))
	tw.finished.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free()
	)

static func _circle(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(max(6, sides)):
		var a: float = float(i) * TAU / float(max(6, sides))
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts

static func _wobbly_circle(center: Vector2, radius: float, sides: int, wobble: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(max(6, sides)):
		var a: float = float(i) * TAU / float(max(6, sides))
		var r: float = radius * (1.0 + sin(float(i) * 2.37) * wobble)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts

static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array(points)
	if result.size() > 0:
		result.append(result[0])
	return result
