class_name RVGameHUD
extends CanvasLayer
@onready var flask_hud: Node = get_node_or_null("%FlaskHUD")

@onready var top_status_label: Label = %TopStatusLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var mana_bar: ProgressBar = %ManaBar
@onready var skill_bar: HBoxContainer = %SkillBar
@onready var prompt_label: Label = %PromptLabel
@onready var notice_label: Label = %NoticeLabel
@onready var notice_panel: Control = %NoticePanel
@onready var objective_panel: Control = get_node_or_null("%ObjectivePanel") as Control
@onready var objective_label: Label = get_node_or_null("%ObjectiveLabel") as Label

func update_from_state(state: RVGameState) -> void:

	if flask_hud == null:
		flask_hud = get_node_or_null("%FlaskHUD")
	if flask_hud != null and flask_hud.has_method("update_from_state"):
		flask_hud.call("update_from_state", state)
	top_status_label.text = "Lv %s  XP %s/%s  Gold %s  MP %s  Refund %s  Spirit %s/%s" % [
		state.level,
		int(state.xp),
		int(state.xp_to_next()),
		state.gold,
		state.mastery_points,
		state.refund_points,
		state.spirit_reserved,
		state.spirit_max
	]

	health_bar.max_value = state.max_hp
	health_bar.value = state.player_hp
	mana_bar.max_value = state.max_mana
	mana_bar.value = state.player_mana

	_update_skill_bar(state)

	prompt_label.text = state.prompt_text
	prompt_label.visible = state.prompt_text != ""

	notice_label.text = state.notice_text
	notice_panel.visible = state.notice_time > 0.0

	if objective_panel != null and objective_label != null:
		objective_label.text = state.room_objective
		objective_panel.visible = state.mode == "combat" and state.room_objective != ""


func _update_skill_bar(state: RVGameState) -> void:
	for index: int in range(skill_bar.get_child_count()):
		var slot: Control = skill_bar.get_child(index)
		var label: Label = slot.get_node_or_null("Label")
		var selected_frame: Control = slot.get_node_or_null("SelectedFrame")

		if label != null:
			if index < state.active_skills.size():
				label.text = str(index + 1) + " " + str(state.active_skills[index])
			else:
				label.text = str(index + 1) + " -"

		if selected_frame != null:
			selected_frame.visible = index == state.selected_skill_index
