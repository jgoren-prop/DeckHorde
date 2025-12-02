extends Control
## CombatLane - Visual display area for deployed persistent weapons
## Displays weapons as scaled-down cards in a "your side" lane, similar to Hearthstone

signal weapon_clicked(card_def, tier: int, lane_index: int)

const CardUIScene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

# Visual settings
const CARD_FILL_PERCENT: float = 0.80  # Cards fill 80% of lane's vertical space
const CARD_BASE_WIDTH: float = 200.0  # Base card width before scaling
const CARD_BASE_HEIGHT: float = 280.0  # Base card height before scaling
const CARD_SPACING: int = 10  # Spacing between scaled cards (positive = gap)

# Calculated at runtime based on lane height
var card_scale: float = 0.55  # Default, recalculated in _ready
const MAX_LANE_CARDS: int = 7  # Maximum weapons that can be deployed
const DEPLOY_ANIM_DURATION: float = 0.35  # Card fly animation duration
const FIRE_PULSE_DURATION: float = 0.25  # Weapon fire pulse duration

# Hover preview settings
const PREVIEW_SCALE: float = 1.5  # Show preview at 150% of original card size
const PREVIEW_OFFSET: Vector2 = Vector2(0, -320)  # Offset above the card
const PREVIEW_FADE_DURATION: float = 0.12  # Fade in/out speed

# Node references
var card_container: HBoxContainer = null
var lane_label: Label = null

# Hover preview
var preview_card: Control = null  # The preview card instance
var preview_container: Control = null  # Container for the preview (to handle positioning)
var hovered_weapon: Dictionary = {}  # Currently hovered weapon data

# State tracking
var deployed_weapons: Array[Dictionary] = []  # {card_def, tier, card_ui, triggers_remaining}

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
	
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "LanePanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# Vertical layout inside panel
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
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


func _update_visibility() -> void:
	"""Update the lane label based on whether weapons are deployed. Lane is always visible."""
	# Lane is always visible to show the golden border/highlight
	visible = true
	
	# Update label text
	if lane_label:
		var count: int = deployed_weapons.size()
		if count == 0:
			lane_label.text = "⚡ WEAPON SLOT"
			lane_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3, 0.7))  # Dimmer when empty
		else:
			lane_label.text = "⚡ DEPLOYED WEAPONS (" + str(count) + "/" + str(MAX_LANE_CARDS) + ")"
			lane_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 0.9))  # Brighter when has weapons


func deploy_weapon(card_def, tier: int, triggers_remaining: int = -1, source_position: Vector2 = Vector2.ZERO) -> void:
	"""Deploy a persistent weapon to the lane with animation."""
	if deployed_weapons.size() >= MAX_LANE_CARDS:
		print("[CombatLane] Lane is full! Cannot deploy more weapons.")
		return
	
	# Create the card UI
	var card_ui: Control = _create_deployed_card(card_def, tier)
	if not card_ui:
		return
	
	# Store the weapon data
	var weapon_data: Dictionary = {
		"card_def": card_def,
		"tier": tier,
		"card_ui": card_ui,
		"triggers_remaining": triggers_remaining
	}
	deployed_weapons.append(weapon_data)
	
	# Add to container (invisible initially for animation)
	card_container.add_child(card_ui)
	card_ui.modulate.a = 0.0
	
	# Update visibility
	_update_visibility()
	
	# Animate deployment
	if source_position != Vector2.ZERO:
		await _animate_deploy(card_ui, source_position)
	else:
		# Just fade in if no source position
		var tween: Tween = card_ui.create_tween()
		tween.tween_property(card_ui, "modulate:a", 1.0, 0.2)


