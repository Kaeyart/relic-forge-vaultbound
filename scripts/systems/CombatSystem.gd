class_name RVCombatSystem
extends RefCounted

static func start_contract(state: RVGameState, contract: Dictionary) -> void:
	state.mode = "combat"
	state.current_contract = contract.duplicate(true)
	state.run_depth = 1
	state.reset_combat_runtime()
	state.player_pos = Vector2(640.0, 370.0)
	state.full_restore()
	spawn_room(state)
	state.add_notice(str(contract.get("name", "Activity")) + ": " + str(contract.get("goal", "Clear rooms")))

static func update(state: RVGameState, delta: float) -> void:
	if state.mode != "combat": return
	update_projectiles(state, delta)
	if state.mode != "combat": return
	update_zones(state, delta)
	if state.mode != "combat": return
	update_enemies(state, delta)
	if state.mode != "combat": return
	remove_dead_and_award(state)
	if state.mode != "combat": return
	if state.enemies.size() == 0:
		complete_room_or_contract(state)

static func complete_room_or_contract(state: RVGameState) -> void:
	RVProgressionSystem.award_room(state)
	var length: int = int(state.current_contract.get("length", 5))
	var mode: String = str(state.current_contract.get("mode", "Dungeon Run"))
	if state.run_depth >= length and mode != "Endless Rift":
		finish_contract(state)
		return
	state.run_depth += 1
	spawn_room(state)

static func finish_contract(state: RVGameState) -> void:
	var reward: String = str(state.current_contract.get("reward", "balanced"))
	if reward == "materials":
		state.materials["embers"] = int(state.materials.get("embers", 0)) + 12
		state.materials["shards"] = int(state.materials.get("shards", 0)) + 8
	elif reward == "boss":
		state.materials["runes"] = int(state.materials.get("runes", 0)) + 2
		state.backpack.append(RVItemDB.generate_drop(state, state.run_depth + 3, "boss"))
	elif reward == "items":
		state.backpack.append(RVItemDB.generate_drop(state, state.run_depth + 2, "items"))
		state.backpack.append(RVItemDB.generate_drop(state, state.run_depth + 2, "items"))
	state.enter_hub()
	state.add_notice("Activity complete · rewards added")

static func spawn_room(state: RVGameState) -> void:
	state.enemies.clear()
	state.projectiles.clear()
	state.zones.clear()
	state.obstacles.clear()
	var contract: Dictionary = state.current_contract
	var mode: String = str(contract.get("mode", "Dungeon Run"))
	var threat: float = float(contract.get("threat", 1.0)) + float(state.run_depth - 1) * 0.08
	if mode == "Endless Rift": threat += float(state.run_depth - 1) * 0.08
	var center: Vector2 = Vector2(640.0, 370.0)
	var count: int = 4 + int(contract.get("tier", 1)) * 2 + int(state.run_depth / 2)
	if mode == "Elite Hunt": count += 2
	if mode == "Boss Trial" and state.run_depth >= int(contract.get("length", 3)):
		state.enemies.append(RVEnemyDB.make("Dungeon Boss", center + Vector2(0.0, -120.0), threat, 0))
		state.enemies.append(RVEnemyDB.make("Ghoul", center + Vector2(-150.0, 80.0), threat, 1))
		state.enemies.append(RVEnemyDB.make("Ghoul", center + Vector2(150.0, 80.0), threat, 2))
	else:
		for i in range(count):
			var angle: float = TAU * float(i) / float(count)
			var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * (185.0 + float(i % 3) * 32.0)
			var enemy_type: String = choose_enemy_type(mode, i, state.run_depth)
			state.enemies.append(RVEnemyDB.make(enemy_type, pos, threat, i))
	spawn_obstacles(state, mode)
	state.add_notice(room_label(state))

static func choose_enemy_type(mode: String, i: int, depth: int) -> String:
	if mode == "Elite Hunt" and i % 4 == 0: return "Elite Knight"
	if mode == "Endless Rift" and depth >= 5 and i % 5 == 0: return "Void Caster"
	if i % 6 == 1: return "Skeleton Archer"
	if i % 6 == 2: return "Fire Spitter"
	if i % 6 == 3: return "Armored Brute"
	if i % 6 == 4 and depth >= 3: return "Void Caster"
	return "Ghoul"

static func room_label(state: RVGameState) -> String:
	var mode: String = str(state.current_contract.get("mode", "Dungeon Run"))
	if mode == "Boss Trial" and state.run_depth >= int(state.current_contract.get("length", 3)): return "Boss Room · defeat the boss"
	if mode == "Material Hunt": return "Material Room " + str(state.run_depth) + " · clear enemies for crafting materials"
	if mode == "Elite Hunt": return "Elite Room " + str(state.run_depth) + " · defeat elite packs"
	if mode == "Endless Rift": return "Rift Room " + str(state.run_depth) + " · scaling difficulty"
	return "Dungeon Room " + str(state.run_depth) + " · clear enemies"

