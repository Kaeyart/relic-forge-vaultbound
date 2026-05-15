class_name RVLabCombatProxyEvaluator
extends RefCounted

static func evaluate(lab_state: RVLabCharacterState) -> Dictionary:
	var coherence: Dictionary = RVLabBuildCoherenceEvaluator.evaluate(lab_state)
	var tag_hits: Dictionary = coherence.get("equipped_tag_hits", {})
	var damage_tags: int = _sum_tags(tag_hits, ["Fire", "Cold", "Lightning", "Void", "Physical", "Melee", "Spell", "Trap", "Projectile"])
	var defense_tags: int = _sum_tags(tag_hits, ["Life", "Armor"])
	var control_tags: int = _sum_tags(tag_hits, ["Cold", "Trap", "Void", "Curse", "Area"])
	var proc_tags: int = _sum_tags(tag_hits, ["Proc", "Chain", "Conversion"])
	var mana_tags: int = _sum_tags(tag_hits, ["Mana", "Spirit", "Cooldown"])
	var dps: float = 20.0 + float(damage_tags) * 8.0 + float(proc_tags) * 6.0
	var aoe: float = 20.0 + float(_sum_tags(tag_hits, ["Area", "Chain", "Projectile", "Trap"])) * 9.0
	var survivability: float = 30.0 + float(defense_tags) * 10.0 + float(control_tags) * 2.0
	var mana_comfort: float = 55.0 + float(mana_tags) * 7.0 - float(proc_tags) * 4.0
	var visual_noise: float = float(proc_tags) * 12.0 + float(_sum_tags(tag_hits, ["Area", "Chain"])) * 6.0
	var clear_speed: float = clamp((dps * 0.45 + aoe * 0.45 + control_tags * 4.0) / 100.0, 0.0, 2.0)
	var death_risk: float = clamp(1.25 - survivability / 100.0 - float(control_tags) * 0.03, 0.05, 1.0)
	return {
		"effective_dps": snapped(dps, 0.1),
		"aoe_coverage": snapped(aoe, 0.1),
		"survivability": snapped(survivability, 0.1),
		"mana_comfort": snapped(mana_comfort, 0.1),
		"visual_noise_risk": snapped(visual_noise, 0.1),
		"clear_speed_proxy": snapped(clear_speed, 0.01),
		"death_risk_proxy": snapped(death_risk, 0.01)
	}

static func _sum_tags(tag_hits: Dictionary, tags: Array) -> int:
	var total: int = 0
	for tag in tags:
		total += int(tag_hits.get(str(tag), 0))
	return total
