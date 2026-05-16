class_name RVEnemyVisualRig
extends Node2D

# Patch 059: Godot-native procedural enemy silhouette rig.
# This is Tier-1 proxy art: readable enemy silhouettes without final sprites.

const ProfileDB := preload("res://scripts/data/EnemyVisualProfileDB.gd")

var body_root: Node2D
var shadow_node: Polygon2D
var marker_root: Node2D
var current_radius: float = 16.0
var current_profile: Dictionary = {}
var current_statuses: Dictionary = {}
var pulse_time: float = 0.0
var visual_state: String = "idle"
var hit_flash_time: float = 0.0

func _ready() -> void:
	z_index = 5
	body_root = Node2D.new()
	body_root.name = "BodyRoot"
	add_child(body_root)
	marker_root = Node2D.new()
	marker_root.name = "MarkerRoot"
	add_child(marker_root)

func apply_profile(enemy_type: String, role: String, radius: float, base_color: Color, data: Dictionary = {}) -> void:
	current_radius = radius
	current_profile = ProfileDB.profile(enemy_type, role, radius, base_color)
	_clear_children(body_root)
	_clear_children(marker_root)
	_make_shadow(radius)
	_make_parts(current_profile)
	_make_markers(current_profile)
	queue_redraw()

func set_visual_state(new_state: String, direction: Vector2 = Vector2.RIGHT) -> void:
	if new_state == "":
		return
	visual_state = new_state
	if body_root == null:
		return
	if direction.length() > 0.1:
		body_root.scale.x = abs(body_root.scale.x) * (1.0 if direction.x >= 0.0 else -1.0)
	match new_state:
		"windup":
			_animate_body(Vector2(0.90 * sign_nonzero(body_root.scale.x), 1.10), -0.10 * sign_nonzero(body_root.scale.x), 0.12)
		"attack":
			_animate_body(Vector2(1.14 * sign_nonzero(body_root.scale.x), 0.92), 0.14 * sign_nonzero(body_root.scale.x), 0.08)
		"recover":
			_animate_body(Vector2(1.0 * sign_nonzero(body_root.scale.x), 1.0), 0.0, 0.18)
		"hit":
			flash_hit()
		"death":
			_animate_body(Vector2(1.22 * sign_nonzero(body_root.scale.x), 0.22), 0.35, 0.22)

func update_statuses(statuses: Dictionary) -> void:
	current_statuses = statuses.duplicate(true)
	queue_redraw()

func flash_hit() -> void:
	hit_flash_time = 0.14
	if body_root != null:
		body_root.modulate = Color(1.35, 1.15, 1.05, 1.0)

func _process(delta: float) -> void:
	pulse_time += delta
	if hit_flash_time > 0.0:
		hit_flash_time -= delta
		if hit_flash_time <= 0.0 and body_root != null:
			body_root.modulate = Color.WHITE
	if body_root == null:
		return
	if visual_state == "idle" or visual_state == "move":
		var breath := 1.0 + sin(pulse_time * (3.8 if visual_state == "move" else 2.0)) * (0.035 if visual_state == "move" else 0.018)
		var sx := sign_nonzero(body_root.scale.x)
		body_root.scale = Vector2(sx * breath, 1.0 / breath)
		body_root.rotation = sin(pulse_time * 3.0) * (0.035 if visual_state == "move" else 0.015)
		body_root.position.y = sin(pulse_time * (7.0 if visual_state == "move" else 2.2)) * (1.8 if visual_state == "move" else 0.6)

func _make_shadow(radius: float) -> void:
	shadow_node = Polygon2D.new()
	shadow_node.name = "Shadow"
	shadow_node.color = Color(0.0, 0.0, 0.0, 0.34)
	shadow_node.polygon = _ellipse_points(Vector2(4.0, radius * 0.64), radius * 0.92, radius * 0.34, 18)
	body_root.add_child(shadow_node)
	body_root.move_child(shadow_node, 0)

func _make_parts(profile: Dictionary) -> void:
	for part_value: Variant in Array(profile.get("parts", [])):
		var part := Dictionary(part_value)
		if str(part.get("kind", "")) != "poly":
			continue
		var poly := Polygon2D.new()
		poly.name = str(part.get("id", "Part"))
		var local_points := PackedVector2Array()
		var local_scale := float(part.get("scale", 1.0)) * current_radius
		for point_value: Variant in Array(part.get("points", [])):
			var point := Vector2(point_value)
			local_points.append(point * local_scale + Vector2(part.get("pos", Vector2.ZERO)))
		poly.polygon = local_points
		poly.color = Color(part.get("color", Color.WHITE))
		body_root.add_child(poly)
		var outline := Line2D.new()
		outline.name = str(part.get("id", "Part")) + "Outline"
		outline.points = _closed(local_points)
		outline.width = max(1.25, current_radius * 0.055)
		outline.default_color = Color(current_profile.get("outline", Color.BLACK))
		body_root.add_child(outline)
	for line_value: Variant in Array(profile.get("lines", [])):
		var line_data := Dictionary(line_value)
		var line := Line2D.new()
		line.name = str(line_data.get("id", "Line"))
		var pts := PackedVector2Array()
		for point_value2: Variant in Array(line_data.get("points", [])):
			pts.append(Vector2(point_value2))
		line.points = pts
		line.width = float(line_data.get("width", 2.0))
		line.default_color = Color(line_data.get("color", Color.WHITE))
		body_root.add_child(line)

func _make_markers(profile: Dictionary) -> void:
	for marker_value: Variant in Array(profile.get("markers", [])):
		var marker := Dictionary(marker_value)
		if str(marker.get("kind", "")) == "circle":
			var glow := Polygon2D.new()
			glow.name = str(marker.get("id", "Marker"))
			glow.polygon = _ellipse_points(Vector2(marker.get("pos", Vector2.ZERO)), float(marker.get("radius", 4.0)), float(marker.get("radius", 4.0)), 14)
			glow.color = Color(marker.get("color", Color.WHITE))
			marker_root.add_child(glow)

func _draw() -> void:
	var ring_radius := current_radius + 6.0
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

func _animate_body(target_scale: Vector2, target_rotation: float, duration: float) -> void:
	if body_root == null:
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(body_root, "scale", target_scale, duration)
	tw.tween_property(body_root, "rotation", target_rotation, duration)

func _ellipse_points(center: Vector2, rx: float, ry: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in range(max(6, sides)):
		var a := float(i) * TAU / float(max(6, sides))
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return points

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array(points)
	if result.size() > 0:
		result.append(result[0])
	return result

func _clear_children(root: Node) -> void:
	if root == null:
		return
	for child: Node in root.get_children():
		child.queue_free()

func sign_nonzero(value: float) -> float:
	return -1.0 if value < 0.0 else 1.0
