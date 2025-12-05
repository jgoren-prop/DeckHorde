extends Node
## MergeManager - V5 2-to-1 card merge system
## Merge 2 copies of the same card at the same tier to create a higher tier version
## V5: 4 tiers (Gray T1, Green T2, Blue T3, Gold T4)

signal merge_completed(card_id: String, new_tier: int)

# V5: 4 tiers, 2 copies required
const MAX_TIER: int = 4
const COPIES_REQUIRED: int = 2

# V5 Tier names and colors
const TIER_NAMES: Array[String] = ["", "T1", "T2", "T3", "T4"]
const TIER_COLORS: Array[Color] = [
	Color.WHITE,
	Color(0.7, 0.7, 0.7),  # Gray - Tier 1
	Color(0.3, 0.8, 0.3),  # Green - Tier 2
	Color(0.3, 0.5, 1.0),  # Blue - Tier 3
	Color(1.0, 0.8, 0.2),  # Gold - Tier 4
]


func _ready() -> void:
	print("[MergeManager] V5 Initialized (2-to-1 merge, 4 tiers)")


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
	
	# Find sets with 2+ copies that aren't max tier
	for key: String in card_counts:
		var data: Dictionary = card_counts[key]
		# Check if card is a weapon (not instant) - only weapons can merge
		var card_def = CardDatabase.get_card(data.card_id)
		if card_def and not card_def.is_instant_card:
			if data.count >= COPIES_REQUIRED and data.tier < MAX_TIER:
				mergeable.append(data)
	
	return mergeable


func can_merge(card_id: String, tier: int) -> bool:
	"""Check if a specific card can be merged."""
	if tier >= MAX_TIER:
		return false
	
	# Check if card is a weapon (only weapons can merge)
	var card_def = CardDatabase.get_card(card_id)
	if card_def and card_def.is_instant_card:
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
	"""Execute a merge: remove 2 copies, add 1 upgraded copy.
	Returns true if successful."""
	if not can_merge(card_id, current_tier):
		print("[MergeManager] Cannot merge - not enough copies or instant card")
		return false
	
	# Get card for family buff tracking
	var card_def = CardDatabase.get_card(card_id)
	
	# Find and remove 2 copies
	var removed: int = 0
	var i: int = RunManager.deck.size() - 1
	while i >= 0 and removed < COPIES_REQUIRED:
		if RunManager.deck[i].card_id == card_id and RunManager.deck[i].tier == current_tier:
			RunManager.deck.remove_at(i)
			removed += 1
			# V5: Track family buff changes (net -1 card since we remove 2, add 1)
			if card_def:
				FamilyBuffManager.remove_card(card_def)
		i -= 1
	
	# Add upgraded card
	var new_tier: int = current_tier + 1
	RunManager.deck.append({"card_id": card_id, "tier": new_tier})
	
	# V5: Add the new card to family buffs (we already removed 2)
	if card_def:
		FamilyBuffManager.add_card(card_def)
	
	print("[MergeManager] Merged 2x ", card_id, " T", current_tier, " -> 1x T", new_tier)
	merge_completed.emit(card_id, new_tier)
	
	return true


func get_upgrade_preview(card_id: String, current_tier: int) -> Dictionary:
	"""Get preview of what stats a card will have after merge."""
	var card_def = CardDatabase.get_card(card_id)
	if not card_def:
		return {}
	
	var new_tier: int = current_tier + 1
	if new_tier > MAX_TIER:
		new_tier = MAX_TIER
	
	var preview: Dictionary = {
		"card_id": card_id,
		"card_name": card_def.card_name,
		"current_tier": current_tier,
		"new_tier": new_tier,
		"current_tier_name": get_tier_name(current_tier),
		"new_tier_name": get_tier_name(new_tier),
		"current_color": get_tier_color(current_tier),
		"new_color": get_tier_color(new_tier),
		"stat_changes": {}
	}
	
	# V5: Calculate damage using tier formulas
	if card_def.base_damage > 0:
		# Temporarily change tier to calculate
		var old_tier: int = card_def.tier
		
		card_def.tier = current_tier
		var old_dmg: int = card_def.get_tiered_base_damage()
		
		card_def.tier = new_tier
		var new_dmg: int = card_def.get_tiered_base_damage()
		
		card_def.tier = old_tier
		
		preview.stat_changes["damage"] = {"old": old_dmg, "new": new_dmg, "diff": new_dmg - old_dmg}
	
	# V5: Show tier multiplier changes
	var old_base_mult: float = card_def.TIER_BASE_MULTIPLIERS[current_tier - 1]
	var new_base_mult: float = card_def.TIER_BASE_MULTIPLIERS[new_tier - 1]
	var old_scale_mult: float = card_def.TIER_SCALING_MULTIPLIERS[current_tier - 1]
	var new_scale_mult: float = card_def.TIER_SCALING_MULTIPLIERS[new_tier - 1]
	
	preview.stat_changes["base_mult"] = {
		"old": old_base_mult,
		"new": new_base_mult,
		"diff_percent": int((new_base_mult - old_base_mult) * 100)
	}
	preview.stat_changes["scaling_mult"] = {
		"old": old_scale_mult,
		"new": new_scale_mult,
		"diff_percent": int((new_scale_mult - old_scale_mult) * 100)
	}
	
	return preview


func get_tier_name(tier: int) -> String:
	"""Get the display name for a tier."""
	if tier >= 0 and tier < TIER_NAMES.size():
		return TIER_NAMES[tier]
	return "T" + str(tier)


func get_tier_color(tier: int) -> Color:
	"""Get the display color for a tier."""
	if tier >= 0 and tier < TIER_COLORS.size():
		return TIER_COLORS[tier]
	return Color.WHITE


func get_merge_info_text(card_id: String, tier: int) -> String:
	"""Get human-readable merge info for UI."""
	var count: int = get_merge_count(card_id, tier)
	var card_def = CardDatabase.get_card(card_id)
	
	if card_def and card_def.is_instant_card:
		return "Instants cannot be merged"
	
	if tier >= MAX_TIER:
		return "Already at max tier (T4 Gold)"
	
	if count >= COPIES_REQUIRED:
		return "Ready to merge! (%d/%d)" % [count, COPIES_REQUIRED]
	else:
		return "Need %d more to merge" % (COPIES_REQUIRED - count)


func auto_merge_all() -> int:
	"""Automatically merge all available cards. Returns number of merges performed."""
	var merges_done: int = 0
	var available: Array[Dictionary] = check_for_merges()
	
	while available.size() > 0:
		var merge_data: Dictionary = available[0]
		if execute_merge(merge_data.card_id, merge_data.tier):
			merges_done += 1
		# Re-check for cascading merges (T1->T2->T3 etc)
		available = check_for_merges()
	
	if merges_done > 0:
		print("[MergeManager] Auto-merged ", merges_done, " cards")
	
	return merges_done
