class_name RVPlayerActor
extends Node2D

func sync_from_state(state: RVGameState) -> void:
	global_position = state.player_pos
	queue_redraw()


func apply_to_state(state: RVGameState) -> void:
	state.player_pos = global_position


func _draw() -> void:
	draw_circle(Vector2(6.0, 10.0), 20.0, Color(0.0, 0.0, 0.0, 0.32))
	draw_circle(Vector2.ZERO, 16.0, Color(0.025, 0.025, 0.030))
	draw_circle(Vector2.ZERO, 11.0, Color(0.92, 0.84, 0.66))
	draw_polygon(
		PackedVector2Array([Vector2(22.0, 0.0), Vector2(-8.0, 9.0), Vector2(-8.0, -9.0)]),
		PackedColorArray([Color(1.0, 0.68, 0.26)])
	)
