extends Control
## BattlefieldArena - Orchestrator for the battlefield visualization.
## V2: Horizontal lane layout - enemies march from top (FAR) to bottom (MELEE).
## Delegates to child nodes for specific functionality:
## - BattlefieldRings: Lane drawing and threat visualization
## - BattlefieldEnemyManager: Individual enemy panels
## - BattlefieldStackSystem: Enemy stacking and groups
## - BattlefieldEffectsNode: Projectiles, damage numbers, effects
## - BattlefieldHoverSystem: Hover states and info cards
## - BattlefieldBanners: Event callout banners

const BattlefieldBannersClass = preload("res://scripts/combat/BattlefieldBanners.gd")
const BattlefieldTargetingHintsClass = preload("res://scripts/combat/BattlefieldTargetingHints.gd")
const BattlefieldDangerSystemClass = preload("res://scripts/combat/BattlefieldDangerSystem.gd")

# Child node references (use Control type to avoid class_name resolution issues)
@onready var rings: Control = $BattlefieldRings
@onready var enemy_manager: Control = $BattlefieldEnemyManager
@onready var stack_system: Control = $BattlefieldStackSystem
@onready var effects_node: Control = $BattlefieldEffectsNode
@onready var hover_system: Control = $BattlefieldHoverSystem

# Non-node managers (for complex calculations)
var banner_manager  # BattlefieldBanners
var targeting_hints  # BattlefieldTargetingHints
var danger_system  # BattlefieldDangerSystem

# Reference to sibling CombatLane
var combat_lane: Control = null

# Group tracking for enemy placement
var enemy_groups: Dictionary = {}  # group_id -> {ring, enemy_id, enemies, angular_position}
var _next_group_id: int = 0

# Projectile tracking - enemies with projectiles in flight get deferred damage visuals
var _enemies_with_pending_projectile: Dictionary = {}  # instance_id -> {damage, is_hex}
var _pending_damage_visuals: Dictionary = {}  # instance_id -> {damage, is_hex}

# Layout
var center: Vector2 = Vector2.ZERO
var max_radius: float = 200.0

# Stacking config
const STACK_THRESHOLD: int = 2


func _ready() -> void:
	# Initialize non-node managers
	banner_manager = BattlefieldBannersClass.new()
	banner_manager.setup(self)
	targeting_hints = BattlefieldTargetingHintsClass.new()
	danger_system = BattlefieldDangerSystemClass.new()
	
	# Connect child signals
	_connect_child_signals()
	
	# Connect CombatManager signals
	_connect_combat_signals()
	
	# Get combat lane reference
	if get_parent():
		combat_lane = get_parent().get_node_or_null("CombatLane")
		if effects_node:
			effects_node.combat_lane = combat_lane
	
	# Initial layout
	call_deferred("_recalculate_layout")


func _connect_child_signals() -> void:
	"""Connect signals from child nodes."""
	if enemy_manager:
		enemy_manager.enemy_hover_entered.connect(_on_enemy_hover_entered)
		enemy_manager.enemy_hover_exited.connect(_on_enemy_hover_exited)
		enemy_manager.enemy_death_finished.connect(_on_enemy_death_finished)
	
	if stack_system:
		stack_system.stack_hover_entered.connect(_on_stack_hover_entered)
		stack_system.stack_hover_exited.connect(_on_stack_hover_exited)
		stack_system.mini_panel_hover_entered.connect(_on_mini_panel_hover_entered)
		stack_system.mini_panel_hover_exited.connect(_on_mini_panel_hover_exited)
	
	if effects_node:
		effects_node.projectile_hit_enemy.connect(_on_projectile_hit_enemy)


func _connect_combat_signals() -> void:
	"""Connect to CombatManager signals."""
	CombatManager.enemy_spawned.connect(_on_enemy_spawned)
	CombatManager.enemy_damaged.connect(_on_enemy_damaged)
	CombatManager.enemy_killed.connect(_on_enemy_died)
	CombatManager.enemy_moved.connect(_on_enemy_moved)
	CombatManager.enemy_targeted.connect(_on_enemy_targeted)
	CombatManager.enemy_hexed.connect(_on_enemy_hexed)
	CombatManager.player_damaged.connect(_on_player_damaged)
	CombatManager.barrier_placed.connect(_on_barrier_placed)
	CombatManager.barrier_triggered.connect(_on_barrier_triggered)
	CombatManager.barrier_consumed.connect(_on_barrier_consumed)
	CombatManager.turn_started.connect(_on_turn_started)
	CombatManager.execution_started.connect(_on_weapons_phase_started)
	CombatManager.execution_completed.connect(_on_weapons_phase_ended)


func _recalculate_layout() -> void:
	"""Recalculate battlefield layout based on size.
	V2: Horizontal lane layout - computes lane rectangles for child nodes."""
	const VERTICAL_PADDING: float = 10.0
	const HORIZONTAL_PADDING: float = 80.0  # Larger horizontal margin to reign in group spread
	const WARDEN_HEIGHT: float = 45.0
	
	# For horizontal layout, center is at the middle-bottom (warden area)
	center = Vector2(size.x / 2, size.y - WARDEN_HEIGHT / 2)
	max_radius = size.y / 2  # Kept for compatibility
	
	# Calculate lane rectangles [MELEE, CLOSE, MID, FAR]
	var drawable_width: float = size.x - HORIZONTAL_PADDING * 2
	var drawable_height: float = size.y - VERTICAL_PADDING * 2
	var lanes_height: float = drawable_height - WARDEN_HEIGHT
	var lane_height: float = lanes_height / 4.0
	
	var lane_rects: Array[Rect2] = []
	for ring: int in range(4):
		# Ring 3 (FAR) at top, Ring 0 (MELEE) at bottom
		var y_pos: float = VERTICAL_PADDING + (3 - ring) * lane_height
		lane_rects.append(Rect2(Vector2(HORIZONTAL_PADDING, y_pos), Vector2(drawable_width, lane_height)))
	
	# Update child nodes
	if rings:
		rings.arena_center = center
		rings.arena_max_radius = max_radius
		rings.recalculate_layout()
	
	if enemy_manager:
		enemy_manager.arena_center = center
		enemy_manager.arena_max_radius = max_radius
		enemy_manager.arena_padding = HORIZONTAL_PADDING
		enemy_manager.lane_rects = lane_rects
	
	if stack_system:
		stack_system.arena_center = center
		stack_system.arena_max_radius = max_radius
		stack_system.arena_padding = HORIZONTAL_PADDING
		stack_system.lane_rects = lane_rects
	
	if effects_node:
		effects_node.arena_center = center


# ============== PUBLIC API ==============

func refresh_display() -> void:
	"""Refresh the entire battlefield display."""
	_recalculate_layout()
	_refresh_all_visuals()


func get_enemy_visual(enemy) -> Panel:
	"""Get the visual for an enemy (individual or from stack)."""
	# Check individual first
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		return enemy_manager.get_enemy_visual(enemy.instance_id)
	
	# Check stacks
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			return stack_system.get_stack_panel(stack_key)
	
	return null


