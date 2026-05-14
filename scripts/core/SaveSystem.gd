class_name RVSaveSystem
extends RefCounted

const SAVE_PATH = "user://relic_forge_clean_arch_save.json"

static func load_into(state: RVGameState) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save(state)
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		state.apply_save_dict(parsed)
	else:
		save(state)


static func save(state: RVGameState) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(state.to_save_dict(), "\t"))


static func save_path() -> String:
	return SAVE_PATH
