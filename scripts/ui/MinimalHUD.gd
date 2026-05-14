extends CanvasLayer

# RELIC FORGE: VAULTBOUND
# Patch 004 UI Rebuild
# Minimalist combat-first HUD + clean side drawer + centered choice sheet.

var root: Control

var status_panel: PanelContainer
var room_panel: PanelContainer
var action_panel: PanelContainer
var drawer_panel: PanelContainer
var choice_panel: PanelContainer
var prompt_panel: PanelContainer
var notice_panel: PanelContainer

var hp_bar: ProgressBar
var mana_bar: ProgressBar
var hp_label: Label
var mana_label: Label
var meta_label: Label

var room_label: Label
var action_title: Label
var prompt_label: Label
var notice_label: Label

var drawer_title: Label
var drawer_body: RichTextLabel

var choice_title: Label
var choice_subtitle: Label
var choice_rows: VBoxContainer

var skill_labels: Array = []

var last_notice_text: String = ""
var notice_timer: float = 0.0

func _ready() -> void:
	layer = 50
	_build_ui()


func _process(delta: float) -> void:
	if notice_timer > 0.0:
		notice_timer -= delta
		if notice_timer <= 0.0:
			notice_panel.visible = false


func _build_ui() -> void:
	root = Control.new()
	root.name = "MinimalHUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var panel_style = _make_panel_style(false)
	var strong_style = _make_panel_style(true)
	var chip_style = _make_chip_style()

	status_panel = _make_panel("StatusPanel", panel_style, Vector2(16, 604), Vector2(290, 92))
	root.add_child(status_panel)

	var status_v = VBoxContainer.new()
	status_v.add_theme_constant_override("separation", 4)
	status_panel.add_child(status_v)

	meta_label = _make_label("Level 1  ·  Depth 0/16", 12, Color(0.76, 0.72, 0.66))
	status_v.add_child(meta_label)

	hp_label = _make_label("HP 120/120", 12, Color(0.92, 0.86, 0.78))
	status_v.add_child(hp_label)

	hp_bar = _make_bar()
	status_v.add_child(hp_bar)

	mana_label = _make_label("Mana 100/100", 12, Color(0.74, 0.82, 0.94))
	status_v.add_child(mana_label)

	mana_bar = _make_bar()
	status_v.add_child(mana_bar)

	room_panel = _make_panel("RoomPanel", chip_style, Vector2(385, 16), Vector2(510, 42))
	root.add_child(room_panel)

	room_label = _make_label("Combat · Ash Crypt · 0 enemies", 12, Color(0.86, 0.82, 0.74))
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_panel.add_child(room_label)

	action_panel = _make_panel("ActionPanel", panel_style, Vector2(342, 626), Vector2(596, 62))
	root.add_child(action_panel)

	var action_v = VBoxContainer.new()
	action_v.add_theme_constant_override("separation", 4)
	action_panel.add_child(action_v)

	action_title = _make_label("Choose a skill draft", 12, Color(0.95, 0.90, 0.82))
	action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_v.add_child(action_title)

	var action_h = HBoxContainer.new()
	action_h.alignment = BoxContainer.ALIGNMENT_CENTER
	action_h.add_theme_constant_override("separation", 6)
	action_v.add_child(action_h)

	for i in range(6):
		var slot = Label.new()
		slot.text = str(i + 1) + "  —"
		slot.custom_minimum_size = Vector2(88, 24)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_theme_font_size_override("font_size", 12)
		slot.add_theme_color_override("font_color", Color(0.72, 0.68, 0.60))
		slot.add_theme_stylebox_override("normal", _make_slot_style(false, false, false))
		skill_labels.append(slot)
		action_h.add_child(slot)

	drawer_panel = _make_panel("DrawerPanel", strong_style, Vector2(930, 86), Vector2(334, 586))
	root.add_child(drawer_panel)

	var drawer_v = VBoxContainer.new()
	drawer_v.add_theme_constant_override("separation", 6)
	drawer_panel.add_child(drawer_v)

	drawer_title = _make_label("BUILD", 14, Color(0.95, 0.90, 0.82))
	drawer_v.add_child(drawer_title)

	drawer_body = RichTextLabel.new()
	drawer_body.bbcode_enabled = false
	drawer_body.fit_content = false
	drawer_body.scroll_active = true
	drawer_body.custom_minimum_size = Vector2(308, 534)
	drawer_body.add_theme_font_size_override("normal_font_size", 12)
	drawer_body.add_theme_color_override("default_color", Color(0.82, 0.79, 0.73))
	drawer_v.add_child(drawer_body)

	prompt_panel = _make_panel("PromptPanel", chip_style, Vector2(1035, 678), Vector2(230, 26))
	root.add_child(prompt_panel)

	prompt_label = _make_label("", 11, Color(0.88, 0.84, 0.76))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)
	prompt_panel.visible = false

	notice_panel = _make_panel("NoticePanel", chip_style, Vector2(446, 68), Vector2(388, 30))
	root.add_child(notice_panel)

	notice_label = _make_label("", 12, Color(1.0, 0.90, 0.60))
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_panel.add_child(notice_label)
	notice_panel.visible = false

	choice_panel = _make_panel("ChoicePanel", strong_style, Vector2(260, 104), Vector2(760, 470))
	root.add_child(choice_panel)

	var choice_v = VBoxContainer.new()
	choice_v.add_theme_constant_override("separation", 8)
	choice_panel.add_child(choice_v)

	choice_title = _make_label("CHOICE", 18, Color(0.96, 0.92, 0.84))
	choice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_v.add_child(choice_title)

	choice_subtitle = _make_label("Pick an option with number keys", 12, Color(0.76, 0.72, 0.66))
	choice_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_v.add_child(choice_subtitle)

	choice_rows = VBoxContainer.new()
	choice_rows.add_theme_constant_override("separation", 8)
	choice_v.add_child(choice_rows)

	choice_panel.visible = false


