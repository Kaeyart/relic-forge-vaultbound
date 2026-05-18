class_name RVCraftingPanel
extends RVUIPanelBase

# Patch 084D: scene-authored crafting table UI.
# The scene owns layout and slots. This script only binds state, handles drag/drop
# target selection, and routes buttons into the existing crafting verb system.

const BackpackSlotButtonScript := preload("res://scripts/ui/controls/CraftingItemDragButton.gd")

const SLOT_COUNT: int = 16
const VERB_BUTTONS: Dictionary = {
	"AshTemperButton": KEY_T,
	"VaultAlchemyButton": KEY_A,
	"RegalEmberButton": KEY_R,
	"ChaosCrucibleButton": KEY_C,
	"ExaltedShardButton": KEY_E,
	"ScouringAshButton": KEY_S,
	"EssenceBrandButton": KEY_B,
	"ForgeSealButton": KEY_F,
}

const MATERIAL_KEYS: Array[String] = [
	"gold",
	"ash_temper",
	"vault_alchemy",
	"regal_ember",
	"chaos_crucible",
	"exalted_shard",
	"scouring_ash",
	"essence_brand",
	"forge_seal",
	"health_flask_shard",
	"mana_flask_shard",
	"iron_shards",
	"ember_shards",
	"bone_shards",
	"rune_dust",
	"relic_fragments",
]

var state_ref: Object = null
var crafting_target_index: int = -1
var backpack_page: int = 0
var backpack_buttons: Array[Button] = []
var material_labels: Array[Label] = []

@onready var target_drop_zone: Button = get_node_or_null("%TargetDropZone") as Button
@onready var target_title_label: Label = get_node_or_null("%TargetTitleLabel") as Label
@onready var target_meta_label: Label = get_node_or_null("%TargetMetaLabel") as Label
@onready var target_stats_label: RichTextLabel = get_node_or_null("%TargetStatsLabel") as RichTextLabel
@onready var target_affixes_label: RichTextLabel = get_node_or_null("%TargetAffixesLabel") as RichTextLabel
@onready var forge_bar: ProgressBar = get_node_or_null("%ForgePotentialBar") as ProgressBar
@onready var forge_label: Label = get_node_or_null("%ForgePotentialLabel") as Label
@onready var materials_label: RichTextLabel = get_node_or_null("%MaterialsLabel") as RichTextLabel
@onready var backpack_page_label: Label = get_node_or_null("%BackpackPageLabel") as Label
@onready var notice_label: Label = get_node_or_null("%CraftingNoticeLabel") as Label

func _ready() -> void:
	_collect_backpack_buttons()
	_wire_buttons()
	_set_notice("Drag an item from the backpack list into the forge slot, or click an item row.")

func update_from_state(state: Object) -> void:
	state_ref = state
	_validate_target()
	_refresh_backpack_list()
	_refresh_target()
	_refresh_materials()
	_refresh_verb_buttons()

func set_crafting_target_index(index: int) -> void:
	if state_ref == null:
		return
	var backpack: Array = Array(_state_get(state_ref, "backpack", []))
	if index < 0 or index >= backpack.size():
		crafting_target_index = -1
		_set_notice("No crafting target selected.")
	else:
		crafting_target_index = index
		_state_set(state_ref, "inventory_cursor", index)
		var item: Dictionary = _normalize_item(Dictionary(backpack[index]) if typeof(backpack[index]) == TYPE_DICTIONARY else {})
		_set_notice("Crafting target: " + str(item.get("name", "Item")))
	_refresh_backpack_list()
	_refresh_target()
	_refresh_verb_buttons()

func clear_crafting_target() -> void:
	crafting_target_index = -1
	_set_notice("Crafting target cleared.")
	_refresh_backpack_list()
	_refresh_target()
	_refresh_verb_buttons()

func _collect_backpack_buttons() -> void:
	backpack_buttons.clear()
	for i: int in range(SLOT_COUNT):
		var node_name: String = "BackpackSlot%02d" % (i + 1)
		var button: Button = get_node_or_null("%" + node_name) as Button
		if button != null:
			backpack_buttons.append(button)
			if button is Button:
				(button as Button).slot_index = i
			button.pressed.connect(_on_backpack_button_pressed.bind(i))

