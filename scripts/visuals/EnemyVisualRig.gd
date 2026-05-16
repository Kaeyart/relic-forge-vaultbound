class_name RVEnemyVisualRig
extends Node2D

# Patch 060: stronger procedural enemy proxy rig.
# Scene-composed silhouettes, role telegraphs, hit pulses, and status badges.

const ProfileDB := preload("res://scripts/data/EnemyVisualProfileDB.gd")

var body_root: Node2D = null
var marker_root: Node2D = null
var telegraph_root: Node2D = null
var shadow_node: Polygon2D = null

var current_radius: float = 16.0
var current_profile: Dictionary = {}
var current_statuses: Dictionary = {}
var visual_state: String = "idle"
var facing: float = 1.0
var pulse_time: float = 0.0
var hit_flash_time: float = 0.0
var current_attack_kind: String = ""
var current_direction: Vector2 = Vector2.RIGHT
var last_state_applied: String = ""

func _ready() -> void:
	z_index = 5
	body_root = Node2D.new()
	body_root.name = "BodyRoot"
	add_child(body_root)
	marker_root = Node2D.new()
	marker_root.name = "MarkerRoot"
	add_child(marker_root)
	telegraph_root = Node2D.new()
	telegraph_root.name = "TelegraphRoot"
	telegraph_root.z_index = -2
	add_child(telegraph_root)

func apply_profile(enemy_type: String, role: String, radius: float, base_color: Color, data: Dictionary = {}) -> void:
	current_radius = radius
	current_profile = ProfileDB.profile(enemy_type, role, radius, base_color)
	if bool(data.get("is_elite", false)):
		current_profile["accent"] = Color(1.0, 0.78, 0.22, 0.95)
	if bool(data.get("is_map_boss", false)):
		current_profile = ProfileDB.profile("boss", "boss", max(radius, 34.0), base_color)
	_clear_children(body_root)
	_clear_children(marker_root)
	_clear_children(telegraph_root)
	_make_shadow(current_radius)
	_make_parts(current_profile)
	_make_markers(current_profile)
	_make_role_badge(current_profile)
	last_state_applied = ""
	set_visual_state("idle", Vector2.RIGHT)
	queue_redraw()

func set_visual_state(new_state: String, direction: Vector2 = Vector2.RIGHT) -> void:
	if new_state == "":
		return
	if direction.length() > 0.1:
		current_direction = direction.normalized()
		facing = -1.0 if current_direction.x < -0.05 else 1.0
	if new_state == visual_state and last_state_applied == new_state:
		_update_facing()
		return
	visual_state = new_state
	last_state_applied = new_state
	_update_facing()
	_clear_children(telegraph_root)
	match new_state:
		"windup":
			_make_state_telegraph()
			_tween_body(Vector2(facing * 0.88, 1.12), -0.13 * facing, 0.10)
		"attack":
			_tween_body(Vector2(facing * 1.18, 0.90), 0.16 * facing, 0.07)
		"recover":
			_tween_body(Vector2(facing, 1.0), 0.0, 0.18)
		"hit":
			flash_hit()
		"death":
			_clear_children(telegraph_root)
			_tween_body(Vector2(facing * 1.20, 0.20), 0.46 * facing, 0.22)
		_:
			_tween_body(Vector2(facing, 1.0), 0.0, 0.10)

func set_attack_kind(kind: String, direction: Vector2 = Vector2.RIGHT) -> void:
	current_attack_kind = kind
	if direction.length() > 0.1:
		current_direction = direction.normalized()
		facing = -1.0 if current_direction.x < -0.05 else 1.0
	_update_facing()
	if visual_state == "windup":
		_clear_children(telegraph_root)
		_make_state_telegraph()

func update_statuses(statuses: Dictionary) -> void:
	current_statuses = statuses.duplicate(true)
	queue_redraw()

func flash_hit() -> void:
	hit_flash_time = 0.14
	if body_root != null:
		body_root.modulate = Color(1.45, 1.22, 1.04, 1.0)
	_make_hit_sparks()

func _process(delta: float) -> void:
	pulse_time += delta
	if hit_flash_time > 0.0:
		hit_flash_time -= delta
		if hit_flash_time <= 0.0 and body_root != null:
			body_root.modulate = Color.WHITE
	if body_root == null:
		return
	if visual_state == "idle" or visual_state == "move" or visual_state == "aggro":
		var rate: float = 5.6 if visual_state == "move" or visual_state == "aggro" else 2.0
		var amount: float = 0.040 if visual_state == "move" or visual_state == "aggro" else 0.018
		var breath: float = 1.0 + sin(pulse_time * rate) * amount
		body_root.scale = Vector2(facing * breath, 1.0 / max(0.4, breath))
		body_root.rotation = sin(pulse_time * rate * 0.65) * (0.040 if visual_state != "idle" else 0.016)
		body_root.position.y = sin(pulse_time * rate * 1.35) * (1.8 if visual_state != "idle" else 0.6)
	if marker_root != null:
		marker_root.modulate.a = 0.78 + sin(pulse_time * 5.0) * 0.16
	if telegraph_root != null:
		telegraph_root.modulate.a = 0.55 + sin(pulse_time * 10.0) * 0.22

