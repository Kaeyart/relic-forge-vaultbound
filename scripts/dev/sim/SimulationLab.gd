class_name RVSimulationLab
extends RefCounted

static var last_text_report: String = "No simulation has been run yet."
static var last_json_report: Dictionary = {}

static func run_quick_report(state: Object) -> String:
	return run_profile_progression(state, 100, 8)

static func run_deep_report(state: Object) -> String:
	return run_profile_progression(state, 1000, 12)

static func run_loot_audit_report(state: Object, drop_count: int = 5000) -> String:
	var report: Dictionary = _loot_audit(state, drop_count)
	last_json_report = report
	last_text_report = _format_loot_audit(report)
	return last_text_report

static func run_profile_progression(state: Object, run_count: int = 250, rooms_per_run: int = 8) -> String:
	var profiles: Array = RVSimProfileDB.profiles()
	var global: Dictionary = {
		"type": "profile_progression",
		"runs": run_count,
		"rooms_per_run": rooms_per_run,
		"profiles": [],
		"warnings": []
	}
	for profile in profiles:
		global["profiles"].append(_simulate_profile(state, profile, run_count, rooms_per_run))
	global["warnings"] = _global_warnings(global)
	last_json_report = global
	last_text_report = _format_progression(global)
	return last_text_report

static func save_last_report() -> String:
	DirAccess.make_dir_recursive_absolute("user://simulation_reports")
	var text_path: String = "user://simulation_reports/latest_simulation_report.txt"
	var json_path: String = "user://simulation_reports/latest_simulation_report.json"
	var file: FileAccess = FileAccess.open(text_path, FileAccess.WRITE)
	if file != null:
		file.store_string(last_text_report)
	var json_file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(last_json_report, "\t"))
	return "Saved reports:\n" + ProjectSettings.globalize_path(text_path) + "\n" + ProjectSettings.globalize_path(json_path)

static func _simulate_profile(state: Object, profile: Dictionary, run_count: int, rooms_per_run: int) -> Dictionary:
	var gear: Dictionary = {}
	var stash_kept: Array = []
	var metrics: Dictionary = {
		"profile_id": profile.get("id", "profile"),
		"profile_name": profile.get("name", "Profile"),
		"description": profile.get("description", ""),
		"drops_seen": 0,
		"useful_drops": 0,
		"upgrades": 0,
		"salvaged": 0,
		"kept_for_crafting": 0,
		"unique_hits": 0,
		"magic_seen": 0,
		"rare_seen": 0,
		"normal_seen": 0,
		"unique_seen": 0,
		"avg_forge_potential": 0.0,
		"total_forge_potential": 0.0,
		"build_tag_hits": {},
		"slot_upgrades": {},
		"warnings": [],
		"example_upgrades": [],
		"example_rejections": []
	}
	var total_drops: int = max(1, run_count * rooms_per_run)
	for n in range(total_drops):
		var depth: int = 1 + int(n % max(1, rooms_per_run)) + int(float(n) / float(max(1, rooms_per_run * 10)))
		var item: Dictionary = _generate_item(state, depth)
		_process_item_for_profile(item, profile, gear, stash_kept, metrics)
	metrics["avg_forge_potential"] = float(metrics["total_forge_potential"]) / max(1.0, float(metrics["drops_seen"]))
	metrics["upgrade_rate"] = float(metrics["upgrades"]) / max(1.0, float(metrics["drops_seen"]))
	metrics["useful_drop_rate"] = float(metrics["useful_drops"]) / max(1.0, float(metrics["drops_seen"]))
	metrics["salvage_rate"] = float(metrics["salvaged"]) / max(1.0, float(metrics["drops_seen"]))
	metrics["build_coherence"] = _build_coherence(metrics, profile)
	metrics["warnings"] = _profile_warnings(metrics, profile)
	return metrics

