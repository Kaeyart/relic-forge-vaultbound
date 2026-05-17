class_name RVCraftingCurrencySystem
extends RefCounted

const CURRENCY_DEFAULTS: Dictionary = {
	"ash_temper": 8,
	"vault_alchemy": 5,
	"regal_ember": 4,
	"chaos_crucible": 4,
	"exalted_shard": 2,
	"scouring_ash": 4,
	"essence_brand": 3,
	"forge_seal": 3,
}

const CURRENCY_NAMES: Dictionary = {
	"ash_temper": "Ash Temper",
	"vault_alchemy": "Vault Alchemy",
	"regal_ember": "Regal Ember",
	"chaos_crucible": "Chaos Crucible",
	"exalted_shard": "Exalted Shard",
	"scouring_ash": "Scouring Ash",
	"essence_brand": "Essence Brand",
	"forge_seal": "Forge Seal",
}

const COSTS: Dictionary = {
	"transmute": {"currency": "ash_temper", "amount": 1, "fp_min": 2, "fp_max": 4},
	"alchemy": {"currency": "vault_alchemy", "amount": 1, "fp_min": 6, "fp_max": 10},
	"regal": {"currency": "regal_ember", "amount": 1, "fp_min": 5, "fp_max": 8},
	"chaos": {"currency": "chaos_crucible", "amount": 1, "fp_min": 9, "fp_max": 15},
	"exalt": {"currency": "exalted_shard", "amount": 1, "fp_min": 8, "fp_max": 12},
	"scour": {"currency": "scouring_ash", "amount": 1, "fp_min": 1, "fp_max": 2},
	"essence": {"currency": "essence_brand", "amount": 1, "fp_min": 8, "fp_max": 13},
	"bench": {"currency": "forge_seal", "amount": 1, "fp_min": 4, "fp_max": 7},
}

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	var materials: Dictionary = Dictionary(_state_get(state, "materials", {}))
	for currency_id: String in ordered_currency_ids():
		if not materials.has(currency_id):
			materials[currency_id] = int(CURRENCY_DEFAULTS.get(currency_id, 0))
	state.set("materials", materials)

static func ordered_currency_ids() -> Array[String]:
	return ["ash_temper", "vault_alchemy", "regal_ember", "chaos_crucible", "exalted_shard", "scouring_ash", "essence_brand", "forge_seal"]

static func display_name(currency_id: String) -> String:
	return str(CURRENCY_NAMES.get(currency_id, currency_id.capitalize()))

static func short_name(currency_id: String) -> String:
	match currency_id:
		"ash_temper": return "Temper"
		"vault_alchemy": return "Alchemy"
		"regal_ember": return "Regal"
		"chaos_crucible": return "Chaos"
		"exalted_shard": return "Exalt"
		"scouring_ash": return "Scour"
		"essence_brand": return "Essence"
		"forge_seal": return "Bench"
		_: return currency_id

static func handle_crafting_key(state: Object, keycode: int) -> bool:
	if state == null:
		return false
	if str(_state_get(state, "panel_mode", "")) != "crafting":
		return false
	match keycode:
		KEY_T: return transmute_selected(state)
		KEY_A: return alchemy_selected(state)
		KEY_R: return regal_selected(state)
		KEY_C: return chaos_selected(state)
		KEY_E: return exalt_selected(state)
		KEY_S: return scour_selected(state)
		KEY_B: return essence_selected(state)
		KEY_F: return bench_craft_selected(state)
	return false

static func crafting_hint_text(state: Object) -> String:
	ensure_defaults(state)
	var lines: Array[String] = []
	lines.append("CRAFTING CURRENCY VERBS")
	lines.append("T Transmute  A Alchemy  R Regal  C Chaos")
	lines.append("E Exalt      S Scour    B Essence F Bench")
	lines.append("")
	lines.append(currency_summary(state))
	lines.append("")
	var item: Dictionary = selected_item(state)
	lines.append("No backpack item selected." if item.is_empty() else item_summary(item))
	return "\n".join(lines)

static func currency_summary(state: Object) -> String:
	var materials: Dictionary = Dictionary(_state_get(state, "materials", {}))
	var parts: Array[String] = []
	for currency_id: String in ordered_currency_ids():
		parts.append(short_name(currency_id) + ": " + str(int(materials.get(currency_id, 0))))
	return " | ".join(parts)

static func selected_item(state: Object) -> Dictionary:
	var backpack: Array = Array(_state_get(state, "backpack", []))
	if backpack.is_empty(): return {}
	var cursor: int = clampi(int(_state_get(state, "inventory_cursor", 0)), 0, backpack.size() - 1)
	var value: Variant = backpack[cursor]
	return Dictionary(value) if typeof(value) == TYPE_DICTIONARY else {}

