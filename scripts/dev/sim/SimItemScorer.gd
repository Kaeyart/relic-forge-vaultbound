class_name RVSimItemScorer
extends RefCounted

static func rarity_rank(item: Dictionary) -> int:
	var rarity: String = str(item.get("rarity", "Normal"))
	match rarity:
		"Normal", "Common":
			return 0
		"Magic":
			return 1
		"Rare":
			return 2
		"Epic":
			return 3
		"Legendary":
			return 4
		"Unique":
			return 5
		"Crafted":
			return 2
	return 0

static func normalize_slot(slot: String) -> String:
	var s: String = slot.to_lower().strip_edges()
	match s:
		"mainhand", "main_hand", "main hand", "weapon", "slotweapon":
			return "weapon"
		"offhand", "off_hand", "off hand", "shield", "focus", "slotoffhand":
			return "offhand"
		"helmet", "helm", "head", "slothelmet", "slothead":
			return "head"
		"body", "body armor", "armour", "armor", "chest", "slotchest":
			return "chest"
		"glove", "gloves", "slotgloves":
			return "gloves"
		"boot", "boots", "slotboots":
			return "boots"
		"neck", "necklace", "amulet", "slotamulet":
			return "amulet"
		"ring", "ring1", "ring2", "left_ring", "right_ring", "slotring", "slotring1", "slotring2":
			return "ring"
		"belt", "slotbelt":
			return "belt"
		"relic", "charm", "slotrelic":
			return "relic"
	return s

static func item_slot(item: Dictionary) -> String:
	return normalize_slot(str(item.get("slot", item.get("base_slot", "misc"))))

static func stat_dictionary(item: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var sources: Array = []
	for key in ["stats", "implicit_stats", "total_stats", "base_stats"]:
		var v: Variant = item.get(key, {})
		if typeof(v) == TYPE_DICTIONARY:
			sources.append(v)
	for dict in sources:
		for k in dict.keys():
			out[str(k)] = float(out.get(str(k), 0.0)) + float(dict[k])
	return out

static func affix_list(item: Dictionary) -> Array:
	var out: Array = []
	for key in ["affixes", "prefixes", "suffixes", "implicit", "unique_effects", "effect_lines"]:
		var v: Variant = item.get(key, [])
		if typeof(v) == TYPE_ARRAY:
			for a in v:
				if typeof(a) == TYPE_DICTIONARY:
					out.append(str(a.get("name", a.get("id", "affix"))))
				else:
					out.append(str(a))
		elif typeof(v) == TYPE_DICTIONARY:
			for a_key in v.keys():
				out.append(str(a_key))
	return out

static func item_tags(item: Dictionary) -> Array:
	var text_parts: Array[String] = []
	text_parts.append(str(item.get("name", "")))
	text_parts.append(str(item.get("rarity", "")))
	text_parts.append(str(item.get("slot", "")))
	text_parts.append(str(item.get("base_type", "")))
	text_parts.append(str(item.get("armor_class", "")))
	for k in stat_dictionary(item).keys():
		text_parts.append(str(k))
	for a in affix_list(item):
		text_parts.append(str(a))
	var flags: Variant = item.get("build_flags", item.get("flags", []))
	if typeof(flags) == TYPE_ARRAY:
		for flag in flags:
			text_parts.append(str(flag))
	var blob: String = " ".join(text_parts).to_lower()
	var tags: Array = []
	var candidates: Dictionary = {
		"Fire": ["fire", "burn", "ignite", "ember", "furnace"],
		"Cold": ["cold", "frost", "freeze", "chill", "ice"],
		"Lightning": ["lightning", "storm", "shock", "chain", "overcharge"],
		"Void": ["void", "rift", "shadow", "curse", "abyss"],
		"Physical": ["physical", "melee", "slash", "bleed", "weapon", "attack"],
		"Trap": ["trap", "blade trap", "trapdoor"],
		"Spell": ["spell", "cast", "caster", "wand", "focus"],
		"Projectile": ["projectile", "fireball", "lance"],
		"Area": ["area", "nova", "aoe", "explosion"],
		"Critical": ["critical", "crit"],
		"Burn": ["burn", "ignite"],
		"Freeze": ["freeze", "chill"],
		"Curse": ["curse", "cursed"],
		"Bleed": ["bleed", "bleeding"],
		"Cooldown": ["cooldown", "recovery"],
		"Mana": ["mana"],
		"Life": ["life", "health", "vitality"],
		"Armor": ["armor", "armour", "defense"],
		"Spirit": ["spirit", "reservation", "reserved"],
		"Potential": ["forge potential", "potential"],
		"Unique": ["unique", "legendary"],
		"Proc": ["trigger", "proc", "cast", "on hit", "on kill", "on crit", "calls"],
		"Conversion": ["convert", "conversion", "becomes", "counts as"],
		"Chain": ["chain", "cascade", "choir"]
	}
	for tag in candidates.keys():
		for needle in candidates[tag]:
			if blob.find(str(needle)) >= 0:
				tags.append(tag)
				break
	return tags

static func power_score(item: Dictionary) -> float:
	var score: float = 0.0
	var stats: Dictionary = stat_dictionary(item)
	for k in stats.keys():
		var key: String = str(k)
		var value: float = abs(float(stats[k]))
		if key.find("Maximum") >= 0 or key.find("Armor") >= 0:
			score += value * 0.025
		else:
			score += value * 12.0
	score += float(affix_list(item).size()) * 0.75
	score += float(rarity_rank(item)) * 1.25
	return score

static func score_item_for_profile(item: Dictionary, profile: Dictionary) -> float:
	if item.is_empty():
		return 0.0
	var weights: Dictionary = profile.get("weights", {})
	var score: float = 0.0
	score += float(rarity_rank(item)) * float(weights.get("rarity", 0.4))
	score += power_score(item) * float(weights.get("power", 1.0))
	var tags: Array = item_tags(item)
	var desired_tags: Array = profile.get("desired_tags", [])
	for tag in tags:
		if desired_tags.has(tag):
			score += 2.0 * float(weights.get("tags", 1.0))
	var desired_stats: Array = profile.get("desired_stats", [])
	var stats: Dictionary = stat_dictionary(item)
	for stat_name in stats.keys():
		if desired_stats.has(str(stat_name)):
			score += 1.65 * float(weights.get("tags", 1.0))
	var potential: float = float(item.get("forge_potential", item.get("forging_potential", 0.0)))
	score += min(potential, 40.0) * 0.12 * float(weights.get("potential", 0.2))
	var rarity: String = str(item.get("rarity", ""))
	if rarity == "Unique" or item.has("unique_effects") or item.has("build_flags"):
		score += 6.0 * float(weights.get("unique", 1.0))
	var slot_focus: Dictionary = profile.get("slot_focus", {})
	var slot: String = item_slot(item)
	var multiplier: float = float(slot_focus.get(slot, slot_focus.get("ring", 1.0) if slot == "ring" else 1.0))
	return score * multiplier

static func useful_for_profile(item: Dictionary, profile: Dictionary, threshold: float = 6.0) -> bool:
	return score_item_for_profile(item, profile) >= threshold
