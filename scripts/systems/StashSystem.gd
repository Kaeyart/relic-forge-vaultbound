class_name RVStashSystem
extends RefCounted

const TAB_GENERAL: String = "general"
const TAB_MAPS: String = "maps"
const TAB_CURRENCY: String = "currency"
const TAB_MATERIALS: String = "materials"
const TAB_GEMS: String = "gems"
const TAB_UNIQUES: String = "uniques"
const TAB_DUMP: String = "dump"

static func tab_order() -> Array[String]:
	return [TAB_GENERAL, TAB_MAPS, TAB_CURRENCY, TAB_MATERIALS, TAB_GEMS, TAB_UNIQUES, TAB_DUMP]

static func default_unlocked_tabs() -> Array[String]:
	return [TAB_GENERAL, TAB_MAPS, TAB_CURRENCY, TAB_MATERIALS]

static func tab_display_name(tab_id: String) -> String:
	match tab_id:
		TAB_GENERAL: return "Items"
		TAB_MAPS: return "Maps"
		TAB_CURRENCY: return "Currency"
		TAB_MATERIALS: return "Materials"
		TAB_GEMS: return "Gems"
		TAB_UNIQUES: return "Uniques"
		TAB_DUMP: return "Dump"
		_: return tab_id.capitalize()

static func tab_cost(tab_id: String) -> int:
	match tab_id:
		TAB_GEMS: return 250
		TAB_UNIQUES: return 500
		TAB_DUMP: return 750
		_: return 0

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	var tabs: Dictionary = Dictionary(_state_get(state, "stash_tabs", {}))
	for tab_id: String in [TAB_CURRENCY, TAB_MATERIALS, TAB_GEMS, TAB_UNIQUES, TAB_DUMP]:
		if not tabs.has(tab_id) or typeof(tabs[tab_id]) != TYPE_ARRAY:
			tabs[tab_id] = []
	state.set("stash_tabs", tabs)

	var purchased: Dictionary = Dictionary(_state_get(state, "stash_purchased_tabs", {}))
	for tab_id: String in default_unlocked_tabs():
		purchased[tab_id] = true
	for tab_id: String in [TAB_GEMS, TAB_UNIQUES, TAB_DUMP]:
		if not purchased.has(tab_id):
			purchased[tab_id] = false
	state.set("stash_purchased_tabs", purchased)

	var active_tab: String = str(_state_get(state, "stash_tab_mode", TAB_GENERAL))
	if not tab_order().has(active_tab):
		active_tab = TAB_GENERAL
	state.set("stash_tab_mode", active_tab)
	state.set("stash_tab_cursor", max(0, int(_state_get(state, "stash_tab_cursor", 0))))
	if _state_get(state, "stash_affinities_enabled", null) == null:
		state.set("stash_affinities_enabled", true)
	if _state_get(state, "stash_economy_version", null) == null:
		state.set("stash_economy_version", 1)

static func is_tab_unlocked(state: Object, tab_id: String) -> bool:
	ensure_defaults(state)
	if tab_cost(tab_id) <= 0:
		return true
	return bool(Dictionary(_state_get(state, "stash_purchased_tabs", {})).get(tab_id, false))

static func purchase_tab(state: Object, tab_id: String) -> bool:
	ensure_defaults(state)
	if is_tab_unlocked(state, tab_id):
		_notice(state, tab_display_name(tab_id) + " tab is already unlocked")
		return false
	var cost: int = tab_cost(tab_id)
	var gold: int = int(_state_get(state, "gold", 0))
	if gold < cost:
		_notice(state, "Not enough gold. Need " + str(cost) + "g to unlock " + tab_display_name(tab_id) + " tab")
		return false
	state.set("gold", gold - cost)
	var purchased: Dictionary = Dictionary(_state_get(state, "stash_purchased_tabs", {}))
	purchased[tab_id] = true
	state.set("stash_purchased_tabs", purchased)
	state.set("stash_upgrade_cost_paid", int(_state_get(state, "stash_upgrade_cost_paid", 0)) + cost)
	_notice(state, "Unlocked stash tab: " + tab_display_name(tab_id))
	return true

