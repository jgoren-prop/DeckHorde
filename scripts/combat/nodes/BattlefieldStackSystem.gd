extends Control
class_name BattlefieldStackSystem
## Manages enemy stacks/groups on the battlefield.
## Owns stack_visuals, handles grouping, expand/collapse, and mini-panel management.

signal stack_hover_entered(panel: Panel, stack_key: String)
signal stack_hover_exited(panel: Panel, stack_key: String)
signal mini_panel_hover_entered(panel: Panel, enemy, stack_key: String)
signal mini_panel_hover_exited(panel: Panel, stack_key: String)
signal stack_expanded(stack_key: String)
signal stack_collapsed(stack_key: String)

const EnemyStackPanelScene = preload("res://scenes/combat/components/EnemyStackPanel.tscn")
const MiniEnemyPanelScene = preload("res://scenes/combat/components/MiniEnemyPanel.tscn")
const BattlefieldEffectsHelper = preload("res://scripts/combat/BattlefieldEffects.gd")
const MINI_PANEL_SIZE: Vector2 = Vector2(55.0, 50.0)
const MINI_PANEL_VERTICAL_GAP: float = 16.0

# Lane system constants
const TOTAL_LANES: int = 12  # Fixed number of lane slots across the semicircle
const COLLISION_BUFFER: float = 12.0  # Pixel buffer between groups
const MAX_GROUPS_BEFORE_SCALE: int = 6  # Start scaling down after this many groups per ring
const MIN_SCALE: float = 0.7  # Minimum scale factor for crowded rings
const SCALE_REDUCTION_PER_GROUP: float = 0.05  # Scale reduction per extra group

# Z-index values per ring (Melee renders above Close, etc.)
const RING_Z_INDEX: Array[int] = [4, 3, 2, 1]  # Melee, Close, Mid, Far

# Enemy colors reference
const ENEMY_COLORS: Dictionary = {
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

# State
var stack_visuals: Dictionary = {}  # stack_key -> {panel, enemies, expanded, mini_panels}
var enemy_groups: Dictionary = {}  # group_id -> {ring, enemy_id, enemies}

# Position tracking
var _stack_base_positions: Dictionary = {}  # stack_key -> Vector2
var _stack_position_tweens: Dictionary = {}  # stack_key -> Tween
var _stack_scale_tweens: Dictionary = {}  # stack_key -> Tween
var _group_positions: Dictionary = {}  # group_id -> Vector2
var _group_angular_positions: Dictionary = {}  # group_id -> float (DEPRECATED - kept for compatibility)

# Lane system state
var _occupied_lanes: Dictionary = {}  # ring -> {lane_index: group_id}
var _group_lanes: Dictionary = {}  # group_id -> lane_index (persists across rings)

# Stack hold system
var _stack_hold_counts: Dictionary = {}  # stack_key -> int
var _stack_collapse_timers: Dictionary = {}  # stack_key -> Timer
const STACK_COLLAPSE_DELAY: float = 1.0

# Weapons phase tracking
var _in_weapons_phase: bool = false
var _weapons_phase_stacks: Array[String] = []

# Layout info (set by parent)
var arena_center: Vector2 = Vector2.ZERO
var arena_max_radius: float = 200.0
var ring_proportions: Array[float] = [0.18, 0.42, 0.68, 0.95]

# Group ID counter
var _next_group_id: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func get_enemy_color(enemy_id: String) -> Color:
	"""Get the color for an enemy type."""
	return ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))


func create_stack(ring: int, enemy_id: String, enemies: Array, stack_key: String = "") -> String:
	"""Create a stack visual for a group of enemies."""
	if enemies.is_empty():
		return ""
	
	if stack_key.is_empty():
		stack_key = _generate_stack_key(ring, enemy_id)
	
	var visual_size: Vector2 = _get_stack_visual_size()
	var color: Color = get_enemy_color(enemy_id)
	
	# Create stack panel
	var panel: Panel = EnemyStackPanelScene.instantiate()
	panel.setup(enemy_id, ring, enemies, color, stack_key, visual_size)
	
	# Connect signals
	panel.hover_entered.connect(_on_stack_hover_enter)
	panel.hover_exited.connect(_on_stack_hover_exit)
	
	add_child(panel)
	
	# Set z_index based on ring (Melee renders above Close, etc.)
	panel.z_index = _get_ring_z_index(ring)
	
	# Store stack data
	stack_visuals[stack_key] = {
		"panel": panel,
		"enemies": enemies.duplicate(),
		"expanded": false,
		"mini_panels": [],
		"ring": ring,
		"enemy_id": enemy_id
	}
	
	# Position the stack
	update_stack_position(stack_key)
	
	# Apply scale factor based on ring crowding
	apply_ring_scale(ring)
	
	return stack_key