func get_enemy_center_position(enemy) -> Vector2:
	"""Get the GLOBAL center position of an enemy's visual.
	For stacked enemies, returns mini-panel position if expanded, otherwise stack center."""
	print("[TARGET DEBUG] get_enemy_center_position called for instance_id=", enemy.instance_id)
	
	# Check individual enemy visual first (not in a stack)
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		var pos: Vector2 = enemy_manager.get_enemy_center_position(enemy.instance_id)
		print("[TARGET DEBUG] -> Using individual enemy visual at: ", pos)
		return pos
	
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		print("[TARGET DEBUG] -> Enemy is in stack: '", stack_key, "'")
		if not stack_key.is_empty():
			# If stack is expanded, get the specific mini-panel position for this enemy
			var mini_pos: Vector2 = stack_system.get_enemy_mini_panel_position(enemy)
			print("[TARGET DEBUG] -> Mini-panel position: ", mini_pos)
			if mini_pos != Vector2.ZERO:
				return mini_pos
			# Fall back to stack center if not expanded or mini-panel not found
			var stack_center: Vector2 = stack_system.get_stack_center_position(stack_key)
			print("[TARGET DEBUG] -> FALLBACK to stack center: ", stack_center)
			return stack_center
	
	print("[TARGET DEBUG] -> FALLBACK to arena center: ", center)
	return center


func shake_enemy(enemy, intensity: float = 8.0, duration: float = 0.25) -> void:
	"""Shake an enemy visual."""
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.shake_enemy(enemy.instance_id, intensity, duration)
	elif stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			stack_system.shake_stack(stack_key, intensity, duration)


func flash_enemy(enemy, color: Color = Color(1.5, 0.4, 0.4, 1.0), duration: float = 0.15) -> void:
	"""Flash an enemy visual."""
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.flash_enemy(enemy.instance_id, color, duration)
	elif stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			stack_system.flash_stack(stack_key, color, duration)


func fire_projectile_to_enemy(enemy, color: Color = Color(1.0, 0.9, 0.3)) -> void:
	"""Fire a projectile at an enemy."""
	var to_pos: Vector2 = get_enemy_center_position(enemy)
	if effects_node:
		effects_node.fire_projectile_to_position(to_pos, color)


func show_damage_on_enemy(enemy, amount: int, is_hex: bool = false, offset: Vector2 = Vector2.ZERO) -> void:
	"""Show a damage number on an enemy.
	offset: Optional offset to stagger multiple simultaneous damage numbers."""
	# Add random spread so multiple damage numbers (from splash) don't overlap
	var random_spread: Vector2 = Vector2(randf_range(-20, 20), randf_range(-15, 15))
	var global_pos: Vector2 = get_enemy_center_position(enemy) - Vector2(15, 30) + offset + random_spread
	if effects_node:
		# Convert global position to local position for effects_node
		var local_pos: Vector2 = global_pos - effects_node.global_position
		effects_node.show_damage_number(local_pos, amount, is_hex)


func show_bomber_warning(enemy) -> void:
	"""Show bomber warning banner."""
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	if enemy_def and banner_manager:
		var explosion_damage: int = enemy_def.buff_amount if enemy_def.buff_amount > 0 else 5
		banner_manager.show_bomber_warning(enemy_def, explosion_damage)


func show_torchbearer_buff_banner(buff_amount: int) -> void:
	"""Show torchbearer buff banner."""
	if banner_manager:
		banner_manager.show_torchbearer_buff_banner(buff_amount)


func set_barrier(ring: int, damage: int, duration: int) -> void:
	"""Set a barrier on a ring."""
	if rings:
		rings.set_barrier(ring, damage, duration)


func clear_barrier(ring: int) -> void:
	"""Clear a barrier from a ring."""
	if rings:
		rings.clear_barrier(ring)


# ============== ENEMY MANAGEMENT ==============

func _create_or_update_enemy_visual(enemy) -> void:
	"""Create or update visual for an enemy, handling stacking."""
	var ring: int = enemy.ring
	var enemy_id: String = enemy.enemy_id
	
	# Find existing group for this enemy type in this ring
	var group_id: String = _find_or_create_group(ring, enemy_id, enemy)
	
	# Count enemies in this group
	var group_data: Dictionary = enemy_groups[group_id]
	var enemy_count: int = group_data.enemies.size()
	
	if enemy_count >= STACK_THRESHOLD:
		# Should be a stack
		var stack_key: String = str(group_data.ring) + "_" + group_data.enemy_id + "_" + group_id
		
		if stack_system and stack_system.has_stack(stack_key):
			# Update existing stack with new enemy count
			_update_stack_enemies(stack_key, group_data)
		else:
			# Create new stack - _ensure_stack_exists handles hiding all individual visuals
			_ensure_stack_exists(group_id, group_data)
	else:
		# Should be individual - calculate unique position for each enemy in the group
		if enemy_manager and not enemy_manager.has_enemy_visual(enemy.instance_id):
			var angular_pos: float = _calculate_intra_group_position(enemy, group_data)
			enemy_manager.set_enemy_angular_position(enemy.instance_id, angular_pos)
			enemy_manager.create_enemy_visual(enemy)


func _update_stack_enemies(stack_key: String, group_data: Dictionary) -> void:
	"""Update an existing stack's enemy list and visuals."""
	if not stack_system or not stack_system.stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_system.stack_visuals[stack_key]
	
	# Update the enemies array
	stack_data.enemies = group_data.enemies.duplicate()
	
	# Update the panel count display
	var panel: Panel = stack_data.panel
	if is_instance_valid(panel) and panel.has_method("update_count"):
		panel.update_count(group_data.enemies)
	
	# Hide any individual visuals for enemies in this group
	if enemy_manager:
		for e in group_data.enemies:
			if enemy_manager.has_enemy_visual(e.instance_id):
				enemy_manager.hide_enemy_visual(e.instance_id)


func _find_or_create_group(ring: int, enemy_id: String, enemy) -> String:
	"""Find an existing group or create a new one for an enemy.
	Groups are based on spawn_batch_id - enemies spawned together stay together.
	Groups NEVER merge, even when same enemy type ends up in the same ring."""
	var batch_id: int = enemy.spawn_batch_id
	
	# Look for existing group with same spawn_batch_id
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		if group.get("spawn_batch_id", -1) == batch_id and batch_id > 0:
			# Add to existing group if not already present
			var found: bool = false
			for e in group.enemies:
				if e.instance_id == enemy.instance_id:
					found = true
					break
			if not found:
				group.enemies.append(enemy)
				# Update ring if the group has moved (shouldn't happen but safety)
				group.ring = ring
			# Set the group_id on the enemy so it can be tracked
			enemy.group_id = group_id
			return group_id
	
	# Create new group with random lane assignment
	_next_group_id += 1
	var group_id: String = "group_" + str(_next_group_id)
	
	# Assign a random lane for this group (lane persists across ring changes)
	var assigned_lane: int = 6  # Default center lane
	if stack_system:
		assigned_lane = stack_system.assign_random_lane(ring, group_id)
	
	# Convert lane to angular position for legacy compatibility
	var angular_pos: float = PI + (float(assigned_lane) / float(11)) * PI  # Lane 0-11 maps to PI-2*PI
	
	enemy_groups[group_id] = {
		"ring": ring,
		"enemy_id": enemy_id,
		"enemies": [enemy],
		"angular_position": angular_pos,
		"lane": assigned_lane,
		"spawn_batch_id": batch_id  # Track batch ID for group matching
	}
	
	# Set the group_id on the enemy so it can be tracked
	enemy.group_id = group_id
	
	return group_id