static func _process_item_for_profile(item: Dictionary, profile: Dictionary, gear: Dictionary, stash_kept: Array, metrics: Dictionary) -> void:
	metrics["drops_seen"] = int(metrics["drops_seen"]) + 1
	var rarity: String = str(item.get("rarity", "Normal"))
	match rarity:
		"Normal", "Common":
			metrics["normal_seen"] = int(metrics["normal_seen"]) + 1
		"Magic":
			metrics["magic_seen"] = int(metrics["magic_seen"]) + 1
		"Rare":
			metrics["rare_seen"] = int(metrics["rare_seen"]) + 1
		"Unique", "Legendary":
			metrics["unique_seen"] = int(metrics["unique_seen"]) + 1
	metrics["total_forge_potential"] = float(metrics["total_forge_potential"]) + float(item.get("forge_potential", item.get("forging_potential", 0.0)))
	var tags: Array = RVSimItemScorer.item_tags(item)
	var desired_tags: Array = profile.get("desired_tags", [])
	for tag in tags:
		if desired_tags.has(tag):
			var hits: Dictionary = metrics["build_tag_hits"]
			hits[tag] = int(hits.get(tag, 0)) + 1
	var slot: String = RVSimItemScorer.item_slot(item)
	var score: float = RVSimItemScorer.score_item_for_profile(item, profile)
	var equipped: Dictionary = gear.get(slot, {})
	var equipped_score: float = RVSimItemScorer.score_item_for_profile(equipped, profile)
	var useful: bool = score >= 6.0
	if useful:
		metrics["useful_drops"] = int(metrics["useful_drops"]) + 1
	if rarity == "Unique" or item.has("unique_effects") or item.has("build_flags"):
		metrics["unique_hits"] = int(metrics["unique_hits"]) + 1
	var upgrade_margin: float = 2.0 + equipped_score * 0.08
	if score > equipped_score + upgrade_margin:
		gear[slot] = item
		metrics["upgrades"] = int(metrics["upgrades"]) + 1
		var slot_upgrades: Dictionary = metrics["slot_upgrades"]
		slot_upgrades[slot] = int(slot_upgrades.get(slot, 0)) + 1
		_add_example(metrics["example_upgrades"], _item_short(item, score), 8)
	elif float(item.get("forge_potential", item.get("forging_potential", 0.0))) >= 18.0 and useful:
		stash_kept.append(item)
		metrics["kept_for_crafting"] = int(metrics["kept_for_crafting"]) + 1
	else:
		metrics["salvaged"] = int(metrics["salvaged"]) + 1
		if not useful:
			_add_example(metrics["example_rejections"], _item_short(item, score), 5)

static func _loot_audit(state: Object, drop_count: int) -> Dictionary:
	var report: Dictionary = {
		"type": "loot_audit",
		"drop_count": drop_count,
		"rarity_counts": {},
		"slot_counts": {},
		"tag_counts": {},
		"avg_forge_potential": 0.0,
		"total_forge_potential": 0.0,
		"empty_or_suspect_items": 0,
		"examples": [],
		"warnings": []
	}
	for i in range(drop_count):
		var depth: int = 1 + int(i % 25)
		var item: Dictionary = _generate_item(state, depth)
		var rarity: String = str(item.get("rarity", "Normal"))
		var slot: String = RVSimItemScorer.item_slot(item)
		_report_inc(report["rarity_counts"], rarity)
		_report_inc(report["slot_counts"], slot)
		for tag in RVSimItemScorer.item_tags(item):
			_report_inc(report["tag_counts"], str(tag))
		report["total_forge_potential"] = float(report["total_forge_potential"]) + float(item.get("forge_potential", item.get("forging_potential", 0.0)))
		if RVSimItemScorer.stat_dictionary(item).is_empty() and RVSimItemScorer.affix_list(item).is_empty() and rarity != "Unique":
			report["empty_or_suspect_items"] = int(report["empty_or_suspect_items"]) + 1
		if i < 20:
			report["examples"].append(_item_short(item, RVSimItemScorer.power_score(item)))
	report["avg_forge_potential"] = float(report["total_forge_potential"]) / max(1.0, float(drop_count))
	report["warnings"] = _loot_warnings(report)
	return report

