extends RVUIPanelBase

@onready var content_label: Label = %ContentLabel

func update_from_state(state: RVGameState) -> void:
	if content_label == null:
		return
	content_label.text = RVInventorySystem.stash_panel_text(state)
