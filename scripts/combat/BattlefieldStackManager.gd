extends RefCounted
class_name BattlefieldStackManager
## Manages enemy stacking, grouping, and stack expansion/collapse in the battlefield.
## Handles persistent groups, stack visuals, and mini-panel management.

# EnemyDatabase is provided via autoload singleton
const BattlefieldInfoCardsHelper = preload("res://scripts/combat/BattlefieldInfoCards.gd")

# Stacking configuration constants
const MAX_ENEMIES_BEFORE_MULTIROW: int = 4
const MAX_ENEMIES_PER_ROW: int = 5
const STACK_THRESHOLD: int = 3
const MAX_TOTAL_BEFORE_STACKING: int = 2
const INNER_ROW_RATIO: float = 0.35
const OUTER_ROW_RATIO: float = 0.75
const STACK_COLLAPSE_DELAY: float = 1.0

# Stack visuals: "ring_enemytype_groupid" -> {panel, enemies, expanded, mini_panels}
var stack_visuals: Dictionary = {}

# Persistent enemy groups: group_id -> {ring, enemy_id, enemies}
var enemy_groups: Dictionary = {}
var _next_group_id: int = 0

# Position tracking
var _stack_base_positions: Dictionary = {}
var _stack_position_tweens: Dictionary = {}
var _stack_scale_tweens: Dictionary = {}
var _group_positions: Dictionary = {}
var _group_angular_positions: Dictionary = {}

# Stack hold system
var _stack_hold_counts: Dictionary = {}
var _stack_collapse_timers: Dictionary = {}

# Deferred refresh tracking
var _pending_ring_refreshes: Dictionary = {}

# References to battlefield arena (set on init)
var _arena: Control = null
var _enemy_container: Control = null


func initialize(arena: Control, enemy_container: Control) -> void:
	"""Initialize with references to the battlefield arena and containers."""
	_arena = arena
	_enemy_container = enemy_container


# ============== GROUP MANAGEMENT ==============

func generate_group_id() -> String:
	"""Generate a unique group ID."""
	_next_group_id += 1
	return "group_" + str(_next_group_id)


func create_enemy_group(ring: int, enemy_id: String, enemies: Array) -> String:
	"""Create a new persistent group and assign enemies to it."""
	var group_id: String = generate_group_id()
	enemy_groups[group_id] = {
		"ring": ring,
		"enemy_id": enemy_id,
		"enemies": enemies
	}
	
	for enemy in enemies:
		enemy.group_id = group_id
	
	return group_id


func add_enemy_to_group(enemy, group_id: String) -> void:
	"""Add an enemy to an existing group."""
	if not enemy_groups.has(group_id):
		push_error("[BattlefieldStackManager] Cannot add enemy to non-existent group: " + group_id)
		return
	
	enemy.group_id = group_id
	enemy_groups[group_id].enemies.append(enemy)


func remove_enemy_from_group(enemy) -> void:
	"""Remove an enemy from its group when killed."""
	if enemy.group_id.is_empty():
		return
	
	var group_id: String = enemy.group_id
	if not enemy_groups.has(group_id):
		return
	
	var group: Dictionary = enemy_groups[group_id]
	group.enemies.erase(enemy)
	enemy.group_id = ""


func get_enemy_groups_in_ring(ring: int) -> Dictionary:
	"""Get persistent groups in a ring. Returns {group_id: {ring, enemy_id, enemies}}"""
	var groups: Dictionary = {}
	
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		var alive_enemies_in_ring: Array = []
		for enemy in group.enemies:
			if enemy.is_alive() and enemy.ring == ring:
				alive_enemies_in_ring.append(enemy)
		
		if not alive_enemies_in_ring.is_empty():
			groups[group_id] = {
				"ring": ring,
				"enemy_id": group.enemy_id,
				"enemies": alive_enemies_in_ring
			}
	
	return groups


func get_persistent_groups_by_type(ring: int) -> Dictionary:
	"""Get groups by enemy type. Returns {enemy_id: Array[group_dict]}"""
	var result: Dictionary = {}
	var groups: Dictionary = get_enemy_groups_in_ring(ring)
	
	for group_id: String in groups.keys():
		var group: Dictionary = groups[group_id]
		var eid: String = group.enemy_id
		if not result.has(eid):
			result[eid] = []
		result[eid].append(group)
	
	return result


