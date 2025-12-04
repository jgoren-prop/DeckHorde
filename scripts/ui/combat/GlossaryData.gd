extends RefCounted
class_name GlossaryData
## GlossaryData - Contains glossary entries for the combat help overlay
## Extracted from CombatScreen.gd to keep files under 500 lines


const GLOSSARY_ENTRIES: Array[Dictionary] = [
	{
		"title": "⚡ Energy",
		"color": Color(1.0, 0.85, 0.2),
		"description": "Resource spent to play cards. Each card has an energy cost shown in the top-left corner. Energy refills to your maximum (usually 3) at the start of each turn."
	},
	{
		"title": "🛡️ Armor",
		"color": Color(0.4, 0.8, 1.0),
		"description": "Absorbs incoming damage before your HP is reduced. Armor persists between turns until it's used up. When you take damage, armor is consumed first."
	},
	{
		"title": "☠️ Hex",
		"color": Color(0.7, 0.4, 1.0),
		"description": "A stacking debuff applied to enemies. When a hexed enemy takes ANY damage, they take bonus damage equal to their hex stacks, then all hex is consumed. Stack hex high, then trigger it with a damage card!"
	},
	{
		"title": "🚧 Barrier",
		"color": Color(0.5, 0.9, 0.6),
		"description": "A defensive zone placed on a ring (Close, Mid, or Far). When enemies move INWARD through that ring, they take the barrier's damage. Barriers last for a set number of turns before expiring."
	},
	{
		"title": "🔫 Persistent Weapon",
		"color": Color(0.9, 0.6, 0.3),
		"description": "Weapons that stay in play after being played. They automatically trigger at the start of each turn (dealing damage to enemies) until combat ends."
	},
	{
		"title": "♥️ Lifesteal",
		"color": Color(0.3, 0.9, 0.4),
		"description": "Healing effect that triggers when dealing damage or killing enemies. Some cards heal you for a portion of damage dealt or per enemy killed."
	},
	{
		"title": "↗️ Push",
		"color": Color(0.6, 0.7, 1.0),
		"description": "Crowd control effect that moves enemies outward to a farther ring. Useful for buying time or forcing enemies through barriers again."
	},
	{
		"title": "📜 Draw",
		"color": Color(0.5, 0.75, 1.0),
		"description": "Draws additional cards from your deck into your hand. If your deck is empty, your discard pile is shuffled back into your deck first."
	},
	{
		"title": "🎯 Targeting",
		"color": Color(1.0, 0.7, 0.4),
		"description": "Cards can target enemies in different ways:\n• Ring (choose): You pick which ring to affect\n• Ring (auto): Automatically hits specific rings\n• Random: Hits random enemies in valid rings\n• Self: Affects only you (buffs, armor, healing)"
	},
	{
		"title": "🔴 Rings",
		"color": Color(1.0, 0.5, 0.5),
		"description": "The battlefield has 4 rings:\n• MELEE (red): Enemies here attack you!\n• CLOSE (orange): One step from melee\n• MID (yellow): Middle distance\n• FAR (blue): Where enemies spawn\n\nEnemies advance inward each turn."
	},
	{
		"title": "⚔️ Card Types",
		"color": Color(0.9, 0.4, 0.4),
		"description": "• Weapon: Deal damage, some persist\n• Skill: Buffs, healing, utility\n• Hex: Apply hex debuff to enemies\n• Defense: Gain armor, create barriers"
	},
	{
		"title": "⭐ Card Tiers",
		"color": Color(1.0, 0.85, 0.3),
		"description": "Cards have tiers (T1, T2, T3). Higher tiers have improved stats. Merge two identical cards at the same tier to upgrade them to the next tier!"
	},
]


static func get_entries() -> Array[Dictionary]:
	"""Get all glossary entries."""
	return GLOSSARY_ENTRIES


static func populate_glossary_content(content_container: VBoxContainer) -> void:
	"""Populate a VBoxContainer with glossary entries."""
	# Clear existing content
	for child: Node in content_container.get_children():
		child.queue_free()
	
	# Add each glossary entry
	for entry: Dictionary in GLOSSARY_ENTRIES:
		var entry_container: VBoxContainer = VBoxContainer.new()
		entry_container.add_theme_constant_override("separation", 6)
		
		# Title
		var title_label: Label = Label.new()
		title_label.text = entry.title
		title_label.add_theme_font_size_override("font_size", 20)
		title_label.add_theme_color_override("font_color", entry.color)
		entry_container.add_child(title_label)
		
		# Description
		var desc_label: Label = Label.new()
		desc_label.text = entry.description
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.custom_minimum_size = Vector2(620, 0)
		entry_container.add_child(desc_label)
		
		# Separator line
		var separator: HSeparator = HSeparator.new()
		separator.add_theme_constant_override("separation", 8)
		entry_container.add_child(separator)
		
		content_container.add_child(entry_container)

