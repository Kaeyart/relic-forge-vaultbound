class_name RVLabJourneySimulator
extends RefCounted

static func run_journey(game_state: RVGameState, profile: Dictionary, scenario: Dictionary, run_count: int = 100, seed: int = 0) -> Dictionary:
	var started_at: int = int(Time.get_unix_time_from_system())
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if seed == 0:
		seed = int(Time.get_unix_time_from_system())
	rng.seed = seed
	var runs: Array = []
	var aggregate: Dictionary = _empty_aggregate(profile, scenario, run_count, seed)
	for run_index in range(run_count):
		var lab_state: RVLabCharacterState = RVLabCharacterState.new()
		lab_state.setup(profile, scenario, run_index)
		_simulate_single_run(game_state, lab_state, rng, seed + run_index * 7919)
		var run_report: Dictionary = _summarize_run(lab_state)
		runs.append(run_report)
		_accumulate(aggregate, run_report)
	_finalize_aggregate(aggregate, run_count, started_at)
	aggregate["warnings"] = RVLabWarningEngine.evaluate_aggregate(aggregate)
	aggregate["runs"] = runs.slice(0, min(runs.size(), 25))
	aggregate["sample_size_note"] = "Only first 25 run details are embedded to keep report size sane. Aggregate metrics include all runs."
	return aggregate

static func _simulate_single_run(game_state: RVGameState, lab_state: RVLabCharacterState, rng: RandomNumberGenerator, run_seed: int) -> void:
	var rooms: int = int(lab_state.scenario.get("rooms", 12))
	var min_items: int = int(lab_state.scenario.get("items_per_room_min", 1))
	var max_items: int = int(lab_state.scenario.get("items_per_room_max", 3))
	var gem_chance: float = float(lab_state.scenario.get("gem_reward_chance", 0.10))
	var material_chance: float = float(lab_state.scenario.get("material_reward_chance", 0.30))
	lab_state.add_timeline("Start", "Started scenario: " + str(lab_state.scenario.get("name", "Scenario")) + " as " + str(lab_state.profile.get("name", "Profile")), {"seed": run_seed})
	for room in range(1, rooms + 1):
		lab_state.room_index = room
		if room > 1 and room % 4 == 0:
			lab_state.level += 1
		var drop_count: int = rng.randi_range(min_items, max_items)
		for drop_index in range(drop_count):
			var item: Dictionary = _generate_real_item(game_state, room, run_seed + room * 101 + drop_index)
			RVLabDecisionEngine.process_item_drop(lab_state, item)
		if rng.randf() < gem_chance:
			RVLabDecisionEngine.process_gem_reward(lab_state, _generate_virtual_gem(lab_state, rng))
		if rng.randf() < material_chance:
			lab_state.material_rewards += 1
			lab_state.add_decision({"room": room, "type": "material", "action": "keep", "amount": rng.randi_range(3, 12)})
		if room % 5 == 0 or room == rooms:
			var combat: Dictionary = RVLabCombatProxyEvaluator.evaluate(lab_state)
			lab_state.combat_snapshots.append({"room": room, "combat": combat})
			if float(combat.get("death_risk_proxy", 0.0)) > 0.75:
				lab_state.add_warning("Death risk proxy is high around room " + str(room) + ".", "Medium")
	lab_state.warnings.append_array(RVLabWarningEngine.evaluate_run(lab_state))

static func _generate_real_item(game_state: RVGameState, depth: int, forced_seed: int) -> Dictionary:
	if game_state != null and game_state.get("rng") != null:
		game_state.rng.seed = forced_seed
	return RVItemDB.generate_drop(game_state, depth)

static func _generate_virtual_gem(lab_state: RVLabCharacterState, rng: RandomNumberGenerator) -> Dictionary:
	var skills: Array = lab_state.profile.get("preferred_skills", {}).keys()
	var skill_name: String = "Fireball"
	if not skills.is_empty():
		skill_name = str(skills[rng.randi_range(0, skills.size() - 1)])
	return {"name": skill_name + " Support Option", "skill": skill_name, "level": max(1, lab_state.level), "tags": [skill_name, "Support"]}

static func _empty_aggregate(profile: Dictionary, scenario: Dictionary, run_count: int, seed: int) -> Dictionary:
	return {
		"tool": "Relic Forge Buildcraft Observatory",
		"version": "034A",
		"profile_id": str(profile.get("id", "unknown")),
		"profile_name": str(profile.get("name", "Unknown Profile")),
		"scenario_id": str(scenario.get("id", "unknown")),
		"scenario_name": str(scenario.get("name", "Unknown Scenario")),
		"run_count": run_count,
		"seed": seed,
		"total_drops": 0,
		"upgrades": 0,
		"useful_keeps": 0,
		"crafting_bases": 0,
		"archetype_hits": 0,
		"confusing_items": 0,
		"ignored_items": 0,
		"salvaged_items": 0,
		"gem_rewards": 0,
		"material_rewards": 0,
		"longest_dry_streak": 0,
		"rarity_counts": {},
		"tag_hits": {},
		"slot_upgrades": {},
		"recommendations": []
	}

