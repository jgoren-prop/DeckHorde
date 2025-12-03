extends Control
## CombatLane - Visual display area for deployed persistent weapons
## Displays weapons as scaled-down cards in a "your side" lane, similar to Hearthstone

signal weapon_clicked(card_def, tier: int, lane_index: int)

const CardUIScene: PackedScene = preload("res://scenes/ui/CardUI.tscn")
const PistolVisual3DScript = preload("res://scripts/ui/PistolVisual3D.gd")

# Visual settings
const CARD_FILL_PERCENT: float = 0.92  # Cards fill 92% of lane's vertical space
const CARD_BASE_WIDTH: float = 200.0  # Base card width before scaling
const CARD_BASE_HEIGHT: float = 280.0  # Base card height before scaling
const CARD_SPACING: int = 10  # Spacing between scaled cards (positive = gap)

# Calculated at runtime based on lane height
var card_scale: float = 0.55  # Default, recalculated in _ready
# V2: No weapon slot limit - can deploy unlimited weapons
# MAX_VISUAL_SLOTS is only for UI layout purposes (cards shrink if more than this)
const MAX_VISUAL_SLOTS: int = 12  # Increased from 8 since no limit now
const DEPLOY_ANIM_DURATION: float = 0.35  # Card fly animation duration
const FIRE_PULSE_DURATION: float = 0.25  # Weapon fire pulse duration

# Hover preview settings
const PREVIEW_SCALE: float = 1.5  # Show preview at 150% of original card size
const PREVIEW_OFFSET: Vector2 = Vector2(0, -320)  # Offset above the card
const PREVIEW_FADE_DURATION: float = 0.12  # Fade in/out speed

# Node references
var card_container: HBoxContainer = null
var lane_label: Label = null
var lane_panel: PanelContainer = null  # Store reference for positioning calculations

# Hover preview
var preview_card: Control = null  # The preview card instance
var preview_container: Control = null  # Container for the preview (to handle positioning)
var hovered_weapon: Dictionary = {}  # Currently hovered weapon data

# State tracking
var deployed_weapons: Array[Dictionary] = []  # {card_def, tier, card_ui, triggers_remaining, pistol_visual}

# Animation tracking
var _pending_deploys: Array[Dictionary] = []  # Queue for deploy animations


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	resized.connect(_on_resized)
	await get_tree().process_frame
	_calculate_card_scale()


func _calculate_card_scale() -> void:
	"""Calculate the card scale based on lane height so cards fill 80% vertically."""
	var lane_height: float = size.y
	if lane_height <= 0:
		call_deferred("_calculate_card_scale")
		return
	
	# Account for panel margins (top: 8, bottom: 8, label ~18, separation ~4)
	var available_height: float = lane_height - 38.0
	var target_card_height: float = available_height * CARD_FILL_PERCENT
	
	card_scale = target_card_height / CARD_BASE_HEIGHT
	card_scale = clampf(card_scale, 0.2, 1.5)  # Safety clamp
	
	print("[CombatLane] Lane height: ", lane_height, ", card_scale: ", card_scale)
	
	# Update any existing cards to use the new scale
	_update_existing_card_scales()


func _on_resized() -> void:
	"""Recalculate card scale when the lane itself changes size."""
	_calculate_card_scale()


func _update_existing_card_scales() -> void:
	"""Update scale of all deployed cards to match current card_scale."""
	for weapon: Dictionary in deployed_weapons:
		var card_ui: Control = weapon.card_ui
		if is_instance_valid(card_ui):
			var scaled_width: float = CARD_BASE_WIDTH * card_scale
			var scaled_height: float = CARD_BASE_HEIGHT * card_scale
			card_ui.custom_minimum_size = Vector2(scaled_width, scaled_height)
			card_ui.scale = Vector2(card_scale, card_scale)


func _setup_ui() -> void:
	"""Create the lane UI structure."""
	# Main container style - always show with golden highlight border
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.03, 0.07, 0.85)
	panel_style.border_color = Color(0.8, 0.65, 0.2, 0.9)  # Golden border always visible
	panel_style.set_border_width_all(3)  # Thicker border for visibility
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 15.0
	panel_style.content_margin_right = 15.0
	panel_style.content_margin_top = 8.0
	panel_style.content_margin_bottom = 8.0
	
	lane_panel = PanelContainer.new()
	lane_panel.name = "LanePanel"
	lane_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	lane_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(lane_panel)
	
	# Vertical layout inside panel
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	lane_panel.add_child(vbox)
	
	# Lane label/title
	lane_label = Label.new()
	lane_label.name = "LaneLabel"
	lane_label.text = "⚡ DEPLOYED WEAPONS"
	lane_label.add_theme_font_size_override("font_size", 14)
	lane_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 0.9))
	lane_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lane_label)
	
	# Horizontal container for cards - use CenterContainer to ensure proper centering
	var center_wrapper: CenterContainer = CenterContainer.new()
	center_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(center_wrapper)
	
	card_container = HBoxContainer.new()
	card_container.name = "CardContainer"
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.add_theme_constant_override("separation", CARD_SPACING)
	center_wrapper.add_child(card_container)
	
	# Create preview container (will be shown above weapon cards on hover)
	_setup_preview_container()
	
	# Lane is always visible now (shows the highlight border)
	visible = true
	_update_visibility()


