extends Control
## CardUI - Visual representation of a card in hand
## Supports drag-and-drop targeting for cards that require targets

signal card_clicked(card_def, tier: int, hand_index: int)  # card_def: CardDefinition
signal card_hovered(card_def, tier: int, is_hovering: bool)  # card_def: CardDefinition
signal card_drag_started(card_def, tier: int, hand_index: int)  # card_def: CardDefinition
signal card_drag_ended(card_def, tier: int, hand_index: int, drop_position: Vector2)  # card_def: CardDefinition

# Node references
@onready var card_background: Panel = $CardBackground
@onready var cost_bg: Panel = $CardBackground/VBox/Header/CostBG
@onready var cost_label: Label = $CardBackground/VBox/Header/CostBG/CostLabel
@onready var name_label: Label = $CardBackground/VBox/Header/NameLabel
@onready var tier_label: Label = $CardBackground/VBox/Header/TierLabel
@onready var type_icon: Label = $CardBackground/VBox/TypeIcon
@onready var description: RichTextLabel = $CardBackground/VBox/Description

# Stats row labels
@onready var stats_row: HBoxContainer = $CardBackground/VBox/StatsRow
@onready var damage_label: Label = $CardBackground/VBox/StatsRow/DamageLabel
@onready var hex_label: Label = $CardBackground/VBox/StatsRow/HexLabel
@onready var heal_label: Label = $CardBackground/VBox/StatsRow/HealLabel
@onready var armor_label: Label = $CardBackground/VBox/StatsRow/ArmorLabel
@onready var draw_label: Label = $CardBackground/VBox/StatsRow/DrawLabel
@onready var energy_label: Label = $CardBackground/VBox/StatsRow/EnergyLabel
@onready var extra_label: Label = $CardBackground/VBox/StatsRow/ExtraLabel

# Target row
@onready var target_row: Panel = $CardBackground/VBox/TargetRow
@onready var target_label: Label = $CardBackground/VBox/TargetRow/TargetLabel

# Footer
@onready var timing_badge: Panel = $CardBackground/VBox/Footer/TimingBadge
@onready var timing_label: Label = $CardBackground/VBox/Footer/TimingBadge/TimingLabel
@onready var tags_label: Label = $CardBackground/VBox/Footer/TagsLabel

@onready var click_area: Button = $ClickArea

var card_def = null  # CardDefinition
var tier: int = 1
var hand_index: int = -1

# When false, card always displays at full brightness (for shop/deck viewer)
var check_playability: bool = true

# Drag state
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_global_position: Vector2 = Vector2.ZERO  # Store global position too
var original_parent: Node = null  # Store original parent for context checking
var original_z_index: int = 0
var is_being_played: bool = false  # Flag to prevent return animation if card is being played
var active_tween: Tween = null  # Track active tween to kill if needed
var hover_tween: Tween = null  # Track hover tween separately

const TYPE_ICONS: Dictionary = {
	"weapon": "⚔️",
	"skill": "✨",
	"hex": "☠️",
	"defense": "🛡️",
	"curse": "💀"
}

const TYPE_COLORS: Dictionary = {
	"weapon": Color(0.9, 0.4, 0.3),
	"skill": Color(0.4, 0.7, 0.9),
	"hex": Color(0.6, 0.3, 0.8),
	"defense": Color(0.4, 0.8, 0.5),
	"curse": Color(0.4, 0.4, 0.4)
}

const TYPE_BG_COLORS: Dictionary = {
	"weapon": Color(0.165, 0.082, 0.082),  # #2a1515
	"skill": Color(0.082, 0.102, 0.165),   # #151a2a
	"hex": Color(0.122, 0.082, 0.165),     # #1f152a
	"defense": Color(0.082, 0.165, 0.122), # #152a1f
	"curse": Color(0.12, 0.12, 0.12)
}