func _calculate_angular_position_for_lane(lane: int) -> float:
	"""DEPRECATED for V2: Calculate a fake angular position for a given slot.
	Kept for backward compatibility with legacy code."""
	var total_slots: int = 12  # Match BattlefieldStackSystem.TOTAL_SLOTS
	return PI + (float(lane) / float(total_slots - 1)) * PI


func _ensure_stack_exists(group_id: String, group_data: Dictionary) -> void:
	"""Ensure a stack visual exists for a group."""
	var stack_key: String = str(group_data.ring) + "_" + group_data.enemy_id + "_" + group_id
	
	if stack_system and not stack_system.has_stack(stack_key):
		stack_system.create_stack(group_data.ring, group_data.enemy_id, group_data.enemies, stack_key)
		
		# Hide ALL individual visuals for enemies in this group (not just the current enemy)
		# This fixes the bug where enemies spawned before the stack threshold still show individually
		if enemy_manager:
			for e in group_data.enemies:
				if enemy_manager.has_enemy_visual(e.instance_id):
					enemy_manager.hide_enemy_visual(e.instance_id)


func _refresh_all_visuals() -> void:
	"""Refresh all enemy visuals."""
	# Clear hover state FIRST to prevent orphaned info cards
	if hover_system:
		hover_system.clear()
	
	# Clear existing
	if enemy_manager:
		enemy_manager.clear_all()
	if stack_system:
		stack_system.clear_all()
	
	enemy_groups.clear()
	
	# Recreate from current battlefield state
	for ring: int in range(4):
		var enemies: Array = CombatManager.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:
			_create_or_update_enemy_visual(enemy)
	
	_update_threat_levels()


func _update_threat_levels() -> void:
	"""Update threat level display for all rings."""
	if not rings:
		return
	
	for ring: int in range(4):
		var enemies: Array = CombatManager.battlefield.get_enemies_in_ring(ring)
		var total_damage: int = 0
		var has_bomber: bool = false
		
		for enemy in enemies:
			var enemy_def: EnemyDefinition = EnemyDatabase.get_enemy(enemy.enemy_id)
			if enemy_def == null:
				continue
			
			var predicted_attack: int = enemy.get_predicted_attack_damage(RunManager.current_wave, enemy_def)
			if predicted_attack > 0:
				total_damage += predicted_attack
			
			if enemy_def.behavior_type == EnemyDefinition.BehaviorType.BOMBER and ring == 0:
				has_bomber = true
		
		var threat_level: int = 0  # ThreatLevel.SAFE
		if total_damage > 0:
			if total_damage >= 20 or has_bomber:
				threat_level = 4  # CRITICAL
			elif total_damage >= 15:
				threat_level = 3  # HIGH
			elif total_damage >= 10:
				threat_level = 2  # MEDIUM
			else:
				threat_level = 1  # LOW
		
		rings.set_threat_level(ring, threat_level, total_damage, has_bomber)


# ============== SIGNAL HANDLERS ==============

func _on_enemy_spawned(enemy) -> void:
	"""Handle enemy spawn."""
	_create_or_update_enemy_visual(enemy)
	_update_threat_levels()


func _on_enemy_damaged(enemy, amount: int, is_hex) -> void:
	"""Handle enemy taking damage."""
	# Check if this enemy has a projectile in flight - if so, defer visuals
	if _enemies_with_pending_projectile.has(enemy.instance_id):
		# Store damage data to be shown when projectile hits
		_pending_damage_visuals[enemy.instance_id] = {"damage": amount, "is_hex": is_hex}
		# Still update HP immediately (just don't show visual feedback yet)
		_update_enemy_hp_display(enemy)
		return
	
	# Show immediate damage visuals (for non-projectile damage like barriers)
	_show_damage_visuals(enemy, amount, is_hex)


func _show_damage_visuals(enemy, amount: int, is_hex: bool) -> void:
	"""Show the damage visual effects (shake, flash, damage number)."""
	shake_enemy(enemy)
	flash_enemy(enemy)
	show_damage_on_enemy(enemy, amount, is_hex)
	_update_enemy_hp_display(enemy)
	
	# Update mini-panel HP if stack is expanded
	_update_mini_panel_hp(enemy)


func _update_enemy_hp_display(enemy) -> void:
	"""Update the HP display for an enemy (both individual and stack visuals)."""
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.update_enemy_hp(enemy)
	
	# Also update stack aggregate HP if in a stack
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			stack_system.update_stack_hp(stack_key)
			# Also update mini-panels if expanded
			_update_mini_panel_hp(enemy, stack_key)


func _update_mini_panel_hp(enemy, stack_key: String = "") -> void:
	"""Update the mini-panel HP for an enemy in an expanded stack."""
	if not stack_system:
		return
	
	if stack_key.is_empty():
		stack_key = stack_system.get_stack_key_for_enemy(enemy)
	
	if stack_key.is_empty():
		return
	
	# Find and update the specific mini-panel for this enemy
	if stack_system.stack_visuals.has(stack_key):
		var stack_data: Dictionary = stack_system.stack_visuals[stack_key]
		var mini_panels: Array = stack_data.get("mini_panels", [])
		for mini_panel in mini_panels:
			if is_instance_valid(mini_panel):
				var panel_enemy = mini_panel.get_meta("enemy_instance", null)
				if panel_enemy and panel_enemy.instance_id == enemy.instance_id:
					# Update HP and hex display on the mini-panel
					if mini_panel.has_method("update_hp"):
						mini_panel.update_hp()
					if mini_panel.has_method("update_hex"):
						mini_panel.update_hex()
					break


func _on_projectile_hit_enemy(enemy, _impact_pos: Vector2) -> void:
	"""Handle when a projectile hits an enemy - show deferred damage visuals."""
	if enemy == null:
		return
	
	# Clear projectile tracking
	_enemies_with_pending_projectile.erase(enemy.instance_id)
	
	# Show any pending damage visuals
	if _pending_damage_visuals.has(enemy.instance_id):
		var data: Dictionary = _pending_damage_visuals[enemy.instance_id]
		_pending_damage_visuals.erase(enemy.instance_id)
		_show_damage_visuals(enemy, data.damage, data.is_hex)


