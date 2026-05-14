extends Node2D

# RELIC FORGE: VAULTBOUND
# Patch 011 — Art + Skill FX Rework
#
# This is a presentation layer, not final sprite art.
# Goal:
# - kill the "debug dots" feeling
# - give each skill a distinct visual identity
# - make enemy roles readable
# - make the hub and dungeon feel physical
# - improve hit/loot/zone readability
#
# This intentionally draws over the primitive game state while we continue
# building toward real sprite packs.

var game = null

var t = 0.0
var fx = []
var projectile_trails = []
var last_projectile_count = 0
var last_enemy_projectile_count = 0
var last_zone_count = 0
var last_trap_count = 0
var last_loot_count = 0
var last_enemy_count = 0
var last_hp = 120.0
var shake = 0.0
var pulse = 0.0

func _ready() -> void:
	game = get_parent()
	z_index = 650

	# Patch 011 replaces the older combat readability overlay.
	var old = get_parent().get_node_or_null("Patch005CombatReadabilityLayer")
	if old != null:
		old.queue_free()

	set_process(true)


func _process(delta: float) -> void:
	t += delta

	if game == null:
		return

	_detect_events(delta)
	_update_fx(delta)
	_update_trails(delta)

	shake = max(0.0, shake - delta * 24.0)
	pulse = max(0.0, pulse - delta * 3.5)

	queue_redraw()


func _draw() -> void:
	if game == null:
		return

	var run_state = str(game.get("run_state"))

	if run_state == "hub":
		_draw_hub_art()
	else:
		_draw_dungeon_art()

	_draw_loot_art()
	_draw_trap_art()
	_draw_zone_art()
	_draw_projectile_art()
	_draw_enemy_projectile_art()
	_draw_enemy_art()
	_draw_player_art()
	_draw_fx()
	_draw_skill_preview()
	_draw_world_vignette()


func _detect_events(delta: float) -> void:
	var hp = float(game.get("player_hp"))
	if hp < last_hp:
		shake = max(shake, 7.0)
		pulse = 1.0
		_add_fx(_player_pos(), 78.0, Color(1.0, 0.16, 0.08, 0.85), "hurt")
	last_hp = hp

	var projectiles = _arr("projectiles")
	if projectiles.size() > last_projectile_count:
		var i = last_projectile_count
		while i < projectiles.size():
			var p = projectiles[i]
			if typeof(p) == TYPE_DICTIONARY:
				_add_cast_fx(p)
			i += 1
	last_projectile_count = projectiles.size()

	var enemy_projectiles = _arr("enemy_projectiles")
	if enemy_projectiles.size() > last_enemy_projectile_count:
		var j = last_enemy_projectile_count
		while j < enemy_projectiles.size():
			var ep = enemy_projectiles[j]
			if typeof(ep) == TYPE_DICTIONARY:
				_add_fx(_v2(ep.get("pos", _player_pos())), 28.0, Color(1.0, 0.22, 0.12, 0.78), "danger")
			j += 1
	last_enemy_projectile_count = enemy_projectiles.size()

	var zones = _arr("zones")
	if zones.size() > last_zone_count:
		var zidx = last_zone_count
		while zidx < zones.size():
			var z = zones[zidx]
			if typeof(z) == TYPE_DICTIONARY:
				var col = _color_from_tags(z.get("tags", []))
				_add_fx(_v2(z.get("pos", _player_pos())), float(z.get("radius", 80.0)), col, "zone_spawn")
			zidx += 1
	last_zone_count = zones.size()

	var traps = _arr("traps")
	if traps.size() > last_trap_count:
		var tidx = last_trap_count
		while tidx < traps.size():
			var tr = traps[tidx]
			if typeof(tr) == TYPE_DICTIONARY:
				_add_fx(_v2(tr.get("pos", _player_pos())), 56.0, Color(1.0, 0.74, 0.25, 0.82), "trap_set")
			tidx += 1
	last_trap_count = traps.size()

	var loot = _arr("loot")
	if loot.size() > last_loot_count:
		var lidx = last_loot_count
		while lidx < loot.size():
			var l = loot[lidx]
			if typeof(l) == TYPE_DICTIONARY:
				var item = l.get("item", {})
				var rarity = "Magic"
				if typeof(item) == TYPE_DICTIONARY:
					rarity = str(item.get("rarity", "Magic"))
				_add_fx(_v2(l.get("pos", _player_pos())), 58.0, _rarity_color(rarity), "loot")
			lidx += 1
	last_loot_count = loot.size()

	var enemies = _arr("enemies")
	if enemies.size() < last_enemy_count:
		shake = max(shake, 3.0)
		_add_fx(_player_pos() + Vector2(randf_range(-90, 90), randf_range(-70, 70)), 64.0, Color(1.0, 0.68, 0.28, 0.75), "kill")
	last_enemy_count = enemies.size()