static func spawn_obstacles(state: RVGameState, mode: String) -> void:
	var c: Vector2 = Vector2(640.0, 370.0)
	state.obstacles.append({"pos": c + Vector2(-155.0, -45.0), "radius": 30.0})
	state.obstacles.append({"pos": c + Vector2(150.0, 45.0), "radius": 30.0})
	if mode == "Elite Hunt" or mode == "Boss Trial":
		state.obstacles.append({"pos": c + Vector2(0.0, -155.0), "radius": 26.0})
		state.obstacles.append({"pos": c + Vector2(0.0, 155.0), "radius": 26.0})
	if mode == "Endless Rift":
		state.obstacles.append({"pos": c + Vector2(-240.0, 110.0), "radius": 22.0})
		state.obstacles.append({"pos": c + Vector2(240.0, -110.0), "radius": 22.0})

static func update_enemies(state: RVGameState, delta: float) -> void:
	var i: int = 0
	while i < state.enemies.size():
		var e: Dictionary = state.enemies[i]
		if float(e.get("hp", 0.0)) <= 0.0:
			i += 1; continue
		var role: String = str(e.get("role", "chaser"))
		var speed: float = float(e.get("speed", 72.0))
		if e.get("statuses", {}).has("freeze"): speed *= 0.25
		var to_player: Vector2 = state.player_pos - e.get("pos", Vector2.ZERO)
		var dist: float = to_player.length()
		var dir: Vector2 = Vector2.ZERO
		if dist > 0.01: dir = to_player / dist
		e["ai_cd"] = max(0.0, float(e.get("ai_cd", 0.0)) - delta)
		if role == "chaser" or role == "brute" or role == "elite" or role == "boss":
			e["pos"] += dir * speed * delta
			if dist <= float(e.get("radius", 16.0)) + state.player_radius + 5.0 and float(e.get("ai_cd", 0.0)) <= 0.0:
				player_damage(state, float(e.get("damage", 10.0)))
				if state.mode != "combat": return
				e["ai_cd"] = 0.65 if role != "boss" else 0.95
			if (role == "elite" or role == "boss") and float(e.get("ai_cd", 0.0)) <= 0.0 and dist < 170.0:
				state.zones.append({"enemy": true, "pos": e["pos"] + dir * 54.0, "radius": 58.0 if role == "boss" else 42.0, "time": 0.35, "duration": 0.35, "damage": float(e.get("damage", 12.0)), "tags": ["Physical", "Area"], "visual": "Slam", "triggered": false})
				e["ai_cd"] = 1.4
		elif role == "shooter":
			if dist < 260.0: e["pos"] -= dir * speed * 0.75 * delta
			elif dist > 380.0: e["pos"] += dir * speed * delta
			if float(e.get("ai_cd", 0.0)) <= 0.0:
				state.projectiles.append({"enemy": true, "pos": e["pos"] + dir * 18.0, "vel": dir * 330.0, "damage": float(e.get("damage", 9.0)), "radius": 8.0, "tags": ["Enemy"], "skill": "Enemy Shot", "life": 2.2, "hit_ids": {}})
				e["ai_cd"] = 1.35
		elif role == "spitter" or role == "caster":
			if dist > 230.0: e["pos"] += dir * speed * delta
			else: e["pos"] -= dir.rotated(0.7) * speed * 0.35 * delta
			if float(e.get("ai_cd", 0.0)) <= 0.0:
				var tags: Array = ["Void", "Area"] if role == "caster" else ["Fire", "Area"]
				state.zones.append({"enemy": true, "pos": state.player_pos, "radius": 58.0 if role == "caster" else 52.0, "time": 0.62, "duration": 0.72, "damage": float(e.get("damage", 10.0)) + 3.0, "tags": tags, "visual": "Enemy Area", "triggered": false})
				e["ai_cd"] = 1.65
		e["pos"].x = clamp(e["pos"].x, state.arena.position.x + float(e.get("radius", 16.0)), state.arena.end.x - float(e.get("radius", 16.0)))
		e["pos"].y = clamp(e["pos"].y, state.arena.position.y + float(e.get("radius", 16.0)), state.arena.end.y - float(e.get("radius", 16.0)))
		for ob in state.obstacles:
			e["pos"] = circle_obstacle_push(e["pos"], float(e.get("radius", 16.0)), ob)
		state.enemies[i] = e
		i += 1