func _on_enemy_died(enemy) -> void:
	"""Handle enemy death."""
	# Clear any pending projectile tracking for this enemy
	_enemies_with_pending_projectile.erase(enemy.instance_id)
	_pending_damage_visuals.erase(enemy.instance_id)
	
	# Remove from groups and track if any groups became empty
	var empty_group_ids: Array[String] = []
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		for i: int in range(group.enemies.size() - 1, -1, -1):
			if group.enemies[i].instance_id == enemy.instance_id:
				group.enemies.remove_at(i)
				# Track if group is now empty for cleanup
				if group.enemies.is_empty():
					empty_group_ids.append(group_id)
				break
	
	# Play death animation for individual enemy
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.play_death_animation(enemy)
	
	# Handle stack death - remove mini-panel and update stack count
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			_remove_enemy_from_stack_visual(enemy, stack_key)
	
	# Clean up empty groups so new enemies don't merge into "ghost" groups
	for empty_id: String in empty_group_ids:
		var ring: int = enemy_groups[empty_id].ring
		if stack_system:
			stack_system.release_lane(empty_id, ring)
		enemy_groups.erase(empty_id)
	
	_update_threat_levels()


func _remove_enemy_from_stack_visual(enemy, stack_key: String) -> void:
	"""Remove a dead enemy's mini-panel from a stack and update the stack."""
	if not stack_system or not stack_system.stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_system.stack_visuals[stack_key]
	var mini_panels: Array = stack_data.get("mini_panels", [])
	
	# Find and animate out the dead enemy's mini-panel
	for i: int in range(mini_panels.size() - 1, -1, -1):
		var mini_panel: Panel = mini_panels[i]
		if is_instance_valid(mini_panel):
			var panel_enemy = mini_panel.get_meta("enemy_instance", null)
			if panel_enemy and panel_enemy.instance_id == enemy.instance_id:
				# Animate the mini-panel death
				var tween: Tween = mini_panel.create_tween()
				tween.set_parallel(true)
				tween.tween_property(mini_panel, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.1)
				tween.tween_property(mini_panel, "scale", Vector2(1.2, 1.2), 0.1)
				tween.set_parallel(false)
				tween.tween_property(mini_panel, "modulate:a", 0.0, 0.15)
				tween.tween_property(mini_panel, "scale", Vector2(0.5, 0.5), 0.15)
				tween.tween_callback(mini_panel.queue_free)
				
				# Remove from array
				mini_panels.remove_at(i)
				break
	
	# Update stack's enemy list
	var enemies: Array = stack_data.get("enemies", [])
	for i: int in range(enemies.size() - 1, -1, -1):
		if enemies[i].instance_id == enemy.instance_id:
			enemies.remove_at(i)
			break
	
	# Update stack panel count and HP
	var main_panel: Panel = stack_data.panel
	if is_instance_valid(main_panel) and main_panel.has_method("update_count"):
		main_panel.update_count(enemies)
	
	# If stack is now empty or has only 1 enemy, clean up
	if enemies.size() == 0:
		# Schedule stack removal (let death animation play first)
		get_tree().create_timer(0.3).timeout.connect(func():
			if stack_system:
				stack_system.remove_stack(stack_key)
		)
	
	# Reposition remaining mini-panels
	_reposition_stack_mini_panels(stack_key)


func _reposition_stack_mini_panels(stack_key: String) -> void:
	"""Reposition remaining mini-panels after one is removed."""
	if not stack_system or not stack_system.stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_system.stack_visuals[stack_key]
	var mini_panels: Array = stack_data.get("mini_panels", [])
	var main_panel: Panel = stack_data.panel
	
	if not is_instance_valid(main_panel) or mini_panels.is_empty():
		return
	
	# Calculate new layout (using same logic as BattlefieldStackSystem)
	var mini_size: Vector2 = Vector2(55.0, 50.0)  # MINI_PANEL_SIZE from BattlefieldStackSystem
	var vertical_gap: float = 16.0
	var spacing: float = mini_size.x + 6.0
	var total_width: float = spacing * mini_panels.size() - 6.0 if mini_panels.size() > 0 else 0.0
	var start_x: float = main_panel.position.x + main_panel.size.x / 2.0 - total_width / 2.0
	var base_y: float = maxf(main_panel.position.y - mini_size.y - vertical_gap, 0.0)
	
	# Animate remaining mini-panels to new positions
	for i: int in range(mini_panels.size()):
		var mini_panel: Panel = mini_panels[i]
		if is_instance_valid(mini_panel):
			var target_pos: Vector2 = Vector2(start_x + i * spacing, base_y)
			var tween: Tween = mini_panel.create_tween()
			tween.tween_property(mini_panel, "position", target_pos, 0.2).set_ease(Tween.EASE_OUT)


func _on_enemy_death_finished(_enemy) -> void:
	"""Handle enemy death animation completed."""
	pass  # Could refresh visuals if needed


func _on_enemy_moved(enemy, from_ring: int, to_ring: int) -> void:
	"""Handle enemy movement. Lane is preserved across ring transitions.
	Groups NEVER merge - each spawn batch stays as its own group permanently."""
	# Find the group for this enemy
	var moving_group_id: String = ""
	var moving_group: Dictionary = {}
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		for e in group.enemies:
			if e.instance_id == enemy.instance_id:
				moving_group_id = group_id
				moving_group = group
				break
		if not moving_group_id.is_empty():
			break
	
	if moving_group_id.is_empty():
		_update_threat_levels()
		return
	
	# Update the moving group's ring
	moving_group.ring = to_ring
	
	# Update occupied lanes tracking
	if stack_system:
		# Release lane in old ring
		stack_system.release_lane(moving_group_id, from_ring)
		# Re-occupy lane in new ring (same lane index preserved)
		var lane: int = stack_system.get_group_lane(moving_group_id)
		stack_system.set_group_lane(moving_group_id, lane, to_ring)
	
	# Update visual positions (no merging - groups stay separate)
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.update_enemy_position(enemy, true)
	
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			stack_system.update_stack_ring(stack_key, to_ring, true)
	
	_update_threat_levels()


func _merge_groups(target_group_id: String, source_group_id: String, target_group: Dictionary, source_group: Dictionary, source_original_ring: int = -1) -> void:
	"""Merge source_group into target_group. Called when groups of same enemy type end up in same ring.
	source_original_ring: The ring the source group was in BEFORE the move (needed for correct stack key lookup)."""
	# Use the original ring for stack key lookup if provided, otherwise fall back to current ring
	var stack_ring: int = source_original_ring if source_original_ring >= 0 else source_group.ring
	
	# Move all enemies from source to target
	for enemy in source_group.enemies:
		# Check if already in target (shouldn't happen but safety check)
		var found: bool = false
		for e in target_group.enemies:
			if e.instance_id == enemy.instance_id:
				found = true
				break
		if not found:
			target_group.enemies.append(enemy)
			enemy.group_id = target_group_id
	
	# Remove the source group's stack visual if it exists
	# IMPORTANT: Use the ORIGINAL ring for the stack key, not the updated ring
	if stack_system:
		var source_stack_key: String = str(stack_ring) + "_" + source_group.enemy_id + "_" + source_group_id
		if stack_system.has_stack(source_stack_key):
			stack_system.remove_stack(source_stack_key)
		
		# Release the source group's lane (use original ring)
		stack_system.release_lane(source_group_id, stack_ring)
	
	# Also remove any individual enemy visuals from the source group
	if enemy_manager:
		for enemy in source_group.enemies:
			if enemy_manager.has_enemy_visual(enemy.instance_id):
				enemy_manager.hide_enemy_visual(enemy.instance_id)
	
	# Remove the source group from tracking
	enemy_groups.erase(source_group_id)
	
	# Update the target group's visual
	_create_or_update_enemy_visual_for_group(target_group_id, target_group)


