class_name RVForgecraftDB
extends RefCounted

const PREFIX_AFFIXES = {
	"fire_damage":{"name":"Scorching", "stat":"fire_damage", "slot":"prefix"},
	"cold_damage":{"name":"Glacial", "stat":"cold_damage", "slot":"prefix"},
	"lightning_damage":{"name":"Galvanic", "stat":"lightning_damage", "slot":"prefix"},
	"void_damage":{"name":"Abyssal", "stat":"void_damage", "slot":"prefix"},
	"melee_damage":{"name":"Butcher's", "stat":"melee_damage", "slot":"prefix"},
	"trap_damage":{"name":"Clockwork", "stat":"trap_damage", "slot":"prefix"},
	"spell_damage":{"name":"Runic", "stat":"spell_damage", "slot":"prefix"}
}

const SUFFIX_AFFIXES = {
	"max_hp":{"name":"of Bone", "stat":"max_hp", "slot":"suffix"},
	"max_mana":{"name":"of Wells", "stat":"max_mana", "slot":"suffix"},
	"cooldown_reduction":{"name":"of Tempo", "stat":"cooldown_reduction", "slot":"suffix"},
	"global_damage":{"name":"of Ruin", "stat":"global_damage", "slot":"suffix"},
	"freeze_duration":{"name":"of Stillness", "stat":"freeze_duration", "slot":"suffix"}
}

static func all_affixes() -> Dictionary:
	var out: Dictionary = {}
	for k in PREFIX_AFFIXES.keys():
		out[k] = PREFIX_AFFIXES[k]
	for k2 in SUFFIX_AFFIXES.keys():
		out[k2] = SUFFIX_AFFIXES[k2]
	return out

static func default_crafting_shards() -> Dictionary:
	return {
		"fire_damage":12,"cold_damage":12,"lightning_damage":12,"void_damage":12,
		"melee_damage":12,"trap_damage":12,"spell_damage":12,
		"max_hp":12,"max_mana":12,"cooldown_reduction":8,"global_damage":6,"freeze_duration":8
	}

static func default_glyphs() -> Dictionary:
	return {"hope":8,"chaos":5,"despair":3,"order":3}

static func default_runes() -> Dictionary:
	return {"shattering":5,"refinement":4,"removal":3,"discovery":3,"creation":1}

static func make_base(state: RVGameState) -> Dictionary:
	var slots: Array = ["weapon","offhand","head","chest","gloves","boots","amulet","ring","relic"]
	var slot: String = slots[state.rng.randi_range(0, slots.size() - 1)]
	return {
		"name":"Blank " + slot.capitalize(),
		"slot":slot,
		"rarity":"Forgeable",
		"stats":{},
		"flags":[],
		"affixes":[],
		"sealed_affix":{},
		"forging_potential": state.rng.randi_range(28, 46),
		"desc":"A forgeable base item."
	}

static func affix_value(affix_id: String, tier: int) -> float:
	var affixes: Dictionary = all_affixes()
	var stat: String = str(affixes.get(affix_id, {}).get("stat", "global_damage"))
	if stat == "max_hp" or stat == "max_mana":
		return 8.0 * float(tier)
	if stat == "cooldown_reduction":
		return 0.012 * float(tier)
	if stat == "freeze_duration":
		return 0.05 * float(tier)
	return 0.035 * float(tier)

static func rebuild_item_stats(item: Dictionary) -> Dictionary:
	var affixes: Dictionary = all_affixes()
	var stats: Dictionary = {}
	for affix in item.get("affixes", []):
		if typeof(affix) != TYPE_DICTIONARY:
			continue
		var id: String = str(affix.get("id", ""))
		if not affixes.has(id):
			continue
		var stat: String = str(affixes[id]["stat"])
		stats[stat] = float(stats.get(stat, 0.0)) + affix_value(id, int(affix.get("tier", 1)))
	var sealed: Variant = item.get("sealed_affix", {})
	if typeof(sealed) == TYPE_DICTIONARY and not sealed.is_empty():
		var sealed_id: String = str(sealed.get("id", ""))
		if affixes.has(sealed_id):
			var sealed_stat: String = str(affixes[sealed_id]["stat"])
			stats[sealed_stat] = float(stats.get(sealed_stat, 0.0)) + affix_value(sealed_id, int(sealed.get("tier", 1)))
	item["stats"] = stats
	return item