func _update_facing() -> void:
	if body_root != null:
		var y: float = body_root.scale.y
		body_root.scale.x = abs(body_root.scale.x) * facing
		body_root.scale.y = y
	if marker_root != null:
		marker_root.scale.x = facing

func _make_shadow(radius: float) -> void:
	shadow_node = Polygon2D.new()
	shadow_node.name = "ProxyShadow"
	shadow_node.z_index = -10
	shadow_node.color = Color(current_profile.get("shadow", Color(0, 0, 0, 0.34)))
	shadow_node.polygon = _ellipse_points(Vector2(5.0, radius * 0.66), radius * 1.05, radius * 0.34, 24)
	body_root.add_child(shadow_node)

func _make_parts(profile: Dictionary) -> void:
	for part_value: Variant in Array(profile.get("parts", [])):
		var part: Dictionary = Dictionary(part_value)
		if str(part.get("kind", "")) != "poly":
			continue
		var local_points: PackedVector2Array = PackedVector2Array()
		var local_scale: float = float(part.get("scale", 1.0)) * current_radius
		var offset: Vector2 = Vector2(part.get("pos", Vector2.ZERO))
		for point_value: Variant in Array(part.get("points", [])):
			local_points.append(Vector2(point_value) * local_scale + offset)
		var poly: Polygon2D = Polygon2D.new()
		poly.name = str(part.get("id", "Part"))
		poly.z_index = int(part.get("z", 0))
		poly.polygon = local_points
		poly.color = Color(part.get("color", Color.WHITE))
		body_root.add_child(poly)
		var outline: Line2D = Line2D.new()
		outline.name = poly.name + "Outline"
		outline.z_index = poly.z_index + 1
		outline.points = _closed(local_points)
		outline.width = max(1.25, current_radius * 0.052)
		outline.default_color = Color(current_profile.get("outline", Color.BLACK))
		body_root.add_child(outline)
	for line_value: Variant in Array(profile.get("lines", [])):
		var line_data: Dictionary = Dictionary(line_value)
		var line: Line2D = Line2D.new()
		line.name = str(line_data.get("id", "Line"))
		line.z_index = int(line_data.get("z", 5))
		var pts: PackedVector2Array = PackedVector2Array()
		for point_value2: Variant in Array(line_data.get("points", [])):
			pts.append(Vector2(point_value2))
		line.points = pts
		line.width = float(line_data.get("width", 2.0))
		line.default_color = Color(line_data.get("color", Color.WHITE))
		body_root.add_child(line)

func _make_markers(profile: Dictionary) -> void:
	for marker_value: Variant in Array(profile.get("markers", [])):
		var marker: Dictionary = Dictionary(marker_value)
		if str(marker.get("kind", "")) != "circle":
			continue
		var glow: Polygon2D = Polygon2D.new()
		glow.name = str(marker.get("id", "Marker"))
		glow.z_index = int(marker.get("z", 8))
		var p: Vector2 = Vector2(marker.get("pos", Vector2.ZERO))
		var r: float = float(marker.get("radius", 4.0))
		glow.polygon = _ellipse_points(p, r, r, 16)
		glow.color = Color(marker.get("color", Color.WHITE))
		marker_root.add_child(glow)

func _make_role_badge(profile: Dictionary) -> void:
	var color: Color = Color(profile.get("accent", Color(1.0, 0.42, 0.10, 0.78)))
	var badge: Line2D = Line2D.new()
	badge.name = "RoleBadge"
	badge.z_index = 12
	badge.points = PackedVector2Array([Vector2(-current_radius * 0.42, -current_radius * 1.22), Vector2(current_radius * 0.42, -current_radius * 1.22)])
	badge.width = max(2.0, current_radius * 0.10)
	badge.default_color = Color(color.r, color.g, color.b, 0.62)
	marker_root.add_child(badge)

func _make_state_telegraph() -> void:
	var telegraph_type: String = str(current_profile.get("telegraph", "ring"))
	var color: Color = Color(current_profile.get("threat_color", Color(1.0, 0.42, 0.10, 0.60)))
	var dir: Vector2 = current_direction.normalized() if current_direction.length() > 0.1 else Vector2.RIGHT
	match telegraph_type:
		"charge_line", "dash_line":
			_make_telegraph_line(dir, current_radius * 3.2, color, 7.0)
		"lob_arc":
			_make_telegraph_arc(dir, color)
		"sigil", "summon_ring":
			_make_telegraph_ring(current_radius * 1.55, color)
		"cleave_cone":
			_make_telegraph_cone(dir, current_radius * 2.0, color)
		"slam_ring", "boss_seal":
			_make_telegraph_ring(current_radius * 2.2, color)
		"short_line":
			_make_telegraph_line(dir, current_radius * 1.85, color, 4.0)
		_:
			_make_telegraph_ring(current_radius * 1.4, color)