static func write_selected_item(state: Object, item: Dictionary) -> void:
	var backpack: Array = Array(_state_get(state, "backpack", []))
	if backpack.is_empty(): return
	var cursor: int = clampi(int(_state_get(state, "inventory_cursor", 0)), 0, backpack.size() - 1)
	backpack[cursor] = item
	state.set("backpack", backpack)

static func transmute_selected(state: Object) -> bool: return _apply_to_selected(state, "transmute")
static func alchemy_selected(state: Object) -> bool: return _apply_to_selected(state, "alchemy")
static func regal_selected(state: Object) -> bool: return _apply_to_selected(state, "regal")
static func chaos_selected(state: Object) -> bool: return _apply_to_selected(state, "chaos")
static func exalt_selected(state: Object) -> bool: return _apply_to_selected(state, "exalt")
static func scour_selected(state: Object) -> bool: return _apply_to_selected(state, "scour")
static func essence_selected(state: Object) -> bool: return _apply_to_selected(state, "essence")
static func bench_craft_selected(state: Object) -> bool: return _apply_to_selected(state, "bench")

static func _apply_to_selected(state: Object, action: String) -> bool:
	ensure_defaults(state)
	var item: Dictionary = RVItemizationSystem.normalize_item(selected_item(state))
	if item.is_empty():
		_notice(state, "No backpack item selected for crafting")
		return false
	if not _is_craftable_equipment(item):
		_notice(state, "Only equipment can use crafting currency")
		return false
	var failure: String = _can_apply_action(item, action)
	if failure != "":
		_notice(state, failure)
		return false
	if not _pay_action_cost(state, item, action):
		return false
	match action:
		"transmute": _do_transmute(item)
		"alchemy": _do_alchemy(item)
		"regal": _do_regal(item)
		"chaos": _do_chaos(item)
		"exalt": _do_exalt(item)
		"scour": _do_scour(item)
		"essence": _do_essence(item)
		"bench": _do_bench(item)
	item = RVItemizationSystem.normalize_item(item)
	write_selected_item(state, item)
	_notice(state, _action_success_text(action, item))
	return true

static func _is_craftable_equipment(item: Dictionary) -> bool:
	if bool(item.get("map_item", false)): return false
	if str(item.get("rarity", "")) == "Unique": return false
	var item_type: String = str(item.get("item_type", "equipment")).to_lower()
	var category: String = str(item.get("category", "")).to_lower()
	var type_value: String = str(item.get("type", "")).to_lower()
	if item_type == "map" or category == "map": return false
	if item_type.contains("gem") or category.contains("gem") or ["active", "support", "spirit"].has(type_value): return false
	if item_type.contains("currency") or category.contains("currency") or item_type.contains("material"): return false
	return RVItemizationSystem.is_equipment_item(item)

static func _can_apply_action(item: Dictionary, action: String) -> String:
	var rarity: String = str(item.get("rarity", "Normal"))
	match action:
		"transmute":
			if rarity != "Normal": return "Ash Temper requires a Normal item"
		"alchemy":
			if rarity != "Normal": return "Vault Alchemy requires a Normal item"
		"regal":
			if rarity != "Magic": return "Regal Ember requires a Magic item"
		"chaos":
			if rarity != "Rare": return "Chaos Crucible requires a Rare item"
		"exalt":
			if rarity != "Rare": return "Exalted Shard requires a Rare item"
			if not _has_open_explicit_slot(item): return "This Rare item has no open affix slot"
		"bench":
			if Array(item.get("crafted_mods", [])).size() >= 1: return "Item already has a crafted modifier"
			if not _has_open_explicit_slot(item): return "No open prefix or suffix for a crafted modifier"
	return ""

static func _pay_action_cost(state: Object, item: Dictionary, action: String) -> bool:
	var cost: Dictionary = Dictionary(COSTS.get(action, {}))
	var currency_id: String = str(cost.get("currency", ""))
	var amount: int = int(cost.get("amount", 1))
	var materials: Dictionary = Dictionary(_state_get(state, "materials", {}))
	if int(materials.get(currency_id, 0)) < amount:
		_notice(state, "Need " + str(amount) + "x " + display_name(currency_id))
		return false
	var fp_cost: int = _roll_fp_cost(action)
	if int(item.get("forge_potential", 0)) < fp_cost:
		_notice(state, "Not enough Forge Potential. Need " + str(fp_cost))
		return false
	materials[currency_id] = int(materials.get(currency_id, 0)) - amount
	state.set("materials", materials)
	item["forge_potential"] = max(0, int(item.get("forge_potential", 0)) - fp_cost)
	item["last_craft_fp_cost"] = fp_cost
	return true