func _connect_signals() -> void:
	"""Connect to CombatManager signals."""
	if CombatManager:
		CombatManager.weapon_triggered.connect(_on_weapon_triggered)
		CombatManager.weapons_phase_started.connect(_on_weapons_phase_started)
		CombatManager.weapons_phase_ended.connect(_on_weapons_phase_ended)
		CombatManager.weapon_expired.connect(_on_weapon_expired)


func _update_visibility() -> void:
	"""Update the lane label based on whether weapons are deployed. Lane is always visible."""
	# Lane is always visible to show the golden border/highlight
	visible = true
	
	# V2: No slot limit, just show count
	if lane_label:
		var count: int = deployed_weapons.size()
		if count == 0:
			lane_label.text = "⚡ DEPLOY WEAPONS HERE"
			lane_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3, 0.7))  # Dimmer when empty
		else:
			lane_label.text = "⚡ DEPLOYED WEAPONS (%d)" % count
			lane_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 0.9))  # Brighter when has weapons


func get_max_weapon_slots() -> int:
	"""V2: No weapon slot limit. Returns a high number for UI layout purposes only."""
	return MAX_VISUAL_SLOTS


func deploy_weapon(card_def, tier: int, triggers_remaining: int = -1, drop_position: Vector2 = Vector2.ZERO) -> void:
	"""Deploy a persistent weapon to the lane with animation.
	drop_position: The EXACT global position where the card was released (dropped).
	Animation: Card moves from drop_position to its calculated centered position.
	V2: No weapon slot limit - can deploy unlimited weapons.
	"""
	# V2: No slot limit check - UI will shrink cards if needed
	
	# Create the card UI
	var card_ui: Control = _create_deployed_card(card_def, tier)
	if not card_ui:
		return
	
	# Check if this is a gun card that should get a pistol visual
	var pistol_visual: Control = null
	if _is_gun_card(card_def):
		pistol_visual = _create_pistol_visual_for_card(card_ui)
	
	# Store the weapon data
	var weapon_data: Dictionary = {
		"card_def": card_def,
		"tier": tier,
		"card_ui": card_ui,
		"triggers_remaining": triggers_remaining,
		"pistol_visual": pistol_visual
	}
	deployed_weapons.append(weapon_data)
	
	# Add card to this Control directly (not HBoxContainer) for manual positioning
	add_child(card_ui)
	card_ui.modulate.a = 0.0
	
	# Update visibility
	_update_visibility()
	
	# Animate deployment from drop position to calculated screen-centered position
	if drop_position != Vector2.ZERO:
		await _animate_deploy_to_center(card_ui, drop_position)
		# After deployment animation, morph the emoji into 3D pistol
		if pistol_visual:
			await _morph_emoji_to_pistol(card_ui, pistol_visual)
	else:
		# Just fade in at calculated position if no drop position
		_position_all_cards_centered()
		var tween: Tween = card_ui.create_tween()
		tween.tween_property(card_ui, "modulate:a", 1.0, 0.2)
		# Morph after fade in
		if pistol_visual:
			await get_tree().create_timer(0.2).timeout
			await _morph_emoji_to_pistol(card_ui, pistol_visual)


func _create_deployed_card(card_def, tier: int) -> Control:
	"""Create a scaled-down card UI for the lane."""
	var card_ui: Control = CardUIScene.instantiate()
	
	# Set up the card
	card_ui.check_playability = false  # Always show at full brightness
	card_ui.enable_hover_scale = false  # Use custom hover in CombatLane (CardUI's hover doesn't work with global_position)
	card_ui.setup(card_def, tier, -1)  # -1 hand index means "deployed"
	
	# Note: We don't set custom_minimum_size since we're manually positioning
	# The card will be positioned using global_position
	
	# Initial scale (will be animated from 1.0 to card_scale during deploy)
	card_ui.scale = Vector2(card_scale, card_scale)
	card_ui.z_index = 1
	
	# Set pivot to center for proper in-place scaling on hover
	card_ui.pivot_offset = Vector2(CARD_BASE_WIDTH / 2.0, CARD_BASE_HEIGHT / 2.0)
	
	# Connect custom hover for in-place scaling (no position change)
	_connect_card_hover_scale(card_ui)
	
	return card_ui