func _add_cast_fx(p: Dictionary) -> void:
	var pos = _v2(p.get("pos", _player_pos()))
	var tags = p.get("tags", [])
	var col = _color_from_tags(tags)
	var kind = "cast"

	for tag in tags:
		var s = str(tag)
		if s == "Fire" or s == "Burn":
			kind = "fire_cast"
		elif s == "Lightning" or s == "Chain":
			kind = "lightning_cast"
		elif s == "Cold" or s == "Freeze":
			kind = "frost_cast"
		elif s == "Void" or s == "Curse":
			kind = "void_cast"
		elif s == "Slash" or s == "Melee":
			kind = "slash_cast"
		elif s == "Trap":
			kind = "trap_set"

	_add_fx(pos, 46.0, col, kind)


func _update_fx(delta: float) -> void:
	var kept = []
	for f in fx:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		f["life"] = float(f.get("life", 0.0)) - delta
		if float(f.get("life", 0.0)) > 0.0:
			kept.append(f)
	fx = kept


func _update_trails(delta: float) -> void:
	var projectiles = _arr("projectiles")
	for p in projectiles:
		if typeof(p) == TYPE_DICTIONARY:
			var tags = p.get("tags", [])
			projectile_trails.append({
				"pos": _v2(p.get("pos", Vector2.ZERO)),
				"color": _color_from_tags(tags),
				"life": 0.22,
				"max_life": 0.22,
				"radius": float(p.get("radius", 6.0))
			})

	var kept = []
	for tr in projectile_trails:
		if typeof(tr) != TYPE_DICTIONARY:
			continue
		tr["life"] = float(tr.get("life", 0.0)) - delta
		if float(tr.get("life", 0.0)) > 0.0:
			kept.append(tr)
	projectile_trails = kept


func _add_fx(pos: Vector2, radius: float, color: Color, kind: String) -> void:
	fx.append({
		"pos": pos,
		"radius": radius,
		"color": color,
		"kind": kind,
		"life": 0.55,
		"max_life": 0.55
	})