func _create_or_update_enemy_visual_for_group(group_id: String, group_data: Dictionary) -> void:
	"""Create or update visuals for an entire group after a merge."""
	var ring: int = group_data.ring
	var enemy_id: String = group_data.enemy_id
	var enemy_count: int = group_data.enemies.size()
	
	if enemy_count >= STACK_THRESHOLD:
		# Should be a stack
		var stack_key: String = str(ring) + "_" + enemy_id + "_" + group_id
		
		if stack_system and stack_system.has_stack(stack_key):
			# Update existing stack with new enemy count
			_update_stack_enemies(stack_key, group_data)
		else:
			# Create new stack
			_ensure_stack_exists(group_id, group_data)
	else:
		# Individual enemies - update each one's position
		if enemy_manager:
			for enemy in group_data.enemies:
				if enemy_manager.has_enemy_visual(enemy.instance_id):
					var angular_pos: float = _calculate_intra_group_position(enemy, group_data)
					enemy_manager.set_enemy_angular_position(enemy.instance_id, angular_pos)
					enemy_manager.update_enemy_position(enemy, true)
				else:
					# Create visual if it doesn't exist
					var angular_pos: float = _calculate_intra_group_position(enemy, group_data)
					enemy_manager.set_enemy_angular_position(enemy.instance_id, angular_pos)
					enemy_manager.create_enemy_visual(enemy)


func _update_group_visuals_in_ring(ring: int) -> void:
	"""Update visual positions for all groups in a ring.
	With lane-based positioning, groups keep their assigned lanes - no rebalancing needed."""
	for gid: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[gid]
		if group.ring == ring:
			# Get lane-based angle
			var lane: int = group.get("lane", 6)
			var angle: float = _calculate_angular_position_for_lane(lane)
			group.angular_position = angle
			
			# Update stack visual if exists
			_update_stack_visual_position(gid)
			# Update individual enemy positions
			_update_individual_enemy_positions(gid, angle)


func _update_stack_visual_position(group_id: String) -> void:
	"""Update the visual position of a stack for a given group."""
	if not stack_system:
		return
	
	if not enemy_groups.has(group_id):
		return
	
	var group: Dictionary = enemy_groups[group_id]
	var stack_key: String = str(group.ring) + "_" + group.enemy_id + "_" + group_id
	
	if stack_system.has_stack(stack_key):
		stack_system.update_stack_position(stack_key, true)  # Animate to new position


func _update_individual_enemy_positions(group_id: String, _angle: float) -> void:
	"""Update the visual positions of all individual enemies in a group."""
	if not enemy_manager:
		return
	
	if not enemy_groups.has(group_id):
		return
	
	var group: Dictionary = enemy_groups[group_id]
	for enemy in group.enemies:
		if enemy_manager.has_enemy_visual(enemy.instance_id):
			var actual_angle: float = _calculate_intra_group_position(enemy, group)
			enemy_manager.set_enemy_angular_position(enemy.instance_id, actual_angle)
			enemy_manager.update_enemy_position(enemy, true)  # Animate to new position


func _calculate_intra_group_position(enemy, group_data: Dictionary) -> float:
	"""Calculate the slot-based position for an individual enemy within a group.
	V2: Returns a fake angle that encodes the slot + offset for spreading.
	Spreads enemies slightly apart when there are multiple individuals in the same group."""
	# Get slot (horizontal position)
	var slot: int = group_data.get("lane", 6)
	var enemies: Array = group_data.enemies
	var enemy_count: int = enemies.size()
	
	# Base angle represents the slot (for backward compatibility with enemy manager)
	var total_slots: int = 12
	var base_angle: float = PI + (float(slot) / float(total_slots - 1)) * PI
	
	# If only 1 enemy, use the group's base position
	if enemy_count <= 1:
		return base_angle
	
	# Find this enemy's index in the group
	var enemy_index: int = -1
	for i: int in range(enemies.size()):
		if enemies[i].instance_id == enemy.instance_id:
			enemy_index = i
			break
	
	if enemy_index < 0:
		return base_angle
	
	# Spread enemies apart within the group using small angular offset
	# This translates to horizontal spread in the lane system
	var spread_angle: float = 0.15  # Smaller spread for horizontal layout
	var total_spread: float = spread_angle * (enemy_count - 1)
	var start_offset: float = -total_spread / 2.0
	
	return base_angle + start_offset + (enemy_index * spread_angle)




func _on_enemy_hexed(enemy, hex_amount: int) -> void:
	"""Handle enemy receiving hex status - show visual feedback."""
	if enemy == null:
		return
	
	# Purple flash on the enemy
	var hex_color: Color = Color(0.7, 0.3, 1.0, 1.0)
	flash_enemy(enemy, hex_color, 0.2)
	
	# Show floating hex stack indicator (+☠X)
	var global_pos: Vector2 = get_enemy_center_position(enemy)
	if effects_node:
		# Convert global position to local position for effects_node
		var local_pos: Vector2 = global_pos - effects_node.global_position
		effects_node.show_hex_stack_number(local_pos - Vector2(15, 40), hex_amount)
		effects_node.spawn_hex_particles(local_pos)
	
	# Update the enemy panel's hex display
	_update_enemy_hex_display(enemy)


func _update_enemy_hex_display(enemy) -> void:
	"""Update the hex display on an enemy's visual panel."""
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		var visual: Panel = enemy_manager.get_enemy_visual(enemy.instance_id)
		if visual and visual.has_method("update_hex"):
			visual.update_hex()
	
	# Also update mini-panels if in a stack
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty() and stack_system.stack_visuals.has(stack_key):
			var stack_data: Dictionary = stack_system.stack_visuals[stack_key]
			var mini_panels: Array = stack_data.get("mini_panels", [])
			for mini_panel in mini_panels:
				if is_instance_valid(mini_panel):
					var panel_enemy = mini_panel.get_meta("enemy_instance", null)
					if panel_enemy and panel_enemy.instance_id == enemy.instance_id:
						if mini_panel.has_method("update_hex"):
							mini_panel.update_hex()
						break


func _on_player_damaged(amount: int, _source) -> void:
	"""Handle player taking damage."""
	if effects_node:
		effects_node.show_player_damage(amount)


func _on_barrier_placed(ring: int, damage: int, duration: int) -> void:
	"""Handle barrier being placed on a ring - show visual feedback."""
	print("[BattlefieldArena] Barrier placed on ring ", ring, " damage=", damage, " duration=", duration)
	
	# Update the ring display to show the barrier
	if rings:
		rings.set_barrier(ring, damage, duration)
	
	# Create visual placement effect
	if effects_node:
		# Calculate barrier position (on the ring edge)
		var barrier_radius: float = rings.get_ring_radius(ring) if rings else max_radius * 0.5
		
		# Create a shield flash effect on the ring
		_create_barrier_placement_effect(ring, barrier_radius)


