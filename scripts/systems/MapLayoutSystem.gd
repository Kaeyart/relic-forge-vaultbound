class_name RVMapLayoutSystem
extends RefCounted

const ARCHETYPE_STRAND_ROAD: String = "strand_road"
const ARCHETYPE_LOOP_CISTERN: String = "loop_cistern"
const ARCHETYPE_BRANCHING_CATACOMB: String = "branching_catacomb"
const ARCHETYPE_SEWER_AQUEDUCT: String = "sewer_aqueduct"
const ARCHETYPE_FORTRESS_BASTION: String = "fortress_bastion"
const ARCHETYPE_FORGEWORKS: String = "forgeworks"
const ARCHETYPE_SANCTUM_TEMPLE: String = "sanctum_temple"
const ARCHETYPE_VAULT: String = "vault"
const ARCHETYPE_OSSUARY_CRYPT: String = "ossuary_crypt"
const ARCHETYPE_OPEN_RUINS: String = "open_ruins"

const ALL_ARCHETYPES: Array[String] = [
	ARCHETYPE_STRAND_ROAD,
	ARCHETYPE_LOOP_CISTERN,
	ARCHETYPE_BRANCHING_CATACOMB,
	ARCHETYPE_SEWER_AQUEDUCT,
	ARCHETYPE_FORTRESS_BASTION,
	ARCHETYPE_FORGEWORKS,
	ARCHETYPE_SANCTUM_TEMPLE,
	ARCHETYPE_VAULT,
	ARCHETYPE_OSSUARY_CRYPT,
	ARCHETYPE_OPEN_RUINS,
]

static func generate_layout(rng: RandomNumberGenerator, map_item: Dictionary) -> Dictionary:
	var archetype: String = archetype_for_map(map_item)
	var layout: Dictionary = _layout_for_archetype(archetype)
	layout["layout_archetype"] = archetype
	layout["layout_label"] = layout_label(archetype)
	layout["clear_pattern"] = clear_pattern(archetype)
	layout["theme"] = _theme_for_map(map_item, archetype)
	layout["map_id"] = str(map_item.get("id", "map"))
	layout["map_name"] = str(map_item.get("name", "Map"))
	layout["map_tier"] = int(map_item.get("tier", 1))
	layout["rarity"] = str(map_item.get("rarity", "Normal"))
	layout["is_continuous_field"] = true
	layout["uses_room_graph"] = false
	layout["pack_density_scalar"] = _pack_density_scalar(map_item)
	layout["recommended_camera_zoom"] = 1.0
	_apply_density(layout, map_item)
	_apply_small_variation(layout, rng, map_item)
	_finalize_layout(layout)
	return layout

static func archetype_for_map(map_item: Dictionary) -> String:
	var text: String = (
		str(map_item.get("layout_archetype", "")) + " " +
		str(map_item.get("id", "")) + " " +
		str(map_item.get("area_name", "")) + " " +
		str(map_item.get("name", "")) + " " +
		str(map_item.get("base_type", ""))
	).to_lower()
	if text.contains("strand") or text.contains("road") or text.contains("causeway") or text.contains("passage"):
		return ARCHETYPE_STRAND_ROAD
	if text.contains("ossuary") or text.contains("bone") or text.contains("charnel"):
		return ARCHETYPE_OSSUARY_CRYPT
	if text.contains("cistern") or text.contains("pool") or text.contains("reservoir") or text.contains("loop"):
		return ARCHETYPE_LOOP_CISTERN
	if text.contains("catacomb") or text.contains("crypt") or text.contains("grave") or text.contains("burial"):
		return ARCHETYPE_BRANCHING_CATACOMB
	if text.contains("aqueduct") or text.contains("sewer") or text.contains("channel") or text.contains("waterway"):
		return ARCHETYPE_SEWER_AQUEDUCT
	if text.contains("bastion") or text.contains("stronghold") or text.contains("keep") or text.contains("fortress") or text.contains("citadel"):
		return ARCHETYPE_FORTRESS_BASTION
	if text.contains("forge") or text.contains("foundry") or text.contains("furnace") or text.contains("works") or text.contains("anvil"):
		return ARCHETYPE_FORGEWORKS
	if text.contains("sanctum") or text.contains("temple") or text.contains("chapel") or text.contains("altar") or text.contains("shrine"):
		return ARCHETYPE_SANCTUM_TEMPLE
	if text.contains("vault") or text.contains("treasure") or text.contains("archive") or text.contains("lockbox"):
		return ARCHETYPE_VAULT
	if text.contains("ruin") or text.contains("ash field") or text.contains("depth") or text.contains("waste") or text.contains("field"):
		return ARCHETYPE_OPEN_RUINS
	var tier: int = int(map_item.get("tier", 1))
	var hash_value: int = abs(str(map_item.get("id", str(map_item.get("name", "map")))).hash())
	return ALL_ARCHETYPES[(hash_value + tier) % ALL_ARCHETYPES.size()]

