class_name RVLabProfileDB
extends RefCounted

static func known_profile_files() -> Array[String]:
	return [
		"res://data/dev/lab/profiles/new_player.json",
		"res://data/dev/lab/profiles/fireball_ignite.json",
		"res://data/dev/lab/profiles/melee_crit.json",
		"res://data/dev/lab/profiles/void_trapper.json",
		"res://data/dev/lab/profiles/crafter_optimizer.json",
		"res://data/dev/lab/profiles/unique_hunter.json",
		"res://data/dev/lab/profiles/wiki_goblin.json"
	]

static func load_profiles() -> Array:
	var profiles: Array = []
	for path in known_profile_files():
		if FileAccess.file_exists(path):
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file != null:
				var parsed = JSON.parse_string(file.get_as_text())
				file.close()
				if typeof(parsed) == TYPE_DICTIONARY:
					profiles.append(parsed)
	if profiles.is_empty():
		profiles = default_profiles()
	return profiles

static func get_profile(profile_id: String) -> Dictionary:
	for profile in load_profiles():
		if str(profile.get("id", "")) == profile_id:
			return profile
	var defaults: Array = default_profiles()
	for profile in defaults:
		if str(profile.get("id", "")) == profile_id:
			return profile
	return defaults[0]

static func profile_ids() -> Array[String]:
	var ids: Array[String] = []
	for profile in load_profiles():
		ids.append(str(profile.get("id", "unknown")))
	return ids

static func default_profiles() -> Array:
	return [
		{
			"id": "new_player",
			"name": "New Player",
			"description": "Equips obvious upgrades and overvalues simple rarity, life, damage, and armor.",
			"preferred_skills": {"Fireball": 4, "Cleave": 4, "Frost Nova": 2},
			"wanted_tags": {"Life": 7, "Armor": 6, "Damage": 5, "Fire": 3, "Physical": 3, "Mana": 3},
			"unwanted_tags": {},
			"decision_style": {"upgrade_threshold": 1.08, "complexity_tolerance": 0.20, "risk_tolerance": 0.10, "crafting_aggression": 0.15, "unique_curiosity": 0.45, "salvage_aggression": 0.40, "keeps_high_potential_bases": false},
			"mistake_model": {"overvalues_raw_damage": true, "undervalues_forge_potential": true, "misses_subtle_synergies": true}
		},
		{
			"id": "fireball_ignite",
			"name": "Fireball Ignite Player",
			"description": "Wants Fireball, Fire, Spell, Projectile, Area, Burn, Mana, and safe support scaling.",
			"preferred_skills": {"Fireball": 10, "Frost Nova": 2, "Storm Lance": 1, "Cleave": -4, "Blade Trap": -4},
			"wanted_tags": {"Fire": 10, "Spell": 8, "Projectile": 6, "Area": 5, "Burn": 10, "Mana": 5, "Cooldown": 3, "Life": 2},
			"unwanted_tags": {"Trap": -6, "Physical": -4, "Cold": -2, "Void": -2},
			"decision_style": {"upgrade_threshold": 1.12, "complexity_tolerance": 0.35, "risk_tolerance": 0.25, "crafting_aggression": 0.35, "unique_curiosity": 0.40, "salvage_aggression": 0.55, "keeps_high_potential_bases": true}
		},
		{
			"id": "melee_crit",
			"name": "Melee Crit Player",
			"description": "Wants weapon power, Physical damage, Crit, Attack, Life, Armor, and direct melee scaling.",
			"preferred_skills": {"Cleave": 10, "Fireball": -4, "Blade Trap": 1},
			"wanted_tags": {"Physical": 10, "Melee": 9, "Critical": 8, "Attack": 6, "Life": 6, "Armor": 5, "Bleed": 5},
			"unwanted_tags": {"Spell": -6, "Mana": -2, "Trap": -2},
			"decision_style": {"upgrade_threshold": 1.10, "complexity_tolerance": 0.30, "risk_tolerance": 0.30, "crafting_aggression": 0.30, "unique_curiosity": 0.35, "salvage_aggression": 0.50, "keeps_high_potential_bases": true}
		},
		{
			"id": "void_trapper",
			"name": "Void Trapper",
			"description": "Wants Blade Trap, Void Rift, Trap, Void, Curse, Area control, Cooldown, and proc chains.",
			"preferred_skills": {"Blade Trap": 10, "Void Rift": 9, "Fireball": -3, "Cleave": -4},
			"wanted_tags": {"Void": 10, "Trap": 10, "Curse": 8, "Area": 6, "Cooldown": 7, "Proc": 8, "Chain": 5, "Life": 3},
			"unwanted_tags": {"Physical": -3, "Fire": -2, "Melee": -5},
			"decision_style": {"upgrade_threshold": 1.13, "complexity_tolerance": 0.65, "risk_tolerance": 0.45, "crafting_aggression": 0.55, "unique_curiosity": 0.70, "salvage_aggression": 0.60, "keeps_high_potential_bases": true}
		},
		{
			"id": "crafter_optimizer",
			"name": "Crafting Optimizer",
			"description": "Keeps ugly high-potential bases and values affix pools, open slots, and salvage material routing.",
			"preferred_skills": {},
			"wanted_tags": {"Forge Potential": 10, "Open Prefix": 6, "Open Suffix": 6, "Life": 3, "Mana": 3, "Unique": 4},
			"unwanted_tags": {},
			"decision_style": {"upgrade_threshold": 1.18, "complexity_tolerance": 0.90, "risk_tolerance": 0.55, "crafting_aggression": 0.90, "unique_curiosity": 0.50, "salvage_aggression": 0.30, "keeps_high_potential_bases": true}
		},
		{
			"id": "unique_hunter",
			"name": "Unique Hunter",
			"description": "Ignores most stat sticks and hunts for conversion, proc, and archetype-enabling uniques.",
			"preferred_skills": {},
			"wanted_tags": {"Unique": 14, "Conversion": 12, "Proc": 10, "Chain": 8, "Spirit": 6, "Skill": 7},
			"unwanted_tags": {},
			"decision_style": {"upgrade_threshold": 1.25, "complexity_tolerance": 0.80, "risk_tolerance": 0.70, "crafting_aggression": 0.20, "unique_curiosity": 1.0, "salvage_aggression": 0.70, "keeps_high_potential_bases": false}
		},
		{
			"id": "wiki_goblin",
			"name": "Wiki Goblin / 10,000 Hour Player",
			"description": "Exploits hidden synergy, keeps speculative bases, and values weird interaction density over obvious stats.",
			"preferred_skills": {},
			"wanted_tags": {"Proc": 12, "Conversion": 12, "Cooldown": 8, "Chain": 8, "Spirit": 7, "Unique": 8, "Forge Potential": 8, "Mana": 5, "Area": 5},
			"unwanted_tags": {},
			"decision_style": {"upgrade_threshold": 1.20, "complexity_tolerance": 1.0, "risk_tolerance": 0.85, "crafting_aggression": 0.85, "unique_curiosity": 0.95, "salvage_aggression": 0.35, "keeps_high_potential_bases": true}
		}
	]