func _get_ring_z_index(ring: int) -> int:
	"""Get the z_index for a given ring. Melee (0) is highest, Far (3) is lowest."""
	if ring >= 0 and ring < RING_Z_INDEX.size():
		return RING_Z_INDEX[ring]
	return 1  # Default to Far's z_index


func update_stack_position(stack_key: String, animate: bool = false) -> void:
	"""Update a stack's visual position."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var panel: Panel = stack_data.panel
	var ring: int = stack_data.ring
	
	var target_pos: Vector2 = _calculate_stack_position(ring, stack_key)
	_stack_base_positions[stack_key] = target_pos
	
	if animate and is_instance_valid(panel):
		_animate_stack_to_position(stack_key, panel, target_pos)
	elif is_instance_valid(panel):
		panel.position = target_pos
	
	# Check for collisions after positioning
	check_and_resolve_collisions(ring)


func update_stack_ring(stack_key: String, new_ring: int, animate: bool = true) -> void:
	"""Update the stored ring for a stack and move it to the new location."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	stack_data.ring = new_ring
	
	# Update z_index when ring changes
	var panel: Panel = stack_data.panel
	if is_instance_valid(panel):
		panel.z_index = _get_ring_z_index(new_ring)
	
	update_stack_position(stack_key, animate)
	
	if stack_data.get("expanded", false):
		_reposition_expanded_stack(stack_key)


func update_stack_hp(stack_key: String) -> void:
	"""Update HP display for a stack (aggregate HP bar)."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var panel: Panel = stack_data.panel
	
	if is_instance_valid(panel) and panel.has_method("update_aggregate_hp"):
		panel.update_aggregate_hp()


func get_stack_panel(stack_key: String) -> Panel:
	"""Get the panel for a stack."""
	if stack_visuals.has(stack_key):
		return stack_visuals[stack_key].panel
	return null


func get_stack_enemies(stack_key: String) -> Array:
	"""Get the enemies in a stack."""
	if stack_visuals.has(stack_key):
		return stack_visuals[stack_key].enemies
	return []


func has_stack(stack_key: String) -> bool:
	"""Check if a stack exists."""
	return stack_visuals.has(stack_key)


func is_stack_expanded(stack_key: String) -> bool:
	"""Check if a stack is expanded."""
	if stack_visuals.has(stack_key):
		return stack_visuals[stack_key].get("expanded", false)
	return false


func get_stack_key_for_enemy(enemy) -> String:
	"""Get the stack key for an enemy based on ring and type."""
	# Find which stack contains this enemy
	for key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[key]
		for stack_enemy in stack_data.enemies:
			if stack_enemy.instance_id == enemy.instance_id:
				return key
	return ""


func get_stack_center_position(stack_key: String) -> Vector2:
	"""Get the center position of a stack's visual."""
	if stack_visuals.has(stack_key):
		var panel: Panel = stack_visuals[stack_key].panel
		if is_instance_valid(panel):
			return panel.position + panel.size / 2
	return Vector2.ZERO


# ============== EXPAND/COLLAPSE ==============

