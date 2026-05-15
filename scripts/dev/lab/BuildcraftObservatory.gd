class_name RVBuildcraftObservatory
extends RefCounted

static var latest_report: Dictionary = {}
static var latest_report_text: String = "No Buildcraft Observatory report yet."

static func run_scenario(game_state: RVGameState, profile_id: String, scenario_id: String, run_count: int, seed: int = 0) -> Dictionary:
	var profile: Dictionary = RVLabProfileDB.get_profile(profile_id)
	var scenario: Dictionary = RVLabScenarioDB.get_scenario(scenario_id)
	RVTelemetryLogger.log_event("LabScenarioStarted", {"profile": profile_id, "scenario": scenario_id, "runs": run_count, "seed": seed})
	latest_report = RVLabJourneySimulator.run_journey(game_state, profile, scenario, run_count, seed)
	latest_report_text = RVLabReportWriter.make_text_report(latest_report)
	RVTelemetryLogger.log_event("LabScenarioFinished", {"profile": profile_id, "scenario": scenario_id, "runs": run_count, "drops": latest_report.get("total_drops", 0), "upgrade_rate": latest_report.get("upgrade_rate", 0.0)})
	return latest_report

static func run_quick_matrix(game_state: RVGameState, run_count: int = 100) -> Dictionary:
	var profiles: Array = RVLabProfileDB.load_profiles()
	var scenario: Dictionary = RVLabScenarioDB.get_scenario("fireball_30_room_journey")
	var combined: Dictionary = {"tool": "Relic Forge Buildcraft Observatory", "version": "034A", "mode": "profile_matrix", "run_count_per_profile": run_count, "profiles": [], "warnings": [], "recommendations": []}
	for profile in profiles:
		var report: Dictionary = RVLabJourneySimulator.run_journey(game_state, profile, scenario, run_count, 0)
		combined["profiles"].append({
			"profile_id": report.get("profile_id", ""),
			"profile_name": report.get("profile_name", ""),
			"upgrade_rate": report.get("upgrade_rate", 0.0),
			"useful_keep_rate": report.get("useful_keep_rate", 0.0),
			"confusing_rate": report.get("confusing_rate", 0.0),
			"archetype_hit_rate": report.get("archetype_hit_rate", 0.0),
			"longest_dry_streak": report.get("longest_dry_streak", 0),
			"warnings": report.get("warnings", [])
		})
		combined["warnings"].append_array(report.get("warnings", []))
	latest_report = combined
	latest_report_text = make_matrix_text(combined)
	return combined

static func make_matrix_text(report: Dictionary) -> String:
	var text: String = "RELIC FORGE BUILDCRAFT OBSERVATORY — PROFILE MATRIX\n"
	text += "Runs per profile: " + str(report.get("run_count_per_profile", 0)) + "\n\n"
	for row in report.get("profiles", []):
		text += "PROFILE: " + str(row.get("profile_name", "Unknown")) + "\n"
		text += "  Upgrade Rate: " + str(snapped(float(row.get("upgrade_rate", 0.0)) * 100.0, 0.01)) + "%\n"
		text += "  Useful Keep Rate: " + str(snapped(float(row.get("useful_keep_rate", 0.0)) * 100.0, 0.01)) + "%\n"
		text += "  Confusing Rate: " + str(snapped(float(row.get("confusing_rate", 0.0)) * 100.0, 0.01)) + "%\n"
		text += "  Archetype Hit Rate: " + str(snapped(float(row.get("archetype_hit_rate", 0.0)) * 100.0, 0.01)) + "%\n"
		text += "  Longest Dry Streak: " + str(row.get("longest_dry_streak", 0)) + "\n"
		for warning in row.get("warnings", []).slice(0, 3):
			text += "  - [" + str(warning.get("severity", "Medium")) + "] " + str(warning.get("text", "")) + "\n"
		text += "\n"
	return text

static func save_latest() -> Dictionary:
	if latest_report.is_empty():
		return {"error": "No report to save"}
	return RVLabReportWriter.save_report(latest_report)

static func save_telemetry() -> String:
	return RVTelemetryLogger.save_latest()

static func clear_latest() -> void:
	latest_report.clear()
	latest_report_text = "No Buildcraft Observatory report yet."