func _wire_buttons() -> void:
	if target_drop_zone != null:
		target_drop_zone.pressed.connect(clear_crafting_target)
	var prev_button: Button = get_node_or_null("%BackpackPrevButton") as Button
	var next_button: Button = get_node_or_null("%BackpackNextButton") as Button
	if prev_button != null:
		prev_button.pressed.connect(_change_backpack_page.bind(-1))
	if next_button != null:
		next_button.pressed.connect(_change_backpack_page.bind(1))
	for button_name: String in VERB_BUTTONS.keys():
		var button: Button = get_node_or_null("%" + button_name) as Button
		if button != null:
			button.pressed.connect(_perform_craft.bind(int(VERB_BUTTONS[button_name])))

func _on_backpack_button_pressed(local_index: int) -> void:
	set_crafting_target_index(backpack_page * SLOT_COUNT + local_index)

func _change_backpack_page(delta: int) -> void:
	var backpack: Array = Array(_state_get(state_ref, "backpack", [])) if state_ref != null else []
	var max_page: int = max(0, int(ceil(float(max(1, backpack.size())) / float(SLOT_COUNT))) - 1)
	backpack_page = clampi(backpack_page + delta, 0, max_page)
	_refresh_backpack_list()

func _validate_target() -> void:
	if state_ref == null:
		crafting_target_index = -1
		return
	var backpack: Array = Array(_state_get(state_ref, "backpack", []))
	if crafting_target_index < 0 or crafting_target_index >= backpack.size():
		crafting_target_index = clampi(int(_state_get(state_ref, "inventory_cursor", -1)), -1, backpack.size() - 1)
	if crafting_target_index >= 0 and crafting_target_index < backpack.size():
		var item: Dictionary = _normalize_item(Dictionary(backpack[crafting_target_index]) if typeof(backpack[crafting_target_index]) == TYPE_DICTIONARY else {})
		if not _is_craftable_item(item):
			# Keep selection visible, but crafting verbs will be disabled with the reason.
			pass

func _refresh_backpack_list() -> void:
	var backpack: Array = Array(_state_get(state_ref, "backpack", [])) if state_ref != null else []
	var max_page: int = max(0, int(ceil(float(max(1, backpack.size())) / float(SLOT_COUNT))) - 1)
	backpack_page = clampi(backpack_page, 0, max_page)
	if backpack_page_label != null:
		backpack_page_label.text = "Backpack Page " + str(backpack_page + 1) + " / " + str(max_page + 1)
	for i: int in range(backpack_buttons.size()):
		var button: Button = backpack_buttons[i]
		var index: int = backpack_page * SLOT_COUNT + i
		if button is Button:
			(button as Button).slot_index = index
		if index < backpack.size() and typeof(backpack[index]) == TYPE_DICTIONARY:
			var item: Dictionary = _normalize_item(Dictionary(backpack[index]))
			button.disabled = false
			button.text = _short_item_row(item, index)
			button.tooltip_text = _item_tooltip(item)
			button.modulate = Color(1.0, 0.90, 0.55, 1.0) if index == crafting_target_index else Color.WHITE
		else:
			button.disabled = true
			button.text = "— empty —"
			button.tooltip_text = ""
			button.modulate = Color(0.45, 0.45, 0.45, 0.65)

