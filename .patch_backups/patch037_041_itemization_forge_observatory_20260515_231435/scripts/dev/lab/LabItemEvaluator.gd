class_name RVLabItemEvaluator
extends RefCounted

static func normalize_slot(slot_name: String) -> String:
	var s: String = slot_name.to_lower()
	if s == "mainhand" or s == "main_hand": return "weapon"
	if s == "off_hand": return "offhand"
	if s == "helmet": return "head"
	if s == "body" or s == "armor" or s == "body_armor": return "chest"
	if s == "ring1" or s == "ring2" or s == "left_ring" or s == "right_ring": return "ring"
	return s

static func item_slot(item: Dictionary) -> String:
	return normalize_slot(str(item.get("slot", "relic")))

static func item_name(item: Dictionary) -> String:
	return str(item.get("name", "Unnamed Item"))

static func item_rarity(item: Dictionary) -> String:
	return str(item.get("rarity", "Normal"))

static func item_forge_potential(item: Dictionary) -> float:
	return float(item.get("forge_potential", item.get("forge_potential_current", 0.0)))

static func item_tags(item: Dictionary) -> Array:
	var tags: Array = []
	_collect_array(tags, item.get("tags", []))
	_collect_array(tags, item.get("build_tags", []))
	_collect_array(tags, item.get("build_flags", []))
	_collect_array(tags, item.get("flags", []))
	_collect_array(tags, item.get("unique_flags", []))
	_collect_array(tags, item.get("affixes", []))
	_collect_affix_tags(tags, item.get("prefixes", []))
	_collect_affix_tags(tags, item.get("suffixes", []))
	var stats: Dictionary = item.get("stats", {})
	for stat_key in stats.keys():
		_add_stat_tags(tags, str(stat_key))
	var rarity: String = item_rarity(item)
	if rarity == "Unique" or rarity == "Legendary":
		_add_unique(tags, "Unique")
	if item.has("unique_effects") or item.has("unique_effect"):
		_add_unique(tags, "Unique")
		_add_unique(tags, "Proc")
	if item_forge_potential(item) >= 22.0:
		_add_unique(tags, "Forge Potential")
	return tags

static func _collect_array(tags: Array, value) -> void:
	if typeof(value) == TYPE_ARRAY:
		for v in value:
			_add_unique(tags, str(v))
	elif typeof(value) == TYPE_STRING:
		_add_unique(tags, str(value))

static func _collect_affix_tags(tags: Array, value) -> void:
	if typeof(value) != TYPE_ARRAY:
		return
	for affix in value:
		if typeof(affix) == TYPE_DICTIONARY:
			_collect_array(tags, affix.get("tags", []))
			_add_stat_tags(tags, str(affix.get("stat", affix.get("name", ""))))
		else:
			_add_stat_tags(tags, str(affix))

static func _add_stat_tags(tags: Array, stat_name: String) -> void:
	var s: String = stat_name.to_lower()
	if s.find("fire") >= 0: _add_unique(tags, "Fire")
	if s.find("cold") >= 0 or s.find("frost") >= 0: _add_unique(tags, "Cold")
	if s.find("lightning") >= 0 or s.find("storm") >= 0: _add_unique(tags, "Lightning")
	if s.find("void") >= 0 or s.find("shadow") >= 0 or s.find("curse") >= 0: _add_unique(tags, "Void")
	if s.find("physical") >= 0 or s.find("melee") >= 0: _add_unique(tags, "Physical")
	if s.find("spell") >= 0: _add_unique(tags, "Spell")
	if s.find("projectile") >= 0: _add_unique(tags, "Projectile")
	if s.find("area") >= 0 or s.find("aoe") >= 0: _add_unique(tags, "Area")
	if s.find("trap") >= 0: _add_unique(tags, "Trap")
	if s.find("critical") >= 0 or s.find("crit") >= 0: _add_unique(tags, "Critical")
	if s.find("burn") >= 0 or s.find("ignite") >= 0: _add_unique(tags, "Burn")
	if s.find("bleed") >= 0: _add_unique(tags, "Bleed")
	if s.find("chain") >= 0: _add_unique(tags, "Chain")
	if s.find("cooldown") >= 0: _add_unique(tags, "Cooldown")
	if s.find("mana") >= 0: _add_unique(tags, "Mana")
	if s.find("spirit") >= 0: _add_unique(tags, "Spirit")
	if s.find("life") >= 0 or s.find("health") >= 0: _add_unique(tags, "Life")
	if s.find("armor") >= 0 or s.find("armour") >= 0: _add_unique(tags, "Armor")
	if s.find("proc") >= 0 or s.find("trigger") >= 0: _add_unique(tags, "Proc")
	if s.find("conversion") >= 0 or s.find("convert") >= 0: _add_unique(tags, "Conversion")

