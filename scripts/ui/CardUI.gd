extends Control
## CardUI - Visual representation of a card (V5 Design)
## Layout matches DESIGN_V5.md specification:
## - Top: Cost (left), Type icons + Damage (right)
## - Card Name (centered)
## - Art Area
## - Effect text
## - Target + Ring indicator
## - Footer: Categories + Tier

signal card_clicked(card_def, tier: int, hand_index: int)  # card_def: CardDefinition
signal card_hovered(card_def, tier: int, is_hovering: bool)  # card_def: CardDefinition
signal card_drag_started(card_def, tier: int, hand_index: int)  # card_def: CardDefinition
signal card_drag_ended(card_def, tier: int, hand_index: int, drop_position: Vector2)  # card_def: CardDefinition

# Node references - V5 Layout
@onready var card_background: Panel = $CardBackground
@onready var cost_bg: Panel = $CardBackground/VBox/TopRow/CostBG
@onready var cost_label: Label = $CardBackground/VBox/TopRow/CostBG/CostLabel
@onready var type_icons: Label = $CardBackground/VBox/TopRow/TypeDamageVBox/TypeIcons
@onready var damage_number: Label = $CardBackground/VBox/TopRow/TypeDamageVBox/DamageNumber
@onready var name_label: Label = $CardBackground/VBox/NameLabel
@onready var art_area: Panel = $CardBackground/VBox/ArtArea
@onready var art_placeholder: Label = $CardBackground/VBox/ArtArea/ArtPlaceholder
@onready var description: RichTextLabel = $CardBackground/VBox/Description

# Weapon sprite display (uses Weapon2DDisplay which can rotate to face targets)
var _weapon_3d: Control = null  # Weapon2DDisplay instance (kept name for API compatibility)
var _is_morphed_to_3d: bool = false  # True when staged in combat lane (weapon mode active)
var _morph_in_progress: bool = false

# Morph signals
signal artwork_morph_started()
signal artwork_morph_completed()
signal weapon_fire_started()
signal weapon_fire_completed()

@onready var target_label: Label = $CardBackground/VBox/TargetRow/TargetLabel
@onready var ring_indicator: Control = $CardBackground/VBox/TargetRow/RingIndicator
@onready var category_label: Label = $CardBackground/VBox/Footer/FooterHBox/CategoryLabel
@onready var tier_badge: Label = $CardBackground/VBox/Footer/FooterHBox/TierBadge
@onready var footer: Panel = $CardBackground/VBox/Footer
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
var original_global_position: Vector2 = Vector2.ZERO
var original_parent: Node = null
var original_z_index: int = 0
var is_being_played: bool = false
var active_tween: Tween = null
var hover_tween: Tween = null

# Hover expansion settings
const DEFAULT_HOVER_SCALE: Vector2 = Vector2(1.5, 1.5)
const DEFAULT_HOVER_LIFT: float = 80.0
const HOVER_DURATION: float = 0.12
const DEFAULT_SCALE: Vector2 = Vector2(1.0, 1.0)

var hover_scale_amount: Vector2 = DEFAULT_HOVER_SCALE
var hover_lift_amount: float = DEFAULT_HOVER_LIFT

# V5 Damage Type Icons
const DAMAGE_TYPE_ICONS: Dictionary = {
	"kinetic": "🔫",
	"thermal": "🔥",
	"arcane": "✨"
}

# V5 Category Icons
const CATEGORY_ICONS: Dictionary = {
	"kinetic": "🔫",
	"thermal": "🔥",
	"arcane": "✨",
	"fortress": "🛡️",
	"shadow": "🗡️",
	"utility": "⚡",
	"control": "🚧",
	"volatile": "💀"
}

# V5 Category Colors
const CATEGORY_COLORS: Dictionary = {
	"kinetic": Color(0.7, 0.7, 0.85),
	"thermal": Color(1.0, 0.5, 0.2),
	"arcane": Color(0.6, 0.3, 0.9),
	"fortress": Color(0.4, 0.6, 0.85),
	"shadow": Color(0.4, 0.4, 0.5),
	"utility": Color(0.3, 0.9, 0.5),
	"control": Color(0.9, 0.7, 0.2),
	"volatile": Color(1.0, 0.3, 0.3)
}