# ============== STACKING LOGIC ==============

func should_stack_in_ring(ring: int, battlefield) -> bool:
	"""Check if stacking should be applied in this ring."""
	if not battlefield:
		return false
	var total: int = battlefield.get_enemies_in_ring(ring).size()
	return total > MAX_TOTAL_BEFORE_STACKING


func ring_stacking_changed(ring: int, battlefield) -> bool:
	"""Check if the stacking state of a ring has changed."""
	if not battlefield:
		return false
	
	var should_stack: bool = should_stack_in_ring(ring, battlefield)
	var has_stacks: bool = false
	
	for key: String in stack_visuals.keys():
		if key.begins_with(str(ring) + "_"):
			has_stacks = true
			break
	
	return should_stack != has_stacks


func get_stack_key(ring: int, enemy_id: String) -> String:
	"""Generate unique key for a stack."""
	return str(ring) + "_" + enemy_id


func get_stack_key_for_enemy(enemy) -> String:
	"""Get the stack key for an enemy based on its group."""
	if not enemy.group_id.is_empty() and enemy_groups.has(enemy.group_id):
		var group: Dictionary = enemy_groups[enemy.group_id]
		var group_key: String = str(group.ring) + "_" + group.enemy_id + "_" + enemy.group_id
		if stack_visuals.has(group_key):
			return group_key
	
	for stack_key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[stack_key]
		if stack_data.has("enemies"):
			for stacked_enemy in stack_data.enemies:
				if stacked_enemy.instance_id == enemy.instance_id:
					return stack_key
	
	return ""


func has_stack(stack_key: String) -> bool:
	"""Check if a stack exists."""
	return stack_visuals.has(stack_key)


func get_stack_data(stack_key: String) -> Dictionary:
	"""Get stack data for a key."""
	return stack_visuals.get(stack_key, {})


func get_stack_panel(stack_key: String) -> Panel:
	"""Get the panel for a stack."""
	if stack_visuals.has(stack_key):
		return stack_visuals[stack_key].get("panel")
	return null


func is_stack_expanded(stack_key: String) -> bool:
	"""Check if a stack is expanded."""
	if stack_visuals.has(stack_key):
		return stack_visuals[stack_key].get("expanded", false)
	return false


func get_stack_enemies(stack_key: String) -> Array:
	"""Get enemies in a stack."""
	if stack_visuals.has(stack_key):
		return stack_visuals[stack_key].get("enemies", [])
	return []


func get_stack_mini_panels(stack_key: String) -> Array:
	"""Get mini panels for an expanded stack."""
	if stack_visuals.has(stack_key):
		return stack_visuals[stack_key].get("mini_panels", [])
	return []


# ============== STACK HOLD SYSTEM ==============

func hold_stack_open(stack_key: String) -> void:
	"""Increment hold count to keep stack expanded."""
	if not stack_visuals.has(stack_key):
		return
	
	if not _stack_hold_counts.has(stack_key):
		_stack_hold_counts[stack_key] = 0
	_stack_hold_counts[stack_key] += 1
	
	# Cancel any pending collapse timer
	if _stack_collapse_timers.has(stack_key):
		_stack_collapse_timers.erase(stack_key)


func release_stack_hold(stack_key: String) -> void:
	"""Decrement hold count, collapse when zero."""
	if not _stack_hold_counts.has(stack_key):
		return
	
	_stack_hold_counts[stack_key] -= 1
	
	if _stack_hold_counts[stack_key] <= 0:
		_stack_hold_counts.erase(stack_key)


func get_hold_count(stack_key: String) -> int:
	"""Get the current hold count for a stack."""
	return _stack_hold_counts.get(stack_key, 0)


func has_collapse_timer(stack_key: String) -> bool:
	"""Check if a collapse timer exists."""
	return _stack_collapse_timers.has(stack_key)


func set_collapse_timer(stack_key: String, timer) -> void:
	"""Store a collapse timer reference."""
	_stack_collapse_timers[stack_key] = timer


func clear_collapse_timer(stack_key: String) -> void:
	"""Clear a collapse timer."""
	_stack_collapse_timers.erase(stack_key)