func _create_barrier_placement_effect(ring: int, _radius: float) -> void:
	"""Create visual effect when a barrier is placed on a lane.
	V2: Uses horizontal line instead of arc."""
	if not effects_node:
		return
	
	# Get lane rectangle for this ring
	var lane_rect: Rect2 = rings.get_lane_rect(ring) if rings else Rect2()
	if lane_rect.size == Vector2.ZERO:
		return
	
	# Barrier line is at the bottom of the lane
	var barrier_y: float = lane_rect.end.y - 8.0
	var barrier_start_x: float = lane_rect.position.x + 20
	var barrier_end_x: float = lane_rect.end.x - 20
	
	# Spawn shield particles along the horizontal barrier line
	var barrier_color: Color = Color(0.3, 0.9, 0.5, 1.0)  # Green/cyan for shield
	var particle_count: int = 12
	
	for i: int in range(particle_count):
		# Spread particles along the horizontal line
		var x: float = barrier_start_x + (float(i) / float(particle_count - 1)) * (barrier_end_x - barrier_start_x)
		var pos: Vector2 = Vector2(x, barrier_y)
		
		# Create particle
		var particle: Panel = Panel.new()
		particle.custom_minimum_size = Vector2(10, 10)
		particle.size = Vector2(10, 10)
		particle.position = pos - Vector2(5, 5)
		particle.z_index = 55
		particle.modulate.a = 0.0
		particle.scale = Vector2(0.5, 0.5)
		
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = barrier_color
		style.set_corner_radius_all(5)
		particle.add_theme_stylebox_override("panel", style)
		
		effects_node.add_child(particle)
		
		# Animate: fade in, pulse, fade out
		var delay: float = float(i) * 0.02
		var tween: Tween = particle.create_tween()
		tween.tween_property(particle, "modulate:a", 1.0, 0.1).set_delay(delay)
		tween.tween_property(particle, "scale", Vector2(1.5, 1.5), 0.2).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.tween_callback(particle.queue_free)
	
	# Also flash the ring itself briefly
	if rings:
		_flash_ring_barrier(ring)


func _flash_ring_barrier(_ring: int) -> void:
	"""Flash the ring to indicate barrier placement."""
	# The ring drawing handles the barrier visual via set_barrier
	# This adds an extra flash effect by temporarily adjusting the visual
	# Since BattlefieldRings handles drawing, we'll trigger a redraw with a pulse
	if rings:
		rings.queue_redraw()


func _on_barrier_consumed(ring: int) -> void:
	"""Handle when a barrier's uses reach 0 and it disappears."""
	print("[BattlefieldArena] Barrier consumed on ring ", ring)
	
	# Clear the barrier visual from the ring
	if rings:
		rings.clear_barrier(ring)
	
	# Optional: Create a "barrier break" visual effect
	if effects_node:
		var barrier_radius: float = rings.get_ring_radius(ring) if rings else max_radius * 0.5
		_create_barrier_break_effect(ring, barrier_radius)


func _create_barrier_break_effect(ring: int, _radius: float) -> void:
	"""Create visual effect when a barrier is consumed/broken.
	V2: Uses horizontal positions instead of arc."""
	if not effects_node:
		return
	
	# Get lane rectangle for this ring
	var lane_rect: Rect2 = rings.get_lane_rect(ring) if rings else Rect2()
	if lane_rect.size == Vector2.ZERO:
		return
	
	var barrier_y: float = lane_rect.end.y - 8.0
	var barrier_start_x: float = lane_rect.position.x + 20
	var barrier_end_x: float = lane_rect.end.x - 20
	
	var barrier_color: Color = Color(0.3, 0.9, 0.5, 0.8)
	var break_color: Color = Color(0.5, 0.5, 0.5, 0.8)  # Gray for "broken"
	
	# Spawn breaking particles along the horizontal barrier line
	var particle_count: int = 16
	for i: int in range(particle_count):
		var x: float = barrier_start_x + (float(i) / float(particle_count - 1)) * (barrier_end_x - barrier_start_x)
		var pos: Vector2 = Vector2(x, barrier_y)
		
		var particle: Panel = Panel.new()
		particle.custom_minimum_size = Vector2(8, 8)
		particle.size = Vector2(8, 8)
		particle.position = pos - Vector2(4, 4)
		particle.z_index = 55
		
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = barrier_color.lerp(break_color, randf())
		style.set_corner_radius_all(4)
		particle.add_theme_stylebox_override("panel", style)
		
		effects_node.add_child(particle)
		
		# Animate: fall downward and fade out
		var fall_offset: Vector2 = Vector2(randf_range(-30, 30), randf_range(40, 80))
		var tween: Tween = particle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", particle.position + fall_offset, 0.5).set_ease(Tween.EASE_IN)
		tween.tween_property(particle, "modulate:a", 0.0, 0.4).set_delay(0.1)
		tween.tween_property(particle, "rotation", randf_range(-PI, PI), 0.5)
		tween.set_parallel(false)
		tween.tween_callback(particle.queue_free)


func _on_barrier_triggered(enemy, ring: int, damage: int) -> void:
	"""Handle barrier being triggered when enemy crosses it."""
	print("[BattlefieldArena] Barrier triggered! Enemy=", enemy.enemy_id if enemy else "null", " ring=", ring, " damage=", damage)
	
	# Sync the barrier visual with the actual state (updates remaining uses display)
	_sync_barrier_visual(ring)
	
	# Get enemy position for effects (global, then convert to local for effects_node)
	var global_enemy_pos: Vector2 = get_enemy_center_position(enemy) if enemy else (center + global_position)
	var local_enemy_pos: Vector2 = global_enemy_pos - effects_node.global_position if effects_node else center
	
	# Visual feedback: sparks from barrier to enemy, and barrier hit effect
	if effects_node and rings:
		var barrier_radius: float = rings.get_ring_radius(ring)
		# Calculate position along the ring where the enemy crossed (using local coords)
		var angle: float = (local_enemy_pos - center).angle()
		var barrier_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * barrier_radius
		
		# Fire sparks from barrier to enemy (both in local coords)
		effects_node.fire_barrier_sparks(barrier_pos, local_enemy_pos)
		
		# Create barrier hit effect at the barrier position
		effects_node.create_barrier_hit_effect(barrier_pos, damage)
	
	# IMPORTANT: Expand the stack to show which enemy was hit
	if enemy and stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			# Hold the stack open so player can see the damage
			stack_system.hold_stack_open(stack_key)
			
			# Shake and flash the stack to draw attention
			stack_system.shake_stack(stack_key, 6.0, 0.2)
			stack_system.flash_stack(stack_key, Color(0.3, 1.0, 0.5, 1.2), 0.2)
			
			# Release the hold after a delay so it can collapse
			var timer: SceneTreeTimer = get_tree().create_timer(1.5)
			timer.timeout.connect(func():
				if stack_system:
					stack_system.release_stack_hold(stack_key)
			)


