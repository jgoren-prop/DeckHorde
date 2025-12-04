extends Control
## CardUI - Visual representation of a card in hand
## Supports drag-and-drop targeting for cards that require targets
## Features compact display with expand-on-hover for readability

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
@onready var target_label: Label = $CardBackground/VBox/TargetRow/TargetHBox/TargetLabel
@onready var ring_indicator: Control = $CardBackground/VBox/TargetRow/TargetHBox/RingIndicator

# Footer (tags only now)
@onready var tags_label: Label = $CardBackground/VBox/Footer/TagsLabel

@onready var click_area: Button = $ClickArea

var card_def = null  # CardDefinition
var tier: int = 1
var hand_index: int = -1

# When false, card always displays at full brightness (for shop/deck viewer)
var check_playability: bool = true

# When false, card does not scale/lift on hover (for deployed weapons that use external preview)
var enable_hover_scale: bool = true

# Buff tracking for visual display
var applied_buffs: Dictionary = {}  # {buff_type: value} for visual display
var base_damage_display: int = 0  # Original damage before buffs
var buffed_damage_display: int = 0  # Damage after buffs

# Fan layout support
var fan_index: int = 0  # Position in the fan (0 = leftmost)
var fan_total: int = 1  # Total cards in fan
var fan_rotation: float = 0.0  # Rotation applied by fan layout

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

# Hover expansion settings (defaults for combat hand)
const DEFAULT_HOVER_SCALE: Vector2 = Vector2(1.5, 1.5)  # Bigger on hover for readability
const DEFAULT_HOVER_LIFT: float = 80.0  # Lift card up
const HOVER_DURATION: float = 0.12  # Animation speed
const DEFAULT_SCALE: Vector2 = Vector2(1.0, 1.0)

# Per-instance hover settings (can be overridden for different contexts like shop)
var hover_scale_amount: Vector2 = DEFAULT_HOVER_SCALE
var hover_lift_amount: float = DEFAULT_HOVER_LIFT

const TYPE_ICONS: Dictionary = {
	"weapon": "⚔️",
	"skill": "✨",
	"hex": "☠️",
	"defense": "🛡️",
	"curse": "💀"
}

# V2 Core type icons (from tags)
const CORE_TYPE_ICONS: Dictionary = {
	"gun": "🔫",
	"hex": "☠️",
	"barrier": "🚧",
	"defense": "🛡️",
	"skill": "✨",
	"engine": "⚙️"
}

# V2 Family tag colors for synergy display
const FAMILY_TAG_COLORS: Dictionary = {
	"lifedrain": Color(0.8, 0.3, 0.3),      # Red - vampire/sustain
	"hex_ritual": Color(0.6, 0.2, 0.8),     # Purple - dark magic
	"fortress": Color(0.4, 0.6, 0.8),       # Steel blue - tank
	"barrier_trap": Color(0.9, 0.6, 0.2),   # Orange - traps
	"volatile": Color(1.0, 0.4, 0.1),       # Bright orange - risky
	"engine_core": Color(0.3, 0.8, 0.5)     # Green - economy
}

