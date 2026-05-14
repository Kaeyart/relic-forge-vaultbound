class_name RVRenderSystem
extends RefCounted

static func draw_world(node: Node2D, state: RVGameState, textures: Dictionary) -> void:
	if state.mode == "hub": draw_hub(node, state, textures)
	else: draw_combat(node, state, textures)
	draw_entities(node, state, textures)
	draw_hud(node, state, textures)


static func draw_hub(node: Node2D, state: RVGameState, textures: Dictionary) -> void:
	var rect: Rect2 = state.hub_bounds.grow(25.0)
	node.draw_rect(rect, Color(0.014, 0.013, 0.016, 0.96), true)
	node.draw_rect(rect, Color(0.70, 0.54, 0.30, 0.24), false, 2.0)
	var c: Vector2 = Vector2(640.0, 370.0)
	node.draw_arc(c, 265.0, -PI, PI, 128, Color(0.85, 0.62, 0.34, 0.10), 2.0)
	node.draw_arc(c, 160.0, -PI, PI, 128, Color(0.85, 0.62, 0.34, 0.14), 2.0)
	draw_label(node, Vector2(640.0, 95.0), "CONTRACT GATES", Color(0.90, 0.58, 1.0))
	draw_label(node, Vector2(990.0, 185.0), "FORGE", Color(1.0, 0.48, 0.18))
	draw_label(node, Vector2(330.0, 185.0), "MASTERY SHRINES", Color(0.74, 0.62, 1.0))
	draw_label(node, Vector2(650.0, 500.0), "SKILL ALTARS", Color(0.56, 1.0, 0.76))
	draw_label(node, Vector2(690.0, 395.0), "STASH / ARMORY", Color(0.95, 0.78, 0.34))
	for obj in state.hub_objects: draw_hub_object(node, state, obj, textures)


static func draw_hub_object(node: Node2D, state: RVGameState, obj: Dictionary, textures: Dictionary) -> void:
	var pos: Vector2 = obj["pos"]; var color: Color = obj.get("color", Color(0.90, 0.84, 0.70)); var kind: String = str(obj["type"])
	var focused: bool = false
	if not state.focused_object.is_empty(): focused = state.focused_object.get("name", "") == obj.get("name", "") and state.player_pos.distance_to(pos) <= 56.0
	var radius: float = 31.0 if focused else 24.0
	node.draw_circle(pos + Vector2(5.0, 8.0), radius + 6.0, Color(0.0, 0.0, 0.0, 0.30))
	if kind == "contract":
		node.draw_arc(pos, radius + 8.0, -PI, PI, 64, Color(color.r, color.g, color.b, 0.65), 4.0)
		node.draw_line(pos + Vector2(-18.0, 18.0), pos + Vector2(0.0, -22.0), color, 3.0)
		node.draw_line(pos + Vector2(18.0, 18.0), pos + Vector2(0.0, -22.0), color, 3.0)
	elif kind == "forge":
		node.draw_rect(Rect2(pos - Vector2(22.0, 12.0), Vector2(44.0, 24.0)), Color(0.035, 0.032, 0.034), true)
		node.draw_rect(Rect2(pos - Vector2(22.0, 12.0), Vector2(44.0, 24.0)), color, false, 3.0)
	elif kind == "passive":
		var pts: PackedVector2Array = PackedVector2Array([pos + Vector2(0.0, -radius), pos + Vector2(radius * 0.75, 0.0), pos + Vector2(0.0, radius), pos + Vector2(-radius * 0.75, 0.0)])
		node.draw_polygon(pts, PackedColorArray([Color(0.030, 0.028, 0.034, 0.96)])); node.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), color, 3.0)
	elif kind == "skill":
		node.draw_circle(pos, radius, Color(0.030, 0.028, 0.034, 0.96)); node.draw_arc(pos, radius + 4.0, -PI, PI, 64, color, 3.0)
		var skill: String = str(obj.get("data", ""));
		if state.active_skills.has(skill): node.draw_circle(pos, 10.0, color)
	else:
		node.draw_circle(pos, radius, Color(0.030, 0.028, 0.034, 0.96)); node.draw_arc(pos, radius + 4.0, -PI, PI, 64, color, 3.0)
	draw_label(node, pos + Vector2(0.0, radius + 22.0), str(obj["name"]), color)