func _create_deployed_card(card_def, tier: int) -> Control:
	"""Create a scaled-down card UI for the lane."""
	var card_ui: Control = CardUIScene.instantiate()
	
	# Set up the card
	card_ui.check_playability = false  # Always show at full brightness
	card_ui.enable_hover_scale = false  # Use external preview instead of in-place scaling
	card_ui.setup(card_def, tier, -1)  # -1 hand index means "deployed"
	
	# Calculate scaled size for layout (HBoxContainer needs to know visual size)
	var scaled_width: float = CARD_BASE_WIDTH * card_scale
	var scaled_height: float = CARD_BASE_HEIGHT * card_scale
	
	# Set custom_minimum_size for layout spacing (tells container how much space to reserve)
	# But keep the card at its natural size - only scale transform changes visual size
	card_ui.custom_minimum_size = Vector2(scaled_width, scaled_height)
	
	# Apply scale transform for visual sizing (card renders at base size, then scaled)
	card_ui.scale = Vector2(card_scale, card_scale)
	card_ui.z_index = 1
	
	# Pivot at top-left since we're in an HBoxContainer that positions from top-left
	card_ui.pivot_offset = Vector2.ZERO
	
	# Connect hover signals for preview
	_connect_card_hover(card_ui, card_def, tier)
	
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
	"""Connect hover signals for a deployed weapon card."""
	# Get the click area button from CardUI to attach hover signals
	var click_area: Button = card_ui.get_node_or_null("ClickArea")
	if click_area:
		click_area.mouse_entered.connect(_on_weapon_hover_enter.bind(card_ui, card_def, tier))
		click_area.mouse_exited.connect(_on_weapon_hover_exit.bind(card_ui))


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


func _animate_deploy(card_ui: Control, source_pos: Vector2) -> void:
	"""Animate the card flying from hand to the lane."""
	if not is_instance_valid(card_ui):
		return
	
	# Wait for card to be properly positioned in container
	await get_tree().process_frame
	
	# Get target position (where card will end up)
	var target_pos: Vector2 = card_ui.global_position
	
	# Move card to source position
	card_ui.global_position = source_pos
	card_ui.modulate.a = 1.0
	card_ui.scale = Vector2(1.0, 1.0)  # Start at full size
	
	# Animate to target
	var tween: Tween = card_ui.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	
	tween.tween_property(card_ui, "global_position", target_pos, DEPLOY_ANIM_DURATION)
	tween.tween_property(card_ui, "scale", Vector2(card_scale, card_scale), DEPLOY_ANIM_DURATION)
	
	# Add a little bounce/glow effect at end
	tween.chain().tween_callback(func():
		if is_instance_valid(card_ui):
			_play_deploy_finish_effect(card_ui)
	)
	
	await tween.finished


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


func fire_weapon(card_name: String, damage: int) -> void:
	"""Visual effect when a weapon fires."""
	var weapon: Dictionary = get_weapon_by_name(card_name)
	if weapon.is_empty():
		return
	
	var card_ui: Control = weapon.card_ui
	if not is_instance_valid(card_ui):
		return
	
	# Pulse effect
	var tween: Tween = card_ui.create_tween()
	tween.tween_property(card_ui, "scale", Vector2(card_scale * 1.25, card_scale * 1.25), FIRE_PULSE_DURATION * 0.4)
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
	
	# Position above the card
	floater.global_position = card_ui.global_position + Vector2(
		card_ui.size.x * card_scale * 0.3,
		-40
	)
	
	add_child(floater)
	
	# Animate up and fade
	var tween: Tween = floater.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floater, "position:y", floater.position.y - 60, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.chain().tween_callback(floater.queue_free)


func _on_weapon_triggered(card_name: String, damage: int) -> void:
	"""Called when CombatManager fires a persistent weapon."""
	fire_weapon(card_name, damage)


func _on_weapons_phase_started() -> void:
	"""Called when weapons phase begins."""
	pass


func _on_weapons_phase_ended() -> void:
	"""Called when weapons phase ends."""
	pass


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
	"""Check if the lane is at capacity."""
	return deployed_weapons.size() >= MAX_LANE_CARDS


func get_card_position(index: int) -> Vector2:
	"""Get the global position of a card slot in the lane."""
	if index < 0 or index >= card_container.get_child_count():
		# Return center of container for new cards
		return card_container.global_position + card_container.size / 2
	
	var card: Control = card_container.get_child(index)
	return card.global_position + card.size * card_scale / 2
