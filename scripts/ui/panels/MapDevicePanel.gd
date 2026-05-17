class_name RVMapDevicePanel
extends Control

@export var card_frame_common: Texture2D
@export var card_frame_magic: Texture2D
@export var card_frame_rare: Texture2D
@export var card_frame_unique: Texture2D
@export var map_icon_default: Texture2D
@export var map_icon_ash_cistern: Texture2D
@export var map_icon_iron_catacomb: Texture2D
@export var map_icon_forgeworks: Texture2D
@export var map_icon_bastion: Texture2D
@export var map_icon_sanctum: Texture2D
@export var map_icon_depths: Texture2D
@export var map_icon_aqueducts: Texture2D
@export var map_icon_vault: Texture2D
@export var map_icon_stronghold: Texture2D
@export var map_icon_ossuary: Texture2D
@export var reward_icon_currency: Texture2D
@export var reward_icon_skill_gem: Texture2D
@export var reward_icon_crafting_shards: Texture2D
@export var reward_icon_boss_loot: Texture2D
@export var reward_icon_maps: Texture2D
@export var reward_icon_completion: Texture2D

@onready var title_label: Label = get_node_or_null("%TitleLabel") as Label
@onready var close_button: Button = get_node_or_null("%CloseButton") as Button

@onready var map_card_frame_art: TextureRect = get_node_or_null("%MapCardFrameArt") as TextureRect
@onready var map_slot_empty_art: TextureRect = get_node_or_null("%MapSlotEmptyArt") as TextureRect
@onready var map_card_placeholder_art: TextureRect = get_node_or_null("%MapCardPlaceholderArt") as TextureRect
@onready var map_icon_art: TextureRect = get_node_or_null("%MapIconArt") as TextureRect
@onready var completed_badge_art: TextureRect = get_node_or_null("%CompletedBadgeArt") as TextureRect
@onready var tier_badge_art: TextureRect = get_node_or_null("%TierBadgeArt") as TextureRect

@onready var map_tier_label: Label = get_node_or_null("%MapTierLabel") as Label
@onready var map_name_label: Label = get_node_or_null("%MapNameLabel") as Label
@onready var map_subtitle_label: Label = get_node_or_null("%MapSubtitleLabel") as Label
@onready var empty_state_label: Label = get_node_or_null("%EmptyStateLabel") as Label

@onready var remove_map_button: Button = get_node_or_null("%RemoveMapButton") as Button
@onready var open_stash_button: Button = get_node_or_null("%OpenStashButton") as Button

@onready var map_tier_filter_label: Label = get_node_or_null("%MapTierFilterLabel") as Label
@onready var map_stored_list_label: Label = get_node_or_null("%MapStoredListLabel") as Label
@onready var backpack_maps_label: Label = get_node_or_null("%BackpackMapsLabel") as Label

@onready var tier_value_label: Label = get_node_or_null("%TierValueLabel") as Label
@onready var item_level_value_label: Label = get_node_or_null("%ItemLevelValueLabel") as Label
@onready var map_type_value_label: Label = get_node_or_null("%MapTypeValueLabel") as Label
@onready var size_value_label: Label = get_node_or_null("%SizeValueLabel") as Label
@onready var quality_value_label: Label = get_node_or_null("%QualityValueLabel") as Label

@onready var modifier_count_label: Label = get_node_or_null("%ModifierCountLabel") as Label
@onready var modifiers_list: VBoxContainer = get_node_or_null("%ModifiersList") as VBoxContainer

@onready var rewards_hint_label: Label = get_node_or_null("%RewardsHintLabel") as Label
@onready var scarabs_button: Button = get_node_or_null("%ScarabsButton") as Button
@onready var atlas_passives_button: Button = get_node_or_null("%AtlasPassivesButton") as Button
@onready var activate_map_button: Button = get_node_or_null("%ActivateMapButton") as Button
@onready var quick_clear_button: Button = get_node_or_null("%QuickClearButton") as Button
@onready var footer_close_button: Button = get_node_or_null("%FooterCloseButton") as Button

var current_state: RVGameState = null
var reward_icons: Array[TextureRect] = []

