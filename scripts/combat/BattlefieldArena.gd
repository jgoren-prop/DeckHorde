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

# Layout
var center: Vector2 = Vector2.ZERO
var max_radius: float = 200.0

# Stacking config
const STACK_THRESHOLD: int = 3


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


func _connect_combat_signals() -> void:
	"""Connect to CombatManager signals."""
	CombatManager.enemy_spawned.connect(_on_enemy_spawned)
	CombatManager.enemy_damaged.connect(_on_enemy_damaged)
	CombatManager.enemy_killed.connect(_on_enemy_died)
	CombatManager.enemy_moved.connect(_on_enemy_moved)
	CombatManager.player_damaged.connect(_on_player_damaged)
	CombatManager.barrier_triggered.connect(_on_barrier_triggered)
	CombatManager.turn_started.connect(_on_turn_started)
	CombatManager.weapons_phase_started.connect(_on_weapons_phase_started)
	CombatManager.weapons_phase_ended.connect(_on_weapons_phase_ended)


func _recalculate_layout() -> void:
	"""Recalculate battlefield layout based on size."""
	center = size / 2
	max_radius = min(size.x, size.y) / 2 * 0.9
	
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
		_ensure_stack_exists(group_id, group_data)
		# Hide individual visual if it exists
		if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
			enemy_manager.hide_enemy_visual(enemy.instance_id)
	else:
		# Should be individual
		if enemy_manager and not enemy_manager.has_enemy_visual(enemy.instance_id):
			enemy_manager.create_enemy_visual(enemy)


func _find_or_create_group(ring: int, enemy_id: String, enemy) -> String:
	"""Find an existing group or create a new one for an enemy."""
	# Look for existing group
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
			return group_id
	
	# Create new group
	_next_group_id += 1
	var group_id: String = "group_" + str(_next_group_id)
	enemy_groups[group_id] = {
		"ring": ring,
		"enemy_id": enemy_id,
		"enemies": [enemy],
		"angular_position": PI * 1.5  # Default to top
	}
	return group_id


func _ensure_stack_exists(group_id: String, group_data: Dictionary) -> void:
	"""Ensure a stack visual exists for a group."""
	var stack_key: String = str(group_data.ring) + "_" + group_data.enemy_id + "_" + group_id
	
	if stack_system and not stack_system.has_stack(stack_key):
		stack_system.create_stack(group_data.ring, group_data.enemy_id, group_data.enemies, stack_key)


func _refresh_all_visuals() -> void:
	"""Refresh all enemy visuals."""
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
			var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
			if enemy_def:
				if ring == 0 and enemy.will_attack_this_turn():
					total_damage += enemy_def.get_scaled_damage(RunManager.current_wave)
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


func _on_enemy_damaged(enemy, amount: int, _source) -> void:
	"""Handle enemy taking damage."""
	shake_enemy(enemy)
	flash_enemy(enemy)
	show_damage_on_enemy(enemy, amount)
	
	# Update HP display
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.update_enemy_hp(enemy)
	elif stack_system:
		var stack_key: String = stack_system.get_stack_key_for_enemy(enemy)
		if not stack_key.is_empty():
			stack_system.update_stack_hp(stack_key)


func _on_enemy_died(enemy) -> void:
	"""Handle enemy death."""
	# Remove from groups
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		for i: int in range(group.enemies.size() - 1, -1, -1):
			if group.enemies[i].instance_id == enemy.instance_id:
				group.enemies.remove_at(i)
				break
	
	# Play death animation
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.play_death_animation(enemy)
	
	_update_threat_levels()


func _on_enemy_death_finished(_enemy) -> void:
	"""Handle enemy death animation completed."""
	pass  # Could refresh visuals if needed


func _on_enemy_moved(enemy, _from_ring: int, to_ring: int) -> void:
	"""Handle enemy movement."""
	# Update group ring
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		for e in group.enemies:
			if e.instance_id == enemy.instance_id:
				group.ring = to_ring
				break
	
	# Update visual position
	if enemy_manager and enemy_manager.has_enemy_visual(enemy.instance_id):
		enemy_manager.update_enemy_position(enemy, true)
	
	_update_threat_levels()




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