func _setup_preview_container() -> void:
	"""Create the container for the hover preview card using CanvasLayer to escape parent bounds."""
	# Use a CanvasLayer so preview can appear outside the CombatLane bounds
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "PreviewCanvasLayer"
	canvas_layer.layer = 80  # High layer to show above most UI
	add_child(canvas_layer)
	
	preview_container = Control.new()
	preview_container.name = "PreviewContainer"
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_container.visible = false
	canvas_layer.add_child(preview_container)


func _connect_card_hover(card_ui: Control, card_def, tier: int) -> void:
	"""Connect hover signals for a deployed weapon card (external preview - unused)."""
	# Get the click area button from CardUI to attach hover signals
	var click_area: Button = card_ui.get_node_or_null("ClickArea")
	if click_area:
		click_area.mouse_entered.connect(_on_weapon_hover_enter.bind(card_ui, card_def, tier))
		click_area.mouse_exited.connect(_on_weapon_hover_exit.bind(card_ui))


# Hover scale tracking for in-place enlargement
var _hover_scale_tweens: Dictionary = {}  # card instance_id -> Tween
const HOVER_SCALE_FACTOR: float = 1.4  # Scale up to 140% on hover
const HOVER_SCALE_DURATION: float = 0.12


func _connect_card_hover_scale(card_ui: Control) -> void:
	"""Connect hover signals for simple in-place scaling (no position change)."""
	var click_area: Button = card_ui.get_node_or_null("ClickArea")
	if click_area:
		click_area.mouse_entered.connect(_on_card_hover_scale_enter.bind(card_ui))
		click_area.mouse_exited.connect(_on_card_hover_scale_exit.bind(card_ui))


func _on_card_hover_scale_enter(card_ui: Control) -> void:
	"""Scale up card in place on hover."""
	if not is_instance_valid(card_ui):
		return
	
	var card_id: int = card_ui.get_instance_id()
	
	# Kill existing tween
	if _hover_scale_tweens.has(card_id) and _hover_scale_tweens[card_id].is_valid():
		_hover_scale_tweens[card_id].kill()
	
	# Scale up around center pivot (already set in _create_deployed_card)
	var target_scale: float = card_scale * HOVER_SCALE_FACTOR
	var tween: Tween = card_ui.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card_ui, "scale", Vector2(target_scale, target_scale), HOVER_SCALE_DURATION)
	
	_hover_scale_tweens[card_id] = tween
	
	# Bring to front
	card_ui.z_index = 50


func _on_card_hover_scale_exit(card_ui: Control) -> void:
	"""Scale card back to normal on hover exit."""
	if not is_instance_valid(card_ui):
		return
	
	var card_id: int = card_ui.get_instance_id()
	
	# Kill existing tween
	if _hover_scale_tweens.has(card_id) and _hover_scale_tweens[card_id].is_valid():
		_hover_scale_tweens[card_id].kill()
	
	# Scale back to normal
	var tween: Tween = card_ui.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(card_ui, "scale", Vector2(card_scale, card_scale), HOVER_SCALE_DURATION)
	
	_hover_scale_tweens[card_id] = tween
	
	# Reset z-index
	card_ui.z_index = 1


func _on_weapon_hover_enter(card_ui: Control, card_def, tier: int) -> void:
	"""Show large preview when hovering over a deployed weapon."""
	if not is_instance_valid(preview_container):
		return
	
	# Store hovered weapon
	hovered_weapon = {"card_def": card_def, "tier": tier, "card_ui": card_ui}
	
	# Clear any existing preview
	_clear_preview()
	
	# Create preview card at full scale (not PREVIEW_SCALE) for readability
	preview_card = CardUIScene.instantiate()
	preview_card.check_playability = false
	preview_card.enable_hover_scale = false  # Prevent hover effects on preview
	preview_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.add_child(preview_card)
	
	# Setup the card after adding to tree
	preview_card.setup(card_def, tier, -1)
	preview_card.scale = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
	preview_card.modulate.a = 0.0  # Start invisible for fade-in
	
	# Set pivot to top-left for easier positioning
	preview_card.pivot_offset = Vector2.ZERO
	
	# Add a glow/border to the preview
	var preview_style: StyleBoxFlat = StyleBoxFlat.new()
	preview_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)  # Transparent
	preview_style.border_color = Color(1.0, 0.85, 0.3, 1.0)  # Gold border
	preview_style.set_border_width_all(4)
	preview_style.set_corner_radius_all(12)
	preview_style.shadow_color = Color(1.0, 0.75, 0.2, 0.7)
	preview_style.shadow_size = 15
	
	var border_panel: Panel = Panel.new()
	border_panel.name = "PreviewBorder"
	border_panel.add_theme_stylebox_override("panel", preview_style)
	border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	border_panel.offset_left = -10
	border_panel.offset_top = -10
	border_panel.offset_right = 10
	border_panel.offset_bottom = 10
	border_panel.z_index = -1
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_card.add_child(border_panel)
	
	# Position preview above the hovered card
	_position_preview(card_ui)
	
	# Show preview container and fade in
	preview_container.visible = true
	var tween: Tween = preview_card.create_tween()
	tween.tween_property(preview_card, "modulate:a", 1.0, PREVIEW_FADE_DURATION)


