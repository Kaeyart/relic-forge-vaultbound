class_name RVMapPropVisualSystem
extends RefCounted

# Patch 059: cheap scene-authored-looking map dressing for runtime maps.
# Uses polygons and lines to turn graph maps into readable prototype spaces.

static func decorate(root: Node2D, layout: Dictionary, map_item: Dictionary = {}) -> void:
	if root == null:
		return
	var decor_root := Node2D.new()
	decor_root.name = "RuntimeProxyMapProps"
	root.add_child(decor_root)
	_add_section_props(decor_root, layout)
	_add_edge_props(decor_root, layout)
	_add_boss_gate(decor_root, layout)
	_add_exit_portal_proxy(decor_root, layout)

static func _add_section_props(root: Node2D, layout: Dictionary) -> void:
	for section_value: Variant in Array(layout.get("sections", [])):
		var section := Dictionary(section_value)
		var pos := Vector2(section.get("pos", Vector2.ZERO))
		var radius := float(section.get("radius", 76.0))
		var kind := str(section.get("kind", "pack"))
		match kind:
			"start":
				_add_braziers(root, pos, radius, Color(1.0, 0.42, 0.10, 0.70))
			"boss":
				_add_altar(root, pos, radius)
			"elite":
				_add_chain_posts(root, pos, radius)
			"side":
				_add_rubble_cluster(root, pos, radius)
			_:
				_add_floor_cracks(root, pos, radius)

static func _add_edge_props(root: Node2D, layout: Dictionary) -> void:
	for edge_value: Variant in Array(layout.get("edges", [])):
		var edge := Array(edge_value)
		if edge.size() < 2:
			continue
		var a := _section_pos(layout, str(edge[0]))
		var b := _section_pos(layout, str(edge[1]))
		var mid := (a + b) * 0.5
		var line := Line2D.new()
		line.name = "CorridorRib"
		var normal := (b - a).orthogonal().normalized() if a.distance_to(b) > 1.0 else Vector2.UP
		line.points = PackedVector2Array([mid - normal * 34.0, mid + normal * 34.0])
		line.width = 3.0
		line.default_color = Color(0.45, 0.28, 0.15, 0.45)
		root.add_child(line)

