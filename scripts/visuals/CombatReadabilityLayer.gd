extends Control

# RELIC FORGE: VAULTBOUND
# Patch 005 — Combat Readability + Skill Feel
#
# This is not final art. It is a strong readability layer:
# - enemy roles have distinct silhouettes
# - skills get trails/rings/pulses
# - loot and interactables become visible
# - combat danger is easier to parse
# - the center remains playable

var visual_data = {}
var t = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 500
	size = get_viewport_rect().size


func _process(delta: float) -> void:
	t += delta
	size = get_viewport_rect().size
	queue_redraw()


func set_visual_data(data: Dictionary) -> void:
	visual_data = data
	queue_redraw()


func _draw() -> void:
	if visual_data.is_empty():
		return

	var shake = float(visual_data.get("shake", 0.0))
	var shake_offset = Vector2.ZERO
	if shake > 0.01:
		shake_offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))

	draw_set_transform(shake_offset, 0.0, Vector2.ONE)

	_draw_arena()
	_draw_soft_grid()
	_draw_room_mods()
	_draw_loot()
	_draw_chests()
	_draw_traps()
	_draw_zones()
	_draw_projectiles()
	_draw_enemy_projectiles()
	_draw_enemies()
	_draw_player()
	_draw_effects()
	_draw_skill_aim_preview()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_arena() -> void:
	var arena = visual_data.get("arena", Rect2(60, 84, 1160, 566))
	draw_rect(arena, Color(0.015, 0.014, 0.016, 0.18), true)
	draw_rect(arena, Color(0.75, 0.62, 0.42, 0.18), false, 2.0)


func _draw_soft_grid() -> void:
	var arena = visual_data.get("arena", Rect2(60, 84, 1160, 566))
	var step = 80.0
	var col = Color(0.70, 0.62, 0.48, 0.045)

	var x = arena.position.x
	while x <= arena.end.x:
		draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), col, 1.0)
		x += step

	var y = arena.position.y
	while y <= arena.end.y:
		draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), col, 1.0)
		y += step


func _draw_room_mods() -> void:
	var room = visual_data.get("current_room", {})
	if typeof(room) != TYPE_DICTIONARY:
		return

	var mods = room.get("mods", [])
	if mods.size() <= 0:
		return

	var arena = visual_data.get("arena", Rect2(60, 84, 1160, 566))
	var pulse = 0.05 + 0.03 * sin(t * 2.0)
	var mod_col = Color(0.90, 0.42, 0.22, pulse)
	draw_rect(arena.grow(-8.0), mod_col, false, 3.0)


func _draw_player() -> void:
	var pos = _v2(visual_data.get("player_pos", Vector2.ZERO))
	var aim = _v2(visual_data.get("aim_pos", pos + Vector2.RIGHT))
	var hp = float(visual_data.get("hp", 100.0))
	var hp_max = max(1.0, float(visual_data.get("hp_max", 100.0)))
	var low_hp = hp / hp_max < 0.33

	var dir = (aim - pos).normalized()
	if dir.length() < 0.1:
		dir = Vector2.RIGHT

	var side = Vector2(-dir.y, dir.x)

	var body_col = Color(0.92, 0.86, 0.72, 0.96)
	var accent_col = Color(1.0, 0.62, 0.25, 0.95)
	if low_hp:
		body_col = Color(1.0, 0.48, 0.38, 0.96)
		accent_col = Color(1.0, 0.18, 0.10, 0.95)

	draw_circle(pos + Vector2(4, 8), 18.0, Color(0, 0, 0, 0.30))
	draw_circle(pos, 16.0, Color(0.02, 0.02, 0.025, 0.95))
	draw_circle(pos, 12.0, body_col)

	var nose = pos + dir * 19.0
	var left = pos - dir * 8.0 + side * 8.0
	var right = pos - dir * 8.0 - side * 8.0
	draw_polygon(PackedVector2Array([nose, left, right]), PackedColorArray([accent_col]))

	draw_arc(pos, 23.0, -PI, PI, 48, Color(0.95, 0.80, 0.52, 0.30), 1.5)

	var dash_cd = float(visual_data.get("dash_cooldown", 0.0))
	if dash_cd <= 0.05:
		draw_arc(pos, 28.0, -PI, PI, 48, Color(0.55, 0.82, 1.0, 0.26), 2.0)