static func update_projectiles(state: RVGameState, delta: float) -> void:
	for i in range(state.projectiles.size() - 1, -1, -1):
		var p: Dictionary = state.projectiles[i]
		p["life"] = float(p.get("life", 0.6)) - delta
		p["pos"] = p.get("pos", Vector2.ZERO) + p.get("vel", Vector2.RIGHT) * delta
		var remove: bool = float(p["life"]) <= 0.0 or not state.arena.grow(45.0).has_point(p["pos"])
		for ob in state.obstacles:
			if point_hits_obstacle(p["pos"], float(p.get("radius", 6.0)), ob): remove = true
		if bool(p.get("enemy", false)):
			if p["pos"].distance_to(state.player_pos) <= float(p.get("radius", 6.0)) + state.player_radius:
				player_damage(state, float(p.get("damage", 8.0)))
				remove = true
		else:
			for e_index in range(state.enemies.size()):
				var e: Dictionary = state.enemies[e_index]
				if float(e.get("hp", 0.0)) <= 0.0: continue
				var enemy_id: String = str(e.get("id", "enemy_" + str(e_index)))
				var hit_ids: Dictionary = p.get("hit_ids", {})
				if hit_ids.has(enemy_id): continue
				if p["pos"].distance_to(e.get("pos", Vector2.ZERO)) <= float(p.get("radius", 6.0)) + float(e.get("radius", 16.0)):
					hit_ids[enemy_id] = true
					p["hit_ids"] = hit_ids
					damage_enemy(state, e, float(p.get("damage", 10.0)), p.get("tags", []))
					state.enemies[e_index] = e
					remove = int(p.get("pierce", 0)) <= 0
					if not remove: p["pierce"] = int(p.get("pierce", 0)) - 1
					break
		if remove: state.projectiles.remove_at(i)
		else: state.projectiles[i] = p

static func update_zones(state: RVGameState, delta: float) -> void:
	for i in range(state.zones.size() - 1, -1, -1):
		var z: Dictionary = state.zones[i]
		z["time"] = float(z.get("time", 0.0)) - delta
		if float(z["time"]) <= 0.0 and not bool(z.get("triggered", false)):
			z["triggered"] = true
			if bool(z.get("enemy", false)):
				if state.player_pos.distance_to(z.get("pos", Vector2.ZERO)) <= float(z.get("radius", 40.0)) + state.player_radius: player_damage(state, float(z.get("damage", 8.0)))
			else:
				for e_index in range(state.enemies.size()):
					var e: Dictionary = state.enemies[e_index]
					if float(e.get("hp", 0.0)) > 0.0 and e.get("pos", Vector2.ZERO).distance_to(z.get("pos", Vector2.ZERO)) <= float(z.get("radius", 40.0)) + float(e.get("radius", 16.0)):
						damage_enemy(state, e, float(z.get("damage", 10.0)), z.get("tags", []))
						state.enemies[e_index] = e
		z["duration"] = float(z.get("duration", 0.0)) - delta
		if bool(z.get("triggered", false)) and float(z.get("duration", 0.0)) <= 0.0: state.zones.remove_at(i)
		else: state.zones[i] = z

static func damage_enemy(state: RVGameState, e: Dictionary, amount: float, tags: Array) -> void:
	e["hp"] = float(e.get("hp", 1.0)) - amount
	if tags.has("Cold") or tags.has("Freeze"): e["statuses"]["freeze"] = 0.8
	state.floating_text.append({"pos": e.get("pos", Vector2.ZERO) + Vector2(0.0, -22.0), "text": str(int(amount)), "life": 0.7, "color": Color(1.0, 0.86, 0.48)})

static func player_damage(state: RVGameState, amount: float) -> void:
	if state.invuln > 0.0: return
	state.player_hp -= amount
	state.invuln = 0.45
	if state.player_hp <= 0.0:
		state.deaths += 1
		state.enter_hub()
		state.add_notice("You died · returned to hub")

static func remove_dead_and_award(state: RVGameState) -> void:
	for i in range(state.enemies.size() - 1, -1, -1):
		if float(state.enemies[i].get("hp", 0.0)) <= 0.0:
			RVProgressionSystem.award_kill(state)
			state.enemies.remove_at(i)

static func circle_obstacle_push(pos: Vector2, radius: float, ob: Dictionary) -> Vector2:
	var center: Vector2 = ob.get("pos", Vector2.ZERO)
	var ob_radius: float = float(ob.get("radius", 24.0))
	var delta: Vector2 = pos - center
	var dist: float = delta.length()
	var min_dist: float = radius + ob_radius
	if dist < min_dist and dist > 0.001: pos += delta.normalized() * (min_dist - dist + 0.5)
	elif dist <= 0.001: pos += Vector2.RIGHT * (min_dist + 0.5)
	return pos

static func point_hits_obstacle(pos: Vector2, radius: float, ob: Dictionary) -> bool:
	return pos.distance_to(ob.get("pos", Vector2.ZERO)) <= radius + float(ob.get("radius", 24.0))
