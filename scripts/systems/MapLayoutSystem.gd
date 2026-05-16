class_name RVMapLayoutSystem
extends RefCounted

# Patch 066: clearer map pacing, safer starts, stronger boss approach, more side-room rhythm.

const ARENA_MIN: Vector2 = Vector2(72.0, 78.0)
const ARENA_MAX: Vector2 = Vector2(1210.0, 650.0)

static func generate_layout(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var style: String = _layout_style(map_item)
	match style:
		"catacomb": return _generate_catacomb(rng, map_item)
		"archive": return _generate_archive(rng, map_item)
		"foundry": return _generate_foundry(rng, map_item)
		_: return _generate_cistern(rng, map_item)

static func _layout_style(map_item: Dictionary) -> String:
	var explicit: String = str(map_item.get("layout_style", ""))
	if explicit != "":
		return explicit
	var text: String = (str(map_item.get("id", "")) + " " + str(map_item.get("area_name", "")) + " " + str(map_item.get("name", ""))).to_lower()
	if text.contains("catacomb") or text.contains("iron"):
		return "catacomb"
	if text.contains("archive") or text.contains("bone") or text.contains("crypt") or text.contains("chapel"):
		return "archive"
	if text.contains("foundry") or text.contains("storm"):
		return "foundry"
	return "cistern"

static func _base_layout(map_item: Dictionary, style: String) -> Dictionary:
	return {
		"style": style,
		"map_name": str(map_item.get("name", "Map")),
		"sections": [],
		"edges": [],
		"obstacles": [],
		"corridor_width": 76.0,
		"start_pos": Vector2(640.0, 594.0),
		"boss_pos": Vector2(640.0, 148.0),
		"reward_pos": Vector2(640.0, 198.0),
		"exit_pos": Vector2(640.0, 594.0),
		"pacing": ["safe_start", "first_pack", "branch", "side_reward", "elite", "boss_gate", "boss"]
	}

static func _generate_cistern(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var layout: Dictionary = _base_layout(map_item, "cistern")
	layout["corridor_width"] = 74.0
	layout["sections"] = _jitter_sections(rng, [
		_section("start", "start", Vector2(640.0, 594.0), 88.0, 0),
		_section("first_pack", "pack", Vector2(500.0, 512.0), 86.0, 3),
		_section("lower_branch", "pack", Vector2(332.0, 408.0), 92.0, 4),
		_section("side_reward", "side", Vector2(888.0, 438.0), 84.0, 3),
		_section("crossroads", "pack", Vector2(618.0, 348.0), 98.0, 5),
		_section("elite_cistern", "elite", Vector2(960.0, 258.0), 94.0, 5),
		_section("boss_gate", "elite", Vector2(664.0, 238.0), 88.0, 4),
		_section("boss", "boss", Vector2(640.0, 146.0), 126.0, 0)
	], 20.0)
	layout["edges"] = [["start", "first_pack"], ["first_pack", "lower_branch"], ["first_pack", "side_reward"], ["lower_branch", "crossroads"], ["side_reward", "elite_cistern"], ["crossroads", "boss_gate"], ["elite_cistern", "boss_gate"], ["boss_gate", "boss"]]
	layout["obstacles"] = [_obstacle(Vector2(505.0, 406.0), 30.0, "broken_pillar"), _obstacle(Vector2(680.0, 418.0), 28.0, "cistern_column"), _obstacle(Vector2(855.0, 320.0), 34.0, "ash_idol"), _obstacle(Vector2(535.0, 220.0), 32.0, "collapsed_bridge")]
	return _finalize(layout)

static func _generate_catacomb(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var layout: Dictionary = _base_layout(map_item, "catacomb")
	layout["corridor_width"] = 68.0
	layout["sections"] = _jitter_sections(rng, [
		_section("start", "start", Vector2(640.0, 604.0), 80.0, 0),
		_section("first_hall", "pack", Vector2(640.0, 500.0), 82.0, 3),
		_section("left_sarc", "side", Vector2(386.0, 430.0), 76.0, 3),
		_section("right_sarc", "side", Vector2(894.0, 430.0), 76.0, 3),
		_section("central_crypt", "pack", Vector2(640.0, 328.0), 92.0, 5),
		_section("left_crypt", "pack", Vector2(392.0, 248.0), 82.0, 3),
		_section("right_crypt", "pack", Vector2(888.0, 248.0), 82.0, 3),
		_section("boss_gate", "elite", Vector2(640.0, 226.0), 86.0, 5),
		_section("boss", "boss", Vector2(640.0, 136.0), 124.0, 0)
	], 14.0)
	layout["edges"] = [["start", "first_hall"], ["first_hall", "central_crypt"], ["first_hall", "left_sarc"], ["first_hall", "right_sarc"], ["central_crypt", "left_crypt"], ["central_crypt", "right_crypt"], ["central_crypt", "boss_gate"], ["boss_gate", "boss"]]
	layout["obstacles"] = [_obstacle(Vector2(550.0, 414.0), 28.0, "tomb"), _obstacle(Vector2(728.0, 414.0), 28.0, "tomb"), _obstacle(Vector2(510.0, 260.0), 32.0, "iron_pillar"), _obstacle(Vector2(770.0, 260.0), 32.0, "iron_pillar")]
	return _finalize(layout)

static func _generate_archive(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var layout: Dictionary = _base_layout(map_item, "archive")
	layout["corridor_width"] = 70.0
	layout["sections"] = _jitter_sections(rng, [
		_section("start", "start", Vector2(640.0, 594.0), 82.0, 0),
		_section("lower", "pack", Vector2(640.0, 476.0), 88.0, 4),
		_section("left", "pack", Vector2(410.0, 374.0), 86.0, 4),
		_section("right", "pack", Vector2(870.0, 374.0), 86.0, 4),
		_section("side_left", "side", Vector2(280.0, 226.0), 78.0, 3),
		_section("side_right", "side", Vector2(1000.0, 226.0), 78.0, 3),
		_section("upper", "elite", Vector2(640.0, 262.0), 96.0, 5),
		_section("boss", "boss", Vector2(640.0, 132.0), 122.0, 0)
	], 18.0)
	layout["edges"] = [["start", "lower"], ["lower", "left"], ["lower", "right"], ["left", "upper"], ["right", "upper"], ["left", "side_left"], ["right", "side_right"], ["upper", "boss"]]
	layout["obstacles"] = [_obstacle(Vector2(585.0, 454.0), 26.0, "book_pile"), _obstacle(Vector2(700.0, 454.0), 26.0, "book_pile"), _obstacle(Vector2(515.0, 310.0), 34.0, "bone_spire"), _obstacle(Vector2(765.0, 310.0), 34.0, "bone_spire")]
	return _finalize(layout)

static func _generate_foundry(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var layout: Dictionary = _base_layout(map_item, "foundry")
	layout["corridor_width"] = 82.0
	layout["sections"] = _jitter_sections(rng, [
		_section("start", "start", Vector2(640.0, 600.0), 86.0, 0),
		_section("forge_1", "pack", Vector2(472.0, 500.0), 90.0, 4),
		_section("forge_2", "pack", Vector2(812.0, 494.0), 90.0, 4),
		_section("crossing", "pack", Vector2(640.0, 380.0), 104.0, 6),
		_section("side_furnace", "side", Vector2(1010.0, 356.0), 86.0, 3),
		_section("elite_bridge", "elite", Vector2(640.0, 248.0), 96.0, 5),
		_section("boss", "boss", Vector2(640.0, 130.0), 130.0, 0)
	], 16.0)
	layout["edges"] = [["start", "forge_1"], ["start", "forge_2"], ["forge_1", "crossing"], ["forge_2", "crossing"], ["crossing", "side_furnace"], ["crossing", "elite_bridge"], ["elite_bridge", "boss"]]
	layout["obstacles"] = [_obstacle(Vector2(560.0, 440.0), 30.0, "forge_anvil"), _obstacle(Vector2(720.0, 440.0), 30.0, "forge_anvil"), _obstacle(Vector2(640.0, 316.0), 38.0, "charged_core"), _obstacle(Vector2(830.0, 260.0), 28.0, "sparking_pillar")]
	return _finalize(layout)

static func _finalize(layout: Dictionary) -> Dictionary:
	layout["boss_pos"] = _section_pos(layout, "boss")
	layout["reward_pos"] = _section_pos(layout, "boss") + Vector2(0.0, 58.0)
	layout["exit_pos"] = _section_pos(layout, "start")
	layout["start_pos"] = _section_pos(layout, "start")
	return layout

static func _section(id: String, kind: String, pos: Vector2, radius: float, pack_count: int) -> Dictionary:
	return {"id": id, "kind": kind, "pos": pos, "radius": radius, "pack_count": pack_count}

static func _obstacle(pos: Vector2, radius: float, kind: String) -> Dictionary:
	return {"pos": pos, "radius": radius, "kind": kind}

static func _jitter_sections(rng: RandomNumberGenerator, sections: Array, amount: float) -> Array:
	var result: Array = []
	for value: Variant in sections:
		var section: Dictionary = Dictionary(value).duplicate(true)
		var kind: String = str(section.get("kind", ""))
		if kind != "start" and kind != "boss":
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