static func layout_label(archetype: String) -> String:
	match archetype:
		ARCHETYPE_STRAND_ROAD: return "Strand / Road"
		ARCHETYPE_LOOP_CISTERN: return "Loop / Cistern"
		ARCHETYPE_BRANCHING_CATACOMB: return "Branching Catacomb"
		ARCHETYPE_SEWER_AQUEDUCT: return "Sewer / Aqueduct"
		ARCHETYPE_FORTRESS_BASTION: return "Fortress / Bastion"
		ARCHETYPE_FORGEWORKS: return "Forgeworks"
		ARCHETYPE_SANCTUM_TEMPLE: return "Sanctum / Temple"
		ARCHETYPE_VAULT: return "Vault"
		ARCHETYPE_OSSUARY_CRYPT: return "Ossuary / Crypt Maze"
		ARCHETYPE_OPEN_RUINS: return "Open Ruins / Ash Field"
	return archetype.capitalize()

static func clear_pattern(archetype: String) -> String:
	match archetype:
		ARCHETYPE_STRAND_ROAD: return "fast linear clear, boss at far end"
		ARCHETYPE_LOOP_CISTERN: return "clockwise/counterclockwise loop clear"
		ARCHETYPE_BRANCHING_CATACOMB: return "main spine with side crypt pockets"
		ARCHETYPE_SEWER_AQUEDUCT: return "parallel lanes with cross-bridges"
		ARCHETYPE_FORTRESS_BASTION: return "courtyards, gatehouses, keep boss"
		ARCHETYPE_FORGEWORKS: return "industrial lanes, furnace pockets, chokepoints"
		ARCHETYPE_SANCTUM_TEMPLE: return "radial hub with ritual spokes"
		ARCHETYPE_VAULT: return "compact dense treasure route"
		ARCHETYPE_OSSUARY_CRYPT: return "maze-like crypt rooms and dead ends"
		ARCHETYPE_OPEN_RUINS: return "wide broken field shaped by ruin pockets"
	return "continuous map clear"

static func _layout_for_archetype(archetype: String) -> Dictionary:
	match archetype:
		ARCHETYPE_STRAND_ROAD: return _layout_strand_road()
		ARCHETYPE_LOOP_CISTERN: return _layout_loop_cistern()
		ARCHETYPE_BRANCHING_CATACOMB: return _layout_branching_catacomb()
		ARCHETYPE_SEWER_AQUEDUCT: return _layout_sewer_aqueduct()
		ARCHETYPE_FORTRESS_BASTION: return _layout_fortress_bastion()
		ARCHETYPE_FORGEWORKS: return _layout_forgeworks()
		ARCHETYPE_SANCTUM_TEMPLE: return _layout_sanctum_temple()
		ARCHETYPE_VAULT: return _layout_vault()
		ARCHETYPE_OSSUARY_CRYPT: return _layout_ossuary_crypt()
		ARCHETYPE_OPEN_RUINS: return _layout_open_ruins()
	return _layout_strand_road()