func _draw_hub_art() -> void:
	var arena = _arena()
	var offset = _shake_offset()

	draw_set_transform(offset, 0.0, Vector2.ONE)

	# Ground
	draw_rect(arena, Color(0.012, 0.011, 0.014, 0.98), true)
	draw_rect(arena, Color(0.72, 0.54, 0.30, 0.22), false, 2.0)

	# Warm forge floor rings
	var c = Vector2(640, 370)
	draw_circle(c, 285.0, Color(0.12, 0.075, 0.035, 0.08))
	draw_circle(c, 175.0, Color(0.18, 0.10, 0.045, 0.08))
	draw_arc(c, 286.0, -PI, PI, 128, Color(0.94, 0.62, 0.26, 0.12), 2.0)
	draw_arc(c, 176.0, -PI, PI, 128, Color(0.94, 0.62, 0.26, 0.16), 2.0)
	draw_arc(c, 86.0, -PI, PI, 128, Color(0.94, 0.62, 0.26, 0.10), 2.0)

	# District tinting
	_draw_district(Vector2(640, 150), "CONTRACT GATES", Color(0.78, 0.32, 1.0, 0.18))
	_draw_district(Vector2(995, 325), "FORGE ANVILS", Color(1.0, 0.35, 0.10, 0.16))
	_draw_district(Vector2(330, 365), "MASTERY SHRINES", Color(0.55, 0.42, 1.0, 0.14))
	_draw_district(Vector2(650, 565), "SKILL ALTARS", Color(0.35, 1.0, 0.60, 0.12))
	_draw_district(Vector2(705, 410), "STASH / ARMORY", Color(1.0, 0.78, 0.26, 0.12))

	# PhysicalHubDirector draws many objects already. Patch 011 adds atmosphere behind/around them.
	_draw_forge_embers()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_dungeon_art() -> void:
	var arena = _arena()
	var offset = _shake_offset()

	draw_set_transform(offset, 0.0, Vector2.ONE)

	var room = game.get("current_room")
	var biome = "Ash Crypt"
	var threat = 1.0
	if typeof(room) == TYPE_DICTIONARY:
		biome = str(room.get("biome", "Ash Crypt"))
		threat = float(room.get("threat", 1.0))

	var base = _biome_base_color(biome)
	draw_rect(arena, Color(base.r * 0.22, base.g * 0.22, base.b * 0.22, 0.96), true)
	draw_rect(arena, Color(base.r, base.g, base.b, 0.22), false, 2.0)

	# Floor material
	var step = 72.0
	var x = arena.position.x
	while x <= arena.end.x:
		draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), Color(base.r, base.g, base.b, 0.055), 1.0)
		x += step

	var y = arena.position.y
	while y <= arena.end.y:
		draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), Color(base.r, base.g, base.b, 0.045), 1.0)
		y += step

	# Biome decorative scars
	var i = 0
	while i < 26:
		var px = arena.position.x + 45.0 + float((i * 173) % int(arena.size.x - 90.0))
		var py = arena.position.y + 40.0 + float((i * 97) % int(arena.size.y - 80.0))
		var a = float(i) * 0.7
		var p = Vector2(px, py)
		var len = 20.0 + float(i % 5) * 7.0
		draw_line(p, p + Vector2(cos(a), sin(a)) * len, Color(base.r, base.g, base.b, 0.09), 2.0)
		i += 1

	if threat > 1.2:
		draw_rect(arena.grow(-8), Color(1.0, 0.20, 0.08, min(0.16, (threat - 1.0) * 0.08)), false, 4.0)

	_draw_obstacle_art()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_district(pos: Vector2, label: String, col: Color) -> void:
	draw_circle(pos, 110.0, Color(col.r, col.g, col.b, col.a))
	draw_arc(pos, 112.0, -PI, PI, 80, Color(col.r, col.g, col.b, col.a * 1.8), 2.0)

	var font = ThemeDB.fallback_font
	var size_font = 12
	var ts = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font)
	draw_string(font, pos - Vector2(ts.x * 0.5, 72), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size_font, Color(col.r, col.g, col.b, 0.68))


func _draw_forge_embers() -> void:
	var i = 0
	while i < 36:
		var x = 900.0 + float((i * 71) % 190)
		var y = 210.0 + float((i * 47) % 310)
		var bob = sin(t * 2.0 + float(i)) * 4.0
		var a = 0.18 + 0.12 * sin(t * 3.0 + float(i) * 0.4)
		draw_circle(Vector2(x, y + bob), 2.0 + float(i % 3), Color(1.0, 0.42, 0.12, a))
		i += 1


func _draw_obstacle_art() -> void:
	var obstacles = _arr("obstacles")
	for o in obstacles:
		if typeof(o) != TYPE_DICTIONARY:
			continue
		var pos = _v2(o.get("pos", Vector2.ZERO))
		var r = float(o.get("radius", 24.0))
		draw_circle(pos + Vector2(6, 9), r * 1.05, Color(0.0, 0.0, 0.0, 0.34))
		_draw_rock(pos, r)


func _draw_rock(pos: Vector2, r: float) -> void:
	var pts = PackedVector2Array()
	var i = 0
	while i < 8:
		var a = float(i) * TAU / 8.0
		var rr = r * (0.78 + 0.22 * sin(float(i) * 2.3))
		pts.append(pos + Vector2(cos(a), sin(a)) * rr)
		i += 1
	draw_polygon(pts, PackedColorArray([Color(0.095, 0.086, 0.080, 0.98)]))
	var closed = PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, Color(0.44, 0.36, 0.27, 0.44), 2.0)


