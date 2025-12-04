extends Control
class_name BattlefieldHoverSystem
## Handles hover states and info cards for enemies and stacks.

signal info_card_requested(enemy, position: Vector2)
signal info_card_hide_requested()

const BattlefieldInfoCardsHelper = preload("res://scripts/combat/BattlefieldInfoCards.gd")

# State
var _current_hover_enemy = null
var _current_hover_stack_key: String = ""
var _info_card: Control = null
var _info_card_tween: Tween = null

# Settings
var info_card_delay: float = 0.3
var _pending_info_timer: SceneTreeTimer = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func on_enemy_hover_enter(visual: Panel, enemy) -> void:
	"""Handle enemy hover enter."""
	_current_hover_enemy = enemy
	
	# Cancel any pending hide
	if _pending_info_timer:
		_pending_info_timer = null
	
	# Show info card after delay
	_pending_info_timer = get_tree().create_timer(info_card_delay)
	_pending_info_timer.timeout.connect(func():
		if _current_hover_enemy == enemy:
			_show_info_card(enemy, visual.global_position + visual.size / 2)
	)


func on_enemy_hover_exit(_visual: Panel) -> void:
	"""Handle enemy hover exit."""
	_current_hover_enemy = null
	_schedule_hide_info_card()


func on_stack_hover_enter(_panel: Panel, stack_key: String) -> void:
	"""Handle stack hover enter."""
	_current_hover_stack_key = stack_key


func on_stack_hover_exit(_panel: Panel, _stack_key: String) -> void:
	"""Handle stack hover exit."""
	_current_hover_stack_key = ""
	_schedule_hide_info_card()


func on_mini_panel_hover_enter(panel: Panel, enemy, _stack_key: String) -> void:
	"""Handle mini-panel hover enter."""
	_current_hover_enemy = enemy
	
	_pending_info_timer = get_tree().create_timer(info_card_delay)
	_pending_info_timer.timeout.connect(func():
		if _current_hover_enemy == enemy:
			_show_info_card(enemy, panel.global_position + panel.size / 2)
	)


func on_mini_panel_hover_exit(_panel: Panel, _stack_key: String) -> void:
	"""Handle mini-panel hover exit."""
	_current_hover_enemy = null
	_schedule_hide_info_card()


func _show_info_card(enemy, global_pos: Vector2) -> void:
	"""Show an info card for an enemy."""
	_hide_info_card()
	
	var enemy_db = Engine.get_singleton("EnemyDatabase")
	var enemy_def = enemy_db.get_enemy(enemy.enemy_id) if enemy_db else null
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
	
	# Position relative to hover position
	var local_pos: Vector2 = global_pos - global_position
	var card_x: float = local_pos.x + 120
	var card_y: float = local_pos.y - 60
	
	# Keep on screen
	if card_x + _info_card.size.x > size.x:
		card_x = local_pos.x - _info_card.size.x - 20
	if card_y + _info_card.size.y > size.y:
		card_y = size.y - _info_card.size.y - 10
	if card_y < 10:
		card_y = 10
	
	_info_card.position = Vector2(card_x, card_y)
	_info_card.modulate.a = 0.0
	
	_info_card_tween = create_tween()
	_info_card_tween.tween_property(_info_card, "modulate:a", 1.0, 0.15)


func _schedule_hide_info_card() -> void:
	"""Schedule hiding the info card after a short delay."""
	_pending_info_timer = get_tree().create_timer(0.1)
	_pending_info_timer.timeout.connect(func():
		if _current_hover_enemy == null:
			_hide_info_card()
	)


func _hide_info_card() -> void:
	"""Hide the current info card."""
	if _info_card_tween and _info_card_tween.is_valid():
		_info_card_tween.kill()
	
	if _info_card and is_instance_valid(_info_card):
		_info_card.queue_free()
	_info_card = null


func clear() -> void:
	"""Clear all hover state."""
	_current_hover_enemy = null
	_current_hover_stack_key = ""
	_hide_info_card()


func clear_all_hover_states() -> void:
	"""Alias for clear() - clears all hover highlights."""
	clear()