static func _generate_item(state: Object, depth: int) -> Dictionary:
	var item: Dictionary = {}
	if state != null:
		item = RVItemDB.generate_drop(state, depth)
	else:
		var stub: Dictionary = {"name": "Sim Item", "slot": "weapon", "rarity": "Magic", "stats": {"Global Damage": 0.05}, "forge_potential": 12, "affixes": ["Global Damage"]}
		item = stub
	return item

static func _build_coherence(metrics: Dictionary, profile: Dictionary) -> float:
	var desired_tags: Array = profile.get("desired_tags", [])
	if desired_tags.size() == 0:
		return 0.0
	var tag_hits: Dictionary = metrics.get("build_tag_hits", {})
	var covered: int = 0
	var weighted_hits: int = 0
	for tag in desired_tags:
		var hits: int = int(tag_hits.get(tag, 0))
		if hits > 0:
			covered += 1
		weighted_hits += min(hits, 8)
	var coverage: float = float(covered) / float(desired_tags.size())
	var density: float = min(1.0, float(weighted_hits) / max(1.0, float(desired_tags.size() * 4)))
	return round((coverage * 0.55 + density * 0.45) * 100.0) / 100.0

static func _profile_warnings(metrics: Dictionary, profile: Dictionary) -> Array:
	var warnings: Array = []
	var upgrade_rate: float = float(metrics.get("upgrade_rate", 0.0))
	var useful_rate: float = float(metrics.get("useful_drop_rate", 0.0))
	var salvage_rate: float = float(metrics.get("salvage_rate", 0.0))
	var coherence: float = float(metrics.get("build_coherence", 0.0))
	if useful_rate < 0.18:
		warnings.append("Useful drops are too rare for this profile. Build-targeted affixes may be underrepresented.")
	if upgrade_rate < 0.06:
		warnings.append("Upgrade rate is low. Player may feel loot dries up too early.")
	if salvage_rate > 0.82:
		warnings.append("Salvage pressure is high. Too many drops are being rejected.")
	if coherence < 0.45:
		warnings.append("Build coherence is weak. Drops are not forming a clear identity for this profile.")
	if int(metrics.get("unique_hits", 0)) == 0 and str(profile.get("id", "")) == "unique_hunter":
		warnings.append("Unique hunter found no archetype hits. Dev unique rate may be too low for testing.")
	if float(metrics.get("avg_forge_potential", 0.0)) < 8.0:
		warnings.append("Average forge potential is low. Crafting journey may feel locked too quickly.")
	return warnings

static func _loot_warnings(report: Dictionary) -> Array:
	var warnings: Array = []
	var rarity_counts: Dictionary = report.get("rarity_counts", {})
	var total: float = float(report.get("drop_count", 1))
	var rare_rate: float = float(rarity_counts.get("Rare", 0)) / max(1.0, total)
	var unique_rate: float = (float(rarity_counts.get("Unique", 0)) + float(rarity_counts.get("Legendary", 0))) / max(1.0, total)
	if rare_rate < 0.20:
		warnings.append("Rare item rate is low for buildcraft testing.")
	if unique_rate < 0.005:
		warnings.append("Unique/archetype item rate is very low. Dev testing may need boosted unique fixtures.")
	if float(report.get("avg_forge_potential", 0.0)) < 8.0:
		warnings.append("Average forge potential is low.")
	if int(report.get("empty_or_suspect_items", 0)) > 0:
		warnings.append("Some generated items appear empty or malformed.")
	var tag_counts: Dictionary = report.get("tag_counts", {})
	for required_tag in ["Fire", "Cold", "Lightning", "Void", "Physical", "Trap"]:
		if int(tag_counts.get(required_tag, 0)) == 0:
			warnings.append("No " + required_tag + "-tagged item support appeared in audit.")
	return warnings

static func _global_warnings(report: Dictionary) -> Array:
	var warnings: Array = []
	for p in report.get("profiles", []):
		for w in p.get("warnings", []):
			warnings.append(str(p.get("profile_name", "Profile")) + ": " + str(w))
	return warnings