func _draw_skill_aim_preview() -> void:
	var pos = _v2(visual_data.get("player_pos", Vector2.ZERO))
	var aim = _v2(visual_data.get("aim_pos", pos + Vector2.RIGHT))
	var skill = str(visual_data.get("selected_skill_name", ""))
	var active = bool(visual_data.get("combat_active", true))

	if not active or skill == "":
		return

	var dir = (aim - pos).normalized()
	if dir.length() < 0.1:
		dir = Vector2.RIGHT

	var col = _skill_color(skill)
	if skill == "Cleave":
		draw_arc(pos, 88.0, dir.angle() - 0.82, dir.angle() + 0.82, 32, Color(col.r, col.g, col.b, 0.18), 4.0)
	elif skill == "Frost Nova":
		draw_arc(pos, 150.0, -PI, PI, 72, Color(col.r, col.g, col.b, 0.16), 3.0)
	elif skill == "Void Rift":
		draw_arc(aim, 58.0 + 8.0 * sin(t * 4.0), -PI, PI, 48, Color(col.r, col.g, col.b, 0.18), 3.0)
	elif skill == "Blade Trap":
		_draw_diamond(aim, 26.0, Color(col.r, col.g, col.b, 0.22), Color(col.r, col.g, col.b, 0.62))
	else:
		draw_line(pos + dir * 18.0, pos + dir * 180.0, Color(col.r, col.g, col.b, 0.22), 3.0)


func _draw_enemies() -> void:
	var enemies = visual_data.get("enemies", [])
	for e in enemies:
		if typeof(e) == TYPE_DICTIONARY:
			_draw_enemy(e)


func _draw_enemy(e: Dictionary) -> void:
	var pos = _v2(e.get("pos", Vector2.ZERO))
	var radius = float(e.get("radius", 16.0))
	var kind = str(e.get("type", e.get("name", "Enemy")))
	var role = str(e.get("role", _role_from_kind(kind)))
	var col = _enemy_color(kind, role)
	var threat = float(e.get("threat_flash", 0.0))

	draw_circle(pos + Vector2(5, 9), radius * 1.08, Color(0, 0, 0, 0.34))

	if role == "brute":
		_draw_hex(pos, radius * 1.18, Color(0.04, 0.045, 0.052, 0.96), col)
		draw_arc(pos, radius * 1.65, -PI, PI, 48, Color(col.r, col.g, col.b, 0.20), 2.0)
	elif role == "shooter" or role == "spitter" or role == "acolyte":
		_draw_diamond(pos, radius * 1.24, Color(0.035, 0.035, 0.042, 0.96), col)
		var aim_dir = (_v2(visual_data.get("player_pos", pos)) - pos).normalized()
		draw_line(pos, pos + aim_dir * (radius * 2.3), Color(col.r, col.g, col.b, 0.55), 2.0)
	elif role == "hound":
		var player = _v2(visual_data.get("player_pos", pos))
		var dir = (player - pos).normalized()
		if dir.length() < 0.1:
			dir = Vector2.RIGHT
		_draw_wedge(pos, dir, radius * 1.25, Color(0.03, 0.04, 0.03, 0.96), col)
	else:
		draw_circle(pos, radius * 1.18, Color(0.035, 0.035, 0.040, 0.96))
		draw_circle(pos, radius * 0.82, col)

	if kind.find("Vault Warden") != -1 or role == "boss":
		draw_arc(pos, radius * 1.9 + sin(t * 3.0) * 5.0, -PI, PI, 72, Color(0.92, 0.36, 1.0, 0.36), 4.0)
		_draw_nameplate(pos + Vector2(0, -radius - 30), "VAULT WARDEN", Color(0.95, 0.70, 1.0, 0.95))
	else:
		_draw_nameplate(pos + Vector2(0, -radius - 18), _short_enemy_name(kind), Color(0.86, 0.80, 0.68, 0.72))

	if threat > 0.0:
		draw_arc(pos, radius * (1.6 + threat), -PI, PI, 48, Color(1.0, 0.22, 0.10, 0.34), 4.0)


