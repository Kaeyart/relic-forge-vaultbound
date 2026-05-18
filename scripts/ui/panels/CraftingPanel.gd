class_name RVCraftingPanel
extends RVUIPanelBase

# Patch 084C: scene-authored crafting UI/UX pass.
# The scene owns layout. This script only binds state, invokes existing crafting
# verbs, and updates labels/button disabled states.

@onready var item_title_label: Label = get_node_or_null("%SelectedItemTitle") as Label
@onready var item_meta_label: Label = get_node_or_null("%SelectedItemMeta") as Label
@onready var item_detail_text: RichTextLabel = get_node_or_null("%SelectedItemDetails") as RichTextLabel
@onready var forge_bar: ProgressBar = get_node_or_null("%ForgePotentialBar") as ProgressBar
@onready var forge_label: Label = get_node_or_null("%ForgePotentialLabel") as Label
@onready var prefix_text: RichTextLabel = get_node_or_null("%PrefixList") as RichTextLabel
@onready var suffix_text: RichTextLabel = get_node_or_null("%SuffixList") as RichTextLabel
@onready var crafted_text: RichTextLabel = get_node_or_null("%CraftedList") as RichTextLabel
@onready var currency_text: RichTextLabel = get_node_or_null("%CurrencySummary") as RichTextLabel
@onready var result_label: Label = get_node_or_null("%ResultHintLabel") as Label
@onready var selected_index_label: Label = get_node_or_null("%SelectedIndexLabel") as Label

@onready var ash_temper_button: Button = get_node_or_null("%AshTemperButton") as Button
@onready var vault_alchemy_button: Button = get_node_or_null("%VaultAlchemyButton") as Button
@onready var regal_ember_button: Button = get_node_or_null("%RegalEmberButton") as Button
@onready var chaos_crucible_button: Button = get_node_or_null("%ChaosCrucibleButton") as Button
@onready var exalted_shard_button: Button = get_node_or_null("%ExaltedShardButton") as Button
@onready var scouring_ash_button: Button = get_node_or_null("%ScouringAshButton") as Button
@onready var essence_brand_button: Button = get_node_or_null("%EssenceBrandButton") as Button
@onready var forge_seal_button: Button = get_node_or_null("%ForgeSealButton") as Button
@onready var previous_item_button: Button = get_node_or_null("%PreviousItemButton") as Button
@onready var next_item_button: Button = get_node_or_null("%NextItemButton") as Button
@onready var close_button: Button = get_node_or_null("%CloseButton") as Button

var bound_state: RVGameState = null
var last_notice: String = "Select an equipment item, then apply a forge verb."

const VERB_META: Dictionary = {
	"ash_temper": {"key": KEY_T, "label": "Ash Temper", "hint": "Normal → Magic. Adds focused early affixes."},
	"vault_alchemy": {"key": KEY_A, "label": "Vault Alchemy", "hint": "Normal → Rare. Creates a full rare project."},
	"regal_ember": {"key": KEY_R, "label": "Regal Ember", "hint": "Magic → Rare. Keeps current affixes and adds one."},
	"chaos_crucible": {"key": KEY_C, "label": "Chaos Crucible", "hint": "Reroll rare affixes. High forge-potential cost."},
	"exalted_shard": {"key": KEY_E, "label": "Exalted Shard", "hint": "Add a random affix to a rare with an open slot."},
	"scouring_ash": {"key": KEY_S, "label": "Scouring Ash", "hint": "Remove explicit affixes; return to a normal base."},
	"essence_brand": {"key": KEY_B, "label": "Essence Brand", "hint": "Reroll as rare with a guaranteed theme."},
	"forge_seal": {"key": KEY_F, "label": "Forge Seal", "hint": "Add a controlled crafted modifier if possible."},
}

func _ready() -> void:
	_connect_button(ash_temper_button, "ash_temper")
	_connect_button(vault_alchemy_button, "vault_alchemy")
	_connect_button(regal_ember_button, "regal_ember")
	_connect_button(chaos_crucible_button, "chaos_crucible")
	_connect_button(exalted_shard_button, "exalted_shard")
	_connect_button(scouring_ash_button, "scouring_ash")
	_connect_button(essence_brand_button, "essence_brand")
	_connect_button(forge_seal_button, "forge_seal")
	if previous_item_button != null:
		previous_item_button.pressed.connect(_select_previous_item)
	if next_item_button != null:
		next_item_button.pressed.connect(_select_next_item)
	if close_button != null:
		close_button.pressed.connect(_close_panel)
	_set_button_focus_none()