func _draw_player_art() -> void:
	var pos = _player_pos()
	var aim = _aim_pos()
	var dir = (aim - pos).normalized()
	if dir.length() < 0.1:
		dir = Vector2.RIGHT
	var side = Vector2(-dir.y, dir.x)

	var hp = float(game.get("player_hp"))
	var max_hp = _max_hp()
	var low = hp / max(1.0, max_hp) < 0.33

	var core = Color(0.92, 0.84, 0.66, 0.98)
	var accent = Color(1.0, 0.68, 0.26, 0.96)
	if low:
		core = Color(1.0, 0.48, 0.36, 0.98)
		accent = Color(1.0, 0.18, 0.10, 0.96)

	draw_circle(pos + Vector2(6, 10), 20.0, Color(0.0, 0.0, 0.0, 0.36))
	draw_circle(pos, 17.0, Color(0.020, 0.020, 0.024, 0.98))
	draw_circle(pos, 12.0, core)

	# Directional mantle / weapon point
	var nose = pos + dir * 24.0
	var left = pos - dir * 10.0 + side * 9.0
	var right = pos - dir * 10.0 - side * 9.0
	draw_polygon(PackedVector2Array([nose, left, right]), PackedColorArray([accent]))

	# Build aura based on selected skill
	var skill = _selected_skill()
	var scol = _skill_color(skill)
	draw_arc(pos, 28.0 + sin(t * 4.0) * 1.6, -PI, PI, 64, Color(scol.r, scol.g, scol.b, 0.28), 2.0)

	# HP ring
	var pct = clamp(hp / max(1.0, max_hp), 0.0, 1.0)
	draw_arc(pos, 34.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 64, Color(0.80, 1.0, 0.62, 0.50), 3.0)


func _draw_enemy_art() -> void:
	var enemies = _arr("enemies")
	for e in enemies:
		if typeof(e) == TYPE_DICTIONARY:
			_draw_enemy(e)


func _draw_enemy(e: Dictionary) -> void:
	var pos = _v2(e.get("pos", Vector2.ZERO))
	var name = str(e.get("type", e.get("name", "Enemy")))
	var role = str(e.get("role", _enemy_role(name)))
	var r = float(e.get("radius", 16.0))
	var hp = float(e.get("hp", 1.0))
	var max_hp = max(1.0, float(e.get("max_hp", hp)))
	var col = _enemy_color(name, role)

	draw_circle(pos + Vector2(6, 10), r * 1.2, Color(0.0, 0.0, 0.0, 0.36))

	if role == "brute":
		_draw_hex(pos, r * 1.15, Color(0.030, 0.032, 0.038, 0.98), col)
		draw_arc(pos, r * 1.55, -PI, PI, 64, Color(col.r, col.g, col.b, 0.20), 3.0)
	elif role == "shooter" or role == "spitter" or role == "acolyte":
		_draw_diamond(pos, r * 1.25, Color(0.030, 0.030, 0.037, 0.98), col)
		var aim_dir = (_player_pos() - pos).normalized()
		if aim_dir.length() < 0.1:
			aim_dir = Vector2.RIGHT
		draw_line(pos, pos + aim_dir * r * 2.5, Color(col.r, col.g, col.b, 0.45), 2.0)
	elif role == "hound":
		var d = (_player_pos() - pos).normalized()
		if d.length() < 0.1:
			d = Vector2.RIGHT
		_draw_wedge(pos, d, r * 1.25, Color(0.025, 0.033, 0.025, 0.98), col)
	else:
		draw_circle(pos, r * 1.10, Color(0.030, 0.030, 0.036, 0.98))
		draw_circle(pos, r * 0.78, col)

	# HP strip
	var pct = clamp(hp / max_hp, 0.0, 1.0)
	var w = r * 2.2
	var bar_pos = pos + Vector2(-w * 0.5, -r - 14.0)
	draw_rect(Rect2(bar_pos, Vector2(w, 4)), Color(0.04, 0.035, 0.035, 0.75), true)
	draw_rect(Rect2(bar_pos, Vector2(w * pct, 4)), Color(0.90, 0.22, 0.16, 0.82), true)

	if name.find("Vault") != -1 or role == "boss":
		draw_arc(pos, r * 2.0 + sin(t * 4.0) * 5.0, -PI, PI, 96, Color(0.90, 0.34, 1.0, 0.35), 4.0)
		_draw_label(pos + Vector2(0, -r - 30), "VAULT WARDEN", Color(0.96, 0.70, 1.0, 0.92))
	else:
		_draw_label(pos + Vector2(0, -r - 24), _enemy_short(name), Color(0.86, 0.80, 0.66, 0.70))