# V5 Category Display Names
const CATEGORY_NAMES: Dictionary = {
	"kinetic": "Kinetic",
	"thermal": "Thermal",
	"arcane": "Arcane",
	"fortress": "Fortress",
	"shadow": "Shadow",
	"utility": "Utility",
	"control": "Control",
	"volatile": "Volatile"
}

# V5 4-tier system colors
const TIER_COLORS: Array[Color] = [
	Color(0.69, 0.69, 0.69),  # Tier 1 - Gray
	Color(0.3, 0.85, 0.4),    # Tier 2 - Green
	Color(0.3, 0.6, 1.0),     # Tier 3 - Blue
	Color(1.0, 0.8, 0.2)      # Tier 4 - Gold
]

# V5 Tier names for display (e.g., on card name suffix)
const TIER_NAMES: Array[String] = ["", "+", "++", "+++"]

# Tier badge icons
const TIER_BADGE_ICONS: Array[String] = ["⬜", "🟩", "🟦", "🟨"]

# Background color based on primary damage type
const DAMAGE_TYPE_BG_COLORS: Dictionary = {
	"kinetic": Color(0.12, 0.12, 0.15),
	"thermal": Color(0.18, 0.1, 0.08),
	"arcane": Color(0.14, 0.08, 0.18)
}


func _ready() -> void:
	click_area.button_down.connect(_on_button_down)
	click_area.button_up.connect(_on_button_up)
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	
	# Set pivot to bottom center for better hover animation
	pivot_offset = Vector2(size.x / 2, size.y)
	
	# Setup card artwork in art area
	_setup_card_artwork()


func setup(card, card_tier: int, index: int) -> void:  # card: CardDefinition
	card_def = card
	tier = card_tier
	hand_index = index
	
	if not is_node_ready():
		await ready
	
	# Setup both 2D and 3D artwork
	if _weapon_3d and card_def:
		_weapon_3d.setup(card_def)
	
	_update_display()


func _setup_card_artwork() -> void:
	"""Setup the CardArtwork and Weapon2DDisplay components in the art area."""
	if not art_area:
		return
	
	# Hide the placeholder text
	if art_placeholder:
		art_placeholder.visible = false
	
	# Load and create 2D weapon sprite display (visible from start - shows weapon sprite)
	# Weapon2DDisplay supports rotation for targeting enemies
	var Weapon2DDisplayClass = load("res://scripts/ui/Weapon2DDisplay.gd")
	if Weapon2DDisplayClass:
		_weapon_3d = Weapon2DDisplayClass.new()
		_weapon_3d.name = "Weapon2DInstance"
		_weapon_3d.set_anchors_preset(Control.PRESET_FULL_RECT)
		_weapon_3d.modulate.a = 1.0  # Visible from start
		_weapon_3d.fire_started.connect(_on_weapon_fire_started)
		_weapon_3d.fire_completed.connect(_on_weapon_fire_completed)
		art_area.add_child(_weapon_3d)
	
	# Setup if we already have card data
	if card_def:
		if _weapon_3d:
			_weapon_3d.setup(card_def)