# V2 Family tag display names
const FAMILY_TAG_NAMES: Dictionary = {
	"lifedrain": "Lifedrain",
	"hex_ritual": "Hex Ritual",
	"fortress": "Fortress",
	"barrier_trap": "Trap",
	"volatile": "Volatile",
	"engine_core": "Engine"
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

func _ready() -> void:
	click_area.button_down.connect(_on_button_down)
	click_area.button_up.connect(_on_button_up)
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	
	# Set pivot to bottom center for better hover animation
	pivot_offset = Vector2(size.x / 2, size.y)


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
	
	# Type icon - prefer V2 core type tag, fall back to legacy card_type
	var core_type: String = card_def.get_core_type()
	if core_type != "" and CORE_TYPE_ICONS.has(core_type):
		type_icon.text = CORE_TYPE_ICONS[core_type]
	else:
		type_icon.text = TYPE_ICONS.get(card_def.card_type, "📜")
	
	# Stats row
	_update_stats_row()
	
	# Description (flavor text with Instant/Persistent labels)
	var desc_text: String = _get_flavor_description()
	description.text = "[center]" + desc_text + "[/center]"
	
	# Target row (now shows targeting info)
	_update_target_row()
	
	# Footer (tags only)
	_update_footer()
	
	# Apply type color to background
	_apply_style()


func _update_stats_row() -> void:
	"""Update the stats row - only show non-zero values. Supports showing buffed stats."""
	# Guard against being called before @onready vars are set
	if not damage_label:
		return
	
	var damage: int = card_def.get_scaled_value("damage", tier)
	var hex_dmg: int = card_def.get_scaled_value("hex_damage", tier)
	var heal: int = card_def.get_scaled_value("heal_amount", tier)
	var armor: int = card_def.get_scaled_value("armor_amount", tier)
	var cards_draw: int = card_def.cards_to_draw
	var energy_gain: int = 0
	var duration: int = card_def.get_scaled_value("duration", tier)
	var push: int = card_def.push_amount
	
	# Store base damage for buff comparison
	base_damage_display = damage
	
	# Calculate buff bonuses from applied_buffs
	var damage_buff: int = 0
	var armor_buff: int = 0
	for buff_key: String in applied_buffs.keys():
		var buff_data: Dictionary = applied_buffs[buff_key]
		if buff_data.type == "gun_damage" or buff_data.type == "all_damage":
			damage_buff += buff_data.value
		elif buff_data.type == "armor_gain":
			armor_buff += buff_data.value
	
	# Apply buffs
	var buffed_damage: int = damage + damage_buff
	var buffed_armor: int = armor + armor_buff
	buffed_damage_display = buffed_damage
	
	# Check for energy gain (from buff_value if effect is energy related)
	if card_def.effect_type == "energy_and_draw":
		energy_gain = card_def.buff_value
	
	# Show/hide each stat label based on value
	damage_label.visible = damage > 0 or damage_buff > 0
	if damage > 0 or damage_buff > 0:
		if damage_buff > 0:
			# Show buffed damage with green color and (+X) notation
			damage_label.text = "⚔ %d (+%d)" % [buffed_damage, damage_buff]
			damage_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))  # Bright green
		else:
			damage_label.text = "⚔ " + str(damage)
			damage_label.remove_theme_color_override("font_color")  # Use default
	
	hex_label.visible = hex_dmg > 0
	if hex_dmg > 0:
		hex_label.text = "☠ " + str(hex_dmg)
	
	heal_label.visible = heal > 0
	if heal > 0:
		heal_label.text = "♥ " + str(heal)
	
	armor_label.visible = armor > 0 or armor_buff > 0
	if armor > 0 or armor_buff > 0:
		if armor_buff > 0:
			# Show buffed armor with cyan color and (+X) notation
			armor_label.text = "🛡 %d (+%d)" % [buffed_armor, armor_buff]
			armor_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.9))  # Bright cyan
		else:
			armor_label.text = "🛡 " + str(armor)
			armor_label.remove_theme_color_override("font_color")
	
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
	"""Update the target row with scope text and visual ring indicator."""
	var scope_text: String = ""
	var show_ring_indicator: bool = true
	
	# Determine scope based on target_type
	match card_def.target_type:
		"self":
			scope_text = "Self"
			show_ring_indicator = false
		"random_enemy":
			var count: int = card_def.target_count if card_def.target_count > 0 else 1
			if count == 1:
				scope_text = "Random"
			else:
				scope_text = str(count) + " Random"
		"ring":
			if card_def.requires_target:
				scope_text = "Choose Ring"
			else:
				scope_text = "In Range"
		"all_rings":
			scope_text = "All Rings"
		"all_enemies":
			scope_text = "All Enemies"
			show_ring_indicator = false
		_:
			# Default for cards without targeting (self-targeting skills)
			scope_text = "Self"
			show_ring_indicator = false
	
	# Update scope label
	target_label.text = "🎯 " + scope_text
	
	# Update ring indicator visual
	if ring_indicator:
		ring_indicator.visible = show_ring_indicator
		if show_ring_indicator:
			ring_indicator.set_targeted_rings(card_def.target_rings)
		else:
			ring_indicator.clear_targeting()


