extends Control
class_name BattlefieldStackSystem
## Manages enemy stacks/groups on the battlefield.
## Owns stack_visuals, handles grouping, expand/collapse, and mini-panel management.
## V2: Horizontal lane layout - enemies spread horizontally within lanes.

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

# Lane system constants - horizontal slots across each lane
const TOTAL_SLOTS: int = 12  # Fixed number of horizontal slots per lane
const COLLISION_BUFFER: float = 8.0  # Pixel buffer between groups
const MAX_GROUPS_BEFORE_SCALE: int = 8  # Start scaling down after this many groups per ring
const MIN_SCALE: float = 0.5  # Minimum scale factor for crowded rings
const SCALE_REDUCTION_PER_GROUP: float = 0.06  # Scale reduction per extra group

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
	"weakling": Color(0.5, 0.5, 0.5),
	"mite": Color(0.45, 0.35, 0.3),
	"swarmling": Color(0.55, 0.4, 0.35),
	"drone": Color(0.4, 0.4, 0.45)
}

# State
var stack_visuals: Dictionary = {}  # stack_key -> {panel, enemies, expanded, mini_panels}
var enemy_groups: Dictionary = {}  # group_id -> {ring, enemy_id, enemies}

# Position tracking
var _stack_base_positions: Dictionary = {}  # stack_key -> Vector2
var _stack_position_tweens: Dictionary = {}  # stack_key -> Tween
var _stack_scale_tweens: Dictionary = {}  # stack_key -> Tween
var _group_positions: Dictionary = {}  # group_id -> Vector2
var _group_slots: Dictionary = {}  # group_id -> slot_index (horizontal position)

# Lane system state
var _occupied_slots: Dictionary = {}  # ring -> {slot_index: group_id}
var _group_lanes: Dictionary = {}  # group_id -> slot_index (persists across rings)

# Stack hold system
var _stack_hold_counts: Dictionary = {}  # stack_key -> int
var _stack_collapse_timers: Dictionary = {}  # stack_key -> Timer
const STACK_COLLAPSE_DELAY: float = 1.0

# Weapons phase tracking
var _in_weapons_phase: bool = false
var _weapons_phase_stacks: Array[String] = []

# Layout info (set by parent) - V2 uses lane rectangles
var arena_center: Vector2 = Vector2.ZERO  # Kept for compatibility
var arena_max_radius: float = 200.0  # Kept for compatibility
var lane_rects: Array[Rect2] = []  # Lane rectangles [MELEE, CLOSE, MID, FAR]
var arena_padding: float = 10.0

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
	"""Get the GLOBAL center position of a stack's visual."""
	if stack_visuals.has(stack_key):
		var panel: Panel = stack_visuals[stack_key].panel
		if is_instance_valid(panel):
			return panel.global_position + panel.size / 2
	return Vector2.ZERO


func get_enemy_mini_panel_position(enemy) -> Vector2:
	"""Get the GLOBAL center position of an enemy's mini-panel if stack is expanded.
	Returns Vector2.ZERO if no mini-panel exists (stack not expanded or enemy not found)."""
	var stack_key: String = get_stack_key_for_enemy(enemy)
	if stack_key.is_empty() or not stack_visuals.has(stack_key):
		return Vector2.ZERO
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	
	# Only return mini-panel position if stack is expanded
	if not stack_data.get("expanded", false):
		return Vector2.ZERO
	
	var mini_panels: Array = stack_data.get("mini_panels", [])
	
	for mini_panel in mini_panels:
		if is_instance_valid(mini_panel):
			var panel_enemy = mini_panel.get_meta("enemy_instance", null)
			if panel_enemy and panel_enemy.instance_id == enemy.instance_id:
				return mini_panel.global_position + mini_panel.size / 2
	
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
		# Setup FIRST - metadata is set synchronously before await
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
	_group_slots.clear()
	_occupied_slots.clear()
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
	"""Calculate position for a stack based on ring and horizontal slot.
	V2: Uses horizontal positioning within lane rectangles."""
	# Get lane rectangle for this ring
	var lane_rect: Rect2 = _get_lane_rect_for_ring(ring)
	
	# Extract group_id from stack_key and get slot position
	var group_id: String = _extract_group_id_from_stack_key(stack_key)
	@warning_ignore("integer_division")
	var slot: int = _group_lanes.get(group_id, TOTAL_SLOTS / 2)  # Default to center slot
	
	# Convert slot to X position within the lane
	var x_pos: float = _slot_to_x_position(slot, lane_rect)
	
	# Y position is centered in the lane, offset by visual size
	var visual_size: Vector2 = _get_stack_visual_size()
	var y_pos: float = lane_rect.get_center().y - visual_size.y / 2
	
	return Vector2(x_pos - visual_size.x / 2, y_pos)


