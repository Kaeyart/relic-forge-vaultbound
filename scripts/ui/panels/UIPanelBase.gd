class_name RVUIPanelBase
extends Control

@export var title: String = "Panel"
@onready var title_label: Label = get_node_or_null("TitleLabel")

func _ready() -> void:
	if title_label != null:
		title_label.text = title


func update_from_state(_state: RVGameState) -> void:
	pass
