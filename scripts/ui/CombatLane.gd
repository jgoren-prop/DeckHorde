extends Control
## CombatLane - V3 Staging System with 2D-to-3D Weapon Morphing
## Players queue cards to this lane, then execute them all left-to-right
## Supports drag-to-reorder before execution
## When staged, card artwork morphs from 2D to 3D weapon display

@warning_ignore("unused_signal")
signal card_clicked(card_def, tier: int, lane_index: int)
signal execute_requested()
signal weapon_fired(card_def, muzzle_position: Vector2, target_position: Vector2)

const CardUIScene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

# Visual settings
const CARD_FILL_PERCENT: float = 0.88
const CARD_BASE_WIDTH: float = 200.0
const CARD_BASE_HEIGHT: float = 280.0
const CARD_SPACING: int = 12
const MAX_VISUAL_SLOTS: int = 12

# Animation settings
const STAGE_ANIM_DURATION: float = 0.3
const EXECUTE_PULSE_DURATION: float = 0.25
const REORDER_ANIM_DURATION: float = 0.2

# Calculated at runtime
var card_scale: float = 0.5

# Node references
var card_container: Control = null
var lane_label: Label = null
var lane_panel: PanelContainer = null
var execute_button: Button = null

# State tracking
var staged_cards: Array[Dictionary] = []  # {card_def, tier, card_ui, applied_buffs}

# Reference to battlefield for targeting
var battlefield_arena: Control = null

# Drag-to-reorder state
var dragging_card_index: int = -1
var drag_start_position: Vector2 = Vector2.ZERO
var drag_preview: Control = null


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	resized.connect(_on_resized)
	await get_tree().process_frame
	_calculate_card_scale()


func _calculate_card_scale() -> void:
	var lane_height: float = size.y
	if lane_height <= 0:
		call_deferred("_calculate_card_scale")
		return
	
	var available_height: float = lane_height - 60.0  # Account for label and button
	var target_card_height: float = available_height * CARD_FILL_PERCENT
	
	card_scale = target_card_height / CARD_BASE_HEIGHT
	card_scale = clampf(card_scale, 0.2, 1.2)
	
	_update_existing_card_scales()


func _on_resized() -> void:
	_calculate_card_scale()


func _update_existing_card_scales() -> void:
	for staged: Dictionary in staged_cards:
		var card_ui: Control = staged.card_ui
		if is_instance_valid(card_ui):
			card_ui.scale = Vector2(card_scale, card_scale)
	_position_all_cards()


func _setup_ui() -> void:
	# Main panel style
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.04, 0.10, 0.9)
	panel_style.border_color = Color(0.5, 0.8, 0.4, 0.9)  # Green border for staging
	panel_style.set_border_width_all(3)
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
	lane_label.text = "⚔️ STAGING LANE - Drop cards here, then EXECUTE"
	lane_label.add_theme_font_size_override("font_size", 14)
	lane_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.6, 0.9))
	lane_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lane_label)
	
	# Card container (manual positioning, not HBox)
	card_container = Control.new()
	card_container.name = "CardContainer"
	card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(card_container)
	
	# Execute button
	execute_button = Button.new()
	execute_button.name = "ExecuteButton"
	execute_button.text = "⚡ EXECUTE ALL ⚡"
	execute_button.add_theme_font_size_override("font_size", 18)
	execute_button.custom_minimum_size = Vector2(200, 40)
	execute_button.pressed.connect(_on_execute_pressed)
	
	# Style the execute button
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.6, 0.3, 1.0)
	btn_style.border_color = Color(0.4, 0.9, 0.5, 1.0)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(8)
	execute_button.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color(0.3, 0.7, 0.4, 1.0)
	execute_button.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_pressed: StyleBoxFlat = btn_style.duplicate()
	btn_pressed.bg_color = Color(0.15, 0.5, 0.25, 1.0)
	execute_button.add_theme_stylebox_override("pressed", btn_pressed)
	
	# Center the button
	var button_center: CenterContainer = CenterContainer.new()
	button_center.add_child(execute_button)
	vbox.add_child(button_center)
	
	_update_visibility()


