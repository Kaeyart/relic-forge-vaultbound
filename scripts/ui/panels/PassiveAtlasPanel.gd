class_name RVPassiveAtlasPanel
extends RVUIPanelBase

var current_state: RVGameState = null
var content_label: Label = null
var detail_label: RichTextLabel = null

func _ready() -> void:
	super._ready()
	content_label = get_node_or_null("%ContentLabel") as Label
	if content_label == null:
		content_label = Label.new()
		content_label.name = "ContentLabel"
		content_label.position = Vector2(24.0, 24.0)
		content_label.size = Vector2(780.0, 520.0)
		content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(content_label)

func update_from_state(state: RVGameState) -> void:
	current_state = state
	if current_state == null:
		return
	current_state.ensure_defaults()
	if content_label != null:
		content_label.text = RVClassAscendancySystem.passive_summary(current_state)

func handle_panel_key(state: RVGameState, keycode: int) -> bool:
	var handled: bool = RVClassAscendancySystem.handle_panel_key(state, keycode)
	if handled:
		update_from_state(state)
	return handled
