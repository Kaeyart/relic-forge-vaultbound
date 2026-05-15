class_name RVLabBuildCoherenceEvaluator
extends RefCounted

static func evaluate(lab_state: RVLabCharacterState) -> Dictionary:
	var wanted: Dictionary = lab_state.profile.get("wanted_tags", {})
	var equipped_tag_hits: Dictionary = {}
	var wanted_hits: int = 0
	var offbuild_hits: int = 0
	var total_tags: int = 0
	for slot_name in lab_state.equipment.keys():
		var item: Dictionary = lab_state.equipment[slot_name]
		var tags: Array = RVLabItemEvaluator.item_tags(item)
		for tag in tags:
			var key: String = str(tag)
			equipped_tag_hits[key] = int(equipped_tag_hits.get(key, 0)) + 1
			total_tags += 1
			if float(wanted.get(key, 0.0)) > 0.0:
				wanted_hits += 1
			elif _is_build_tag(key):
				offbuild_hits += 1
	var coherence: float = 0.0
	if total_tags > 0:
		coherence = clamp(float(wanted_hits) / float(max(1, wanted_hits + offbuild_hits)), 0.0, 1.0)
	var primary: Array = _top_tags(equipped_tag_hits, wanted, true, 4)
	var noise: Array = _top_tags(equipped_tag_hits, wanted, false, 4)
	return {
		"coherence": coherence,
		"wanted_hits": wanted_hits,
		"offbuild_hits": offbuild_hits,
		"equipped_tag_hits": equipped_tag_hits,
		"primary_identity": primary,
		"offbuild_noise": noise
	}

static func _is_build_tag(tag: String) -> bool:
	return ["Fire", "Cold", "Lightning", "Void", "Physical", "Melee", "Trap", "Spell", "Projectile", "Area", "Burn", "Bleed", "Critical", "Proc", "Chain", "Conversion", "Spirit", "Mana"].has(tag)

static func _top_tags(tag_hits: Dictionary, wanted: Dictionary, wanted_only: bool, limit: int) -> Array:
	var rows: Array = []
	for tag in tag_hits.keys():
		var weight: float = float(wanted.get(str(tag), 0.0))
		if wanted_only and weight <= 0.0:
			continue
		if not wanted_only and weight > 0.0:
			continue
		rows.append({"tag": str(tag), "count": int(tag_hits[tag]), "weight": weight})
	rows.sort_custom(func(a, b): return int(a.get("count", 0)) > int(b.get("count", 0)))
	return rows.slice(0, min(limit, rows.size()))
