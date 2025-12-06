extends RefCounted
class_name ShopStatsFormatter
## ShopStatsFormatter - Formatting utilities for shop stat displays
## Extracted from Shop.gd to keep files under 500 lines

# Note: TagConstants is globally available via class_name - use directly


static func format_player_stats(stats, current_hp: int, armor: int, scrap: int, wave: int, warden) -> String:
	"""Format player stats for the stats panel display."""
	if not stats:
		return "[color=#ff6666]No stats available[/color]"
	
	var text: String = ""
	
	# Runtime state
	text += "[color=#ffcc66]━━ RUNTIME ━━[/color]\n"
	text += "HP: [color=#ff6666]%d/%d[/color]\n" % [current_hp, stats.max_hp]
	text += "Armor: [color=#66ccff]%d[/color]\n" % armor
	text += "Scrap: [color=#ffcc33]%d[/color]\n" % scrap
	text += "Wave: [color=#ffaa33]%d[/color]\n" % wave
	
	# Warden info
	if warden:
		var warden_name: String = "Unknown"
		if warden is WardenDefinition:
			warden_name = warden.warden_name
		text += "Warden: [color=#66ff66]%s[/color]\n" % warden_name
	text += "\n"
	
	# V5 Flat damage stats (from synergies)
	text += "[color=#ff9966]━━ FLAT DMG ━━[/color]\n"
	text += "🔫 Kinetic: [color=#%s]+%d[/color]\n" % [_get_flat_stat_color(stats.kinetic), stats.kinetic]
	text += "🔥 Thermal: [color=#%s]+%d[/color]\n" % [_get_flat_stat_color(stats.thermal), stats.thermal]
	text += "✨ Arcane: [color=#%s]+%d[/color]\n" % [_get_flat_stat_color(stats.arcane), stats.arcane]
	text += "\n"
	
	# Offense stats
	text += "[color=#ff6666]━━ DMG %% ━━[/color]\n"
	text += "Kinetic: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.kinetic_percent), stats.kinetic_percent]
	text += "Thermal: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.thermal_percent), stats.thermal_percent]
	text += "Arcane: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.arcane_percent), stats.arcane_percent]
	text += "All Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_percent), stats.damage_percent]
	text += "\n"
	
	# Crit stats
	text += "[color=#ffaa00]━━ CRIT ━━[/color]\n"
	text += "Crit Chance: [color=#%s]%.0f%%[/color]\n" % [_get_flat_stat_color(int(stats.crit_chance)), stats.crit_chance]
	text += "Crit Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.crit_damage), stats.crit_damage]
	text += "\n"
	
	# Economy stats
	text += "[color=#ffcc33]━━ ECONOMY ━━[/color]\n"
	text += "Energy/Turn: [color=#ffff66]%d[/color]\n" % stats.energy_per_turn
	text += "Draw/Turn: [color=#%s]%d[/color]\n" % [_get_flat_stat_color(stats.draw_per_turn - 5), stats.draw_per_turn]
	text += "Hand Size: [color=#aaaaaa]%d[/color]\n" % stats.hand_size_max
	text += "Scrap Gain: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.scrap_gain_percent), stats.scrap_gain_percent]
	
	return text


static func format_tag_counts(_deck: Array) -> String:
	"""Format V5 category synergies from the deck using FamilyBuffManager."""
	var text: String = ""
	
	# Get data from FamilyBuffManager
	var category_counts: Dictionary = FamilyBuffManager.category_counts
	var active_tiers: Dictionary = FamilyBuffManager.active_buff_tiers
	
	text += "[color=#ffaa66]━━ SYNERGIES ━━[/color]\n\n"
	
	# Show each V5 category with its synergy status
	for category: String in TagConstants.CATEGORIES:
		var count: int = category_counts.get(category, 0)
		var tier: int = active_tiers.get(category, 0)
		var icon: String = TagConstants.get_category_icon(category)
		
		# Determine tier thresholds
		var tier1_min: int = TagConstants.FAMILY_TIER_1_MIN  # 3
		var tier2_min: int = TagConstants.FAMILY_TIER_2_MIN  # 6
		var tier3_min: int = TagConstants.FAMILY_TIER_3_MIN  # 9
		
		# Get next threshold
		var next_threshold: int = tier1_min
		if tier >= 1:
			next_threshold = tier2_min
		if tier >= 2:
			next_threshold = tier3_min
		if tier >= 3:
			next_threshold = count  # Already maxed
		
		# Get current bonus
		var current_bonus: String = _get_synergy_bonus_text(category, tier)
		
		# Build count/threshold display
		var count_display: String
		if tier >= 3:
			count_display = "[color=#ffcc33]%d[/color]" % count  # Gold for max
		elif count > 0:
			count_display = "[color=#66ff66]%d[/color]/%d" % [count, next_threshold]
		else:
			count_display = "[color=#666666]%d[/color]/%d" % [count, next_threshold]
		
		# Category name with tier indicator
		var tier_indicator: String = ""
		if tier > 0:
			tier_indicator = " [color=#ffcc33]★%d[/color]" % tier
		
		text += "%s [color=#%s]%s[/color]%s: %s\n" % [
			icon,
			_get_category_name_color(tier),
			category,
			tier_indicator,
			count_display
		]
		
		# Show current bonus if active
		if tier > 0:
			text += "   [color=#66ff66]%s[/color]\n" % current_bonus
	
	return text


