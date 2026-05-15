class_name RVHubStation
extends Node2D

@export var station_type: String = "activity"
@export var station_id: String = "dungeon_run"
@export var display_name: String = "Dungeon Run"
@export var prompt_text: String = "E interact"
@export var activity_tier: int = 1
@export var activity_threat: float = 1.0
@export var activity_length: int = 5
@export var color: Color = Color(0.90, 0.84, 0.70)

func get_payload() -> Dictionary:
	return {
		"type": station_type,
		"id": station_id,
		"name": display_name,
		"tier": activity_tier,
		"threat": activity_threat,
		"length": activity_length,
		"pos": global_position,
		"color": color
	}
