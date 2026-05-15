class_name RVHubStation
extends Node2D

# Scene-authored hub station.
#
# The station position, child visuals, label placement, and collision radius are
# owned by the .tscn scene. The script only exposes metadata and handles focus.
#
# Expected optional children:
# - Visual: Sprite2D
# - NameLabel: Label
# - InteractionArea/CollisionShape2D: Area2D + CollisionShape2D

@export var station_id: String = ""
@export_enum("activity", "inventory", "crafting", "passive", "skills", "stash", "character", "training", "map_device", "none") var station_type: String = "activity"
@export var display_name: String = "Station"
@export var activity_id: String = ""
@export_multiline var prompt_text: String = "E - Interact"
@export var interaction_radius: float = 56.0
@export var station_color: Color = Color(0.9, 0.75, 0.45, 1.0)
@export var visual_texture: Texture2D
@export var visual_scale: Vector2 = Vector2.ONE
@export var show_label_when_unfocused: bool = true

@onready var visual: Sprite2D = get_node_or_null("Visual")
@onready var name_label: Label = get_node_or_null("NameLabel")
@onready var interaction_area: Area2D = get_node_or_null("InteractionArea")
@onready var collision_shape: CollisionShape2D = get_node_or_null("InteractionArea/CollisionShape2D")

var focused: bool = false

func _ready() -> void:
	apply_scene_values()
	set_focused(false)


func apply_scene_values() -> void:
	if visual != null:
		if visual_texture != null:
			visual.texture = visual_texture
		visual.scale = visual_scale

	if name_label != null:
		name_label.text = display_name
		name_label.modulate = station_color
		name_label.visible = show_label_when_unfocused

	if collision_shape != null:
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = interaction_radius
		collision_shape.shape = circle

	if interaction_area != null:
		interaction_area.monitoring = true
		interaction_area.monitorable = true


func is_player_in_range(player_pos: Vector2) -> bool:
	return global_position.distance_to(player_pos) <= interaction_radius


func distance_to_player(player_pos: Vector2) -> float:
	return global_position.distance_to(player_pos)


func set_focused(value: bool) -> void:
	focused = value

	if visual != null:
		if focused:
			visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
			visual.scale = visual_scale * 1.08
		else:
			visual.modulate = Color(0.82, 0.82, 0.82, 1.0)
			visual.scale = visual_scale

	if name_label != null:
		name_label.visible = show_label_when_unfocused or focused
		if focused:
			name_label.modulate = Color(1.0, 0.90, 0.62, 1.0)
		else:
			name_label.modulate = station_color


func get_prompt() -> String:
	if prompt_text.strip_edges() != "":
		return prompt_text
	return "E - " + display_name