func _ready() -> void:
	visible = false
	reward_icons = [
		get_node_or_null("%RewardIcon1") as TextureRect,
		get_node_or_null("%RewardIcon2") as TextureRect,
		get_node_or_null("%RewardIcon3") as TextureRect,
		get_node_or_null("%RewardIcon4") as TextureRect,
		get_node_or_null("%RewardIcon5") as TextureRect,
		get_node_or_null("%RewardIcon6") as TextureRect,
	]
	_bind_button(close_button, _on_close_pressed)
	_bind_button(footer_close_button, _on_close_pressed)
	_bind_button(activate_map_button, _on_activate_map_pressed)
	_bind_button(open_stash_button, _on_store_maps_pressed)
	_bind_button(remove_map_button, _on_withdraw_map_pressed)
	_bind_button(scarabs_button, _on_scarabs_pressed)
	_bind_button(atlas_passives_button, _on_atlas_passives_pressed)
	_bind_button(quick_clear_button, _on_quick_clear_pressed)
	if open_stash_button != null:
		open_stash_button.text = "STORE MAPS"
	if remove_map_button != null:
		remove_map_button.text = "WITHDRAW MAP"
	_apply_static_reward_icons(false)

func update_from_state(state: RVGameState) -> void:
	current_state = state
	RVMapSystem.ensure_defaults(state)
	if title_label != null:
		title_label.text = "MAP DEVICE"
	_render_map_tab(state)
	var map_item: Dictionary = RVMapSystem.selected_map_item(state)
	if map_item.is_empty():
		_render_empty_state()
	else:
		_render_map_state(state, map_item)

func _render_map_tab(state: RVGameState) -> void:
	_set_label(map_tier_filter_label, RVMapSystem.tier_filter_text(state).to_upper())
	_set_label(map_stored_list_label, _compact_map_tab_text(state))
	_set_label(backpack_maps_label, "Backpack maps: " + str(_count_backpack_maps(state)) + " · M / Store Maps deposits them")

func _compact_map_tab_text(state: RVGameState) -> String:
	var lines: Array[String] = []
	var indices: Array = RVMapSystem.filtered_map_indices(state)
	if indices.is_empty():
		return "No stored maps for this tier filter.\nPress G to generate a dev map drop.\nPress M to store backpack maps."
	for local_i: int in range(min(indices.size(), 6)):
		var index: int = int(indices[local_i])
		var item: Dictionary = Dictionary(state.map_stash[index])
		var marker: String = "> " if index == state.map_cursor else "  "
		var done: String = "✓" if RVMapSystem.is_map_completed(state, item) else "□"
		lines.append(marker + done + " T" + str(item.get("tier", 1)) + "  " + str(item.get("name", "Map")))
	if indices.size() > 6:
		lines.append("  … " + str(indices.size() - 6) + " more stored maps")
	return "\n".join(lines)

func _render_empty_state() -> void:
	_set_label(map_tier_label, "TIER —")
	_set_label(map_name_label, "No Map Selected")
	_set_label(map_subtitle_label, "Store a physical map item in the Map Tab")
	_set_label(empty_state_label, "Maps drop into the backpack first. Store them in the Map Tab to run them.")
	_set_label(tier_value_label, "—")
	_set_label(item_level_value_label, "—")
	_set_label(map_type_value_label, "—")
	_set_label(size_value_label, "—")
	_set_label(quality_value_label, "—")
	_set_texture(map_card_frame_art, card_frame_common)
	_set_visible(map_card_frame_art, false)
	_set_visible(map_slot_empty_art, true)
	_set_visible(map_card_placeholder_art, false)
	_set_visible(map_icon_art, false)
	_set_visible(completed_badge_art, false)
	_set_visible(tier_badge_art, false)
	_clear_modifier_rows()
	_add_modifier_row("No stored map selected", "EMPTY", Color(0.45, 0.40, 0.34, 1.0))
	_set_label(modifier_count_label, "0 MODIFIERS")
	_set_label(rewards_hint_label, "Completion is tracked per map base and tier after boss clear.")
	_set_buttons_for_loaded(false)
	_apply_static_reward_icons(false)

