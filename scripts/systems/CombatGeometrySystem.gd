class_name RVCombatGeometrySystem
extends RefCounted

const DEFAULT_BOUNDS: Rect2 = Rect2(0, 0, 1280, 720)

static func layout_bounds(layout: Dictionary) -> Rect2:
	if layout.has("bounds") and typeof(layout.get("bounds")) == TYPE_RECT2:
		return Rect2(layout.get("bounds"))
	return DEFAULT_BOUNDS

static func layout_obstacles(layout: Dictionary) -> Array:
	if layout.has("obstacles") and typeof(layout.get("obstacles")) == TYPE_ARRAY:
		return Array(layout.get("obstacles"))
	return []

static func is_layout_active(layout: Dictionary) -> bool:
	return not layout.is_empty() and bool(layout.get("is_continuous_field", false))

static func constrain_point(layout: Dictionary, point: Vector2, radius: float = 14.0) -> Vector2:
	if layout.is_empty():
		return point
	var p: Vector2 = point
	var bounds: Rect2 = layout_bounds(layout)
	p.x = clampf(p.x, bounds.position.x + radius, bounds.position.x + bounds.size.x - radius)
	p.y = clampf(p.y, bounds.position.y + radius, bounds.position.y + bounds.size.y - radius)
	var obstacles: Array = layout_obstacles(layout)
	for pass_index: int in range(4):
		var changed: bool = false
		for obstacle_value: Variant in obstacles:
			if typeof(obstacle_value) != TYPE_DICTIONARY:
				continue
			var obstacle: Dictionary = Dictionary(obstacle_value)
			var center: Vector2 = Vector2(obstacle.get("pos", Vector2.ZERO))
			var obstacle_radius: float = float(obstacle.get("radius", 24.0))
			var min_distance: float = obstacle_radius + radius
			var delta: Vector2 = p - center
			var distance: float = delta.length()
			if distance <= 0.001:
				delta = Vector2.RIGHT
				distance = 1.0
			if distance < min_distance:
				p = center + delta.normalized() * min_distance
				p.x = clampf(p.x, bounds.position.x + radius, bounds.position.x + bounds.size.x - radius)
				p.y = clampf(p.y, bounds.position.y + radius, bounds.position.y + bounds.size.y - radius)
				changed = true
		if not changed:
			break
	return p

static func is_point_blocked(layout: Dictionary, point: Vector2, radius: float = 4.0) -> bool:
	if layout.is_empty():
		return false
	var bounds: Rect2 = layout_bounds(layout)
	if point.x < bounds.position.x + radius or point.y < bounds.position.y + radius:
		return true
	if point.x > bounds.position.x + bounds.size.x - radius or point.y > bounds.position.y + bounds.size.y - radius:
		return true
	for obstacle_value: Variant in layout_obstacles(layout):
		if typeof(obstacle_value) != TYPE_DICTIONARY:
			continue
		var obstacle: Dictionary = Dictionary(obstacle_value)
		var center: Vector2 = Vector2(obstacle.get("pos", Vector2.ZERO))
		var obstacle_radius: float = float(obstacle.get("radius", 24.0))
		if center.distance_to(point) <= obstacle_radius + radius:
			return true
	return false

static func has_line_of_sight(layout: Dictionary, from_pos: Vector2, to_pos: Vector2, padding: float = 8.0) -> bool:
	if layout.is_empty():
		return true
	for obstacle_value: Variant in layout_obstacles(layout):
		if typeof(obstacle_value) != TYPE_DICTIONARY:
			continue
		var obstacle: Dictionary = Dictionary(obstacle_value)
		var center: Vector2 = Vector2(obstacle.get("pos", Vector2.ZERO))
		var obstacle_radius: float = float(obstacle.get("radius", 24.0)) + padding
		if segment_intersects_circle(from_pos, to_pos, center, obstacle_radius):
			return false
	return true

static func segment_intersects_circle(a: Vector2, b: Vector2, center: Vector2, radius: float) -> bool:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.001:
		return a.distance_to(center) <= radius
	var t: float = clampf((center - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return closest.distance_to(center) <= radius

static func segment_collision_normal(layout: Dictionary, a: Vector2, b: Vector2, radius: float = 4.0) -> Vector2:
	var bounds: Rect2 = layout_bounds(layout)
	if b.x < bounds.position.x + radius:
		return Vector2.RIGHT
	if b.x > bounds.position.x + bounds.size.x - radius:
		return Vector2.LEFT
	if b.y < bounds.position.y + radius:
		return Vector2.DOWN
	if b.y > bounds.position.y + bounds.size.y - radius:
		return Vector2.UP
	for obstacle_value: Variant in layout_obstacles(layout):
		if typeof(obstacle_value) != TYPE_DICTIONARY:
			continue
		var obstacle: Dictionary = Dictionary(obstacle_value)
		var center: Vector2 = Vector2(obstacle.get("pos", Vector2.ZERO))
		var obstacle_radius: float = float(obstacle.get("radius", 24.0)) + radius
		if segment_intersects_circle(a, b, center, obstacle_radius):
			var normal: Vector2 = (b - center).normalized()
			if normal.length_squared() <= 0.001:
				normal = (a - center).normalized()
			if normal.length_squared() <= 0.001:
				normal = Vector2.UP
			return normal
	return Vector2.ZERO

static func resolve_projectile_segment(layout: Dictionary, previous_pos: Vector2, current_pos: Vector2, velocity: Vector2, radius: float = 5.0, bounces_remaining: int = 0) -> Dictionary:
	var normal: Vector2 = segment_collision_normal(layout, previous_pos, current_pos, radius)
	if normal == Vector2.ZERO:
		return {"hit": false, "expired": false, "position": current_pos, "velocity": velocity, "bounces_remaining": bounces_remaining}
	if bounces_remaining > 0 and velocity.length_squared() > 0.001:
		var bounced_velocity: Vector2 = velocity.bounce(normal)
		var safe_pos: Vector2 = constrain_point(layout, previous_pos + normal * (radius + 2.0), radius)
		return {"hit": true, "expired": false, "position": safe_pos, "velocity": bounced_velocity, "bounces_remaining": bounces_remaining - 1}
	return {"hit": true, "expired": true, "position": previous_pos, "velocity": Vector2.ZERO, "bounces_remaining": 0}
