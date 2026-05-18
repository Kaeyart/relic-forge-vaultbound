class_name RVCraftingTargetDropZone
extends Button

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_CAN_DROP

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and str(Dictionary(data).get("rv_kind", "")) == "crafting_backpack_item"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var panel: Node = _find_crafting_panel()
	if panel != null and panel.has_method("set_crafting_target_index"):
		panel.call("set_crafting_target_index", int(Dictionary(data).get("index", -1)))

func _find_crafting_panel() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("set_crafting_target_index"):
			return node
		node = node.get_parent()
	return null