func _render_map_state(state: RVGameState, map_item: Dictionary) -> void:
	var tier: int = int(map_item.get("tier", 1))
	var map_level: int = int(map_item.get("map_level", 1))
	var rarity: String = str(map_item.get("rarity", "Normal"))
	var area_name: String = str(map_item.get("area_name", "Unknown Area"))
	var boss_name: String = str(map_item.get("boss_name", "Map Boss"))
	var pack_size: float = float(map_item.get("pack_size", 1.0))
	var quality_percent: int = int(round(max(0.0, pack_size - 1.0) * 100.0))
	var threat: float = float(map_item.get("threat", 1.0))
	var map_size: String = _map_size_name(int(map_item.get("rooms", 1)), pack_size)
	var completed: bool = RVMapSystem.is_map_completed(state, map_item)
	_set_label(map_tier_label, "T" + str(tier))
	_set_label(map_name_label, str(map_item.get("name", "Map")))
	_set_label(map_subtitle_label, rarity + " • " + area_name)
	_set_label(empty_state_label, "Boss: " + boss_name + "  •  Threat: " + str(snappedf(threat, 0.01)))
	_set_texture(map_card_frame_art, _card_frame_for_rarity(rarity))
	_set_visible(map_card_frame_art, true)
	_set_texture(map_icon_art, _map_icon_for(map_item))
	_set_visible(map_slot_empty_art, false)
	_set_visible(map_card_placeholder_art, true)
	_set_visible(map_icon_art, true)
	_set_visible(completed_badge_art, completed)
	_set_visible(tier_badge_art, true)
	_set_label(tier_value_label, str(tier))
	_set_label(item_level_value_label, str(map_level))
	_set_label(map_type_value_label, area_name)
	_set_label(size_value_label, map_size)
	_set_label(quality_value_label, "+" + str(quality_percent) + "%")
	_render_modifiers(Array(map_item.get("mods", [])))
	_set_label(rewards_hint_label, _reward_hint_for(map_item, completed))
	_apply_static_reward_icons(true)
	_set_buttons_for_loaded(true)

func _render_modifiers(mods: Array) -> void:
	_clear_modifier_rows()
	if mods.is_empty():
		_add_modifier_row("No explicit modifiers", "NORMAL", Color(0.50, 0.45, 0.36, 1.0))
		_set_label(modifier_count_label, "0 MODIFIERS")
		return
	for i: int in range(mods.size()):
		_add_modifier_row(str(mods[i]), _tag_for_modifier(str(mods[i])), _modifier_color(i))
	_set_label(modifier_count_label, str(mods.size()) + " MODIFIERS")

func _clear_modifier_rows() -> void:
	if modifiers_list == null:
		return
	for child: Node in modifiers_list.get_children():
		child.queue_free()

func _add_modifier_row(text: String, tag: String, icon_color: Color) -> void:
	if modifiers_list == null:
		return
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 28.0)
	row.add_theme_constant_override("separation", 8)
	var icon: ColorRect = ColorRect.new()
	icon.custom_minimum_size = Vector2(18.0, 18.0)
	icon.color = icon_color
	row.add_child(icon)
	var text_label: Label = Label.new()
	text_label.text = text
	text_label.clip_text = true
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.74, 1.0))
	row.add_child(text_label)
	var tag_label: Label = Label.new()
	tag_label.text = tag
	tag_label.custom_minimum_size = Vector2(96.0, 0.0)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag_label.add_theme_color_override("font_color", icon_color.lightened(0.25))
	row.add_child(tag_label)
	modifiers_list.add_child(row)

func _apply_static_reward_icons(has_map: bool) -> void:
	var textures: Array[Texture2D] = [
		reward_icon_currency,
		reward_icon_skill_gem,
		reward_icon_crafting_shards,
		reward_icon_boss_loot,
		reward_icon_maps,
		reward_icon_completion,
	]
	var hints: Array[String] = ["Currency", "Skill Gems", "Crafting Shards", "Boss Loot", "Maps", "Completion"]
	for i: int in range(reward_icons.size()):
		var icon: TextureRect = reward_icons[i]
		if icon == null:
			continue
		icon.visible = has_map
		icon.texture = textures[i] if i < textures.size() else null
		icon.tooltip_text = hints[i] if i < hints.size() else "Reward"

func _set_buttons_for_loaded(has_map: bool) -> void:
	if activate_map_button != null:
		activate_map_button.disabled = not has_map
	if remove_map_button != null:
		remove_map_button.disabled = not has_map
	if quick_clear_button != null:
		quick_clear_button.disabled = not has_map

func _bind_button(button: Button, callback: Callable) -> void:
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _on_activate_map_pressed() -> void:
	if current_state == null:
		return
	RVMapSystem.prepare_selected_map_activity(current_state)

