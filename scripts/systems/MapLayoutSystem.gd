class_name RVMapLayoutSystem
extends RefCounted

const ARENA_MIN: Vector2 = Vector2(72.0, 78.0)
const ARENA_MAX: Vector2 = Vector2(1210.0, 650.0)

static func generate_layout(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var style: String = _layout_style(map_item)
	match style:
		"catacomb":
			return _generate_catacomb(rng, map_item)
		"archive":
			return _generate_archive(rng, map_item)
		_:
			return _generate_cistern(rng, map_item)

static func _layout_style(map_item: Dictionary) -> String:
	var explicit: String = str(map_item.get("layout_style", ""))
	if explicit != "":
		return explicit
	var text: String = (str(map_item.get("id", "")) + " " + str(map_item.get("area_name", "")) + " " + str(map_item.get("name", ""))).to_lower()
	if text.contains("catacomb") or text.contains("iron"):
		return "catacomb"
	if text.contains("archive") or text.contains("bone") or text.contains("crypt"):
		return "archive"
	return "cistern"

static func _base_layout(map_item: Dictionary, style: String) -> Dictionary:
	return {
		"style": style,
		"map_name": str(map_item.get("name", "Map")),
		"sections": [],
		"edges": [],
		"obstacles": [],
		"corridor_width": 74.0,
		"start_pos": Vector2(640.0, 594.0),
		"boss_pos": Vector2(640.0, 158.0),
		"reward_pos": Vector2(640.0, 178.0),
		"exit_pos": Vector2(640.0, 594.0)
	}

static func _generate_cistern(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var layout: Dictionary = _base_layout(map_item, "cistern")
	layout["corridor_width"] = 70.0
	var sections: Array = [
		_section("start", "start", Vector2(640.0, 594.0), 82.0, 0),
		_section("lower_left", "pack", Vector2(430.0, 520.0), 82.0, 3),
		_section("mid_left", "pack", Vector2(300.0, 365.0), 88.0, 4),
		_section("mid", "pack", Vector2(590.0, 344.0), 94.0, 5),
		_section("side_right", "side", Vector2(890.0, 438.0), 82.0, 3),
		_section("upper_right", "pack", Vector2(970.0, 248.0), 86.0, 4),
		_section("boss", "boss", Vector2(640.0, 152.0), 112.0, 0)
	]
	var edges: Array = [
		["start", "lower_left"],
		["lower_left", "mid_left"],
		["mid_left", "mid"],
		["mid", "side_right"],
		["side_right", "upper_right"],
		["mid", "boss"],
		["upper_right", "boss"]
	]
	layout["sections"] = _jitter_sections(rng, sections, 22.0)
	layout["edges"] = edges
	layout["obstacles"] = [
		_obstacle(Vector2(505.0, 406.0), 30.0, "broken_pillar"),
		_obstacle(Vector2(680.0, 418.0), 28.0, "cistern_column"),
		_obstacle(Vector2(855.0, 320.0), 34.0, "ash_idol"),
		_obstacle(Vector2(535.0, 220.0), 32.0, "collapsed_bridge")
	]
	layout["boss_pos"] = _section_pos(layout, "boss")
	layout["reward_pos"] = _section_pos(layout, "boss") + Vector2(0.0, 46.0)
	layout["exit_pos"] = _section_pos(layout, "start")
	layout["start_pos"] = _section_pos(layout, "start")
	return layout

static func _generate_catacomb(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var layout: Dictionary = _base_layout(map_item, "catacomb")
	layout["corridor_width"] = 64.0
	var sections: Array = [
		_section("start", "start", Vector2(640.0, 604.0), 74.0, 0),
		_section("hall_1", "pack", Vector2(640.0, 494.0), 76.0, 3),
		_section("left_sarc", "side", Vector2(392.0, 430.0), 72.0, 3),
		_section("right_sarc", "side", Vector2(888.0, 430.0), 72.0, 3),
		_section("hall_2", "pack", Vector2(640.0, 332.0), 86.0, 5),
		_section("left_crypt", "pack", Vector2(392.0, 250.0), 78.0, 3),
		_section("right_crypt", "pack", Vector2(888.0, 250.0), 78.0, 3),
		_section("boss", "boss", Vector2(640.0, 142.0), 116.0, 0)
	]
	var edges: Array = [
		["start", "hall_1"],
		["hall_1", "hall_2"],
		["hall_1", "left_sarc"],
		["hall_1", "right_sarc"],
		["hall_2", "left_crypt"],
		["hall_2", "right_crypt"],
		["hall_2", "boss"]
	]
	layout["sections"] = _jitter_sections(rng, sections, 14.0)
	layout["edges"] = edges
	layout["obstacles"] = [
		_obstacle(Vector2(550.0, 414.0), 28.0, "tomb"),
		_obstacle(Vector2(728.0, 414.0), 28.0, "tomb"),
		_obstacle(Vector2(510.0, 260.0), 32.0, "iron_pillar"),
		_obstacle(Vector2(770.0, 260.0), 32.0, "iron_pillar")
	]
	layout["boss_pos"] = _section_pos(layout, "boss")
	layout["reward_pos"] = _section_pos(layout, "boss") + Vector2(0.0, 54.0)
	layout["exit_pos"] = _section_pos(layout, "start")
	layout["start_pos"] = _section_pos(layout, "start")
	return layout

static func _generate_archive(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var layout: Dictionary = _base_layout(map_item, "archive")
	layout["corridor_width"] = 66.0
	var sections: Array = [
		_section("start", "start", Vector2(640.0, 594.0), 76.0, 0),
		_section("lower", "pack", Vector2(640.0, 470.0), 82.0, 4),
		_section("left", "pack", Vector2(410.0, 372.0), 82.0, 4),
		_section("right", "pack", Vector2(870.0, 372.0), 82.0, 4),
		_section("upper", "pack", Vector2(640.0, 262.0), 90.0, 5),
		_section("side_left", "side", Vector2(280.0, 220.0), 74.0, 3),
		_section("side_right", "side", Vector2(1000.0, 220.0), 74.0, 3),
		_section("boss", "boss", Vector2(640.0, 132.0), 108.0, 0)
	]
	var edges: Array = [
		["start", "lower"],
		["lower", "left"],
		["lower", "right"],
		["left", "upper"],
		["right", "upper"],
		["upper", "boss"],
		["left", "side_left"],
		["right", "side_right"]
	]
	layout["sections"] = _jitter_sections(rng, sections, 18.0)
	layout["edges"] = edges
	layout["obstacles"] = [
		_obstacle(Vector2(585.0, 454.0), 26.0, "book_pile"),
		_obstacle(Vector2(700.0, 454.0), 26.0, "book_pile"),
		_obstacle(Vector2(515.0, 310.0), 34.0, "bone_spire"),
		_obstacle(Vector2(765.0, 310.0), 34.0, "bone_spire"),
		_obstacle(Vector2(640.0, 210.0), 30.0, "archive_plinth")
	]
	layout["boss_pos"] = _section_pos(layout, "boss")
	layout["reward_pos"] = _section_pos(layout, "boss") + Vector2(0.0, 52.0)
	layout["exit_pos"] = _section_pos(layout, "start")
	layout["start_pos"] = _section_pos(layout, "start")
	return layout

static func _section(id: String, kind: String, pos: Vector2, radius: float, pack_count: int) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"pos": pos,
		"radius": radius,
		"pack_count": pack_count
	}

static func _obstacle(pos: Vector2, radius: float, kind: String) -> Dictionary:
	return {
		"pos": pos,
		"radius": radius,
		"kind": kind
	}

static func _jitter_sections(rng: RandomNumberGenerator, sections: Array, amount: float) -> Array:
	var result: Array = []
	for value: Variant in sections:
		var section: Dictionary = Dictionary(value).duplicate(true)
		if str(section.get("kind", "")) != "start" and str(section.get("kind", "")) != "boss":
			var jitter: Vector2 = Vector2(rng.randf_range(-amount, amount), rng.randf_range(-amount, amount))
			var pos: Vector2 = Vector2(section.get("pos", Vector2.ZERO)) + jitter
			pos.x = clamp(pos.x, ARENA_MIN.x + 90.0, ARENA_MAX.x - 90.0)
			pos.y = clamp(pos.y, ARENA_MIN.y + 90.0, ARENA_MAX.y - 90.0)
			section["pos"] = pos
		result.append(section)
	return result

static func _section_pos(layout: Dictionary, id: String) -> Vector2:
	for value: Variant in Array(layout.get("sections", [])):
		var section: Dictionary = Dictionary(value)
		if str(section.get("id", "")) == id:
			return Vector2(section.get("pos", Vector2.ZERO))
	return Vector2.ZERO
