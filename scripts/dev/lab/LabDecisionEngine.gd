class_name RVLabDecisionEngine
extends RefCounted

static func process_item_drop(lab_state: RVLabCharacterState, item: Dictionary) -> Dictionary:
	lab_state.total_drops += 1
	var rarity: String = RVLabItemEvaluator.item_rarity(item)
	lab_state.count_rarity(rarity)
	var slot_name: String = RVLabItemEvaluator.item_slot(item)
	var equipped_item: Dictionary = lab_state.equipment.get(slot_name, {})
	var evaluation: Dictionary = RVLabItemEvaluator.classify_item(lab_state.profile, item, equipped_item)
	lab_state.hit_tags(evaluation.get("tags", []))
	var classification: String = str(evaluation.get("classification", "Trash"))
	var decision: Dictionary = {
		"room": lab_state.room_index,
		"item_name": RVLabItemEvaluator.item_name(item),
		"slot": slot_name,
		"rarity": rarity,
		"score": float(evaluation.get("score", 0.0)),
		"previous_score": float(evaluation.get("previous_score", 0.0)),
		"classification": classification,
		"tags": evaluation.get("tags", [])
	}
	if bool(evaluation.get("archetype_hit", false)):
		lab_state.archetype_hits += 1
	if classification == "Immediate Upgrade":
		lab_state.equipment[slot_name] = item.duplicate(true)
		lab_state.register_upgrade(slot_name)
		decision["action"] = "equip"
		lab_state.add_timeline("Upgrade", "Equipped " + RVLabItemEvaluator.item_name(item) + " in " + slot_name + " (score " + _fmt(float(evaluation.get("score", 0.0))) + ")", decision)
	elif classification == "Build-Relevant Keep" or classification == "Unique Archetype Enabler" or classification == "Sidegrade":
		lab_state.kept_items.append(item.duplicate(true))
		lab_state.useful_keeps += 1
		lab_state.register_non_upgrade()
		decision["action"] = "keep"
	elif classification == "Crafting Base":
		lab_state.crafting_bases.append(item.duplicate(true))
		lab_state.crafting_keeps += 1
		lab_state.register_non_upgrade()
		decision["action"] = "crafting_base"
		lab_state.add_timeline("CraftingBase", "Kept high-potential base: " + RVLabItemEvaluator.item_name(item), decision)
	elif classification == "Confusing Item":
		lab_state.confusing_items += 1
		lab_state.salvaged_items.append(item.duplicate(true))
		lab_state.register_non_upgrade()
		decision["action"] = "confusing_salvage"
	else:
		lab_state.salvaged_items.append(item.duplicate(true))
		lab_state.ignored_items += 1
		lab_state.register_non_upgrade()
		decision["action"] = "salvage"
	lab_state.add_decision(decision)
	return decision

static func process_gem_reward(lab_state: RVLabCharacterState, gem: Dictionary = {}) -> Dictionary:
	lab_state.gem_rewards += 1
	var decision: Dictionary = {"room": lab_state.room_index, "type": "gem", "action": "inspect", "gem": gem}
	lab_state.add_decision(decision)
	if lab_state.gem_rewards == 1:
		lab_state.add_timeline("Gem", "First gem reward appeared.", decision)
	return decision

static func _fmt(value: float) -> String:
	return str(snapped(value, 0.1))