static func draw_combat(node: Node2D, state: RVGameState, textures: Dictionary) -> void:
	node.draw_rect(state.arena, Color(0.030, 0.022, 0.018, 0.98), true); node.draw_rect(state.arena, Color(0.75, 0.33, 0.16, 0.24), false, 2.0)
	var x: float = state.arena.position.x
	while x <= state.arena.end.x:
		node.draw_line(Vector2(x, state.arena.position.y), Vector2(x, state.arena.end.y), Color(0.75, 0.33, 0.16, 0.045), 1.0); x += 72.0
	var y: float = state.arena.position.y
	while y <= state.arena.end.y:
		node.draw_line(Vector2(state.arena.position.x, y), Vector2(state.arena.end.x, y), Color(0.75, 0.33, 0.16, 0.045), 1.0); y += 72.0
	for ob in state.obstacles:
		var pos: Vector2 = ob.get("pos", Vector2.ZERO); var radius: float = float(ob.get("radius", 24.0))
		node.draw_circle(pos + Vector2(6.0, 9.0), radius + 3.0, Color(0.0, 0.0, 0.0, 0.32)); node.draw_circle(pos, radius, Color(0.10, 0.085, 0.075, 0.95)); node.draw_arc(pos, radius, -PI, PI, 40, Color(0.48, 0.38, 0.28, 0.45), 2.0)


static func draw_entities(node: Node2D, state: RVGameState, textures: Dictionary) -> void:
	for z in state.zones:
		var pos: Vector2 = z["pos"]; var radius: float = float(z["radius"]); var color: Color = color_for_tags(z.get("tags", []))
		node.draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.10)); node.draw_arc(pos, radius, -PI, PI, 72, Color(color.r, color.g, color.b, 0.52), 3.0)
	for p in state.projectiles:
		var pos2: Vector2 = p["pos"]; var color2: Color = color_for_tags(p.get("tags", []))
		node.draw_circle(pos2, float(p["radius"]) * 2.0, Color(color2.r, color2.g, color2.b, 0.18)); node.draw_circle(pos2, float(p["radius"]), color2)
	for e in state.enemies:
		if float(e["hp"]) <= 0.0: continue
		var epos: Vector2 = e["pos"]; var er: float = float(e["radius"]); var ecol: Color = e.get("color", Color(0.90, 0.25, 0.15)); var role: String = str(e.get("role", "chaser"))
		node.draw_circle(epos + Vector2(6.0, 10.0), er * 1.15, Color(0.0, 0.0, 0.0, 0.36))
		if role == "brute": draw_hex(node, epos, er * 1.15, Color(0.030, 0.032, 0.038), ecol)
		elif role == "shooter" or role == "spitter": draw_diamond(node, epos, er * 1.2, Color(0.030, 0.030, 0.037), ecol)
		else:
			node.draw_circle(epos, er, Color(0.030, 0.030, 0.036)); node.draw_circle(epos, er * 0.70, ecol)
		var pct: float = clamp(float(e["hp"]) / max(1.0, float(e["max_hp"])), 0.0, 1.0)
		node.draw_rect(Rect2(epos + Vector2(-er, -er - 12.0), Vector2(er * 2.0, 4.0)), Color(0.08, 0.04, 0.04, 0.75), true)
		node.draw_rect(Rect2(epos + Vector2(-er, -er - 12.0), Vector2(er * 2.0 * pct, 4.0)), Color(0.90, 0.20, 0.14, 0.85), true)
	draw_player(node, state)


static func draw_player(node: Node2D, state: RVGameState) -> void:
	var pos: Vector2 = state.player_pos; var aim: Vector2 = node.get_global_mouse_position(); var dir: Vector2 = aim - pos
	if dir.length() < 0.01: dir = Vector2.RIGHT
	else: dir = dir.normalized()
	var side: Vector2 = Vector2(-dir.y, dir.x)
	node.draw_circle(pos + Vector2(6.0, 10.0), 20.0, Color(0.0, 0.0, 0.0, 0.36)); node.draw_circle(pos, 17.0, Color(0.020, 0.020, 0.024)); node.draw_circle(pos, 12.0, Color(0.92, 0.84, 0.66))
	node.draw_polygon(PackedVector2Array([pos + dir * 25.0, pos - dir * 9.0 + side * 9.0, pos - dir * 9.0 - side * 9.0]), PackedColorArray([Color(1.0, 0.68, 0.26)]))
	var hp_pct: float = clamp(state.player_hp / max(1.0, state.max_hp), 0.0, 1.0)
	node.draw_arc(pos, 34.0, -PI * 0.5, -PI * 0.5 + TAU * hp_pct, 64, Color(0.80, 1.0, 0.62, 0.55), 3.0)

