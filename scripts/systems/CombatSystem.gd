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
	state.add_notice("Entered " + str(contract["name"]))


static func update(state: RVGameState, delta: float) -> void:
	update_projectiles(state, delta)
	update_zones(state, delta)
	update_enemies(state, delta)
	remove_dead_and_award(state)
	if state.enemies.size() == 0 and state.mode == "combat":
		RVProgressionSystem.award_room(state)
		state.run_depth += 1
		spawn_room(state)


static func spawn_room(state: RVGameState) -> void:
	state.enemies.clear(); state.projectiles.clear(); state.zones.clear(); state.obstacles.clear()
	var contract: Dictionary = state.current_contract
	var tier: int = int(contract.get("tier", 1))
	var threat: float = float(contract.get("threat", 1.0))
	var center: Vector2 = Vector2(640.0, 370.0)
	var count: int = 4 + tier * 2 + int(state.run_depth / 2)
	for i in range(count):
		var angle: float = TAU * float(i) / float(count)
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * (185.0 + float(i % 3) * 32.0)
		var enemy_type: String = "Ash Grunt"
		if tier >= 2 and i % 4 == 1: enemy_type = "Bone Archer"
		elif tier >= 2 and i % 4 == 2: enemy_type = "Cinder Spitter"
		elif tier >= 3 and i % 5 == 0: enemy_type = "Iron Brute"
		state.enemies.append(RVEnemyDB.make(enemy_type, pos, threat, i))
	state.obstacles.append({"pos": center + Vector2(-155.0, -45.0), "radius": 30.0})
	state.obstacles.append({"pos": center + Vector2(150.0, 45.0), "radius": 30.0})
	state.obstacles.append({"pos": center + Vector2(0.0, -155.0), "radius": 26.0})
	state.obstacles.append({"pos": center + Vector2(0.0, 155.0), "radius": 26.0})


static func update_enemies(state: RVGameState, delta: float) -> void:
	for i in range(state.enemies.size()):
		var e: Dictionary = state.enemies[i]
		if float(e["hp"]) <= 0.0: continue
		var role: String = str(e["role"])
		var speed: float = float(e["speed"])
		if e["statuses"].has("freeze"): speed *= 0.25
		var to_player: Vector2 = state.player_pos - e["pos"]
		var dist: float = to_player.length()
		var dir: Vector2 = Vector2.ZERO
		if dist > 0.01: dir = to_player / dist
		e["ai_cd"] = max(0.0, float(e["ai_cd"]) - delta)
		if role == "chaser":
			e["pos"] += dir * speed * delta; enemy_touch_player(state, e, dist)
		elif role == "shooter":
			if dist < 260.0: e["pos"] -= dir * speed * 0.75 * delta
			elif dist > 380.0: e["pos"] += dir * speed * delta
			if float(e["ai_cd"]) <= 0.0:
				state.projectiles.append({"enemy": true, "pos": e["pos"] + dir * 18.0, "vel": dir * 330.0, "damage": float(e["damage"]), "radius": 8.0, "tags": ["Enemy"], "skill": "Enemy Shot", "life": 2.2, "hit_ids": {}})
				e["ai_cd"] = 1.35
		elif role == "spitter":
			if dist > 230.0: e["pos"] += dir * speed * delta
			else: e["pos"] -= dir.rotated(0.7) * speed * 0.35 * delta
			if float(e["ai_cd"]) <= 0.0:
				state.zones.append({"enemy": true, "pos": state.player_pos, "radius": 52.0, "time": 0.55, "duration": 0.72, "damage": float(e["damage"]) + 3.0, "tags": ["Fire", "Area"], "visual": "Spit", "triggered": false})
				e["ai_cd"] = 1.7
		elif role == "brute":
			e["pos"] += dir * speed * delta; enemy_touch_player(state, e, dist)
		e["pos"].x = clamp(e["pos"].x, state.arena.position.x + float(e["radius"]), state.arena.end.x - float(e["radius"]))
		e["pos"].y = clamp(e["pos"].y, state.arena.position.y + float(e["radius"]), state.arena.end.y - float(e["radius"]))
		for ob in state.obstacles: e["pos"] = circle_obstacle_push(e["pos"], float(e["radius"]), ob)
		state.enemies[i] = e


