class_name RVFloatingCombatTextSystem
extends RefCounted

static func spawn_text(root: Node2D, world_pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 16, lifetime: float = 0.75, velocity: Vector2 = Vector2(0, -44)) -> Label:
	if root == null:
		return null
	var label: Label = Label.new()
	label.name = "FloatingText"
	label.text = text
	label.position = world_pos
	label.z_as_relative = false
	label.z_index = 120
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	_animate_float(label, lifetime, velocity)
	return label

static func spawn_damage(root: Node2D, world_pos: Vector2, amount: float, tags: Array = [], crit: bool = false) -> void:
	var color: Color = _damage_color(tags, crit)
	var size: int = 18 if crit or amount >= 80.0 else 14
	var prefix: String = "✦ " if crit else ""
	spawn_text(root, world_pos + Vector2(randf_range(-8.0, 8.0), -12.0), prefix + str(int(round(amount))), color, size, 0.78, Vector2(randf_range(-12.0, 12.0), -46.0))

static func spawn_callout(root: Node2D, world_pos: Vector2, label_text: String, color: Color = Color(1.0, 0.82, 0.32), size: int = 15) -> void:
	spawn_text(root, world_pos + Vector2(0, -28), label_text, color, size, 0.95, Vector2(0, -32))

static func _damage_color(tags: Array, crit: bool) -> Color:
	if crit:
		return Color(1.0, 0.78, 0.24)
	if tags.has("Fire") or tags.has("Burn") or tags.has("inflicts_burn"):
		return Color(1.0, 0.42, 0.16)
	if tags.has("Cold") or tags.has("Freeze") or tags.has("inflicts_freeze"):
		return Color(0.52, 0.84, 1.0)
	if tags.has("Lightning") or tags.has("Shock"):
		return Color(0.80, 0.92, 1.0)
	if tags.has("Void") or tags.has("Curse"):
		return Color(0.78, 0.48, 1.0)
	if tags.has("Bleed") or tags.has("Physical"):
		return Color(1.0, 0.72, 0.54)
	return Color(0.92, 0.88, 0.74)

static func _animate_float(label: Label, lifetime: float, velocity: Vector2) -> void:
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + velocity, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, lifetime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