static func _add_unique(tags: Array, tag: String) -> void:
	if tag == "": return
	if not tags.has(tag): tags.append(tag)

static func score_item(profile: Dictionary, item: Dictionary) -> float:
	var wanted: Dictionary = profile.get("wanted_tags", {})
	var unwanted: Dictionary = profile.get("unwanted_tags", {})
	var style: Dictionary = profile.get("decision_style", {})
	var tags: Array = item_tags(item)
	var score: float = 0.0
	for tag in tags:
		var key: String = str(tag)
		score += float(wanted.get(key, 0.0))
		score += float(unwanted.get(key, 0.0))
	var stats: Dictionary = item.get("stats", {})
	for stat_key in stats.keys():
		score += abs(float(stats[stat_key])) * 12.0
	var rarity: String = item_rarity(item)
	if rarity == "Magic": score += 3.0
	elif rarity == "Rare": score += 7.0
	elif rarity == "Unique" or rarity == "Legendary": score += 18.0 * float(style.get("unique_curiosity", 0.5))
	elif rarity == "Crafted": score += 5.0
	if bool(style.get("keeps_high_potential_bases", false)):
		score += item_forge_potential(item) * 0.45
	else:
		score += min(item_forge_potential(item), 18.0) * 0.08
	return score

static func classify_item(profile: Dictionary, item: Dictionary, equipped_item: Dictionary) -> Dictionary:
	var score: float = score_item(profile, item)
	var previous_score: float = 0.0
	if not equipped_item.is_empty():
		previous_score = score_item(profile, equipped_item)
	var style: Dictionary = profile.get("decision_style", {})
	var threshold: float = float(style.get("upgrade_threshold", 1.12))
	var tags: Array = item_tags(item)
	var relevant_tag_count: int = 0
	var wanted: Dictionary = profile.get("wanted_tags", {})
	for tag in tags:
		if float(wanted.get(str(tag), 0.0)) >= 5.0:
			relevant_tag_count += 1
	var archetype: bool = is_archetype_hit(item, tags)
	var confusing: bool = is_confusing(profile, tags)
	var classification: String = "Trash"
	if previous_score <= 0.01 and score >= 10.0:
		classification = "Immediate Upgrade"
	elif previous_score > 0.01 and score >= previous_score * threshold:
		classification = "Immediate Upgrade"
	elif archetype:
		classification = "Unique Archetype Enabler"
	elif item_forge_potential(item) >= 24.0 and relevant_tag_count >= 1 and bool(style.get("keeps_high_potential_bases", false)):
		classification = "Crafting Base"
	elif relevant_tag_count >= 2 and score >= 16.0:
		classification = "Build-Relevant Keep"
	elif confusing and score >= 8.0:
		classification = "Confusing Item"
	elif score >= 8.0:
		classification = "Sidegrade"
	else:
		classification = "Salvage"
	return {
		"item": item,
		"score": score,
		"previous_score": previous_score,
		"uplift": score - previous_score,
		"tags": tags,
		"relevant_tag_count": relevant_tag_count,
		"classification": classification,
		"archetype_hit": archetype,
		"confusing": confusing
	}

static func is_archetype_hit(item: Dictionary, tags: Array) -> bool:
	if item_rarity(item) == "Unique" or item_rarity(item) == "Legendary":
		return true
	if item.has("unique_effects") or item.has("unique_effect") or item.has("build_flags"):
		return true
	var strong_tags: int = 0
	for tag in ["Proc", "Conversion", "Chain", "Spirit", "Unique"]:
		if tags.has(tag): strong_tags += 1
	return strong_tags >= 2

static func is_confusing(profile: Dictionary, tags: Array) -> bool:
	var wanted: Dictionary = profile.get("wanted_tags", {})
	var unwanted: Dictionary = profile.get("unwanted_tags", {})
	var wanted_hits: int = 0
	var unwanted_hits: int = 0
	for tag in tags:
		if float(wanted.get(str(tag), 0.0)) > 0.0:
			wanted_hits += 1
		if float(unwanted.get(str(tag), 0.0)) < 0.0:
			unwanted_hits += 1
	return wanted_hits > 0 and unwanted_hits > 0