static func _summarize_run(lab_state: RVLabCharacterState) -> Dictionary:
	var coherence: Dictionary = RVLabBuildCoherenceEvaluator.evaluate(lab_state)
	var combat: Dictionary = RVLabCombatProxyEvaluator.evaluate(lab_state)
	return {
		"run_index": lab_state.run_index,
		"total_drops": lab_state.total_drops,
		"upgrades": lab_state.upgrades,
		"useful_keeps": lab_state.useful_keeps,
		"crafting_bases": lab_state.crafting_keeps,
		"archetype_hits": lab_state.archetype_hits,
		"confusing_items": lab_state.confusing_items,
		"ignored_items": lab_state.ignored_items,
		"salvaged_items": lab_state.salvaged_items.size(),
		"gem_rewards": lab_state.gem_rewards,
		"material_rewards": lab_state.material_rewards,
		"longest_dry_streak": lab_state.longest_dry_streak,
		"rarity_counts": lab_state.rarity_counts.duplicate(true),
		"tag_hits": lab_state.tag_hits.duplicate(true),
		"slot_upgrades": lab_state.slot_upgrades.duplicate(true),
		"equipment": lab_state.equipment.duplicate(true),
		"build_coherence": coherence,
		"combat_proxy": combat,
		"timeline": lab_state.timeline.slice(0, min(lab_state.timeline.size(), 40)),
		"decisions": lab_state.decisions.slice(0, min(lab_state.decisions.size(), 80)),
		"warnings": lab_state.warnings
	}

static func _accumulate(aggregate: Dictionary, run_report: Dictionary) -> void:
	aggregate["total_drops"] = int(aggregate["total_drops"]) + int(run_report.get("total_drops", 0))
	aggregate["upgrades"] = int(aggregate["upgrades"]) + int(run_report.get("upgrades", 0))
	aggregate["useful_keeps"] = int(aggregate["useful_keeps"]) + int(run_report.get("useful_keeps", 0))
	aggregate["crafting_bases"] = int(aggregate["crafting_bases"]) + int(run_report.get("crafting_bases", 0))
	aggregate["archetype_hits"] = int(aggregate["archetype_hits"]) + int(run_report.get("archetype_hits", 0))
	aggregate["confusing_items"] = int(aggregate["confusing_items"]) + int(run_report.get("confusing_items", 0))
	aggregate["ignored_items"] = int(aggregate["ignored_items"]) + int(run_report.get("ignored_items", 0))
	aggregate["salvaged_items"] = int(aggregate["salvaged_items"]) + int(run_report.get("salvaged_items", 0))
	aggregate["gem_rewards"] = int(aggregate["gem_rewards"]) + int(run_report.get("gem_rewards", 0))
	aggregate["material_rewards"] = int(aggregate["material_rewards"]) + int(run_report.get("material_rewards", 0))
	aggregate["longest_dry_streak"] = max(int(aggregate["longest_dry_streak"]), int(run_report.get("longest_dry_streak", 0)))
	_merge_counts(aggregate["rarity_counts"], run_report.get("rarity_counts", {}))
	_merge_counts(aggregate["tag_hits"], run_report.get("tag_hits", {}))
	_merge_counts(aggregate["slot_upgrades"], run_report.get("slot_upgrades", {}))

static func _finalize_aggregate(aggregate: Dictionary, run_count: int, started_at: int) -> void:
	var drops: float = float(max(1, int(aggregate.get("total_drops", 0))))
	aggregate["upgrade_rate"] = snapped(float(aggregate.get("upgrades", 0)) / drops, 0.0001)
	aggregate["useful_keep_rate"] = snapped(float(aggregate.get("useful_keeps", 0)) / drops, 0.0001)
	aggregate["crafting_base_rate"] = snapped(float(aggregate.get("crafting_bases", 0)) / drops, 0.0001)
	aggregate["archetype_hit_rate"] = snapped(float(aggregate.get("archetype_hits", 0)) / drops, 0.0001)
	aggregate["confusing_rate"] = snapped(float(aggregate.get("confusing_items", 0)) / drops, 0.0001)
	aggregate["salvage_rate"] = snapped(float(aggregate.get("salvaged_items", 0)) / drops, 0.0001)
	aggregate["duration_seconds"] = int(Time.get_unix_time_from_system()) - started_at
	aggregate["recommendations"] = _recommendations(aggregate)

static func _merge_counts(target: Dictionary, source) -> void:
	if typeof(source) != TYPE_DICTIONARY:
		return
	for key in source.keys():
		target[key] = int(target.get(key, 0)) + int(source[key])

static func _recommendations(aggregate: Dictionary) -> Array:
	var rows: Array = []
	if float(aggregate.get("upgrade_rate", 0.0)) < 0.035:
		rows.append("Increase early meaningful upgrade cadence or lower virtual profile thresholds after inspecting item pools.")
	if float(aggregate.get("confusing_rate", 0.0)) > 0.20:
		rows.append("Increase affix tag cohesion on rare items; reduce unrelated mixed-element rolls on the same item.")
	if float(aggregate.get("archetype_hit_rate", 0.0)) < 0.02:
		rows.append("Add more build-defining unique/proc/conversion outcomes to the tested reward pool.")
	if int(aggregate.get("longest_dry_streak", 0)) >= 8:
		rows.append("Add pity/targeting mechanics or activity-specific rewards to reduce long dry streaks.")
	if rows.is_empty():
		rows.append("No critical issue detected by current lab thresholds. Inspect run timelines for qualitative problems.")
	return rows