func _connect_signals() -> void:
	if CombatManager:
		CombatManager.card_staged.connect(_on_card_staged)
		CombatManager.card_unstaged.connect(_on_card_unstaged)
		CombatManager.cards_reordered.connect(_on_cards_reordered)
		CombatManager.execution_started.connect(_on_execution_started)
		CombatManager.execution_completed.connect(_on_execution_completed)
		CombatManager.card_executing.connect(_on_card_executing)
		CombatManager.card_executed.connect(_on_card_executed)
		CombatManager.lane_buff_applied.connect(_on_lane_buff_applied)
		CombatManager.staged_card_buffed.connect(_on_staged_card_buffed)


func _update_visibility() -> void:
	visible = true
	
	if lane_label:
		var count: int = staged_cards.size()
		if count == 0:
			lane_label.text = "⚔️ STAGING LANE - Drop cards here, then EXECUTE"
			lane_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.4, 0.7))
		else:
			lane_label.text = "⚔️ STAGED CARDS (%d) - Drag to reorder" % count
			lane_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.6, 0.9))
	
	if execute_button:
		execute_button.disabled = staged_cards.is_empty()
		execute_button.text = "⚡ EXECUTE ALL (%d) ⚡" % staged_cards.size() if staged_cards.size() > 0 else "⚡ EXECUTE ⚡"


func _on_execute_pressed() -> void:
	if staged_cards.is_empty():
		return
	execute_requested.emit()
	CombatManager.execute_staged_cards()


# =============================================================================
# STAGING
# =============================================================================

func stage_card(card_def, tier: int, drop_position: Vector2 = Vector2.ZERO) -> void:
	"""Add a card to the staging lane with animation and morph artwork to 3D."""
	var card_ui: Control = _create_staged_card(card_def, tier)
	if not card_ui:
		return
	
	var staged_entry: Dictionary = {
		"card_def": card_def,
		"tier": tier,
		"card_ui": card_ui,
		"applied_buffs": {}
	}
	staged_cards.append(staged_entry)
	
	# Add to tree FIRST so @onready vars are initialized
	card_container.add_child(card_ui)
	card_ui.modulate.a = 0.0
	
	# Apply any existing lane buffs to this newly staged card (must be after add_child)
	_apply_existing_buffs_to_card(card_ui, card_def)
	
	_update_visibility()
	
	if drop_position != Vector2.ZERO:
		await _animate_stage(card_ui, drop_position)
	else:
		_position_all_cards()
		var tween: Tween = card_ui.create_tween()
		tween.tween_property(card_ui, "modulate:a", 1.0, 0.2)
	
	# Morph the artwork to weapon sprite after card is positioned
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(card_ui) and card_ui.has_method("morph_artwork_to_3d"):
		await card_ui.morph_artwork_to_3d()


func _create_staged_card(card_def, tier: int) -> Control:
	var card_ui: Control = CardUIScene.instantiate()
	
	card_ui.check_playability = false
	card_ui.enable_hover_scale = false
	card_ui.setup(card_def, tier, -1)
	
	card_ui.scale = Vector2(card_scale, card_scale)
	card_ui.z_index = 1
	card_ui.pivot_offset = Vector2(CARD_BASE_WIDTH / 2.0, CARD_BASE_HEIGHT / 2.0)
	
	# Connect hover for in-place scaling
	_connect_card_hover(card_ui)
	
	# Connect drag for reordering
	_connect_card_drag(card_ui, staged_cards.size())
	
	return card_ui


func _apply_existing_buffs_to_card(card_ui: Control, card_def) -> void:
	"""Apply any existing lane buffs from CombatManager to a newly staged card.
	This is called when a card is staged AFTER buff cards have already been played."""
	if not CombatManager:
		return
	
	var lane_buffs: Dictionary = CombatManager.lane_buffs
	for buff_key: String in lane_buffs.keys():
		var buff_data: Dictionary = lane_buffs[buff_key]
		var tag_filter: String = buff_data.get("tag_filter", "")
		
		# Check if this card is affected by the buff
		var is_affected: bool = tag_filter.is_empty() or card_def.has_tag(tag_filter)
		
		if is_affected and card_ui.has_method("apply_buff"):
			# Apply the buff silently (no animation since it's initial state)
			card_ui.applied_buffs[buff_key] = buff_data.duplicate()
			card_ui._update_stats_row()
			print("[CombatLane] Applied existing buff to new card: ", buff_data.type, " +", buff_data.value)


