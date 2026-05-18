class_name RVCraftingItemDragButton
extends Button

@export var slot_index: int = -1

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_index < 0:
		return null
	var payload: Dictionary = {"rv_kind": "crafting_backpack_item", "index": slot_index}
	var preview: Label = Label.new()
	preview.text = text
	preview.modulate = Color(1.0, 0.86, 0.48, 0.92)
	set_drag_preview(preview)
	return payload