static func _add_braziers(root: Node2D, pos: Vector2, radius: float, color: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var p := pos + Vector2(side * radius * 0.55, radius * 0.18)
		_add_poly(root, "BrazierBase", _circle(p, 10.0, 6), Color(0.12, 0.10, 0.08, 1.0))
		_add_poly(root, "BrazierFlame", _circle(p + Vector2(0, -8), 7.0, 5), color)

static func _add_altar(root: Node2D, pos: Vector2, radius: float) -> void:
	_add_poly(root, "BossAltar", _circle(pos, radius * 0.22, 6), Color(0.17, 0.05, 0.04, 0.86))
	var ring := Line2D.new()
	ring.name = "BossSealRing"
	ring.points = _closed(_circle(pos, radius * 0.48, 34))
	ring.width = 4.0
	ring.default_color = Color(0.88, 0.30, 0.08, 0.52)
	root.add_child(ring)

static func _add_chain_posts(root: Node2D, pos: Vector2, radius: float) -> void:
	var pts := [pos + Vector2(-radius * 0.42, -radius * 0.28), pos + Vector2(radius * 0.42, -radius * 0.28), pos + Vector2(-radius * 0.36, radius * 0.30), pos + Vector2(radius * 0.36, radius * 0.30)]
	for p: Vector2 in pts:
		_add_poly(root, "ChainPost", _circle(p, 7.0, 5), Color(0.32, 0.26, 0.20, 0.95))
	var chain := Line2D.new()
	chain.name = "EliteChainLine"
	chain.points = PackedVector2Array(pts)
	chain.width = 2.0
	chain.default_color = Color(0.70, 0.50, 0.26, 0.46)
	root.add_child(chain)

static func _add_rubble_cluster(root: Node2D, pos: Vector2, radius: float) -> void:
	for i: int in range(5):
		var a := float(i) * TAU / 5.0 + radius * 0.01
		var p := pos + Vector2(cos(a), sin(a)) * radius * (0.34 + 0.08 * float(i % 2))
		_add_poly(root, "Rubble", _wobble_circle(p, 8.0 + float(i % 3) * 4.0, 6), Color(0.13, 0.10, 0.08, 0.92))

static func _add_floor_cracks(root: Node2D, pos: Vector2, radius: float) -> void:
	for i: int in range(3):
		var a := float(i) * TAU / 3.0 + 0.4
		var start := pos + Vector2(cos(a), sin(a)) * radius * 0.18
		var end := pos + Vector2(cos(a + 0.18), sin(a + 0.18)) * radius * 0.62
		var crack := Line2D.new()
		crack.name = "FloorCrack"
		crack.points = PackedVector2Array([start, (start + end) * 0.5 + Vector2(7.0, -5.0).rotated(a), end])
		crack.width = 2.0
		crack.default_color = Color(0.72, 0.38, 0.15, 0.30)
		root.add_child(crack)

static func _add_boss_gate(root: Node2D, layout: Dictionary) -> void:
	var boss := Vector2(layout.get("boss_pos", Vector2.ZERO))
	if boss == Vector2.ZERO:
		return
	var gate_pos := boss + Vector2(0, 90)
	var left := gate_pos + Vector2(-44, 0)
	var right := gate_pos + Vector2(44, 0)
	_add_poly(root, "BossGateLeft", _rect_points(left, Vector2(14, 58)), Color(0.20, 0.14, 0.10, 1.0))
	_add_poly(root, "BossGateRight", _rect_points(right, Vector2(14, 58)), Color(0.20, 0.14, 0.10, 1.0))
	var arch := Line2D.new()
	arch.name = "BossGateArch"
	arch.points = PackedVector2Array([left + Vector2(0, -30), gate_pos + Vector2(0, -62), right + Vector2(0, -30)])
	arch.width = 6.0
	arch.default_color = Color(0.76, 0.42, 0.18, 0.62)
	root.add_child(arch)

static func _add_exit_portal_proxy(root: Node2D, layout: Dictionary) -> void:
	var exit_pos := Vector2(layout.get("exit_pos", Vector2.ZERO))
	if exit_pos == Vector2.ZERO:
		return
	var ring := Line2D.new()
	ring.name = "ExitPortalProxyRing"
	ring.points = _closed(_circle(exit_pos, 30.0, 28))
	ring.width = 4.0
	ring.default_color = Color(0.95, 0.62, 0.22, 0.58)
	root.add_child(ring)

static func _section_pos(layout: Dictionary, id: String) -> Vector2:
	for section_value: Variant in Array(layout.get("sections", [])):
		var section := Dictionary(section_value)
		if str(section.get("id", "")) == id:
			return Vector2(section.get("pos", Vector2.ZERO))
	return Vector2.ZERO

static func _add_poly(root: Node2D, name: String, points: PackedVector2Array, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.name = name
	poly.polygon = points
	poly.color = color
	root.add_child(poly)

static func _circle(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in range(max(5, sides)):
		var a := float(i) * TAU / float(max(5, sides))
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	return points

static func _wobble_circle(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in range(max(5, sides)):
		var a := float(i) * TAU / float(max(5, sides))
		var r := radius * (0.86 + 0.24 * sin(float(i) * 2.1))
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points

static func _rect_points(center: Vector2, size: Vector2) -> PackedVector2Array:
	var h := size * 0.5
	return PackedVector2Array([center + Vector2(-h.x, -h.y), center + Vector2(h.x, -h.y), center + Vector2(h.x, h.y), center + Vector2(-h.x, h.y)])

static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array(points)
	if result.size() > 0:
		result.append(result[0])
	return result