func _on_weapon_hover_exit(card_ui: Control) -> void:
	"""Hide preview when mouse leaves the weapon."""
	# Fade out and hide preview
	if preview_card and is_instance_valid(preview_card):
		var tween: Tween = preview_card.create_tween()
		tween.tween_property(preview_card, "modulate:a", 0.0, PREVIEW_FADE_DURATION)
		tween.tween_callback(_clear_preview)
	else:
		_clear_preview()
	
	hovered_weapon = {}


func _position_preview(card_ui: Control) -> void:
	"""Position the preview card above the hovered weapon."""
	if not preview_card or not is_instance_valid(preview_card):
		return
	
	# Get the card's global position
	var card_global_pos: Vector2 = card_ui.global_position
	var card_visual_size: Vector2 = Vector2(CARD_BASE_WIDTH, CARD_BASE_HEIGHT) * card_scale
	
	# Calculate preview visual size (scaled)
	var preview_visual_size: Vector2 = Vector2(CARD_BASE_WIDTH, CARD_BASE_HEIGHT) * PREVIEW_SCALE
	
	# Position above the card, centered horizontally relative to the card's visual center
	var card_center_x: float = card_global_pos.x + card_visual_size.x / 2.0
	var preview_pos: Vector2 = Vector2(
		card_center_x - preview_visual_size.x / 2.0,
		card_global_pos.y - preview_visual_size.y - 30  # 30px gap above card
	)
	
	# Clamp to screen bounds
	var viewport_size: Vector2 = get_viewport_rect().size
	preview_pos.x = clampf(preview_pos.x, 15.0, viewport_size.x - preview_visual_size.x - 15.0)
	preview_pos.y = maxf(preview_pos.y, 15.0)  # Don't go above screen top
	
	# If preview would overlap with card (not enough vertical space), position to the side
	if preview_pos.y + preview_visual_size.y > card_global_pos.y - 15:
		# Try right side first
		preview_pos.x = card_global_pos.x + card_visual_size.x + 25
		preview_pos.y = card_global_pos.y + (card_visual_size.y - preview_visual_size.y) / 2.0
		
		# If that goes off screen, try left side
		if preview_pos.x + preview_visual_size.x > viewport_size.x - 15:
			preview_pos.x = card_global_pos.x - preview_visual_size.x - 25
		
		preview_pos.y = clampf(preview_pos.y, 15.0, viewport_size.y - preview_visual_size.y - 15.0)
	
	# Since we're using a CanvasLayer, position is in global/screen coordinates
	preview_card.position = preview_pos


func _clear_preview() -> void:
	"""Remove the current preview card."""
	if preview_card and is_instance_valid(preview_card):
		preview_card.queue_free()
		preview_card = null
	
	if preview_container:
		preview_container.visible = false


func _animate_deploy_to_center(card_ui: Control, source_card_global_pos: Vector2) -> void:
	"""Animate the card from the source card's position to the calculated centered position.
	
	IMPORTANT: source_card_global_pos is the global_position of the ORIGINAL card (top-left).
	We animate our new card from that position to its target position in the lane.
	"""
	if not is_instance_valid(card_ui):
		return
	
	# The source_card_global_pos is the top-left of the original dragged card
	# The original card was at scale ~1.3 when being dragged
	var original_scale: float = 1.3  # Dragged cards are scaled up
	
	# Calculate target position (top-left of where our card should end up)
	var target_pos: Vector2 = _calculate_card_target_position(deployed_weapons.size() - 1)
	
	# Start at the source card's position (both are top-left positions)
	card_ui.global_position = source_card_global_pos
	card_ui.modulate.a = 1.0
	card_ui.scale = Vector2(original_scale, original_scale)  # Match original card's scale
	card_ui.z_index = 50  # Above other cards during animation
	
	# Animate from source position to target position
	var tween: Tween = card_ui.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	
	# Move to target position
	tween.tween_property(card_ui, "global_position", target_pos, DEPLOY_ANIM_DURATION)
	# Scale down to lane card size
	tween.tween_property(card_ui, "scale", Vector2(card_scale, card_scale), DEPLOY_ANIM_DURATION)
	
	await tween.finished
	
	# Reset z_index after animation
	card_ui.z_index = 1
	
	# Reposition ALL cards to ensure proper centering (in case spacing changed)
	_position_all_cards_centered()
	
	# Add a little bounce/glow effect at end
	if is_instance_valid(card_ui):
		_play_deploy_finish_effect(card_ui)