func update_ui(data: Dictionary) -> void:
	var hp = float(data.get("hp", 0.0))
	var hp_max = max(1.0, float(data.get("hp_max", 100.0)))
	var mana = float(data.get("mana", 0.0))
	var mana_max = max(1.0, float(data.get("mana_max", 100.0)))
	var level = int(data.get("level", 1))
	var depth = int(data.get("depth", 0))
	var max_depth = int(data.get("max_depth", 16))
	var passive_points = int(data.get("passive_points", 0))
	var room_type = str(data.get("room_type", "Combat"))
	var room_biome = str(data.get("room_biome", "Unknown"))
	var enemies = int(data.get("enemies", 0))
	var active_skills = data.get("active_skills", [])
	var selected_skill = int(data.get("selected_skill", 0))
	var cooldowns = data.get("cooldowns", {})
	var mana_costs = data.get("mana_costs", {})
	var open_panel = str(data.get("open_panel", "build"))
	var drawer_visible = bool(data.get("drawer_visible", true))
	var interact_hint = str(data.get("interact_hint", ""))
	var build_summary = str(data.get("build_summary", ""))
	var inventory_summary = str(data.get("inventory_summary", ""))
	var skilltree_summary = str(data.get("skilltree_summary", ""))
	var dungeon_summary = str(data.get("dungeon_summary", ""))
	var choice_active = bool(data.get("choice_active", false))
	var choice_title_text = str(data.get("choice_title", ""))
	var choice_subtitle_text = str(data.get("choice_subtitle", ""))
	var choices = data.get("choices", [])
	var notice = str(data.get("notice", ""))

	hp_label.text = "HP  " + str(int(hp)) + " / " + str(int(hp_max))
	hp_bar.max_value = hp_max
	hp_bar.value = clamp(hp, 0.0, hp_max)

	mana_label.text = "MANA  " + str(int(mana)) + " / " + str(int(mana_max))
	mana_bar.max_value = mana_max
	mana_bar.value = clamp(mana, 0.0, mana_max)

	meta_label.text = "Level " + str(level) + "  ·  Depth " + str(depth) + "/" + str(max_depth) + "  ·  Passive " + str(passive_points)
	room_label.text = room_type + "  ·  " + room_biome + "  ·  " + str(enemies) + " enemies"

	var selected_name = "No skill selected"
	if selected_skill >= 0 and selected_skill < active_skills.size():
		selected_name = str(active_skills[selected_skill])
	action_title.text = selected_name

	for i in range(skill_labels.size()):
		var slot = skill_labels[i] as Label
		if i < active_skills.size():
			var skill_name = str(active_skills[i])
			var cd = float(cooldowns.get(skill_name, 0.0))
			var cost = float(mana_costs.get(skill_name, 0.0))
			var affordable = mana >= cost
			var ready = cd <= 0.05
			var selected = i == selected_skill
			var suffix = ""
			if not ready:
				suffix = " " + str(snapped(cd, 0.1))
			elif not affordable:
				suffix = " nm"
			slot.text = str(i + 1) + "  " + _short_skill(skill_name) + suffix
			slot.add_theme_color_override("font_color", Color(0.97, 0.90, 0.82) if selected else Color(0.78, 0.74, 0.68))
			slot.add_theme_stylebox_override("normal", _make_slot_style(selected, ready, affordable))
		else:
			slot.text = str(i + 1) + "  —"
			slot.add_theme_color_override("font_color", Color(0.48, 0.45, 0.40))
			slot.add_theme_stylebox_override("normal", _make_slot_style(false, false, false))

	drawer_panel.visible = drawer_visible
	match open_panel:
		"inventory":
			drawer_title.text = "INVENTORY"
			drawer_body.text = inventory_summary
		"skilltree":
			drawer_title.text = "SKILL TREE"
			drawer_body.text = skilltree_summary
		"dungeon":
			drawer_title.text = "DUNGEON"
			drawer_body.text = dungeon_summary
		_:
			drawer_title.text = "BUILD"
			drawer_body.text = build_summary

	prompt_panel.visible = interact_hint != ""
	prompt_label.text = interact_hint

	_render_choice_sheet(choice_active, choice_title_text, choice_subtitle_text, choices)

	if notice != "":
		push_notice(notice)


