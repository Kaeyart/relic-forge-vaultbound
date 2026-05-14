class_name RVSkillSystem
extends RefCounted

static func update(state: RVGameState, delta: float) -> void:
	for skill in state.skill_cooldowns.keys():
		state.skill_cooldowns[skill] = max(0.0, float(state.skill_cooldowns[skill]) - delta)


static func cast_selected(state: RVGameState, aim: Vector2) -> void:
	if state.active_skills.size() == 0: return
	state.selected_skill = clamp(state.selected_skill, 0, state.active_skills.size() - 1)
	var skill: String = str(state.active_skills[state.selected_skill])
	cast(state, skill, aim)


static func cast(state: RVGameState, skill: String, aim: Vector2) -> void:
	var data: Dictionary = RVSkillDB.data(skill)
	if data.is_empty(): return
	var cost: float = float(data.get("cost", 10.0))
	var cooldown: float = float(data.get("cooldown", 0.5))
	var cd: float = float(state.skill_cooldowns.get(skill, 0.0))
	if cd > 0.0: return
	if state.player_mana < cost:
		state.add_notice("Not enough mana")
		return
	state.player_mana -= cost
	state.skill_cooldowns[skill] = cooldown
	var damage: float = scale_damage(state, skill, float(data.get("damage", 10.0)))
	var tags: Array = data.get("tags", [])
	var dir: Vector2 = aim - state.player_pos
	if dir.length() < 0.01: dir = Vector2.RIGHT
	else: dir = dir.normalized()
	match skill:
		"Fireball": state.projectiles.append(make_projectile(state.player_pos + dir * 24.0, dir * 520.0, damage, 8.0, tags, skill, 0.95, 0))
		"Storm Lance": state.projectiles.append(make_projectile(state.player_pos + dir * 28.0, dir * 720.0, damage, 6.0, tags, skill, 0.72, 1))
		"Cleave": state.zones.append({"pos": state.player_pos + dir * 58.0, "radius": 76.0, "time": 0.05, "duration": 0.16, "damage": damage, "tags": tags, "visual": "Cleave", "triggered": false})
		"Frost Nova": state.zones.append({"pos": state.player_pos, "radius": 145.0, "time": 0.18, "duration": 0.34, "damage": damage, "tags": tags, "visual": "Frost Nova", "triggered": false})
		"Void Rift": state.zones.append({"pos": aim, "radius": 92.0, "time": 0.38, "duration": 0.75, "damage": damage, "tags": tags, "visual": "Void Rift", "triggered": false, "pull": true})
		"Blade Trap": state.zones.append({"pos": aim, "radius": 64.0, "time": 0.45, "duration": 0.52, "damage": damage, "tags": tags, "visual": "Blade Trap", "triggered": false})


static func make_projectile(pos: Vector2, vel: Vector2, damage: float, radius: float, tags: Array, skill: String, life: float, pierce: int) -> Dictionary:
	return {"pos": pos, "vel": vel, "damage": damage, "radius": radius, "tags": tags.duplicate(true), "skill": skill, "life": life, "pierce": pierce, "hit_ids": {}}


static func scale_damage(state: RVGameState, skill: String, base: float) -> float:
	var value: float = base
	var rank: int = int(state.skill_ranks.get(skill, 0))
	value *= 1.0 + float(rank) * 0.08
	var tags: Array = RVSkillDB.tags(skill)
	var stat_keys: Array = []
	if tags.has("Fire"): stat_keys.append("fire_damage")
	if tags.has("Cold"): stat_keys.append("cold_damage")
	if tags.has("Lightning"): stat_keys.append("lightning_damage")
	if tags.has("Void"): stat_keys.append("void_damage")
	if tags.has("Physical") or tags.has("Melee"): stat_keys.append("melee_damage")
	if tags.has("Trap"): stat_keys.append("trap_damage")
	if tags.has("Spell"): stat_keys.append("spell_damage")
	stat_keys.append("global_damage")
	for slot in state.equipped.keys():
		var item: Variant = state.equipped[slot]
		if typeof(item) != TYPE_DICTIONARY: continue
		var stats: Dictionary = item.get("stats", {})
		for key in stat_keys:
			value *= 1.0 + float(stats.get(key, 0.0))
	return value
