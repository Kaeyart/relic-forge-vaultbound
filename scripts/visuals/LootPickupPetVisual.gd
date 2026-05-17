class_name RVLootPickupPetVisual
extends Node2D

var target_position: Vector2 = Vector2.ZERO
var pulse: float = 0.0

func _ready() -> void:
	set_process(true)
	queue_redraw()

func sync_from_state(state: Object, player: Node) -> void:
	if state == null:
		visible = false
		return
	visible = bool(state.get("loot_pet_enabled"))
	if player != null and player is Node2D:
		target_position = (player as Node2D).global_position + Vector2(-34.0, -30.0)
	else:
		var value: Variant = state.get("player_pos")
		target_position = (value if typeof(value) == TYPE_VECTOR2 else Vector2.ZERO) + Vector2(-34.0, -30.0)

func _process(delta: float) -> void:
	pulse += delta * 4.0
	global_position = global_position.lerp(target_position, min(1.0, delta * 9.0))
	queue_redraw()

func _draw() -> void:
	var glow_alpha: float = 0.28 + 0.10 * sin(pulse)
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.50, 0.12, glow_alpha))
	draw_circle(Vector2.ZERO, 8.0, Color(0.95, 0.35, 0.08, 0.82))
	draw_polygon(PackedVector2Array([Vector2(0, -15), Vector2(10, 0), Vector2(0, 15), Vector2(-10, 0)]), PackedColorArray([Color(1.0, 0.75, 0.30, 0.92)]))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.95, 0.62, 1.0))
