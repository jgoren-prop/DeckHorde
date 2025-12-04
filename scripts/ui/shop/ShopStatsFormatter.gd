extends RefCounted
class_name ShopStatsFormatter
## ShopStatsFormatter - Formatting utilities for shop stat displays
## Extracted from Shop.gd to keep files under 500 lines

const TagConstants = preload("res://scripts/constants/TagConstants.gd")


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
	
	# Offense stats
	text += "[color=#ff6666]━━ OFFENSE ━━[/color]\n"
	text += "Gun Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.gun_damage_percent), stats.gun_damage_percent]
	text += "Hex Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.hex_damage_percent), stats.hex_damage_percent]
	text += "Barrier Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.barrier_damage_percent), stats.barrier_damage_percent]
	text += "Generic Damage: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.generic_damage_percent), stats.generic_damage_percent]
	text += "\n"
	
	# Defense stats
	text += "[color=#66ccff]━━ DEFENSE ━━[/color]\n"
	text += "Armor Gain: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.armor_gain_percent), stats.armor_gain_percent]
	text += "Barrier Strength: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.barrier_strength_percent), stats.barrier_strength_percent]
	text += "\n"
	
	# Economy stats
	text += "[color=#ffcc33]━━ ECONOMY ━━[/color]\n"
	text += "Energy/Turn: [color=#ffff66]%d[/color]\n" % stats.energy_per_turn
	text += "Draw/Turn: [color=#66aaff]%d[/color]\n" % stats.draw_per_turn
	text += "Hand Size: [color=#aaaaaa]%d[/color]\n" % stats.hand_size_max
	text += "Scrap Gain: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.scrap_gain_percent), stats.scrap_gain_percent]
	text += "Shop Prices: [color=#%s]%.0f%%[/color]\n" % [_get_inverse_stat_color(stats.shop_price_percent), stats.shop_price_percent]
	text += "\n"
	
	# Ring damage
	text += "[color=#aa66ff]━━ RING DMG ━━[/color]\n"
	text += "vs Melee: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_vs_melee_percent), stats.damage_vs_melee_percent]
	text += "vs Close: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_vs_close_percent), stats.damage_vs_close_percent]
	text += "vs Mid: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_vs_mid_percent), stats.damage_vs_mid_percent]
	text += "vs Far: [color=#%s]%.0f%%[/color]\n" % [_get_stat_color(stats.damage_vs_far_percent), stats.damage_vs_far_percent]
	
	return text


static func format_tag_counts(deck: Array) -> String:
	"""Format tag counts from the deck for the tag tracker panel."""
	# Count tags from deck
	var tag_counts: Dictionary = {}
	
	for entry: Dictionary in deck:
		var card_def = CardDatabase.get_card(entry.card_id)
		if card_def:
			for tag: Variant in card_def.tags:
				if tag is String:
					if not tag_counts.has(tag):
						tag_counts[tag] = 0
					tag_counts[tag] += 1
	
	# Build display text
	var text: String = ""
	
	# Core type tags
	text += "[color=#ff9966]━━ CORE TYPES ━━[/color]\n"
	for core_tag: String in TagConstants.CORE_TYPES:
		var count: int = tag_counts.get(core_tag, 0)
		var display_name: String = TagConstants.get_core_type_display_name(core_tag)
		var color: String = _get_tag_count_color(count)
		var icon: String = _get_tag_icon(core_tag)
		text += "%s %s: [color=#%s]%d[/color]\n" % [icon, display_name, color, count]
	
	text += "\n"
	
	# Family tags
	text += "[color=#aa66ff]━━ FAMILIES ━━[/color]\n"
	for family_tag: String in TagConstants.FAMILY_TAGS:
		var count: int = tag_counts.get(family_tag, 0)
		var display_name: String = TagConstants.get_family_display_name(family_tag)
		var color: String = _get_tag_count_color(count)
		var icon: String = _get_family_tag_icon(family_tag)
		text += "%s %s: [color=#%s]%d[/color]\n" % [icon, display_name, color, count]
	
	return text


static func _get_stat_color(value: float) -> String:
	"""Get color hex based on whether value is above, below, or at 100%."""
	if value > 100.0:
		return "66ff66"  # Green for bonus
	elif value < 100.0:
		return "ff6666"  # Red for penalty
	else:
		return "aaaaaa"  # Gray for neutral


static func _get_inverse_stat_color(value: float) -> String:
	"""Get color hex for inverse stats (lower is better, like shop prices)."""
	if value < 100.0:
		return "66ff66"  # Green for bonus (cheaper)
	elif value > 100.0:
		return "ff6666"  # Red for penalty (more expensive)
	else:
		return "aaaaaa"  # Gray for neutral


static func _get_tag_count_color(count: int) -> String:
	"""Get color hex based on tag count."""
	if count == 0:
		return "666666"  # Gray for none
	elif count <= 2:
		return "aaaaaa"  # Light gray for few
	elif count <= 5:
		return "66ccff"  # Blue for moderate
	elif count <= 8:
		return "66ff66"  # Green for good
	else:
		return "ffcc33"  # Gold for many


static func _get_tag_icon(tag: String) -> String:
	"""Get an icon for a core type tag."""
	match tag:
		TagConstants.TAG_GUN:
			return "🔫"
		TagConstants.TAG_HEX:
			return "🔮"
		TagConstants.TAG_BARRIER:
			return "🛡️"
		TagConstants.TAG_DEFENSE:
			return "🛡️"
		TagConstants.TAG_SKILL:
			return "⚡"
		TagConstants.TAG_ENGINE:
			return "⚙️"
		_:
			return "•"


static func _get_family_tag_icon(tag: String) -> String:
	"""Get an icon for a family tag."""
	match tag:
		TagConstants.TAG_LIFEDRAIN:
			return "🩸"
		TagConstants.TAG_HEX_RITUAL:
			return "🌑"
		TagConstants.TAG_FORTRESS:
			return "🏰"
		TagConstants.TAG_BARRIER_TRAP:
			return "💥"
		TagConstants.TAG_VOLATILE:
			return "💀"
		TagConstants.TAG_ENGINE_CORE:
			return "🔋"
		_:
			return "•"

