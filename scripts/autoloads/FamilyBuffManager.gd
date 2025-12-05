extends Node
## FamilyBuffManager - V5 Family Buff System
## Tracks category counts in the deck and applies tier-based stat bonuses
## Based on DESIGN_V5.md family buff system

const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")
const CardDef = preload("res://scripts/resources/CardDefinition.gd")

signal family_buffs_changed(category_counts: Dictionary, active_buffs: Dictionary)

# Category counts in the current deck
var category_counts: Dictionary = {}

# Active buff tiers per category (0-3)
var active_buff_tiers: Dictionary = {}

# Cached buff values that have been applied to stats
var applied_buffs: Dictionary = {}


func _ready() -> void:
	# Initialize category counts
	for category: String in TagConstantsClass.CATEGORIES:
		category_counts[category] = 0
		active_buff_tiers[category] = 0
		applied_buffs[category] = 0


# =============================================================================
# CATEGORY COUNTING
# =============================================================================

func recalculate_from_deck() -> void:
	"""Recalculate category counts from RunManager's deck."""
	# Reset counts
	for category: String in TagConstantsClass.CATEGORIES:
		category_counts[category] = 0
	
	# Count categories in deck
	for card_entry: Variant in RunManager.deck:
		if card_entry is Dictionary:
			var card_id: String = card_entry.get("card_id", "")
			var card: CardDef = CardDatabase.get_card(card_id)
			if card:
				_count_card_categories(card)
	
	# Update buff tiers and apply changes
	_update_buff_tiers()
	_apply_buff_changes()
	
	print("[FamilyBuffManager] Recalculated from deck:")
	for category: String in TagConstantsClass.CATEGORIES:
		if category_counts[category] > 0:
			print("  %s: %d cards (Tier %d)" % [category, category_counts[category], active_buff_tiers[category]])


func add_card(card: CardDef) -> void:
	"""Add a card's categories to the count."""
	_count_card_categories(card)
	_update_buff_tiers()
	_apply_buff_changes()


func remove_card(card: CardDef) -> void:
	"""Remove a card's categories from the count."""
	for category: String in card.categories:
		if category_counts.has(category):
			category_counts[category] = maxi(0, category_counts[category] - 1)
	
	_update_buff_tiers()
	_apply_buff_changes()


func _count_card_categories(card: CardDef) -> void:
	"""Add a card's categories to the count."""
	for category: String in card.categories:
		if category_counts.has(category):
			category_counts[category] += 1


func _update_buff_tiers() -> void:
	"""Update active buff tiers based on category counts."""
	for category: String in TagConstantsClass.CATEGORIES:
		var count: int = category_counts.get(category, 0)
		active_buff_tiers[category] = TagConstantsClass.get_family_buff_tier(count)


# =============================================================================
# BUFF APPLICATION
# =============================================================================

func _apply_buff_changes() -> void:
	"""Apply changes to buffs based on new tier levels."""
	var stats = RunManager.player_stats
	
	for category: String in TagConstantsClass.CATEGORIES:
		var new_tier: int = active_buff_tiers.get(category, 0)
		var old_applied: int = applied_buffs.get(category, 0)
		var new_value: int = TagConstantsClass.get_family_buff_value(category, new_tier)
		var stat_name: String = TagConstantsClass.get_family_buff_stat(category)
		
		# Calculate delta
		var delta: int = new_value - old_applied
		
		if delta != 0 and not stat_name.is_empty():
			# Apply the delta to the appropriate stat
			_apply_stat_delta(stats, stat_name, category, delta)
			applied_buffs[category] = new_value
			
			if delta > 0:
				print("[FamilyBuffManager] %s Tier %d: +%d %s" % [category, new_tier, delta, stat_name])
			else:
				print("[FamilyBuffManager] %s reduced: %d %s" % [category, delta, stat_name])
	
	# Emit signal
	family_buffs_changed.emit(category_counts.duplicate(), active_buff_tiers.duplicate())


func _apply_stat_delta(stats, stat_name: String, _category: String, delta: int) -> void:
	"""Apply a delta to the appropriate stat."""
	match stat_name:
		"kinetic":
			stats.kinetic += delta
		"thermal":
			stats.thermal += delta
		"arcane":
			stats.arcane += delta
		"armor_start":
			stats.armor_start += delta
		"crit_chance":
			stats.crit_chance += float(delta)
		"draw_per_turn":
			stats.draw_per_turn += delta
		"max_hp":
			stats.max_hp += delta
			# Also adjust current HP if max HP increased
			if delta > 0:
				RunManager.current_hp += delta
				RunManager.hp_changed.emit(RunManager.current_hp, stats.max_hp)
		"barriers":
			# Control barriers are special - they're placed at wave start
			# We track them separately
			stats.barriers += delta
		_:
			push_warning("[FamilyBuffManager] Unknown stat: " + stat_name)


