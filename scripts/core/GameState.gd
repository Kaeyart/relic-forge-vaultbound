class_name RVGameState
extends RefCounted

const SAVE_VERSION: int = 19

var mode: String = "hub"
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var player_pos: Vector2 = Vector2.ZERO
var player_hp: float = 120.0
var player_mana: float = 100.0
var max_hp: float = 120.0
var max_mana: float = 100.0
var player_radius: float = 15.0
var invuln: float = 0.0

var level: int = 1
var xp: float = 0.0
var mastery_points: int = 0
var refund_points: int = 0
var gold: int = 0

var materials: Dictionary = {"embers": 12, "shards": 6, "runes": 0, "echo_glass": 0}

var available_skills: Array = ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"]
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
	"Fire Damage": 0,
	"Cold Damage": 0,
	"Lightning Damage": 0,
	"Void Damage": 0,
	"Melee Damage": 0,
	"Trap Damage": 0,
	"Maximum Life": 0,
	"Mana": 0
}

var equipped: Dictionary = {}
var backpack: Array = []
var stash: Array = []

var current_activity: Dictionary = {}
var run_depth: int = 0
var rooms_cleared: int = 0
var kills: int = 0
var deaths: int = 0

var prompt: String = ""
var notice: String = ""
var notice_time: float = 0.0
var panel_mode: String = ""

# Compatibility fields from earlier buildcraft patches.
var spirit_max: int = 30
var spirit_reserved: int = 0
var spirit_gems_enabled: Dictionary = {}
var passive_atlas_allocated: Array = ["center"]
var passive_atlas_refund_stack: Array = []
var build_stats: Dictionary = {}
var build_flags: Array = []
var skill_gem_sockets: Dictionary = {}
var support_gem_inventory: Dictionary = {}
var crafting_shards: Dictionary = {}
var glyph_counts: Dictionary = {}
var rune_counts: Dictionary = {}

func init() -> void:
	rng.randomize()
	if active_skills.size() == 0:
		active_skills = ["Fireball", "Cleave"]
	selected_skill = clamp(selected_skill, 0, max(0, active_skills.size() - 1))
	for skill in available_skills:
		if not skill_cooldowns.has(skill):
			skill_cooldowns[skill] = 0.0
		if not skill_ranks.has(skill):
			skill_ranks[skill] = 0
		if not skill_gem_sockets.has(skill):
			skill_gem_sockets[skill] = []
	recompute_stats()

func enter_hub() -> void:
	mode = "hub"
	current_activity = {}
	run_depth = 0
	panel_mode = ""
	full_restore()

func enter_combat(activity: Dictionary) -> void:
	mode = "combat"
	current_activity = activity.duplicate(true)
	run_depth = 1
	rooms_cleared = 0
	kills = 0
	panel_mode = ""
	full_restore()

func full_restore() -> void:
	recompute_stats()
	player_hp = max_hp
	player_mana = max_mana
	invuln = 0.0

func recompute_stats() -> void:
	max_hp = 120.0 + float(level - 1) * 5.0 + float(passives.get("Maximum Life", 0)) * 6.0
	max_mana = 100.0 + float(level - 1) * 2.0 + float(passives.get("Mana", 0)) * 4.0
	player_hp = min(player_hp, max_hp)
	player_mana = min(player_mana, max_mana)

func add_notice(text: String) -> void:
	notice = text
	notice_time = 2.4

func xp_to_next() -> float:
	return 160.0 + pow(float(level), 1.35) * 70.0

func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		mastery_points += 1
		refund_points += 1
		add_notice("Level Up: Passive Point gained")
	recompute_stats()

func to_save_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"level": level,
		"xp": xp,
		"mastery_points": mastery_points,
		"refund_points": refund_points,
		"gold": gold,
		"materials": materials,
		"active_skills": active_skills,
		"selected_skill": selected_skill,
		"skill_ranks": skill_ranks,
		"passives": passives,
		"equipped": equipped,
		"backpack": backpack,
		"stash": stash,
		"deaths": deaths,
		"spirit_max": spirit_max,
		"spirit_reserved": spirit_reserved,
		"spirit_gems_enabled": spirit_gems_enabled,
		"passive_atlas_allocated": passive_atlas_allocated,
		"passive_atlas_refund_stack": passive_atlas_refund_stack,
		"build_stats": build_stats,
		"build_flags": build_flags,
		"skill_gem_sockets": skill_gem_sockets,
		"support_gem_inventory": support_gem_inventory,
		"crafting_shards": crafting_shards,
		"glyph_counts": glyph_counts,
		"rune_counts": rune_counts
	}

func apply_save_dict(data: Dictionary) -> void:
	level = int(data.get("level", level))
	xp = float(data.get("xp", xp))
	mastery_points = int(data.get("mastery_points", mastery_points))
	refund_points = int(data.get("refund_points", refund_points))
	gold = int(data.get("gold", gold))
	if typeof(data.get("materials", {})) == TYPE_DICTIONARY:
		materials.merge(data.get("materials", {}), true)
	if typeof(data.get("active_skills", [])) == TYPE_ARRAY:
		active_skills = data.get("active_skills", active_skills)
	if active_skills.size() == 0:
		active_skills = ["Fireball", "Cleave"]
	selected_skill = clamp(int(data.get("selected_skill", selected_skill)), 0, max(0, active_skills.size() - 1))
	if typeof(data.get("skill_ranks", {})) == TYPE_DICTIONARY:
		skill_ranks.merge(data.get("skill_ranks", {}), true)
	if typeof(data.get("passives", {})) == TYPE_DICTIONARY:
		passives.merge(data.get("passives", {}), true)
	if typeof(data.get("equipped", {})) == TYPE_DICTIONARY:
		equipped = data.get("equipped", equipped)
	if typeof(data.get("backpack", [])) == TYPE_ARRAY:
		backpack = data.get("backpack", backpack)
	if typeof(data.get("stash", [])) == TYPE_ARRAY:
		stash = data.get("stash", stash)
	deaths = int(data.get("deaths", deaths))
	spirit_max = int(data.get("spirit_max", spirit_max))
	spirit_reserved = int(data.get("spirit_reserved", spirit_reserved))
	if typeof(data.get("spirit_gems_enabled", {})) == TYPE_DICTIONARY:
		spirit_gems_enabled = data.get("spirit_gems_enabled", spirit_gems_enabled)
	if typeof(data.get("passive_atlas_allocated", [])) == TYPE_ARRAY:
		passive_atlas_allocated = data.get("passive_atlas_allocated", passive_atlas_allocated)
	if typeof(data.get("passive_atlas_refund_stack", [])) == TYPE_ARRAY:
		passive_atlas_refund_stack = data.get("passive_atlas_refund_stack", passive_atlas_refund_stack)
	init()
