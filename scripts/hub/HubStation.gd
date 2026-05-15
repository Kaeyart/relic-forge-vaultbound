class_name RVHubStation
extends Node2D

@export var station_id: String = ""
@export var station_type: String = "activity"
@export var display_name: String = "Station"
@export var activity_id: String = ""
@export var prompt_text: String = "Press E"
@export var radius: float = 52.0
@export var station_color: Color = Color(0.9, 0.75, 0.45)

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(4.0, 8.0), radius * 0.55, Color(0.0, 0.0, 0.0, 0.28))
	draw_circle(Vector2.ZERO, radius * 0.42, Color(0.035, 0.032, 0.034, 0.96))
	draw_arc(Vector2.ZERO, radius * 0.50, -PI, PI, 64, station_color, 3.0)

	var font: Font = ThemeDB.fallback_font
	var label_size: Vector2 = font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_string(font, Vector2(-label_size.x * 0.5, radius * 0.72), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, station_color)