static func _layout_strand_road() -> Dictionary:
	return _layout("strand_road", [
		_section("start", "start", Vector2(640, 640), 96, 0),
		_section("road_1", "pack", Vector2(620, 420), 104, 4),
		_section("road_2", "pack", Vector2(720, 210), 106, 4),
		_section("side_cache_l", "side", Vector2(440, 110), 92, 3),
		_section("road_3", "pack", Vector2(805, -20), 112, 5),
		_section("road_4", "pack", Vector2(670, -250), 112, 5),
		_section("side_cache_r", "side", Vector2(930, -180), 88, 3),
		_section("road_5", "elite", Vector2(560, -480), 116, 5),
		_section("approach", "pack", Vector2(690, -720), 118, 5),
		_section("boss", "boss", Vector2(700, -995), 170, 0),
	], [
		["start", "road_1"], ["road_1", "road_2"], ["road_2", "road_3"], ["road_2", "side_cache_l"],
		["road_3", "road_4"], ["road_3", "side_cache_r"], ["road_4", "road_5"], ["road_5", "approach"], ["approach", "boss"],
	], 86, Rect2(180, -1180, 960, 1960))

static func _layout_loop_cistern() -> Dictionary:
	return _layout("loop_cistern", [
		_section("start", "start", Vector2(640, 650), 102, 0),
		_section("south_pool", "pack", Vector2(410, 480), 118, 4),
		_section("west_intake", "side", Vector2(250, 230), 104, 4),
		_section("northwest", "pack", Vector2(360, -45), 118, 5),
		_section("north_ring", "elite", Vector2(640, -165), 132, 5),
		_section("northeast", "pack", Vector2(930, -45), 118, 5),
		_section("east_intake", "side", Vector2(1040, 230), 104, 4),
		_section("east_pool", "pack", Vector2(870, 480), 118, 4),
		_section("central_silt", "pack", Vector2(640, 220), 132, 5),
		_section("boss", "boss", Vector2(640, -430), 170, 0),
	], [
		["start", "south_pool"], ["start", "east_pool"], ["south_pool", "west_intake"], ["west_intake", "northwest"],
		["northwest", "north_ring"], ["north_ring", "northeast"], ["northeast", "east_intake"], ["east_intake", "east_pool"],
		["east_pool", "central_silt"], ["central_silt", "south_pool"], ["north_ring", "boss"],
	], 92, Rect2(95, -610, 1100, 1400))

static func _layout_branching_catacomb() -> Dictionary:
	return _layout("branching_catacomb", [
		_section("start", "start", Vector2(640, 660), 92, 0),
		_section("spine_1", "pack", Vector2(640, 455), 92, 4),
		_section("left_crypt_1", "side", Vector2(405, 390), 92, 4),
		_section("right_crypt_1", "side", Vector2(885, 335), 94, 4),
		_section("spine_2", "pack", Vector2(640, 215), 98, 4),
		_section("left_crypt_2", "pack", Vector2(345, 145), 100, 5),
		_section("spine_3", "elite", Vector2(640, -20), 110, 5),
		_section("right_crypt_2", "side", Vector2(930, -80), 100, 4),
		_section("spine_4", "pack", Vector2(640, -270), 104, 5),
		_section("left_deadend", "side", Vector2(410, -335), 88, 3),
		_section("boss", "boss", Vector2(640, -560), 160, 0),
	], [
		["start", "spine_1"], ["spine_1", "spine_2"], ["spine_1", "left_crypt_1"], ["spine_2", "right_crypt_1"],
		["spine_2", "left_crypt_2"], ["spine_2", "spine_3"], ["spine_3", "right_crypt_2"], ["spine_3", "spine_4"],
		["spine_4", "left_deadend"], ["spine_4", "boss"],
	], 74, Rect2(180, -720, 980, 1540))

static func _layout_sewer_aqueduct() -> Dictionary:
	return _layout("sewer_aqueduct", [
		_section("start", "start", Vector2(640, 650), 88, 0),
		_section("lower_left", "pack", Vector2(420, 470), 92, 4),
		_section("lower_right", "pack", Vector2(865, 470), 92, 4),
		_section("bridge_1", "side", Vector2(640, 285), 84, 3),
		_section("mid_left", "pack", Vector2(420, 105), 98, 5),
		_section("mid_right", "pack", Vector2(865, 105), 98, 5),
		_section("bridge_2", "elite", Vector2(640, -85), 104, 5),
		_section("upper_left", "pack", Vector2(420, -285), 98, 5),
		_section("upper_right", "side", Vector2(865, -285), 98, 4),
		_section("sluice_gate", "pack", Vector2(640, -475), 108, 5),
		_section("boss", "boss", Vector2(640, -720), 160, 0),
	], [
		["start", "lower_left"], ["start", "lower_right"], ["lower_left", "bridge_1"], ["lower_right", "bridge_1"],
		["bridge_1", "mid_left"], ["bridge_1", "mid_right"], ["mid_left", "bridge_2"], ["mid_right", "bridge_2"],
		["bridge_2", "upper_left"], ["bridge_2", "upper_right"], ["upper_left", "sluice_gate"], ["upper_right", "sluice_gate"], ["sluice_gate", "boss"],
	], 78, Rect2(220, -880, 850, 1700))