static func _format_progression(report: Dictionary) -> String:
	var out: Array[String] = []
	out.append("SIMULATION LAB — PROFILE PROGRESSION")
	out.append("Runs: %s | Rooms per run: %s" % [str(report.get("runs", 0)), str(report.get("rooms_per_run", 0))])
	out.append("")
	for profile in report.get("profiles", []):
		out.append("PROFILE: " + str(profile.get("profile_name", "Profile")))
		out.append("  " + str(profile.get("description", "")))
		out.append("  Drops Seen: %s" % str(profile.get("drops_seen", 0)))
		out.append("  Useful Drop Rate: %s%%" % _pct(profile.get("useful_drop_rate", 0.0)))
		out.append("  Upgrade Rate: %s%%" % _pct(profile.get("upgrade_rate", 0.0)))
		out.append("  Salvage Rate: %s%%" % _pct(profile.get("salvage_rate", 0.0)))
		out.append("  Build Coherence: %s%%" % _pct(profile.get("build_coherence", 0.0)))
		out.append("  Avg Forge Potential: %.2f" % float(profile.get("avg_forge_potential", 0.0)))
		out.append("  Unique / Archetype Hits: %s" % str(profile.get("unique_hits", 0)))
		out.append("  Slot Upgrades: " + _dict_line(profile.get("slot_upgrades", {})))
		out.append("  Build Tag Hits: " + _dict_line(profile.get("build_tag_hits", {})))
		if profile.get("example_upgrades", []).size() > 0:
			out.append("  Example Upgrades:")
			for example in profile.get("example_upgrades", []):
				out.append("    - " + str(example))
		if profile.get("warnings", []).size() > 0:
			out.append("  Warnings:")
			for warning in profile.get("warnings", []):
				out.append("    - " + str(warning))
		out.append("")
	out.append("GLOBAL WARNINGS")
	if report.get("warnings", []).size() == 0:
		out.append("  None.")
	else:
		for warning in report.get("warnings", []):
			out.append("  - " + str(warning))
	return "\n".join(out)

static func _format_loot_audit(report: Dictionary) -> String:
	var out: Array[String] = []
	out.append("SIMULATION LAB — LOOT AUDIT")
	out.append("Drops: " + str(report.get("drop_count", 0)))
	out.append("Average Forge Potential: %.2f" % float(report.get("avg_forge_potential", 0.0)))
	out.append("Suspect Items: " + str(report.get("empty_or_suspect_items", 0)))
	out.append("")
	out.append("RARITIES")
	out.append("  " + _dict_line(report.get("rarity_counts", {})))
	out.append("SLOTS")
	out.append("  " + _dict_line(report.get("slot_counts", {})))
	out.append("TAGS")
	out.append("  " + _dict_line(report.get("tag_counts", {})))
	out.append("")
	out.append("EXAMPLE ITEMS")
	for example in report.get("examples", []):
		out.append("  - " + str(example))
	out.append("")
	out.append("WARNINGS")
	if report.get("warnings", []).size() == 0:
		out.append("  None.")
	else:
		for warning in report.get("warnings", []):
			out.append("  - " + str(warning))
	return "\n".join(out)

static func _item_short(item: Dictionary, score: float) -> String:
	var name: String = str(item.get("name", "Item"))
	var rarity: String = str(item.get("rarity", "Normal"))
	var slot: String = RVSimItemScorer.item_slot(item)
	var potential: int = int(item.get("forge_potential", item.get("forging_potential", 0)))
	var tags: Array = RVSimItemScorer.item_tags(item)
	return "%s %s [%s] score %.1f FP %s tags %s" % [rarity, name, slot, score, str(potential), ",".join(tags)]

static func _report_inc(dict: Dictionary, key: String) -> void:
	dict[key] = int(dict.get(key, 0)) + 1

static func _add_example(list: Array, value: String, cap: int) -> void:
	if list.size() < cap:
		list.append(value)

static func _dict_line(dict: Dictionary) -> String:
	if dict.is_empty():
		return "none"
	var keys: Array = dict.keys()
	keys.sort()
	var parts: Array[String] = []
	for k in keys:
		parts.append(str(k) + "=" + str(dict[k]))
	return ", ".join(parts)

static func _pct(value: Variant) -> String:
	return "%.1f" % (float(value) * 100.0)