func _make_telegraph_line(dir: Vector2, length: float, color: Color, width: float) -> void:
	var line: Line2D = Line2D.new()
	line.name = "WindupLineTelegraph"
	line.points = PackedVector2Array([Vector2.ZERO, dir.normalized() * length])
	line.width = width
	line.default_color = color
	telegraph_root.add_child(line)

func _make_telegraph_ring(radius: float, color: Color) -> void:
	var ring: Line2D = Line2D.new()
	ring.name = "WindupRingTelegraph"
	ring.points = _closed(_ellipse_points(Vector2.ZERO, radius, radius * 0.62, 36))
	ring.width = 4.0
	ring.default_color = color
	telegraph_root.add_child(ring)

func _make_telegraph_cone(dir: Vector2, length: float, color: Color) -> void:
	var center_angle: float = dir.angle()
	var pts: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
	for i: int in range(9):
		var t: float = -0.62 + 1.24 * float(i) / 8.0
		pts.append(Vector2(cos(center_angle + t), sin(center_angle + t)) * length)
	var poly: Polygon2D = Polygon2D.new()
	poly.name = "WindupConeTelegraph"
	poly.polygon = pts
	poly.color = Color(color.r, color.g, color.b, 0.20)
	telegraph_root.add_child(poly)
	var edge: Line2D = Line2D.new()
	edge.name = "WindupConeEdge"
	edge.points = _closed(pts)
	edge.width = 2.5
	edge.default_color = color
	telegraph_root.add_child(edge)

func _make_telegraph_arc(dir: Vector2, color: Color) -> void:
	var arc: Line2D = Line2D.new()
	arc.name = "LobArcTelegraph"
	var end: Vector2 = dir.normalized() * current_radius * 2.5
	arc.points = PackedVector2Array([Vector2.ZERO, end * 0.50 + Vector2(0, -current_radius * 0.9), end])
	arc.width = 3.0
	arc.default_color = color
	telegraph_root.add_child(arc)

func _make_hit_sparks() -> void:
	if marker_root == null:
		return
	var accent: Color = Color(current_profile.get("accent", Color(1, 0.4, 0.1, 0.8)))
	for i: int in range(5):
		var a: float = float(i) * TAU / 5.0 + pulse_time
		var line: Line2D = Line2D.new()
		line.name = "HitSpark"
		line.z_index = 20
		var start: Vector2 = Vector2(cos(a), sin(a)) * current_radius * 0.25
		var end: Vector2 = Vector2(cos(a), sin(a)) * current_radius * 0.82
		line.points = PackedVector2Array([start, end])
		line.width = 2.0
		line.default_color = accent
		marker_root.add_child(line)
		_fade_and_free(line, 0.18)

func _draw() -> void:
	var ring_radius: float = current_radius + 6.0
	if _has_status("burn"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 28, Color(1.0, 0.26, 0.04, 0.78), 2.0)
		ring_radius += 4.0
	if _has_status("freeze"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 28, Color(0.45, 0.86, 1.0, 0.78), 2.0)
		ring_radius += 4.0
	if _has_status("curse"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 28, Color(0.75, 0.30, 1.0, 0.76), 2.0)
		ring_radius += 4.0
	if _has_status("bleed"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 28, Color(0.82, 0.03, 0.02, 0.76), 2.0)
		ring_radius += 4.0
	if _has_status("shock"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 28, Color(0.78, 0.96, 1.0, 0.78), 2.0)

func _has_status(id: String) -> bool:
	if not current_statuses.has(id):
		return false
	return float(Dictionary(current_statuses[id]).get("time", 0.0)) > 0.0

func _tween_body(target_scale: Vector2, target_rotation: float, duration: float) -> void:
	if body_root == null:
		return
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(body_root, "scale", target_scale, duration)
	tw.tween_property(body_root, "rotation", target_rotation, duration)

func _fade_and_free(node: CanvasItem, duration: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(node, "modulate:a", 0.0, duration)
	tw.finished.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free()
	)

func _ellipse_points(center: Vector2, rx: float, ry: float, sides: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(max(6, sides)):
		var a: float = float(i) * TAU / float(max(6, sides))
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return points

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array(points)
	if result.size() > 0:
		result.append(result[0])
	return result

func _clear_children(root: Node) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		child.queue_free()