func _update_footer() -> void:
	"""Update the footer with play mode and tags."""
	# Build footer text: [INSTANT/COMBAT] │ Tags
	var play_mode_text: String = ""
	var play_mode_color: Color = Color.WHITE
	
	if card_def.has_method("is_instant") and card_def.is_instant():
		play_mode_text = "⚡ INSTANT"
		play_mode_color = Color(0.5, 0.85, 1.0)  # Cyan
	else:
		play_mode_text = "⚔️ COMBAT"
		play_mode_color = Color(1.0, 0.65, 0.35)  # Orange
	
	var tags_text: String = _format_tags_display()
	
	if tags_text != "":
		tags_label.text = play_mode_text + " │ " + tags_text
	else:
		tags_label.text = play_mode_text
	
	# Color the whole label based on play mode (will affect tags too, but that's acceptable)
	tags_label.add_theme_color_override("font_color", play_mode_color)


func _format_tags_display() -> String:
	"""Format tags for display: core type icon + important tags."""
	if card_def.tags.size() == 0:
		return ""
	
	var parts: Array[String] = []
	
	# Get core type icon (gun, hex, barrier, defense, skill, engine)
	var core_type: String = card_def.get_core_type()
	if core_type != "":
		var icon: String = CORE_TYPE_ICONS.get(core_type, "")
		if icon != "":
			parts.append(icon)
	
	# Show damage type tags (piercing, explosive, beam, etc.)
	var damage_type_icons: Dictionary = {
		"piercing": "➡️",
		"explosive": "💣",
		"beam": "⚡",
		"shock": "⚡",
		"corrosive": "🧪"
	}
	for tag: Variant in card_def.tags:
		if tag is String and damage_type_icons.has(tag):
			parts.append(damage_type_icons[tag])
	
	# Show mechanical tags (aoe, sniper, etc.)
	var mechanical_displays: Dictionary = {
		"aoe": "AOE",
		"sniper": "Sniper",
		"shotgun": "Close",
		"scaling": "Scale",
		"multi_target": "Multi",
		"ring_control": "Push",
		"rapid_fire": "Rapid"
	}
	for tag: Variant in card_def.tags:
		if tag is String and mechanical_displays.has(tag):
			parts.append(mechanical_displays[tag])
	
	# Get family tags (lifedrain, hex_ritual, fortress, etc.)
	var family_tags: Array[String] = card_def.get_family_tags()
	for family_tag: String in family_tags:
		var display_name: String = FAMILY_TAG_NAMES.get(family_tag, family_tag.capitalize())
		parts.append(display_name)
	
	if parts.size() == 0:
		return ""
	elif parts.size() == 1:
		return parts[0]
	else:
		# Format: "🔫 │ AOE, Piercing"
		var core_part: String = ""
		var other_parts: Array[String] = []
		
		if core_type != "" and parts.size() > 0:
			core_part = parts[0]
			for i: int in range(1, parts.size()):
				other_parts.append(parts[i])
		else:
			other_parts = parts
		
		if core_part != "" and other_parts.size() > 0:
			return core_part + " │ " + ", ".join(other_parts)
		elif core_part != "":
			return core_part
		else:
			return ", ".join(other_parts)