func _update_display() -> void:
	if not card_def:
		return
	
	# === TOP ROW: Cost (left), Type + Damage (right) ===
	cost_label.text = str(card_def.base_cost)
	
	# Type icons (show damage type icon)
	var damage_type: String = card_def.damage_type
	var type_icon_text: String = ""
	if damage_type != "" and damage_type != "none" and DAMAGE_TYPE_ICONS.has(damage_type):
		type_icon_text = DAMAGE_TYPE_ICONS[damage_type]
	else:
		# Fall back to primary category icon for instant cards
		var categories: Array = card_def.categories
		if categories.size() > 0:
			var primary_cat: String = str(categories[0])
			type_icon_text = CATEGORY_ICONS.get(primary_cat, "📜")
		else:
			type_icon_text = "📜"
	type_icons.text = type_icon_text
	
	# Calculated damage number
	var base_dmg: int = card_def.base_damage
	var damage: int = _calculate_v5_display_damage(base_dmg)
	base_damage_display = damage
	
	# Calculate buff bonuses
	var damage_buff: int = 0
	for buff_key: String in applied_buffs.keys():
		var buff_data: Dictionary = applied_buffs[buff_key]
		if buff_data.type == "all_damage" or buff_data.type == "kinetic_damage" or buff_data.type == "thermal_damage" or buff_data.type == "arcane_damage":
			damage_buff += buff_data.value
	
	var final_damage: int = damage + damage_buff
	buffed_damage_display = final_damage
	
	if final_damage > 0:
		if damage_buff > 0:
			damage_number.text = str(final_damage)
			damage_number.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		else:
			damage_number.text = str(final_damage)
			damage_number.remove_theme_color_override("font_color")
		damage_number.visible = true
	else:
		damage_number.visible = false
	
	# === NAME (centered) ===
	name_label.text = card_def.card_name.to_upper()
	
	# === DESCRIPTION (effect text) ===
	var desc_text: String = _get_effect_description()
	if desc_text != "":
		description.text = "[center]" + desc_text + "[/center]"
		description.visible = true
	else:
		description.visible = false
	
	# === TARGET ROW ===
	_update_target_row()
	
	# === FOOTER: Categories + Tier ===
	_update_footer()
	
	# === APPLY STYLE ===
	_apply_style()


func _calculate_v5_display_damage(base: int) -> int:
	"""Calculate display damage using V5 formula."""
	if base <= 0:
		return 0
	
	# Apply tier scaling to base
	var tier_base_mult: float = 1.0 + (tier - 1) * 0.5  # +50% per tier
	var scaled_base: int = int(base * tier_base_mult)
	
	# Add stat scaling preview (uses current player stats if available)
	var stat_bonus: int = 0
	if RunManager and RunManager.player_stats:
		var tier_scale_mult: float = 1.0 + (tier - 1) * 0.25  # +25% scaling per tier
		if card_def.kinetic_scaling > 0:
			stat_bonus += int(RunManager.player_stats.kinetic * card_def.kinetic_scaling * tier_scale_mult / 100.0)
		if card_def.thermal_scaling > 0:
			stat_bonus += int(RunManager.player_stats.thermal * card_def.thermal_scaling * tier_scale_mult / 100.0)
		if card_def.arcane_scaling > 0:
			stat_bonus += int(RunManager.player_stats.arcane * card_def.arcane_scaling * tier_scale_mult / 100.0)
		if card_def.armor_start_scaling > 0:
			stat_bonus += int(RunManager.player_stats.armor_start * card_def.armor_start_scaling * tier_scale_mult / 100.0)
	
	return scaled_base + stat_bonus


func _get_effect_description() -> String:
	"""Get the card effect description."""
	# Check for explicit description first
	if card_def.description != "":
		return _substitute_values(card_def.description)
	
	# V5 auto-generated descriptions based on effects
	var parts: Array[String] = []
	
	var hex_stacks: int = card_def.hex_stacks if card_def.get("hex_stacks") else card_def.hex_damage
	var burn_stacks: int = card_def.burn_stacks if card_def.get("burn_stacks") else card_def.burn_damage
	var heal: int = card_def.heal_amount
	var armor: int = card_def.armor_gain if card_def.get("armor_gain") else card_def.armor_amount
	var cards_drawn: int = card_def.draw_cards if card_def.get("draw_cards") else card_def.cards_to_draw
	var energy: int = card_def.energy_gain if card_def.get("energy_gain") else 0
	var self_dmg: int = card_def.self_damage
	var push: int = card_def.push_amount
	var barrier_dmg: int = card_def.barrier_damage if card_def.get("barrier_damage") else 0
	var barrier_uses: int = card_def.barrier_uses if card_def.get("barrier_uses") else card_def.duration
	
	if hex_stacks > 0:
		parts.append("☠️ " + str(hex_stacks) + " Hex")
	if burn_stacks > 0:
		parts.append("🔥 " + str(burn_stacks) + " Burn")
	if heal > 0:
		parts.append("❤️ " + str(heal))
	if armor > 0:
		parts.append("🛡️ +" + str(armor))
	if cards_drawn > 0:
		parts.append("📜 " + str(cards_drawn))
	if energy > 0:
		parts.append("⚡ +" + str(energy))
	if push > 0:
		parts.append("➡️ " + str(push))
	if self_dmg > 0:
		parts.append("💔 " + str(self_dmg))
	if barrier_dmg > 0 and barrier_uses > 0:
		parts.append("🚧 " + str(barrier_dmg) + "×" + str(barrier_uses))
	
	return " ".join(parts)


