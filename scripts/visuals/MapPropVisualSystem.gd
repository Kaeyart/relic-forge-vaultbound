class_name RVMapPropVisualSystem
extends RefCounted

# Patch 060: stronger runtime map dressing.
# Still procedural, but deliberately authored-looking: floor scars, props, gates, landmarks.

static func decorate(root: Node2D, layout: Dictionary, map_item: Dictionary = {}) -> void:
	if root == null:
		return
	var decor_root: Node2D = Node2D.new()
	decor_root.name = "RuntimeProxyMapPropsPlus"
	decor_root.z_index = -6
	root.add_child(decor_root)
	var biome: String = str(map_item.get("biome", map_item.get("layout_id", "ash"))).to_lower()
	_add_section_floor_language(decor_root, layout, biome)
	_add_corridor_language(decor_root, layout, biome)
	_add_section_props(decor_root, layout, biome)
	_add_boss_gate(decor_root, layout, biome)
	_add_exit_portal_proxy(decor_root, layout)

static func _add_section_floor_language(root: Node2D, layout: Dictionary, biome: String) -> void:
	for section_value: Variant in Array(layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		var pos: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
		var radius: float = float(section.get("radius", 76.0))
		var kind: String = str(section.get("kind", "pack"))
		var floor_color: Color = _biome_floor_color(biome)
		_add_poly(root, "FloorPlate", _wobble_circle(pos, radius * 0.92, 28), floor_color)
		_add_floor_cracks(root, pos, radius, biome)
		if kind == "boss":
			_add_boss_seal(root, pos, radius, biome)
		elif kind == "start":
			_add_start_seal(root, pos, radius)
		elif kind == "elite":
			_add_elite_warning_mark(root, pos, radius)

static func _add_corridor_language(root: Node2D, layout: Dictionary, biome: String) -> void:
	for edge_value: Variant in Array(layout.get("edges", [])):
		var edge: Array = Array(edge_value)
		if edge.size() < 2:
			continue
		var a: Vector2 = _section_pos(layout, str(edge[0]))
		var b: Vector2 = _section_pos(layout, str(edge[1]))
		if a == Vector2.ZERO and b == Vector2.ZERO:
			continue
		var dir: Vector2 = (b - a).normalized() if a.distance_to(b) > 1.0 else Vector2.RIGHT
		var normal: Vector2 = dir.orthogonal()
		var mid: Vector2 = (a + b) * 0.5
		var rail_color: Color = _biome_trim_color(biome)
		for side: float in [-1.0, 1.0]:
			var rail: Line2D = Line2D.new()
			rail.name = "CorridorEdgeTrim"
			rail.z_index = -3
			rail.points = PackedVector2Array([a + normal * 42.0 * side, b + normal * 42.0 * side])
			rail.width = 3.0
			rail.default_color = rail_color
			root.add_child(rail)
		for i: int in range(3):
			var t: float = float(i + 1) / 4.0
			var rib_mid: Vector2 = a.lerp(b, t)
			var rib: Line2D = Line2D.new()
			rib.name = "CorridorRib"
			rib.z_index = -2
			rib.points = PackedVector2Array([rib_mid - normal * 34.0, rib_mid + normal * 34.0])
			rib.width = 2.4
			rib.default_color = Color(rail_color.r, rail_color.g, rail_color.b, 0.33)
			root.add_child(rib)
		_add_poly(root, "CorridorAshPatch", _wobble_circle(mid, 18.0, 7), Color(0.04, 0.035, 0.03, 0.28))

static func _add_section_props(root: Node2D, layout: Dictionary, biome: String) -> void:
	for section_value: Variant in Array(layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		var pos: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
		var radius: float = float(section.get("radius", 76.0))
		var kind: String = str(section.get("kind", "pack"))
		match kind:
			"start":
				_add_braziers(root, pos, radius, Color(1.0, 0.46, 0.12, 0.75))
			"boss":
				_add_altar(root, pos, radius, biome)
			"elite":
				_add_chain_posts(root, pos, radius)
			"side":
				_add_rubble_cluster(root, pos, radius)
			_:
				_add_small_dressing(root, pos, radius, biome)

static func _add_braziers(root: Node2D, pos: Vector2, radius: float, color: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var p: Vector2 = pos + Vector2(side * radius * 0.56, radius * 0.18)
		_add_poly(root, "BrazierBase", _circle(p, 10.0, 6), Color(0.11, 0.085, 0.065, 0.96))
		_add_poly(root, "BrazierFlameOuter", _circle(p + Vector2(0, -8), 10.0, 7), Color(color.r, color.g, color.b, 0.22))
		_add_poly(root, "BrazierFlame", _circle(p + Vector2(0, -10), 6.0, 5), color)

static func _add_altar(root: Node2D, pos: Vector2, radius: float, biome: String) -> void:
	_add_poly(root, "BossAltarBase", _circle(pos, radius * 0.24, 6), Color(0.16, 0.055, 0.040, 0.92))
	_add_poly(root, "BossAltarCore", _circle(pos + Vector2(0, -4), radius * 0.14, 6), Color(0.58, 0.14, 0.05, 0.70))
	var ring: Line2D = Line2D.new()
	ring.name = "BossSealRing"
	ring.z_index = 0
	ring.points = _closed(_circle(pos, radius * 0.52, 38))
	ring.width = 4.0
	ring.default_color = Color(0.88, 0.28, 0.07, 0.58)
	root.add_child(ring)
	for i: int in range(8):
		var a: float = float(i) * TAU / 8.0
		var p1: Vector2 = pos + Vector2(cos(a), sin(a)) * radius * 0.30
		var p2: Vector2 = pos + Vector2(cos(a), sin(a)) * radius * 0.54
		_add_line(root, "BossSealRay", p1, p2, Color(0.96, 0.46, 0.14, 0.36), 2.0)

static func _add_chain_posts(root: Node2D, pos: Vector2, radius: float) -> void:
	var pts: Array = [
		pos + Vector2(-radius * 0.46, -radius * 0.30),
		pos + Vector2(radius * 0.46, -radius * 0.30),
		pos + Vector2(-radius * 0.40, radius * 0.32),
		pos + Vector2(radius * 0.40, radius * 0.32)
	]
	for p_value: Variant in pts:
		var p: Vector2 = Vector2(p_value)
		_add_poly(root, "EliteChainPost", _circle(p, 8.0, 5), Color(0.34, 0.27, 0.20, 0.95))
	var chain: Line2D = Line2D.new()
	chain.name = "EliteChainLoop"
	chain.z_index = 1
	chain.points = PackedVector2Array([Vector2(pts[0]), Vector2(pts[1]), Vector2(pts[3]), Vector2(pts[2]), Vector2(pts[0])])
	chain.width = 2.0
	chain.default_color = Color(0.74, 0.52, 0.24, 0.48)
	root.add_child(chain)

static func _add_rubble_cluster(root: Node2D, pos: Vector2, radius: float) -> void:
	for i: int in range(8):
		var a: float = float(i) * TAU / 8.0 + 0.23
		var p: Vector2 = pos + Vector2(cos(a), sin(a)) * radius * (0.24 + 0.23 * float(i % 3) / 2.0)
		_add_poly(root, "Rubble", _wobble_circle(p, 7.0 + float(i % 3) * 3.0, 6), Color(0.12, 0.095, 0.075, 0.90))

static func _add_small_dressing(root: Node2D, pos: Vector2, radius: float, biome: String) -> void:
	var trim: Color = _biome_trim_color(biome)
	for i: int in range(4):
		var a: float = float(i) * TAU / 4.0 + 0.5
		var p: Vector2 = pos + Vector2(cos(a), sin(a)) * radius * 0.60
		if i % 2 == 0:
			_add_poly(root, "AshPile", _wobble_circle(p, 13.0, 7), Color(0.055, 0.050, 0.045, 0.34))
		else:
			_add_line(root, "BrokenChain", p + Vector2(-10, 0), p + Vector2(10, 3), Color(trim.r, trim.g, trim.b, 0.38), 2.0)

static func _add_floor_cracks(root: Node2D, pos: Vector2, radius: float, biome: String) -> void:
	var color: Color = Color(0.72, 0.34, 0.10, 0.26)
	if biome.find("bone") >= 0:
		color = Color(0.62, 0.52, 0.36, 0.25)
	elif biome.find("iron") >= 0:
		color = Color(0.44, 0.36, 0.28, 0.28)
	for i: int in range(4):
		var a: float = float(i) * TAU / 4.0 + 0.35
		var start: Vector2 = pos + Vector2(cos(a), sin(a)) * radius * 0.14
		var end: Vector2 = pos + Vector2(cos(a + 0.20), sin(a + 0.20)) * radius * 0.66
		var crack: Line2D = Line2D.new()
		crack.name = "FloorCrack"
		crack.z_index = -1
		crack.points = PackedVector2Array([start, (start + end) * 0.5 + Vector2(7.0, -5.0).rotated(a), end])
		crack.width = 2.0
		crack.default_color = color
		root.add_child(crack)

static func _add_boss_seal(root: Node2D, pos: Vector2, radius: float, biome: String) -> void:
	var seal_color: Color = Color(0.90, 0.24, 0.08, 0.28)
	_add_poly(root, "BossSealFill", _circle(pos, radius * 0.60, 32), seal_color)
	for i: int in range(6):
		var a: float = float(i) * TAU / 6.0
		_add_line(root, "BossSealSpoke", pos, pos + Vector2(cos(a), sin(a)) * radius * 0.58, Color(1.0, 0.54, 0.16, 0.34), 2.0)

static func _add_start_seal(root: Node2D, pos: Vector2, radius: float) -> void:
	var ring: Line2D = Line2D.new()
	ring.name = "StartSeal"
	ring.z_index = 2
	ring.points = _closed(_circle(pos, radius * 0.42, 28))
	ring.width = 3.0
	ring.default_color = Color(0.90, 0.62, 0.28, 0.38)
	root.add_child(ring)

static func _add_elite_warning_mark(root: Node2D, pos: Vector2, radius: float) -> void:
	var mark: Line2D = Line2D.new()
	mark.name = "EliteWarningMark"
	mark.z_index = 2
	mark.points = PackedVector2Array([pos + Vector2(-radius * 0.38, 0), pos + Vector2(0, -radius * 0.34), pos + Vector2(radius * 0.38, 0), pos + Vector2(0, radius * 0.34), pos + Vector2(-radius * 0.38, 0)])
	mark.width = 3.0
	mark.default_color = Color(1.0, 0.74, 0.20, 0.38)
	root.add_child(mark)

static func _add_boss_gate(root: Node2D, layout: Dictionary, biome: String) -> void:
	var boss: Vector2 = Vector2(layout.get("boss_pos", Vector2.ZERO))
	if boss == Vector2.ZERO:
		return
	var gate_pos: Vector2 = boss + Vector2(0, 94)
	var left: Vector2 = gate_pos + Vector2(-48, 0)
	var right: Vector2 = gate_pos + Vector2(48, 0)
	_add_poly(root, "BossGateLeft", _rect_points(left, Vector2(16, 64)), Color(0.19, 0.13, 0.09, 0.98))
	_add_poly(root, "BossGateRight", _rect_points(right, Vector2(16, 64)), Color(0.19, 0.13, 0.09, 0.98))
	_add_line(root, "BossGateArch", left + Vector2(0, -32), gate_pos + Vector2(0, -68), Color(0.76, 0.42, 0.18, 0.62), 7.0)
	_add_line(root, "BossGateArch2", gate_pos + Vector2(0, -68), right + Vector2(0, -32), Color(0.76, 0.42, 0.18, 0.62), 7.0)
	_add_poly(root, "BossGateSeal", _circle(gate_pos + Vector2(0, -38), 10.0, 6), Color(1.0, 0.34, 0.08, 0.54))

static func _add_exit_portal_proxy(root: Node2D, layout: Dictionary) -> void:
	var exit_pos: Vector2 = Vector2(layout.get("exit_pos", Vector2.ZERO))
	if exit_pos == Vector2.ZERO:
		return
	var ring: Line2D = Line2D.new()
	ring.name = "ExitPortalProxyRing"
	ring.z_index = 8
	ring.points = _closed(_circle(exit_pos, 32.0, 30))
	ring.width = 4.0
	ring.default_color = Color(0.95, 0.62, 0.22, 0.64)
	root.add_child(ring)
	_add_poly(root, "ExitPortalGlow", _circle(exit_pos, 20.0, 22), Color(1.0, 0.50, 0.18, 0.14))

static func _section_pos(layout: Dictionary, id: String) -> Vector2:
	for section_value: Variant in Array(layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		if str(section.get("id", "")) == id:
			return Vector2(section.get("pos", Vector2.ZERO))
	return Vector2.ZERO

static func _biome_floor_color(biome: String) -> Color:
	if biome.find("iron") >= 0:
		return Color(0.055, 0.052, 0.050, 0.22)
	if biome.find("bone") >= 0:
		return Color(0.10, 0.085, 0.060, 0.20)
	return Color(0.070, 0.048, 0.040, 0.24)

static func _biome_trim_color(biome: String) -> Color:
	if biome.find("iron") >= 0:
		return Color(0.48, 0.42, 0.34, 0.46)
	if biome.find("bone") >= 0:
		return Color(0.70, 0.60, 0.42, 0.42)
	return Color(0.70, 0.34, 0.14, 0.44)

static func _add_poly(root: Node2D, name: String, points: PackedVector2Array, color: Color) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.name = name
	poly.z_index = -1
	poly.polygon = points
	poly.color = color
	root.add_child(poly)

static func _add_line(root: Node2D, name: String, a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var line: Line2D = Line2D.new()
	line.name = name
	line.z_index = 1
	line.points = PackedVector2Array([a, b])
	line.width = width
	line.default_color = color
	root.add_child(line)

static func _circle(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(max(5, sides)):
		var a: float = float(i) * TAU / float(max(5, sides))
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	return points

static func _wobble_circle(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(max(5, sides)):
		var a: float = float(i) * TAU / float(max(5, sides))
		var r: float = radius * (0.86 + 0.24 * sin(float(i) * 2.1))
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points

static func _rect_points(center: Vector2, size: Vector2) -> PackedVector2Array:
	var h: Vector2 = size * 0.5
	return PackedVector2Array([center + Vector2(-h.x, -h.y), center + Vector2(h.x, -h.y), center + Vector2(h.x, h.y), center + Vector2(-h.x, h.y)])

static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array(points)
	if result.size() > 0:
		result.append(result[0])
	return result