static func _layout_fortress_bastion() -> Dictionary:
	return _layout("fortress_bastion", [
		_section("start", "start", Vector2(640, 650), 96, 0),
		_section("outer_gate", "pack", Vector2(640, 450), 116, 5),
		_section("left_wall", "side", Vector2(390, 310), 104, 4),
		_section("right_wall", "side", Vector2(890, 310), 104, 4),
		_section("courtyard", "pack", Vector2(640, 160), 145, 6),
		_section("barracks_l", "pack", Vector2(385, 20), 108, 5),
		_section("barracks_r", "pack", Vector2(895, 20), 108, 5),
		_section("inner_gate", "elite", Vector2(640, -135), 118, 6),
		_section("keep_yard", "pack", Vector2(640, -345), 124, 5),
		_section("boss", "boss", Vector2(640, -610), 180, 0),
	], [
		["start", "outer_gate"], ["outer_gate", "left_wall"], ["outer_gate", "right_wall"], ["outer_gate", "courtyard"],
		["left_wall", "courtyard"], ["right_wall", "courtyard"], ["courtyard", "barracks_l"], ["courtyard", "barracks_r"],
		["barracks_l", "inner_gate"], ["barracks_r", "inner_gate"], ["inner_gate", "keep_yard"], ["keep_yard", "boss"],
	], 88, Rect2(180, -800, 1000, 1600))

static func _layout_forgeworks() -> Dictionary:
	return _layout("forgeworks", [
		_section("start", "start", Vector2(640, 650), 92, 0),
		_section("conveyor_1", "pack", Vector2(640, 455), 100, 4),
		_section("furnace_l", "side", Vector2(380, 320), 98, 4),
		_section("furnace_r", "side", Vector2(905, 300), 98, 4),
		_section("press_hall", "pack", Vector2(640, 175), 112, 5),
		_section("slag_pit", "pack", Vector2(430, 20), 104, 5),
		_section("chainworks", "pack", Vector2(855, -5), 104, 5),
		_section("anvil_choke", "elite", Vector2(640, -195), 118, 6),
		_section("molten_lane", "pack", Vector2(640, -430), 112, 5),
		_section("boss", "boss", Vector2(640, -690), 170, 0),
	], [
		["start", "conveyor_1"], ["conveyor_1", "press_hall"], ["conveyor_1", "furnace_l"], ["conveyor_1", "furnace_r"],
		["press_hall", "slag_pit"], ["press_hall", "chainworks"], ["slag_pit", "anvil_choke"], ["chainworks", "anvil_choke"],
		["anvil_choke", "molten_lane"], ["molten_lane", "boss"],
	], 82, Rect2(180, -850, 1000, 1680))

static func _layout_sanctum_temple() -> Dictionary:
	return _layout("sanctum_temple", [
		_section("start", "start", Vector2(640, 650), 96, 0),
		_section("ritual_hub", "pack", Vector2(640, 355), 140, 6),
		_section("west_spoke", "side", Vector2(340, 250), 98, 4),
		_section("east_spoke", "side", Vector2(940, 250), 98, 4),
		_section("northwest_spoke", "pack", Vector2(430, 25), 104, 5),
		_section("northeast_spoke", "pack", Vector2(850, 25), 104, 5),
		_section("inner_ring", "elite", Vector2(640, -75), 120, 6),
		_section("reliquary_l", "side", Vector2(410, -250), 92, 4),
		_section("reliquary_r", "side", Vector2(870, -250), 92, 4),
		_section("boss", "boss", Vector2(640, -430), 175, 0),
	], [
		["start", "ritual_hub"], ["ritual_hub", "west_spoke"], ["ritual_hub", "east_spoke"], ["ritual_hub", "northwest_spoke"],
		["ritual_hub", "northeast_spoke"], ["northwest_spoke", "inner_ring"], ["northeast_spoke", "inner_ring"],
		["inner_ring", "reliquary_l"], ["inner_ring", "reliquary_r"], ["inner_ring", "boss"],
	], 90, Rect2(180, -620, 1000, 1450))