const TIER_COLORS: Array[Color] = [
	Color(0.69, 0.69, 0.69),  # Tier 1 - Gray #b0b0b0
	Color(0.3, 0.6, 1.0),     # Tier 2 - Blue #4d99ff
	Color(1.0, 0.8, 0.2)      # Tier 3 - Gold #ffcc33
]

const RING_NAMES: Array[String] = ["M", "C", "D", "F"]


func _ready() -> void:
	click_area.button_down.connect(_on_button_down)
	click_area.button_up.connect(_on_button_up)
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)


func setup(card, card_tier: int, index: int) -> void:  # card: CardDefinition
	card_def = card
	tier = card_tier
	hand_index = index
	
	# Defer display update if nodes aren't ready yet
	if not is_node_ready():
		await ready
	_update_display()


func _update_display() -> void:
	if not card_def:
		return
	
	# Cost
	cost_label.text = str(card_def.base_cost)
	
	# Name with tier suffix
	var tier_suffix: String = card_def.get_tier_name(tier)
	name_label.text = card_def.card_name + tier_suffix
	
	# Tier indicator
	if tier > 1:
		tier_label.text = "T" + str(tier)
		tier_label.add_theme_color_override("font_color", TIER_COLORS[tier - 1])
	else:
		tier_label.text = ""
	
	# Type icon
	type_icon.text = TYPE_ICONS.get(card_def.card_type, "📜")
	
	# Stats row
	_update_stats_row()
	
	# Description (flavor text)
	var desc_text: String = _get_flavor_description()
	description.text = "[center]" + desc_text + "[/center]"
	
	# Target row
	_update_target_row()
	
	# Footer (timing + tags)
	_update_footer()
	
	# Apply type color to background
	_apply_style()


func _update_stats_row() -> void:
	"""Update the stats row - only show non-zero values."""
	var damage: int = card_def.get_scaled_value("damage", tier)
	var hex_dmg: int = card_def.get_scaled_value("hex_damage", tier)
	var heal: int = card_def.get_scaled_value("heal_amount", tier)
	var armor: int = card_def.get_scaled_value("armor_amount", tier)
	var cards_draw: int = card_def.cards_to_draw
	var energy_gain: int = 0
	var duration: int = card_def.get_scaled_value("duration", tier)
	var push: int = card_def.push_amount
	
	# Check for energy gain (from buff_value if effect is energy related)
	if card_def.effect_type == "energy_and_draw":
		energy_gain = card_def.buff_value
	
	# Show/hide each stat label based on value
	damage_label.visible = damage > 0
	if damage > 0:
		damage_label.text = "⚔ " + str(damage)
	
	hex_label.visible = hex_dmg > 0
	if hex_dmg > 0:
		hex_label.text = "☠ " + str(hex_dmg)
	
	heal_label.visible = heal > 0
	if heal > 0:
		heal_label.text = "♥ " + str(heal)
	
	armor_label.visible = armor > 0
	if armor > 0:
		armor_label.text = "🛡 " + str(armor)
	
	draw_label.visible = cards_draw > 0
	if cards_draw > 0:
		draw_label.text = "📜 " + str(cards_draw)
	
	energy_label.visible = energy_gain > 0
	if energy_gain > 0:
		energy_label.text = "⚡ +" + str(energy_gain)
	
	# Extra label for duration, push, or special effects
	extra_label.visible = false
	if duration > 0:
		extra_label.visible = true
		extra_label.text = "⏱ " + str(duration)
	elif push > 0:
		extra_label.visible = true
		extra_label.text = "↗ " + str(push)
	elif card_def.effect_type == "shield_bash":
		extra_label.visible = true
		extra_label.text = "⚔=🛡"
		damage_label.visible = false  # Hide regular damage since it's special
	elif card_def.effect_type == "buff" and card_def.buff_type == "hex_damage":
		extra_label.visible = true
		extra_label.text = "✦2x Hex"