# ============== POSITION TRACKING ==============

func get_base_position(stack_key: String) -> Vector2:
	"""Get the base position for a stack."""
	return _stack_base_positions.get(stack_key, Vector2.ZERO)


func set_base_position(stack_key: String, pos: Vector2) -> void:
	"""Set the base position for a stack."""
	_stack_base_positions[stack_key] = pos


func has_base_position(stack_key: String) -> bool:
	"""Check if a base position exists."""
	return _stack_base_positions.has(stack_key)


func clear_base_position(stack_key: String) -> void:
	"""Clear base position tracking."""
	_stack_base_positions.erase(stack_key)


func get_group_position(group_id: String) -> Vector2:
	"""Get preserved position for a group."""
	return _group_positions.get(group_id, Vector2.ZERO)


func set_group_position(group_id: String, pos: Vector2) -> void:
	"""Set preserved position for a group."""
	_group_positions[group_id] = pos


func has_group_position(group_id: String) -> bool:
	"""Check if a group position exists."""
	return _group_positions.has(group_id)


func get_angular_position(group_id: String) -> float:
	"""Get angular position for a group."""
	return _group_angular_positions.get(group_id, 0.0)


func set_angular_position(group_id: String, angle: float) -> void:
	"""Set angular position for a group."""
	_group_angular_positions[group_id] = angle


# ============== TWEEN MANAGEMENT ==============

func get_position_tween(stack_key: String) -> Tween:
	"""Get active position tween for a stack."""
	return _stack_position_tweens.get(stack_key)


func set_position_tween(stack_key: String, tween: Tween) -> void:
	"""Set position tween for a stack."""
	_stack_position_tweens[stack_key] = tween


func kill_position_tween(stack_key: String) -> void:
	"""Kill and clear position tween."""
	if _stack_position_tweens.has(stack_key):
		var tween: Tween = _stack_position_tweens[stack_key]
		if tween and tween.is_valid():
			tween.kill()
		_stack_position_tweens.erase(stack_key)


func get_scale_tween(stack_key: String) -> Tween:
	"""Get active scale tween for a stack."""
	return _stack_scale_tweens.get(stack_key)


func set_scale_tween(stack_key: String, tween: Tween) -> void:
	"""Set scale tween for a stack."""
	_stack_scale_tweens[stack_key] = tween


func kill_scale_tween(stack_key: String) -> void:
	"""Kill and clear scale tween."""
	if _stack_scale_tweens.has(stack_key):
		var tween: Tween = _stack_scale_tweens[stack_key]
		if tween and tween.is_valid():
			tween.kill()
		_stack_scale_tweens.erase(stack_key)


# ============== STACK VISUAL MANAGEMENT ==============

func register_stack(stack_key: String, panel: Panel, enemies: Array) -> void:
	"""Register a new stack visual."""
	stack_visuals[stack_key] = {
		"panel": panel,
		"enemies": enemies,
		"expanded": false,
		"mini_panels": []
	}


func set_stack_expanded(stack_key: String, expanded: bool) -> void:
	"""Set the expanded state of a stack."""
	if stack_visuals.has(stack_key):
		stack_visuals[stack_key].expanded = expanded


func set_stack_mini_panels(stack_key: String, panels: Array) -> void:
	"""Set mini panels for a stack."""
	if stack_visuals.has(stack_key):
		stack_visuals[stack_key].mini_panels = panels


func clear_stack_mini_panels(stack_key: String) -> void:
	"""Clear and free mini panels for a stack."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	if stack_data.has("mini_panels"):
		for mini_panel in stack_data.mini_panels:
			if is_instance_valid(mini_panel):
				mini_panel.queue_free()
		stack_data.mini_panels.clear()


func remove_stack(stack_key: String) -> void:
	"""Remove a stack and clean up its resources."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	
	# Kill tweens
	kill_position_tween(stack_key)
	kill_scale_tween(stack_key)
	
	# Clear base position
	clear_base_position(stack_key)
	
	# Clear mini panels
	clear_stack_mini_panels(stack_key)
	
	# Free main panel
	if stack_data.has("panel") and is_instance_valid(stack_data.panel):
		stack_data.panel.queue_free()
	
	stack_visuals.erase(stack_key)