static func _layout_vault() -> Dictionary:
	return _layout("vault", [
		_section("start", "start", Vector2(640, 635), 86, 0),
		_section("entry_lock", "pack", Vector2(640, 465), 92, 4),
		_section("left_cache", "side", Vector2(430, 360), 86, 4),
		_section("right_cache", "side", Vector2(850, 360), 86, 4),
		_section("gold_lane", "pack", Vector2(520, 180), 92, 5),
		_section("relic_lane", "pack", Vector2(760, 180), 92, 5),
		_section("security_core", "elite", Vector2(640, 10), 115, 6),
		_section("deep_cache_l", "side", Vector2(435, -130), 86, 4),
		_section("deep_cache_r", "side", Vector2(845, -130), 86, 4),
		_section("boss", "boss", Vector2(640, -330), 150, 0),
	], [
		["start", "entry_lock"], ["entry_lock", "left_cache"], ["entry_lock", "right_cache"], ["entry_lock", "gold_lane"], ["entry_lock", "relic_lane"],
		["gold_lane", "security_core"], ["relic_lane", "security_core"], ["security_core", "deep_cache_l"], ["security_core", "deep_cache_r"], ["security_core", "boss"],
	], 76, Rect2(250, -500, 780, 1280))

static func _layout_ossuary_crypt() -> Dictionary:
	return _layout("ossuary_crypt", [
		_section("start", "start", Vector2(640, 650), 88, 0),
		_section("bone_hall_1", "pack", Vector2(530, 470), 88, 4),
		_section("bone_hall_2", "pack", Vector2(755, 440), 88, 4),
		_section("skull_room_l", "side", Vector2(340, 325), 86, 4),
		_section("spine_junction", "pack", Vector2(640, 240), 98, 5),
		_section("rib_room_r", "side", Vector2(955, 155), 86, 4),
		_section("ossuary_cross", "elite", Vector2(550, -5), 108, 6),
		_section("dead_end_l", "side", Vector2(300, -150), 82, 3),
		_section("crypt_turn", "pack", Vector2(760, -210), 98, 5),
		_section("marrow_cache", "side", Vector2(1040, -260), 82, 4),
		_section("boss", "boss", Vector2(650, -520), 165, 0),
	], [
		["start", "bone_hall_1"], ["start", "bone_hall_2"], ["bone_hall_1", "skull_room_l"], ["bone_hall_1", "spine_junction"],
		["bone_hall_2", "spine_junction"], ["spine_junction", "rib_room_r"], ["spine_junction", "ossuary_cross"],
		["ossuary_cross", "dead_end_l"], ["ossuary_cross", "crypt_turn"], ["crypt_turn", "marrow_cache"], ["crypt_turn", "boss"],
	], 70, Rect2(150, -690, 1060, 1540))

static func _layout_open_ruins() -> Dictionary:
	return _layout("open_ruins", [
		_section("start", "start", Vector2(640, 650), 105, 0),
		_section("south_ruins", "pack", Vector2(470, 470), 126, 5),
		_section("broken_square", "pack", Vector2(790, 440), 132, 5),
		_section("west_plaza", "side", Vector2(300, 190), 112, 4),
		_section("central_road", "pack", Vector2(640, 190), 142, 6),
		_section("east_camp", "side", Vector2(990, 160), 112, 4),
		_section("fallen_tower", "elite", Vector2(470, -90), 126, 6),
		_section("ash_market", "pack", Vector2(805, -115), 126, 5),
		_section("north_ruins", "pack", Vector2(640, -355), 134, 6),
		_section("boss", "boss", Vector2(640, -650), 185, 0),
	], [
		["start", "south_ruins"], ["start", "broken_square"], ["south_ruins", "west_plaza"], ["south_ruins", "central_road"],
		["broken_square", "central_road"], ["broken_square", "east_camp"], ["central_road", "fallen_tower"], ["central_road", "ash_market"],
		["fallen_tower", "north_ruins"], ["ash_market", "north_ruins"], ["north_ruins", "boss"],
	], 104, Rect2(90, -850, 1160, 1700))