func _draw_projectile_art() -> void:
	for tr in projectile_trails:
		if typeof(tr) != TYPE_DICTIONARY:
			continue
		var life = float(tr.get("life", 0.0))
		var max_life = max(0.01, float(tr.get("max_life", 0.22)))
		var k = clamp(life / max_life, 0.0, 1.0)
		var col = tr.get("color", Color(1, 1, 1, 1))
		var pos = _v2(tr.get("pos", Vector2.ZERO))
		var r = float(tr.get("radius", 6.0))
		draw_circle(pos, r * (0.5 + k), Color(col.r, col.g, col.b, 0.16 * k))

	var projectiles = _arr("projectiles")
	for p in projectiles:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pos2 = _v2(p.get("pos", Vector2.ZERO))
		var vel = _v2(p.get("vel", Vector2.RIGHT))
		var r2 = float(p.get("radius", 7.0))
		var tags = p.get("tags", [])
		var col2 = _color_from_tags(tags)
		var dir = vel.normalized()
		if dir.length() < 0.1:
			dir = Vector2.RIGHT

		draw_line(pos2 - dir * 44.0, pos2 - dir * 10.0, Color(col2.r, col2.g, col2.b, 0.28), max(3.0, r2 * 1.3))
		draw_circle(pos2, r2 * 2.1, Color(col2.r, col2.g, col2.b, 0.18))
		draw_circle(pos2, r2, Color(col2.r, col2.g, col2.b, 0.96))
		draw_circle(pos2 - dir * r2 * 0.4, r2 * 0.35, Color(1.0, 1.0, 1.0, 0.58))


func _draw_enemy_projectile_art() -> void:
	var enemy_projectiles = _arr("enemy_projectiles")
	for ep in enemy_projectiles:
		if typeof(ep) != TYPE_DICTIONARY:
			continue
		var pos = _v2(ep.get("pos", Vector2.ZERO))
		var vel = _v2(ep.get("vel", Vector2.RIGHT))
		var r = float(ep.get("radius", 6.0))
		var dir = vel.normalized()
		if dir.length() < 0.1:
			dir = Vector2.RIGHT

		draw_line(pos - dir * 36.0, pos, Color(1.0, 0.18, 0.10, 0.30), r * 1.6)
		draw_circle(pos, r * 2.0, Color(1.0, 0.14, 0.08, 0.20))
		draw_circle(pos, r, Color(1.0, 0.34, 0.20, 0.96))


func _draw_zone_art() -> void:
	var zones = _arr("zones")
	for z in zones:
		if typeof(z) != TYPE_DICTIONARY:
			continue
		var pos = _v2(z.get("pos", Vector2.ZERO))
		var r = float(z.get("radius", 80.0))
		var visual = str(z.get("visual", "Zone"))
		var tags = z.get("tags", [])
		var col = _skill_color(visual)
		if typeof(tags) == TYPE_ARRAY and tags.size() > 0:
			col = _color_from_tags(tags)

		var breath = 0.08 + 0.04 * sin(t * 5.0)
		draw_circle(pos, r, Color(col.r, col.g, col.b, breath))
		draw_arc(pos, r, -PI, PI, 96, Color(col.r, col.g, col.b, 0.50), 3.0)
		draw_arc(pos, r * 0.66, -PI, PI, 64, Color(col.r, col.g, col.b, 0.22), 2.0)

		if visual.find("Void") != -1:
			var i = 0
			while i < 8:
				var a = t * 1.7 + float(i) * TAU / 8.0
				var p1 = pos + Vector2(cos(a), sin(a)) * r
				var p2 = pos + Vector2(cos(a + 0.75), sin(a + 0.75)) * r * 0.35
				draw_line(p1, p2, Color(col.r, col.g, col.b, 0.26), 2.0)
				i += 1


func _draw_trap_art() -> void:
	var traps = _arr("traps")
	for tr in traps:
		if typeof(tr) != TYPE_DICTIONARY:
			continue
		var pos = _v2(tr.get("pos", Vector2.ZERO))
		var r = float(tr.get("radius", 44.0))
		var armed = bool(tr.get("armed", true))
		var col = Color(1.0, 0.72, 0.24, 0.80)
		if not armed:
			col = Color(0.62, 0.58, 0.50, 0.45)

		draw_arc(pos, r, -PI, PI, 64, Color(col.r, col.g, col.b, 0.35), 2.0)
		_draw_diamond(pos, 18.0, Color(0.035, 0.030, 0.025, 0.96), col)
		draw_line(pos + Vector2(-13, 0), pos + Vector2(13, 0), Color(col.r, col.g, col.b, 0.65), 2.0)
		draw_line(pos + Vector2(0, -13), pos + Vector2(0, 13), Color(col.r, col.g, col.b, 0.65), 2.0)