static func enemy_touch_player(state: RVGameState, e: Dictionary, dist: float) -> void:
	if dist <= float(e["radius"]) + state.player_radius + 5.0 and float(e["ai_cd"]) <= 0.0:
		player_damage(state, float(e["damage"])); e["ai_cd"] = 0.65


static func update_projectiles(state: RVGameState, delta: float) -> void:
	for i in range(state.projectiles.size() - 1, -1, -1):
		var p: Dictionary = state.projectiles[i]
		p["life"] = float(p["life"]) - delta
		p["pos"] = p["pos"] + p["vel"] * delta
		var remove: bool = false
		if float(p["life"]) <= 0.0: remove = true
		elif not state.arena.grow(45.0).has_point(p["pos"]): remove = true
		for ob in state.obstacles:
			if point_hits_obstacle(p["pos"], float(p["radius"]), ob): remove = true
		if bool(p.get("enemy", false)):
			if p["pos"].distance_to(state.player_pos) <= float(p["radius"]) + state.player_radius:
				player_damage(state, float(p["damage"])); remove = true
		else:
			for e_index in range(state.enemies.size()):
				var e: Dictionary = state.enemies[e_index]
				if float(e["hp"]) <= 0.0: continue
				var enemy_id: String = str(e["id"])
				var hit_ids: Dictionary = p.get("hit_ids", {})
				if hit_ids.has(enemy_id): continue
				if p["pos"].distance_to(e["pos"]) <= float(p["radius"]) + float(e["radius"]):
					hit_ids[enemy_id] = true; p["hit_ids"] = hit_ids
					damage_enemy(state, e, float(p["damage"]), p.get("tags", [])); state.enemies[e_index] = e
					if int(p.get("pierce", 0)) <= 0: remove = true
					else: p["pierce"] = int(p["pierce"]) - 1
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
				if state.player_pos.distance_to(z["pos"]) <= float(z["radius"]) + state.player_radius: player_damage(state, float(z["damage"]))
			else:
				for e_index in range(state.enemies.size()):
					var e: Dictionary = state.enemies[e_index]
					if float(e["hp"]) <= 0.0: continue
					if e["pos"].distance_to(z["pos"]) <= float(z["radius"]) + float(e["radius"]):
						damage_enemy(state, e, float(z["damage"]), z.get("tags", [])); state.enemies[e_index] = e
		z["duration"] = float(z.get("duration", 0.0)) - delta
		if bool(z.get("triggered", false)) and float(z["duration"]) <= 0.0: state.zones.remove_at(i)
		else: state.zones[i] = z


static func damage_enemy(state: RVGameState, e: Dictionary, amount: float, tags: Array) -> void:
	e["hp"] = float(e["hp"]) - amount
	if tags.has("Cold") or tags.has("Freeze"): e["statuses"]["freeze"] = 0.8
	state.floating_text.append({"pos": e["pos"] + Vector2(0.0, -22.0), "text": str(int(amount)), "life": 0.7, "color": Color(1.0, 0.86, 0.48)})


static func player_damage(state: RVGameState, amount: float) -> void:
	if state.invuln > 0.0: return
	state.player_hp -= amount; state.invuln = 0.45; state.add_notice("-" + str(int(amount)) + " HP")
	if state.player_hp <= 0.0:
		state.deaths += 1; state.add_notice("You died. Returned to Forgehold."); state.enter_hub()


static func remove_dead_and_award(state: RVGameState) -> void:
	for i in range(state.enemies.size() - 1, -1, -1):
		var e: Dictionary = state.enemies[i]
		if float(e["hp"]) <= 0.0:
			RVProgressionSystem.award_kill(state); state.enemies.remove_at(i)


static func circle_obstacle_push(pos: Vector2, radius: float, ob: Dictionary) -> Vector2:
	var center: Vector2 = ob.get("pos", Vector2.ZERO); var ob_radius: float = float(ob.get("radius", 24.0))
	var delta: Vector2 = pos - center; var dist: float = delta.length(); var min_dist: float = radius + ob_radius
	if dist < min_dist and dist > 0.001: pos += delta.normalized() * (min_dist - dist + 0.5)
	elif dist <= 0.001: pos += Vector2.RIGHT * (min_dist + 0.5)
	return pos


static func point_hits_obstacle(pos: Vector2, radius: float, ob: Dictionary) -> bool:
	var center: Vector2 = ob.get("pos", Vector2.ZERO); var ob_radius: float = float(ob.get("radius", 24.0))
	return pos.distance_to(center) <= radius + ob_radius
