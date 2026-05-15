class_name RVUIPanelBase
extends Control

var bound_state: Object = null

func open_panel(state: Object) -> void:
	bound_state = state
	visible = true
	refresh(state)


func close_panel() -> void:
	visible = false


func refresh(state: Object) -> void:
	bound_state = state


func _set_rich_text(path: String, text_value: String) -> void:
	var node: Node = get_node_or_null(path)
	if node != null and node is RichTextLabel:
		var label: RichTextLabel = node
		label.text = text_value


func _arr(state: Object, key: String) -> Array:
	if state == null:
		return []
	var value: Variant = state.get(key)
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _dict(state: Object, key: String) -> Dictionary:
	if state == null:
		return {}
	var value: Variant = state.get(key)
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _int(state: Object, key: String, fallback: int = 0) -> int:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)
	return fallback


func _float(state: Object, key: String, fallback: float = 0.0) -> float:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)
	return fallback


func _string_from_item(item: Variant) -> String:
	if typeof(item) != TYPE_DICTIONARY:
		return "Empty"
	var d: Dictionary = item
	if d.is_empty():
		return "Empty"
	var line: String = str(d.get("name", "Item"))
	line += "  [" + str(d.get("rarity", "Common")) + "]"
	line += "\nSlot: " + str(d.get("slot", "none"))
	var stats: Dictionary = d.get("stats", {})
	if not stats.is_empty():
		line += "\nStats:"
		for key in stats.keys():
			line += "\n  " + str(key).replace("_", " ").capitalize() + ": " + str(stats[key])
	var flags: Array = d.get("flags", [])
	if flags.size() > 0:
		line += "\nFlags: " + ", ".join(flags)
	return line
