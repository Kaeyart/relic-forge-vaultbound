extends RVUIPanelBase

func refresh(state: Object) -> void:
	super.refresh(state)
	var allocated: Array = _arr(state, "passive_atlas_allocated")
	var stats: Dictionary = _dict(state, "build_stats")
	var flags: Array = _arr(state, "build_flags")
	var points: int = _int(state, "mastery_points", 0)
	var refunds: int = _int(state, "refund_points", 0)
	var text: String = "PASSIVE ATLAS\n\nAvailable Points: " + str(points) + "\nRefund Points: " + str(refunds) + "\nAllocated Nodes: " + str(allocated.size()) + "\n\n"
	for node_id in allocated:
		text += "- " + str(node_id).replace("_", " ").capitalize() + "\n"
	var detail: String = "BUILD SUMMARY\n\nStats\n"
	for key in stats.keys():
		detail += "- " + str(key).replace("_", " ").capitalize() + ": " + str(stats[key]) + "\n"
	detail += "\nFlags\n"
	for flag in flags:
		detail += "- " + str(flag).replace("_", " ").capitalize() + "\n"
	if flags.size() == 0:
		detail += "No build flags yet.\n"
	_set_rich_text("Body", text)
	_set_rich_text("Detail", detail)
