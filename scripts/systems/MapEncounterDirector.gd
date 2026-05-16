class_name RVMapEncounterDirector
extends RefCounted

# Patch 058: map pacing and pack composition. This is intentionally pure data/planning.
# CombatArena consumes the generated plan and spawns EnemyActor nodes.

const PACKS: Dictionary = {
	"pressure": {
		"label": "Pressure Pack",
		"types": ["Grunt", "Grunt", "Grunt", "Lunger"],
		"elite_chance": 0.02
	},
	"ranged": {
		"label": "Ranged Pack",
		"types": ["Grunt", "Archer", "Archer", "Spitter"],
		"elite_chance": 0.03
	},
	"caster": {
		"label": "Caster Pack",
		"types": ["Grunt", "Spitter", "Binder", "Archer"],
		"elite_chance": 0.04
	},
	"hound": {
		"label": "Hound Rush",
		"types": ["Hound", "Hound", "Hound", "Grunt", "Lunger"],
		"elite_chance": 0.02
	},
	"guard": {
		"label": "Guard Pack",
		"types": ["Knight", "Grunt", "Archer", "Binder"],
		"elite_chance": 0.04
	},
	"elite": {
		"label": "Elite Pack",
		"types": ["Brute", "Knight", "Grunt", "Archer", "Spitter"],
		"elite_chance": 1.0
	},
	"boss_guard": {
		"label": "Boss Guard",
		"types": ["Knight", "Knight", "Binder", "Spitter"],
		"elite_chance": 0.18
	}
}

static func build_plan(rng: RandomNumberGenerator, map_item: Dictionary, layout: Dictionary) -> Dictionary:
	var plan: Dictionary = {
		"objective_total_packs": 0,
		"packs": [],
		"boss": {},
		"boss_guard_pack_id": ""
	}
	var map_tags: Array[String] = _map_tags(map_item)
	var pack_index: int = 0
	for section_value: Variant in Array(layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		var kind: String = str(section.get("kind", "pack"))
		if kind == "start" or kind == "boss":
			continue
		var pack_kind: String = _choose_pack_kind(rng, kind, map_tags, pack_index)
		var pack_id: String = "pack_" + str(pack_index)
		var pack: Dictionary = _make_pack(rng, map_item, section, pack_kind, pack_id, pack_index)
		plan["packs"].append(pack)
		plan["objective_total_packs"] = int(plan["objective_total_packs"]) + 1
		pack_index += 1

	var boss_pos: Vector2 = Vector2(layout.get("boss_pos", Vector2(640.0, 150.0)))
	var boss_pack_id: String = "boss_guard"
	var boss_guard: Dictionary = _make_pack(rng, map_item, {
		"id": "boss_guard",
		"kind": "elite",
		"pos": boss_pos + Vector2(0.0, 92.0),
		"radius": 86.0,
		"pack_count": 4
	}, "boss_guard", boss_pack_id, pack_index)
	plan["packs"].append(boss_guard)
	plan["objective_total_packs"] = int(plan["objective_total_packs"]) + 1
	plan["boss_guard_pack_id"] = boss_pack_id
	plan["boss"] = {
		"pos": boss_pos,
		"wake_radius": 540.0,
		"leash_center": boss_pos,
		"leash_radius": 360.0
	}
	return plan

static func _make_pack(rng: RandomNumberGenerator, map_item: Dictionary, section: Dictionary, pack_kind: String, pack_id: String, pack_index: int) -> Dictionary:
	var pack_data: Dictionary = PACKS.get(pack_kind, PACKS["pressure"])
	var types: Array = Array(pack_data.get("types", ["Grunt"])).duplicate(true)
	var base_count: int = max(2, int(section.get("pack_count", 3)))
	var pack_size: float = max(0.65, float(map_item.get("pack_size", 1.0)))
	var count: int = clampi(int(round(float(base_count) * pack_size)) + (1 if pack_kind == "elite" else 0), 2, 9)
	var center: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
	var radius: float = float(section.get("radius", 72.0))
	var enemies: Array[Dictionary] = []
	for i: int in range(count):
		var angle: float = (float(i) / float(max(1, count))) * TAU + rng.randf_range(-0.25, 0.25)
		var dist: float = rng.randf_range(8.0, max(12.0, radius - 24.0))
		var spawn_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
		var enemy_type: String = str(types[i % max(1, types.size())])
		var elite_chance: float = float(pack_data.get("elite_chance", 0.0))
		var is_elite: bool = rng.randf() < elite_chance and i == 0
		enemies.append({
			"enemy_type": enemy_type,
			"pos": spawn_pos,
			"is_elite": is_elite
		})
	return {
		"id": pack_id,
		"label": str(pack_data.get("label", pack_kind)),
		"kind": pack_kind,
		"section_id": str(section.get("id", "")),
		"center": center,
		"radius": radius,
		"wake_radius": max(175.0, radius + 138.0),
		"leash_radius": max(245.0, radius + 185.0),
		"index": pack_index,
		"enemies": enemies,
		"cleared": false
	}

static func _choose_pack_kind(rng: RandomNumberGenerator, section_kind: String, map_tags: Array[String], pack_index: int) -> String:
	if section_kind == "elite":
		return "elite"
	if section_kind == "side":
		return ["ranged", "caster", "hound"][rng.randi_range(0, 2)]
	if pack_index > 0 and pack_index % 4 == 3:
		return "elite"
	if map_tags.has("void"):
		return ["caster", "ranged", "guard"][rng.randi_range(0, 2)]
	if map_tags.has("iron"):
		return ["guard", "pressure", "elite"][rng.randi_range(0, 2)]
	if map_tags.has("storm"):
		return ["ranged", "hound", "caster"][rng.randi_range(0, 2)]
	return ["pressure", "ranged", "hound", "caster"][rng.randi_range(0, 3)]

static func _map_tags(map_item: Dictionary) -> Array[String]:
	var text: String = (str(map_item.get("id", "")) + " " + str(map_item.get("area_name", "")) + " " + str(map_item.get("name", ""))).to_lower()
	var tags: Array[String] = []
	for tag: String in ["void", "iron", "storm", "ash", "catacomb", "chapel"]:
		if text.contains(tag):
			tags.append(tag)
	return tags
