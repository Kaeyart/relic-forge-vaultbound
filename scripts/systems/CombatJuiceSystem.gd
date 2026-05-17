class_name RVCombatJuiceSystem
extends RefCounted

# Patch 068: combat feel infrastructure.
# Cheap, Godot-native juice: hit stop, screen shake, enemy impulses, tactical callouts.

static func skill_cast_feedback(arena: Node2D, root: Node2D, skill_name: String, origin: Vector2, tags: Array = []) -> void:
	var strength: float = 1.2
	match skill_name:
		"Cleave": strength = 2.4
		"Fireball": strength = 1.8
		"Void Rift": strength = 1.6
		"Frost Nova": strength = 1.2
		"Storm Lance": strength = 0.9
		"Blade Trap": strength = 0.7
	_screen_shake(arena, strength, 0.07)
	_spawn_tactical_text(root, origin + Vector2(0.0, -44.0), skill_name, _color_for_tags(tags), 0.28)

static func enemy_hit_feedback(arena: Node2D, root: Node2D, enemy: Node, amount: float, tags: Array = []) -> void:
	if enemy == null:
		return
	var pos: Vector2 = Vector2.ZERO
	if enemy is Node2D:
		pos = (enemy as Node2D).global_position
	var heavy: bool = amount >= 35.0 or tags.has("Boss") or tags.has("Explosion") or tags.has("Slam")
	var color: Color = _color_for_tags(tags)
	if enemy.has_method("flash_hit"):
		enemy.call("flash_hit")
	if enemy.has_method("apply_stagger"):
		enemy.call("apply_stagger", amount, tags)
	if heavy:
		_request_hit_stop(arena, 0.035, 0.18)
		_screen_shake(arena, 2.0, 0.09)
	else:
		_request_hit_stop(arena, 0.014, 0.28)
	_spawn_micro_burst(root, pos, color, heavy)

static func enemy_kill_feedback(arena: Node2D, root: Node2D, pos: Vector2, tags: Array = []) -> void:
	_request_hit_stop(arena, 0.028, 0.20)
	_screen_shake(arena, 1.8, 0.10)
	_spawn_tactical_text(root, pos + Vector2(0.0, -44.0), "KILL", Color(1.0, 0.86, 0.42, 0.95), 0.42)
	_spawn_radial_lines(root, pos, _color_for_tags(tags), 10, 46.0, 0.24)

static func player_damage_feedback(arena: Node2D, root: Node2D, player_pos: Vector2, amount: float) -> void:
	var strength: float = clamp(amount * 0.16, 1.4, 6.0)
	_screen_shake(arena, strength, 0.13)
	_request_hit_stop(arena, 0.018, 0.30)
	_spawn_tactical_text(root, player_pos + Vector2(0.0, -58.0), "-" + str(int(round(amount))), Color(1.0, 0.18, 0.10, 0.96), 0.34)

static func boss_phase_feedback(arena: Node2D, root: Node2D, pos: Vector2, phase: int) -> void:
	_request_hit_stop(arena, 0.055, 0.16)
	_screen_shake(arena, 5.0, 0.20)
	_spawn_tactical_text(root, pos + Vector2(0.0, -86.0), "BOSS PHASE " + str(phase), Color(1.0, 0.38, 0.10, 1.0), 0.82)
	_spawn_radial_lines(root, pos, Color(1.0, 0.28, 0.08, 0.88), 18, 86.0, 0.42)

static func pack_callout(root: Node2D, pos: Vector2, text: String, danger: bool = false) -> void:
	var color: Color = Color(1.0, 0.80, 0.32, 0.95)
	if danger:
		color = Color(1.0, 0.24, 0.08, 0.98)
	_spawn_tactical_text(root, pos + Vector2(0.0, -72.0), text, color, 0.72)

static func _request_hit_stop(anchor: Node, duration: float, scale: float) -> void:
	if anchor == null or anchor.get_tree() == null:
		return
	if duration <= 0.0:
		return
	var serial: int = int(anchor.get_meta("rf_hitstop_serial", 0)) + 1
	anchor.set_meta("rf_hitstop_serial", serial)
	Engine.time_scale = min(Engine.time_scale, scale)
	var timer := anchor.get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(anchor) and int(anchor.get_meta("rf_hitstop_serial", 0)) == serial:
			Engine.time_scale = 1.0
	)

static func _screen_shake(target: Node2D, strength: float, duration: float) -> void:
	if target == null or strength <= 0.0 or duration <= 0.0:
		return
	if bool(target.get_meta("rf_shake_active", false)):
		return
	target.set_meta("rf_shake_active", true)
	var origin: Vector2 = target.position
	var tween: Tween = target.create_tween()
	var steps: int = 8
	for i: int in range(steps):
		var offset: Vector2 = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(target, "position", origin + offset, duration / float(steps))
	tween.tween_callback(func() -> void:
		if is_instance_valid(target):
			target.position = origin
			target.set_meta("rf_shake_active", false)
	)

static func _spawn_micro_burst(root: Node2D, pos: Vector2, color: Color, heavy: bool) -> void:
	if root == null:
		return
	var count: int = 8 if heavy else 4
	var distance: float = 54.0 if heavy else 28.0
	_spawn_radial_lines(root, pos, color, count, distance, 0.18 if not heavy else 0.28)

static func _spawn_radial_lines(root: Node2D, pos: Vector2, color: Color, count: int, distance: float, life: float) -> void:
	if root == null:
		return
	for i: int in range(max(1, count)):
		var a: float = TAU * float(i) / float(max(1, count)) + randf_range(-0.12, 0.12)
		var start: Vector2 = pos + Vector2(cos(a), sin(a)) * 6.0
		var end: Vector2 = pos + Vector2(cos(a), sin(a)) * randf_range(distance * 0.55, distance)
		var line := Line2D.new()
		line.points = PackedVector2Array([start, end])
		line.width = randf_range(1.5, 4.0)
		line.default_color = color
		line.z_index = 930
		root.add_child(line)
		var tween: Tween = line.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, life)
		tween.tween_callback(line.queue_free)

static func _spawn_tactical_text(root: Node2D, pos: Vector2, text: String, color: Color, life: float) -> void:
	if root == null or text == "":
		return
	var label := Label.new()
	label.text = text
	label.position = pos
	label.z_index = 960
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position", pos + Vector2(0.0, -22.0), life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, life)
	tween.tween_callback(label.queue_free)

static func _color_for_tags(tags: Array) -> Color:
	if tags.has("Fire") or tags.has("Burn"):
		return Color(1.0, 0.34, 0.08, 0.95)
	if tags.has("Cold") or tags.has("Freeze"):
		return Color(0.55, 0.90, 1.0, 0.95)
	if tags.has("Lightning") or tags.has("Shock"):
		return Color(0.74, 0.96, 1.0, 0.95)
	if tags.has("Void") or tags.has("Curse"):
		return Color(0.74, 0.26, 1.0, 0.95)
	if tags.has("Bleed") or tags.has("Physical"):
		return Color(1.0, 0.72, 0.40, 0.95)
	return Color(0.95, 0.86, 0.62, 0.95)