func _update_target_row() -> void:
	"""Update the target row with scope and ring info."""
	var scope_text: String = ""
	var rings_text: String = ""
	
	# Determine scope based on target_type
	match card_def.target_type:
		"self":
			scope_text = "🎯 Self"
		"random_enemy":
			var count: int = card_def.target_count if card_def.target_count > 0 else 1
			if count == 1:
				scope_text = "🎯 1 Random"
			else:
				scope_text = "🎯 " + str(count) + " Random"
		"ring":
			if card_def.requires_target:
				scope_text = "🎯 Ring (choose)"
			else:
				scope_text = "🎯 Ring (auto)"
		"all_rings":
			scope_text = "🎯 ALL Rings"
		"all_enemies":
			scope_text = "🎯 ALL Enemies"
		_:
			# Default for cards without targeting (self-targeting skills)
			scope_text = "🎯 Self"
	
	# Determine rings text
	if card_def.target_type != "self" and card_def.target_type != "all_enemies":
		rings_text = _get_rings_text(card_def.target_rings)
	
	# Combine
	if rings_text != "" and rings_text != "ALL":
		target_label.text = scope_text + " │ " + rings_text
	elif rings_text == "ALL" and card_def.target_type != "all_enemies":
		target_label.text = scope_text + " │ ALL"
	else:
		target_label.text = scope_text


func _get_rings_text(rings: Array) -> String:
	"""Convert ring array to display text."""
	if rings.size() == 0:
		return ""
	
	# Check if all rings
	if rings.size() >= 4:
		var has_all: bool = true
		for i: int in range(4):
			if i not in rings:
				has_all = false
				break
		if has_all:
			return "ALL"
	
	# Build ring letters
	var letters: Array[String] = []
	var sorted_rings: Array = rings.duplicate()
	sorted_rings.sort()
	for ring: int in sorted_rings:
		if ring >= 0 and ring < RING_NAMES.size():
			letters.append(RING_NAMES[ring])
	
	return " ".join(letters)


func _update_footer() -> void:
	"""Update the footer with timing badge and tags."""
	# Timing badge
	var timing_text: String = "⚡ INSTANT"
	var timing_color: Color = Color(0.8, 0.8, 0.8)
	
	if card_def.effect_type == "weapon_persistent":
		timing_text = "🔁 PERSISTENT"
		timing_color = Color(1.0, 0.85, 0.3)  # Gold
	elif card_def.effect_type == "buff":
		timing_text = "✦ BUFF"
		timing_color = Color(0.5, 0.7, 1.0)  # Blue
	
	timing_label.text = timing_text
	timing_label.add_theme_color_override("font_color", timing_color)
	
	# Style timing badge background
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	badge_style.set_corner_radius_all(3)
	timing_badge.add_theme_stylebox_override("panel", badge_style)
	
	# Tags
	if card_def.tags.size() > 0:
		tags_label.text = ", ".join(card_def.tags)
	else:
		tags_label.text = ""