static func _do_transmute(item: Dictionary) -> void:
	_clear_explicit(item); item["rarity"] = "Magic"; _add_random_affix(item)
	if randf() < 0.35: _add_random_affix(item)
static func _do_alchemy(item: Dictionary) -> void:
	_clear_explicit(item); item["rarity"] = "Rare"
	for i: int in range(randi_range(4, 6)): _add_random_affix(item)
static func _do_regal(item: Dictionary) -> void:
	item["rarity"] = "Rare"; _add_random_affix(item)
static func _do_chaos(item: Dictionary) -> void:
	_clear_explicit(item); item["rarity"] = "Rare"
	for i: int in range(randi_range(4, 6)): _add_random_affix(item)
static func _do_exalt(item: Dictionary) -> void: _add_random_affix(item)
static func _do_scour(item: Dictionary) -> void: _clear_explicit(item); item["rarity"] = "Normal"
static func _do_essence(item: Dictionary) -> void:
	_clear_explicit(item); item["rarity"] = "Rare"; _add_affix(item, _make_affix("prefix", "Essence Branded", "Elemental Damage", 0.16, 3, ["elemental", "essence", "damage"]))
	for i: int in range(randi_range(3, 5)): _add_random_affix(item)
static func _do_bench(item: Dictionary) -> void:
	var affix_type: String = "prefix" if _open_prefix_count(item) > 0 else "suffix"
	var crafted: Array = Array(item.get("crafted_mods", []))
	crafted.append(_make_affix(affix_type, "Bench Forged", "Maximum Life" if affix_type == "prefix" else "Resistance", 18.0 if affix_type == "prefix" else 0.12, 4, ["crafted", "bench"]))
	item["crafted_mods"] = crafted
	if str(item.get("rarity", "Normal")) == "Normal": item["rarity"] = "Magic"

static func _add_random_affix(item: Dictionary) -> bool:
	var affix_type: String = _choose_affix_type(item)
	if affix_type == "": return false
	var tags: Array = Array(item.get("affix_tags", item.get("tags", [])))
	var slot: String = str(item.get("slot", ""))
	var stat: String = "Maximum Life"
	var name: String = "Vital"
	var value: float = float(randi_range(10, 35))
	var affix_tags: Array = ["life"]
	if affix_type == "suffix":
		var suffix_roll: int = randi_range(0, 3)
		match suffix_roll:
			0: stat = "Resistance"; name = "Warded"; value = randf_range(0.08, 0.22); affix_tags = ["defense", "resistance"]
			1: stat = "Movement Speed"; name = "Fleet"; value = randf_range(0.03, 0.08); affix_tags = ["speed", "movement"]
			2: stat = "Critical Chance"; name = "Precise"; value = randf_range(0.04, 0.10); affix_tags = ["crit"]
			_: stat = "Maximum Mana"; name = "Lucid"; value = float(randi_range(8, 28)); affix_tags = ["mana"]
	else:
		if slot == "weapon" or tags.has("weapon"):
			var weapon_roll: int = randi_range(0, 3)
			match weapon_roll:
				0: stat = "Attack Damage"; name = "Jagged"; value = randf_range(0.08, 0.24); affix_tags = ["attack", "damage"]
				1: stat = "Spell Damage"; name = "Runic"; value = randf_range(0.08, 0.24); affix_tags = ["spell", "damage"]
				2: stat = "Fire Damage"; name = "Scorching"; value = randf_range(0.08, 0.24); affix_tags = ["fire", "damage"]
				_: stat = "Bleed Chance"; name = "Serrated"; value = randf_range(0.06, 0.18); affix_tags = ["bleed", "ailment"]
		elif slot == "chest" or slot == "head" or slot == "gloves" or slot == "boots" or tags.has("armor"):
			var armor_roll: int = randi_range(0, 2)
			match armor_roll:
				0: stat = "Armor"; name = "Plated"; value = float(randi_range(12, 46)); affix_tags = ["armor", "defense"]
				1: stat = "Maximum Life"; name = "Vital"; value = float(randi_range(12, 42)); affix_tags = ["life", "defense"]
				_: stat = "Dodge"; name = "Evasive"; value = randf_range(0.04, 0.12); affix_tags = ["dodge", "defense"]
	return _add_affix(item, _make_affix(affix_type, name, stat, value, _tier_for_item(item), affix_tags))

static func _choose_affix_type(item: Dictionary) -> String:
	var can_prefix: bool = _open_prefix_count(item) > 0
	var can_suffix: bool = _open_suffix_count(item) > 0
	if can_prefix and can_suffix: return "prefix" if randf() < 0.52 else "suffix"
	if can_prefix: return "prefix"
	if can_suffix: return "suffix"
	return ""