func expand_stack(stack_key: String) -> void:
	"""Expand a stack to show individual mini-panels."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	if stack_data.expanded:
		return
	
	stack_data.expanded = true
	var panel: Panel = stack_data.panel
	var enemies: Array = stack_data.enemies
	
	if not is_instance_valid(panel):
		return
	
	# Calculate mini-panel positions
	var mini_size: Vector2 = MINI_PANEL_SIZE
	var layout: Dictionary = _calculate_mini_layout(panel, enemies.size(), mini_size)
	var start_x: float = layout.start_x
	var base_y: float = layout.base_y
	var spacing: float = layout.spacing
	
	# Create mini-panels
	for i: int in range(enemies.size()):
		var enemy = enemies[i]
		var color: Color = get_enemy_color(enemy.enemy_id)
		
		var mini_panel: Panel = MiniEnemyPanelScene.instantiate()
		mini_panel.setup(enemy, mini_size, color, stack_key)
		mini_panel.position = Vector2(start_x + i * spacing, base_y)
		mini_panel.modulate.a = 0.0
		mini_panel.scale = Vector2(0.5, 0.5)
		
		# Connect signals
		mini_panel.hover_entered.connect(_on_mini_panel_hover_enter)
		mini_panel.hover_exited.connect(_on_mini_panel_hover_exit)
		
		add_child(mini_panel)
		stack_data.mini_panels.append(mini_panel)
		
		# Animate in
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(mini_panel, "modulate:a", 1.0, 0.15).set_delay(i * 0.03)
		tween.tween_property(mini_panel, "scale", Vector2.ONE, 0.15).set_delay(i * 0.03).set_ease(Tween.EASE_OUT)
	
	_reposition_expanded_stack(stack_key)
	
	stack_expanded.emit(stack_key)


func collapse_stack(stack_key: String) -> void:
	"""Collapse a stack, hiding mini-panels."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	if not stack_data.expanded:
		return
	
	# Check holds
	if _stack_hold_counts.get(stack_key, 0) > 0:
		return
	
	stack_data.expanded = false
	
	# Animate out and remove mini-panels
	var mini_panels: Array = stack_data.mini_panels
	for i: int in range(mini_panels.size() - 1, -1, -1):
		var mini_panel = mini_panels[i]
		if is_instance_valid(mini_panel):
			var reverse_idx: int = mini_panels.size() - 1 - i
			var tween: Tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(mini_panel, "modulate:a", 0.0, 0.1).set_delay(reverse_idx * 0.02)
			tween.tween_property(mini_panel, "scale", Vector2(0.5, 0.5), 0.1).set_delay(reverse_idx * 0.02)
			tween.set_parallel(false)
			tween.tween_callback(mini_panel.queue_free)
	
	stack_data.mini_panels.clear()
	stack_collapsed.emit(stack_key)


func hold_stack_open(stack_key: String) -> void:
	"""Hold a stack open (prevent collapse)."""
	_stack_hold_counts[stack_key] = _stack_hold_counts.get(stack_key, 0) + 1
	
	# Cancel any pending collapse
	if _stack_collapse_timers.has(stack_key):
		_stack_collapse_timers[stack_key].queue_free()
		_stack_collapse_timers.erase(stack_key)
	
	# Expand if not already
	if stack_visuals.has(stack_key) and not stack_visuals[stack_key].expanded:
		expand_stack(stack_key)


func release_stack_hold(stack_key: String) -> void:
	"""Release a hold on a stack."""
	if _stack_hold_counts.has(stack_key):
		_stack_hold_counts[stack_key] = max(0, _stack_hold_counts[stack_key] - 1)
		
		if _stack_hold_counts[stack_key] == 0:
			# Schedule collapse
			var timer: Timer = Timer.new()
			timer.wait_time = STACK_COLLAPSE_DELAY
			timer.one_shot = true
			timer.timeout.connect(func():
				_stack_collapse_timers.erase(stack_key)
				collapse_stack(stack_key)
				timer.queue_free()
			)
			add_child(timer)
			timer.start()
			_stack_collapse_timers[stack_key] = timer


func set_weapons_phase(active: bool) -> void:
	"""Set whether we're in weapons phase (keeps stacks open)."""
	_in_weapons_phase = active
	if not active:
		_weapons_phase_stacks.clear()


# ============== SHAKE/FLASH ==============

