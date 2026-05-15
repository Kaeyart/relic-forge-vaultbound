class_name RVSkillSystem
extends RefCounted

static func update(state: RVGameState, delta: float) -> void:
	for skill in state.skill_cooldowns.keys():
		state.skill_cooldowns[skill] = max(0.0, float(state.skill_cooldowns[skill]) - delta)

static func cast_selected(state: RVGameState, aim: Vector2) -> void:
	if state.active_skills.size() == 0: return
	state.selected_skill = clamp(state.selected_skill, 0, state.active_skills.size() - 1)
	cast(state, str(state.active_skills[state.selected_skill]), aim)

static func cast(state: RVGameState, skill: String, aim: Vector2) -> void:
	var data: Dictionary = RVSkillDB.data(skill)
	if data.is_empty(): return
	var mods: Dictionary = support_mods(state, skill)
	var cost: float = float(data.get("cost", 10.0)) * float(mods.get("cost_mult", 1.0))
	cost *= 1.0 - float(mods.get("mana_cost_reduction", 0.0))
	var cooldown: float = float(data.get("cooldown", 0.5)) * float(mods.get("cooldown_mult", 1.0))
	cooldown *= 1.0 - float(mods.get("cooldown_reduction", 0.0))
	if float(state.skill_cooldowns.get(skill, 0.0)) > 0.0: return
	if state.player_mana < cost: state.add_notice("Not enough mana"); return
	state.player_mana -= cost
	state.skill_cooldowns[skill] = max(0.05, cooldown)
	var damage: float = scale_damage(state, skill, float(data.get("damage", 10.0)), mods)
	var tags: Array = data.get("tags", [])
	var dir: Vector2 = aim - state.player_pos
	if dir.length() < 0.01: dir = Vector2.RIGHT
	else: dir = dir.normalized()
	var extra: int = int(mods.get("extra_projectiles", 0.0))
	match skill:
		"Fireball", "Storm Lance":
			spawn_projectile_set(state, skill, dir, damage, tags, extra)
		"Cleave":
			state.zones.append(zone(state.player_pos + dir * 58.0, 76.0, 0.05, 0.16, damage, tags, "Cleave"))
		"Frost Nova":
			state.zones.append(zone(state.player_pos, 145.0 * (1.0 + float(mods.get("area_size", 0.0))), 0.18, 0.34, damage, tags, "Frost Nova"))
		"Void Rift":
			var z: Dictionary = zone(aim, 92.0 * (1.0 + float(mods.get("area_size", 0.0))), 0.38, 0.75, damage, tags, "Void Rift")
			z["pull"] = true
			state.zones.append(z)
		"Blade Trap":
			state.zones.append(zone(aim, 64.0 * (1.0 + float(mods.get("area_size", 0.0))), 0.45, 0.52, damage, tags, "Blade Trap"))

static func spawn_projectile_set(state: RVGameState, skill: String, dir: Vector2, damage: float, tags: Array, extra: int) -> void:
	var speed: float = 520.0 if skill == "Fireball" else 720.0
	var radius: float = 8.0 if skill == "Fireball" else 6.0
	var pierce: int = 0 if skill == "Fireball" else 1
	var total: int = 1 + extra
	for i in range(total):
		var offset: float = 0.0
		if total > 1: offset = (float(i) - float(total - 1) * 0.5) * 0.16
		var fd: Vector2 = dir.rotated(offset)
		var final_damage: float = damage
		if extra > 0: final_damage *= 0.75
		state.projectiles.append({"pos": state.player_pos + fd * 24.0, "vel": fd * speed, "damage": final_damage, "radius": radius, "tags": tags.duplicate(true), "skill": skill, "life": 0.95, "pierce": pierce, "hit_ids": {}})

static func zone(pos: Vector2, radius: float, time: float, duration: float, damage: float, tags: Array, visual: String) -> Dictionary:
	return {"pos": pos, "radius": radius, "time": time, "duration": duration, "damage": damage, "tags": tags.duplicate(true), "visual": visual, "triggered": false}

static func support_mods(state: RVGameState, skill: String) -> Dictionary:
	var out: Dictionary = {"cost_mult": 1.0, "cooldown_mult": 1.0}
	for support in state.skill_gem_sockets.get(skill, []):
		var sd: Dictionary = RVSkillGemDB.support_data(str(support))
		out["cost_mult"] = float(out.get("cost_mult", 1.0)) * float(sd.get("cost_mult", 1.0))
		out["cooldown_mult"] = float(out.get("cooldown_mult", 1.0)) * float(sd.get("cooldown_mult", 1.0))
		for k in sd.get("stats", {}).keys():
			out[k] = float(out.get(k, 0.0)) + float(sd["stats"][k])
	return out

static func scale_damage(state: RVGameState, skill: String, base: float, mods: Dictionary) -> float:
	var value: float = base * (1.0 + float(state.skill_ranks.get(skill, 0)) * 0.08)
	var stat_keys: Array = ["global_damage"]
	var tags: Array = RVSkillDB.tags(skill)
	if tags.has("Fire"): stat_keys.append("fire_damage")
	if tags.has("Cold"): stat_keys.append("cold_damage")
	if tags.has("Lightning"): stat_keys.append("lightning_damage")
	if tags.has("Void"): stat_keys.append("void_damage")
	if tags.has("Physical") or tags.has("Attack"): stat_keys.append("melee_damage")
	if tags.has("Trap"): stat_keys.append("trap_damage")
	if tags.has("Spell"): stat_keys.append("spell_damage")
	for key in stat_keys:
		value *= 1.0 + float(state.build_stats.get(key, 0.0)) + float(mods.get(key, 0.0))
		for slot in state.equipped.keys():
			var item: Variant = state.equipped[slot]
			if typeof(item) == TYPE_DICTIONARY: value *= 1.0 + float(item.get("stats", {}).get(key, 0.0))
	value *= 1.0 - float(mods.get("less_damage", 0.0))
	return value