func _get_flavor_description() -> String:
	"""Get the card description with labeled effects."""
	# If card has explicit instant/persistent descriptions, use those
	var has_instant: bool = card_def.instant_description != ""
	var has_persistent: bool = card_def.persistent_description != ""
	
	if has_instant or has_persistent:
		var parts: Array[String] = []
		if has_instant:
			var instant_text: String = _substitute_values(card_def.instant_description)
			parts.append("[color=#88ddff]Instant:[/color] " + instant_text)
		if has_persistent:
			var persist_text: String = _substitute_values(card_def.persistent_description)
			parts.append("[color=#ffcc55]Persistent:[/color] " + persist_text)
		return "\n".join(parts)
	
	# Fall back to auto-generated descriptions for cards without explicit descriptions
	match card_def.effect_type:
		"weapon_persistent":
			return "[color=#ffcc55]Persistent:[/color] Deal " + str(card_def.get_scaled_value("damage", tier)) + " to a random enemy each turn."
		"instant_damage":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			if card_def.target_type == "ring" and not card_def.requires_target:
				return "[color=#88ddff]Instant:[/color] Deal " + str(dmg) + " to all enemies in range."
			elif card_def.target_type == "ring" and card_def.requires_target:
				return "[color=#88ddff]Instant:[/color] Deal " + str(dmg) + " to all enemies in chosen ring."
			else:
				return "[color=#88ddff]Instant:[/color] Deal " + str(dmg) + " to random enemy."
		"scatter_damage":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			return "[color=#88ddff]Instant:[/color] Deal " + str(dmg) + " to " + str(card_def.target_count) + " random enemies."
		"damage_and_draw":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			return "[color=#88ddff]Instant:[/color] Deal " + str(dmg) + " to random enemy. Draw " + str(card_def.cards_to_draw) + " card."
		"damage_and_heal":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			var heal: int = card_def.get_scaled_value("heal_amount", tier)
			return "[color=#88ddff]Instant:[/color] Deal " + str(dmg) + ", heal " + str(heal) + " HP."
		"heal":
			var heal: int = card_def.get_scaled_value("heal_amount", tier)
			return "[color=#88ddff]Instant:[/color] Heal " + str(heal) + " HP."
		"energy_and_draw":
			return "[color=#88ddff]Instant:[/color] Gain " + str(card_def.buff_value) + " Energy. Draw " + str(card_def.cards_to_draw) + " card."
		"gambit":
			return "[color=#88ddff]Instant:[/color] Discard hand, draw " + str(card_def.cards_to_draw) + " cards."
		"buff":
			if card_def.buff_type == "hex_damage":
				return "[color=#88ddff]Instant:[/color] Your next Hex deals double."
			return "[color=#88ddff]Instant:[/color] Apply a temporary buff."
		"apply_hex":
			var hex: int = card_def.get_scaled_value("hex_damage", tier)
			if card_def.target_type == "all_enemies":
				return "[color=#88ddff]Instant:[/color] Apply " + str(hex) + " Hex to ALL enemies."
			elif card_def.target_type == "ring" and card_def.requires_target:
				return "[color=#88ddff]Instant:[/color] Apply " + str(hex) + " Hex to enemies in chosen ring."
			elif card_def.target_type == "ring":
				return "[color=#88ddff]Instant:[/color] Apply " + str(hex) + " Hex to enemies in range."
			return "[color=#88ddff]Instant:[/color] Apply " + str(hex) + " Hex to random enemy."
		"damage_and_hex":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			var hex: int = card_def.get_scaled_value("hex_damage", tier)
			return "[color=#88ddff]Instant:[/color] Deal " + str(dmg) + " and apply " + str(hex) + " Hex."
		"gain_armor":
			var armor: int = card_def.get_scaled_value("armor_amount", tier)
			return "[color=#88ddff]Instant:[/color] Gain " + str(armor) + " Armor."
		"ring_barrier":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			var dur: int = card_def.get_scaled_value("duration", tier)
			return "[color=#88ddff]Instant:[/color] Create barrier (" + str(dmg) + " dmg, " + str(dur) + " turns)."
		"armor_and_lifesteal":
			var armor: int = card_def.get_scaled_value("armor_amount", tier)
			return "[color=#88ddff]Instant:[/color] Gain " + str(armor) + " Armor. Heal 1 per Melee enemy."
		"push_enemies":
			return "[color=#88ddff]Instant:[/color] Push enemies back " + str(card_def.push_amount) + " ring."
		"shield_bash":
			return "[color=#88ddff]Instant:[/color] Deal damage equal to your Armor."
		_:
			return card_def.get_description_with_values(tier)


func _substitute_values(text: String) -> String:
	"""Replace placeholders with actual scaled values."""
	var result: String = text
	result = result.replace("{damage}", str(card_def.get_scaled_value("damage", tier)))
	result = result.replace("{hex_damage}", str(card_def.get_scaled_value("hex_damage", tier)))
	result = result.replace("{heal_amount}", str(card_def.get_scaled_value("heal_amount", tier)))
	result = result.replace("{armor}", str(card_def.get_scaled_value("armor_amount", tier)))
	result = result.replace("{buff_value}", str(card_def.get_scaled_value("buff_value", tier)))
	result = result.replace("{duration}", str(card_def.get_scaled_value("duration", tier)))
	result = result.replace("{draw}", str(card_def.cards_to_draw))
	result = result.replace("{push}", str(card_def.push_amount))
	result = result.replace("{target_count}", str(card_def.target_count))
	return result


