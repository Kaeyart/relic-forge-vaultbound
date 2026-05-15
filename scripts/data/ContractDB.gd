class_name RVContractDB
extends RefCounted

const ACTIVITIES: Array[Dictionary] = [
	{
		"id": "dungeon_run",
		"name": "Dungeon Run",
		"summary": "Clear rooms, earn general loot, return stronger.",
		"threat": 1.0,
		"rooms": 4,
		"reward": "Balanced loot"
	},
	{
		"id": "material_hunt",
		"name": "Material Hunt",
		"summary": "Fight weaker rooms for extra crafting materials.",
		"threat": 0.85,
		"rooms": 3,
		"reward": "Materials"
	},
	{
		"id": "elite_hunt",
		"name": "Elite Hunt",
		"summary": "Harder enemies, better item drops.",
		"threat": 1.35,
		"rooms": 4,
		"reward": "Rare items"
	},
	{
		"id": "boss_trial",
		"name": "Boss Trial",
		"summary": "Short run ending in a strong encounter.",
		"threat": 1.65,
		"rooms": 2,
		"reward": "High-value loot"
	},
	{
		"id": "endless_rift",
		"name": "Endless Rift",
		"summary": "Repeat rooms until you return or die.",
		"threat": 1.1,
		"rooms": 999,
		"reward": "Scaling rewards"
	}
]

static func all() -> Array[Dictionary]:
	return ACTIVITIES.duplicate(true)


static func by_id(activity_id: String) -> Dictionary:
	for activity: Dictionary in ACTIVITIES:
		if str(activity.get("id", "")) == activity_id:
			return activity.duplicate(true)
	return ACTIVITIES[0].duplicate(true)