static func _add_affix(item: Dictionary, affix: Dictionary) -> bool:
	var affix_type: String = str(affix.get("affix_type", "prefix"))
	if affix_type == "suffix":
		if _open_suffix_count(item) <= 0: return false
		var suffixes: Array = Array(item.get("suffixes", [])); suffixes.append(affix); item["suffixes"] = suffixes; return true
	if _open_prefix_count(item) <= 0: return false
	var prefixes: Array = Array(item.get("prefixes", [])); prefixes.append(affix); item["prefixes"] = prefixes; return true

static func _make_affix(affix_type: String, name: String, stat: String, value: float, tier: int, tags: Array) -> Dictionary:
	return {"id": name.to_lower().replace(" ", "_"), "name": name, "affix_type": affix_type, "tier": tier, "stat": stat, "value": value, "stats": {stat: value}, "tags": tags.duplicate(true)}
static func _clear_explicit(item: Dictionary) -> void: item["prefixes"] = []; item["suffixes"] = []; item["crafted_mods"] = []
static func _has_open_explicit_slot(item: Dictionary) -> bool: return _open_prefix_count(item) > 0 or _open_suffix_count(item) > 0
static func _open_prefix_count(item: Dictionary) -> int:
	var rarity: String = str(item.get("rarity", "Normal")); var max_count: int = 1 if rarity == "Magic" else (3 if rarity == "Rare" else 0)
	return max(0, max_count - Array(item.get("prefixes", [])).size() - _crafted_count_for(item, "prefix"))
static func _open_suffix_count(item: Dictionary) -> int:
	var rarity: String = str(item.get("rarity", "Normal")); var max_count: int = 1 if rarity == "Magic" else (3 if rarity == "Rare" else 0)
	return max(0, max_count - Array(item.get("suffixes", [])).size() - _crafted_count_for(item, "suffix"))
static func _crafted_count_for(item: Dictionary, affix_type: String) -> int:
	var count: int = 0
	for value: Variant in Array(item.get("crafted_mods", [])):
		if typeof(value) == TYPE_DICTIONARY and str(Dictionary(value).get("affix_type", "prefix")) == affix_type: count += 1
	return count
static func _tier_for_item(item: Dictionary) -> int:
	var ilvl: int = int(item.get("item_level", 1))
	if ilvl >= 70: return randi_range(1, 3)
	if ilvl >= 50: return randi_range(2, 4)
	if ilvl >= 30: return randi_range(3, 5)
	return randi_range(4, 5)
static func _roll_fp_cost(action: String) -> int:
	var cost: Dictionary = Dictionary(COSTS.get(action, {})); return randi_range(int(cost.get("fp_min", 1)), int(cost.get("fp_max", 3)))
static func _action_success_text(action: String, item: Dictionary) -> String:
	var verb: String = action.capitalize()
	match action:
		"transmute": verb = "Ash Tempered"
		"alchemy": verb = "Vault Alchemized"
		"regal": verb = "Regal Ember Applied"
		"chaos": verb = "Chaos Crucible Applied"
		"exalt": verb = "Exalted Shard Applied"
		"scour": verb = "Scoured"
		"essence": verb = "Essence Branded"
		"bench": verb = "Bench Crafted"
	return verb + ": " + str(item.get("name", "Item")) + " (FP " + str(item.get("forge_potential", 0)) + ")"
static func item_summary(item: Dictionary) -> String:
	var n: Dictionary = RVItemizationSystem.normalize_item(item); var lines: Array[String] = []
	lines.append(str(n.get("name", "Item")) + " · " + str(n.get("rarity", "Normal")))
	lines.append("Item Level: " + str(n.get("item_level", 1)) + " · Forge Potential: " + str(n.get("forge_potential", 0)) + "/" + str(n.get("max_forge_potential", 0)))
	lines.append("Prefixes: " + str(Array(n.get("prefixes", [])).size()) + "/3 · Suffixes: " + str(Array(n.get("suffixes", [])).size()) + "/3")
	for value: Variant in Array(n.get("prefixes", [])) + Array(n.get("suffixes", [])) + Array(n.get("crafted_mods", [])):
		if typeof(value) == TYPE_DICTIONARY:
			var affix: Dictionary = Dictionary(value); lines.append("  T" + str(affix.get("tier", "?")) + " " + str(affix.get("name", "Affix")))
	return "\n".join(lines)
static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null: return fallback
	var value: Variant = state.get(key); return fallback if value == null else value
static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"): state.call("add_notice", text)