func _draw_projectiles() -> void:
	var arr = visual_data.get("projectiles", [])
	for p in arr:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pos = _v2(p.get("pos", Vector2.ZERO))
		var vel = _v2(p.get("vel", Vector2.ZERO))
		var radius = float(p.get("radius", 7.0))
		var tags = p.get("tags", [])
		var col = _tag_color(tags)

		var dir = vel.normalized()
		if dir.length() < 0.1:
			dir = Vector2.RIGHT

		draw_line(pos - dir * 38.0, pos - dir * 8.0, Color(col.r, col.g, col.b, 0.24), radius * 1.4)
		draw_circle(pos, radius * 1.7, Color(col.r, col.g, col.b, 0.22))
		draw_circle(pos, radius, Color(col.r, col.g, col.b, 0.96))
		draw_circle(pos - dir * radius * 0.5, radius * 0.45, Color(1.0, 1.0, 1.0, 0.55))


func _draw_enemy_projectiles() -> void:
	var arr = visual_data.get("enemy_projectiles", [])
	for p in arr:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pos = _v2(p.get("pos", Vector2.ZERO))
		var vel = _v2(p.get("vel", Vector2.ZERO))
		var radius = float(p.get("radius", 6.0))
		var dir = vel.normalized()
		if dir.length() < 0.1:
			dir = Vector2.RIGHT

		draw_line(pos - dir * 30.0, pos, Color(1.0, 0.25, 0.14, 0.30), radius * 1.5)
		draw_circle(pos, radius * 1.7, Color(1.0, 0.18, 0.10, 0.25))
		draw_circle(pos, radius, Color(1.0, 0.38, 0.24, 0.96))


func _draw_zones() -> void:
	var arr = visual_data.get("zones", [])
	for z in arr:
		if typeof(z) != TYPE_DICTIONARY:
			continue
		var pos = _v2(z.get("pos", Vector2.ZERO))
		var radius = float(z.get("radius", 60.0))
		var visual = str(z.get("visual", "Zone"))
		var tags = z.get("tags", [])
		var col = _skill_color(visual)
		if tags.size() > 0:
			col = _tag_color(tags)

		var pulse = 0.08 + 0.04 * sin(t * 5.0)
		draw_circle(pos, radius, Color(col.r, col.g, col.b, pulse))
		draw_arc(pos, radius, -PI, PI, 72, Color(col.r, col.g, col.b, 0.44), 3.0)
		draw_arc(pos, radius * 0.68, -PI, PI, 48, Color(col.r, col.g, col.b, 0.18), 2.0)

		if visual.find("Void") != -1:
			for i in range(6):
				var a = t * 1.7 + float(i) * TAU / 6.0
				draw_line(pos + Vector2(cos(a), sin(a)) * radius, pos + Vector2(cos(a + 0.6), sin(a + 0.6)) * radius * 0.42, Color(col.r, col.g, col.b, 0.22), 2.0)


func _draw_traps() -> void:
	var arr = visual_data.get("traps", [])
	for tr in arr:
		if typeof(tr) != TYPE_DICTIONARY:
			continue
		var pos = _v2(tr.get("pos", Vector2.ZERO))
		var radius = float(tr.get("radius", 42.0))
		var armed = bool(tr.get("armed", true))
		var col = Color(0.95, 0.78, 0.46, 0.76) if armed else Color(0.58, 0.54, 0.48, 0.45)
		_draw_diamond(pos, 18.0, Color(0.05, 0.045, 0.038, 0.88), col)
		draw_arc(pos, radius, -PI, PI, 48, Color(col.r, col.g, col.b, 0.28), 2.0)
		draw_line(pos + Vector2(-14, 0), pos + Vector2(14, 0), Color(col.r, col.g, col.b, 0.55), 2.0)
		draw_line(pos + Vector2(0, -14), pos + Vector2(0, 14), Color(col.r, col.g, col.b, 0.55), 2.0)


