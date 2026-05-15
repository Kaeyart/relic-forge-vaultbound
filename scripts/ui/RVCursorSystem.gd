class_name RVCursorSystem
extends Node

const CURSOR_NORMAL: Texture2D = preload("res://assets/ui/patch029a_inventory_foundation/slices/cursors/cursor_normal.png")
const CURSOR_HOVER: Texture2D = preload("res://assets/ui/patch029a_inventory_foundation/slices/cursors/cursor_hover.png")
const CURSOR_DRAG: Texture2D = preload("res://assets/ui/patch029a_inventory_foundation/slices/cursors/cursor_drag_item.png")
const CURSOR_INVALID: Texture2D = preload("res://assets/ui/patch029a_inventory_foundation/slices/cursors/cursor_invalid.png")

func _ready() -> void:
	apply_default_cursor()

static func apply_default_cursor() -> void:
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_ARROW, Vector2(8, 8))
	Input.set_custom_mouse_cursor(CURSOR_HOVER, Input.CURSOR_POINTING_HAND, Vector2(8, 8))
	Input.set_custom_mouse_cursor(CURSOR_DRAG, Input.CURSOR_DRAG, Vector2(8, 8))
	Input.set_custom_mouse_cursor(CURSOR_INVALID, Input.CURSOR_FORBIDDEN, Vector2(8, 8))
