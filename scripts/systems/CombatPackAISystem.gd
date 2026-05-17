class_name RVCombatPackAISystem
extends RefCounted

# Patch 069: cheap crowd steering and pack behavior.
# Keeps enemies from collapsing into one blob and gives roles better positioning.

static func apply_context(enemy: Node2D, enemies_root: Node, player_pos: Vector2, delta: float) -> void:
	if enemy == null or enemies_root == null or delta <= 0.0:
		return
	var role: String = str(enemy.get("role"))
	var radius: float = float(enemy.get("radius"))
	var speed: float = float(enemy.get("speed"))
	_apply_separation(enemy, enemies_root, radius, delta)
	_apply_role_spacing(enemy, role, speed, player_pos, delta)

static func _apply_separation(enemy: Node2D, enemies_root: Node, radius: float, delta: float) -> void:
	var push: Vector2 = Vector2.ZERO
	for other_node: Node in enemies_root.get_children():
		if other_node == enemy or not (other_node is Node2D):
			continue
		var other: Node2D = other_node as Node2D
		var other_radius: float = 14.0
		if other.has_method("get"):
			other_radius = float(other.get("radius"))
		var diff: Vector2 = enemy.global_position - other.global_position
		var distance: float = diff.length()
		var min_distance: float = max(18.0, radius + other_radius + 8.0)
		if distance > 0.001 and distance < min_distance:
			push += diff.normalized() * ((min_distance - distance) / min_distance)
	if push.length() > 0.001:
		enemy.global_position += push.normalized() * min(56.0, 18.0 + push.length() * 44.0) * delta

static func _apply_role_spacing(enemy: Node2D, role: String, speed: float, player_pos: Vector2, delta: float) -> void:
	var to_player: Vector2 = player_pos - enemy.global_position
	var distance: float = to_player.length()
	if distance <= 0.001:
		return
	var dir: Vector2 = to_player / distance
	match role:
		"shooter", "caster", "binder", "caller":
			if distance < 190.0:
				enemy.global_position -= dir * speed * 0.34 * delta
		"brute", "knight":
			# Heavies drift toward center-line and hold space instead of overstacking.
			if distance < 54.0:
				enemy.global_position -= dir * speed * 0.12 * delta
		"lunger", "hound":
			# Flankers get a small lateral bias so they do not all charge the same line.
			if distance > 80.0 and distance < 260.0:
				var side: Vector2 = dir.rotated(PI * 0.5)
				enemy.global_position += side * sin(Time.get_ticks_msec() * 0.004 + enemy.global_position.x * 0.01) * speed * 0.10 * delta
