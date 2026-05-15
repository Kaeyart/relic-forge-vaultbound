class_name RVLabReportWriter
extends RefCounted

static func make_text_report(report: Dictionary) -> String:
	var text: String = "RELIC FORGE BUILDCRAFT OBSERVATORY\n"
	text += "Version: " + str(report.get("version", "?")) + "\n"
	text += "Scenario: " + str(report.get("scenario_name", "Unknown")) + "\n"
	text += "Profile: " + str(report.get("profile_name", "Unknown")) + "\n"
	text += "Runs: " + str(report.get("run_count", 0)) + " | Seed: " + str(report.get("seed", 0)) + "\n\n"
	text += "AGGREGATE METRICS\n"
	text += "Drops: " + str(report.get("total_drops", 0)) + "\n"
	text += "Upgrade Rate: " + _pct(float(report.get("upgrade_rate", 0.0))) + "\n"
	text += "Useful Keep Rate: " + _pct(float(report.get("useful_keep_rate", 0.0))) + "\n"
	text += "Crafting Base Rate: " + _pct(float(report.get("crafting_base_rate", 0.0))) + "\n"
	text += "Archetype Hit Rate: " + _pct(float(report.get("archetype_hit_rate", 0.0))) + "\n"
	text += "Confusing Item Rate: " + _pct(float(report.get("confusing_rate", 0.0))) + "\n"
	text += "Salvage Rate: " + _pct(float(report.get("salvage_rate", 0.0))) + "\n"
	text += "Longest Dry Streak: " + str(report.get("longest_dry_streak", 0)) + "\n\n"
	text += "RARITY SPREAD\n" + _dict_lines(report.get("rarity_counts", {})) + "\n"
	text += "SLOT UPGRADES\n" + _dict_lines(report.get("slot_upgrades", {})) + "\n"
	text += "TOP BUILD TAG HITS\n" + _top_dict_lines(report.get("tag_hits", {}), 18) + "\n"
	text += "WARNINGS\n"
	var warnings: Array = report.get("warnings", [])
	if warnings.is_empty():
		text += "- none\n"
	else:
		for warning in warnings:
			text += "- [" + str(warning.get("severity", "Medium")) + "] " + str(warning.get("text", "")) + "\n"
	text += "\nRECOMMENDED TASKS\n"
	for recommendation in report.get("recommendations", []):
		text += "- " + str(recommendation) + "\n"
	text += "\nSAMPLE RUN TIMELINES\n"
	var runs: Array = report.get("runs", [])
	for run_report in runs.slice(0, min(3, runs.size())):
		text += "\nRUN " + str(run_report.get("run_index", 0)) + "\n"
		text += "Upgrades: " + str(run_report.get("upgrades", 0)) + " | Dry Streak: " + str(run_report.get("longest_dry_streak", 0)) + " | Confusing: " + str(run_report.get("confusing_items", 0)) + "\n"
		var coherence: Dictionary = run_report.get("build_coherence", {})
		text += "Build Coherence: " + _pct(float(coherence.get("coherence", 0.0))) + "\n"
		var combat: Dictionary = run_report.get("combat_proxy", {})
		text += "Combat Proxy: DPS " + str(combat.get("effective_dps", 0)) + ", AoE " + str(combat.get("aoe_coverage", 0)) + ", Mana " + str(combat.get("mana_comfort", 0)) + ", DeathRisk " + str(combat.get("death_risk_proxy", 0)) + "\n"
		for event in run_report.get("timeline", []).slice(0, 12):
			text += "  R" + str(event.get("room", 0)) + " " + str(event.get("kind", "Event")) + ": " + str(event.get("text", "")) + "\n"
	return text

static func save_report(report: Dictionary) -> Dictionary:
	var base_path: String = "user://buildcraft_observatory/latest"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_path))
	var text_path: String = base_path + "/summary.txt"
	var json_path: String = base_path + "/full_report.json"
	var text_file: FileAccess = FileAccess.open(text_path, FileAccess.WRITE)
	if text_file != null:
		text_file.store_string(make_text_report(report))
		text_file.close()
	var json_file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(report, "\t"))
		json_file.close()
	return {"text": ProjectSettings.globalize_path(text_path), "json": ProjectSettings.globalize_path(json_path)}

static func _pct(v: float) -> String:
	return str(snapped(v * 100.0, 0.01)) + "%"

static func _dict_lines(value) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "- none\n"
	var keys: Array = value.keys()
	keys.sort()
	var text: String = ""
	for key in keys:
		text += "- " + str(key) + ": " + str(value[key]) + "\n"
	if text == "": text = "- none\n"
	return text

static func _top_dict_lines(value, limit: int) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return "- none\n"
	var rows: Array = []
	for key in value.keys():
		rows.append({"key": str(key), "value": int(value[key])})
	rows.sort_custom(func(a, b): return int(a.get("value", 0)) > int(b.get("value", 0)))
	var text: String = ""
	for row in rows.slice(0, min(limit, rows.size())):
		text += "- " + str(row.get("key", "")) + ": " + str(row.get("value", 0)) + "\n"
	if text == "": text = "- none\n"
	return text