func update_from_state(state: RVGameState) -> void:
	bound_state = state
	if state == null:
		visible = false
		return
	visible = str(state.panel_mode) == "crafting"
	if not visible:
		return
	var item: Dictionary = _selected_item(state)
	_update_selected_item(item, state)
	_update_affix_lists(item)
	_update_currency_summary(state)
	_update_buttons(item)
	if result_label != null:
		result_label.text = last_notice

func _connect_button(button: Button, verb_id: String) -> void:
	if button == null:
		return
	button.pressed.connect(func() -> void: _apply_verb(verb_id))
	var meta: Dictionary = Dictionary(VERB_META.get(verb_id, {}))
	button.tooltip_text = str(meta.get("hint", ""))

func _set_button_focus_none() -> void:
	for button in [ash_temper_button, vault_alchemy_button, regal_ember_button, chaos_crucible_button, exalted_shard_button, scouring_ash_button, essence_brand_button, forge_seal_button, previous_item_button, next_item_button, close_button]:
		if button is Button:
			(button as Button).focus_mode = Control.FOCUS_NONE

func _selected_item(state: RVGameState) -> Dictionary:
	if state == null or state.backpack.is_empty():
		return {}
	state.inventory_cursor = clampi(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	var raw: Variant = state.backpack[int(state.inventory_cursor)]
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return RVItemDB.normalize_item(Dictionary(raw))

func _commit_selected_item(item: Dictionary) -> void:
	if bound_state == null or bound_state.backpack.is_empty() or item.is_empty():
		return
	bound_state.inventory_cursor = clampi(int(bound_state.inventory_cursor), 0, max(0, bound_state.backpack.size() - 1))
	bound_state.backpack[int(bound_state.inventory_cursor)] = item
	if bound_state.has_method("recompute_stats"):
		bound_state.recompute_stats()

func _update_selected_item(item: Dictionary, state: RVGameState) -> void:
	if selected_index_label != null:
		selected_index_label.text = "Backpack " + str(int(state.inventory_cursor) + 1) + " / " + str(state.backpack.size())
	if item.is_empty():
		if item_title_label != null:
			item_title_label.text = "No crafting target"
		if item_meta_label != null:
			item_meta_label.text = "Select an equipment item in the backpack."
		if item_detail_text != null:
			item_detail_text.text = "Open Inventory, move the cursor to an equipment item, then return here."
		_set_forge_bar(0, 1)
		return
	if item_title_label != null:
		item_title_label.text = str(item.get("name", "Unnamed Item"))
	if item_meta_label != null:
		item_meta_label.text = _item_meta_line(item)
	if item_detail_text != null:
		item_detail_text.text = _item_detail_text(item)
	_set_forge_bar(int(item.get("forge_potential", 0)), max(1, int(item.get("max_forge_potential", item.get("forge_potential", 1)))))

func _item_meta_line(item: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append(str(item.get("rarity", "Normal")))
	parts.append(str(item.get("slot", item.get("item_type", "item"))).capitalize())
	parts.append("Item Lv. " + str(int(item.get("item_level", 1))))
	parts.append("Req. " + str(int(item.get("required_level", 1))))
	return " · ".join(parts)

func _item_detail_text(item: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("[b]Base[/b]: " + str(item.get("base_name", item.get("base_type", item.get("base_id", "Unknown")))))
	lines.append("[b]Forge Potential[/b]: " + str(int(item.get("forge_potential", 0))) + " / " + str(int(item.get("max_forge_potential", item.get("forge_potential", 0)))))
	var quality: int = int(item.get("quality", 0))
	if quality != 0:
		lines.append("[b]Quality[/b]: +" + str(quality) + "%")
	var tags: Array = Array(item.get("affix_tags", item.get("tags", [])))
	if not tags.is_empty():
		lines.append("[b]Tags[/b]: " + _join_array(tags))
	var stats: Dictionary = Dictionary(item.get("total_stats", item.get("stats", {})))
	if not stats.is_empty():
		lines.append("")
		lines.append("[b]Total Stats[/b]")
		for key_value: Variant in stats.keys():
			lines.append("• " + str(key_value) + ": " + _format_stat_value(stats[key_value]))
	return "\n".join(lines)

func _update_affix_lists(item: Dictionary) -> void:
	_set_affix_text(prefix_text, Array(item.get("prefixes", [])), "No prefixes.")
	_set_affix_text(suffix_text, Array(item.get("suffixes", [])), "No suffixes.")
	_set_affix_text(crafted_text, Array(item.get("crafted_mods", [])), "No crafted modifier.")

func _set_affix_text(target: RichTextLabel, affixes: Array, empty_text: String) -> void:
	if target == null:
		return
	if affixes.is_empty():
		target.text = "[color=#8f877a]" + empty_text + "[/color]"
		return
	var lines: Array[String] = []
	for affix_value: Variant in affixes:
		if typeof(affix_value) != TYPE_DICTIONARY:
			continue
		var affix: Dictionary = Dictionary(affix_value)
		var tier: String = "T" + str(affix.get("tier", "?"))
		var name: String = str(affix.get("name", "Affix"))
		var stat: String = _affix_stat_line(affix)
		var sealed: String = " [color=#d99745](sealed)[/color]" if bool(affix.get("sealed", false)) else ""
		lines.append("[b]" + tier + " " + name + "[/b]" + sealed + "\n" + stat)
	target.text = "\n".join(lines)

func _affix_stat_line(affix: Dictionary) -> String:
	var stats: Dictionary = Dictionary(affix.get("stats", {}))
	if stats.is_empty() and affix.has("stat"):
		return "• " + str(affix.get("stat")) + ": " + _format_stat_value(affix.get("value", 0))
	var parts: Array[String] = []
	for key_value: Variant in stats.keys():
		parts.append("• " + str(key_value) + ": " + _format_stat_value(stats[key_value]))
	return "\n".join(parts)

func _update_currency_summary(state: RVGameState) -> void:
	if currency_text == null:
		return
	var lines: Array[String] = []
	lines.append("[b]Currency / Materials[/b]")
	var materials: Dictionary = Dictionary(_state_get(state, "materials", {}))
	var crafting_currencies: Dictionary = Dictionary(_state_get(state, "crafting_currencies", {}))
	var seen: Dictionary = {}
	for key_value: Variant in materials.keys():
		seen[str(key_value)] = materials[key_value]
	for key2: Variant in crafting_currencies.keys():
		seen[str(key2)] = crafting_currencies[key2]
	if seen.is_empty():
		lines.append("[color=#8f877a]No crafting materials found yet.[/color]")
	else:
		var keys: Array = seen.keys()
		keys.sort()
		var shown: int = 0
		for k: Variant in keys:
			if shown >= 18:
				break
			lines.append("• " + _pretty_key(str(k)) + ": " + str(seen[k]))
			shown += 1
	currency_text.text = "\n".join(lines)

func _update_buttons(item: Dictionary) -> void:
	_set_button_state(ash_temper_button, "ash_temper", item)
	_set_button_state(vault_alchemy_button, "vault_alchemy", item)
	_set_button_state(regal_ember_button, "regal_ember", item)
	_set_button_state(chaos_crucible_button, "chaos_crucible", item)
	_set_button_state(exalted_shard_button, "exalted_shard", item)
	_set_button_state(scouring_ash_button, "scouring_ash", item)
	_set_button_state(essence_brand_button, "essence_brand", item)
	_set_button_state(forge_seal_button, "forge_seal", item)

func _set_button_state(button: Button, verb_id: String, item: Dictionary) -> void:
	if button == null:
		return
	var available: bool = _verb_looks_available(verb_id, item)
	button.disabled = not available
	var meta: Dictionary = Dictionary(VERB_META.get(verb_id, {}))
	button.tooltip_text = str(meta.get("hint", "")) if available else _blocked_reason(verb_id, item)

func _verb_looks_available(verb_id: String, item: Dictionary) -> bool:
	if item.is_empty():
		return false
	if not _is_equipment(item):
		return false
	var rarity: String = str(item.get("rarity", "Normal"))
	if rarity == "Unique":
		return false
	var fp: int = int(item.get("forge_potential", 0))
	match verb_id:
		"ash_temper": return rarity == "Normal" and fp > 0
		"vault_alchemy": return rarity == "Normal" and fp > 0
		"regal_ember": return rarity == "Magic" and fp > 0
		"chaos_crucible": return rarity == "Rare" and fp > 0
		"exalted_shard": return rarity == "Rare" and fp > 0 and _has_open_affix_slot(item)
		"scouring_ash": return rarity != "Normal" and _explicit_affix_count(item) > 0
		"essence_brand": return fp > 0
		"forge_seal": return fp > 0 and Array(item.get("crafted_mods", [])).size() < 1
	return fp > 0

func _blocked_reason(verb_id: String, item: Dictionary) -> String:
	if item.is_empty():
		return "No selected crafting target."
	if not _is_equipment(item):
		return "Only equipment can be crafted."
	if str(item.get("rarity", "Normal")) == "Unique":
		return "Uniques cannot be modified yet."
	if int(item.get("forge_potential", 0)) <= 0:
		return "Not enough forge potential."
	match verb_id:
		"ash_temper": return "Requires a normal item."
		"vault_alchemy": return "Requires a normal item."
		"regal_ember": return "Requires a magic item."
		"chaos_crucible": return "Requires a rare item."
		"exalted_shard": return "Requires a rare item with an open affix slot."
		"scouring_ash": return "Requires explicit affixes to remove."
		"forge_seal": return "Requires an open crafted-mod slot."
	return "Crafting verb is currently invalid."

func _apply_verb(verb_id: String) -> void:
	if bound_state == null:
		return
	var item_before: Dictionary = _selected_item(bound_state)
	if not _verb_looks_available(verb_id, item_before):
		last_notice = _blocked_reason(verb_id, item_before)
		update_from_state(bound_state)
		return
	var meta: Dictionary = Dictionary(VERB_META.get(verb_id, {}))
	var keycode: int = int(meta.get("key", 0))
	var old_notice: String = str(_state_get(bound_state, "notice_text", ""))
	var ok: bool = false
	if keycode != 0:
		ok = RVBuildcraftSystem.handle_crafting_key(bound_state, keycode)
	if ok:
		last_notice = "Applied " + str(meta.get("label", verb_id)) + "."
		if bound_state.has_method("recompute_stats"):
			bound_state.recompute_stats()
		RVSaveSystem.save(bound_state)
	else:
		var new_notice: String = str(_state_get(bound_state, "notice_text", ""))
		last_notice = new_notice if new_notice != "" and new_notice != old_notice else "Could not apply " + str(meta.get("label", verb_id)) + "."
	update_from_state(bound_state)

func _select_previous_item() -> void:
	if bound_state == null or bound_state.backpack.is_empty():
		return
	bound_state.inventory_cursor = wrapi(int(bound_state.inventory_cursor) - 1, 0, bound_state.backpack.size())
	last_notice = "Selected previous backpack item."
	update_from_state(bound_state)

func _select_next_item() -> void:
	if bound_state == null or bound_state.backpack.is_empty():
		return
	bound_state.inventory_cursor = wrapi(int(bound_state.inventory_cursor) + 1, 0, bound_state.backpack.size())
	last_notice = "Selected next backpack item."
	update_from_state(bound_state)

func _close_panel() -> void:
	if bound_state != null:
		bound_state.panel_mode = ""
		visible = false

func _is_equipment(item: Dictionary) -> bool:
	var item_type: String = str(item.get("item_type", item.get("type", "equipment"))).to_lower()
	if ["map", "skill_gem", "support_gem", "spirit_gem", "currency", "material", "flask_upgrade"].has(item_type):
		return false
	if item.has("slot") or item.has("base_id") or item.has("prefixes") or item.has("suffixes"):
		return true
	return item_type == "equipment" or item_type == "item"

func _explicit_affix_count(item: Dictionary) -> int:
	return Array(item.get("prefixes", [])).size() + Array(item.get("suffixes", [])).size() + Array(item.get("crafted_mods", [])).size()

func _has_open_affix_slot(item: Dictionary) -> bool:
	return Array(item.get("prefixes", [])).size() < 3 or Array(item.get("suffixes", [])).size() < 3

func _set_forge_bar(current: int, maximum: int) -> void:
	var safe_max: int = max(1, maximum)
	if forge_bar != null:
		forge_bar.max_value = safe_max
		forge_bar.value = clampi(current, 0, safe_max)
	if forge_label != null:
		forge_label.text = "Forge Potential: " + str(clampi(current, 0, safe_max)) + " / " + str(safe_max)

func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value

func _join_array(values: Array) -> String:
	var out: Array[String] = []
	for value: Variant in values:
		out.append(str(value))
	return ", ".join(out)

func _format_stat_value(value: Variant) -> String:
	if typeof(value) == TYPE_FLOAT:
		var f: float = float(value)
		if abs(f) < 1.0:
			return str(snappedf(f * 100.0, 0.1)) + "%"
		return str(snappedf(f, 0.01))
	return str(value)

func _pretty_key(key: String) -> String:
	return key.replace("_", " ").capitalize()