func _substitute_values(text: String) -> String:
	"""Replace placeholders with actual V5 values."""
	var result: String = text
	
	result = result.replace("{damage}", str(_calculate_v5_display_damage(card_def.base_damage)))
	
	var hex_stacks: int = card_def.hex_stacks if card_def.get("hex_stacks") else card_def.hex_damage
	result = result.replace("{hex}", str(hex_stacks))
	result = result.replace("{hex_stacks}", str(hex_stacks))
	
	var burn_stacks: int = card_def.burn_stacks if card_def.get("burn_stacks") else card_def.burn_damage
	result = result.replace("{burn}", str(burn_stacks))
	result = result.replace("{burn_stacks}", str(burn_stacks))
	
	var armor: int = card_def.armor_gain if card_def.get("armor_gain") else card_def.armor_amount
	result = result.replace("{armor}", str(armor))
	
	var cards_drawn: int = card_def.draw_cards if card_def.get("draw_cards") else card_def.cards_to_draw
	result = result.replace("{draw}", str(cards_drawn))
	
	var energy: int = card_def.energy_gain if card_def.get("energy_gain") else 0
	result = result.replace("{energy}", str(energy))
	
	result = result.replace("{push}", str(card_def.push_amount))
	result = result.replace("{self_damage}", str(card_def.self_damage))
	
	var barrier_dmg: int = card_def.barrier_damage if card_def.get("barrier_damage") else 0
	result = result.replace("{barrier_damage}", str(barrier_dmg))
	
	var barrier_uses: int = card_def.barrier_uses if card_def.get("barrier_uses") else 0
	result = result.replace("{barrier_uses}", str(barrier_uses))
	
	return result


func _update_target_row() -> void:
	"""Update the target row with scope text and visual ring indicator."""
	var scope_text: String = ""
	var show_ring_indicator: bool = true
	
	var target_type: String = card_def.target_type
	var target_count: int = card_def.target_count
	var requires_target: bool = card_def.requires_target
	var target_rings: Array = card_def.target_rings
	
	match target_type:
		"self":
			scope_text = "Self"
			show_ring_indicator = false
		"random_enemy":
			# Note: Despite the name, combat actually targets closest enemy
			if target_count == 1:
				scope_text = "Closest"
			else:
				scope_text = str(target_count) + " Closest"
		"ring":
			if requires_target:
				scope_text = "Choose Ring"
			else:
				scope_text = "In Range"
		"all_rings":
			scope_text = "All Rings"
		"all_enemies":
			scope_text = "All"
			show_ring_indicator = false
		_:
			scope_text = "Self"
			show_ring_indicator = false
	
	target_label.text = "🎯 " + scope_text
	
	if ring_indicator:
		ring_indicator.visible = show_ring_indicator
		if show_ring_indicator:
			ring_indicator.set_targeted_rings(target_rings)
		else:
			ring_indicator.clear_targeting()