func clear_ring_stacks(ring: int) -> Dictionary:
	"""Clear all stacks for a ring, returning preserved positions."""
	var preserved_positions: Dictionary = {}
	var keys_to_remove: Array = []
	
	for key: String in stack_visuals.keys():
		if key.begins_with(str(ring) + "_"):
			var stack_data: Dictionary = stack_visuals[key]
			
			# Preserve position
			var preserved_pos: Vector2 = Vector2.ZERO
			if _stack_base_positions.has(key):
				preserved_pos = _stack_base_positions[key]
				preserved_positions[key] = preserved_pos
			elif stack_data.has("panel") and is_instance_valid(stack_data.panel):
				preserved_pos = stack_data.panel.position
				preserved_positions[key] = preserved_pos
			
			# Save position by group_id for cross-ring persistence
			var key_parts: PackedStringArray = key.split("_")
			if key_parts.size() >= 3:
				var group_id_parts: Array[String] = []
				for i: int in range(2, key_parts.size()):
					group_id_parts.append(key_parts[i])
				var group_id: String = "_".join(group_id_parts)
				
				if not group_id.is_empty() and preserved_pos.length() > 1.0:
					_group_positions[group_id] = preserved_pos
			
			# Kill tweens
			kill_position_tween(key)
			kill_scale_tween(key)
			clear_base_position(key)
			
			# Clean up mini panels
			clear_stack_mini_panels(key)
			
			# Free main panel
			if stack_data.has("panel") and is_instance_valid(stack_data.panel):
				stack_data.panel.queue_free()
			
			keys_to_remove.append(key)
	
	for key: String in keys_to_remove:
		stack_visuals.erase(key)
	
	return preserved_positions


func clear_all_stacks() -> void:
	"""Clear all stack visuals."""
	for stack_key: String in stack_visuals.keys():
		remove_stack(stack_key)
	stack_visuals.clear()
	_stack_hold_counts.clear()
	_stack_collapse_timers.clear()


# ============== DEFERRED REFRESH ==============

func schedule_deferred_refresh(ring: int, callback: Callable) -> void:
	"""Schedule a deferred refresh for a ring."""
	var frame: int = Engine.get_process_frames()
	var key: String = str(ring) + "_" + str(frame)
	
	if _pending_ring_refreshes.has(key):
		return
	
	_pending_ring_refreshes[key] = true
	callback.call()
	
	# Clean up old entries
	var keys_to_remove: Array = []
	for k: String in _pending_ring_refreshes.keys():
		if not k.ends_with("_" + str(frame)):
			keys_to_remove.append(k)
	for k: String in keys_to_remove:
		_pending_ring_refreshes.erase(k)


# ============== UTILITY ==============

func update_stack_count_display(stack_key: String) -> void:
	"""Update the count badge on a stack panel."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var panel: Panel = stack_data.get("panel")
	var enemies: Array = stack_data.get("enemies", [])
	
	if not is_instance_valid(panel):
		return
	
	var count_badge: Panel = panel.get_node_or_null("CountBadge")
	if count_badge:
		var count_label: Label = count_badge.get_node_or_null("CountLabel")
		if count_label:
			count_label.text = "x" + str(enemies.size())


func update_stack_hp_display(stack_key: String) -> void:
	"""Update HP display on a stack panel."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var panel: Panel = stack_data.get("panel")
	var enemies: Array = stack_data.get("enemies", [])
	
	if not is_instance_valid(panel):
		return
	
	# Calculate aggregate HP
	var total_hp: int = 0
	var total_max_hp: int = 0
	for enemy in enemies:
		if enemy.is_alive():
			total_hp += enemy.current_hp
			total_max_hp += enemy.max_hp
	
	# Update HP fill
	var hp_fill: ColorRect = panel.get_node_or_null("HPFill")
	if hp_fill:
		var max_width: float = hp_fill.get_meta("max_width", hp_fill.size.x)
		var hp_percent: float = float(total_hp) / float(total_max_hp) if total_max_hp > 0 else 0.0
		hp_fill.size.x = max_width * hp_percent
		hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	
	# Update HP text
	var hp_text: Label = panel.get_node_or_null("HPText")
	if hp_text:
		hp_text.text = str(total_hp) + "/" + str(total_max_hp) + " total"

