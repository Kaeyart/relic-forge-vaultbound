class_name RVCraftingCurrencyDB
extends RefCounted

const CURRENCIES: Dictionary = {
	"ash_temper": {
		"name": "Ash Temper",
		"short": "Temper",
		"verb": "Transmute",
		"description": "Upgrade a Normal equipment item into a Magic item.",
		"default": 18,
	},
	"vault_alchemy": {
		"name": "Vault Alchemy",
		"short": "Alchemy",
		"verb": "Alchemy",
		"description": "Upgrade a Normal equipment item into a Rare item.",
		"default": 8,
	},
	"regal_ember": {
		"name": "Regal Ember",
		"short": "Regal",
		"verb": "Regal",
		"description": "Upgrade a Magic equipment item into a Rare item while adding one affix.",
		"default": 6,
	},
	"chaos_crucible": {
		"name": "Chaos Crucible",
		"short": "Chaos",
		"verb": "Chaos",
		"description": "Reroll all explicit affixes on a Rare item.",
		"default": 5,
	},
	"exalted_shard": {
		"name": "Exalted Shard",
		"short": "Exalt",
		"verb": "Exalt",
		"description": "Add one random affix to a Rare item with an open affix slot.",
		"default": 3,
	},
	"scouring_ash": {
		"name": "Scouring Ash",
		"short": "Scour",
		"verb": "Scour",
		"description": "Remove explicit affixes and return an item to Normal rarity.",
		"default": 10,
	},
	"essence_brand": {
		"name": "Essence Brand",
		"short": "Essence",
		"verb": "Essence",
		"description": "Reroll an item as Rare while guaranteeing a themed affix.",
		"default": 4,
	},
	"forge_seal": {
		"name": "Forge Seal",
		"short": "Bench",
		"verb": "Bench Craft",
		"description": "Add one controlled crafted modifier if the item has room.",
		"default": 5,
	},
}

static func default_amount(currency_id: String) -> int:
	return int(Dictionary(CURRENCIES.get(currency_id, {})).get("default", 0))

static func display_name(currency_id: String) -> String:
	return str(Dictionary(CURRENCIES.get(currency_id, {})).get("name", currency_id.capitalize()))

static func short_name(currency_id: String) -> String:
	return str(Dictionary(CURRENCIES.get(currency_id, {})).get("short", display_name(currency_id)))

static func ordered_ids() -> Array[String]:
	return ["ash_temper", "vault_alchemy", "regal_ember", "chaos_crucible", "exalted_shard", "scouring_ash", "essence_brand", "forge_seal"]
