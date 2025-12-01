extends Control
## CombatLane - Visual display area for deployed persistent weapons
## Displays weapons as scaled-down cards in a "your side" lane, similar to Hearthstone

signal weapon_clicked(card_def, tier: int, lane_index: int)

const CardUIScene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

# Visual settings
const CARD_SCALE: float = 0.55  # Scale deployed cards to 55%
const CARD_SPACING: int = -30  # Overlap cards slightly like hand
const MAX_LANE_CARDS: int = 7  # Maximum weapons that can be deployed
const DEPLOY_ANIM_DURATION: float = 0.35  # Card fly animation duration
const FIRE_PULSE_DURATION: float = 0.25  # Weapon fire pulse duration

# Node references
var card_container: HBoxContainer = null
var lane_label: Label = null
var glow_overlay: ColorRect = null

# State tracking
var deployed_weapons: Array[Dictionary] = []  # {card_def, tier, card_ui, triggers_remaining}

# Animation tracking
var _pending_deploys: Array[Dictionary] = []  # Queue for deploy animations


func _ready() -> void:
	_setup_ui()
	_connect_signals()


func _setup_ui() -> void:
	"""Create the lane UI structure."""
	# Main container style
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.03, 0.07, 0.85)
	panel_style.border_color = Color(0.3, 0.25, 0.15, 0.8)
	panel_style.set_border_width_all(2)
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
	
	# Horizontal container for cards
	card_container = HBoxContainer.new()
	card_container.name = "CardContainer"
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.add_theme_constant_override("separation", CARD_SPACING)
	card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(card_container)
	
	# Create a glow overlay for fire effects
	glow_overlay = ColorRect.new()
	glow_overlay.name = "GlowOverlay"
	glow_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_overlay.color = Color(1.0, 0.7, 0.2, 0.0)  # Start invisible
	glow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_overlay.z_index = 10
	add_child(glow_overlay)
	
	# Update visibility based on state
	_update_visibility()


func _connect_signals() -> void:
	"""Connect to CombatManager signals."""
	if CombatManager:
		CombatManager.weapon_triggered.connect(_on_weapon_triggered)
		CombatManager.weapons_phase_started.connect(_on_weapons_phase_started)
		CombatManager.weapons_phase_ended.connect(_on_weapons_phase_ended)


func _update_visibility() -> void:
	"""Show/hide the lane based on whether weapons are deployed."""
	var has_weapons: bool = deployed_weapons.size() > 0 or _pending_deploys.size() > 0
	visible = has_weapons
	
	# Update label text
	if lane_label:
		var count: int = deployed_weapons.size()
		if count == 0:
			lane_label.text = "⚡ DEPLOYED WEAPONS"
		else:
			lane_label.text = "⚡ DEPLOYED WEAPONS (" + str(count) + "/" + str(MAX_LANE_CARDS) + ")"


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
	card_ui.setup(card_def, tier, -1)  # -1 hand index means "deployed"
	
	# Scale down
	card_ui.scale = Vector2(CARD_SCALE, CARD_SCALE)
	card_ui.z_index = 1
	
	# Disable dragging for deployed cards
	# (CardUI drag only starts when CombatManager.can_play_card returns true)
	
	# Add a subtle glow effect to indicate it's active
	var glow_style: StyleBoxFlat = StyleBoxFlat.new()
	glow_style.bg_color = Color(1.0, 0.85, 0.3, 0.15)
	glow_style.set_corner_radius_all(8)
	glow_style.shadow_color = Color(1.0, 0.75, 0.2, 0.4)
	glow_style.shadow_size = 6
	
	# Create glow panel behind the card
	var glow_panel: Panel = Panel.new()
	glow_panel.name = "DeployedGlow"
	glow_panel.add_theme_stylebox_override("panel", glow_style)
	glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_panel.offset_left = -6
	glow_panel.offset_top = -6
	glow_panel.offset_right = 6
	glow_panel.offset_bottom = 6
	glow_panel.z_index = -1
	card_ui.add_child(glow_panel)
	glow_panel.set_owner(card_ui)
	
	return card_ui


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
	tween.tween_property(card_ui, "scale", Vector2(CARD_SCALE, CARD_SCALE), DEPLOY_ANIM_DURATION)
	
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
	tween.tween_property(card_ui, "scale", Vector2(CARD_SCALE * 1.15, CARD_SCALE * 1.15), 0.08)
	tween.tween_property(card_ui, "scale", Vector2(CARD_SCALE, CARD_SCALE), 0.12)
	
	# Flash the glow
	var glow_panel: Panel = card_ui.get_node_or_null("DeployedGlow")
	if glow_panel:
		var glow_tween: Tween = glow_panel.create_tween()
		glow_tween.tween_property(glow_panel, "modulate", Color(1.5, 1.2, 0.6, 1.0), 0.1)
		glow_tween.tween_property(glow_panel, "modulate", Color.WHITE, 0.2)


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
	tween.tween_property(card_ui, "scale", Vector2(CARD_SCALE * 1.25, CARD_SCALE * 1.25), FIRE_PULSE_DURATION * 0.4)
	tween.parallel().tween_property(card_ui, "modulate", Color(1.5, 1.3, 0.8, 1.0), FIRE_PULSE_DURATION * 0.4)
	tween.tween_property(card_ui, "scale", Vector2(CARD_SCALE, CARD_SCALE), FIRE_PULSE_DURATION * 0.6)
	tween.parallel().tween_property(card_ui, "modulate", Color.WHITE, FIRE_PULSE_DURATION * 0.6)
	
	# Glow panel flash
	var glow_panel: Panel = card_ui.get_node_or_null("DeployedGlow")
	if glow_panel:
		var glow_tween: Tween = glow_panel.create_tween()
		glow_tween.tween_property(glow_panel, "modulate", Color(2.0, 1.5, 0.5, 1.0), 0.08)
		glow_tween.tween_property(glow_panel, "modulate", Color.WHITE, 0.2)
	
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
		card_ui.size.x * CARD_SCALE * 0.3,
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
	"""Called when weapons phase begins - subtle glow effect."""
	if glow_overlay:
		var tween: Tween = glow_overlay.create_tween()
		tween.tween_property(glow_overlay, "color:a", 0.15, 0.3)


func _on_weapons_phase_ended() -> void:
	"""Called when weapons phase ends - remove glow."""
	if glow_overlay:
		var tween: Tween = glow_overlay.create_tween()
		tween.tween_property(glow_overlay, "color:a", 0.0, 0.3)


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
	return card.global_position + card.size * CARD_SCALE / 2


