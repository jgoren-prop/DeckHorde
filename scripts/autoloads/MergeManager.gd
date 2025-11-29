extends Node
## MergeManager - Triple-merge card upgrade system
## MINIMAL STUB for testing - will be expanded later

signal merge_available(card_id: String, current_tier: int)
signal merge_completed(card_id: String, new_tier: int)
signal merge_declined(card_id: String, tier: int)

const MAX_TIER: int = 3


func _ready() -> void:
	print("[MergeManager] Initialized")


func check_for_merges() -> Array:
	return []


func execute_merge(card_id: String, current_tier: int) -> void:
	print("[MergeManager] Merging ", card_id, " T", current_tier)
	merge_completed.emit(card_id, current_tier + 1)


func decline_merge(card_id: String, tier: int) -> void:
	merge_declined.emit(card_id, tier)