func _get_flavor_description() -> String:
	"""Get the card description with labeled effects."""
	# If card has explicit instant/persistent descriptions, use those
	var has_instant: bool = card_def.instant_description != ""
	var has_persistent: bool = card_def.persistent_description != ""
	
	if has_instant or has_persistent:
		var parts: Array[String] = []
		# Only add labels if card has BOTH instant and persistent effects
		var needs_labels: bool = has_instant and has_persistent
		if has_instant:
			var instant_text: String = _substitute_values(card_def.instant_description)
			if needs_labels:
				parts.append("[color=#88ddff]Instant:[/color] " + instant_text)
			else:
				parts.append(instant_text)
		if has_persistent:
			var persist_text: String = _substitute_values(card_def.persistent_description)
			if needs_labels:
				parts.append("[color=#ffcc55]Persistent:[/color] " + persist_text)
			else:
				parts.append(persist_text)
		return "\n".join(parts)
	
	# Fall back to auto-generated descriptions for cards without explicit descriptions
	# No "Instant:" prefix needed since card type badge already shows it
	match card_def.effect_type:
		"weapon_persistent":
			return "Deal " + str(card_def.get_scaled_value("damage", tier)) + " to random enemy."
		"instant_damage":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			if card_def.target_type == "ring" and not card_def.requires_target:
				return "Deal " + str(dmg) + " to all in range."
			elif card_def.target_type == "ring" and card_def.requires_target:
				return "Deal " + str(dmg) + " to ring."
			else:
				return "Deal " + str(dmg) + " damage."
		"scatter_damage":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			return "Deal " + str(dmg) + " to " + str(card_def.target_count) + " random."
		"damage_and_draw":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			return "Deal " + str(dmg) + ". Draw " + str(card_def.cards_to_draw) + "."
		"damage_and_heal":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			var heal: int = card_def.get_scaled_value("heal_amount", tier)
			return "Deal " + str(dmg) + ", heal " + str(heal) + "."
		"heal":
			var heal: int = card_def.get_scaled_value("heal_amount", tier)
			return "Heal " + str(heal) + " HP."
		"energy_and_draw":
			return "Gain " + str(card_def.buff_value) + " Energy. Draw " + str(card_def.cards_to_draw) + "."
		"gambit":
			return "Discard hand, draw " + str(card_def.cards_to_draw) + "."
		"buff":
			if card_def.buff_type == "hex_damage":
				return "Next Hex deals double."
			return "Apply buff."
		"apply_hex":
			var hex: int = card_def.get_scaled_value("hex_damage", tier)
			if card_def.target_type == "all_enemies":
				return "Apply " + str(hex) + " Hex to ALL."
			elif card_def.target_type == "ring" and card_def.requires_target:
				return "Apply " + str(hex) + " Hex to ring."
			elif card_def.target_type == "ring":
				return "Apply " + str(hex) + " Hex in range."
			return "Apply " + str(hex) + " Hex."
		"damage_and_hex":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			var hex: int = card_def.get_scaled_value("hex_damage", tier)
			return "Deal " + str(dmg) + " + " + str(hex) + " Hex."
		"gain_armor":
			var armor: int = card_def.get_scaled_value("armor_amount", tier)
			return "Gain " + str(armor) + " Armor."
		"ring_barrier":
			var dmg: int = card_def.get_scaled_value("damage", tier)
			var dur: int = card_def.get_scaled_value("duration", tier)
			return "Barrier (" + str(dmg) + " dmg, " + str(dur) + "t)."
		"armor_and_lifesteal":
			var armor: int = card_def.get_scaled_value("armor_amount", tier)
			return str(armor) + " Armor. Heal per Melee."
		"push_enemies":
			if card_def.requires_target:
				return "Push ring back " + str(card_def.push_amount) + "."
			else:
				return "Push back " + str(card_def.push_amount) + " ring."
		"shield_bash":
			return "Deal damage = Armor."
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
	style.set_corner_radius_all(8)
	
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
	
	# Reset rotation when dragging
	rotation = 0.0
	
	# Scale up while dragging (from hover scale back to slightly larger)
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	
	card_drag_started.emit(card_def, tier, hand_index)


func _on_button_up() -> void:
	if not is_dragging:
		# Simple click - emit signal
		if card_def:
			card_clicked.emit(card_def, tier, hand_index)
		
		# Fix for stuck hover: Button press can prevent mouse_exited from firing
		# Check if mouse is actually still over this card, reset hover if not
		await get_tree().process_frame  # Wait for any position changes to settle
		if is_instance_valid(self) and enable_hover_scale:
			var mouse_pos: Vector2 = get_global_mouse_position()
			var rect: Rect2 = click_area.get_global_rect()
			if not rect.has_point(mouse_pos):
				_force_reset_hover()
		return
	
	# End dragging
	is_dragging = false
	z_index = original_z_index
	
	# Get drop position before resetting
	var drop_pos: Vector2 = get_global_mouse_position()
	
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
	var _parent_changed: bool = false
	if current_parent and original_parent:
		# Check if we're still in the hand
		var is_in_hand: bool = current_parent == original_parent
		if not is_in_hand:
			_parent_changed = true
	
	if not is_being_played and is_instance_valid(self) and current_parent == original_parent:
		# Kill any existing tweens
		if active_tween and active_tween.is_valid():
			active_tween.kill()
		
		# Restore fan rotation
		rotation = fan_rotation
		
		# Reset position for fan layout
		position = original_position
		
		# Animate scale back to normal
		active_tween = create_tween()
		active_tween.set_ease(Tween.EASE_OUT)
		active_tween.set_trans(Tween.TRANS_BACK)
		active_tween.tween_property(self, "scale", DEFAULT_SCALE, 0.25)
		
		active_tween.finished.connect(func():
			active_tween = null
		)


