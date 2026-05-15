class_name RVGameHUD
extends CanvasLayer

@onready var top_label: Label = $Root/TopStatus/Label
@onready var hp_fill: ColorRect = $Root/BottomHUD/HPBar/Fill
@onready var mana_fill: ColorRect = $Root/BottomHUD/ManaBar/Fill
@onready var prompt_label: Label = $Root/PromptBanner/Label
@onready var notice_label: Label = $Root/NoticeBanner/Label
@onready var panel_root: Control = $Root/PanelRoot
@onready var panel_label: Label = $Root/PanelRoot/PanelText

var skill_labels: Array = []

func _ready() -> void:
	for i in range(6):
		skill_labels.append(get_node("Root/SkillBar/Slot" + str(i) + "/Label"))

func update_from_state(state: RVGameState) -> void:
	top_label.text = "Lv %s   XP %s/%s   Passives %s   Refund %s   Spirit %s/%s   Gold %s" % [state.level, int(state.xp), int(state.xp_to_next()), state.mastery_points, state.refund_points, state.spirit_reserved, state.spirit_max, state.gold]
	var hp_pct: float = clamp(state.player_hp / max(1.0, state.max_hp), 0.0, 1.0)
	var mana_pct: float = clamp(state.player_mana / max(1.0, state.max_mana), 0.0, 1.0)
	hp_fill.size.x = 228.0 * hp_pct
	mana_fill.size.x = 228.0 * mana_pct
	for i in range(skill_labels.size()):
		var label: Label = skill_labels[i]
		if i < state.active_skills.size():
			label.text = str(i + 1) + "\n" + str(state.active_skills[i])
			label.modulate = Color(1.0, 0.84, 0.42) if i == state.selected_skill else Color(0.85, 0.82, 0.74)
		else:
			label.text = str(i + 1) + "\n-"
			label.modulate = Color(0.42, 0.40, 0.36)
	prompt_label.text = state.prompt
	$Root/PromptBanner.visible = state.prompt != ""
	notice_label.text = state.notice
	$Root/NoticeBanner.visible = state.notice_time > 0.0
	panel_root.visible = state.panel_mode != ""
	if state.panel_mode == "passive_tree":
		panel_label.text = _passive_text(state)
	elif state.panel_mode == "skill_gems":
		panel_label.text = _skill_text(state)
	elif state.panel_mode == "crafting":
		panel_label.text = _crafting_text(state)
	else:
		panel_label.text = ""

func _passive_text(state: RVGameState) -> String:
	var t: String = "PASSIVE TREE\n\nAllocate points at shrine stations for now.\n\n"
	for k in state.passives.keys():
		t += str(k) + ": " + str(state.passives[k]) + "\n"
	return t

func _skill_text(state: RVGameState) -> String:
	var t: String = "SKILL GEMS\n\n1-6 in Hub toggles skills into Loadout.\nQ/E in Combat cycles selected skill.\n\nLoadout:\n"
	for skill in state.active_skills:
		t += "- " + str(skill) + " Rank " + str(state.skill_ranks.get(skill, 0)) + "\n"
	return t

func _crafting_text(state: RVGameState) -> String:
	return "CRAFTING\n\nScene-driven crafting bench placeholder.\nUse Forge stations in the hub.\n\nMaterials:\nEmbers: %s\nShards: %s\nRunes: %s\nEcho Glass: %s" % [state.materials.get("embers", 0), state.materials.get("shards", 0), state.materials.get("runes", 0), state.materials.get("echo_glass", 0)]