func _calculate_card_target_position(card_index: int) -> Vector2:
	"""Calculate the global TOP-LEFT position for a card at the given index.
	
	Cards are centered horizontally on the SCREEN (viewport center), not the container.
	Returns the TOP-LEFT position since global_position is always top-left in Godot Controls.
	"""
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_center_x: float = viewport_size.x / 2.0
	
	# Calculate card dimensions at scale
	var scaled_width: float = CARD_BASE_WIDTH * card_scale
	var scaled_height: float = CARD_BASE_HEIGHT * card_scale
	
	# Total number of cards (including the one being added)
	var total_cards: int = deployed_weapons.size()
	
	# Calculate total width of all cards with spacing
	var total_width: float = (scaled_width * total_cards) + (CARD_SPACING * (total_cards - 1))
	
	# Starting X position for first card's LEFT edge (so all cards are centered on screen)
	var start_x: float = screen_center_x - (total_width / 2.0)
	
	# This card's LEFT X position (top-left corner)
	var card_left_x: float = start_x + (card_index * (scaled_width + CARD_SPACING))
	
	# Y position: center the card vertically within the lane panel
	# Use the lane_panel's global rect for accurate positioning
	var panel_rect: Rect2 = lane_panel.get_global_rect() if lane_panel else get_global_rect()
	var lane_center_y: float = panel_rect.position.y + (panel_rect.size.y / 2.0)
	# Convert from center to top-left Y
	var card_top_y: float = lane_center_y - (scaled_height / 2.0)
	
	return Vector2(card_left_x, card_top_y)


func _position_all_cards_centered() -> void:
	"""Reposition all deployed cards to be centered on the screen.
	
	This ensures cards are always visually centered regardless of container position.
	"""
	if deployed_weapons.size() == 0:
		return
	
	for i: int in range(deployed_weapons.size()):
		var weapon: Dictionary = deployed_weapons[i]
		var card_ui: Control = weapon.card_ui
		if is_instance_valid(card_ui):
			var target_pos: Vector2 = _calculate_card_target_position(i)
			
			# Smoothly animate to new position (for when cards need to shift after adding new ones)
			var tween: Tween = card_ui.create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(card_ui, "global_position", target_pos, 0.2)
			
			# Ensure proper scale
			card_ui.scale = Vector2(card_scale, card_scale)
			card_ui.z_index = 1


func _play_deploy_finish_effect(card_ui: Control) -> void:
	"""Play a small effect when card finishes deploying."""
	if not is_instance_valid(card_ui):
		return
	
	# Quick scale bounce
	var tween: Tween = card_ui.create_tween()
	tween.tween_property(card_ui, "scale", Vector2(card_scale * 1.15, card_scale * 1.15), 0.08)
	tween.tween_property(card_ui, "scale", Vector2(card_scale, card_scale), 0.12)


func remove_weapon(card_def) -> void:
	"""Remove a weapon from the lane (expired or removed by effect)."""
	for i: int in range(deployed_weapons.size() - 1, -1, -1):
		var weapon: Dictionary = deployed_weapons[i]
		if weapon.card_def.card_id == card_def.card_id:
			_animate_remove(weapon.card_ui)
			deployed_weapons.remove_at(i)
			break
	
	_update_visibility()
	
	# Reposition remaining cards to stay centered
	_position_all_cards_centered()


func _animate_remove(card_ui: Control) -> void:
	"""Animate card removal from lane."""
	if not is_instance_valid(card_ui):
		return
	
	var tween: Tween = card_ui.create_tween()
	tween.set_parallel(true)
	tween.tween_property(card_ui, "modulate:a", 0.0, 0.25)
	tween.tween_property(card_ui, "scale", Vector2(0.2, 0.2), 0.25)
	tween.tween_callback(card_ui.queue_free)


func clear_all_weapons() -> void:
	"""Remove all weapons from the lane (wave end)."""
	for weapon: Dictionary in deployed_weapons:
		if is_instance_valid(weapon.card_ui):
			weapon.card_ui.queue_free()
	
	deployed_weapons.clear()
	_update_visibility()


func get_weapon_by_name(card_name: String) -> Dictionary:
	"""Find a deployed weapon by its card name."""
	for weapon: Dictionary in deployed_weapons:
		if weapon.card_def.card_name == card_name:
			return weapon
	return {}