func _on_mouse_entered() -> void:
	if is_dragging:
		return
	
	# Emit hover signal regardless (for external preview systems)
	card_hovered.emit(card_def, tier, true)
	
	# Skip scale/lift effect if disabled (e.g., deployed weapons use external preview)
	if not enable_hover_scale:
		return
	
	# Kill any existing hover tween
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Store original position for hover
	if not has_meta("hover_base_pos"):
		set_meta("hover_base_pos", position)
		set_meta("hover_base_rotation", rotation)
	
	var base_pos: Vector2 = get_meta("hover_base_pos", position)
	
	# Hover effect - scale up and lift card up (negative Y), reset rotation for readability
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_BACK)
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", hover_scale_amount, HOVER_DURATION)
	hover_tween.tween_property(self, "position:y", base_pos.y - hover_lift_amount, HOVER_DURATION)
	hover_tween.tween_property(self, "rotation", 0.0, HOVER_DURATION)  # Straighten card
	hover_tween.finished.connect(func(): hover_tween = null)
	
	# Bring to front
	z_index = 50


func _on_mouse_exited() -> void:
	if is_dragging:
		return
	
	# Emit hover signal regardless (for external preview systems)
	card_hovered.emit(card_def, tier, false)
	
	# Skip scale/lift reset if disabled (e.g., deployed weapons use external preview)
	if not enable_hover_scale:
		return
	
	_animate_hover_reset()


func _animate_hover_reset() -> void:
	"""Animate the card back to its base (non-hovered) state."""
	# Kill any existing hover tween
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Reset hover effect
	var base_pos: Vector2 = get_meta("hover_base_pos", position)
	var base_rotation: float = get_meta("hover_base_rotation", fan_rotation)
	
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_QUAD)
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", DEFAULT_SCALE, HOVER_DURATION)
	hover_tween.tween_property(self, "position:y", base_pos.y, HOVER_DURATION)
	hover_tween.tween_property(self, "rotation", base_rotation, HOVER_DURATION)  # Restore fan rotation
	hover_tween.finished.connect(func(): hover_tween = null)
	
	z_index = fan_index  # Use fan index for z-ordering


func _force_reset_hover() -> void:
	"""Immediately reset hover state without animation (for stuck hover fix)."""
	# Kill any existing hover tween
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Reset to base state immediately
	var base_pos: Vector2 = get_meta("hover_base_pos", position)
	var base_rotation: float = get_meta("hover_base_rotation", fan_rotation)
	
	scale = DEFAULT_SCALE
	position.y = base_pos.y
	rotation = base_rotation
	z_index = fan_index


func set_fan_position(index: int, total: int, pos: Vector2, rot: float) -> void:
	"""Set the card's position and rotation in the fan layout."""
	fan_index = index
	fan_total = total
	fan_rotation = rot
	
	position = pos
	rotation = rot
	z_index = index
	
	# Store for hover restoration
	set_meta("hover_base_pos", pos)
	set_meta("hover_base_rotation", rot)
	
	# Update pivot for better rotation (center-bottom)
	pivot_offset = Vector2(size.x / 2, size.y)


# =============================================================================
# BUFF VISUAL FEEDBACK SYSTEM
# =============================================================================

