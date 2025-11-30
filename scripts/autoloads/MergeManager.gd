extends Node
## MergeManager - Triple-merge card upgrade system
## Merge 3 copies of the same card at the same tier to create a higher tier version

signal merge_completed(card_id: String, new_tier: int)

const MAX_TIER: int = 3
const COPIES_REQUIRED: int = 3


func _ready() -> void:
	print("[MergeManager] Initialized")


func check_for_merges() -> Array[Dictionary]:
	"""Check RunManager.deck for any available merges.
	Returns array of {card_id, tier, count} for each mergeable set."""
	var mergeable: Array[Dictionary] = []
	var card_counts: Dictionary = {}
	
	# Count cards by id+tier
	for entry: Dictionary in RunManager.deck:
		var key: String = entry.card_id + "_T" + str(entry.tier)
		if not card_counts.has(key):
			card_counts[key] = {"card_id": entry.card_id, "tier": entry.tier, "count": 0}
		card_counts[key].count += 1
	
	# Find sets with 3+ copies that aren't max tier
	for key: String in card_counts:
		var data: Dictionary = card_counts[key]
		if data.count >= COPIES_REQUIRED and data.tier < MAX_TIER:
			mergeable.append(data)
	
	return mergeable


func can_merge(card_id: String, tier: int) -> bool:
	"""Check if a specific card can be merged."""
	if tier >= MAX_TIER:
		return false
	
	var count: int = 0
	for entry: Dictionary in RunManager.deck:
		if entry.card_id == card_id and entry.tier == tier:
			count += 1
	
	return count >= COPIES_REQUIRED


func get_merge_count(card_id: String, tier: int) -> int:
	"""Get how many copies of a card at a tier exist in deck."""
	var count: int = 0
	for entry: Dictionary in RunManager.deck:
		if entry.card_id == card_id and entry.tier == tier:
			count += 1
	return count


func execute_merge(card_id: String, current_tier: int) -> bool:
	"""Execute a merge: remove 3 copies, add 1 upgraded copy.
	Returns true if successful."""
	if not can_merge(card_id, current_tier):
		print("[MergeManager] Cannot merge - not enough copies")
		return false
	
	# Find and remove 3 copies
	var removed: int = 0
	var i: int = RunManager.deck.size() - 1
	while i >= 0 and removed < COPIES_REQUIRED:
		if RunManager.deck[i].card_id == card_id and RunManager.deck[i].tier == current_tier:
			RunManager.deck.remove_at(i)
			removed += 1
		i -= 1
	
	# Add upgraded card
	var new_tier: int = current_tier + 1
	RunManager.deck.append({"card_id": card_id, "tier": new_tier})
	
	print("[MergeManager] Merged 3x ", card_id, " T", current_tier, " -> 1x T", new_tier)
	merge_completed.emit(card_id, new_tier)
	
	return true


func get_upgrade_preview(card_id: String, current_tier: int) -> Dictionary:
	"""Get preview of what stats a card will have after merge."""
	var card_def = CardDatabase.get_card(card_id)
	if not card_def:
		return {}
	
	var new_tier: int = current_tier + 1
	var preview: Dictionary = {
		"card_id": card_id,
		"card_name": card_def.card_name,
		"current_tier": current_tier,
		"new_tier": new_tier,
		"stat_changes": {}
	}
	
	# Get stat differences
	if card_def.base_damage > 0:
		var old_dmg: int = card_def.get_scaled_value("damage", current_tier)
		var new_dmg: int = card_def.get_scaled_value("damage", new_tier)
		preview.stat_changes["damage"] = {"old": old_dmg, "new": new_dmg}
	
	if card_def.hex_damage > 0:
		var old_hex: int = card_def.get_scaled_value("hex_damage", current_tier)
		var new_hex: int = card_def.get_scaled_value("hex_damage", new_tier)
		preview.stat_changes["hex"] = {"old": old_hex, "new": new_hex}
	
	if card_def.heal_amount > 0:
		var old_heal: int = card_def.get_scaled_value("heal_amount", current_tier)
		var new_heal: int = card_def.get_scaled_value("heal_amount", new_tier)
		preview.stat_changes["heal"] = {"old": old_heal, "new": new_heal}
	
	if card_def.armor_amount > 0:
		var old_armor: int = card_def.get_scaled_value("armor_amount", current_tier)
		var new_armor: int = card_def.get_scaled_value("armor_amount", new_tier)
		preview.stat_changes["armor"] = {"old": old_armor, "new": new_armor}
	
	return preview