func _draw_loot_art() -> void:
	var loot = _arr("loot")
	for l in loot:
		if typeof(l) != TYPE_DICTIONARY:
			continue
		var pos = _v2(l.get("pos", Vector2.ZERO))
		var item = l.get("item", {})
		var rarity = "Magic"
		var name = "Loot"
		if typeof(item) == TYPE_DICTIONARY:
			rarity = str(item.get("rarity", "Magic"))
			name = str(item.get("name", "Loot"))

		var col = _rarity_color(rarity)
		var beam = 42.0 + sin(t * 4.0 + pos.x * 0.02) * 5.0
		draw_line(pos + Vector2(0, -beam), pos + Vector2(0, 5), Color(col.r, col.g, col.b, 0.42), 4.0)
		draw_circle(pos, 14.0, Color(col.r, col.g, col.b, 0.18))
		_draw_diamond(pos, 9.0, Color(0.025, 0.025, 0.030, 0.96), col)
		_draw_label(pos + Vector2(0, -beam - 12), name, Color(col.r, col.g, col.b, 0.88))


func _draw_skill_preview() -> void:
	var run_state = str(game.get("run_state"))
	if run_state == "hub":
		return

	var pos = _player_pos()
	var aim = _aim_pos()
	var skill = _selected_skill()
	if skill == "":
		return

	var dir = (aim - pos).normalized()
	if dir.length() < 0.1:
		dir = Vector2.RIGHT

	var col = _skill_color(skill)

	if skill == "Cleave":
		draw_arc(pos, 96.0, dir.angle() - 0.85, dir.angle() + 0.85, 48, Color(col.r, col.g, col.b, 0.20), 5.0)
		draw_line(pos, pos + dir * 96.0, Color(col.r, col.g, col.b, 0.16), 2.0)
	elif skill == "Frost Nova":
		draw_arc(pos, 150.0, -PI, PI, 96, Color(col.r, col.g, col.b, 0.16), 3.0)
	elif skill == "Void Rift":
		draw_circle(aim, 56.0 + sin(t * 4.0) * 5.0, Color(col.r, col.g, col.b, 0.10))
		draw_arc(aim, 64.0, -PI, PI, 72, Color(col.r, col.g, col.b, 0.26), 3.0)
	elif skill == "Blade Trap":
		_draw_diamond(aim, 26.0, Color(col.r, col.g, col.b, 0.16), Color(col.r, col.g, col.b, 0.62))
	else:
		draw_line(pos + dir * 22.0, pos + dir * 190.0, Color(col.r, col.g, col.b, 0.18), 4.0)


func _draw_fx() -> void:
	for f in fx:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		var pos = _v2(f.get("pos", Vector2.ZERO))
		var r = float(f.get("radius", 40.0))
		var life = float(f.get("life", 0.0))
		var max_life = max(0.01, float(f.get("max_life", 0.55)))
		var k = clamp(life / max_life, 0.0, 1.0)
		var inv = 1.0 - k
		var col = f.get("color", Color(1, 1, 1, 1))
		var kind = str(f.get("kind", "burst"))

		if kind == "slash_cast":
			draw_arc(pos, r * (0.5 + inv), -0.8, 0.8, 32, Color(col.r, col.g, col.b, 0.70 * k), 7.0)
		elif kind == "lightning_cast":
			var i = 0
			while i < 5:
				var a = float(i) * TAU / 5.0 + t * 7.0
				draw_line(pos, pos + Vector2(cos(a), sin(a)) * r * (0.5 + inv), Color(col.r, col.g, col.b, 0.56 * k), 3.0)
				i += 1
		elif kind == "void_cast" or kind == "zone_spawn":
			draw_circle(pos, r * (0.35 + inv * 0.7), Color(col.r, col.g, col.b, 0.11 * k))
			draw_arc(pos, r * (0.55 + inv * 0.8), -PI, PI, 72, Color(col.r, col.g, col.b, 0.58 * k), 3.0)
		elif kind == "hurt":
			draw_circle(pos, r * (0.4 + inv), Color(1.0, 0.05, 0.02, 0.13 * k))
			draw_arc(pos, r * (0.5 + inv), -PI, PI, 64, Color(1.0, 0.10, 0.05, 0.55 * k), 4.0)
		else:
			draw_circle(pos, r * (0.25 + inv), Color(col.r, col.g, col.b, 0.10 * k))
			draw_arc(pos, r * (0.35 + inv), -PI, PI, 64, Color(col.r, col.g, col.b, 0.60 * k), 3.0)


