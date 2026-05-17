class_name RVCombatAudioProxySystem
extends RefCounted

# Patch 068 companion: intentionally tiny audio placeholder API.
# Kept dormant by default until real audio assets exist. Calls are safe no-ops.

static func play_event(_root: Node, _event_id: String, _strength: float = 1.0) -> void:
	# Future hook for generated WAVs or AudioStreamPlayer2D nodes.
	pass
