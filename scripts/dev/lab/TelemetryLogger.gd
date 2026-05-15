class_name RVTelemetryLogger
extends RefCounted

static var session_id: String = ""
static var events: Array = []
static var max_events: int = 5000

static func start_session(label: String = "manual") -> void:
	var stamp: int = int(Time.get_unix_time_from_system())
	session_id = label + "_" + str(stamp)
	events.clear()
	log_event("TelemetrySessionStarted", {"label": label, "session_id": session_id})

static func log_event(event_type: String, payload: Dictionary = {}) -> void:
	if session_id == "":
		session_id = "auto_" + str(int(Time.get_unix_time_from_system()))
	var record: Dictionary = {
		"t": Time.get_unix_time_from_system(),
		"type": event_type,
		"payload": payload.duplicate(true)
	}
	events.append(record)
	if events.size() > max_events:
		events.remove_at(0)

static func clear() -> void:
	events.clear()

static func event_count() -> int:
	return events.size()

static func summary_text() -> String:
	var counts: Dictionary = {}
	for event_record in events:
		var event_type: String = str(event_record.get("type", "Unknown"))
		counts[event_type] = int(counts.get(event_type, 0)) + 1
	var keys: Array = counts.keys()
	keys.sort()
	var text: String = "REAL GAMEPLAY TELEMETRY\n"
	text += "Session: " + session_id + "\n"
	text += "Events: " + str(events.size()) + "\n\n"
	for key in keys:
		text += "- " + str(key) + ": " + str(counts[key]) + "\n"
	return text

static func export_text() -> String:
	var text: String = summary_text() + "\nEVENT LOG\n"
	for event_record in events:
		text += str(event_record.get("t", 0.0)) + " | " + str(event_record.get("type", "Unknown")) + " | " + JSON.stringify(event_record.get("payload", {})) + "\n"
	return text

static func save_latest() -> String:
	var base_path: String = "user://buildcraft_observatory/latest"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_path))
	var text_path: String = base_path + "/telemetry.txt"
	var json_path: String = base_path + "/telemetry.json"
	var f: FileAccess = FileAccess.open(text_path, FileAccess.WRITE)
	if f != null:
		f.store_string(export_text())
		f.close()
	var j: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if j != null:
		j.store_string(JSON.stringify({"session_id": session_id, "events": events}, "\t"))
		j.close()
	return ProjectSettings.globalize_path(text_path)