func _connect_card_hover(card_ui: Control) -> void:
	var click_area: Button = card_ui.get_node_or_null("ClickArea")
	if click_area:
		click_area.mouse_entered.connect(_on_card_hover_enter.bind(card_ui))
		click_area.mouse_exited.connect(_on_card_hover_exit.bind(card_ui))


func _connect_card_drag(card_ui: Control, index: int) -> void:
	var click_area: Button = card_ui.get_node_or_null("ClickArea")
	if click_area:
		click_area.button_down.connect(_on_card_drag_start.bind(index))
		click_area.button_up.connect(_on_card_drag_end)


func _on_card_hover_enter(card_ui: Control) -> void:
	if not is_instance_valid(card_ui) or dragging_card_index >= 0:
		return
	
	var target_scale: float = card_scale * 1.15
	var tween: Tween = card_ui.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card_ui, "scale", Vector2(target_scale, target_scale), 0.12)
	card_ui.z_index = 50


func _on_card_hover_exit(card_ui: Control) -> void:
	if not is_instance_valid(card_ui):
		return
	
	var tween: Tween = card_ui.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(card_ui, "scale", Vector2(card_scale, card_scale), 0.12)
	card_ui.z_index = 1


# =============================================================================
# DRAG TO REORDER
# =============================================================================

func _on_card_drag_start(index: int) -> void:
	if index < 0 or index >= staged_cards.size():
		return
	
	dragging_card_index = index
	drag_start_position = get_global_mouse_position()
	
	var card_ui: Control = staged_cards[index].card_ui
	if is_instance_valid(card_ui):
		card_ui.z_index = 100
		card_ui.modulate = Color(1.2, 1.2, 1.0, 0.9)


func _on_card_drag_end() -> void:
	if dragging_card_index < 0:
		return
	
	var old_index: int = dragging_card_index
	var new_index: int = _get_drop_index()
	
	# Reset the dragged card's appearance
	if old_index < staged_cards.size():
		var card_ui: Control = staged_cards[old_index].card_ui
		if is_instance_valid(card_ui):
			card_ui.z_index = 1
			card_ui.modulate = Color.WHITE
	
	dragging_card_index = -1
	
	# Reorder if needed
	if new_index != old_index and new_index >= 0:
		CombatManager.reorder_staged_cards(old_index, new_index)


func _get_drop_index() -> int:
	"""Calculate where the card should be dropped based on mouse position."""
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	for i: int in range(staged_cards.size()):
		var card_ui: Control = staged_cards[i].card_ui
		if not is_instance_valid(card_ui):
			continue
		
		var card_center_x: float = card_ui.global_position.x + (CARD_BASE_WIDTH * card_scale / 2.0)
		if mouse_pos.x < card_center_x:
			return i
	
	return staged_cards.size() - 1


func _process(_delta: float) -> void:
	if dragging_card_index >= 0 and dragging_card_index < staged_cards.size():
		var card_ui: Control = staged_cards[dragging_card_index].card_ui
		if is_instance_valid(card_ui):
			var mouse_pos: Vector2 = get_global_mouse_position()
			card_ui.global_position = mouse_pos - Vector2(CARD_BASE_WIDTH * card_scale / 2.0, CARD_BASE_HEIGHT * card_scale / 2.0)


# =============================================================================
# POSITIONING
# =============================================================================

