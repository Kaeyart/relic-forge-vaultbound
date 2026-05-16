class_name RVMapEncounterDirector
extends RefCounted

# Patch 066: stronger map pacing and tactical pack recipes.
# CombatArena consumes this pure-data plan.

const PACKS: Dictionary = {
	"pressure": {"label": "Pressure Pack", "types": ["Grunt", "Grunt", "Grunt", "Lunger"], "elite_chance": 0.02, "intent": "basic melee pressure"},
	"ranged_denial": {"label": "Ranged Denial Pack", "types": ["Grunt", "Grunt", "Spitter", "Archer", "Archer"], "elite_chance": 0.03, "intent": "force target priority"},
	"caster_support": {"label": "Caster Support Pack", "types": ["Grunt", "Binder", "Binder", "Spitter"], "elite_chance": 0.05, "intent": "kill support enemies first"},
	"hound_rush": {"label": "Hound Rush", "types": ["Hound", "Hound", "Hound", "Lunger", "Grunt"], "elite_chance": 0.02, "intent": "punish stillness"},
	"guard_wall": {"label": "Guard Wall", "types": ["Knight", "Knight", "Grunt", "Binder", "Archer"], "elite_chance": 0.05, "intent": "break through front line"},
	"brute_denial": {"label": "Brute Denial", "types": ["Brute", "Grunt", "Spitter", "Spitter"], "elite_chance": 0.12, "intent": "slam plus ground denial"},
	"caller_priority": {"label": "Caller Priority", "types": ["Caller", "Grunt", "Grunt", "Hound"], "elite_chance": 0.06, "intent": "rush the summoner"},
	"elite": {"label": "Elite Pack", "types": ["Brute", "Knight", "Binder", "Spitter", "Lunger"], "elite_chance": 1.0, "intent": "danger spike"},
	"boss_guard": {"label": "Boss Guard", "types": ["Knight", "Knight", "Binder", "Spitter", "Caller"], "elite_chance": 0.22, "intent": "pre-boss check"}
}

static func build_plan(rng: RandomNumberGenerator, map_item: Dictionary, layout: Dictionary) -> Dictionary:
	var plan: Dictionary = {
		"objective_total_packs": 0,
		"packs": [],
		"boss": {},
		"boss_guard_pack_id": "",
		"pacing_label": "start → packs → side rooms → elite → boss"
	}
	var map_tags: Array[String] = _map_tags(map_item)
	var pack_index: int = 0
	for section_value: Variant in Array(layout.get("sections", [])):
		var section: Dictionary = Dictionary(section_value)
		var kind: String = str(section.get("kind", "pack"))
		if kind == "start" or kind == "boss" or kind == "empty":
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
		"pos": boss_pos + Vector2(0.0, 112.0),
		"radius": 92.0,
		"pack_count": 5
	}, "boss_guard", boss_pack_id, pack_index)
	plan["packs"].append(boss_guard)
	plan["objective_total_packs"] = int(plan["objective_total_packs"]) + 1
	plan["boss_guard_pack_id"] = boss_pack_id
	plan["boss"] = {
		"pos": boss_pos,
		"wake_radius": 560.0,
		"leash_center": boss_pos,
		"leash_radius": 380.0,
		"phase_count": 3,
		"boss_role": "map_boss"
	}
	return plan

static func _make_pack(rng: RandomNumberGenerator, map_item: Dictionary, section: Dictionary, pack_kind: String, pack_id: String, pack_index: int) -> Dictionary:
	var pack_data: Dictionary = PACKS.get(pack_kind, PACKS["pressure"])
	var types: Array = Array(pack_data.get("types", ["Grunt"])).duplicate(true)
	var base_count: int = max(2, int(section.get("pack_count", 3)))
	var pack_size: float = max(0.65, float(map_item.get("pack_size", 1.0)))
	var count: int = clampi(int(round(float(base_count) * pack_size)) + (1 if pack_kind == "elite" else 0), 2, 10)
	var center: Vector2 = Vector2(section.get("pos", Vector2.ZERO))
	var radius: float = float(section.get("radius", 72.0))
	var enemies: Array[Dictionary] = []
	for i: int in range(count):
		var angle: float = (float(i) / float(max(1, count))) * TAU + rng.randf_range(-0.22, 0.22)
		var dist: float = rng.randf_range(14.0, max(16.0, radius - 20.0))
		var spawn_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
		var enemy_type: String = str(types[i % max(1, types.size())])
		var elite_chance: float = float(pack_data.get("elite_chance", 0.0))
		var is_elite: bool = rng.randf() < elite_chance and i == 0
		enemies.append({
			"enemy_type": enemy_type,
			"pos": spawn_pos,
			"is_elite": is_elite,
			"encounter_role": _encounter_role_for(enemy_type, pack_kind),
			"encounter_pack_type": pack_kind
		})
	return {
		"id": pack_id,
		"label": str(pack_data.get("label", pack_kind)),
		"kind": pack_kind,
		"intent": str(pack_data.get("intent", "combat beat")),
		"section_id": str(section.get("id", "")),
		"center": center,
		"radius": radius,
		"wake_radius": max(185.0, radius + 148.0),
		"leash_radius": max(265.0, radius + 205.0),
		"index": pack_index,
		"enemies": enemies,
		"cleared": false
	}

static func _choose_pack_kind(rng: RandomNumberGenerator, section_kind: String, map_tags: Array[String], pack_index: int) -> String:
	if section_kind == "elite" or pack_index > 0 and pack_index % 4 == 3:
		return ["elite", "brute_denial", "caller_priority"][rng.randi_range(0, 2)]
	if section_kind == "side":
		return ["ranged_denial", "caster_support", "hound_rush"][rng.randi_range(0, 2)]
	if map_tags.has("void"):
		return ["caster_support", "guard_wall", "ranged_denial"][rng.randi_range(0, 2)]
	if map_tags.has("iron") or map_tags.has("catacomb"):
		return ["guard_wall", "brute_denial", "pressure"][rng.randi_range(0, 2)]
	if map_tags.has("storm"):
		return ["ranged_denial", "hound_rush", "caster_support"][rng.randi_range(0, 2)]
	return ["pressure", "ranged_denial", "hound_rush", "caster_support", "brute_denial"][rng.randi_range(0, 4)]

static func _encounter_role_for(enemy_type: String, pack_kind: String) -> String:
	match enemy_type:
		"Lunger", "Hound": return "flanker"
		"Spitter", "Archer": return "ranged_denial"
		"Binder": return "support_caster"
		"Brute": return "space_control"
		"Caller": return "priority_summoner"
		"Knight": return "frontline_guard"
	return "pressure"

static func _map_tags(map_item: Dictionary) -> Array[String]:
	var text: String = (str(map_item.get("id", "")) + " " + str(map_item.get("area_name", "")) + " " + str(map_item.get("name", ""))).to_lower()
	var tags: Array[String] = []
	for tag: String in ["void", "iron", "storm", "ash", "catacomb", "chapel", "foundry", "archive"]:
		if text.contains(tag):
			tags.append(tag)
	return tags
