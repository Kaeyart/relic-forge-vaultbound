class_name RVLabScenarioDB
extends RefCounted

static func known_scenario_files() -> Array[String]:
	return [
		"res://data/dev/lab/scenarios/new_player_first_12_rooms.json",
		"res://data/dev/lab/scenarios/fireball_30_room_journey.json",
		"res://data/dev/lab/scenarios/void_trapper_30_room_journey.json",
		"res://data/dev/lab/scenarios/loot_audit_10000.json",
		"res://data/dev/lab/scenarios/unique_archetype_audit.json"
	]

static func load_scenarios() -> Array:
	var scenarios: Array = []
	for path in known_scenario_files():
		if FileAccess.file_exists(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file != null:
				var parsed = JSON.parse_string(file.get_as_text())
				file.close()
				if typeof(parsed) == TYPE_DICTIONARY:
					scenarios.append(parsed)
	if scenarios.is_empty():
		scenarios = default_scenarios()
	return scenarios

static func get_scenario(scenario_id: String) -> Dictionary:
	for scenario in load_scenarios():
		if str(scenario.get("id", "")) == scenario_id:
			return scenario
	var defaults: Array = default_scenarios()
	for scenario in defaults:
		if str(scenario.get("id", "")) == scenario_id:
			return scenario
	return defaults[0]

static func default_scenarios() -> Array:
	return [
		{
			"id": "new_player_first_12_rooms",
			"name": "New Player First 12 Rooms",
			"rooms": 12,
			"start_level": 1,
			"items_per_room_min": 1,
			"items_per_room_max": 3,
			"gem_reward_chance": 0.08,
			"material_reward_chance": 0.30,
			"tracked_questions": ["Does a beginner find obvious upgrades?", "Does loot stay readable?", "Does upgrade cadence dry up?"]
		},
		{
			"id": "fireball_30_room_journey",
			"name": "Fireball Ignite 30-Room Journey",
			"rooms": 30,
			"start_level": 1,
			"items_per_room_min": 1,
			"items_per_room_max": 3,
			"gem_reward_chance": 0.14,
			"material_reward_chance": 0.32,
			"tracked_questions": ["Does Fire identity form?", "Does mana comfort collapse?", "Are supports found early enough?"]
		},
		{
			"id": "void_trapper_30_room_journey",
			"name": "Void Trapper 30-Room Journey",
			"rooms": 30,
			"start_level": 1,
			"items_per_room_min": 1,
			"items_per_room_max": 3,
			"gem_reward_chance": 0.14,
			"material_reward_chance": 0.35,
			"tracked_questions": ["Do Void and Trap tags appear together?", "Does a delayed-control build form?", "Are proc chains available?"]
		},
		{
			"id": "loot_audit_10000",
			"name": "Loot Audit 10000 Drops",
			"rooms": 100,
			"start_level": 1,
			"items_per_room_min": 5,
			"items_per_room_max": 10,
			"gem_reward_chance": 0.05,
			"material_reward_chance": 0.0,
			"tracked_questions": ["Are rarity rates sane?", "Are affix tags coherent?", "How much loot is confusing?"]
		},
		{
			"id": "unique_archetype_audit",
			"name": "Unique Archetype Audit",
			"rooms": 120,
			"start_level": 20,
			"items_per_room_min": 2,
			"items_per_room_max": 4,
			"gem_reward_chance": 0.10,
			"material_reward_chance": 0.20,
			"tracked_questions": ["Do uniques create archetypes?", "Are conversions rejected by narrow profiles?", "Do build flags matter?"]
		}
	]