func fire_weapon(card_name: String, damage: int, weapon_index: int = -1, target_pos: Vector2 = Vector2.ZERO) -> void:
	"""Visual effect when a weapon fires.
	weapon_index: The index in deployed_weapons array (-1 to use name-based lookup for backwards compatibility).
	target_pos: Global position of the target enemy (for pistol aiming animation).
	"""
	var weapon: Dictionary = {}
	
	# Use index-based lookup if provided, otherwise fall back to name-based
	if weapon_index >= 0 and weapon_index < deployed_weapons.size():
		weapon = deployed_weapons[weapon_index]
	else:
		weapon = get_weapon_by_name(card_name)
	
	if weapon.is_empty():
		return
	
	var card_ui: Control = weapon.card_ui
	if not is_instance_valid(card_ui):
		return
	
	# Check if this weapon has a pistol visual
	var pistol_visual: Control = weapon.get("pistol_visual", null)
	if pistol_visual and is_instance_valid(pistol_visual) and target_pos != Vector2.ZERO:
		# Fire the pistol animation (aim + fire + recoil)
		await _animate_pistol_fire(pistol_visual, target_pos)
	
	# Card pulse effect (happens alongside or after pistol animation)
	var tween: Tween = card_ui.create_tween()
	tween.tween_property(card_ui, "scale", Vector2(card_scale * 1.15, card_scale * 1.15), FIRE_PULSE_DURATION * 0.4)
	tween.parallel().tween_property(card_ui, "modulate", Color(1.5, 1.3, 0.8, 1.0), FIRE_PULSE_DURATION * 0.4)
	tween.tween_property(card_ui, "scale", Vector2(card_scale, card_scale), FIRE_PULSE_DURATION * 0.6)
	tween.parallel().tween_property(card_ui, "modulate", Color.WHITE, FIRE_PULSE_DURATION * 0.6)
	
	# Show damage floater
	_show_damage_floater(card_ui, damage)


func _show_damage_floater(card_ui: Control, damage: int) -> void:
	"""Show floating damage number above the fired weapon."""
	var floater: Label = Label.new()
	floater.text = "-" + str(damage) + "⚔"
	floater.add_theme_font_size_override("font_size", 24)
	floater.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 1.0))
	floater.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1, 1.0))
	floater.add_theme_constant_override("outline_size", 3)
	floater.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floater.z_index = 100
	
	# IMPORTANT: Add to tree FIRST, then set global_position
	# Setting global_position before add_child doesn't work correctly in Godot
	add_child(floater)
	
	# Now set global position (node is in the tree, so this works correctly)
	floater.global_position = card_ui.global_position + Vector2(
		card_ui.size.x * card_scale * 0.3,
		-40
	)
	
	# Cache the starting position for the animation (now in local coordinates)
	var start_y: float = floater.position.y
	
	# Animate up and fade
	var tween: Tween = floater.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position:y", start_y - 60, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.chain().tween_callback(floater.queue_free)


func _on_weapon_triggered(card_name: String, damage: int, weapon_index: int) -> void:
	"""Called when CombatManager fires a persistent weapon."""
	fire_weapon(card_name, damage, weapon_index)


func _on_weapons_phase_started() -> void:
	"""Called when weapons phase begins."""
	pass


func _on_weapons_phase_ended() -> void:
	"""Called when weapons phase ends."""
	pass


func _on_weapon_expired(card_def, destination: String) -> void:
	"""Called when a weapon's duration expires."""
	print("[CombatLane] Weapon expired: %s -> %s" % [card_def.card_name, destination])
	remove_weapon(card_def)


func update_weapon_triggers(card_name: String, remaining: int) -> void:
	"""Update the remaining triggers display for a weapon."""
	var weapon: Dictionary = get_weapon_by_name(card_name)
	if weapon.is_empty():
		return
	
	weapon.triggers_remaining = remaining
	
	# Could add visual indicator for remaining triggers if needed
	# (e.g., a small counter on the card)


func get_deployed_count() -> int:
	"""Return the number of deployed weapons."""
	return deployed_weapons.size()


func is_full() -> bool:
	"""V2: No weapon slot limit, always returns false."""
	return false


func get_weapon_center_position(card_name: String) -> Vector2:
	"""Get the global center position of a deployed weapon by name.
	Used by CombatAnimationManager to originate attack projectiles from the correct card.
	NOTE: This returns the FIRST weapon with this name. Use get_weapon_position_by_index for multiple same-name weapons.
	"""
	var weapon: Dictionary = get_weapon_by_name(card_name)
	if weapon.is_empty():
		return Vector2.ZERO
	
	var card_ui: Control = weapon.card_ui
	if not is_instance_valid(card_ui):
		return Vector2.ZERO
	
	# Calculate the visual center of the card
	# The card is scaled, so we need to account for that
	var scaled_size: Vector2 = Vector2(CARD_BASE_WIDTH, CARD_BASE_HEIGHT) * card_scale
	return card_ui.global_position + scaled_size / 2.0


func get_weapon_position_by_index(index: int) -> Vector2:
	"""Get the global center position of a deployed weapon by its index.
	Used when multiple weapons with the same name are deployed.
	"""
	if index < 0 or index >= deployed_weapons.size():
		return Vector2.ZERO
	
	var weapon: Dictionary = deployed_weapons[index]
	var card_ui: Control = weapon.card_ui
	if not is_instance_valid(card_ui):
		return Vector2.ZERO
	
	# Calculate the visual center of the card
	var scaled_size: Vector2 = Vector2(CARD_BASE_WIDTH, CARD_BASE_HEIGHT) * card_scale
	return card_ui.global_position + scaled_size / 2.0