static func _layout(id: String, sections: Array, edges: Array, corridor_width: float, bounds: Rect2) -> Dictionary:
	var start_pos: Vector2 = Vector2(640, 620)
	var boss_pos: Vector2 = Vector2(640, -560)
	for section_value: Variant in sections:
		var section: Dictionary = Dictionary(section_value)
		if str(section.get("id", "")) == "start":
			start_pos = Vector2(section.get("pos", start_pos))
		elif str(section.get("kind", "")) == "boss":
			boss_pos = Vector2(section.get("pos", boss_pos))
	return {
		"id": id,
		"sections": sections,
		"edges": edges,
		"obstacles": _build_obstacles(sections, id),
		"corridor_width": corridor_width,
		"bounds": bounds,
		"start_pos": start_pos,
		"boss_pos": boss_pos,
		"reward_pos": boss_pos + Vector2(0, 118),
		"exit_pos": start_pos + Vector2(0, 50),
		"is_continuous_field": true,
	}

static func _section(id: String, kind: String, pos: Vector2, radius: float, pack_count: int = 4) -> Dictionary:
	return {"id": id, "kind": kind, "pos": pos, "radius": radius, "pack_count": pack_count}

static func _build_obstacles(sections: Array, id: String) -> Array:
	var obstacles: Array = []
	var index: int = 0
	for section_value: Variant in sections:
		var section: Dictionary = Dictionary(section_value)
		var kind: String = str(section.get("kind", "pack"))
		if kind == "start" or kind == "boss":
			continue
		var center: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
		var radius: float = float(section.get("radius", 88.0))
		var count: int = 1 if kind == "side" else 2
		for local_index: int in range(count):
			var angle: float = (float(index + local_index) * 1.973) + float(abs(id.hash()) % 17) * 0.11
			var dist: float = radius * (0.58 + 0.16 * float(local_index))
			obstacles.append({
				"id": "obs_" + str(index) + "_" + str(local_index),
				"pos": center + Vector2(cos(angle), sin(angle)) * dist,
				"radius": clamp(radius * (0.18 + 0.04 * float((index + local_index) % 3)), 18.0, 42.0),
				"kind": "ruin_blocker",
			})
		index += 1
	return obstacles

static func _apply_density(layout: Dictionary, map_item: Dictionary) -> void:
	var tier: int = int(map_item.get("tier", 1))
	var rarity: String = str(map_item.get("rarity", "Normal"))
	var scalar: float = _pack_density_scalar(map_item)
	var bonus_sections: int = 0
	if rarity == "Rare":
		bonus_sections = 2
	elif rarity == "Magic":
		bonus_sections = 1
	if tier >= 11:
		bonus_sections += 1
	var sections: Array = Array(layout.get("sections", []))
	for i: int in range(sections.size()):
		var section: Dictionary = Dictionary(sections[i])
		if str(section.get("kind", "")) in ["pack", "side", "elite"]:
			section["pack_count"] = clampi(int(round(float(section.get("pack_count", 4)) * scalar)), 2, 8)
		sections[i] = section
	layout["sections"] = sections
	if bonus_sections > 0:
		_add_density_side_pockets(layout, bonus_sections)

static func _add_density_side_pockets(layout: Dictionary, count: int) -> void:
	var sections: Array = Array(layout.get("sections", []))
	var edges: Array = Array(layout.get("edges", []))
	var candidates: Array = []
	for section_value: Variant in sections:
		var section: Dictionary = Dictionary(section_value)
		if str(section.get("kind", "")) in ["pack", "elite"]:
			candidates.append(section)
	for i: int in range(min(count, candidates.size())):
		var base: Dictionary = Dictionary(candidates[(i * 3 + 1) % candidates.size()])
		var base_pos: Vector2 = Vector2(base.get("pos", Vector2.ZERO))
		var dir: Vector2 = Vector2.RIGHT.rotated(float(i) * 2.09 + float(abs(str(layout.get("id", "map")).hash()) % 9) * 0.12)
		var pocket_id: String = "density_side_" + str(i)
		sections.append(_section(pocket_id, "side", base_pos + dir * 225.0, 84.0, 3))
		edges.append([str(base.get("id", "")), pocket_id])
	layout["sections"] = sections
	layout["edges"] = edges
	layout["obstacles"] = _build_obstacles(sections, str(layout.get("id", "map")))