func _sync_barrier_visual(ring: int) -> void:
	"""Sync the barrier visual with the actual BattlefieldState."""
	if not rings or not CombatManager.battlefield:
		return
	
	var battlefield_barriers: Dictionary = CombatManager.battlefield.ring_barriers
	if battlefield_barriers.has(ring):
		var barrier: Dictionary = battlefield_barriers[ring]
		rings.set_barrier(ring, barrier.damage, barrier.turns_remaining)
	else:
		# Barrier no longer exists in state, clear visual
		rings.clear_barrier(ring)


func _on_enemy_targeted(enemy) -> void:
	"""Handle visual feedback when an enemy is targeted by a projectile.
	NEW FLOW: Expand stack -> Wait for layout -> Highlight target -> Fire from muzzle -> Impact effects"""
	if enemy == null:
		return
	
	print("[TARGET DEBUG] ===========================================")
	print("[TARGET DEBUG] _on_enemy_targeted: enemy=", enemy.enemy_id, " instance_id=", enemy.instance_id)
	
	# STEP 1: Expand the enemy stack FIRST (if applicable)
	var stack_key: String = ""
	if stack_system:
		stack_key = stack_system.get_stack_key_for_enemy(enemy)
		print("[TARGET DEBUG] Stack key: '", stack_key, "'")
		if not stack_key.is_empty():
			# Expand stack immediately to show all units
			stack_system.hold_stack_open(stack_key)
			# Wait for layout to complete (global_position needs a frame to update)
			await get_tree().process_frame
			await get_tree().process_frame
			print("[TARGET DEBUG] Stack expanded: ", stack_system.is_stack_expanded(stack_key))
	
	# STEP 2: Get target position AFTER expansion and layout (mini-panel position now available)
	var target_pos: Vector2 = get_enemy_center_position(enemy)
	print("[TARGET DEBUG] Target position: ", target_pos)
	
	# STEP 3: Highlight the target enemy with a targeting reticle
	_highlight_target_enemy(enemy, stack_key)
	
	# Track this enemy as having a projectile in flight
	_enemies_with_pending_projectile[enemy.instance_id] = true
	
	if not effects_node:
		return
	
	# STEP 4: Fire weapon from muzzle with VFX
	var lane_index: int = CombatManager.current_executing_lane_index
	
	if lane_index >= 0 and combat_lane and combat_lane.has_method("set_weapon_target"):
		# Aim the weapon at the target
		combat_lane.set_weapon_target(lane_index, target_pos)
		
		# Fire from weapon and get muzzle position for projectile
		if combat_lane.has_method("fire_weapon_at_target"):
			var muzzle_pos: Vector2 = combat_lane.fire_weapon_at_target(lane_index, target_pos)
			if muzzle_pos != Vector2.ZERO:
				# Create muzzle flash VFX
				_create_muzzle_flash(muzzle_pos)
				# Fire fast projectile from muzzle
				_fire_fast_projectile(muzzle_pos, target_pos, enemy, Color(1.0, 0.9, 0.3), stack_key)
				return
	
	# Fallback: fire generic projectile from arena center
	_fire_fast_projectile(arena_center(), target_pos, enemy, Color(1.0, 0.9, 0.3), stack_key)


func _highlight_target_enemy(enemy, stack_key: String) -> void:
	"""Highlight the enemy being targeted with a red flash/pulse."""
	# Flash the enemy red to indicate targeting
	var target_color: Color = Color(1.0, 0.4, 0.4, 1.0)
	
	if stack_key.is_empty():
		# Individual enemy - flash directly
		if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
			var visual: Panel = enemy_manager.get_enemy_visual(enemy.instance_id)
			_pulse_target(visual, target_color)
	else:
		# Stacked enemy - flash the mini-panel if expanded
		if stack_system and stack_system.stack_visuals.has(stack_key):
			var stack_data: Dictionary = stack_system.stack_visuals[stack_key]
			var mini_panels: Array = stack_data.get("mini_panels", [])
			
			# Find the specific mini-panel for this enemy
			for mini_panel in mini_panels:
				if is_instance_valid(mini_panel):
					var panel_enemy = mini_panel.get_meta("enemy_instance", null)
					if panel_enemy and panel_enemy.instance_id == enemy.instance_id:
						_pulse_target(mini_panel, target_color)
						break
			
			# Also pulse the main stack panel
			var main_panel: Panel = stack_data.panel
			if is_instance_valid(main_panel):
				_pulse_target(main_panel, target_color, 0.8)  # Subtle pulse


func _pulse_target(visual: Control, color: Color, intensity: float = 1.0) -> void:
	"""Apply a quick targeting pulse to a visual element."""
	if not is_instance_valid(visual):
		return
	
	var target_modulate: Color = color.lerp(Color.WHITE, 1.0 - intensity)
	
	var tween: Tween = visual.create_tween()
	tween.tween_property(visual, "modulate", target_modulate, 0.08)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.12)


func _create_muzzle_flash(pos: Vector2) -> void:
	"""Create a muzzle flash VFX at the weapon's muzzle position."""
	# Add to root viewport so muzzle flash appears at correct position regardless of UI hierarchy
	var root_canvas: Node = get_tree().root
	
	# Create bright flash using global position
	var flash: Panel = Panel.new()
	flash.custom_minimum_size = Vector2(24, 24)
	flash.size = Vector2(24, 24)
	flash.position = pos - Vector2(12, 12)  # Use global position directly
	flash.z_index = 100  # High z-index to render above everything
	flash.pivot_offset = flash.size / 2
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.9, 0.4, 1.0)
	style.set_corner_radius_all(12)
	flash.add_theme_stylebox_override("panel", style)
	
	root_canvas.add_child(flash)
	
	# Quick flash animation
	var tween: Tween = flash.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.04)
	tween.parallel().tween_property(flash, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.04)
	tween.tween_property(flash, "scale", Vector2(0.5, 0.5), 0.06)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.06)
	tween.tween_callback(flash.queue_free)
	
	# Spawn a few sparks
	for i: int in range(3):
		var spark: ColorRect = ColorRect.new()
		spark.size = Vector2(4, 4)
		spark.color = Color(1.0, 0.8, 0.3, 1.0)
		spark.position = pos - Vector2(2, 2)  # Use global position
		spark.z_index = 99
		root_canvas.add_child(spark)
		
		var angle: float = randf_range(-PI/4, PI/4)  # Forward cone
		var spark_dist: float = randf_range(15, 35)
		var spark_target: Vector2 = pos + Vector2(cos(angle), sin(angle)) * spark_dist
		
		var spark_tween: Tween = spark.create_tween()
		spark_tween.set_parallel(true)
		spark_tween.tween_property(spark, "position", spark_target - Vector2(2, 2), 0.1)
		spark_tween.tween_property(spark, "modulate:a", 0.0, 0.1)
		spark_tween.tween_callback(spark.queue_free)