func _animate_stage(card_ui: Control, source_pos: Vector2) -> void:
	if not is_instance_valid(card_ui):
		return
	
	var target_pos: Vector2 = _calculate_card_position(staged_cards.size() - 1)
	
	card_ui.global_position = source_pos
	card_ui.modulate.a = 1.0
	card_ui.scale = Vector2(1.0, 1.0)
	card_ui.z_index = 50
	
	var tween: Tween = card_ui.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	
	tween.tween_property(card_ui, "global_position", target_pos, STAGE_ANIM_DURATION)
	tween.tween_property(card_ui, "scale", Vector2(card_scale, card_scale), STAGE_ANIM_DURATION)
	
	await tween.finished
	
	card_ui.z_index = 1
	_position_all_cards()


func _calculate_card_position(card_index: int) -> Vector2:
	var container_rect: Rect2 = card_container.get_global_rect()
	var container_center_x: float = container_rect.position.x + container_rect.size.x / 2.0
	
	var scaled_width: float = CARD_BASE_WIDTH * card_scale
	var scaled_height: float = CARD_BASE_HEIGHT * card_scale
	
	var total_cards: int = staged_cards.size()
	var total_width: float = (scaled_width * total_cards) + (CARD_SPACING * (total_cards - 1))
	
	var start_x: float = container_center_x - (total_width / 2.0)
	var card_x: float = start_x + (card_index * (scaled_width + CARD_SPACING))
	
	var container_center_y: float = container_rect.position.y + container_rect.size.y / 2.0
	var card_y: float = container_center_y - (scaled_height / 2.0)
	
	return Vector2(card_x, card_y)


func _position_all_cards() -> void:
	if staged_cards.is_empty():
		return
	
	for i: int in range(staged_cards.size()):
		var staged: Dictionary = staged_cards[i]
		var card_ui: Control = staged.card_ui
		if is_instance_valid(card_ui) and i != dragging_card_index:
			var target_pos: Vector2 = _calculate_card_position(i)
			
			var tween: Tween = card_ui.create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(card_ui, "global_position", target_pos, REORDER_ANIM_DURATION)
			
			card_ui.scale = Vector2(card_scale, card_scale)
			card_ui.z_index = 1


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_card_staged(_card_def, _tier: int, _lane_index: int) -> void:
	# CombatManager handles the staging, we just need to create the visual
	# This is called AFTER CombatManager.stage_card succeeds
	pass  # Visual is created when card is dropped on lane


func _on_card_unstaged(_lane_index: int) -> void:
	# Refresh visuals
	_sync_with_combat_manager()


func _on_cards_reordered() -> void:
	_sync_with_combat_manager()


func _sync_with_combat_manager() -> void:
	"""Sync our visual state with CombatManager's staged_cards."""
	var cm_staged: Array[Dictionary] = CombatManager.get_staged_cards()
	
	# Remove visuals for cards no longer staged
	var to_remove: Array[int] = []
	for i: int in range(staged_cards.size() - 1, -1, -1):
		var found: bool = false
		for cm_entry: Dictionary in cm_staged:
			if cm_entry.card_def == staged_cards[i].card_def:
				found = true
				break
		if not found:
			if is_instance_valid(staged_cards[i].card_ui):
				staged_cards[i].card_ui.queue_free()
			to_remove.append(i)
	
	for idx: int in to_remove:
		staged_cards.remove_at(idx)
	
	# Reorder to match CombatManager's order and sync buffs
	var new_order: Array[Dictionary] = []
	for cm_entry: Dictionary in cm_staged:
		for staged: Dictionary in staged_cards:
			if staged.card_def == cm_entry.card_def:
				# Sync buffs from CombatManager's entry to our visual
				staged.applied_buffs = cm_entry.get("applied_buffs", {}).duplicate()
				# Update the card UI's applied_buffs
				var card_ui: Control = staged.card_ui
				if is_instance_valid(card_ui):
					card_ui.applied_buffs = staged.applied_buffs.duplicate()
					card_ui._update_stats_row()
				new_order.append(staged)
				break
	staged_cards = new_order
	
	_position_all_cards()
	_update_visibility()