func _refresh_target() -> void:
	var item: Dictionary = _target_item()
	if item.is_empty():
		if target_title_label != null:
			target_title_label.text = "No Item Inserted"
		if target_meta_label != null:
			target_meta_label.text = "Drag a backpack item here."
		if target_stats_label != null:
			target_stats_label.text = ""
		if target_affixes_label != null:
			target_affixes_label.text = ""
		if forge_bar != null:
			forge_bar.value = 0
		if forge_label != null:
			forge_label.text = "Forge Potential: —"
		if target_drop_zone != null:
			target_drop_zone.text = "DROP ITEM HERE"
		return
	if target_title_label != null:
		target_title_label.text = str(item.get("name", "Item"))
	if target_meta_label != null:
		target_meta_label.text = _target_meta(item)
	if target_stats_label != null:
		target_stats_label.text = _stats_text(item)
	if target_affixes_label != null:
		target_affixes_label.text = _affix_text(item)
	var fp: int = _as_int(item.get("forge_potential", 0), 0)
	var max_fp: int = max(1, _as_int(item.get("max_forge_potential", max(1, fp)), max(1, fp)))
	if forge_bar != null:
		forge_bar.max_value = max_fp
		forge_bar.value = clampi(fp, 0, max_fp)
	if forge_label != null:
		forge_label.text = "Forge Potential: " + str(fp) + " / " + str(max_fp)
	if target_drop_zone != null:
		target_drop_zone.text = "TARGET: " + str(item.get("name", "Item"))

func _refresh_materials() -> void:
	if materials_label == null:
		return
	var lines: Array[String] = []
	lines.append("[b]Currency + Crafting Materials[/b]")
	lines.append("Gold: " + str(_as_int(_state_get(state_ref, "gold", 0), 0)))
	var materials: Dictionary = Dictionary(_state_get(state_ref, "materials", {})) if state_ref != null else {}
	for key: String in MATERIAL_KEYS:
		if key == "gold":
			continue
		var amount: int = _as_int(materials.get(key, _state_get(state_ref, key, 0)), 0)
		if amount > 0:
			lines.append(_display_key(key) + ": " + str(amount))
	# Fallback: show any extra material keys not in the curated list.
	for key_value: Variant in materials.keys():
		var key2: String = str(key_value)
		if MATERIAL_KEYS.has(key2):
			continue
		var amount2: int = _as_int(materials[key_value], 0)
		if amount2 > 0:
			lines.append(_display_key(key2) + ": " + str(amount2))
	if lines.size() <= 2:
		lines.append("No special crafting materials yet. Run maps and kill elites/bosses.")
	materials_label.text = "\n".join(lines)

func _refresh_verb_buttons() -> void:
	var item: Dictionary = _target_item()
	var reason: String = _craft_block_reason(item)
	for button_name: String in VERB_BUTTONS.keys():
		var button: Button = get_node_or_null("%" + button_name) as Button
		if button == null:
			continue
		button.disabled = reason != ""
		button.tooltip_text = reason if reason != "" else "Uses selected item in the forge slot. Cost is paid from your material drawer."
		button.modulate = Color(0.50, 0.50, 0.50, 0.75) if button.disabled else Color.WHITE

func _perform_craft(keycode: int) -> void:
	if state_ref == null:
		return
	var item: Dictionary = _target_item()
	var reason: String = _craft_block_reason(item)
	if reason != "":
		_set_notice(reason)
		return
	_state_set(state_ref, "inventory_cursor", crafting_target_index)
	var changed: bool = bool(RVBuildcraftSystem.handle_crafting_key(state_ref, keycode))
	if state_ref.has_method("recompute_stats"):
		state_ref.call("recompute_stats")
	if changed:
		_set_notice("Craft applied.")
		RVSaveSystem.save(state_ref)
	else:
		_set_notice("Craft failed or had no valid effect.")
	_refresh_backpack_list()
	_refresh_target()
	_refresh_materials()
	_refresh_verb_buttons()

func _target_item() -> Dictionary:
	if state_ref == null:
		return {}
	var backpack: Array = Array(_state_get(state_ref, "backpack", []))
	if crafting_target_index < 0 or crafting_target_index >= backpack.size():
		return {}
	if typeof(backpack[crafting_target_index]) != TYPE_DICTIONARY:
		return {}
	return _normalize_item(Dictionary(backpack[crafting_target_index]))