func _on_store_maps_pressed() -> void:
	if current_state == null:
		return
	RVMapSystem.deposit_all_maps_from_backpack_to_map_stash(current_state)
	update_from_state(current_state)

func _on_withdraw_map_pressed() -> void:
	if current_state == null:
		return
	RVMapSystem.withdraw_selected_map_to_backpack(current_state)
	update_from_state(current_state)

func _on_scarabs_pressed() -> void:
	if current_state == null:
		return
	current_state.add_notice("Scarab socket UI is reserved for a later map-device pass")

func _on_atlas_passives_pressed() -> void:
	if current_state == null:
		return
	current_state.panel_mode = "passive_atlas"

func _on_quick_clear_pressed() -> void:
	if current_state == null:
		return
	current_state.add_notice(RVMapSystem.completion_summary_text(current_state))

func _on_close_pressed() -> void:
	if current_state != null:
		current_state.panel_mode = ""
	visible = false

func _set_label(label: Label, text: String) -> void:
	if label != null:
		label.text = text

func _set_texture(rect: TextureRect, texture: Texture2D) -> void:
	if rect != null:
		rect.texture = texture

func _set_visible(control: CanvasItem, next_visible: bool) -> void:
	if control != null:
		control.visible = next_visible

func _card_frame_for_rarity(rarity: String) -> Texture2D:
	match rarity.to_lower():
		"unique":
			return card_frame_unique
		"rare":
			return card_frame_rare
		"magic":
			return card_frame_magic
		_:
			return card_frame_common

func _map_icon_for(map_item: Dictionary) -> Texture2D:
	var tokens: Array[String] = [
		str(map_item.get("id", "")),
		str(map_item.get("area_name", "")),
		str(map_item.get("name", "")),
	]
	var key: String = " ".join(tokens).to_lower()
	if key.contains("ash") or key.contains("cistern"):
		return map_icon_ash_cistern
	if key.contains("iron") or key.contains("catacomb"):
		return map_icon_iron_catacomb
	if key.contains("forge"):
		return map_icon_forgeworks
	if key.contains("bastion"):
		return map_icon_bastion
	if key.contains("sanctum"):
		return map_icon_sanctum
	if key.contains("depth"):
		return map_icon_depths
	if key.contains("aqua") or key.contains("duct"):
		return map_icon_aqueducts
	if key.contains("vault"):
		return map_icon_vault
	if key.contains("stronghold"):
		return map_icon_stronghold
	if key.contains("ossuary"):
		return map_icon_ossuary
	return map_icon_default

func _modifier_color(index: int) -> Color:
	var colors: Array[Color] = [
		Color(0.72, 0.19, 0.12, 1.0),
		Color(0.82, 0.48, 0.14, 1.0),
		Color(0.28, 0.48, 0.86, 1.0),
		Color(0.55, 0.25, 0.82, 1.0),
		Color(0.76, 0.62, 0.25, 1.0),
	]
	return colors[index % colors.size()]

func _tag_for_modifier(mod_text: String) -> String:
	var lower: String = mod_text.to_lower()
	if lower.contains("rare") or lower.contains("boss"):
		return "REWARD"
	if lower.contains("fire") or lower.contains("void") or lower.contains("caster"):
		return "HAZARD"
	if lower.contains("pack") or lower.contains("armored") or lower.contains("pressure"):
		return "MONSTER"
	return "MOD"

func _map_size_name(rooms: int, pack_size: float) -> String:
	if rooms >= 3 or pack_size >= 1.25:
		return "Large"
	if rooms <= 1 and pack_size < 1.10:
		return "Compact"
	return "Medium"

func _reward_hint_for(map_item: Dictionary, completed: bool) -> String:
	var rarity: String = str(map_item.get("rarity", "Normal"))
	var tier: int = int(map_item.get("tier", 1))
	var boss: String = str(map_item.get("boss_name", "Map Boss"))
	var completion: String = "completed" if completed else "not completed"
	return "Tier " + str(tier) + " " + rarity + " map · " + completion + " · Boss: " + boss + "."

func _count_backpack_maps(state: RVGameState) -> int:
	var count: int = 0
	for value: Variant in state.backpack:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = Dictionary(value)
		if bool(item.get("map_item", false)) or str(item.get("item_type", "")) == "map" or str(item.get("category", "")) == "map" or item.has("map_level") and item.has("tier") and item.has("boss_name"):
			count += 1
	return count
