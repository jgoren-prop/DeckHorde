extends Control
class_name BattlefieldHoverSystem
## Handles hover states and info cards for enemies and stacks.

@warning_ignore("unused_signal")
signal info_card_requested(enemy, position: Vector2)
@warning_ignore("unused_signal")
signal info_card_hide_requested()

const BattlefieldInfoCardsHelper = preload("res://scripts/combat/BattlefieldInfoCards.gd")
const STACK_MINI_PANEL_SIZE: Vector2 = Vector2(55.0, 50.0)
const STACK_MINI_VERTICAL_GAP: float = 16.0
const INFO_CARD_HORIZONTAL_GAP: float = 24.0
const INFO_CARD_VERTICAL_SPACING: float = 6.0

# State
var _current_hover_enemy = null
var _current_hover_stack_key: String = ""
var _info_card: Control = null
var _info_card_tween: Tween = null
var _current_hover_anchor_rect: Rect2 = Rect2()

# Settings
var info_card_delay: float = 0.3
var _pending_info_timer: SceneTreeTimer = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func on_enemy_hover_enter(visual: Panel, enemy) -> void:
	"""Handle enemy hover enter."""
	_current_hover_enemy = enemy
	_current_hover_anchor_rect = _build_anchor_rect(visual)
	_begin_info_card_timer(enemy, visual.global_position + visual.size / 2, "", info_card_delay, _current_hover_anchor_rect)


func on_enemy_hover_exit(visual: Panel) -> void:
	"""Handle enemy hover exit."""
	_current_hover_enemy = null
	_current_hover_anchor_rect = Rect2()
	
	# If the panel is no longer valid (being removed), hide immediately
	if not is_instance_valid(visual):
		_hide_info_card()
	else:
		_schedule_hide_info_card()


func on_stack_hover_enter(panel: Panel, stack_key: String) -> void:
	"""Handle stack hover enter."""
	_current_hover_stack_key = stack_key
	_current_hover_anchor_rect = _build_anchor_rect(panel)
	var enemy = panel.get_meta("representative_enemy", null)
	if enemy and is_instance_valid(enemy):
		_current_hover_enemy = enemy
		_begin_info_card_timer(enemy, panel.global_position + panel.size / 2, stack_key, 0.0, _current_hover_anchor_rect)
	else:
		_current_hover_enemy = null


func on_stack_hover_exit(panel: Panel, stack_key: String) -> void:
	"""Handle stack hover exit."""
	# Only clear if this matches the current hover (prevents clearing wrong state)
	if _current_hover_stack_key == stack_key:
		_current_hover_stack_key = ""
		_current_hover_enemy = null
		_current_hover_anchor_rect = Rect2()
	
	# If the panel is no longer valid (being removed), hide immediately
	if not is_instance_valid(panel):
		_hide_info_card()
	else:
		_schedule_hide_info_card()


func on_mini_panel_hover_enter(_panel: Panel, _enemy, _stack_key: String) -> void:
	"""Handle mini-panel hover enter."""
	# Mini-panels should not spawn info cards; just ensure no pending card shows.
	_current_hover_enemy = null
	_current_hover_anchor_rect = Rect2()


func on_mini_panel_hover_exit(_panel: Panel, _stack_key: String) -> void:
	"""Handle mini-panel hover exit."""
	_current_hover_enemy = null
	_current_hover_anchor_rect = Rect2()
	_schedule_hide_info_card()


func _show_info_card(enemy, global_pos: Vector2, anchor_rect: Rect2 = Rect2()) -> void:
	"""Show an info card for an enemy."""
	if enemy == null:
		return
	if enemy is Object and not is_instance_valid(enemy):
		return
	_hide_info_card()
	
	var enemy_def: EnemyDefinition = EnemyDatabase.get_enemy(enemy.enemy_id)
	if not enemy_def:
		return
	
	# Use the existing static method
	var ring_names: Array[String] = ["MELEE", "CLOSE", "MID", "FAR"]
	var enemy_colors: Dictionary = {
		"husk": Color(0.7, 0.4, 0.3),
		"spinecrawler": Color(0.8, 0.3, 0.5),
		"torchbearer": Color(1.0, 0.6, 0.2),
		"spitter": Color(0.3, 0.7, 0.4),
		"shell_titan": Color(0.5, 0.5, 0.65),
		"bomber": Color(1.0, 0.3, 0.1),
		"channeler": Color(0.6, 0.3, 0.8),
		"ember_saint": Color(1.0, 0.5, 0.0),
		"cultist": Color(0.5, 0.4, 0.6),
		"stalker": Color(0.3, 0.3, 0.4),
		"weakling": Color(0.5, 0.5, 0.5)
	}
	_info_card = BattlefieldInfoCardsHelper.create_enemy_type_card(enemy_def, ring_names, enemy_colors)
	add_child(_info_card)
	
	var card_size: Vector2 = _info_card.get_combined_minimum_size()
	if card_size == Vector2.ZERO:
		card_size = _info_card.size
	if card_size == Vector2.ZERO:
		card_size = Vector2(200, 280)
	_info_card.custom_minimum_size = card_size
	
	var local_pos: Vector2 = global_pos - global_position
	var positioned: Vector2 = _calculate_info_card_position(anchor_rect, local_pos, card_size)
	_info_card.position = positioned
	_info_card.modulate.a = 0.0
	
	_info_card_tween = create_tween()
	_info_card_tween.tween_property(_info_card, "modulate:a", 1.0, 0.15)