func _get_lane_rect_for_ring(ring: int) -> Rect2:
	"""Get the lane rectangle for a ring. Falls back to calculation if not set."""
	if ring >= 0 and ring < lane_rects.size():
		return lane_rects[ring]
	
	# Fallback calculation based on size
	var padding: float = arena_padding
	var drawable_width: float = size.x - padding * 2
	var drawable_height: float = size.y - padding * 2
	var warden_height: float = 45.0
	var lanes_height: float = drawable_height - warden_height
	var lane_height: float = lanes_height / 4.0
	
	# Ring 3 (FAR) at top, Ring 0 (MELEE) at bottom
	var y_pos: float = padding + (3 - ring) * lane_height
	
	return Rect2(Vector2(padding, y_pos), Vector2(drawable_width, lane_height))


func _slot_to_x_position(slot: int, lane_rect: Rect2) -> float:
	"""Convert a slot index (0-11) to an X position within the lane.
	Slot 0 = left edge, Slot 11 = right edge."""
	slot = clampi(slot, 0, TOTAL_SLOTS - 1)
	var usable_width: float = lane_rect.size.x - 40  # Padding on edges
	var x_start: float = lane_rect.position.x + 20
	return x_start + (float(slot) / float(TOTAL_SLOTS - 1)) * usable_width


func _x_position_to_slot(x_pos: float, lane_rect: Rect2) -> int:
	"""Convert an X position to the nearest slot index."""
	var usable_width: float = lane_rect.size.x - 40
	var x_start: float = lane_rect.position.x + 20
	var normalized: float = (x_pos - x_start) / usable_width
	return clampi(roundi(normalized * float(TOTAL_SLOTS - 1)), 0, TOTAL_SLOTS - 1)


# ============== SLOT ASSIGNMENT ==============

func assign_random_lane(ring: int, group_id: String) -> int:
	"""Assign a random available slot to a group. Returns the assigned slot index."""
	var available: Array[int] = get_available_slots(ring)
	
	var slot: int
	if available.is_empty():
		# All slots occupied - find the least crowded slot or reuse
		slot = _find_least_crowded_slot(ring)
	else:
		# Pick a random available slot
		slot = available[randi() % available.size()]
	
	set_group_slot(group_id, slot, ring)
	return slot


func get_available_slots(ring: int) -> Array[int]:
	"""Get list of unoccupied slots for a ring."""
	var available: Array[int] = []
	var occupied: Dictionary = _occupied_slots.get(ring, {})
	
	for slot: int in range(TOTAL_SLOTS):
		if not occupied.has(slot):
			available.append(slot)
	
	return available


func get_available_lanes(ring: int) -> Array[int]:
	"""Alias for get_available_slots for backward compatibility."""
	return get_available_slots(ring)


func set_group_slot(group_id: String, slot: int, ring: int) -> void:
	"""Set a group's slot and mark it as occupied in the specified ring."""
	# Store slot for group (persists across ring changes)
	_group_lanes[group_id] = slot
	_group_slots[group_id] = slot
	
	# Initialize ring's occupied slots if needed
	if not _occupied_slots.has(ring):
		_occupied_slots[ring] = {}
	
	# Mark slot as occupied by this group
	_occupied_slots[ring][slot] = group_id


func set_group_lane(group_id: String, lane: int, ring: int) -> void:
	"""Alias for set_group_slot for backward compatibility."""
	set_group_slot(group_id, lane, ring)