func _draw_world_vignette() -> void:
	var arena = _arena()
	var dark = 0.10 + pulse * 0.08
	draw_rect(Rect2(arena.position, Vector2(arena.size.x, 18)), Color(0, 0, 0, dark), true)
	draw_rect(Rect2(Vector2(arena.position.x, arena.end.y - 18), Vector2(arena.size.x, 18)), Color(0, 0, 0, dark), true)
	draw_rect(Rect2(arena.position, Vector2(18, arena.size.y)), Color(0, 0, 0, dark), true)
	draw_rect(Rect2(Vector2(arena.end.x - 18, arena.position.y), Vector2(18, arena.size.y)), Color(0, 0, 0, dark), true)


func _draw_hex(pos: Vector2, r: float, fill: Color, outline: Color) -> void:
	var pts = PackedVector2Array()
	var i = 0
	while i < 6:
		var a = PI / 6.0 + float(i) * TAU / 6.0
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
		i += 1
	draw_polygon(pts, PackedColorArray([fill]))
	var closed = PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, outline, 2.0)


func _draw_diamond(pos: Vector2, r: float, fill: Color, outline: Color) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(0, -r),
		pos + Vector2(r, 0),
		pos + Vector2(0, r),
		pos + Vector2(-r, 0)
	])
	draw_polygon(pts, PackedColorArray([fill]))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), outline, 2.0)


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