func _schedule_hide_info_card(delay: float = 0.1) -> void:
	"""Schedule hiding the info card after a delay."""
	# Safety check: if we're no longer in the tree (scene changing), hide immediately
	if not is_inside_tree():
		_hide_info_card()
		return
	
	_pending_info_timer = get_tree().create_timer(delay)
	_pending_info_timer.timeout.connect(func():
		if _current_hover_enemy == null:
			_hide_info_card()
	)


func _hide_info_card() -> void:
	"""Hide the current info card with fade-out animation."""
	# Only kill the fade-in tween if we have a card to hide
	# Don't kill fade-out tweens that are already running (card already being freed)
	if _info_card and is_instance_valid(_info_card):
		# Kill any fade-in tween
		if _info_card_tween and _info_card_tween.is_valid():
			_info_card_tween.kill()
		_info_card_tween = null
		
		var card_to_free: Control = _info_card
		_info_card = null
		
		# If we're not in the tree (scene changing), just free immediately without animation
		if not is_inside_tree():
			card_to_free.queue_free()
			return
		
		# Fade out before freeing - use a separate local tween so it doesn't get killed
		var fade_out_tween: Tween = create_tween()
		fade_out_tween.tween_property(card_to_free, "modulate:a", 0.0, 0.15)
		fade_out_tween.tween_callback(card_to_free.queue_free)
	# If _info_card is already null, a fade-out may already be in progress - don't interfere


func _begin_info_card_timer(enemy, global_pos: Vector2, stack_key: String = "", delay: float = info_card_delay, anchor_rect: Rect2 = Rect2()) -> void:
	"""Start the timer that spawns an info card for the provided enemy."""
	if enemy == null:
		return
	
	# Safety check: if we're no longer in the tree (scene changing), abort
	if not is_inside_tree():
		return
	
	if _pending_info_timer:
		_pending_info_timer = null
	
	var awaited_enemy = enemy
	var awaited_stack: String = stack_key
	var awaited_rect: Rect2 = anchor_rect
	var awaited_pos: Vector2 = global_pos
	
	if delay <= 0.0:
		if _should_show_info_card(awaited_enemy, awaited_stack):
			_show_info_card(awaited_enemy, awaited_pos, awaited_rect)
		return
	
	_pending_info_timer = get_tree().create_timer(delay)
	_pending_info_timer.timeout.connect(func():
		if _should_show_info_card(awaited_enemy, awaited_stack):
			_show_info_card(awaited_enemy, awaited_pos, awaited_rect)
	)


func _build_anchor_rect(control: Control) -> Rect2:
	if control == null or not is_instance_valid(control):
		return Rect2()
	var inv_transform: Transform2D = get_global_transform_with_canvas().affine_inverse()
	var top_left: Vector2 = inv_transform * control.global_position
	return Rect2(top_left, control.size)


func _calculate_info_card_position(anchor_rect: Rect2, fallback_local: Vector2, card_size: Vector2) -> Vector2:
	var has_anchor: bool = anchor_rect.size != Vector2.ZERO
	var card_pos: Vector2 = Vector2(fallback_local.x + 120.0, fallback_local.y - 60.0)
	
	if has_anchor:
		card_pos.x = anchor_rect.position.x + anchor_rect.size.x + INFO_CARD_HORIZONTAL_GAP
		card_pos.y = anchor_rect.position.y + INFO_CARD_VERTICAL_SPACING
		if not _current_hover_stack_key.is_empty():
			var mini_bottom: float = anchor_rect.position.y - STACK_MINI_VERTICAL_GAP
			card_pos.y = mini_bottom + INFO_CARD_VERTICAL_SPACING
	
	# Clamp horizontally
	if card_pos.x + card_size.x > size.x - 10.0:
		if has_anchor:
			card_pos.x = anchor_rect.position.x - card_size.x - INFO_CARD_HORIZONTAL_GAP
		else:
			card_pos.x = fallback_local.x - card_size.x - INFO_CARD_HORIZONTAL_GAP
	card_pos.x = clamp(card_pos.x, 10.0, max(10.0, size.x - card_size.x - 10.0))
	
	# Clamp vertically
	if card_pos.y + card_size.y > size.y - 10.0:
		card_pos.y = size.y - card_size.y - 10.0
	if card_pos.y < 10.0:
		card_pos.y = 10.0
	
	return card_pos


func _should_show_info_card(awaited_enemy, awaited_stack: String) -> bool:
	var enemy_matches: bool = _current_hover_enemy == awaited_enemy
	var stack_matches: bool = awaited_stack.is_empty() or _current_hover_stack_key == awaited_stack
	return enemy_matches and stack_matches


func clear() -> void:
	"""Clear all hover state."""
	_current_hover_enemy = null
	_current_hover_stack_key = ""
	_current_hover_anchor_rect = Rect2()
	# Cancel any pending info card timer
	_pending_info_timer = null
	_hide_info_card()


func clear_all_hover_states() -> void:
	"""Alias for clear() - clears all hover highlights."""
	clear()