func _fire_fast_projectile(from_pos: Vector2, to_pos: Vector2, enemy, color: Color, enemy_stack_key: String = "") -> void:
	"""Fire a FAST projectile from source to target. Much snappier than the slow version."""
	if not effects_node:
		return
	
	# Add projectile to root viewport so it can travel across UI boundaries (e.g., from CombatLane to BattlefieldArena)
	var root_canvas: Node = get_tree().root
	
	var projectile: ColorRect = ColorRect.new()
	projectile.size = Vector2(14, 5)
	projectile.color = color
	projectile.position = from_pos - projectile.size / 2  # Use global position directly
	projectile.z_index = 100  # High z-index to render above everything
	
	# Rotate to face target
	var angle: float = from_pos.angle_to_point(to_pos)
	projectile.pivot_offset = projectile.size / 2
	projectile.rotation = angle
	
	root_canvas.add_child(projectile)
	
	# FAST travel - much snappier
	var distance: float = from_pos.distance_to(to_pos)
	var travel_time: float = distance / 1800.0  # Very fast: 1800 px/s
	travel_time = maxf(travel_time, 0.05)  # Minimum 50ms
	travel_time = minf(travel_time, 0.20)  # Maximum 200ms (slightly longer for visibility)
	
	var tween: Tween = projectile.create_tween()
	tween.tween_property(projectile, "position", to_pos - projectile.size / 2, travel_time).set_ease(Tween.EASE_OUT)
	tween.tween_callback(projectile.queue_free)
	
	# Schedule impact when projectile arrives
	var captured_enemy = enemy
	var captured_stack_key: String = enemy_stack_key
	var captured_stack_system = stack_system
	var captured_effects_node = effects_node
	var captured_to_pos: Vector2 = to_pos
	var impact_timer: SceneTreeTimer = get_tree().create_timer(travel_time)
	impact_timer.timeout.connect(func():
		if captured_effects_node and is_instance_valid(captured_effects_node):
			# Convert global to_pos to local for effects_node
			var local_impact: Vector2 = captured_to_pos - captured_effects_node.global_position
			captured_effects_node.create_impact_flash(local_impact, color)
		# Emit signal to show damage numbers
		if captured_enemy and captured_effects_node:
			captured_effects_node.projectile_hit_enemy.emit(captured_enemy, captured_to_pos)
		# Release stack hold after impact
		if captured_stack_system and not captured_stack_key.is_empty():
			# Small delay before collapsing to let player see the damage
			var release_timer: SceneTreeTimer = get_tree().create_timer(0.35)
			release_timer.timeout.connect(func():
				if captured_stack_system:
					captured_stack_system.release_stack_hold(captured_stack_key)
			)
	, CONNECT_ONE_SHOT)


func arena_center() -> Vector2:
	"""Get the center position of the arena in global coordinates."""
	return center + global_position


func _fire_projectile_from_to(from_pos: Vector2, to_pos: Vector2, color: Color) -> void:
	"""Fire a projectile from a specific position to a target."""
	if not effects_node:
		return
	
	# Add projectile to root viewport so it can travel across UI boundaries
	var root_canvas: Node = get_tree().root
	
	var projectile: ColorRect = ColorRect.new()
	projectile.size = Vector2(12, 4)
	projectile.color = color
	projectile.position = from_pos - projectile.size / 2  # Use global position
	projectile.z_index = 100  # High z-index to render above everything
	
	var angle: float = from_pos.angle_to_point(to_pos)
	projectile.pivot_offset = projectile.size / 2
	projectile.rotation = angle
	
	root_canvas.add_child(projectile)
	
	var distance: float = from_pos.distance_to(to_pos)
	var travel_time: float = distance / 600.0
	
	var tween: Tween = projectile.create_tween()
	tween.tween_property(projectile, "position", to_pos - projectile.size / 2, travel_time).set_ease(Tween.EASE_OUT)
	tween.tween_callback(projectile.queue_free)
	
	# Impact flash
	var captured_effects_node = effects_node
	var captured_to_pos: Vector2 = to_pos
	var impact_timer: SceneTreeTimer = get_tree().create_timer(travel_time)
	impact_timer.timeout.connect(func():
		if captured_effects_node and is_instance_valid(captured_effects_node):
			var local_impact: Vector2 = captured_to_pos - captured_effects_node.global_position
			captured_effects_node.create_impact_flash(local_impact, color)
	)




func _on_turn_started(_turn: int) -> void:
	"""Handle turn starting."""
	_update_threat_levels()


func _on_weapons_phase_started() -> void:
	"""Handle weapons phase starting."""
	if stack_system:
		stack_system.set_weapons_phase(true)


func _on_weapons_phase_ended() -> void:
	"""Handle weapons phase ending."""
	if stack_system:
		stack_system.set_weapons_phase(false)


# ============== HOVER HANDLERS ==============

func _on_enemy_hover_entered(visual: Panel, enemy) -> void:
	"""Handle enemy hover."""
	if hover_system:
		hover_system.on_enemy_hover_enter(visual, enemy)


func _on_enemy_hover_exited(visual: Panel) -> void:
	"""Handle enemy hover exit."""
	if hover_system:
		hover_system.on_enemy_hover_exit(visual)


func _on_stack_hover_entered(panel: Panel, stack_key: String) -> void:
	"""Handle stack hover."""
	if hover_system:
		hover_system.on_stack_hover_enter(panel, stack_key)


func _on_stack_hover_exited(panel: Panel, stack_key: String) -> void:
	"""Handle stack hover exit."""
	if hover_system:
		hover_system.on_stack_hover_exit(panel, stack_key)


func _on_mini_panel_hover_entered(panel: Panel, enemy, stack_key: String) -> void:
	"""Handle mini-panel hover."""
	if hover_system:
		hover_system.on_mini_panel_hover_enter(panel, enemy, stack_key)


func _on_mini_panel_hover_exited(panel: Panel, stack_key: String) -> void:
	"""Handle mini-panel hover exit."""
	if hover_system:
		hover_system.on_mini_panel_hover_exit(panel, stack_key)


# ================================================================
# PUBLIC API FACADE - Functions called from CombatScreen
# ================================================================

func clear_all_hover_states() -> void:
	"""Clear all hover highlights."""
	if hover_system:
		hover_system.clear_all_hover_states()


func highlight_all_rings(should_highlight: bool) -> void:
	"""Highlight all rings."""
	if rings:
		rings.highlight_all_rings(should_highlight)


func highlight_ring(ring_idx: int, should_highlight: bool) -> void:
	"""Highlight a specific ring."""
	if rings:
		rings.highlight_ring(ring_idx, should_highlight)


func highlight_rings(ring_indices: Array, should_highlight: bool) -> void:
	"""Highlight multiple specific rings."""
	if rings:
		rings.highlight_rings(ring_indices, should_highlight)


func get_ring_at_position(pos: Vector2) -> int:
	"""Get which ring a screen position is over."""
	if rings:
		return rings.get_ring_at_position(pos)
	return -1


func update_enemy_hp(enemy) -> void:
	"""Update an enemy's HP display."""
	if enemy_manager:
		enemy_manager.update_enemy_hp(enemy)


func show_card_targeting_hints(card_def, tier: int = 0) -> void:
	"""Show targeting hints for a card being hovered."""
	if targeting_hints:
		targeting_hints.show_for_card(card_def, tier, enemy_groups, center)


func clear_card_targeting_hints() -> void:
	"""Clear targeting hints."""
	if targeting_hints:
		targeting_hints.clear()