static func format_synergy_info() -> String:
	"""Format detailed synergy information as a table with highlighted active tiers."""
	var text: String = ""
	
	text += "[color=#ffaa66]━━━━━━━━━━ SYNERGY BONUSES ━━━━━━━━━━[/color]\n\n"
	
	# Table header
	text += "[color=#888888]Category          ★1 (3)              ★2 (6)              ★3 (9)[/color]\n"
	text += "[color=#444444]─────────────────────────────────────────────────────────────────[/color]\n"
	
	# Show each category as a row
	for category: String in TagConstants.CATEGORIES:
		var icon: String = TagConstants.get_category_icon(category)
		var tier: int = FamilyBuffManager.active_buff_tiers.get(category, 0)
		var count: int = FamilyBuffManager.category_counts.get(category, 0)
		
		# Get buff data
		var buff_data: Dictionary = TagConstants.FAMILY_BUFFS.get(category, {})
		var values: Array = buff_data.get("values", [0, 0, 0])
		var stat: String = buff_data.get("stat", "")
		
		# Category name with count
		var cat_color: String = "aaaaaa" if tier == 0 else "ffffff"
		var count_str: String = " (%d)" % count if count > 0 else ""
		text += "%s [color=#%s]%s[/color][color=#666666]%s[/color]\n" % [icon, cat_color, category, count_str]
		
		# Show all 3 tiers on one line with proper highlighting
		var tier_texts: Array[String] = []
		for i: int in range(3):
			var tier_num: int = i + 1
			var value: int = values[i] if i < values.size() else 0
			var bonus_text: String = _get_short_bonus_text(stat, value, category, tier_num)
			
			# Determine color based on active status
			var tier_color: String
			var prefix: String = "  "
			if tier_num <= tier:
				# Active - bright green with checkmark
				tier_color = "66ff66"
				prefix = "✓ "
			elif tier_num == tier + 1 and count > 0:
				# Next tier - show progress
				var needed: int = [3, 6, 9][i]
				tier_color = "ffcc66"
				prefix = "› "
				bonus_text += " [%d/%d]" % [count, needed]
			else:
				# Locked - gray
				tier_color = "555555"
			
			tier_texts.append("[color=#%s]%s%s[/color]" % [tier_color, prefix, bonus_text])
		
		text += "   %s\n" % "   ".join(tier_texts)
		text += "\n"
	
	# Legend
	text += "[color=#444444]─────────────────────────────────────────────────────────────────[/color]\n"
	text += "[color=#66ff66]✓ Active[/color]  [color=#ffcc66]› Next[/color]  [color=#555555]Locked[/color]\n"
	
	return text


static func _get_short_bonus_text(stat: String, value: int, category: String, tier: int) -> String:
	"""Get a SHORT bonus text for table display."""
	match stat:
		"kinetic":
			return "+%d Kinetic" % value
		"thermal":
			return "+%d Thermal" % value
		"arcane":
			return "+%d Arcane" % value
		"armor_start":
			return "+%d Armor" % value
		"crit_chance":
			return "+%d%% Crit" % value
		"draw_per_turn":
			return "+%d Draw" % value
		"max_hp":
			return "+%d HP" % value
		"barriers":
			var barrier_damage: Array = TagConstants.FAMILY_BUFFS.get(category, {}).get("barrier_damage", [2, 3, 3])
			var dmg: int = barrier_damage[tier - 1] if tier - 1 < barrier_damage.size() else 2
			return "+%d Barrier(%d)" % [value, dmg]
		_:
			return "+%d %s" % [value, stat]


static func _get_synergy_bonus_text(category: String, tier: int) -> String:
	"""Get a short description of the current bonus for a category."""
	if tier <= 0:
		return ""
	
	var buff_data: Dictionary = TagConstants.FAMILY_BUFFS.get(category, {})
	var values: Array = buff_data.get("values", [0, 0, 0])
	var stat: String = buff_data.get("stat", "")
	var value: int = values[tier - 1] if tier - 1 < values.size() else 0
	
	return _get_stat_display_name(stat, value, category, tier)


static func _get_stat_display_name(stat: String, value: int, category: String, tier: int) -> String:
	"""Get human-readable stat bonus text."""
	match stat:
		"kinetic":
			return "+%d Kinetic damage" % value
		"thermal":
			return "+%d Thermal damage" % value
		"arcane":
			return "+%d Arcane damage" % value
		"armor_start":
			return "+%d Armor at wave start" % value
		"crit_chance":
			return "+%d%% Crit chance" % value
		"draw_per_turn":
			return "+%d Card draw per turn" % value
		"max_hp":
			return "+%d Max HP" % value
		"barriers":
			# Control has special barrier logic
			var barrier_damage: Array = TagConstants.FAMILY_BUFFS.get(category, {}).get("barrier_damage", [2, 3, 3])
			var dmg: int = barrier_damage[tier - 1] if tier - 1 < barrier_damage.size() else 2
			return "+%d Barrier(s) (%d dmg)" % [value, dmg]
		_:
			return "+%d %s" % [value, stat]


static func _get_category_name_color(tier: int) -> String:
	"""Get color for category name based on tier."""
	match tier:
		0:
			return "aaaaaa"  # Gray for inactive
		1:
			return "66ccff"  # Blue for tier 1
		2:
			return "66ff66"  # Green for tier 2
		3:
			return "ffcc33"  # Gold for tier 3
		_:
			return "aaaaaa"


static func _get_stat_color(value: float) -> String:
	"""Get color hex based on whether value is above, below, or at 100%."""
	if value > 100.0:
		return "66ff66"  # Green for bonus
	elif value < 100.0:
		return "ff6666"  # Red for penalty
	else:
		return "aaaaaa"  # Gray for neutral


static func _get_flat_stat_color(value: int) -> String:
	"""Get color hex for flat stats (higher is better)."""
	if value > 0:
		return "66ff66"  # Green for bonus
	elif value < 0:
		return "ff6666"  # Red for penalty
	else:
		return "aaaaaa"  # Gray for neutral