func _update_footer() -> void:
	"""Update the footer with V5 categories and tier badge."""
	var categories: Array = card_def.categories
	
	# Format categories with icons
	var cat_parts: Array[String] = []
	for cat in categories:
		var cat_str: String = str(cat)
		var icon: String = CATEGORY_ICONS.get(cat_str, "")
		var cat_name: String = CATEGORY_NAMES.get(cat_str, cat_str.capitalize())
		if icon != "":
			cat_parts.append(icon + " " + cat_name)
		else:
			cat_parts.append(cat_name)
	
	if cat_parts.size() > 0:
		category_label.text = " │ ".join(cat_parts)
	else:
		category_label.text = ""
	
	# Color based on primary category
	if categories.size() > 0:
		var primary_cat: String = str(categories[0])
		var cat_color: Color = CATEGORY_COLORS.get(primary_cat, Color(0.6, 0.6, 0.65))
		category_label.add_theme_color_override("font_color", cat_color)
	
	# Tier badge - always show for all tiers (T1-T4)
	var tier_idx: int = mini(tier - 1, 3)
	var tier_color: Color = TIER_COLORS[tier_idx]
	var tier_icon: String = TIER_BADGE_ICONS[tier_idx]
	
	tier_badge.text = "T" + str(tier) + " " + tier_icon
	tier_badge.add_theme_color_override("font_color", tier_color)
	tier_badge.visible = true


func _apply_style() -> void:
	"""Apply V5 visual style to the card."""
	var style: StyleBoxFlat = StyleBoxFlat.new()
	
	# Base color from damage type
	var damage_type: String = card_def.damage_type
	var base_color: Color = DAMAGE_TYPE_BG_COLORS.get(damage_type, Color(0.12, 0.12, 0.15))
	style.bg_color = base_color
	
	# Border color based on 4-tier system
	var tier_idx: int = mini(tier - 1, 3)
	var tier_color: Color = TIER_COLORS[tier_idx]
	style.border_color = tier_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	
	card_background.add_theme_stylebox_override("panel", style)
	
	# Cost background style
	var cost_style: StyleBoxFlat = StyleBoxFlat.new()
	cost_style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	cost_style.border_color = Color(1.0, 0.85, 0.2, 0.9)
	cost_style.set_border_width_all(2)
	cost_style.set_corner_radius_all(6)
	cost_bg.add_theme_stylebox_override("panel", cost_style)
	
	# Art area style
	var art_style: StyleBoxFlat = StyleBoxFlat.new()
	art_style.bg_color = Color(0.08, 0.08, 0.1, 0.6)
	art_style.set_corner_radius_all(4)
	art_area.add_theme_stylebox_override("panel", art_style)
	
	# Footer style
	var footer_style: StyleBoxFlat = StyleBoxFlat.new()
	footer_style.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	footer_style.set_corner_radius_all(4)
	footer.add_theme_stylebox_override("panel", footer_style)
	
	# Check if playable
	if check_playability:
		var can_play: bool = CombatManager.can_play_card(card_def, tier) if CombatManager else false
		if not can_play:
			modulate = Color(0.5, 0.5, 0.55, 1.0)
			cost_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4, 1.0))
		else:
			modulate = Color.WHITE
			cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	else:
		modulate = Color.WHITE
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))


func _process(_delta: float) -> void:
	if is_dragging:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var new_global_pos: Vector2 = mouse_pos - drag_offset
		global_position = new_global_pos


func _on_button_down() -> void:
	var can_play: bool = CombatManager.can_play_card(card_def, tier) if CombatManager else false
	if not can_play:
		return
	
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	is_dragging = true
	is_being_played = false
	original_position = position
	original_global_position = global_position
	original_parent = get_parent()
	original_z_index = z_index
	z_index = 100
	drag_offset = get_global_mouse_position() - global_position
	
	rotation = 0.0
	
	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	
	card_drag_started.emit(card_def, tier, hand_index)