static func toggle_affinities(state: Object) -> bool:
	var enabled: bool = not bool(_state_get(state, "stash_affinities_enabled", true))
	state.set("stash_affinities_enabled", enabled)
	_notice(state, "Stash affinities " + ("enabled" if enabled else "disabled"))
	return enabled

static func tab_items(state: Object, tab_id: String) -> Array:
	ensure_defaults(state)
	if tab_id == TAB_GENERAL:
		return Array(_state_get(state, "stash", []))
	if tab_id == TAB_MAPS:
		return Array(_state_get(state, "map_stash", []))
	var tabs: Dictionary = Dictionary(_state_get(state, "stash_tabs", {}))
	if not tabs.has(tab_id) or typeof(tabs[tab_id]) != TYPE_ARRAY:
		tabs[tab_id] = []
		state.set("stash_tabs", tabs)
	return Array(tabs[tab_id])

static func set_tab_items(state: Object, tab_id: String, items: Array) -> void:
	if tab_id == TAB_GENERAL:
		state.set("stash", items)
		return
	if tab_id == TAB_MAPS:
		state.set("map_stash", items)
		return
	var tabs: Dictionary = Dictionary(_state_get(state, "stash_tabs", {}))
	tabs[tab_id] = items
	state.set("stash_tabs", tabs)

static func tab_count(state: Object, tab_id: String) -> int:
	if tab_id == TAB_MAPS:
		return Array(_state_get(state, "map_stash", [])).size()
	return tab_items(state, tab_id).size()

static func affinity_tab_for_item(value: Variant) -> String:
	if RVMapItemSystem.is_map_item(value):
		return TAB_MAPS
	if typeof(value) != TYPE_DICTIONARY:
		return TAB_GENERAL
	var item: Dictionary = Dictionary(value)
	var item_type: String = str(item.get("item_type", item.get("type", ""))).to_lower()
	var category: String = str(item.get("category", "")).to_lower()
	var slot: String = str(item.get("slot", "")).to_lower()
	var base_type: String = str(item.get("base_type", "")).to_lower()
	var name: String = str(item.get("name", "")).to_lower()
	var rarity: String = str(item.get("rarity", ""))
	if item_type.contains("currency") or category.contains("currency") or base_type.contains("currency") or name.contains("orb") or name.contains("rune"):
		return TAB_CURRENCY
	if item_type.contains("material") or category.contains("material") or item_type.contains("craft") or category.contains("craft") or base_type.contains("material") or name.contains("shard") or name.contains("ember") or name.contains("essence"):
		return TAB_MATERIALS
	if item_type.contains("gem") or category.contains("gem") or ["active", "support", "spirit"].has(item_type) or ["active", "support", "spirit"].has(str(item.get("type", "")).to_lower()):
		return TAB_GEMS
	if rarity == "Unique" or category == "unique" or slot == "unique":
		return TAB_UNIQUES
	return TAB_GENERAL

static func deposit_all_backpack_by_affinity(state: Object) -> Dictionary:
	ensure_defaults(state)
	var result: Dictionary = {"moved": 0, "general": 0, "maps": 0, "currency": 0, "materials": 0, "gems": 0, "uniques": 0, "dump": 0, "blocked": 0}
	var backpack: Array = Array(_state_get(state, "backpack", []))
	var affinities_enabled: bool = bool(_state_get(state, "stash_affinities_enabled", true))
	for i: int in range(backpack.size() - 1, -1, -1):
		var value: Variant = backpack[i]
		var target_tab: String = affinity_tab_for_item(value) if affinities_enabled else TAB_GENERAL
		if not is_tab_unlocked(state, target_tab):
			target_tab = TAB_GENERAL
		if not is_tab_unlocked(state, target_tab):
			result["blocked"] = int(result.get("blocked", 0)) + 1
			continue
		var item: Dictionary = RVMapItemSystem.normalize_inventory_value(value, "stash_affinity", state)
		if target_tab == TAB_MAPS:
			item = RVMapItemSystem.normalize_map_item(item, "stash_affinity", state)
		append_to_tab(state, target_tab, item)
		backpack.remove_at(i)
		result["moved"] = int(result.get("moved", 0)) + 1
		result[target_tab] = int(result.get(target_tab, 0)) + 1
	state.set("backpack", backpack)
	if int(result.get("moved", 0)) > 0:
		_notice(state, stash_deposit_summary(result))
	else:
		_notice(state, "No backpack items deposited")
	return result