func _draw_label(pos: Vector2, text: String, col: Color) -> void:
	if text == "":
		return
	var font = ThemeDB.fallback_font
	var font_size = 10
	var size_text = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var rect = Rect2(pos - Vector2(size_text.x * 0.5 + 6.0, 9.0), Vector2(size_text.x + 12.0, 17.0))
	draw_rect(rect, Color(0.012, 0.012, 0.015, 0.62), true)
	draw_rect(rect, Color(col.r, col.g, col.b, 0.20), false, 1.0)
	draw_string(font, pos + Vector2(-size_text.x * 0.5, 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


func _shake_offset() -> Vector2:
	if shake <= 0.01:
		return Vector2.ZERO
	return Vector2(randf_range(-shake, shake), randf_range(-shake, shake))


func _arr(name: String) -> Array:
	var value = game.get(name)
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _arena() -> Rect2:
	var value = game.get("ARENA")
	if typeof(value) == TYPE_RECT2:
		return value
	return Rect2(60, 84, 1160, 566)


func _player_pos() -> Vector2:
	var value = game.get("player_pos")
	if typeof(value) == TYPE_VECTOR2:
		return value
	return Vector2(640, 370)


func _aim_pos() -> Vector2:
	return get_global_mouse_position()


func _selected_skill() -> String:
	var skills = _arr("active_skills")
	var selected = int(game.get("selected_skill"))
	if selected >= 0 and selected < skills.size():
		return str(skills[selected])
	return ""


func _max_hp() -> float:
	var hp = 120.0
	if game.has_method("build_stats"):
		var stats = game.call("build_stats")
		if typeof(stats) == TYPE_DICTIONARY:
			hp = max(1.0, float(stats.get("max_hp", 120.0)))
	return hp


func _v2(value) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return value
	return Vector2.ZERO


func _biome_base_color(biome: String) -> Color:
	var b = biome.to_lower()
	if b.find("bone") != -1:
		return Color(0.58, 0.52, 0.38, 1.0)
	if b.find("void") != -1:
		return Color(0.38, 0.22, 0.62, 1.0)
	if b.find("forge") != -1:
		return Color(0.68, 0.26, 0.10, 1.0)
	if b.find("frost") != -1:
		return Color(0.25, 0.48, 0.68, 1.0)
	return Color(0.54, 0.18, 0.10, 1.0)


func _skill_color(skill: String) -> Color:
	if skill.find("Fire") != -1 or skill.find("Ember") != -1:
		return Color(1.0, 0.34, 0.10, 0.96)
	if skill.find("Cleave") != -1 or skill.find("Slash") != -1:
		return Color(1.0, 0.80, 0.48, 0.96)
	if skill.find("Frost") != -1 or skill.find("Nova") != -1 or skill.find("Cold") != -1:
		return Color(0.42, 0.82, 1.0, 0.96)
	if skill.find("Storm") != -1 or skill.find("Lance") != -1:
		return Color(0.72, 0.92, 1.0, 0.96)
	if skill.find("Void") != -1 or skill.find("Rift") != -1:
		return Color(0.70, 0.36, 1.0, 0.96)
	if skill.find("Trap") != -1:
		return Color(0.95, 0.72, 0.28, 0.96)
	return Color(0.90, 0.84, 0.70, 0.96)


func _color_from_tags(tags) -> Color:
	if typeof(tags) != TYPE_ARRAY:
		return Color(0.90, 0.84, 0.70, 0.96)

	for tag in tags:
		var s = str(tag)
		if s == "Fire" or s == "Burn":
			return Color(1.0, 0.34, 0.10, 0.96)
		if s == "Cold" or s == "Freeze":
			return Color(0.42, 0.82, 1.0, 0.96)
		if s == "Lightning" or s == "Chain":
			return Color(0.72, 0.92, 1.0, 0.96)
		if s == "Void" or s == "Curse":
			return Color(0.70, 0.36, 1.0, 0.96)
		if s == "Trap":
			return Color(0.95, 0.72, 0.28, 0.96)
		if s == "Slash" or s == "Melee" or s == "Physical":
			return Color(1.0, 0.80, 0.48, 0.96)

	return Color(0.90, 0.84, 0.70, 0.96)


func _enemy_role(name: String) -> String:
	var n = name.to_lower()
	if n.find("brute") != -1 or n.find("knight") != -1:
		return "brute"
	if n.find("archer") != -1:
		return "shooter"
	if n.find("spitter") != -1:
		return "spitter"
	if n.find("hound") != -1:
		return "hound"
	if n.find("acolyte") != -1:
		return "acolyte"
	if n.find("warden") != -1:
		return "boss"
	return "chaser"


func _enemy_color(name: String, role: String) -> Color:
	var n = name.to_lower()
	if n.find("bone") != -1:
		return Color(0.90, 0.82, 0.60, 0.96)
	if n.find("cinder") != -1:
		return Color(1.0, 0.50, 0.14, 0.96)
	if n.find("iron") != -1 or n.find("knight") != -1:
		return Color(0.62, 0.66, 0.72, 0.96)
	if n.find("rot") != -1:
		return Color(0.38, 0.95, 0.30, 0.96)
	if n.find("mirror") != -1 or n.find("void") != -1 or n.find("warden") != -1:
		return Color(0.74, 0.40, 1.0, 0.96)
	if role == "shooter":
		return Color(0.95, 0.78, 0.42, 0.96)
	if role == "brute":
		return Color(0.70, 0.70, 0.76, 0.96)
	return Color(0.92, 0.28, 0.16, 0.96)


func _enemy_short(name: String) -> String:
	if name.find("Bone") != -1:
		return "ARCHER"
	if name.find("Cinder") != -1:
		return "SPITTER"
	if name.find("Iron") != -1:
		return "BRUTE"
	if name.find("Rot") != -1:
		return "HOUND"
	if name.find("Knight") != -1:
		return "KNIGHT"
	if name.find("Mirror") != -1:
		return "ACOLYTE"
	if name.find("Ash") != -1:
		return "GRUNT"
	return ""


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Magic":
			return Color(0.42, 0.72, 1.0, 0.96)
		"Rare":
			return Color(1.0, 0.82, 0.32, 0.96)
		"Legendary":
			return Color(1.0, 0.44, 0.14, 0.96)
		"Crafted":
			return Color(0.90, 0.36, 1.0, 0.96)
		"Mythic":
			return Color(0.95, 0.25, 1.0, 0.96)
	return Color(0.84, 0.82, 0.74, 0.96)