static func _apply_small_variation(layout: Dictionary, rng: RandomNumberGenerator, map_item: Dictionary) -> void:
	if rng == null:
		return
	var sections: Array = Array(layout.get("sections", []))
	var jitter: float = 14.0 + min(18.0, float(int(map_item.get("tier", 1))) * 1.25)
	for i: int in range(sections.size()):
		var section: Dictionary = Dictionary(sections[i])
		var kind: String = str(section.get("kind", ""))
		if kind == "start" or kind == "boss":
			sections[i] = section
			continue
		var pos: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
		pos += Vector2(rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter))
		section["pos"] = pos
		sections[i] = section
	layout["sections"] = sections
	layout["obstacles"] = _build_obstacles(sections, str(layout.get("id", "map")))

static func _finalize_layout(layout: Dictionary) -> void:
	var sections: Array = Array(layout.get("sections", []))
	var start_pos: Vector2 = Vector2(layout.get("start_pos", Vector2(640, 620)))
	var boss_pos: Vector2 = Vector2(layout.get("boss_pos", Vector2(640, -560)))
	for section_value: Variant in sections:
		var section: Dictionary = Dictionary(section_value)
		if str(section.get("id", "")) == "start":
			start_pos = Vector2(section.get("pos", start_pos))
		if str(section.get("kind", "")) == "boss":
			boss_pos = Vector2(section.get("pos", boss_pos))
	layout["start_pos"] = start_pos
	layout["boss_pos"] = boss_pos
	layout["reward_pos"] = boss_pos + Vector2(0, 118)
	layout["exit_pos"] = start_pos + Vector2(0, 50)
	if not layout.has("bounds"):
		layout["bounds"] = _bounds_from_sections(sections)

static func _bounds_from_sections(sections: Array) -> Rect2:
	if sections.is_empty():
		return Rect2(0, 0, 1280, 720)
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	for section_value: Variant in sections:
		var section: Dictionary = Dictionary(section_value)
		var pos: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
		var radius: float = float(section.get("radius", 90.0)) + 220.0
		min_x = min(min_x, pos.x - radius)
		min_y = min(min_y, pos.y - radius)
		max_x = max(max_x, pos.x + radius)
		max_y = max(max_y, pos.y + radius)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

static func _pack_density_scalar(map_item: Dictionary) -> float:
	var scalar: float = max(0.75, float(map_item.get("pack_size", 1.0)))
	match str(map_item.get("rarity", "Normal")):
		"Magic": scalar += 0.08
		"Rare": scalar += 0.16
		"Unique": scalar += 0.22
	return clamp(scalar, 0.80, 1.65)

static func _theme_for_map(map_item: Dictionary, archetype: String) -> String:
	var text: String = (str(map_item.get("id", "")) + " " + str(map_item.get("area_name", "")) + " " + str(map_item.get("name", ""))).to_lower()
	for tag: String in ["ash", "iron", "forge", "bone", "water", "void", "storm", "vault", "sanctum", "ruin"]:
		if text.contains(tag):
			return tag
	match archetype:
		ARCHETYPE_LOOP_CISTERN: return "ash"
		ARCHETYPE_BRANCHING_CATACOMB, ARCHETYPE_OSSUARY_CRYPT: return "bone"
		ARCHETYPE_SEWER_AQUEDUCT: return "water"
		ARCHETYPE_FORGEWORKS: return "forge"
		ARCHETYPE_VAULT: return "vault"
		ARCHETYPE_SANCTUM_TEMPLE: return "sanctum"
		ARCHETYPE_FORTRESS_BASTION: return "iron"
		ARCHETYPE_OPEN_RUINS: return "ruin"
	return "ash"