func get_card_position(index: int) -> Vector2:
	"""Get the global position of a card slot in the lane."""
	if index < 0 or index >= card_container.get_child_count():
		# Return center of container for new cards
		return card_container.global_position + card_container.size / 2
	
	var card: Control = card_container.get_child(index)
	return card.global_position + card.size * card_scale / 2


# === Gun/Pistol Visual Functions ===

func _is_gun_card(card_def) -> bool:
	"""Check if a card is a gun type (has 'gun' tag)."""
	if card_def and card_def.tags:
		return "gun" in card_def.tags
	return false


func _create_pistol_visual_for_card(card_ui: Control) -> Control:
	"""Create a PistolVisual3D and add it as an overlay on the card."""
	var pistol: Control = PistolVisual3DScript.new()
	pistol.name = "PistolVisual"
	pistol.z_index = 50  # High z_index to show above card content
	pistol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Set the Control size to contain the pistol visual
	pistol.custom_minimum_size = Vector2(100, 80)
	pistol.size = Vector2(100, 80)
	
	# Add directly to card_ui (not using CanvasLayer to simplify positioning)
	card_ui.add_child(pistol)
	
	# Position centered on the card
	# The pistol's internal pivot is at (25, 30), so we offset to center it on the card
	var card_center_x: float = CARD_BASE_WIDTH / 2.0
	var card_center_y: float = CARD_BASE_HEIGHT / 2.0
	pistol.position = Vector2(card_center_x - 50, card_center_y - 40)  # Center the 100x80 pistol on card
	
	# Initially hidden (will be shown after morph animation)
	pistol.modulate.a = 0.0
	
	# Store reference for positioning updates
	pistol.set_meta("card_ui", card_ui)
	
	print("[CombatLane DEBUG] Created pistol visual at position: ", pistol.position, " size: ", pistol.size)
	
	return pistol


func _morph_emoji_to_pistol(card_ui: Control, pistol_visual: Control) -> void:
	"""Animate the emoji morphing into the 3D pistol visual."""
	if not is_instance_valid(pistol_visual) or not is_instance_valid(card_ui):
		print("[CombatLane DEBUG] Morph failed - invalid pistol or card_ui")
		return
	
	print("[CombatLane DEBUG] Starting morph animation")
	
	# Get the type_icon label (emoji) from the card
	var type_icon: Label = card_ui.get_node_or_null("CardBackground/VBox/TypeIcon")
	
	# Calculate final position for the pistol (centered on card)
	# Pistol size is 100x80, so to center it on a 180x250 card:
	var final_pos: Vector2 = Vector2(
		CARD_BASE_WIDTH / 2.0 - 50,  # Center 100px wide pistol on 180px card
		CARD_BASE_HEIGHT / 2.0 - 40  # Center 80px tall pistol on 250px card
	)
	
	if not type_icon:
		# Just fade in the pistol at center if we can't find the emoji
		pistol_visual.position = final_pos
		var tween: Tween = pistol_visual.create_tween()
		tween.tween_property(pistol_visual, "modulate:a", 1.0, 0.3)
		print("[CombatLane DEBUG] No emoji found, fading in at: ", final_pos)
		return
	
	print("[CombatLane DEBUG] Found emoji at global_position: ", type_icon.global_position)
	
	# Hide the emoji immediately since we're replacing it
	type_icon.modulate.a = 0.0
	
	# Start pistol at final position but scaled down and faded
	pistol_visual.position = final_pos
	pistol_visual.scale = Vector2(0.3, 0.3)
	
	print("[CombatLane DEBUG] Pistol start pos: ", pistol_visual.position, " scale: ", pistol_visual.scale)
	
	# Play the morph animation - scale up from center
	var pistol_tween: Tween = pistol_visual.create_tween()
	pistol_tween.set_parallel(true)
	pistol_tween.set_ease(Tween.EASE_OUT)
	pistol_tween.set_trans(Tween.TRANS_BACK)
	
	# Fade in
	pistol_tween.tween_property(pistol_visual, "modulate:a", 1.0, 0.15)
	# Scale up with overshoot
	pistol_tween.tween_property(pistol_visual, "scale", Vector2(1.0, 1.0), 0.3)
	
	await pistol_tween.finished
	print("[CombatLane DEBUG] Morph complete, pistol position: ", pistol_visual.position, " modulate: ", pistol_visual.modulate, " scale: ", pistol_visual.scale)


func _update_pistol_position(_card_ui: Control, pistol_visual: Control) -> void:
	"""Update the pistol's position to stay centered on the card."""
	if not is_instance_valid(pistol_visual):
		return
	
	# Pistol is now a direct child of card_ui, so just ensure it's centered
	# Pistol size is 100x80, card is 180x250
	pistol_visual.position = Vector2(
		CARD_BASE_WIDTH / 2.0 - 50,  # Center 100px wide pistol on 180px card
		CARD_BASE_HEIGHT / 2.0 - 40  # Center 80px tall pistol on 250px card
	)