func shake_stack(stack_key: String, intensity: float = 8.0, duration: float = 0.25) -> void:
	"""Shake a stack panel."""
	if not stack_visuals.has(stack_key):
		return
	
	var panel: Panel = stack_visuals[stack_key].panel
	if not is_instance_valid(panel):
		return
	
	var base_pos: Vector2 = _stack_base_positions.get(stack_key, panel.position)
	
	# Kill existing tween
	if _stack_position_tweens.has(stack_key):
		var old_tween: Tween = _stack_position_tweens[stack_key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	panel.position = base_pos
	
	var tween: Tween = create_tween()
	var shake_count: int = 4
	var step_time: float = duration / float(shake_count + 1)
	for i: int in range(shake_count):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(panel, "position", base_pos + offset, step_time)
	tween.tween_property(panel, "position", base_pos, step_time)
	
	_stack_position_tweens[stack_key] = tween


func flash_stack(stack_key: String, color: Color = Color(1.5, 0.4, 0.4, 1.0), duration: float = 0.15) -> void:
	"""Flash a stack panel."""
	if not stack_visuals.has(stack_key):
		return
	
	var panel: Panel = stack_visuals[stack_key].panel
	if not is_instance_valid(panel):
		return
	
	var tween: Tween = panel.create_tween()
	tween.tween_property(panel, "modulate", color, duration * 0.4)
	tween.tween_property(panel, "modulate", Color.WHITE, duration * 0.6)


# ============== CLEANUP ==============

func remove_stack(stack_key: String) -> void:
	"""Remove a stack and its visuals."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var ring: int = stack_data.get("ring", -1)
	
	# Release lane occupation
	var group_id: String = _extract_group_id_from_stack_key(stack_key)
	if ring >= 0:
		release_lane(group_id, ring)
	
	# Emit exit signal so hover system can clean up if this stack was being hovered
	if is_instance_valid(stack_data.panel):
		stack_hover_exited.emit(stack_data.panel, stack_key)
	
	# Kill tweens
	_kill_stack_tweens(stack_key)
	
	# Remove mini-panels
	for mini_panel in stack_data.mini_panels:
		if is_instance_valid(mini_panel):
			mini_panel.queue_free()
	
	# Remove main panel
	if is_instance_valid(stack_data.panel):
		stack_data.panel.queue_free()
	
	stack_visuals.erase(stack_key)
	_stack_base_positions.erase(stack_key)
	
	# Update scales for remaining stacks in the ring
	if ring >= 0:
		apply_ring_scale(ring)


func clear_all() -> void:
	"""Clear all stacks."""
	for stack_key: String in stack_visuals.keys():
		remove_stack(stack_key)
	stack_visuals.clear()
	enemy_groups.clear()
	_stack_base_positions.clear()
	_group_positions.clear()
	_group_angular_positions.clear()
	_occupied_lanes.clear()
	_group_lanes.clear()


# ============== PRIVATE METHODS ==============

func _get_stack_visual_size() -> Vector2:
	"""Get the standard size for stack visuals."""
	return Vector2(110, 120)


func _generate_stack_key(ring: int, enemy_id: String) -> String:
	"""Generate a unique stack key."""
	_next_group_id += 1
	return str(ring) + "_" + enemy_id + "_group_" + str(_next_group_id)


func _calculate_stack_position(ring: int, stack_key: String) -> Vector2:
	"""Calculate position for a stack based on ring and lane."""
	var outer_radius: float = arena_max_radius * ring_proportions[ring]
	var inner_radius: float = 0.0
	if ring > 0:
		inner_radius = arena_max_radius * ring_proportions[ring - 1]
	# Position at 35% from inner to outer edge (clearly inside the ring, not at center)
	var ring_radius: float = inner_radius + (outer_radius - inner_radius) * 0.35
	
	# Extract group_id from stack_key and get lane-based angle
	var group_id: String = _extract_group_id_from_stack_key(stack_key)
	@warning_ignore("integer_division")
	var lane: int = _group_lanes.get(group_id, TOTAL_LANES / 2)  # Default to center lane
	var angle: float = _lane_to_angle(lane)
	
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * ring_radius
	var visual_size: Vector2 = _get_stack_visual_size()
	
	return arena_center + offset - visual_size / 2


func _lane_to_angle(lane: int) -> float:
	"""Convert a lane index (0-11) to an angle on the semicircle.
	Lane 0 = PI (far left), Lane 11 = 2*PI (far right), center lanes near top."""
	# Clamp lane to valid range
	lane = clampi(lane, 0, TOTAL_LANES - 1)
	# Map lane index to angle: PI (left) to 2*PI (right)
	return PI + (float(lane) / float(TOTAL_LANES - 1)) * PI


func _angle_to_lane(angle: float) -> int:
	"""Convert an angle to the nearest lane index."""
	# Normalize angle to PI to 2*PI range
	while angle < PI:
		angle += TAU
	while angle > TAU:
		angle -= TAU
	# Map angle to lane: PI -> 0, 2*PI -> TOTAL_LANES-1
	var normalized: float = (angle - PI) / PI
	return clampi(roundi(normalized * float(TOTAL_LANES - 1)), 0, TOTAL_LANES - 1)


# ============== LANE ASSIGNMENT ==============

func assign_random_lane(ring: int, group_id: String) -> int:
	"""Assign a random available lane to a group. Returns the assigned lane index."""
	var available: Array[int] = get_available_lanes(ring)
	
	var lane: int
	if available.is_empty():
		# All lanes occupied - find the least crowded lane or reuse
		lane = _find_least_crowded_lane(ring)
	else:
		# Pick a random available lane
		lane = available[randi() % available.size()]
	
	set_group_lane(group_id, lane, ring)
	return lane


func get_available_lanes(ring: int) -> Array[int]:
	"""Get list of unoccupied lanes for a ring."""
	var available: Array[int] = []
	var occupied: Dictionary = _occupied_lanes.get(ring, {})
	
	for lane: int in range(TOTAL_LANES):
		if not occupied.has(lane):
			available.append(lane)
	
	return available


func set_group_lane(group_id: String, lane: int, ring: int) -> void:
	"""Set a group's lane and mark it as occupied in the specified ring."""
	# Store lane for group (persists across ring changes)
	_group_lanes[group_id] = lane
	
	# Initialize ring's occupied lanes if needed
	if not _occupied_lanes.has(ring):
		_occupied_lanes[ring] = {}
	
	# Mark lane as occupied by this group
	_occupied_lanes[ring][lane] = group_id
	
	# Also store as angular position for legacy compatibility
	_group_angular_positions[group_id] = _lane_to_angle(lane)


func get_group_lane(group_id: String) -> int:
	"""Get the lane assigned to a group. Returns center lane if not assigned."""
	@warning_ignore("integer_division")
	return _group_lanes.get(group_id, TOTAL_LANES / 2)


func release_lane(group_id: String, ring: int) -> void:
	"""Release a lane when a group is removed or moves to another ring."""
	if not _occupied_lanes.has(ring):
		return
	
	var lane: int = _group_lanes.get(group_id, -1)
	if lane >= 0 and _occupied_lanes[ring].has(lane):
		# Only release if this group owns the lane
		if _occupied_lanes[ring][lane] == group_id:
			_occupied_lanes[ring].erase(lane)


func _find_least_crowded_lane(_ring: int) -> int:
	"""Find a lane to use when all lanes are occupied. Returns center-ish lane."""
	# When overcrowded, prefer center lanes as they have more visual space
	@warning_ignore("integer_division")
	var center: int = TOTAL_LANES / 2
	# Try lanes outward from center
	for offset: int in range(TOTAL_LANES):
		var lane1: int = center + offset
		var lane2: int = center - offset
		if lane1 < TOTAL_LANES:
			return lane1
		if lane2 >= 0:
			return lane2
	return center


func get_groups_in_ring(ring: int) -> int:
	"""Get the count of groups currently in a ring."""
	if not _occupied_lanes.has(ring):
		return 0
	return _occupied_lanes[ring].size()


# ============== COLLISION DETECTION ==============

func check_and_resolve_collisions(ring: int) -> void:
	"""Check for collisions between stacks in a ring and apply offsets if needed."""
	var stacks_in_ring: Array[String] = _get_stacks_in_ring(ring)
	if stacks_in_ring.size() < 2:
		return
	
	# Sort stacks by their lane (left to right)
	stacks_in_ring.sort_custom(func(a: String, b: String) -> bool:
		var lane_a: int = _get_stack_lane(a)
		var lane_b: int = _get_stack_lane(b)
		return lane_a < lane_b
	)
	
	# Check adjacent stacks for overlap
	for i: int in range(stacks_in_ring.size() - 1):
		var key_a: String = stacks_in_ring[i]
		var key_b: String = stacks_in_ring[i + 1]
		
		if not stack_visuals.has(key_a) or not stack_visuals.has(key_b):
			continue
		
		var panel_a: Panel = stack_visuals[key_a].panel
		var panel_b: Panel = stack_visuals[key_b].panel
		
		if not is_instance_valid(panel_a) or not is_instance_valid(panel_b):
			continue
		
		# Check if panels overlap horizontally (including buffer)
		var right_edge_a: float = panel_a.position.x + panel_a.size.x + COLLISION_BUFFER
		var left_edge_b: float = panel_b.position.x
		
		if right_edge_a > left_edge_b:
			# Collision detected - nudge panels apart
			var overlap: float = right_edge_a - left_edge_b
			var half_offset: float = overlap / 2.0
			panel_a.position.x -= half_offset
			panel_b.position.x += half_offset
			
			# Update base positions
			_stack_base_positions[key_a] = panel_a.position
			_stack_base_positions[key_b] = panel_b.position


func _get_stacks_in_ring(ring: int) -> Array[String]:
	"""Get all stack keys for a given ring."""
	var result: Array[String] = []
	for key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[key]
		if stack_data.get("ring", -1) == ring:
			result.append(key)
	return result


func _get_stack_lane(stack_key: String) -> int:
	"""Get the lane index for a stack."""
	var group_id: String = _extract_group_id_from_stack_key(stack_key)
	@warning_ignore("integer_division")
	return _group_lanes.get(group_id, TOTAL_LANES / 2)


func has_collision(ring: int, lane: int, exclude_group: String = "") -> bool:
	"""Check if a lane in a ring would cause a collision."""
	if not _occupied_lanes.has(ring):
		return false
	
	# Lane is occupied by another group
	if _occupied_lanes[ring].has(lane):
		var occupant: String = _occupied_lanes[ring][lane]
		if occupant != exclude_group:
			return true
	
	return false


# ============== SIZE CLAMPING ==============

func get_scale_factor_for_ring(ring: int) -> float:
	"""Calculate scale factor for stacks in a ring based on crowding.
	When many groups exist, scale down to avoid visual clutter."""
	var group_count: int = get_groups_in_ring(ring)
	
	if group_count <= MAX_GROUPS_BEFORE_SCALE:
		return 1.0
	
	# Scale down for each extra group beyond threshold
	var extra_groups: int = group_count - MAX_GROUPS_BEFORE_SCALE
	var scale_factor: float = 1.0 - (float(extra_groups) * SCALE_REDUCTION_PER_GROUP)
	
	return maxf(scale_factor, MIN_SCALE)


func apply_ring_scale(ring: int) -> void:
	"""Apply appropriate scale to all stacks in a ring based on crowding."""
	var scale_factor: float = get_scale_factor_for_ring(ring)
	var stacks: Array[String] = _get_stacks_in_ring(ring)
	
	for stack_key: String in stacks:
		if not stack_visuals.has(stack_key):
			continue
		
		var panel: Panel = stack_visuals[stack_key].panel
		if is_instance_valid(panel):
			# Animate scale change for smooth transition
			if _stack_scale_tweens.has(stack_key):
				var old_tween: Tween = _stack_scale_tweens[stack_key]
				if old_tween and old_tween.is_valid():
					old_tween.kill()
			
			var tween: Tween = create_tween()
			tween.tween_property(panel, "scale", Vector2(scale_factor, scale_factor), 0.2).set_ease(Tween.EASE_OUT)
			_stack_scale_tweens[stack_key] = tween


func update_all_ring_scales() -> void:
	"""Update scale factors for all rings."""
	for ring: int in range(4):
		apply_ring_scale(ring)


func _extract_group_id_from_stack_key(stack_key: String) -> String:
	"""Extract group_id from stack_key. Format: 'ring_enemytype_group_X' -> 'group_X'"""
	# Find the last occurrence of "group_" and return from there
	var group_idx: int = stack_key.rfind("group_")
	if group_idx >= 0:
		return stack_key.substr(group_idx)
	return stack_key  # Fallback to full key if no group_ found


func set_group_angular_position(group_id: String, angle: float) -> void:
	"""Set the angular position for a group. Persists across ring changes."""
	_group_angular_positions[group_id] = angle


func get_group_angular_position(group_id: String) -> float:
	"""Get the angular position for a group."""
	return _group_angular_positions.get(group_id, PI * 1.5)


func _animate_stack_to_position(stack_key: String, panel: Panel, target_pos: Vector2) -> void:
	"""Animate a stack to a new position."""
	if _stack_position_tweens.has(stack_key):
		var old_tween: Tween = _stack_position_tweens[stack_key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	var tween: Tween = create_tween()
	tween.tween_property(panel, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_stack_position_tweens[stack_key] = tween


func _calculate_mini_layout(panel: Panel, count: int, mini_size: Vector2) -> Dictionary:
	"""Calculate layout values for expanded mini-panels."""
	var spacing: float = mini_size.x + 6.0
	var total_width: float = 0.0
	if count > 0:
		total_width = spacing * count - 6.0
	var start_x: float = panel.position.x + panel.size.x / 2.0 - total_width / 2.0
	var base_y: float = max(panel.position.y - mini_size.y - MINI_PANEL_VERTICAL_GAP, 0.0)
	return {
		"start_x": start_x,
		"base_y": base_y,
		"spacing": spacing
	}


func _reposition_expanded_stack(stack_key: String) -> void:
	"""Reposition mini-panels for an already expanded stack."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var panel: Panel = stack_data.panel
	if not is_instance_valid(panel):
		return
	
	var mini_panels: Array = stack_data.get("mini_panels", [])
	if mini_panels.is_empty():
		return
	
	var mini_size: Vector2 = MINI_PANEL_SIZE
	var layout: Dictionary = _calculate_mini_layout(panel, mini_panels.size(), mini_size)
	var start_x: float = layout.start_x
	var base_y: float = layout.base_y
	var spacing: float = layout.spacing
	
	for i: int in range(mini_panels.size()):
		var mini_panel: Panel = mini_panels[i]
		if is_instance_valid(mini_panel):
			mini_panel.position = Vector2(start_x + i * spacing, base_y)


func _kill_stack_tweens(stack_key: String) -> void:
	"""Kill all tweens for a stack."""
	if _stack_position_tweens.has(stack_key):
		var tween: Tween = _stack_position_tweens[stack_key]
		if tween and tween.is_valid():
			tween.kill()
		_stack_position_tweens.erase(stack_key)
	
	if _stack_scale_tweens.has(stack_key):
		var tween: Tween = _stack_scale_tweens[stack_key]
		if tween and tween.is_valid():
			tween.kill()
		_stack_scale_tweens.erase(stack_key)


func _on_stack_hover_enter(panel: Panel, stack_key: String) -> void:
	"""Handle stack hover enter."""
	stack_hover_entered.emit(panel, stack_key)
	expand_stack(stack_key)


func _on_stack_hover_exit(panel: Panel, stack_key: String) -> void:
	"""Handle stack hover exit."""
	stack_hover_exited.emit(panel, stack_key)
	# Schedule collapse after delay (0.1s to match info card hide for snappy feel)
	if not _in_weapons_phase:
		var timer: SceneTreeTimer = get_tree().create_timer(0.1)
		timer.timeout.connect(func():
			if stack_visuals.has(stack_key) and stack_visuals[stack_key].expanded:
				collapse_stack(stack_key)
		)


func _on_mini_panel_hover_enter(panel: Panel, enemy, stack_key: String) -> void:
	"""Handle mini-panel hover enter."""
	mini_panel_hover_entered.emit(panel, enemy, stack_key)


func _on_mini_panel_hover_exit(panel: Panel, stack_key: String) -> void:
	"""Handle mini-panel hover exit."""
	mini_panel_hover_exited.emit(panel, stack_key)

