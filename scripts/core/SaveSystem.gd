class_name RVSaveSystem
extends RefCounted

const SAVE_DIR: String = "user://relic_forge_vaultbound_characters"
const ROSTER_PATH: String = "user://relic_forge_vaultbound_roster.json"
const LEGACY_SAVE_PATH: String = "user://relic_forge_vaultbound_clean_save.json"
const MAX_SLOTS: int = 10

static var current_slot_index: int = 0

static func ensure_roster() -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var roster: Dictionary = _read_json(ROSTER_PATH)
	if roster.is_empty():
		roster = {"version": 1, "selected_slot": 0, "slots": []}
		for i: int in range(MAX_SLOTS):
			roster["slots"].append({"index": i, "slot_id": "slot_" + str(i), "exists": false, "name": "", "class_id": "", "ascendancy_id": "", "level": 1})
		_write_json(ROSTER_PATH, roster)
	current_slot_index = clamp(int(roster.get("selected_slot", 0)), 0, MAX_SLOTS - 1)
	return roster

static func load_into(state: RVGameState) -> void:
	var roster: Dictionary = ensure_roster()
	current_slot_index = clamp(int(roster.get("selected_slot", 0)), 0, MAX_SLOTS - 1)
	var path: String = _slot_path(current_slot_index)
	if not FileAccess.file_exists(path):
		state.init_new()
		state.character_slot_index = current_slot_index
		state.character_slot_id = "slot_" + str(current_slot_index)
		state.character_name = "Character " + str(current_slot_index + 1)
		state.character_class_id = "sorceress"
		state.character_class_locked = false
		if FileAccess.file_exists(LEGACY_SAVE_PATH) and current_slot_index == 0:
			var legacy: Dictionary = _read_json(LEGACY_SAVE_PATH)
			if not legacy.is_empty():
				state.apply_save_dict(legacy)
				state.character_slot_index = 0
				state.character_slot_id = "slot_0"
				state.character_name = str(legacy.get("character_name", "Character 1"))
		save(state)
		return
	var parsed: Dictionary = _read_json(path)
	if parsed.is_empty():
		state.init_new()
		state.character_slot_index = current_slot_index
		state.character_slot_id = "slot_" + str(current_slot_index)
		state.character_name = "Character " + str(current_slot_index + 1)
		save(state)
		return
	state.apply_save_dict(parsed)
	state.character_slot_index = current_slot_index
	state.character_slot_id = "slot_" + str(current_slot_index)
	state.ensure_defaults()

static func save(state: RVGameState) -> void:
	ensure_roster()
	current_slot_index = clamp(int(state.character_slot_index), 0, MAX_SLOTS - 1)
	state.character_slot_index = current_slot_index
	state.character_slot_id = "slot_" + str(current_slot_index)
	_write_json(_slot_path(current_slot_index), state.to_save_dict())
	_update_roster_summary(state)

static func select_slot_and_load(state: RVGameState, slot_index: int) -> void:
	var roster: Dictionary = ensure_roster()
	current_slot_index = clamp(slot_index, 0, MAX_SLOTS - 1)
	roster["selected_slot"] = current_slot_index
	_write_json(ROSTER_PATH, roster)
	load_into(state)

static func create_character_in_slot(state: RVGameState, slot_index: int, class_id: String, character_name: String = "") -> void:
	current_slot_index = clamp(slot_index, 0, MAX_SLOTS - 1)
	state.init_new()
	state.character_slot_index = current_slot_index
	state.character_slot_id = "slot_" + str(current_slot_index)
	state.character_name = character_name if character_name != "" else "Character " + str(current_slot_index + 1)
	state.character_class_id = class_id if RVClassDB.has_class(class_id) else "sorceress"
	state.character_class_locked = true
	state.ascendancy_id = ""
	state.ascendancy_allocated.clear()
	state.passive_atlas_allocated = ["center", RVClassDB.start_node(state.character_class_id)]
	state.passive_atlas_refund_stack.clear()
	state.ensure_defaults()
	state.recompute_stats()
	save(state)

static func roster_summary() -> String:
	var roster: Dictionary = ensure_roster()
	var text: String = "CHARACTER SLOTS\n"
	for entry_value: Variant in roster.get("slots", []):
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var index: int = int(entry.get("index", 0))
		var selected: String = "> " if index == current_slot_index else "  "
		if bool(entry.get("exists", false)):
			text += selected + str(index + 1) + ". " + str(entry.get("name", "Character")) + "  Lv " + str(entry.get("level", 1)) + "  " + RVClassDB.name_for(str(entry.get("class_id", "sorceress"))) + "  " + RVAscendancyDB.name_for(str(entry.get("ascendancy_id", ""))) + "\n"
		else:
			text += selected + str(index + 1) + ". Empty Slot\n"
	return text

static func _update_roster_summary(state: RVGameState) -> void:
	var roster: Dictionary = ensure_roster()
	var slots: Array = roster.get("slots", [])
	for i: int in range(slots.size()):
		var entry: Dictionary = slots[i]
		if int(entry.get("index", i)) == current_slot_index:
			entry["exists"] = true
			entry["name"] = state.character_name
			entry["class_id"] = state.character_class_id
			entry["ascendancy_id"] = state.ascendancy_id
			entry["level"] = state.level
			entry["slot_id"] = state.character_slot_id
			slots[i] = entry
	roster["selected_slot"] = current_slot_index
	roster["slots"] = slots
	_write_json(ROSTER_PATH, roster)

static func _slot_path(slot_index: int) -> String:
	return SAVE_DIR + "/character_" + str(clamp(slot_index, 0, MAX_SLOTS - 1)) + ".json"

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func _write_json(path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