func _apply_style() -> void:
	# Card background style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	
	# Base color from type
	var base_color: Color = TYPE_BG_COLORS.get(card_def.card_type, Color(0.12, 0.12, 0.15))
	style.bg_color = base_color
	
	# Border color based on tier
	var tier_color: Color = TIER_COLORS[tier - 1] if tier <= 3 else TIER_COLORS[2]
	style.border_color = tier_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	
	card_background.add_theme_stylebox_override("panel", style)
	
	# Cost background style
	var cost_style: StyleBoxFlat = StyleBoxFlat.new()
	cost_style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	cost_style.border_color = Color(1.0, 0.85, 0.2, 0.9)
	cost_style.set_border_width_all(2)
	cost_style.set_corner_radius_all(4)
	cost_bg.add_theme_stylebox_override("panel", cost_style)
	
	# Target row background style
	var target_style: StyleBoxFlat = StyleBoxFlat.new()
	target_style.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	target_style.set_corner_radius_all(3)
	target_row.add_theme_stylebox_override("panel", target_style)
	
	# Check if playable (only in combat contexts)
	if check_playability:
		var can_play: bool = CombatManager.can_play_card(card_def, tier) if CombatManager else false
		if not can_play:
			modulate = Color(0.5, 0.5, 0.55, 1.0)
			cost_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4, 1.0))
		else:
			modulate = Color.WHITE
			cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	else:
		# Always show full brightness for non-combat contexts (shop, deck viewer)
		modulate = Color.WHITE
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))


func _process(_delta: float) -> void:
	if is_dragging:
		# Follow mouse while dragging
		var mouse_pos: Vector2 = get_global_mouse_position()
		var new_global_pos: Vector2 = mouse_pos - drag_offset
		
		# Check if position changed significantly (debug)
		var pos_delta: Vector2 = new_global_pos - global_position
		if pos_delta.length() > 1.0:  # Only log if moved more than 1 pixel
			print("[CardUI DEBUG] Position update - card: ", card_def.card_name if card_def else "null",
				  " | mouse: ", mouse_pos, " | drag_offset: ", drag_offset,
				  " | new global: ", new_global_pos, " | old global: ", global_position,
				  " | delta: ", pos_delta, " | parent: ", str(get_parent().name) if get_parent() else "null")
		
		global_position = new_global_pos


func _on_button_down() -> void:
	# Check if card is playable before starting drag
	var can_play: bool = CombatManager.can_play_card(card_def, tier) if CombatManager else false
	if not can_play:
		return
	
	# Kill ALL existing tweens (including hover tweens)
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Start dragging
	is_dragging = true
	is_being_played = false
	original_position = position
	original_global_position = global_position
	original_parent = get_parent()  # Store original parent for context checking
	original_z_index = z_index
	z_index = 100  # Bring to front while dragging
	drag_offset = get_global_mouse_position() - global_position
	
	print("[CardUI DEBUG] Drag started - card: ", card_def.card_name if card_def else "null", 
		  " | local pos: ", original_position, " | global pos: ", original_global_position,
		  " | parent: ", str(get_parent().name) if get_parent() else "null")
	
	# Scale up while dragging
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	
	card_drag_started.emit(card_def, tier, hand_index)