func _on_execution_started() -> void:
	execute_button.disabled = true
	execute_button.text = "⚡ EXECUTING... ⚡"
	
	# Change lane border to indicate execution
	var panel_style: StyleBoxFlat = lane_panel.get_theme_stylebox("panel").duplicate()
	panel_style.border_color = Color(1.0, 0.8, 0.3, 1.0)  # Gold during execution
	lane_panel.add_theme_stylebox_override("panel", panel_style)


func _on_execution_completed() -> void:
	# Clear all card visuals
	for staged: Dictionary in staged_cards:
		var card_ui: Control = staged.get("card_ui")
		_animate_card_discard(card_ui)
	
	staged_cards.clear()
	_update_visibility()
	
	# Restore lane border
	var panel_style: StyleBoxFlat = lane_panel.get_theme_stylebox("panel").duplicate()
	panel_style.border_color = Color(0.5, 0.8, 0.4, 0.9)  # Green
	lane_panel.add_theme_stylebox_override("panel", panel_style)


func _animate_card_discard(card_ui: Control) -> void:
	if is_instance_valid(card_ui):
		var tween: Tween = card_ui.create_tween()
		tween.set_parallel(true)
		tween.tween_property(card_ui, "modulate:a", 0.0, 0.3)
		tween.tween_property(card_ui, "position:y", card_ui.position.y + 50, 0.3)
		tween.tween_callback(card_ui.queue_free)


func _on_card_executing(card_def, _tier: int, lane_index: int) -> void:
	if lane_index < 0 or lane_index >= staged_cards.size():
		return
	
	var staged: Dictionary = staged_cards[lane_index]
	var card_ui: Control = staged.card_ui
	
	if not is_instance_valid(card_ui):
		return
	
	# Pulse effect on the card (artwork is already in 3D mode from staging)
	var tween: Tween = card_ui.create_tween()
	tween.tween_property(card_ui, "scale", Vector2(card_scale * 1.2, card_scale * 1.2), EXECUTE_PULSE_DURATION * 0.4)
	tween.parallel().tween_property(card_ui, "modulate", Color(1.5, 1.3, 0.8, 1.0), EXECUTE_PULSE_DURATION * 0.4)


func _on_card_executed(card_def, _tier: int) -> void:
	# Find the card and dim it after execution
	for staged: Dictionary in staged_cards:
		if staged.card_def == card_def:
			var card_ui: Control = staged.card_ui
			if is_instance_valid(card_ui):
				var tween: Tween = card_ui.create_tween()
				tween.tween_property(card_ui, "modulate", Color(0.5, 0.5, 0.5, 0.7), 0.2)
				tween.tween_property(card_ui, "scale", Vector2(card_scale * 0.9, card_scale * 0.9), 0.2)
			break


func _on_lane_buff_applied(buff_type: String, buff_value: int, tag_filter: String) -> void:
	"""Called when an instant buff card is played - update all affected staged cards."""
	print("[CombatLane] Lane buff applied: ", buff_type, " +", buff_value, " (filter: ", tag_filter, ")")
	
	# Update visual on each affected card
	for staged: Dictionary in staged_cards:
		var card_ui: Control = staged.card_ui
		var card_def = staged.card_def
		
		if not is_instance_valid(card_ui):
			continue
		
		# Check if this card is affected by the buff (based on tag filter)
		var is_affected: bool = tag_filter.is_empty() or card_def.has_tag(tag_filter)
		
		if is_affected and card_ui.has_method("apply_buff"):
			card_ui.apply_buff(buff_type, buff_value, tag_filter)


func _on_staged_card_buffed(lane_index: int, buff_type: String, buff_value: int) -> void:
	"""Called when a specific staged card receives a buff."""
	if lane_index < 0 or lane_index >= staged_cards.size():
		return
	
	# The CardUI.apply_buff method is called via _on_lane_buff_applied
	# This signal is for additional tracking if needed
	print("[CombatLane] Card at index ", lane_index, " buffed: ", buff_type, " +", buff_value)


# =============================================================================
# PUBLIC API
# =============================================================================

func clear_all_cards() -> void:
	"""Remove all staged cards (wave end)."""
	for staged: Dictionary in staged_cards:
		if is_instance_valid(staged.card_ui):
			staged.card_ui.queue_free()
	staged_cards.clear()
	_update_visibility()