func _draw_loot() -> void:
	var arr = visual_data.get("loot", [])
	for l in arr:
		if typeof(l) != TYPE_DICTIONARY:
			continue
		var pos = _v2(l.get("pos", Vector2.ZERO))
		var item = l.get("item", {})
		var rarity = "Common"
		var name = "Loot"
		if typeof(item) == TYPE_DICTIONARY:
			rarity = str(item.get("rarity", "Common"))
			name = str(item.get("name", "Loot"))

		var col = _rarity_color(rarity)
		var beam_h = 34.0 + sin(t * 4.0 + pos.x * 0.02) * 4.0
		draw_line(pos + Vector2(0, -beam_h), pos + Vector2(0, 4), Color(col.r, col.g, col.b, 0.42), 4.0)
		draw_circle(pos, 11.0, Color(col.r, col.g, col.b, 0.22))
		_draw_diamond(pos, 8.0, Color(0.03, 0.03, 0.035, 0.95), col)
		_draw_nameplate(pos + Vector2(0, -beam_h - 12), name, Color(col.r, col.g, col.b, 0.86))


func _draw_chests() -> void:
	var arr = visual_data.get("chests", [])
	for c in arr:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var pos = _v2(c.get("pos", Vector2.ZERO))
		var opened = bool(c.get("opened", false))
		var col = Color(0.95, 0.70, 0.32, 0.85) if not opened else Color(0.38, 0.34, 0.28, 0.55)
		draw_rect(Rect2(pos - Vector2(15, 10), Vector2(30, 20)), Color(0.04, 0.035, 0.03, 0.94), true)
		draw_rect(Rect2(pos - Vector2(15, 10), Vector2(30, 20)), col, false, 2.0)
		draw_line(pos + Vector2(-12, 0), pos + Vector2(12, 0), Color(col.r, col.g, col.b, 0.66), 2.0)


func _draw_effects() -> void:
	var fx = visual_data.get("fx", [])
	for f in fx:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		var pos = _v2(f.get("pos", Vector2.ZERO))
		var life = float(f.get("life", 0.0))
		var max_life = max(0.01, float(f.get("max_life", 0.5)))
		var kind = str(f.get("kind", "pulse"))
		var color = f.get("color", Color(1, 1, 1, 1))
		var k = clamp(life / max_life, 0.0, 1.0)
		var inv = 1.0 - k
		var radius = float(f.get("radius", 40.0)) * (0.45 + inv * 0.85)

		if kind == "slash":
			draw_arc(pos, radius, float(f.get("angle", 0.0)) - 0.9, float(f.get("angle", 0.0)) + 0.9, 32, Color(color.r, color.g, color.b, 0.65 * k), 6.0)
		elif kind == "burst":
			draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.16 * k))
			draw_arc(pos, radius, -PI, PI, 48, Color(color.r, color.g, color.b, 0.70 * k), 3.0)
		elif kind == "line":
			var dir = _v2(f.get("dir", Vector2.RIGHT)).normalized()
			draw_line(pos - dir * radius, pos + dir * radius, Color(color.r, color.g, color.b, 0.60 * k), 5.0)
		else:
			draw_arc(pos, radius, -PI, PI, 48, Color(color.r, color.g, color.b, 0.62 * k), 3.0)


func _draw_nameplate(pos: Vector2, text_value: String, col: Color) -> void:
	if text_value == "":
		return
	var font = ThemeDB.fallback_font
	var font_size = 10
	var size_text = font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var rect = Rect2(pos - Vector2(size_text.x * 0.5 + 5, 8), Vector2(size_text.x + 10, 16))
	draw_rect(rect, Color(0.02, 0.02, 0.024, 0.52), true)
	draw_string(font, pos + Vector2(-size_text.x * 0.5, 4), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


func _draw_diamond(pos: Vector2, r: float, fill: Color, outline: Color) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(0, -r),
		pos + Vector2(r, 0),
		pos + Vector2(0, r),
		pos + Vector2(-r, 0)
	])
	draw_polygon(pts, PackedColorArray([fill]))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), outline, 2.0)


func _draw_hex(pos: Vector2, r: float, fill: Color, outline: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(6):
		var a = PI / 6.0 + float(i) * TAU / 6.0
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
	draw_polygon(pts, PackedColorArray([fill]))
	var loop = PackedVector2Array(pts)
	loop.append(pts[0])
	draw_polyline(loop, outline, 2.0)


func _draw_wedge(pos: Vector2, dir: Vector2, r: float, fill: Color, outline: Color) -> void:
	var side = Vector2(-dir.y, dir.x)
	var pts = PackedVector2Array([
		pos + dir * r * 1.35,
		pos - dir * r * 0.75 + side * r * 0.75,
		pos - dir * r * 0.35,
		pos - dir * r * 0.75 - side * r * 0.75
	])
	draw_polygon(pts, PackedColorArray([fill]))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), outline, 2.0)