func _animate_pistol_fire(pistol_visual: Control, target_pos: Vector2) -> void:
	"""Animate the pistol firing at the target."""
	if not is_instance_valid(pistol_visual):
		return
	
	# Update pistol position first
	var card_ui: Control = pistol_visual.get_meta("card_ui", null)
	if card_ui:
		_update_pistol_position(card_ui, pistol_visual)
	
	# Fire at target
	if pistol_visual.has_method("fire_at_target"):
		pistol_visual.fire_at_target(target_pos)
		# Wait for fire animation to complete
		await pistol_visual.fire_completed
	else:
		# Fallback: quick pulse
		var tween: Tween = pistol_visual.create_tween()
		tween.tween_property(pistol_visual, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(pistol_visual, "scale", Vector2.ONE, 0.1)
		await tween.finished


func get_pistol_barrel_position(weapon_index: int) -> Vector2:
	"""Get the global position of the pistol barrel tip for projectile spawning."""
	if weapon_index < 0 or weapon_index >= deployed_weapons.size():
		return Vector2.ZERO
	
	var weapon: Dictionary = deployed_weapons[weapon_index]
	var pistol_visual: Control = weapon.get("pistol_visual", null)
	var card_ui: Control = weapon.card_ui
	
	if pistol_visual and is_instance_valid(pistol_visual) and is_instance_valid(card_ui):
		# The pistol is a child of card_ui, but the card is scaled
		# Barrel tip is at local position (88, 22) relative to pistol's origin
		# Pistol's origin is at its position within the card
		var pistol_local_pos: Vector2 = pistol_visual.position
		var barrel_local: Vector2 = pistol_local_pos + Vector2(88, 22)
		
		# Convert to global, accounting for card's scale
		var barrel_scaled: Vector2 = barrel_local * card_scale
		return card_ui.global_position + barrel_scaled
	
	# Fallback to weapon card center
	return get_weapon_position_by_index(weapon_index)


func animate_pistol_fire_at_index(weapon_index: int, target_global_pos: Vector2) -> void:
	"""Animate the pistol at the given weapon index to fire at the target position.
	Called by BattlefieldArena before firing the projectile.
	"""
	if weapon_index < 0 or weapon_index >= deployed_weapons.size():
		return
	
	var weapon: Dictionary = deployed_weapons[weapon_index]
	var pistol_visual: Control = weapon.get("pistol_visual", null)
	
	if pistol_visual and is_instance_valid(pistol_visual):
		await _animate_pistol_fire(pistol_visual, target_global_pos)
	else:
		# No pistol visual - just do a quick card pulse
		var card_ui: Control = weapon.card_ui
		if is_instance_valid(card_ui):
			var tween: Tween = card_ui.create_tween()
			tween.tween_property(card_ui, "scale", Vector2(card_scale * 1.15, card_scale * 1.15), 0.08)
			tween.tween_property(card_ui, "scale", Vector2(card_scale, card_scale), 0.12)
			await tween.finished


func has_pistol_at_index(weapon_index: int) -> bool:
	"""Check if the weapon at the given index has a pistol visual."""
	if weapon_index < 0 or weapon_index >= deployed_weapons.size():
		return false
	
	var weapon: Dictionary = deployed_weapons[weapon_index]
	var pistol_visual: Control = weapon.get("pistol_visual", null)
	return pistol_visual != null and is_instance_valid(pistol_visual)


# Drop highlight for weapon targeting
var _drop_highlight_panel: Panel = null

func set_drop_highlight(highlight: bool) -> void:
	"""Show or hide drop highlight when dragging a weapon over the lane."""
	if highlight:
		if not _drop_highlight_panel:
			_create_drop_highlight()
		_drop_highlight_panel.visible = true
	else:
		if _drop_highlight_panel:
			_drop_highlight_panel.visible = false


func _create_drop_highlight() -> void:
	"""Create the drop highlight overlay."""
	_drop_highlight_panel = Panel.new()
	_drop_highlight_panel.name = "DropHighlight"
	_drop_highlight_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_drop_highlight_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop_highlight_panel.z_index = 10
	
	var highlight_style: StyleBoxFlat = StyleBoxFlat.new()
	highlight_style.bg_color = Color(0.4, 0.8, 0.3, 0.25)  # Green tint
	highlight_style.border_color = Color(0.5, 1.0, 0.4, 0.9)  # Bright green border
	highlight_style.set_border_width_all(4)
	highlight_style.set_corner_radius_all(12)
	_drop_highlight_panel.add_theme_stylebox_override("panel", highlight_style)
	
	add_child(_drop_highlight_panel)
	_drop_highlight_panel.visible = false
