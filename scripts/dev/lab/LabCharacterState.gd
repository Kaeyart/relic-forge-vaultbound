class_name RVLabCharacterState
extends RefCounted

var profile: Dictionary = {}
var scenario: Dictionary = {}
var run_index: int = 0
var level: int = 1
var room_index: int = 0
var equipment: Dictionary = {}
var kept_items: Array = []
var salvaged_items: Array = []
var crafting_bases: Array = []
var skill_setup: Dictionary = {}
var timeline: Array = []
var decisions: Array = []
var warnings: Array = []
var dry_streak: int = 0
var longest_dry_streak: int = 0
var last_upgrade_room: int = 0
var total_drops: int = 0
var upgrades: int = 0
var useful_keeps: int = 0
var crafting_keeps: int = 0
var archetype_hits: int = 0
var confusing_items: int = 0
var ignored_items: int = 0
var material_rewards: int = 0
var gem_rewards: int = 0
var tag_hits: Dictionary = {}
var rarity_counts: Dictionary = {}
var slot_upgrades: Dictionary = {}
var combat_snapshots: Array = []

func setup(p_profile: Dictionary, p_scenario: Dictionary, p_run_index: int) -> void:
	profile = p_profile.duplicate(true)
	scenario = p_scenario.duplicate(true)
	run_index = p_run_index
	level = int(scenario.get("start_level", 1))
	room_index = 0
	equipment.clear()
	kept_items.clear()
	salvaged_items.clear()
	crafting_bases.clear()
	timeline.clear()
	decisions.clear()
	warnings.clear()
	tag_hits.clear()
	rarity_counts.clear()
	slot_upgrades.clear()
	combat_snapshots.clear()
	dry_streak = 0
	longest_dry_streak = 0
	last_upgrade_room = 0
	total_drops = 0
	upgrades = 0
	useful_keeps = 0
	crafting_keeps = 0
	archetype_hits = 0
	confusing_items = 0
	ignored_items = 0
	material_rewards = 0
	gem_rewards = 0

func add_timeline(kind: String, text: String, data: Dictionary = {}) -> void:
	timeline.append({"room": room_index, "kind": kind, "text": text, "data": data.duplicate(true)})

func add_decision(decision: Dictionary) -> void:
	decisions.append(decision.duplicate(true))

func add_warning(text: String, severity: String = "Medium") -> void:
	warnings.append({"severity": severity, "text": text, "room": room_index})

func hit_tags(tags: Array) -> void:
	for tag in tags:
		var key: String = str(tag)
		tag_hits[key] = int(tag_hits.get(key, 0)) + 1

func count_rarity(rarity: String) -> void:
	rarity_counts[rarity] = int(rarity_counts.get(rarity, 0)) + 1

func register_upgrade(slot_name: String) -> void:
	upgrades += 1
	dry_streak = 0
	last_upgrade_room = room_index
	slot_upgrades[slot_name] = int(slot_upgrades.get(slot_name, 0)) + 1

func register_non_upgrade() -> void:
	dry_streak += 1
	longest_dry_streak = max(longest_dry_streak, dry_streak)