func push_notice(text: String) -> void:
	if text == "" or text == last_notice_text:
		return
	last_notice_text = text
	notice_label.text = text
	notice_panel.visible = true
	notice_timer = 2.0


func _render_choice_sheet(active: bool, title_text: String, subtitle_text: String, choices: Array) -> void:
	choice_panel.visible = active
	if not active:
		return

	choice_title.text = title_text
	choice_subtitle.text = subtitle_text

	for c in choice_rows.get_children():
		c.queue_free()

	var idx = 1
	for choice in choices:
		var row = PanelContainer.new()
		row.add_theme_stylebox_override("panel", _make_card_style())
		choice_rows.add_child(row)

		var row_v = VBoxContainer.new()
		row_v.add_theme_constant_override("separation", 3)
		row.add_child(row_v)

		var name_label = _make_label(str(idx) + ". " + str(choice.get("name", "Option")), 13, Color(0.94, 0.89, 0.80))
		row_v.add_child(name_label)

		var desc_label = _make_label(str(choice.get("desc", "")), 11, Color(0.76, 0.73, 0.68))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_v.add_child(desc_label)

		idx += 1

	if choices.size() == 0:
		var empty_label = _make_label("No visible options.", 12, Color(0.72, 0.68, 0.62))
		choice_rows.add_child(empty_label)


func _make_panel(name_text: String, style: StyleBox, pos: Vector2, size: Vector2) -> PanelContainer:
	var p = PanelContainer.new()
	p.name = name_text
	p.position = pos
	p.custom_minimum_size = size
	p.add_theme_stylebox_override("panel", style)
	return p


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.clip_text = false
	return l


func _make_bar() -> ProgressBar:
	var b = ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 100.0
	b.value = 100.0
	b.show_percentage = false
	b.custom_minimum_size = Vector2(260, 10)
	return b


func _make_panel_style(strong: bool) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	if strong:
		s.bg_color = Color(0.02, 0.021, 0.024, 0.93)
		s.border_color = Color(0.58, 0.50, 0.39, 0.42)
	else:
		s.bg_color = Color(0.03, 0.031, 0.035, 0.78)
		s.border_color = Color(0.50, 0.45, 0.36, 0.30)
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


func _make_chip_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.03, 0.031, 0.035, 0.72)
	s.border_color = Color(0.50, 0.45, 0.36, 0.24)
	s.set_border_width_all(1)
	s.set_corner_radius_all(14)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _make_slot_style(selected: bool, ready: bool, affordable: bool) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.09, 0.10, 0.88)
	if selected:
		s.border_color = Color(0.92, 0.78, 0.46, 0.80)
	elif not ready:
		s.border_color = Color(0.58, 0.56, 0.68, 0.44)
	elif not affordable:
		s.border_color = Color(0.68, 0.44, 0.44, 0.44)
	else:
		s.border_color = Color(0.42, 0.40, 0.36, 0.28)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left = 5
	s.content_margin_right = 5
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s


func _make_card_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.06, 0.07, 0.92)
	s.border_color = Color(0.56, 0.48, 0.37, 0.36)
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func _short_skill(skill_name: String) -> String:
	match skill_name:
		"Fireball":
			return "FIRE"
		"Cleave":
			return "CLEAVE"
		"Frost Nova":
			return "NOVA"
		"Storm Lance":
			return "LANCE"
		"Void Rift":
			return "RIFT"
		"Blade Trap":
			return "TRAP"
		_:
			return skill_name.to_upper()