static func draw_hud(node: Node2D, state: RVGameState, textures: Dictionary) -> void:
	var font: Font = ThemeDB.fallback_font
	var screen_size: Vector2 = node.get_viewport_rect().size

	# Compact top strip. This replaces the previous unclear top banner.
	var top_left_rect: Rect2 = Rect2(Vector2(14.0, 12.0), Vector2(420.0, 28.0))
	node.draw_rect(top_left_rect, Color(0.018, 0.017, 0.020, 0.78), true)
	node.draw_rect(top_left_rect, Color(0.68, 0.52, 0.32, 0.22), false, 1.0)

	var mode_text: String = "FORGEHOLD" if state.mode == "hub" else "CONTRACT DEPTH " + str(state.run_depth)
	var top_text: String = mode_text + "  ·  Lv " + str(state.level)
	top_text += "  XP " + str(int(state.xp)) + "/" + str(int(state.xp_to_next()))
	top_text += "  MP " + str(state.mastery_points)
	node.draw_string(font, Vector2(26.0, 32.0), top_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.84, 0.74, 0.92))

	# Small material/status row on the top-right, not a giant banner.
	var right_text: String = "Gold " + str(state.gold)
	right_text += "   Embers " + str(state.materials.get("embers", 0))
	right_text += "   Shards " + str(state.materials.get("shards", 0))
	right_text += "   Runes " + str(state.materials.get("runes", 0))
	right_text += "   Echo " + str(state.materials.get("echo_glass", 0))
	var right_rect: Rect2 = Rect2(Vector2(screen_size.x - 650.0, 12.0), Vector2(636.0, 28.0))
	node.draw_rect(right_rect, Color(0.018, 0.017, 0.020, 0.68), true)
	node.draw_rect(right_rect, Color(0.68, 0.52, 0.32, 0.18), false, 1.0)
	node.draw_string(font, Vector2(right_rect.position.x + 14.0, 32.0), right_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.84, 0.74, 0.88))

	# Bottom-left HP/Mana: fill is drawn first, then frame is drawn on top.
	# Fill proportions are intentionally inset so they stay inside the 015A frame art.
	var bar_x: float = 16.0
	var hp_y: float = screen_size.y - 112.0
	var mana_y: float = screen_size.y - 76.0
	var bar_size: Vector2 = Vector2(300.0, 75.0)
	var fill_margin_x: float = bar_size.x * 0.165
	var fill_margin_y: float = bar_size.y * 0.415
	var fill_width: float = bar_size.x * 0.665
	var fill_height: float = bar_size.y * 0.145

	var hp_pct: float = clamp(state.player_hp / max(1.0, state.max_hp), 0.0, 1.0)
	var mana_pct: float = clamp(state.player_mana / max(1.0, state.max_mana), 0.0, 1.0)

	var hp_frame_rect: Rect2 = Rect2(Vector2(bar_x, hp_y), bar_size)
	var mana_frame_rect: Rect2 = Rect2(Vector2(bar_x, mana_y), bar_size)
	var hp_fill_bg: Rect2 = Rect2(hp_frame_rect.position + Vector2(fill_margin_x, fill_margin_y), Vector2(fill_width, fill_height))
	var mana_fill_bg: Rect2 = Rect2(mana_frame_rect.position + Vector2(fill_margin_x, fill_margin_y), Vector2(fill_width, fill_height))

	node.draw_rect(hp_fill_bg, Color(0.08, 0.025, 0.020, 0.90), true)
	node.draw_rect(Rect2(hp_fill_bg.position, Vector2(hp_fill_bg.size.x * hp_pct, hp_fill_bg.size.y)), Color(0.88, 0.15, 0.10, 0.92), true)

	node.draw_rect(mana_fill_bg, Color(0.020, 0.035, 0.07, 0.90), true)
	node.draw_rect(Rect2(mana_fill_bg.position, Vector2(mana_fill_bg.size.x * mana_pct, mana_fill_bg.size.y)), Color(0.22, 0.62, 1.0, 0.92), true)

	if textures.has("ui_health_bar_frame"):
		node.draw_texture_rect(textures["ui_health_bar_frame"], hp_frame_rect, false, Color(1.0, 1.0, 1.0, 0.96))
	else:
		node.draw_rect(hp_fill_bg, Color(0.90, 0.18, 0.12, 0.82), false, 2.0)

	if textures.has("ui_mana_bar_frame"):
		node.draw_texture_rect(textures["ui_mana_bar_frame"], mana_frame_rect, false, Color(1.0, 1.0, 1.0, 0.96))
	else:
		node.draw_rect(mana_fill_bg, Color(0.25, 0.68, 1.0, 0.82), false, 2.0)

	node.draw_string(font, hp_frame_rect.position + Vector2(67.0, 48.0), "HP " + str(int(state.player_hp)) + "/" + str(int(state.max_hp)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.92, 0.84, 0.74, 0.86))
	node.draw_string(font, mana_frame_rect.position + Vector2(67.0, 48.0), "MP " + str(int(state.player_mana)) + "/" + str(int(state.max_mana)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.72, 0.86, 1.0, 0.86))

	# Skill bar. In hub, 1-6 toggles from the full skill list. In combat, 1-6 selects active slots and Q/E cycles.
	var slot_size: Vector2 = Vector2(58.0, 58.0)
	var slot_gap: float = 10.0
	var total_width: float = 6.0 * slot_size.x + 5.0 * slot_gap
	var start_x: float = screen_size.x * 0.5 - total_width * 0.5
	var slot_y: float = screen_size.y - 78.0
	var all_skills: Array = ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"]

	for i in range(6):
		var pos: Vector2 = Vector2(start_x + float(i) * (slot_size.x + slot_gap), slot_y)
		var skill_name: String = ""
		var slot_active: bool = false
		var selected: bool = false

		if state.mode == "hub":
			skill_name = str(all_skills[i])
			slot_active = state.active_skills.has(skill_name)
			selected = slot_active
		else:
			if i < state.active_skills.size():
				skill_name = str(state.active_skills[i])
				slot_active = true
			selected = i == state.selected_skill

		var tex_key: String = "ui_skill_slot_selected" if selected else "ui_skill_slot_empty"
		if textures.has(tex_key):
			node.draw_texture_rect(textures[tex_key], Rect2(pos, slot_size), false, Color(1.0, 1.0, 1.0, 0.96 if slot_active else 0.42))
		else:
			var frame_color: Color = Color(1.0, 0.76, 0.35) if selected else Color(0.35, 0.32, 0.28)
			node.draw_rect(Rect2(pos, slot_size), Color(0.030, 0.030, 0.036), true)
			node.draw_rect(Rect2(pos, slot_size), frame_color, false, 2.0)

		if skill_name != "":
			var col: Color = RVSkillDB.color(skill_name)
			var alpha: float = 0.88 if slot_active else 0.26
			node.draw_circle(pos + slot_size * 0.5, 14.0, Color(col.r, col.g, col.b, alpha))
			node.draw_string(font, pos + Vector2(5.0, 51.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.94, 0.86, 0.68, 0.90))

	var controls: String = "Hub: 1-6 toggle skills · E interact · X secondary · F5 save" if state.mode == "hub" else "Combat: 1-6 select · Q/E cycle · LMB/Space cast · Esc hub"
	node.draw_string(font, Vector2(start_x, slot_y - 8.0), controls, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.76, 0.72, 0.64, 0.72))

	if state.prompt != "":
		var prompt_rect: Rect2 = Rect2(Vector2(screen_size.x * 0.5 - 300.0, screen_size.y - 34.0), Vector2(600.0, 28.0))
		node.draw_rect(prompt_rect, Color(0.018, 0.017, 0.020, 0.74), true)
		node.draw_rect(prompt_rect, Color(0.68, 0.52, 0.32, 0.20), false, 1.0)
		node.draw_string(font, prompt_rect.position + Vector2(16.0, 20.0), state.prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.96, 0.88, 0.68, 0.92))

	# Temporary notice. Smaller than before so it does not feel like a permanent top banner.
	if state.notice_time > 0.0:
		var notice_rect: Rect2 = Rect2(Vector2(screen_size.x * 0.5 - 220.0, 46.0), Vector2(440.0, 54.0))
		if textures.has("ui_notice_banner"):
			node.draw_texture_rect(textures["ui_notice_banner"], notice_rect, false, Color(1.0, 1.0, 1.0, 0.88))
		else:
			node.draw_rect(notice_rect, Color(0.018, 0.017, 0.020, 0.84), true)
		node.draw_string(font, notice_rect.position + Vector2(42.0, 33.0), state.notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.82, 0.44, 0.96))