func _on_button_up() -> void:
	if not is_dragging:
		if card_def:
			card_clicked.emit(card_def, tier, hand_index)
		
		await get_tree().process_frame
		if is_instance_valid(self) and enable_hover_scale:
			var mouse_pos: Vector2 = get_global_mouse_position()
			var rect: Rect2 = click_area.get_global_rect()
			if not rect.has_point(mouse_pos):
				_force_reset_hover()
		return
	
	is_dragging = false
	z_index = original_z_index
	
	var drop_pos: Vector2 = get_global_mouse_position()
	card_drag_ended.emit(card_def, tier, hand_index, drop_pos)
	
	await get_tree().process_frame
	
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	var current_parent: Node = get_parent()
	var _parent_changed: bool = false
	if current_parent and original_parent:
		var is_in_hand: bool = current_parent == original_parent
		if not is_in_hand:
			_parent_changed = true
	
	if not is_being_played and is_instance_valid(self) and current_parent == original_parent:
		if active_tween and active_tween.is_valid():
			active_tween.kill()
		
		rotation = fan_rotation
		position = original_position
		
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
	
	card_hovered.emit(card_def, tier, true)
	
	if not enable_hover_scale:
		return
	
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	if not has_meta("hover_base_pos"):
		set_meta("hover_base_pos", position)
		set_meta("hover_base_rotation", rotation)
	
	var base_pos: Vector2 = get_meta("hover_base_pos", position)
	
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_BACK)
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", hover_scale_amount, HOVER_DURATION)
	hover_tween.tween_property(self, "position:y", base_pos.y - hover_lift_amount, HOVER_DURATION)
	hover_tween.tween_property(self, "rotation", 0.0, HOVER_DURATION)
	hover_tween.finished.connect(func(): hover_tween = null)
	
	z_index = 50


func _on_mouse_exited() -> void:
	if is_dragging:
		return
	
	card_hovered.emit(card_def, tier, false)
	
	if not enable_hover_scale:
		return
	
	_animate_hover_reset()


func _animate_hover_reset() -> void:
	"""Animate the card back to its base (non-hovered) state."""
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	var base_pos: Vector2 = get_meta("hover_base_pos", position)
	var base_rotation: float = get_meta("hover_base_rotation", fan_rotation)
	
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_QUAD)
	hover_tween.set_parallel(true)
	hover_tween.tween_property(self, "scale", DEFAULT_SCALE, HOVER_DURATION)
	hover_tween.tween_property(self, "position:y", base_pos.y, HOVER_DURATION)
	hover_tween.tween_property(self, "rotation", base_rotation, HOVER_DURATION)
	hover_tween.finished.connect(func(): hover_tween = null)
	
	z_index = fan_index


func _force_reset_hover() -> void:
	"""Immediately reset hover state without animation."""
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
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
	
	set_meta("hover_base_pos", pos)
	set_meta("hover_base_rotation", rot)
	
	pivot_offset = Vector2(size.x / 2, size.y)


# =============================================================================
# BUFF VISUAL FEEDBACK SYSTEM
# =============================================================================

func apply_buff(buff_type: String, buff_value: int, tag_filter: String = "") -> void:
	"""Apply a buff to this card with visual feedback."""
	if not tag_filter.is_empty():
		var categories: Array = card_def.categories
		var has_category: bool = false
		for cat in categories:
			if str(cat) == tag_filter:
				has_category = true
				break
		if not has_category:
			return
	
	var buff_key: String = buff_type + "_" + tag_filter
	if not applied_buffs.has(buff_key):
		applied_buffs[buff_key] = {"type": buff_type, "value": 0, "tag_filter": tag_filter}
	applied_buffs[buff_key].value += buff_value
	
	_update_display()
	_play_buff_animation(buff_type, buff_value)


func _play_buff_animation(buff_type: String, buff_value: int) -> void:
	"""Play visual effects when a buff is applied."""
	if not is_inside_tree():
		return
	
	var buff_color: Color = Color(0.4, 1.0, 0.5)
	var buff_icon: String = "⚔"
	
	match buff_type:
		"gun_damage", "all_damage":
			buff_color = Color(0.4, 1.0, 0.5)
			buff_icon = "⚔"
		"armor_gain":
			buff_color = Color(0.4, 1.0, 0.9)
			buff_icon = "🛡"
		"hex_damage":
			buff_color = Color(0.8, 0.4, 1.0)
			buff_icon = "☠"
		_:
			buff_color = Color(1.0, 0.9, 0.4)
			buff_icon = "✦"
	
	_spawn_buff_floater(buff_icon, buff_value, buff_color)
	_play_buff_pulse(buff_color)
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
	
	floater.position = Vector2(size.x / 2 - 30, -30)
	add_child(floater)
	
	var tween: Tween = floater.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position:y", floater.position.y - 60, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tween.tween_property(floater, "scale", Vector2(1.3, 1.3), 0.2).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(floater, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_callback(floater.queue_free).set_delay(1.2)