func get_staged_count() -> int:
	return staged_cards.size()


func get_card_center_position(index: int) -> Vector2:
	"""Get the global center position of a staged card."""
	if index < 0 or index >= staged_cards.size():
		return Vector2.ZERO
	
	var card_ui: Control = staged_cards[index].card_ui
	if not is_instance_valid(card_ui):
		return Vector2.ZERO
	
	var scaled_size: Vector2 = Vector2(CARD_BASE_WIDTH, CARD_BASE_HEIGHT) * card_scale
	return card_ui.global_position + scaled_size / 2.0


func fire_weapon_at_target(index: int, target_position: Vector2) -> Vector2:
	"""Fire the weapon at a target and return the muzzle position for projectile origin."""
	if index < 0 or index >= staged_cards.size():
		return Vector2.ZERO
	
	var staged: Dictionary = staged_cards[index]
	var card_ui: Control = staged.card_ui
	
	if is_instance_valid(card_ui) and card_ui.has_method("fire_weapon"):
		# Point weapon at target and fire
		card_ui.fire_weapon(target_position)
		
		# Get muzzle position
		var muzzle_pos: Vector2 = card_ui.get_muzzle_global_position()
		
		# Emit signal for projectile system
		weapon_fired.emit(staged.card_def, muzzle_pos, target_position)
		
		return muzzle_pos
	
	# Fallback to card center
	return get_card_center_position(index)


func get_weapon_muzzle_position(index: int) -> Vector2:
	"""Get the muzzle position of a staged weapon."""
	if index < 0 or index >= staged_cards.size():
		return Vector2.ZERO
	
	var staged: Dictionary = staged_cards[index]
	var card_ui: Control = staged.card_ui
	
	if is_instance_valid(card_ui) and card_ui.has_method("get_muzzle_global_position"):
		return card_ui.get_muzzle_global_position()
	
	return get_card_center_position(index)


func set_weapon_target(index: int, target_position: Vector2) -> void:
	"""Set the target for a weapon to face."""
	if index < 0 or index >= staged_cards.size():
		return
	
	var staged: Dictionary = staged_cards[index]
	var card_ui: Control = staged.card_ui
	
	if is_instance_valid(card_ui) and card_ui.has_method("set_weapon_target"):
		card_ui.set_weapon_target(target_position)


func get_weapon_center_position(weapon_name: String) -> Vector2:
	"""Get the center position of a weapon by name (for projectile origins)."""
	for i: int in range(staged_cards.size()):
		var staged: Dictionary = staged_cards[i]
		if staged.card_def.card_name == weapon_name:
			var card_ui: Control = staged.card_ui
			if is_instance_valid(card_ui) and card_ui.has_method("get_muzzle_global_position"):
				return card_ui.get_muzzle_global_position()
			return get_card_center_position(i)
	return Vector2.ZERO


# Drop highlight for staging
var _drop_highlight_panel: Panel = null


func set_drop_highlight(highlight: bool) -> void:
	"""Show or hide drop highlight when dragging a card over the lane."""
	if highlight:
		if not _drop_highlight_panel:
			_create_drop_highlight()
		_drop_highlight_panel.visible = true
	else:
		if _drop_highlight_panel:
			_drop_highlight_panel.visible = false


func _create_drop_highlight() -> void:
	_drop_highlight_panel = Panel.new()
	_drop_highlight_panel.name = "DropHighlight"
	_drop_highlight_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_drop_highlight_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drop_highlight_panel.z_index = 10
	
	var highlight_style: StyleBoxFlat = StyleBoxFlat.new()
	highlight_style.bg_color = Color(0.4, 0.8, 0.3, 0.25)
	highlight_style.border_color = Color(0.5, 1.0, 0.4, 0.9)
	highlight_style.set_border_width_all(4)
	highlight_style.set_corner_radius_all(12)
	_drop_highlight_panel.add_theme_stylebox_override("panel", highlight_style)
	
	add_child(_drop_highlight_panel)
	_drop_highlight_panel.visible = false
