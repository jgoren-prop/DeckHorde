extends Control
## BattlefieldArena - Orchestrator for the ring-based battlefield visualization.
## Delegates to child nodes for specific functionality:
## - BattlefieldRings: Ring drawing and threat visualization
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
	CombatManager.player_damaged.connect(_on_player_damaged)
	CombatManager.barrier_triggered.connect(_on_barrier_triggered)
	CombatManager.turn_started.connect(_on_turn_started)
	CombatManager.weapons_phase_started.connect(_on_weapons_phase_started)
	CombatManager.weapons_phase_ended.connect(_on_weapons_phase_ended)


func _recalculate_layout() -> void:
	"""Recalculate battlefield layout based on size."""
	# For semicircle layout, center is at the bottom of the control
	# This matches BattlefieldRings.recalculate_layout()
	const SEMICIRCLE_PADDING: float = 18.0
	center = Vector2(size.x / 2, size.y - SEMICIRCLE_PADDING)
	
	# Calculate max radius - use whichever dimension is smaller to ensure fit
	var max_by_width: float = (size.x / 2) * 0.98
	var max_by_height: float = (size.y - SEMICIRCLE_PADDING * 2) * 0.98
	max_radius = min(max_by_width, max_by_height)
	
	# Update child nodes
	if rings:
		rings.arena_center = center
		rings.arena_max_radius = max_radius
		rings.recalculate_layout()
	
	if enemy_manager:
		enemy_manager.arena_center = center
		enemy_manager.arena_max_radius = max_radius
	
	if stack_system:
		stack_system.arena_center = center
		stack_system.arena_max_radius = max_radius
	
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
	"""Get the center position of an enemy's visual."""
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		return enemy_manager.get_enemy_center_position(enemy.instance_id)
	
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			return stack_system.get_stack_center_position(stack_key)
	
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


func show_damage_on_enemy(enemy, amount: int, is_hex: bool = false) -> void:
	"""Show a damage number on an enemy."""
	var pos: Vector2 = get_enemy_center_position(enemy) - Vector2(15, 30)
	if effects_node:
		effects_node.show_damage_number(pos, amount, is_hex)


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
	All enemies of the same type in the same ring are merged into one group."""
	# Look for existing group with same enemy type in same ring
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		if group.ring == ring and group.enemy_id == enemy_id:
			# Add to existing group if not already present
			var found: bool = false
			for e in group.enemies:
				if e.instance_id == enemy.instance_id:
					found = true
					break
			if not found:
				group.enemies.append(enemy)
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
		"lane": assigned_lane
	}
	
	# Set the group_id on the enemy so it can be tracked
	enemy.group_id = group_id
	
	return group_id


func _calculate_angular_position_for_lane(lane: int) -> float:
	"""Calculate the angular position for a given lane index.
	Lane 0 = PI (far left), Lane 11 = 2*PI (far right)."""
	var total_lanes: int = 12  # Match BattlefieldStackSystem.TOTAL_LANES
	return PI + (float(lane) / float(total_lanes - 1)) * PI


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
	
	# Remove from groups
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		for i: int in range(group.enemies.size() - 1, -1, -1):
			if group.enemies[i].instance_id == enemy.instance_id:
				group.enemies.remove_at(i)
				break
	
	# Play death animation for individual enemy
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.play_death_animation(enemy)
	
	# Handle stack death - remove mini-panel and update stack count
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			_remove_enemy_from_stack_visual(enemy, stack_key)
	
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
	"""Handle enemy movement. Lane is preserved across ring transitions."""
	# Find the group for this enemy and track if ring changed
	var moved_group_id: String = ""
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		for e in group.enemies:
			if e.instance_id == enemy.instance_id:
				if group.ring != to_ring:
					moved_group_id = group_id
				group.ring = to_ring
				break
		if not moved_group_id.is_empty():
			break
	
	# Update occupied lanes tracking when a group changes rings
	if not moved_group_id.is_empty() and stack_system:
		# Release lane in old ring
		stack_system.release_lane(moved_group_id, from_ring)
		# Re-occupy lane in new ring (same lane index preserved)
		var lane: int = stack_system.get_group_lane(moved_group_id)
		stack_system.set_group_lane(moved_group_id, lane, to_ring)
	
	# Update visual position (lane stays the same, only radius changes)
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.update_enemy_position(enemy, true)
	
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			stack_system.update_stack_ring(stack_key, to_ring, true)
	
	_update_threat_levels()


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
	"""Calculate the angular position for an individual enemy within a group.
	Spreads enemies slightly apart when there are multiple individuals in the same group."""
	# Get lane-based angle (ensures we use lane, not legacy angular_position)
	var lane: int = group_data.get("lane", 6)
	var base_angle: float = _calculate_angular_position_for_lane(lane)
	var enemies: Array = group_data.enemies
	var enemy_count: int = enemies.size()
	
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
	
	# Spread enemies apart within the group
	# Use angular offset (~0.25 radians = ~14 degrees between enemies)
	# This provides good visual separation for 2 individual enemies
	var spread_angle: float = 0.25  # radians (~14 degrees)
	var total_spread: float = spread_angle * (enemy_count - 1)
	var start_offset: float = -total_spread / 2.0
	
	return base_angle + start_offset + (enemy_index * spread_angle)




func _on_player_damaged(amount: int, _source) -> void:
	"""Handle player taking damage."""
	if effects_node:
		effects_node.show_player_damage(amount)


func _on_barrier_triggered(ring: int, _damage_absorbed: int) -> void:
	"""Handle barrier being triggered."""
	# Visual feedback
	if effects_node and rings:
		var barrier_pos: Vector2 = center + Vector2(0, -rings.get_ring_center_radius(ring))
		effects_node.fire_barrier_sparks(barrier_pos, center)


func _on_enemy_targeted(enemy) -> void:
	"""Handle visual feedback when an enemy is targeted by a projectile."""
	if enemy == null:
		return
	
	var target_pos: Vector2 = get_enemy_center_position(enemy)
	
	# Keep stacks expanded while they're being aimed at
	if stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			stack_system.hold_stack_open(stack_key)
			var timer: SceneTreeTimer = get_tree().create_timer(1.5)
			timer.timeout.connect(func():
				if stack_system:
					stack_system.release_stack_hold(stack_key)
			)
	
	if not effects_node:
		return
	
	var weapon_index: int = CombatManager.current_firing_weapon_index
	if weapon_index >= 0:
		# Track that this enemy has a projectile in flight - defer damage visuals
		_enemies_with_pending_projectile[enemy.instance_id] = true
		# Fire weapon projectile at the enemy (damage visuals will be triggered on hit)
		effects_node.fire_weapon_projectile_at_enemy(enemy, target_pos, Color(1.0, 0.9, 0.3), weapon_index)
	else:
		effects_node.fire_projectile_to_position(target_pos, Color(1.0, 0.9, 0.3))




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
