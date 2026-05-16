class_name RVSkillBehaviorSystem
extends RefCounted

# Patch 067: active-skill identity scaling and support-driven behavior descriptors.
# CombatArena can read these keys over time; the UI and VFX can already show them.

static func apply_identity_scaling(state: RVGameState, skill_name: String, skill_data: Dictionary) -> Dictionary:
	var out: Dictionary = skill_data.duplicate(true)
	var gem: Dictionary = _active_gem_for_skill(state, skill_name)
	var gem_level: int = int(gem.get("level", 1)) if not gem.is_empty() else 1
	var supports: Array = gem.get("supports", []) if not gem.is_empty() else []
	var level_mult: float = 1.0 + max(0, gem_level - 1) * 0.035
	out["damage"] = float(out.get("damage", 10.0)) * level_mult
	out["identity_notes"] = []
	match skill_name:
		"Fireball":
			out["burn_duration"] = 2.4 + float(gem_level) * 0.04
			out["burn_power"] = 1.0 + _support_count(supports, ["burning", "added_fire", "controlled_power"]) * 0.18
			out["impact_radius"] = float(out.get("impact_radius", 46.0)) * (1.0 + _support_count(supports, ["area_expansion", "increased_area"]) * 0.20)
			out["identity_notes"].append("Projectile explosion applies Burn.")
		"Storm Lance":
			out["chain_count"] = int(out.get("chain_count", 2)) + _support_count(supports, ["chain", "overcharge"])
			out["shock_duration"] = 1.8 + float(gem_level) * 0.025
			out["identity_notes"].append("Fast lance chains and shocks priority packs.")
		"Frost Nova":
			out["freeze_duration"] = 1.10 + float(gem_level) * 0.03 + _support_count(supports, ["frostbite"]) * 0.35
			out["control_radius"] = float(out.get("radius", 145.0)) * (1.0 + _support_count(supports, ["area_expansion", "increased_area"]) * 0.16)
			out["identity_notes"].append("Defensive nova slows and freezes nearby enemies.")
		"Void Rift":
			out["pulse_count"] = 2 + _support_count(supports, ["void_echo"])
			out["pull_strength"] = 34.0 + float(gem_level) * 0.7
			out["curse_duration"] = 2.2 + _support_count(supports, ["void_echo", "controlled_power"]) * 0.5
			out["identity_notes"].append("Delayed rift pulls, curses, and pulses.")
		"Cleave":
			out["bleed_duration"] = 2.6 + float(gem_level) * 0.04
			out["execute_threshold"] = 0.18 + _support_count(supports, ["bloodletting", "critical_focus"]) * 0.04
			out["arc_width"] = 1.10 + _support_count(supports, ["area_expansion"]) * 0.18
			out["identity_notes"].append("Close arc bleeds and executes weakened enemies.")
		"Blade Trap":
			out["trap_arming_time"] = max(0.18, 0.55 - _support_count(supports, ["trap_mechanism", "swift_cast"]) * 0.08)
			out["trap_repeat_count"] = 1 + _support_count(supports, ["void_echo", "trap_mechanism"])
			out["identity_notes"].append("Arms, spins, and repeats in controlled space.")
	out["combat_identity_ready"] = true
	return out

static func _active_gem_for_skill(state: RVGameState, skill_name: String) -> Dictionary:
	if state == null:
		return {}
	for value: Variant in state.skill_gem_inventory:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var gem: Dictionary = Dictionary(value)
		if str(gem.get("type", "")) != "active":
			continue
		var name: String = str(gem.get("name", gem.get("skill_name", gem.get("gem_id", ""))))
		var gem_id: String = str(gem.get("gem_id", ""))
		if name == skill_name or gem_id == skill_name or name.to_lower() == skill_name.to_lower():
			return gem
	return {}

static func _support_count(supports: Array, ids: Array) -> int:
	var count: int = 0
	for support_value: Variant in supports:
		var support_id: String = str(support_value).to_lower()
		for id_value: Variant in ids:
			if support_id == str(id_value).to_lower():
				count += 1
	return count