func _normalize_item(item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {}
	return RVItemDB.normalize_item(item)

func _is_craftable_item(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	var item_type: String = str(item.get("item_type", item.get("type", ""))).to_lower()
	var rarity: String = str(item.get("rarity", "Normal"))
	if rarity == "Unique":
		return false
	if ["map", "gem", "skill_gem", "support_gem", "spirit_gem", "currency", "material", "flask_upgrade"].has(item_type):
		return false
	if item.has("slot") and str(item.get("slot", "")) != "":
		return true
	if item.has("base_id") or item.has("prefixes") or item.has("suffixes"):
		return true
	return false

func _craft_block_reason(item: Dictionary) -> String:
	if item.is_empty():
		return "No target item. Drag an item into the forge slot."
	if not _is_craftable_item(item):
		return "This item cannot be crafted here. Use equipment bases, magic items, or rares."
	if _as_int(item.get("forge_potential", 0), 0) <= 0:
		return "No forge potential remaining."
	return ""

func _short_item_row(item: Dictionary, index: int) -> String:
	var rarity: String = str(item.get("rarity", ""))
	var ilvl: int = _as_int(item.get("item_level", item.get("level", 1)), 1)
	var fp: int = _as_int(item.get("forge_potential", 0), 0)
	return str(index + 1) + ". " + str(item.get("name", "Item")) + "  [" + rarity + " · i" + str(ilvl) + " · FP " + str(fp) + "]"

func _target_meta(item: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append(str(item.get("rarity", "Normal")))
	parts.append(str(item.get("slot", item.get("item_type", "equipment"))))
	parts.append("Item Level " + str(_as_int(item.get("item_level", item.get("level", 1)), 1)))
	parts.append("Required " + str(_as_int(item.get("required_level", 1), 1)))
	return " · ".join(parts)

func _stats_text(item: Dictionary) -> String:
	var stats: Dictionary = Dictionary(item.get("total_stats", item.get("stats", {})))
	if stats.is_empty():
		return "[b]Stats[/b]\n—"
	var lines: Array[String] = ["[b]Stats[/b]"]
	for key_value: Variant in stats.keys():
		lines.append(str(key_value) + ": " + _format_stat_value(stats[key_value]))
	return "\n".join(lines)

func _affix_text(item: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("[b]Prefixes[/b]")
	_append_affix_lines(lines, Array(item.get("prefixes", [])))
	lines.append("\n[b]Suffixes[/b]")
	_append_affix_lines(lines, Array(item.get("suffixes", [])))
	var crafted: Array = Array(item.get("crafted_mods", []))
	if crafted.size() > 0:
		lines.append("\n[b]Crafted[/b]")
		_append_affix_lines(lines, crafted)
	return "\n".join(lines)

func _append_affix_lines(lines: Array[String], affixes: Array) -> void:
	if affixes.is_empty():
		lines.append("— open —")
		return
	for affix_value: Variant in affixes:
		if typeof(affix_value) != TYPE_DICTIONARY:
			continue
		var affix: Dictionary = Dictionary(affix_value)
		var tier: String = "T" + str(affix.get("tier", "?"))
		var name: String = str(affix.get("name", "Affix"))
		var stat: String = str(affix.get("stat", ""))
		var value: String = _format_stat_value(affix.get("value", ""))
		lines.append(tier + " " + name + (" — " + stat + " " + value if stat != "" else ""))

func _item_tooltip(item: Dictionary) -> String:
	return str(item.get("name", "Item")) + "\n" + _target_meta(item) + "\nDrag into the forge slot or click to target."

func _set_notice(text: String) -> void:
	if notice_label != null:
		notice_label.text = text

func _display_key(key: String) -> String:
	var words: PackedStringArray = key.replace("_", " ").split(" ")
	var out: Array[String] = []
	for word: String in words:
		if word.length() > 0:
			out.append(word.substr(0, 1).to_upper() + word.substr(1))
	return " ".join(out)

func _format_stat_value(value: Variant) -> String:
	if typeof(value) == TYPE_FLOAT:
		var f: float = float(value)
		if abs(f) < 2.0:
			return str(snappedf(f * 100.0, 0.1)) + "%"
		return str(int(round(f)))
	return str(value)

func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value

func _state_set(state: Object, key: String, value: Variant) -> void:
	if state != null:
		state.set(key, value)

func _as_int(value: Variant, fallback: int = 0) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(round(value))
		TYPE_STRING:
			return int(value) if String(value).is_valid_int() else fallback
		_:
			return fallback
