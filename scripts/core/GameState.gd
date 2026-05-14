class_name RVGameState
extends RefCounted

const SAVE_VERSION = 14

var mode: String = "hub"
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var arena: Rect2 = Rect2(60.0, 84.0, 1160.0, 566.0)
var hub_bounds: Rect2 = Rect2(80.0, 105.0, 1120.0, 525.0)

var player_pos: Vector2 = Vector2(640.0, 370.0)
var player_radius: float = 15.0
var player_speed: float = 235.0
var player_hp: float = 120.0
var player_mana: float = 100.0
var max_hp: float = 120.0
var max_mana: float = 100.0
var invuln: float = 0.0

var level: int = 1
var xp: float = 0.0
var mastery_points: int = 0
var gold: int = 0

var materials: Dictionary = {
	"embers": 12,
	"shards": 6,
	"runes": 0,
	"echo_glass": 0
}

var active_skills: Array = ["Fireball", "Cleave"]
var selected_skill: int = 0
var skill_cooldowns: Dictionary = {}
var skill_ranks: Dictionary = {
	"Fireball": 0,
	"Cleave": 0,
	"Frost Nova": 0,
	"Storm Lance": 0,
	"Void Rift": 0,
	"Blade Trap": 0
}

var passives: Dictionary = {
	"ash": 0,
	"frost": 0,
	"storm": 0,
	"void": 0,
	"steel": 0,
	"trap": 0,
	"blood": 0,
	"relic": 0
}

var equipped: Dictionary = {
	"weapon": {},
	"offhand": {},
	"head": {},
	"chest": {},
	"gloves": {},
	"boots": {},
	"amulet": {},
	"ring1": {},
	"ring2": {},
	"relic": {}
}

var backpack: Array = []
var stash: Array = []

var enemies: Array = []
var projectiles: Array = []
var zones: Array = []
var loot_drops: Array = []
var obstacles: Array = []
var floating_text: Array = []

var hub_objects: Array = []
var focused_object: Dictionary = {}
var prompt: String = ""
var notice: String = ""
var notice_time: float = 0.0

var current_contract: Dictionary = {}
var run_depth: int = 0
var rooms_cleared: int = 0
var kills: int = 0
var deaths: int = 0

func init() -> void:
	rng.randomize()

	if equipped["weapon"].is_empty():
		equipped["weapon"] = {
			"name": "Cracked Initiate Focus",
			"slot": "weapon",
			"rarity": "Starter",
			"stats": {"spell_damage": 0.04},
			"flags": [],
			"desc": "Starter focus."
		}

	for skill in active_skills:
		if not skill_cooldowns.has(skill):
			skill_cooldowns[skill] = 0.0

	recompute_stats()
	full_restore()


func reset_combat_runtime() -> void:
	enemies.clear()
	projectiles.clear()
	zones.clear()
	loot_drops.clear()
	obstacles.clear()
	floating_text.clear()
	kills = 0


func enter_hub() -> void:
	mode = "hub"
	player_pos = Vector2(640.0, 370.0)
	reset_combat_runtime()
	full_restore()
	focus_clear()


func full_restore() -> void:
	recompute_stats()
	player_hp = max_hp
	player_mana = max_mana
	invuln = 0.0


func recompute_stats() -> void:
	max_hp = 120.0 + float(level - 1) * 5.0
	max_mana = 100.0 + float(level - 1) * 2.0

	for slot in equipped.keys():
		var item: Variant = equipped[slot]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var stats: Dictionary = item.get("stats", {})
		max_hp += float(stats.get("max_hp", 0.0))
		max_mana += float(stats.get("max_mana", 0.0))

	max_hp += float(passives.get("steel", 0)) * 5.0
	max_hp += float(passives.get("blood", 0)) * 4.0
	max_mana += float(passives.get("void", 0)) * 3.0
	max_mana += float(passives.get("relic", 0)) * 2.0

	player_hp = min(player_hp, max_hp)
	player_mana = min(player_mana, max_mana)


func focus_clear() -> void:
	focused_object = {}
	prompt = ""


func add_notice(text: String) -> void:
	notice = text
	notice_time = 2.2


func xp_to_next() -> float:
	return 160.0 + pow(float(level), 1.35) * 70.0


func to_save_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"level": level,
		"xp": xp,
		"mastery_points": mastery_points,
		"gold": gold,
		"materials": materials,
		"active_skills": active_skills,
		"selected_skill": selected_skill,
		"skill_ranks": skill_ranks,
		"passives": passives,
		"equipped": equipped,
		"backpack": backpack,
		"stash": stash,
		"rooms_cleared": rooms_cleared,
		"kills": kills,
		"deaths": deaths
	}


func apply_save_dict(data: Dictionary) -> void:
	level = int(data.get("level", level))
	xp = float(data.get("xp", xp))
	mastery_points = int(data.get("mastery_points", mastery_points))
	gold = int(data.get("gold", gold))

	if typeof(data.get("materials", {})) == TYPE_DICTIONARY:
		materials.merge(data["materials"], true)

	if typeof(data.get("active_skills", [])) == TYPE_ARRAY:
		active_skills = data["active_skills"]

	selected_skill = int(data.get("selected_skill", selected_skill))

	if typeof(data.get("skill_ranks", {})) == TYPE_DICTIONARY:
		skill_ranks.merge(data["skill_ranks"], true)

	if typeof(data.get("passives", {})) == TYPE_DICTIONARY:
		passives.merge(data["passives"], true)

	if typeof(data.get("equipped", {})) == TYPE_DICTIONARY:
		equipped.merge(data["equipped"], true)

	if typeof(data.get("backpack", [])) == TYPE_ARRAY:
		backpack = data["backpack"]

	if typeof(data.get("stash", [])) == TYPE_ARRAY:
		stash = data["stash"]

	deaths = int(data.get("deaths", deaths))
	recompute_stats()