static func draw_label(node: Node2D, pos: Vector2, text: String, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font; var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	node.draw_string(font, pos - Vector2(size.x * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)


static func draw_hex(node: Node2D, pos: Vector2, radius: float, fill: Color, outline: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var a: float = PI / 6.0 + float(i) * TAU / 6.0; pts.append(pos + Vector2(cos(a), sin(a)) * radius)
	node.draw_polygon(pts, PackedColorArray([fill])); var closed: PackedVector2Array = PackedVector2Array(pts); closed.append(pts[0]); node.draw_polyline(closed, outline, 2.0)


static func draw_diamond(node: Node2D, pos: Vector2, radius: float, fill: Color, outline: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([pos + Vector2(0.0, -radius), pos + Vector2(radius, 0.0), pos + Vector2(0.0, radius), pos + Vector2(-radius, 0.0)])
	node.draw_polygon(pts, PackedColorArray([fill])); node.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), outline, 2.0)


static func color_for_tags(tags: Array) -> Color:
	if tags.has("Fire"): return Color(1.0, 0.34, 0.10)
	if tags.has("Cold"): return Color(0.42, 0.82, 1.0)
	if tags.has("Lightning"): return Color(0.72, 0.92, 1.0)
	if tags.has("Void"): return Color(0.70, 0.36, 1.0)
	if tags.has("Trap"): return Color(0.95, 0.72, 0.28)
	if tags.has("Physical"): return Color(1.0, 0.80, 0.48)
	return Color(0.90, 0.84, 0.70)