# =============================================================================
# WAVE START BONUSES
# =============================================================================

func apply_wave_start_bonuses() -> void:
	"""Apply bonuses that activate at the start of each wave."""
	var stats = RunManager.player_stats
	
	# Fortress: Gain armor at wave start
	var fortress_tier: int = active_buff_tiers.get(TagConstantsClass.CAT_FORTRESS, 0)
	if fortress_tier > 0:
		var armor_bonus: int = TagConstantsClass.get_family_buff_value(TagConstantsClass.CAT_FORTRESS, fortress_tier)
		RunManager.add_armor(armor_bonus)
		print("[FamilyBuffManager] Fortress wave bonus: +%d armor" % armor_bonus)
	
	# Control: Place barriers at wave start
	var control_tier: int = active_buff_tiers.get(TagConstantsClass.CAT_CONTROL, 0)
	if control_tier > 0:
		var barrier_count: int = TagConstantsClass.get_family_buff_value(TagConstantsClass.CAT_CONTROL, control_tier)
		var barrier_damage: int = TagConstantsClass.FAMILY_BUFFS[TagConstantsClass.CAT_CONTROL].get("barrier_damage", [2, 3, 3])[control_tier - 1]
		# Barriers will be placed by CombatManager at wave start
		stats.barriers = barrier_count
		print("[FamilyBuffManager] Control wave bonus: %d barriers (%d dmg each)" % [barrier_count, barrier_damage])
	
	# Utility: Extra draw at wave start (handled by draw_per_turn stat already)
	# The stat is already modified, so CombatManager will draw more cards naturally


# =============================================================================
# QUERY FUNCTIONS
# =============================================================================

func get_category_count(category: String) -> int:
	"""Get the count for a specific category."""
	return category_counts.get(category, 0)


func get_buff_tier(category: String) -> int:
	"""Get the active buff tier for a category (0-3)."""
	return active_buff_tiers.get(category, 0)


func get_active_buff_value(category: String) -> int:
	"""Get the current buff value for a category."""
	var tier: int = active_buff_tiers.get(category, 0)
	return TagConstantsClass.get_family_buff_value(category, tier)


func get_all_active_buffs() -> Dictionary:
	"""Get all active buffs as {category: {tier: int, value: int, stat: String}}."""
	var result: Dictionary = {}
	for category: String in TagConstantsClass.CATEGORIES:
		var tier: int = active_buff_tiers.get(category, 0)
		if tier > 0:
			result[category] = {
				"tier": tier,
				"value": TagConstantsClass.get_family_buff_value(category, tier),
				"stat": TagConstantsClass.get_family_buff_stat(category),
				"count": category_counts.get(category, 0)
			}
	return result


func get_progress_to_next_tier(category: String) -> Dictionary:
	"""Get progress info toward next tier for a category.
	Returns: {current: int, needed: int, next_tier: int, next_value: int}
	"""
	var count: int = category_counts.get(category, 0)
	var current_tier: int = active_buff_tiers.get(category, 0)
	
	var next_tier: int = 0
	var needed: int = 0
	
	if current_tier == 0:
		next_tier = 1
		needed = TagConstantsClass.FAMILY_TIER_1_MIN
	elif current_tier == 1:
		next_tier = 2
		needed = TagConstantsClass.FAMILY_TIER_2_MIN
	elif current_tier == 2:
		next_tier = 3
		needed = TagConstantsClass.FAMILY_TIER_3_MIN
	else:
		# Max tier
		next_tier = 3
		needed = count
	
	return {
		"current": count,
		"needed": needed,
		"next_tier": next_tier,
		"next_value": TagConstantsClass.get_family_buff_value(category, next_tier)
	}


# =============================================================================
# RESET
# =============================================================================

func reset() -> void:
	"""Reset all family buffs (call at start of new run)."""
	# Remove applied buffs
	var stats = RunManager.player_stats
	for category: String in TagConstantsClass.CATEGORIES:
		var old_applied: int = applied_buffs.get(category, 0)
		if old_applied != 0:
			var stat_name: String = TagConstantsClass.get_family_buff_stat(category)
			_apply_stat_delta(stats, stat_name, category, -old_applied)
		
		category_counts[category] = 0
		active_buff_tiers[category] = 0
		applied_buffs[category] = 0
	
	print("[FamilyBuffManager] Reset all family buffs")