func get_group_lane(group_id: String) -> int:
	"""Get the slot assigned to a group. Returns center slot if not assigned."""
	@warning_ignore("integer_division")
	return _group_lanes.get(group_id, TOTAL_SLOTS / 2)


func release_lane(group_id: String, ring: int) -> void:
	"""Release a slot when a group is removed or moves to another ring."""
	if not _occupied_slots.has(ring):
		return
	
	var slot: int = _group_lanes.get(group_id, -1)
	if slot >= 0 and _occupied_slots[ring].has(slot):
		# Only release if this group owns the slot
		if _occupied_slots[ring][slot] == group_id:
			_occupied_slots[ring].erase(slot)


func _find_least_crowded_slot(_ring: int) -> int:
	"""Find a slot to use when all slots are occupied. Returns center-ish slot."""
	# When overcrowded, prefer center slots as they have more visual space
	@warning_ignore("integer_division")
	var center: int = TOTAL_SLOTS / 2
	# Try slots outward from center
	for offset: int in range(TOTAL_SLOTS):
		var slot1: int = center + offset
		var slot2: int = center - offset
		if slot1 < TOTAL_SLOTS:
			return slot1
		if slot2 >= 0:
			return slot2
	return center


func get_groups_in_ring(ring: int) -> int:
	"""Get the count of groups currently in a ring."""
	if not _occupied_slots.has(ring):
		return 0
	return _occupied_slots[ring].size()


# ============== COLLISION DETECTION ==============

func check_and_resolve_collisions(ring: int) -> void:
	"""Check for collisions between stacks in a ring and apply offsets if needed.
	V2: Uses horizontal X positions for collision detection."""
	var stacks_in_ring: Array[String] = _get_stacks_in_ring(ring)
	if stacks_in_ring.size() < 2:
		return
	
	# Sort stacks by their X position (left to right)
	stacks_in_ring.sort_custom(func(a: String, b: String) -> bool:
		var pos_a: Vector2 = _stack_base_positions.get(a, Vector2.ZERO)
		var pos_b: Vector2 = _stack_base_positions.get(b, Vector2.ZERO)
		return pos_a.x < pos_b.x
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
		var right_edge_a: float = panel_a.position.x + panel_a.size.x * panel_a.scale.x + COLLISION_BUFFER
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


func _get_stack_slot(stack_key: String) -> int:
	"""Get the slot index for a stack."""
	var group_id: String = _extract_group_id_from_stack_key(stack_key)
	@warning_ignore("integer_division")
	return _group_lanes.get(group_id, TOTAL_SLOTS / 2)


func _get_stack_lane(stack_key: String) -> int:
	"""Alias for _get_stack_slot for backward compatibility."""
	return _get_stack_slot(stack_key)


func has_collision(ring: int, slot: int, exclude_group: String = "") -> bool:
	"""Check if a slot in a ring would cause a collision."""
	if not _occupied_slots.has(ring):
		return false
	
	# Slot is occupied by another group
	if _occupied_slots[ring].has(slot):
		var occupant: String = _occupied_slots[ring][slot]
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


func set_group_angular_position(group_id: String, _angle: float) -> void:
	"""DEPRECATED: V2 uses horizontal slots. This converts angle to slot for compatibility."""
	# Convert angle to slot: PI (left) = 0, 2*PI (right) = TOTAL_SLOTS-1
	var normalized: float = (_angle - PI) / PI
	var slot: int = clampi(roundi(normalized * float(TOTAL_SLOTS - 1)), 0, TOTAL_SLOTS - 1)
	_group_slots[group_id] = slot
	_group_lanes[group_id] = slot


func get_group_angular_position(group_id: String) -> float:
	"""DEPRECATED: V2 uses horizontal slots. Returns a fake angle for compatibility."""
	# Convert slot back to angle for legacy code
	@warning_ignore("integer_division")
	var slot: int = _group_slots.get(group_id, TOTAL_SLOTS / 2)
	return PI + (float(slot) / float(TOTAL_SLOTS - 1)) * PI


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