func _on_button_up() -> void:
	if not is_dragging:
		# Simple click - show hint to drag
		if card_def:
			card_clicked.emit(card_def, tier, hand_index)
		return
	
	# End dragging
	is_dragging = false
	z_index = original_z_index
	
	# Get drop position before resetting
	var drop_pos: Vector2 = get_global_mouse_position()
	
	print("[CardUI DEBUG] Drag ended - card: ", card_def.card_name if card_def else "null",
		  " | current global pos: ", global_position, " | drop pos: ", drop_pos,
		  " | original local pos: ", original_position, " | original global pos: ", original_global_position,
		  " | parent: ", str(get_parent().name) if get_parent() else "null")
	
	# Emit drag ended signal with drop position
	card_drag_ended.emit(card_def, tier, hand_index, drop_pos)
	
	# Only animate return if card is NOT being played (CombatScreen will set is_being_played flag)
	# Wait a frame to see if card gets played
	await get_tree().process_frame
	
	# Kill ALL tweens before returning (including hover tweens)
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Check parent context - if parent changed, original_position might be invalid
	var current_parent: Node = get_parent()
	var parent_changed: bool = false
	if current_parent and original_parent:
		# Check if we're still in the hand
		var is_in_hand: bool = current_parent == original_parent
		if not is_in_hand:
			parent_changed = true
			print("[CardUI DEBUG] WARNING - Parent changed! Original parent context may be invalid")
	
	if not is_being_played and is_instance_valid(self) and current_parent == original_parent:
		# Only return if we're still in the original parent (CardHand)
		# HBoxContainer will automatically position the card, so we just need to:
		# 1. Reset position to let container handle it
		# 2. Animate scale back to normal
		
		print("[CardUI DEBUG] Returning card - card: ", card_def.card_name if card_def else "null",
			  " | current position: ", position, " | original position: ", original_position)
		
		# Kill any existing tweens
		if active_tween and active_tween.is_valid():
			active_tween.kill()
		
		# Reset position immediately - let HBoxContainer handle layout
		# Store the original position's Y for hover effects
		var hand_container: HBoxContainer = current_parent as HBoxContainer
		if hand_container:
			# HBoxContainer will auto-position, but we need to reset Y to 0 for hover to work
			position = Vector2(position.x, 0.0)  # Keep X, reset Y
			set_meta("hover_base_y", 0.0)
		else:
			# Not in HBoxContainer - use original position
			position = original_position
			set_meta("hover_base_y", original_position.y)
		
		# Animate scale back to normal
		active_tween = create_tween()
		active_tween.set_ease(Tween.EASE_OUT)
		active_tween.set_trans(Tween.TRANS_BACK)
		active_tween.tween_property(self, "scale", Vector2.ONE, 0.25)
		
		active_tween.finished.connect(func():
			active_tween = null
			print("[CardUI DEBUG] Return animation finished - final position: ", position)
		)
	elif parent_changed:
		print("[CardUI DEBUG] Card parent changed, cannot return - card: ", card_def.card_name if card_def else "null")
	else:
		print("[CardUI DEBUG] Card is being played, skipping return animation - card: ", card_def.card_name if card_def else "null")


func _on_mouse_entered() -> void:
	if is_dragging:
		return
	
	# Kill any existing hover tween
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Store original position for hover (use current position, not meta)
	var hover_base_y: float = position.y
	if not has_meta("hover_base_y"):
		set_meta("hover_base_y", hover_base_y)
	else:
		# Update hover_base_y to current position if card was moved
		hover_base_y = get_meta("hover_base_y", position.y)
	
	# Hover effect - scale up and lift card
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
	hover_tween.parallel().tween_property(self, "position:y", hover_base_y - 50, 0.1)
	hover_tween.finished.connect(func(): hover_tween = null)
	
	# Bring to front
	z_index = 10
	
	card_hovered.emit(card_def, tier, true)


func _on_mouse_exited() -> void:
	if is_dragging:
		return
	
	# Kill any existing hover tween
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Reset hover effect - get the base Y from meta, or use current position if not set
	var base_y: float = get_meta("hover_base_y", position.y + 50)
	
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	hover_tween.parallel().tween_property(self, "position:y", base_y, 0.1)
	hover_tween.finished.connect(func(): hover_tween = null)
	
	z_index = 0
	
	card_hovered.emit(card_def, tier, false)