static func append_to_tab(state: Object, tab_id: String, item: Dictionary) -> void:
	var items: Array = tab_items(state, tab_id)
	items.append(item)
	set_tab_items(state, tab_id, items)

static func withdraw_from_tab(state: Object, tab_id: String, index: int) -> bool:
	ensure_defaults(state)
	var items: Array = tab_items(state, tab_id)
	if index < 0 or index >= items.size():
		return false
	var item: Dictionary = RVMapItemSystem.normalize_inventory_value(items[index], "withdraw", state)
	items.remove_at(index)
	set_tab_items(state, tab_id, items)
	var backpack: Array = Array(_state_get(state, "backpack", []))
	backpack.append(item)
	state.set("backpack", backpack)
	state.set("stash_tab_cursor", clampi(int(_state_get(state, "stash_tab_cursor", 0)), 0, max(0, items.size() - 1)))
	_notice(state, "Withdrew from " + tab_display_name(tab_id) + ": " + str(item.get("name", "Item")))
	return true

static func selected_detail_text(state: Object, tab_id: String, index: int) -> String:
	if not is_tab_unlocked(state, tab_id):
		return tab_display_name(tab_id).to_upper() + " TAB LOCKED\n\nCost: " + str(tab_cost(tab_id)) + " gold.\nBuy this tab to enable its affinity."
	if tab_id == TAB_MAPS:
		var map_items: Array = tab_items(state, TAB_MAPS)
		if index >= 0 and index < map_items.size():
			return RVMapItemSystem.map_plain_text(Dictionary(map_items[index]), state)
		return "MAP TAB\n\nNo map selected."
	var items: Array = tab_items(state, tab_id)
	if index >= 0 and index < items.size():
		var item: Dictionary = RVMapItemSystem.normalize_inventory_value(items[index], "detail", state)
		if RVMapItemSystem.is_map_item(item):
			return RVMapItemSystem.map_plain_text(item, state)
		var lines: Array[String] = []
		lines.append(tab_display_name(tab_id).to_upper() + " TAB")
		lines.append("")
		lines.append(str(item.get("name", "Item")))
		lines.append(str(item.get("rarity", "")) + " " + str(item.get("base_type", item.get("slot", "Item"))))
		if item.has("item_level"):
			lines.append("Item Level: " + str(item.get("item_level")))
		var stats: Dictionary = Dictionary(item.get("stats", item.get("total_stats", {})))
		if not stats.is_empty():
			lines.append("")
			lines.append("Stats:")
			for key: Variant in stats.keys():
				lines.append(" • " + str(key) + ": " + str(stats[key]))
		return "\n".join(lines)
	return tab_display_name(tab_id).to_upper() + " TAB\n\nNo item selected."

static func stash_deposit_summary(result: Dictionary) -> String:
	var parts: Array[String] = []
	for tab_id: String in tab_order():
		var count: int = int(result.get(tab_id, 0))
		if count > 0:
			parts.append(tab_display_name(tab_id) + " " + str(count))
	return "Deposited: " + ", ".join(parts)

static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	var value: Variant = state.get(key)
	return fallback if value == null else value

static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"):
		state.call("add_notice", text)