func _play_buff_pulse(_color: Color) -> void:
	"""Pulse the card's scale briefly."""
	if not card_background:
		return
	
	var original_scale: Vector2 = scale
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 1.12, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale, 0.25).set_ease(Tween.EASE_IN_OUT)


func _play_buff_glow(color: Color) -> void:
	"""Create a brief glow effect around the card."""
	if not card_background:
		return
	
	var current_style = card_background.get_theme_stylebox("panel")
	if not current_style:
		return
	
	var glow_style: StyleBoxFlat = current_style.duplicate() if current_style is StyleBoxFlat else StyleBoxFlat.new()
	glow_style.border_color = color
	glow_style.set_border_width_all(4)
	glow_style.shadow_color = Color(color.r, color.g, color.b, 0.6)
	glow_style.shadow_size = 8
	
	card_background.add_theme_stylebox_override("panel", glow_style)
	
	await get_tree().create_timer(0.4).timeout
	
	if is_instance_valid(card_background) and is_instance_valid(self):
		_apply_style()


func clear_buffs() -> void:
	"""Clear all applied buffs and restore original display."""
	applied_buffs.clear()
	if card_def:
		_update_display()


func get_total_damage_with_buffs() -> int:
	"""Get the total damage including all applied buffs."""
	return buffed_damage_display


func has_buffs() -> bool:
	"""Check if this card has any buffs applied."""
	return not applied_buffs.is_empty()


# =============================================================================
# ARTWORK 2D-TO-3D MORPH SYSTEM
# =============================================================================

func morph_artwork_to_3d() -> void:
	"""Activate weapon mode - play a subtle pulse animation when card is staged."""
	if _is_morphed_to_3d or _morph_in_progress:
		return
	if not _weapon_3d:
		return
	
	_morph_in_progress = true
	artwork_morph_started.emit()
	
	# Simple scale pulse to indicate card is staged and ready
	if art_area:
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(art_area, "scale", Vector2(1.08, 1.08), 0.15)
		tween.tween_property(art_area, "scale", Vector2.ONE, 0.2)
		await tween.finished
	
	_is_morphed_to_3d = true
	_morph_in_progress = false
	
	# Start idle animation
	if _weapon_3d.has_method("play_idle_animation"):
		_weapon_3d.play_idle_animation()
	
	artwork_morph_completed.emit()


func morph_artwork_to_2d() -> void:
	"""Deactivate weapon mode - called when card returns to hand (not typically used)."""
	if not _is_morphed_to_3d or _morph_in_progress:
		return
	if not _weapon_3d:
		return
	
	_morph_in_progress = true
	artwork_morph_started.emit()
	
	# Stop idle animation
	if _weapon_3d.has_method("stop_idle_animation"):
		_weapon_3d.stop_idle_animation()
	
	_is_morphed_to_3d = false
	_morph_in_progress = false
	artwork_morph_completed.emit()


func is_artwork_3d() -> bool:
	"""Check if card is in 'weapon mode' (staged in combat lane)."""
	return _is_morphed_to_3d


func set_weapon_target(target_pos: Vector2) -> void:
	"""Set the target position for the weapon to face."""
	# Always rotate the weapon sprite if available (works regardless of morph state)
	if _weapon_3d:
		_weapon_3d.set_target_direction(target_pos)


func fire_weapon(target_pos: Vector2) -> void:
	"""Fire the weapon at a target position with animation."""
	set_weapon_target(target_pos)
	
	# Fire animation works regardless of morph state
	if _weapon_3d:
		_weapon_3d.play_fire_animation()


func get_muzzle_global_position() -> Vector2:
	"""Get the global position of the weapon's muzzle (for projectile origin)."""
	# Get muzzle position from weapon sprite if available
	if _weapon_3d:
		return _weapon_3d.get_muzzle_global_position()
	
	# Fallback to center of art area
	if art_area:
		return art_area.global_position + art_area.size / 2.0
	return global_position + size / 2.0


func _on_weapon_fire_started() -> void:
	weapon_fire_started.emit()


func _on_weapon_fire_completed() -> void:
	weapon_fire_completed.emit()