func apply_buff(buff_type: String, buff_value: int, tag_filter: String = "") -> void:
	"""Apply a buff to this card with visual feedback. Called from CombatLane."""
	# Check if this card should receive the buff (based on tag filter)
	if not tag_filter.is_empty() and not card_def.has_tag(tag_filter):
		return
	
	# Store the buff
	var buff_key: String = buff_type + "_" + tag_filter
	if not applied_buffs.has(buff_key):
		applied_buffs[buff_key] = {"type": buff_type, "value": 0, "tag_filter": tag_filter}
	applied_buffs[buff_key].value += buff_value
	
	# Update display to show buffed stats
	_update_stats_row()
	
	# Play buff visual effects
	_play_buff_animation(buff_type, buff_value)


func _play_buff_animation(buff_type: String, buff_value: int) -> void:
	"""Play visual effects when a buff is applied to this card."""
	if not is_inside_tree():
		return
	
	# Determine buff color based on type
	var buff_color: Color = Color(0.4, 1.0, 0.5)  # Default green
	var buff_icon: String = "⚔"
	
	match buff_type:
		"gun_damage", "all_damage":
			buff_color = Color(0.4, 1.0, 0.5)  # Bright green
			buff_icon = "⚔"
		"armor_gain":
			buff_color = Color(0.4, 1.0, 0.9)  # Cyan
			buff_icon = "🛡"
		"hex_damage":
			buff_color = Color(0.8, 0.4, 1.0)  # Purple
			buff_icon = "☠"
		_:
			buff_color = Color(1.0, 0.9, 0.4)  # Gold
			buff_icon = "✦"
	
	# Create floating buff notification
	_spawn_buff_floater(buff_icon, buff_value, buff_color)
	
	# Pulse the card border
	_play_buff_pulse(buff_color)
	
	# Brief glow effect
	_play_buff_glow(buff_color)


func _spawn_buff_floater(icon: String, value: int, color: Color) -> void:
	"""Spawn a floating text showing the buff amount."""
	var floater: Label = Label.new()
	floater.text = "%s +%d" % [icon, value]
	floater.add_theme_font_size_override("font_size", 20)
	floater.add_theme_color_override("font_color", color)
	floater.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	floater.add_theme_constant_override("outline_size", 3)
	floater.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floater.z_index = 200
	
	# Position above the card
	floater.position = Vector2(size.x / 2 - 30, -30)
	add_child(floater)
	
	# Animate: float up and fade out
	var tween: Tween = floater.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position:y", floater.position.y - 60, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tween.tween_property(floater, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(floater, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_callback(floater.queue_free).set_delay(1.2)


func _play_buff_pulse(_color: Color) -> void:
	"""Pulse the card's scale briefly to draw attention."""
	if not card_background:
		return
	
	# Save original scale
	var original_scale: Vector2 = scale
	
	# Create pulse tween
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 1.12, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale, 0.25).set_ease(Tween.EASE_IN_OUT)


func _play_buff_glow(color: Color) -> void:
	"""Create a brief glow effect around the card."""
	if not card_background:
		return
	
	# Get the current style
	var current_style = card_background.get_theme_stylebox("panel")
	if not current_style:
		return
	
	# Create a new style with glow border
	var glow_style: StyleBoxFlat = current_style.duplicate() if current_style is StyleBoxFlat else StyleBoxFlat.new()
	glow_style.border_color = color
	glow_style.set_border_width_all(4)
	glow_style.shadow_color = Color(color.r, color.g, color.b, 0.6)
	glow_style.shadow_size = 8
	
	# Apply glow style
	card_background.add_theme_stylebox_override("panel", glow_style)
	
	# Animate back to original
	await get_tree().create_timer(0.4).timeout
	
	if is_instance_valid(card_background) and is_instance_valid(self):
		# Restore original style
		_apply_style()


func clear_buffs() -> void:
	"""Clear all applied buffs and restore original display."""
	applied_buffs.clear()
	if card_def:
		_update_stats_row()


func get_total_damage_with_buffs() -> int:
	"""Get the total damage including all applied buffs."""
	return buffed_damage_display


func has_buffs() -> bool:
	"""Check if this card has any buffs applied."""
	return not applied_buffs.is_empty()
