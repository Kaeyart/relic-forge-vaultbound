class_name RVBuildcraftSystem
extends RefCounted

static func handle_key(state: RVGameState, keycode: int) -> bool:
	if state.panel_mode == "":
		return false
	match state.panel_mode:
		"inventory":
			return handle_inventory_key(state, keycode)
		"crafting":
			return handle_crafting_key(state, keycode)
		"passive_atlas":
			return handle_passive_key(state, keycode)
		"skill_gems":
			return handle_skill_gem_key(state, keycode)
		"stash":
			return handle_stash_key(state, keycode)
	return false

static func handle_inventory_key(state: RVGameState, keycode: int) -> bool:
	if keycode == KEY_E:
		RVInventorySystem.equip_selected_backpack_item(state)
		return true
	if keycode == KEY_X:
		RVInventorySystem.salvage_selected_backpack_item(state)
		return true
	return false

static func handle_crafting_key(state: RVGameState, keycode: int) -> bool:
	if RVCraftingCurrencySystem.handle_crafting_key(state, keycode):
		return true
	match keycode:
		KEY_F:
			state.backpack.append(RVItemDB.craft_basic_item(state))
			state.add_notice("Crafted basic item")
			return true
		KEY_A:
			return RVForgecraftSystem.add_prefix(state)
		KEY_S:
			return RVForgecraftSystem.add_suffix(state)
		KEY_U:
			return RVForgecraftSystem.upgrade_affix(state)
		KEY_R:
			return RVForgecraftSystem.reroll_affix(state)
		KEY_DELETE, KEY_BACKSPACE:
			return RVForgecraftSystem.remove_affix(state)
		KEY_L:
			return RVForgecraftSystem.seal_affix(state)
		KEY_X:
			return RVForgecraftSystem.shatter_selected_item(state)
	return false

static func handle_passive_key(state: RVGameState, keycode: int) -> bool:
	if keycode >= KEY_0 and keycode <= KEY_9:
		var slot_index: int = 9 if keycode == KEY_0 else keycode - KEY_1
		RVSaveSystem.save(state)
		RVSaveSystem.select_slot_and_load(state, slot_index)
		state.add_notice("Loaded character slot " + str(slot_index + 1))
		return true
	return RVClassAscendancySystem.handle_panel_key(state, keycode)

static func handle_skill_gem_key(state: RVGameState, keycode: int) -> bool:
	return RVSkillGemSystem.handle_panel_key(state, keycode)

static func handle_stash_key(state: RVGameState, keycode: int) -> bool:
	if keycode == KEY_E:
		RVInventorySystem.deposit_all_backpack(state)
		return true
	if keycode == KEY_X:
		RVInventorySystem.withdraw_selected_stash_item(state)
		return true
	return false
