class_name RVPassiveAtlasPanel
extends RVUIPanelBase

@onready var content_label: Label = get_node_or_null("%ContentLabel") as Label
@onready var title_label: Label = get_node_or_null("%TitleLabel") as Label

func update_from_state(state: RVGameState) -> void:
	if content_label == null:
		return
	if title_label != null:
		title_label.text = "Passive Atlas"
	content_label.text = _build_text(state)

func _build_text(state: RVGameState) -> String:
	RVClassAscendancySystem.ensure_defaults(state)
	var text: String = RVSaveSystem.roster_summary()
	text += "\n" + RVClassAscendancySystem.panel_text(state)
	text += "\nCharacter slots: press 1-9 or 0 while this panel is open. Current slot auto-saves before switching.\n"
	text += "Class is chosen per character save. Press C before locking, then Enter to lock.\n"
	return text
