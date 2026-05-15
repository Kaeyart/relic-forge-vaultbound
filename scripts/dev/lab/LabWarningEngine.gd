class_name RVLabWarningEngine
extends RefCounted

static func evaluate_run(lab_state: RVLabCharacterState) -> Array:
	var warnings: Array = []
	var drops: int = max(1, lab_state.total_drops)
	var upgrade_rate: float = float(lab_state.upgrades) / float(drops)
	var confusing_rate: float = float(lab_state.confusing_items) / float(drops)
	var salvage_rate: float = float(lab_state.salvaged_items.size()) / float(drops)
	var coherence: Dictionary = RVLabBuildCoherenceEvaluator.evaluate(lab_state)
	var combat: Dictionary = RVLabCombatProxyEvaluator.evaluate(lab_state)
	if upgrade_rate < 0.035:
		warnings.append(_w("High", "Upgrade cadence is low for this journey. Loot may feel dry."))
	if lab_state.longest_dry_streak >= 8:
		warnings.append(_w("High", "Long dry streak detected: " + str(lab_state.longest_dry_streak) + " non-upgrade drops in a row."))
	if confusing_rate > 0.25:
		warnings.append(_w("Medium", "Too many confusing items. Affixes may mix unrelated identities."))
	if salvage_rate > 0.80:
		warnings.append(_w("Medium", "Salvage pressure is very high. Most loot is being discarded."))
	if float(coherence.get("coherence", 0.0)) < 0.50 and lab_state.equipment.size() >= 3:
		warnings.append(_w("High", "Build coherence is weak. Equipped items are not forming a clear identity."))
	if float(combat.get("mana_comfort", 100.0)) < 45.0:
		warnings.append(_w("Medium", "Mana/resource comfort is low. Supports or proc density may be too expensive."))
	if float(combat.get("visual_noise_risk", 0.0)) > 70.0:
		warnings.append(_w("Medium", "Visual noise risk is high. Proc/chain density may become unreadable."))
	return warnings

static func evaluate_aggregate(aggregate: Dictionary) -> Array:
	var warnings: Array = []
	var upgrade_rate: float = float(aggregate.get("upgrade_rate", 0.0))
	var useful_rate: float = float(aggregate.get("useful_keep_rate", 0.0))
	var confusing_rate: float = float(aggregate.get("confusing_rate", 0.0))
	if useful_rate >= 0.95:
		warnings.append(_w("Critical", "Useful rate is near 100%. Scoring or classification is too permissive."))
	if upgrade_rate < 0.03:
		warnings.append(_w("High", "Aggregate upgrade rate is low. Players may feel progression dries up."))
	if confusing_rate > 0.20:
		warnings.append(_w("Medium", "Aggregate confusing item rate is high. Loot may feel noisy."))
	return warnings

static func _w(severity: String, text: String) -> Dictionary:
	return {"severity": severity, "text": text}