func _role_from_kind(kind: String) -> String:
	var k = kind.to_lower()
	if k.find("brute") != -1 or k.find("knight") != -1:
		return "brute"
	if k.find("archer") != -1:
		return "shooter"
	if k.find("spitter") != -1:
		return "spitter"
	if k.find("hound") != -1:
		return "hound"
	if k.find("acolyte") != -1:
		return "acolyte"
	if k.find("warden") != -1:
		return "boss"
	return "chaser"


func _enemy_color(kind: String, role: String) -> Color:
	var k = kind.to_lower()
	if k.find("ash") != -1:
		return Color(0.92, 0.28, 0.16, 0.96)
	if k.find("bone") != -1:
		return Color(0.92, 0.84, 0.62, 0.96)
	if k.find("iron") != -1 or k.find("knight") != -1:
		return Color(0.60, 0.65, 0.70, 0.96)
	if k.find("cinder") != -1:
		return Color(1.0, 0.52, 0.16, 0.96)
	if k.find("rot") != -1:
		return Color(0.38, 0.95, 0.32, 0.96)
	if k.find("mirror") != -1 or k.find("void") != -1 or k.find("warden") != -1:
		return Color(0.74, 0.40, 1.0, 0.96)
	if role == "shooter":
		return Color(0.92, 0.80, 0.48, 0.96)
	if role == "brute":
		return Color(0.68, 0.68, 0.74, 0.96)
	return Color(0.85, 0.34, 0.24, 0.96)


func _tag_color(tags: Array) -> Color:
	for tag in tags:
		var s = str(tag)
		if s == "Fire" or s == "Burn":
			return Color(1.0, 0.36, 0.12, 0.96)
		if s == "Cold" or s == "Freeze":
			return Color(0.42, 0.82, 1.0, 0.96)
		if s == "Lightning" or s == "Chain":
			return Color(0.78, 0.90, 1.0, 0.96)
		if s == "Void" or s == "Curse":
			return Color(0.72, 0.36, 1.0, 0.96)
		if s == "Trap":
			return Color(0.95, 0.72, 0.32, 0.96)
		if s == "Slash" or s == "Physical" or s == "Melee":
			return Color(1.0, 0.82, 0.52, 0.96)
	return Color(0.90, 0.86, 0.76, 0.96)


func _skill_color(skill: String) -> Color:
	if skill.find("Fire") != -1 or skill.find("Ember") != -1:
		return Color(1.0, 0.34, 0.12, 0.96)
	if skill.find("Frost") != -1 or skill.find("Nova") != -1 or skill.find("Cold") != -1:
		return Color(0.42, 0.82, 1.0, 0.96)
	if skill.find("Storm") != -1 or skill.find("Lance") != -1:
		return Color(0.75, 0.90, 1.0, 0.96)
	if skill.find("Void") != -1 or skill.find("Rift") != -1:
		return Color(0.70, 0.34, 1.0, 0.96)
	if skill.find("Trap") != -1:
		return Color(0.95, 0.72, 0.32, 0.96)
	if skill.find("Cleave") != -1:
		return Color(1.0, 0.82, 0.50, 0.96)
	return Color(0.90, 0.86, 0.76, 0.96)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Magic":
			return Color(0.42, 0.72, 1.0, 0.96)
		"Rare":
			return Color(1.0, 0.82, 0.32, 0.96)
		"Legendary":
			return Color(1.0, 0.44, 0.14, 0.96)
		"Mythic":
			return Color(0.90, 0.36, 1.0, 0.96)
		_:
			return Color(0.84, 0.82, 0.74, 0.96)


func _short_enemy_name(kind: String) -> String:
	if kind.find("Ash") != -1:
		return "GRUNT"
	if kind.find("Bone") != -1:
		return "ARCHER"
	if kind.find("Iron") != -1:
		return "BRUTE"
	if kind.find("Cinder") != -1:
		return "SPITTER"
	if kind.find("Rot") != -1:
		return "HOUND"
	if kind.find("Knight") != -1:
		return "KNIGHT"
	if kind.find("Mirror") != -1:
		return "ACOLYTE"
	return ""


func _v2(value) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return value
	return Vector2.ZERO
