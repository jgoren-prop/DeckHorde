extends Control
## BattlefieldArena - Visual representation of the ring-based battlefield
## Shows concentric rings with the Warden at center and enemies in rings

# Note: ring_clicked and enemy_clicked signals removed as they weren't being used
# Direct drag-drop and hover interactions are handled via other mechanisms

@onready var rings_container: Control = $RingsContainer
@onready var enemy_container: Control = $EnemyContainer
@onready var effects_container: Control = $EffectsContainer
@onready var damage_numbers: Control = $DamageNumbers

# Ring configuration - proportions of the available space (made larger)
const RING_PROPORTIONS: Array[float] = [0.18, 0.42, 0.68, 0.95]  # MELEE, CLOSE, MID, FAR
# Subtle grayscale fills - let threat borders be the primary visual indicator
const RING_COLORS: Array[Color] = [
	Color(0.25, 0.18, 0.18, 0.20),   # MELEE - Subtle dark warm
	Color(0.22, 0.18, 0.15, 0.15),   # CLOSE - Subtle warm gray
	Color(0.18, 0.18, 0.15, 0.12),   # MID - Subtle neutral
	Color(0.15, 0.15, 0.18, 0.08)    # FAR - Subtle cool gray
]
const RING_NAMES: Array[String] = ["MELEE", "CLOSE", "MID", "FAR"]
# Default border colors (used only when threat system not active)
const RING_BORDER_COLORS: Array[Color] = [
	Color(0.5, 0.35, 0.35, 0.5),
	Color(0.45, 0.38, 0.35, 0.4),
	Color(0.4, 0.4, 0.35, 0.35),
	Color(0.35, 0.38, 0.45, 0.3)
]

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
	"stalker": Color(0.3, 0.3, 0.4)
}

# Stacking and multi-row distribution constants
const MAX_ENEMIES_BEFORE_MULTIROW: int = 4  # Use single row up to this count
const MAX_ENEMIES_PER_ROW: int = 5  # Max enemies per row before stacking
const STACK_THRESHOLD: int = 3  # Min same-type enemies to create a stack
const MAX_TOTAL_BEFORE_STACKING: int = 2  # Stacking kicks in when 3+ enemies present (allows stacking at 3 same-type)

# Row distribution within a ring (proportion of ring depth)
const INNER_ROW_RATIO: float = 0.35  # Inner row at 35% depth into ring
const OUTER_ROW_RATIO: float = 0.75  # Outer row at 75% depth into ring

# Threat level colors for ring borders - bold and clear
enum ThreatLevel { SAFE, LOW, MEDIUM, HIGH, CRITICAL }
const THREAT_COLORS: Dictionary = {
	ThreatLevel.SAFE: Color(0.3, 0.75, 0.3, 0.9),      # Green - safe
	ThreatLevel.LOW: Color(0.95, 0.9, 0.2, 0.9),      # Yellow - some threat
	ThreatLevel.MEDIUM: Color(1.0, 0.55, 0.1, 0.95),  # Orange - moderate threat
	ThreatLevel.HIGH: Color(1.0, 0.25, 0.2, 1.0),     # Red - high threat
	ThreatLevel.CRITICAL: Color(1.0, 0.1, 0.1, 1.0)   # Bright Red (pulses) - lethal
}
const THREAT_BORDER_WIDTH: Dictionary = {
	ThreatLevel.SAFE: 2.0,
	ThreatLevel.LOW: 3.0,
	ThreatLevel.MEDIUM: 4.0,
	ThreatLevel.HIGH: 5.0,
	ThreatLevel.CRITICAL: 6.0
}

var enemy_visuals: Dictionary = {}  # instance_id -> Control (individual enemies)
var stack_visuals: Dictionary = {}  # "ring_enemytype" -> {panel: Control, enemies: Array, expanded: bool}
var center: Vector2 = Vector2.ZERO
var max_radius: float = 200.0

# Persistent enemy groups - groups stay intact even when count drops
var enemy_groups: Dictionary = {}  # group_id -> {ring: int, enemy_id: String, enemies: Array[EnemyInstance]}
var _next_group_id: int = 0

# Ring threat tracking
var ring_threat_levels: Array[ThreatLevel] = [ThreatLevel.SAFE, ThreatLevel.SAFE, ThreatLevel.SAFE, ThreatLevel.SAFE]
var ring_threat_damage: Array[int] = [0, 0, 0, 0]  # Damage expected from each ring
var ring_has_bomber: Array[bool] = [false, false, false, false]
var _threat_pulse_time: float = 0.0  # For pulsing critical rings

# Barrier tracking for visual display
var ring_barriers: Dictionary = {}  # ring -> {damage: int, duration: int}
var _barrier_pulse_time: float = 0.0  # For pulsing barrier rings

# Attack indicator tracking
var _pending_attack_indicator: Dictionary = {}  # Tracks which enemy is being targeted
var _active_weapon_reticles: Array[Control] = []  # Track all weapon reticles for cleanup

# Tween tracking to prevent animation conflicts (spazzing)
var _enemy_position_tweens: Dictionary = {}  # instance_id -> Tween
var _stack_position_tweens: Dictionary = {}  # stack_key -> Tween
var _enemy_base_positions: Dictionary = {}  # instance_id -> Vector2 (target/base position)
var _stack_base_positions: Dictionary = {}  # stack_key -> Vector2 (target/base position)
var _enemy_scale_tweens: Dictionary = {}  # instance_id -> Tween
var _stack_scale_tweens: Dictionary = {}  # stack_key -> Tween
var _enemy_debug_timers: Dictionary = {}  # instance_id -> Timer (for cleanup)

# Danger highlighting system - pulsing glow on high-priority threats
enum DangerLevel { NONE, LOW, MEDIUM, HIGH, CRITICAL }
const DANGER_GLOW_COLORS: Dictionary = {
	DangerLevel.NONE: Color(0.0, 0.0, 0.0, 0.0),        # No glow
	DangerLevel.LOW: Color(0.3, 0.9, 0.9, 0.6),         # Cyan - fast enemies
	DangerLevel.MEDIUM: Color(0.7, 0.3, 1.0, 0.7),      # Purple - active buffer/spawner
	DangerLevel.HIGH: Color(1.0, 0.5, 0.1, 0.8),        # Orange - reaching melee next turn
	DangerLevel.CRITICAL: Color(1.0, 0.2, 0.1, 0.9)     # Red - bomber about to explode
}
var _danger_glow_tweens: Dictionary = {}  # instance_id or stack_key -> Tween
var _danger_glow_panels: Dictionary = {}  # instance_id or stack_key -> Panel (glow overlay)


func _ready() -> void:
	_connect_signals()
	# Ensure overlay containers don't block mouse events on enemies
	if rings_container:
		rings_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if effects_container:
		effects_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if damage_numbers:
		damage_numbers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The enemy container needs to pass through events to children
	if enemy_container:
		enemy_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# This control itself should ignore mouse events
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ensure we redraw when ready
	queue_redraw()


func _process(delta: float) -> void:
	# Update pulse time for critical rings
	_threat_pulse_time += delta * 3.0  # 3x speed for pulsing
	if _threat_pulse_time > TAU:
		_threat_pulse_time -= TAU
	
	# Update barrier pulse time
	_barrier_pulse_time += delta * 2.5
	if _barrier_pulse_time > TAU:
		_barrier_pulse_time -= TAU
	
	# Continuously redraw to ensure rings are visible
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalculate_layout()
		queue_redraw()


func _recalculate_layout() -> void:
	# The arena draws as a top-half semicircle, so its visual center is halfway
	# between the warden (bottom) and the top of the FAR ring.
	# Use most of the available vertical space for the battlefield
	max_radius = min(size.x * 0.48, size.y * 0.85)
	center = Vector2(size.x / 2.0, size.y - 40.0)


func update_ring_threat_levels() -> void:
	"""Calculate and update threat levels for each ring based on current enemies."""
	if not CombatManager or not CombatManager.battlefield:
		return
	
	var player_hp: int = RunManager.current_hp if RunManager else 60
	
	# Reset threat data
	ring_threat_damage = [0, 0, 0, 0]
	ring_has_bomber = [false, false, false, false]
	
	# Calculate threat from each ring
	for ring: int in range(4):
		var enemies: Array = CombatManager.battlefield.get_enemies_in_ring(ring)
		var ring_damage: int = 0
		
		for enemy in enemies:
			var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
			if not enemy_def:
				continue
			
			# Check for bombers
			if enemy_def.behavior_type == EnemyDefinition.BehaviorType.BOMBER:
				ring_has_bomber[ring] = true
			
			# Calculate damage from this enemy
			# Enemies in melee (ring 0) will attack next turn
			# Ranged enemies at their target ring will also attack
			if ring == 0:
				# Melee attackers
				ring_damage += enemy_def.get_scaled_damage(RunManager.current_wave)
			elif enemy_def.attack_type == "ranged" and ring <= enemy_def.attack_range and ring == enemy_def.target_ring:
				# Ranged attackers at their target ring
				ring_damage += enemy_def.get_scaled_damage(RunManager.current_wave)
		
		ring_threat_damage[ring] = ring_damage
		
		# Determine threat level for this ring
		if ring_damage >= player_hp:
			ring_threat_levels[ring] = ThreatLevel.CRITICAL
		elif ring_damage > 20 or ring_has_bomber[ring]:
			ring_threat_levels[ring] = ThreatLevel.HIGH
		elif ring_damage > 10:
			ring_threat_levels[ring] = ThreatLevel.MEDIUM
		elif ring_damage > 0:
			ring_threat_levels[ring] = ThreatLevel.LOW
		else:
			ring_threat_levels[ring] = ThreatLevel.SAFE
	
	# Check for enemies moving to melee next turn - increase threat on their current ring
	for ring: int in range(1, 4):
		var enemies_will_reach_melee: int = 0
		var enemies: Array = CombatManager.battlefield.get_enemies_in_ring(ring)
		for enemy in enemies:
			var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
			if enemy_def and enemy.ring - enemy_def.movement_speed <= 0:
				enemies_will_reach_melee += 1
		
		# If enemies will reach melee from this ring, bump up threat
		if enemies_will_reach_melee > 0 and ring_threat_levels[ring] == ThreatLevel.SAFE:
			ring_threat_levels[ring] = ThreatLevel.LOW


func get_ring_threat_color(ring: int) -> Color:
	"""Get the current threat color for a ring, including pulse effect for critical."""
	if ring < 0 or ring > 3:
		return RING_BORDER_COLORS[0]
	
	var threat: ThreatLevel = ring_threat_levels[ring]
	var base_color: Color = THREAT_COLORS[threat]
	
	# Add pulse effect for critical rings
	if threat == ThreatLevel.CRITICAL:
		var pulse: float = (sin(_threat_pulse_time) + 1.0) / 2.0  # 0 to 1
		base_color = base_color.lerp(Color(1.0, 0.6, 0.6, 1.0), pulse * 0.5)
	
	return base_color


func get_ring_threat_border_width(ring: int) -> float:
	"""Get the border width for a ring based on its threat level."""
	if ring < 0 or ring > 3:
		return 2.0
	
	var threat: ThreatLevel = ring_threat_levels[ring]
	var base_width: float = THREAT_BORDER_WIDTH[threat]
	
	# Add pulse effect to width for critical rings
	if threat == ThreatLevel.CRITICAL:
		var pulse: float = (sin(_threat_pulse_time) + 1.0) / 2.0  # 0 to 1
		base_width += pulse * 2.0  # Pulses between base and base+2
	
	return base_width


func _draw() -> void:
	_recalculate_layout()
	
	# Debug: print size to ensure we have valid dimensions
	if size.x < 10 or size.y < 10:
		print("[BattlefieldArena] Warning: Size too small: ", size)
		return
	
	# Draw background
	var bg_rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, Color(0.06, 0.04, 0.09, 1.0))
	
	# Draw rings from outer to inner
	for i: int in range(RING_PROPORTIONS.size() - 1, -1, -1):
		var radius: float = max_radius * RING_PROPORTIONS[i]
		_draw_ring(i, radius)
	
	# Draw warden at center
	_draw_warden()


func _draw_warden() -> void:
	# Draw warden glow
	var glow_color: Color = Color(0.9, 0.7, 0.3, 0.3)
	draw_circle(center, 50.0, glow_color)
	
	# Draw warden body
	var body_color: Color = Color(0.95, 0.8, 0.5, 1.0)
	draw_circle(center, 38.0, body_color)
	
	# Draw inner highlight
	var highlight_color: Color = Color(1.0, 0.9, 0.6, 1.0)
	draw_circle(center, 24.0, highlight_color)
	
	# Draw warden icon
	var icon_color: Color = Color(0.3, 0.2, 0.1, 1.0)
	draw_circle(center, 12.0, icon_color)


func _connect_signals() -> void:
	# Connect to CombatManager signals
	if CombatManager:
		CombatManager.enemy_spawned.connect(_on_enemy_spawned)
		CombatManager.enemy_killed.connect(_on_enemy_killed)
		CombatManager.enemy_moved.connect(_on_enemy_moved)
		CombatManager.enemy_damaged.connect(_on_enemy_damaged)
		CombatManager.player_damaged.connect(_on_player_damaged)
		# Note: weapon_triggered is handled by CombatScreen for icon flash
		CombatManager.turn_started.connect(_on_turn_started_threat_update)
		CombatManager.enemy_targeted.connect(_on_enemy_targeted)
		CombatManager.enemy_hexed.connect(_on_enemy_hexed)
		CombatManager.barrier_placed.connect(_on_barrier_placed)
		CombatManager._enemies_spawned_together.connect(_on_enemies_spawned_together)


func _on_enemy_targeted(enemy) -> void:
	"""Show targeting indicator on an enemy before they're hit."""
	# Check if enemy is in a stack - if so, expand first then fire
	var stack_key: String = _get_stack_key_for_enemy(enemy)
	
	if not stack_key.is_empty() and stack_visuals.has(stack_key):
		# Expand the stack and fire at the specific mini-card (no damage yet)
		_expand_stack_and_fire(enemy, stack_key, 0, false)
	else:
		# Individual enemy - show indicator and fire directly (fast)
		show_attack_indicator(enemy, 0.15)
		_fire_fast_projectile_to_enemy(enemy, Color(1.0, 0.9, 0.3))


func _on_enemy_hexed(enemy, hex_amount: int) -> void:
	"""Show hex application visual on an enemy."""
	# Check if enemy is in a stack - if so, expand and show hex on mini-card
	var stack_key: String = _get_stack_key_for_enemy(enemy)
	
	if not stack_key.is_empty() and stack_visuals.has(stack_key):
		# Expand the stack and show hex effect on the specific mini-card
		_expand_stack_and_show_hex(enemy, stack_key, hex_amount)
	else:
		# Individual enemy - show hex effect directly
		_show_hex_effect_on_enemy(enemy, hex_amount)


func _on_barrier_placed(ring: int, damage: int, duration: int) -> void:
	"""Handle barrier being placed on a ring."""
	set_ring_barrier(ring, damage, duration)


func _on_enemies_spawned_together(enemies: Array, ring: int, enemy_id: String) -> void:
	"""Handle a batch of enemies spawned together - create a persistent group."""
	if enemies.is_empty():
		return
	
	# Create a persistent group for these enemies
	_create_enemy_group(ring, enemy_id, enemies)
	print("[BattlefieldArena] Created group for ", enemies.size(), " enemies of type ", enemy_id, " in ring ", ring)
	
	# Refresh visuals for the ring
	call_deferred("_deferred_refresh_ring", ring)
	call_deferred("update_ring_threat_levels")


func _on_enemy_spawned(enemy) -> void:  # enemy: EnemyInstance
	# Individual spawns (not part of a batch) won't be grouped automatically
	# Check if this enemy should be part of a stack - defer to batch multiple spawns
	call_deferred("_deferred_refresh_ring", enemy.ring)
	call_deferred("update_ring_threat_levels")


func _on_enemy_killed(enemy) -> void:  # enemy: EnemyInstance
	var ring: int = enemy.ring
	
	# Get the stack key BEFORE removing enemy from group (otherwise we lose the group_id)
	var stack_key: String = _get_stack_key_for_enemy(enemy)
	
	# Remove enemy from its group (but keep the group intact)
	_remove_enemy_from_group(enemy)
	
	# If enemy was in a stack, update the stack instead of doing a full refresh
	if not stack_key.is_empty() and stack_visuals.has(stack_key):
		var stack_data: Dictionary = stack_visuals[stack_key]
		
		# Remove enemy from stack's enemies array
		var updated_enemies: Array = []
		for stacked_enemy in stack_data.enemies:
			if stacked_enemy.instance_id != enemy.instance_id:
				updated_enemies.append(stacked_enemy)
		stack_data.enemies = updated_enemies
		
		# Remove mini-panel for this enemy if expanded
		if stack_data.has("mini_panels"):
			var updated_mini_panels: Array = []
			for mini_panel in stack_data.mini_panels:
				if is_instance_valid(mini_panel):
					var mini_enemy_instance_id: int = mini_panel.get_meta("instance_id", -1)
					if mini_enemy_instance_id == enemy.instance_id:
						mini_panel.queue_free()
					else:
						updated_mini_panels.append(mini_panel)
			stack_data.mini_panels = updated_mini_panels
		
		# Update the stack's visual (count and HP) without recreating it
		_update_stack_hp_display(stack_key)
		
		# If no enemies left in the stack, remove the stack panel entirely
		if updated_enemies.is_empty():
			if stack_data.has("panel") and is_instance_valid(stack_data.panel):
				stack_data.panel.queue_free()
			# Clean up position tracking
			_stack_base_positions.erase(stack_key)
			if _stack_position_tweens.has(stack_key):
				var old_tween: Tween = _stack_position_tweens[stack_key]
				if old_tween and old_tween.is_valid():
					old_tween.kill()
				_stack_position_tweens.erase(stack_key)
			stack_visuals.erase(stack_key)
	
	_remove_enemy_visual(enemy)
	# Only do a full refresh if enemy was NOT in a stack (handled above)
	if stack_key.is_empty():
		call_deferred("_deferred_refresh_ring", ring)
	call_deferred("update_ring_threat_levels")
	call_deferred("_cleanup_orphaned_mini_panels")


func _on_enemy_moved(enemy, from_ring: int, to_ring: int) -> void:  # enemy: EnemyInstance
	print("[BattlefieldArena DEBUG] ========== ENEMY MOVED SIGNAL ==========")
	print("[BattlefieldArena DEBUG] Enemy: ", enemy.enemy_id, " (instance_id: ", enemy.instance_id, ")")
	print("[BattlefieldArena DEBUG] From ring: ", from_ring, " -> To ring: ", to_ring)
	print("[BattlefieldArena DEBUG] Enemy current ring (from enemy.ring): ", enemy.ring)
	
	# Update group's ring if enemy is in a group
	# Check if all enemies in the group are now in the same ring, and update group.ring accordingly
	var enemy_has_group: bool = false
	if not enemy.group_id.is_empty() and enemy_groups.has(enemy.group_id):
		enemy_has_group = true
		var group: Dictionary = enemy_groups[enemy.group_id]
		var alive_enemies: Array = []
		for group_enemy in group.enemies:
			if group_enemy.is_alive():
				alive_enemies.append(group_enemy)
		
		# If all alive enemies in the group are in the same ring, update group.ring
		if not alive_enemies.is_empty():
			var first_ring: int = alive_enemies[0].ring
			var all_same_ring: bool = true
			for group_enemy in alive_enemies:
				if group_enemy.ring != first_ring:
					all_same_ring = false
					break
			
			if all_same_ring:
				group.ring = first_ring
				print("[BattlefieldArena DEBUG] Updated group ", enemy.group_id, " ring to ", first_ring)
	
	# If enemy is in a group, always refresh both rings to update group visuals
	# Otherwise, check if stacking state needs to change before doing a full refresh
	var from_needs_full_refresh: bool = _ring_stacking_changed(from_ring)
	var to_needs_full_refresh: bool = _ring_stacking_changed(to_ring)
	
	if enemy_has_group or from_needs_full_refresh or to_needs_full_refresh:
		# Enemy is in a group or stacking state changed - need full refresh but defer it to batch multiple moves
		print("[BattlefieldArena DEBUG] Enemy has group or stacking changed - deferring full refresh")
		call_deferred("_deferred_refresh_ring", from_ring)
		call_deferred("_deferred_refresh_ring", to_ring)
	else:
		# Just update the moved enemy's position - no stacking change
		print("[BattlefieldArena DEBUG] No stacking change - updating enemy position directly")
		if enemy_visuals.has(enemy.instance_id):
			_update_enemy_position(enemy)
		else:
			print("[BattlefieldArena DEBUG] WARNING - Enemy visual not found for instance_id: ", enemy.instance_id)
		# Also check for stack position updates
		var from_stack_key: String = _get_stack_key(from_ring, enemy.enemy_id)
		var to_stack_key: String = _get_stack_key(to_ring, enemy.enemy_id)
		if stack_visuals.has(from_stack_key):
			print("[BattlefieldArena DEBUG] Updating from_stack position: ", from_stack_key)
			_update_stack_position(from_stack_key)
		if stack_visuals.has(to_stack_key):
			print("[BattlefieldArena DEBUG] Updating to_stack position: ", to_stack_key)
			_update_stack_position(to_stack_key)
	
	call_deferred("update_ring_threat_levels")
	print("[BattlefieldArena DEBUG] ========== ENEMY MOVED HANDLER COMPLETE ==========")


func _on_enemy_damaged(enemy, amount: int) -> void:  # enemy: EnemyInstance
	"""Called when a specific enemy takes damage."""
	# Check if enemy is in a stack
	var stack_key: String = _get_stack_key_for_enemy(enemy)
	var is_in_stack: bool = not stack_key.is_empty() and stack_visuals.has(stack_key)
	
	# Check for hex trigger (purple flash) - hex was consumed if it's now 0
	var is_hex_trigger: bool = enemy.get_status_value("hex") == 0 and amount > 0
	var flash_color: Color = Color(0.8, 0.3, 1.0, 1.0) if is_hex_trigger else Color(1.5, 0.5, 0.5, 1.0)
	
	if is_in_stack:
		# Enemy is in a stack - show damage on the mini-card
		_show_damage_on_stacked_enemy(enemy, amount, stack_key, is_hex_trigger)
		# Add shake to stack
		_shake_stack(stack_key, min(5.0 + amount * 0.15, 10.0), 0.15)
	else:
		# Individual enemy - show floating damage number
		if enemy_visuals.has(enemy.instance_id):
			var visual: Panel = enemy_visuals[enemy.instance_id]
			
			# Show damage number floating above the enemy
			_show_damage_number_at_position(
				visual.position + Vector2(visual.size.x / 2 - 15, -15),
				amount,
				is_hex_trigger
			)
			
			# Update the enemy's HP display
			_update_enemy_hp_display(enemy, visual)
			
			# Flash the enemy to show damage (purple for hex, red for normal)
			var tween: Tween = create_tween()
			tween.tween_property(visual, "modulate", flash_color, 0.05)
			tween.tween_property(visual, "modulate", Color.WHITE, 0.15)
			
			# Add shake effect (faster)
			shake_enemy(enemy, min(6.0 + amount * 0.2, 12.0), 0.15)


func _on_weapon_triggered(card_name: String, _damage: int) -> void:
	"""Show visual feedback when a persistent weapon fires."""
	_show_weapon_trigger_effect(card_name)


func _show_weapon_trigger_effect(card_name: String) -> void:
	"""Show weapon fire visual - name label at center."""
	_recalculate_layout()
	
	# Show weapon name at warden
	var label: Label = Label.new()
	label.text = "🔫 " + card_name + " fires!"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	label.z_index = 60
	
	label.position = center + Vector2(-70, -70)
	
	damage_numbers.add_child(label)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)


func _on_turn_started_threat_update(_turn: int) -> void:
	"""Update ring threat levels at the start of each turn."""
	update_ring_threat_levels()
	# Update danger highlighting for all enemies (threat levels may have changed)
	_update_all_danger_highlights()


func _on_player_damaged(damage_amount: int, _source: String) -> void:
	_show_player_damage(damage_amount)


func _create_enemy_visual(enemy) -> void:  # enemy: EnemyInstance
	_recalculate_layout()
	
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	
	# Use a Panel as the base - it handles mouse events better
	var visual: Panel = Panel.new()
	var enemy_visual_size: Vector2 = _get_enemy_visual_size()
	var width: float = enemy_visual_size.x
	var height: float = enemy_visual_size.y
	visual.custom_minimum_size = enemy_visual_size
	visual.size = enemy_visual_size
	visual.mouse_filter = Control.MOUSE_FILTER_STOP
	# Set anchors to disable anchor-based positioning (use absolute positioning)
	# This prevents the position from resetting to (0,0) during layout updates
	visual.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Store enemy reference for hover
	visual.set_meta("enemy_instance", enemy)
	visual.set_meta("enemy_id", enemy.enemy_id)
	visual.set_meta("instance_id", enemy.instance_id)
	
	# Style the panel directly
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy.enemy_id, Color(0.8, 0.3, 0.3))
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.3, 0.35, 1.0)
	visual.add_theme_stylebox_override("panel", style)
	
	# Behavior badge (top-left corner)
	if enemy_def:
		var badge: Panel = _create_behavior_badge(enemy_def)
		badge.position = Vector2(4, 4)
		visual.add_child(badge)
	
	# Turn countdown badge (top-right corner) - large and prominent
	var countdown_badge: Panel = _create_turn_countdown_badge(enemy)
	countdown_badge.position = Vector2(width - 42, 2)
	visual.add_child(countdown_badge)
	
	# Enemy icon
	var icon_label: Label = Label.new()
	icon_label.position = Vector2((width - 30.0) * 0.5, 6.0)
	icon_label.size = Vector2(30, 30)
	icon_label.add_theme_font_size_override("font_size", 26)
	icon_label.text = "👤" if not enemy_def else enemy_def.display_icon
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(icon_label)
	
	# Damage indicator (shows how much damage this enemy deals)
	var damage_label: Label = Label.new()
	damage_label.name = "DamageLabel"
	damage_label.position = Vector2(0.0, height * 0.42)
	damage_label.size = Vector2(width, 20.0)
	damage_label.add_theme_font_size_override("font_size", 12)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if enemy_def:
		var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
		damage_label.text = "⚔ " + str(dmg)
	visual.add_child(damage_label)
	
	# HP bar background
	var hp_bg: ColorRect = ColorRect.new()
	hp_bg.position = Vector2(4.0, height * 0.68)
	hp_bg.size = Vector2(width - 8.0, 10.0)
	hp_bg.color = Color(0.1, 0.1, 0.1, 1.0)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(hp_bg)
	
	# HP bar fill
	var hp_fill: ColorRect = ColorRect.new()
	hp_fill.name = "HPFill"
	hp_fill.position = hp_bg.position
	hp_fill.size = hp_bg.size
	hp_fill.set_meta("max_width", hp_bg.size.x)
	hp_fill.color = Color(0.2, 0.85, 0.2, 1.0)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(hp_fill)
	
	# HP text
	var hp_text: Label = Label.new()
	hp_text.name = "HPText"
	hp_text.position = Vector2(0.0, height * 0.8)
	hp_text.size = Vector2(width, 18.0)
	hp_text.add_theme_font_size_override("font_size", 11)
	hp_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.text = str(enemy.current_hp)
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(hp_text)
	
	# Intent indicator for melee enemies
	if enemy_def and enemy.ring == 0:  # In melee range
		var intent: Label = Label.new()
		intent.name = "IntentIcon"
		intent.position = Vector2(width - 20.0, -10.0)
		intent.add_theme_font_size_override("font_size", 16)
		intent.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		intent.text = "⚔️"
		intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(intent)
	
	# Hex indicator (hidden by default, shown when hex applied)
	var hex_label: Label = Label.new()
	hex_label.name = "HexLabel"
	hex_label.position = Vector2(0.0, -12.0)
	hex_label.size = Vector2(width, 20.0)
	hex_label.add_theme_font_size_override("font_size", 12)
	hex_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0, 1.0))
	hex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hex_label.text = ""
	hex_label.visible = false
	hex_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(hex_label)
	
	# Connect hover signals
	visual.mouse_entered.connect(_on_enemy_hover_enter.bind(visual, enemy))
	visual.mouse_exited.connect(_on_enemy_hover_exit.bind(visual))
	
	enemy_container.add_child(visual)
	enemy_visuals[enemy.instance_id] = visual
	
	# Set initial position and update
	_update_enemy_position(enemy)
	_update_enemy_hp_display(enemy, visual)
	
	# Apply danger highlighting based on threat level
	_apply_danger_highlighting(visual, enemy, "enemy_" + str(enemy.instance_id))


func _remove_enemy_visual(enemy) -> void:  # enemy: EnemyInstance
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	# Kill any active position tween for this enemy
	if _enemy_position_tweens.has(enemy.instance_id):
		var old_tween: Tween = _enemy_position_tweens[enemy.instance_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		_enemy_position_tweens.erase(enemy.instance_id)
	
	# Kill any active scale tween for this enemy
	if _enemy_scale_tweens.has(enemy.instance_id):
		var old_tween: Tween = _enemy_scale_tweens[enemy.instance_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		_enemy_scale_tweens.erase(enemy.instance_id)
	
	# Stop and cleanup any debug timer
	if _enemy_debug_timers.has(enemy.instance_id):
		var debug_timer: Timer = _enemy_debug_timers[enemy.instance_id]
		if is_instance_valid(debug_timer):
			debug_timer.stop()
			debug_timer.queue_free()
		_enemy_debug_timers.erase(enemy.instance_id)
	
	# Clean up base position tracking
	_enemy_base_positions.erase(enemy.instance_id)
	
	# Clean up danger glow
	_remove_danger_glow("enemy_" + str(enemy.instance_id))
		
	var visual: Panel = enemy_visuals[enemy.instance_id]
	var death_pos: Vector2 = visual.global_position + visual.size / 2
	
	# Spawn death particles
	_spawn_death_particles(death_pos, ENEMY_COLORS.get(enemy.enemy_id, Color.RED))
	
	# Death animation
	var tween: Tween = create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.05)
	tween.tween_property(visual, "modulate", Color.RED, 0.1)
	tween.tween_property(visual, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(visual.queue_free)
	
	enemy_visuals.erase(enemy.instance_id)


func _spawn_death_particles(pos: Vector2, color: Color) -> void:
	for i: int in range(12):
		var particle: ColorRect = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = color
		particle.position = pos - particle.size / 2
		effects_container.add_child(particle)
		
		var dir: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var speed: float = randf_range(80, 180)
		var target_pos: Vector2 = particle.position + dir * speed
		
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_property(particle, "size", Vector2.ZERO, 0.5)
		tween.chain().tween_callback(particle.queue_free)


func _update_enemy_position(enemy) -> void:  # enemy: EnemyInstance
	if not enemy_visuals.has(enemy.instance_id):
		print("[BattlefieldArena DEBUG] _update_enemy_position - enemy visual not found for instance_id: ", enemy.instance_id)
		return
	
	_recalculate_layout()
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	var target_pos: Vector2 = _get_enemy_position(enemy)
	
	# Check if enemy is going to be in a stack (off-screen position means it's non-representative in a stack)
	# If so, skip individual position update - the stack refresh will handle it
	if target_pos.x < -500 or target_pos.y < -500:
		print("[BattlefieldArena DEBUG] ========== ENEMY POSITION UPDATE ==========")
		print("[BattlefieldArena DEBUG] Enemy: ", enemy.enemy_id, " (instance_id: ", enemy.instance_id, ")")
		print("[BattlefieldArena DEBUG] Ring: ", enemy.ring)
		print("[BattlefieldArena DEBUG] Target pos is off-screen (", target_pos, ") - enemy will be in stack, skipping individual update")
		return
	
	# Offset by half the visual size to center it
	target_pos -= visual.size / 2
	
	# Check if already at target position (within tolerance) - skip animation
	var current_base: Vector2 = _enemy_base_positions.get(enemy.instance_id, visual.position)
	var distance: float = current_base.distance_to(target_pos)
	
	print("[BattlefieldArena DEBUG] ========== ENEMY POSITION UPDATE ==========")
	print("[BattlefieldArena DEBUG] Enemy: ", enemy.enemy_id, " (instance_id: ", enemy.instance_id, ")")
	print("[BattlefieldArena DEBUG] Ring: ", enemy.ring)
	print("[BattlefieldArena DEBUG] Current base pos: ", current_base, " | Target pos: ", target_pos, " | Distance: ", distance)
	print("[BattlefieldArena DEBUG] Visual current pos: ", visual.position, " | Visual global pos: ", visual.global_position)
	
	if distance < 2.0:
		# Already at target, just ensure position is exact
		_enemy_base_positions[enemy.instance_id] = target_pos
		print("[BattlefieldArena DEBUG] Already at target - skipping animation")
		return
	
	# Store the base position for this enemy (used by shake animations)
	_enemy_base_positions[enemy.instance_id] = target_pos
	
	# Kill any existing position tween to prevent conflicts
	if _enemy_position_tweens.has(enemy.instance_id):
		var old_tween: Tween = _enemy_position_tweens[enemy.instance_id]
		if old_tween and old_tween.is_valid():
			print("[BattlefieldArena DEBUG] Killing existing tween for enemy instance_id: ", enemy.instance_id)
			old_tween.kill()
		else:
			print("[BattlefieldArena DEBUG] Existing tween found but invalid for instance_id: ", enemy.instance_id)
		_enemy_position_tweens.erase(enemy.instance_id)
	
	# Stop and cleanup any existing debug timer
	if _enemy_debug_timers.has(enemy.instance_id):
		var old_debug_timer: Timer = _enemy_debug_timers[enemy.instance_id]
		if is_instance_valid(old_debug_timer):
			old_debug_timer.stop()
			old_debug_timer.queue_free()
		_enemy_debug_timers.erase(enemy.instance_id)
	
	# Use the tracked base position as the starting point, not the visual's current position
	# This prevents jumping to (0,0) if the visual's position was reset during a refresh
	var start_pos: Vector2 = current_base
	if start_pos.distance_to(visual.position) > 10.0:
		# If the tracked position is very different from visual position, use visual position
		# This handles cases where the enemy was just created
		start_pos = visual.position
		_enemy_base_positions[enemy.instance_id] = start_pos
	
	# Set the visual's position to the start position before animating
	# This ensures we're animating from the correct starting point
	visual.position = start_pos
	
	# Animate movement - use simple ease out without bounce-back to avoid erratic motion
	var tween: Tween = create_tween()
	tween.tween_property(visual, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Track the tween
	_enemy_position_tweens[enemy.instance_id] = tween
	
	print("[BattlefieldArena DEBUG] Created new tween - animating from ", start_pos, " to ", target_pos)
	
	# Add debug tracking during animation
	var debug_timer: Timer = Timer.new()
	debug_timer.wait_time = 0.05
	debug_timer.set_meta("visual", visual)
	debug_timer.set_meta("tween", tween)
	debug_timer.set_meta("enemy_id", enemy.enemy_id)
	debug_timer.set_meta("target_pos", target_pos)
	debug_timer.set_meta("instance_id", enemy.instance_id)
	debug_timer.set_meta("frame_count", 0)
	debug_timer.timeout.connect(_on_enemy_move_debug_tick.bind(debug_timer))
	add_child(debug_timer)
	debug_timer.start()
	
	# Track the debug timer for cleanup
	_enemy_debug_timers[enemy.instance_id] = debug_timer
	
	tween.finished.connect(_on_enemy_move_tween_finished.bind(enemy.instance_id, target_pos, debug_timer))
	
	# Update HP display
	_update_enemy_hp_display(enemy, visual)
	
	# Update turn countdown badge (enemy moved to new ring)
	_update_turn_countdown_badge(visual, enemy)
	
	# Update danger highlighting (threat level may have changed)
	_apply_danger_highlighting(visual, enemy, "enemy_" + str(enemy.instance_id))


func _update_enemy_hp_display(enemy, visual: Panel) -> void:
	var hp_fill: ColorRect = visual.get_node_or_null("HPFill")
	var hp_text: Label = visual.get_node_or_null("HPText")
	
	if hp_fill:
		var hp_percent: float = enemy.get_hp_percentage()
		var max_width: float = float(hp_fill.get_meta("max_width", hp_fill.size.x))
		hp_fill.size.x = max_width * hp_percent
		hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	
	if hp_text:
		hp_text.text = str(enemy.current_hp)
	
	# Update hex indicator
	var hex_label: Label = visual.get_node_or_null("HexLabel")
	if hex_label:
		var hex_stacks: int = enemy.get_status_value("hex")
		if hex_stacks > 0:
			hex_label.text = "☠️ " + str(hex_stacks)
			hex_label.visible = true
		else:
			hex_label.visible = false
	
	# Update intent indicator based on ring
	var intent: Label = visual.get_node_or_null("IntentIcon")
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	
	if enemy_def:
		if intent == null and enemy.ring == 0:
			# Add attack intent for melee enemies
			intent = Label.new()
			intent.name = "IntentIcon"
			var panel_width: float = visual.custom_minimum_size.x
			intent.position = Vector2(panel_width - 20.0, -10.0)
			intent.add_theme_font_size_override("font_size", 16)
			intent.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			intent.text = "⚔️"
			intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
			visual.add_child(intent)
		elif intent and enemy.ring != 0:
			intent.queue_free()
		
		# Show movement intent if not at target ring
		if enemy.ring > enemy_def.target_ring:
			var move_intent: Label = visual.get_node_or_null("MoveIntent")
			if move_intent == null:
				move_intent = Label.new()
				move_intent.name = "MoveIntent"
				move_intent.position = Vector2(-8, -8)
				move_intent.add_theme_font_size_override("font_size", 16)
				move_intent.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
				move_intent.text = "→"
				move_intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
				visual.add_child(move_intent)


func _get_enemy_position(enemy) -> Vector2:  # enemy: EnemyInstance
	# Calculate ring boundaries
	var outer_radius: float = max_radius * RING_PROPORTIONS[enemy.ring]
	var inner_radius: float = 0.0
	if enemy.ring > 0:
		inner_radius = max_radius * RING_PROPORTIONS[enemy.ring - 1]
	
	var ring_depth: float = outer_radius - inner_radius
	
	# Get display info for this enemy (handles stacking logic)
	var display_info: Dictionary = _get_enemy_display_info(enemy)
	
	# If enemy is stacked and not the "representative", it won't be displayed individually
	if display_info.is_stacked and not display_info.is_representative:
		# Return off-screen position - this enemy is part of a stack
		return Vector2(-1000, -1000)
	
	# Calculate row radius based on multi-row distribution
	var row_ratio: float = 0.5  # Default middle
	if display_info.total_display_items > MAX_ENEMIES_BEFORE_MULTIROW:
		# Multi-row distribution
		if display_info.row == 0:
			row_ratio = INNER_ROW_RATIO
		else:
			row_ratio = OUTER_ROW_RATIO
	
	var ring_radius: float = inner_radius + ring_depth * row_ratio
	
	# Calculate angle position
	var angle_start: float = PI + PI * 0.12  # Start slightly past left
	var angle_end: float = 2 * PI - PI * 0.12  # End slightly before right
	var angle_spread: float = angle_end - angle_start
	
	var items_in_row: int = display_info.items_in_row
	var index_in_row: int = display_info.index_in_row
	
	var angle: float = angle_start + angle_spread / 2.0  # Default to center
	if items_in_row > 1:
		angle = angle_start + (angle_spread / float(items_in_row - 1)) * float(index_in_row)
	
	return center + Vector2(cos(angle), sin(angle)) * ring_radius


func _get_enemy_display_info(enemy) -> Dictionary:
	"""
	Calculate display information for an enemy, including multi-row and stacking logic.
	Returns: {
		row: int (0=inner, 1=outer),
		index_in_row: int,
		items_in_row: int,
		total_display_items: int,
		is_stacked: bool,
		is_representative: bool (if stacked, is this the one we show?)
	}
	"""
	var result: Dictionary = {
		"row": 0,
		"index_in_row": 0,
		"items_in_row": 1,
		"total_display_items": 1,
		"is_stacked": false,
		"is_representative": true
	}
	
	if not CombatManager.battlefield:
		return result
	
	var enemies_in_ring: Array = CombatManager.battlefield.get_enemies_in_ring(enemy.ring)
	var total_count: int = enemies_in_ring.size()
	
	# Group enemies by type for potential stacking
	var groups: Dictionary = _get_enemy_groups_in_ring(enemy.ring)
	
	# Determine if we need stacking (ring is crowded + same-type groups exist)
	var need_stacking: bool = total_count > MAX_TOTAL_BEFORE_STACKING
	
	# Build display list: either individual enemies or stack representatives
	var display_items: Array = []  # Array of {enemy: enemy, is_stack: bool, stack_count: int}
	
	if need_stacking:
		var processed_types: Dictionary = {}
		for e in enemies_in_ring:
			var etype: String = e.enemy_id
			if processed_types.has(etype):
				continue
			
			var group: Array = groups.get(etype, [])
			if group.size() >= STACK_THRESHOLD:
				# This type forms a stack - only add first enemy as representative
				display_items.append({
					"enemy": group[0],
					"is_stack": true,
					"stack_count": group.size(),
					"stack_enemies": group
				})
				processed_types[etype] = true
			else:
				# Show each enemy individually
				for individual in group:
					display_items.append({
						"enemy": individual,
						"is_stack": false,
						"stack_count": 1,
						"stack_enemies": [individual]
					})
				processed_types[etype] = true
	else:
		# No stacking needed - all enemies shown individually
		for e in enemies_in_ring:
			display_items.append({
				"enemy": e,
				"is_stack": false,
				"stack_count": 1,
				"stack_enemies": [e]
			})
	
	result.total_display_items = display_items.size()
	
	# Find this enemy's position in display_items
	var display_index: int = -1
	for i: int in range(display_items.size()):
		var item: Dictionary = display_items[i]
		if item.is_stack:
			# Check if enemy is in this stack
			for se in item.stack_enemies:
				if se.instance_id == enemy.instance_id:
					if se.instance_id == item.enemy.instance_id:
						# This is the representative
						display_index = i
						result.is_stacked = true
						result.is_representative = true
					else:
						# Part of stack but not representative
						result.is_stacked = true
						result.is_representative = false
						return result
					break
		else:
			if item.enemy.instance_id == enemy.instance_id:
				display_index = i
				break
	
	if display_index < 0:
		return result
	
	# Calculate row distribution
	if result.total_display_items <= MAX_ENEMIES_BEFORE_MULTIROW:
		# Single row
		result.row = 0
		result.index_in_row = display_index
		result.items_in_row = result.total_display_items
	else:
		# Multi-row: distribute evenly between inner and outer rows
		var outer_count: int = (result.total_display_items + 1) / 2  # Outer row gets more/equal
		var inner_count: int = result.total_display_items - outer_count
		
		if display_index < inner_count:
			result.row = 0  # Inner row
			result.index_in_row = display_index
			result.items_in_row = inner_count
		else:
			result.row = 1  # Outer row
			result.index_in_row = display_index - inner_count
			result.items_in_row = outer_count
	
	return result


func _get_enemy_visual_size(is_mini_size: bool = false) -> Vector2:
	var shortest_side: float = min(size.x, size.y)
	if shortest_side <= 0.0:
		return Vector2(100.0, 130.0) if not is_mini_size else Vector2(50.0, 65.0)
	
	if is_mini_size:
		# Smaller size for expanded stack mini-panels
		var width: float = clamp(shortest_side * 0.08, 50.0, 100.0)
		var height: float = clamp(width * 1.25, 60.0, 125.0)
		return Vector2(width, height)
	else:
		var width: float = clamp(shortest_side * 0.14, 90.0, 180.0)
		var height: float = clamp(width * 1.25, 110.0, 220.0)
		return Vector2(width, height)


func _create_behavior_badge(enemy_def, is_mini_badge: bool = false) -> Panel:
	"""Create a behavior badge showing the enemy's archetype icon."""
	var badge_size: float = 20.0 if not is_mini_badge else 14.0
	var font_size: int = 12 if not is_mini_badge else 9
	
	var badge: Panel = Panel.new()
	badge.custom_minimum_size = Vector2(badge_size, badge_size)
	badge.size = Vector2(badge_size, badge_size)
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	badge.z_index = 5
	
	# Style the badge with the behavior color
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	var badge_color: Color = enemy_def.get_behavior_badge_color()
	badge_style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	badge_style.set_corner_radius_all(int(badge_size / 2))
	badge_style.set_border_width_all(2)
	badge_style.border_color = badge_color
	badge.add_theme_stylebox_override("panel", badge_style)
	
	# Badge icon
	var badge_label: Label = Label.new()
	badge_label.text = enemy_def.get_behavior_badge_icon()
	badge_label.add_theme_font_size_override("font_size", font_size)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.position = Vector2(0, 0)
	badge_label.size = Vector2(badge_size, badge_size)
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_label)
	
	# Store tooltip text
	badge.set_meta("tooltip_text", enemy_def.get_behavior_tooltip())
	
	return badge


func _create_turn_countdown_badge(enemy, is_mini_badge: bool = false) -> Panel:
	"""Create a large, prominent badge showing turns until enemy reaches melee."""
	var turns: int = enemy.get_turns_until_melee()
	
	# MUCH larger badge sizes for visibility
	var badge_width: float = 38.0 if not is_mini_badge else 26.0
	var badge_height: float = 22.0 if not is_mini_badge else 16.0
	var font_size: int = 14 if not is_mini_badge else 11
	
	var badge: Panel = Panel.new()
	badge.name = "TurnCountdown"
	badge.custom_minimum_size = Vector2(badge_width, badge_height)
	badge.size = Vector2(badge_width, badge_height)
	badge.mouse_filter = Control.MOUSE_FILTER_PASS
	badge.z_index = 10  # Higher z-index to be on top
	
	# Determine badge color and background based on turns
	var badge_color: Color
	var bg_color: Color
	var badge_text: String
	var tooltip_text: String
	
	if turns == 0:
		# In melee - attacking! CRITICAL
		badge_color = Color(1.0, 1.0, 1.0)  # White text for contrast
		bg_color = Color(0.9, 0.2, 0.2, 0.95)  # Solid red background
		badge_text = "⚔️ 0"
		tooltip_text = "IN MELEE - Attacks this turn!"
	elif turns == -1:
		# Won't reach melee (ranged)
		badge_color = Color(0.9, 0.95, 1.0)  # Light blue text
		bg_color = Color(0.2, 0.35, 0.6, 0.9)  # Blue background
		badge_text = "🏹"
		tooltip_text = "RANGED - Won't advance to melee"
	elif turns == 1:
		# Arrives next turn - URGENT!
		badge_color = Color(1.0, 1.0, 1.0)  # White text
		bg_color = Color(0.9, 0.5, 0.1, 0.95)  # Orange background
		badge_text = "⚠️ 1"
		tooltip_text = "DANGER - Reaches melee NEXT turn!"
	elif turns == 2:
		# Coming soon - warning
		badge_color = Color(0.1, 0.1, 0.1)  # Dark text
		bg_color = Color(1.0, 0.85, 0.2, 0.9)  # Yellow background
		badge_text = "→ 2"
		tooltip_text = "WARNING - Reaches melee in 2 turns"
	else:
		# Further away - safe for now
		badge_color = Color(1.0, 1.0, 1.0)  # White text
		bg_color = Color(0.25, 0.55, 0.3, 0.85)  # Green background
		badge_text = "→ " + str(turns)
		tooltip_text = "Safe - Reaches melee in " + str(turns) + " turns"
	
	# Style the badge with solid colored background for maximum visibility
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = bg_color
	badge_style.set_corner_radius_all(6)
	badge_style.set_border_width_all(2)
	badge_style.border_color = Color(0.0, 0.0, 0.0, 0.8)  # Dark border for contrast
	# Add shadow effect for depth
	badge_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	badge_style.shadow_size = 2
	badge_style.shadow_offset = Vector2(1, 1)
	badge.add_theme_stylebox_override("panel", badge_style)
	
	# Badge text - larger and bold
	var badge_label: Label = Label.new()
	badge_label.name = "TurnLabel"
	badge_label.text = badge_text
	badge_label.add_theme_font_size_override("font_size", font_size)
	badge_label.add_theme_color_override("font_color", badge_color)
	# Add text outline for better readability
	badge_label.add_theme_constant_override("outline_size", 2)
	badge_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.7))
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.position = Vector2(0, 0)
	badge_label.size = Vector2(badge_width, badge_height)
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_label)
	
	# Store tooltip
	badge.set_meta("tooltip_text", tooltip_text)
	
	return badge


func _update_turn_countdown_badge(visual: Panel, enemy) -> void:
	"""Update the turn countdown badge for an enemy panel."""
	var countdown: Panel = visual.get_node_or_null("TurnCountdown")
	if not countdown:
		return
	
	var turns: int = enemy.get_turns_until_melee()
	var turn_label: Label = countdown.get_node_or_null("TurnLabel")
	if not turn_label:
		return
	
	# Update text, colors, and background (matching create function)
	var badge_color: Color
	var bg_color: Color
	var badge_text: String
	var tooltip_text: String
	
	if turns == 0:
		badge_color = Color(1.0, 1.0, 1.0)
		bg_color = Color(0.9, 0.2, 0.2, 0.95)
		badge_text = "⚔️ 0"
		tooltip_text = "IN MELEE - Attacks this turn!"
	elif turns == -1:
		badge_color = Color(0.9, 0.95, 1.0)
		bg_color = Color(0.2, 0.35, 0.6, 0.9)
		badge_text = "🏹"
		tooltip_text = "RANGED - Won't advance to melee"
	elif turns == 1:
		badge_color = Color(1.0, 1.0, 1.0)
		bg_color = Color(0.9, 0.5, 0.1, 0.95)
		badge_text = "⚠️ 1"
		tooltip_text = "DANGER - Reaches melee NEXT turn!"
	elif turns == 2:
		badge_color = Color(0.1, 0.1, 0.1)
		bg_color = Color(1.0, 0.85, 0.2, 0.9)
		badge_text = "→ 2"
		tooltip_text = "WARNING - Reaches melee in 2 turns"
	else:
		badge_color = Color(1.0, 1.0, 1.0)
		bg_color = Color(0.25, 0.55, 0.3, 0.85)
		badge_text = "→ " + str(turns)
		tooltip_text = "Safe - Reaches melee in " + str(turns) + " turns"
	
	turn_label.text = badge_text
	turn_label.add_theme_color_override("font_color", badge_color)
	
	# Update background and border color
	var new_style: StyleBoxFlat = StyleBoxFlat.new()
	new_style.bg_color = bg_color
	new_style.set_corner_radius_all(6)
	new_style.set_border_width_all(2)
	new_style.border_color = Color(0.0, 0.0, 0.0, 0.8)
	new_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	new_style.shadow_size = 2
	new_style.shadow_offset = Vector2(1, 1)
	countdown.add_theme_stylebox_override("panel", new_style)
	
	countdown.set_meta("tooltip_text", tooltip_text)


# ============== DANGER HIGHLIGHTING SYSTEM ==============

func _get_enemy_danger_level(enemy) -> DangerLevel:
	"""Calculate the danger level for an enemy based on threat priority."""
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	if not enemy_def:
		return DangerLevel.NONE
	
	var turns_until_melee: int = enemy.get_turns_until_melee()
	
	# CRITICAL: Bomber about to explode (in melee or reaching next turn)
	if enemy_def.behavior_type == EnemyDefinition.BehaviorType.BOMBER:
		if enemy.ring == 0 or turns_until_melee == 1:
			return DangerLevel.CRITICAL
	
	# CRITICAL: Any enemy IN melee right now (attacking this turn!)
	if enemy.ring == 0 and turns_until_melee == 0:
		return DangerLevel.CRITICAL
	
	# HIGH: Any enemy reaching melee next turn (1 turn away)
	if turns_until_melee == 1:
		return DangerLevel.HIGH
	
	# MEDIUM: Active buffer or spawner at their target ring
	if enemy_def.behavior_type == EnemyDefinition.BehaviorType.BUFFER:
		if enemy.ring <= enemy_def.target_ring:
			return DangerLevel.MEDIUM
	if enemy_def.behavior_type == EnemyDefinition.BehaviorType.SPAWNER:
		if enemy.ring <= enemy_def.target_ring:
			return DangerLevel.MEDIUM
	
	# LOW: Fast enemies (speed 2+) not yet close
	if enemy_def.movement_speed >= 2 and enemy.ring >= 2:
		return DangerLevel.LOW
	
	return DangerLevel.NONE


func _apply_danger_highlighting(visual: Panel, enemy, key: String) -> void:
	"""Apply danger highlighting by modifying the enemy panel's border directly."""
	var danger_level: DangerLevel = _get_enemy_danger_level(enemy)
	
	# Clean up existing pulse if danger level is NONE
	if danger_level == DangerLevel.NONE:
		_remove_danger_glow(key)
		# Reset to default border
		_reset_panel_style(visual, enemy.enemy_id)
		return
	
	var glow_color: Color = DANGER_GLOW_COLORS[danger_level]
	
	# Apply danger style directly to the enemy panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy.enemy_id, Color(0.8, 0.3, 0.3))
	style.set_corner_radius_all(8)
	style.set_border_width_all(4)  # Thicker danger border
	style.border_color = glow_color
	# Add shadow for glow effect
	style.shadow_color = glow_color
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 0)
	visual.add_theme_stylebox_override("panel", style)
	
	# Store that this panel has danger highlighting
	_danger_glow_panels[key] = visual
	
	# Start or restart the pulsing animation on the panel itself
	_start_danger_pulse(key, visual, glow_color, danger_level)


func _reset_panel_style(visual: Panel, enemy_id: String) -> void:
	"""Reset panel to default style (no danger)."""
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.3, 0.35, 1.0)
	visual.add_theme_stylebox_override("panel", style)
	# Reset modulate to normal
	visual.modulate = Color.WHITE


func _start_danger_pulse(key: String, panel: Panel, _glow_color: Color, danger_level: DangerLevel) -> void:
	"""Start or restart a subtle pulsing animation on the panel's modulate."""
	# Kill existing tween
	if _danger_glow_tweens.has(key):
		var old_tween: Tween = _danger_glow_tweens[key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		_danger_glow_tweens.erase(key)
	
	if not is_instance_valid(panel):
		return
	
	# Pulse speed based on danger level (faster = more urgent)
	var pulse_duration: float
	match danger_level:
		DangerLevel.CRITICAL:
			pulse_duration = 0.5  # Fast pulse for critical
		DangerLevel.HIGH:
			pulse_duration = 0.7
		DangerLevel.MEDIUM:
			pulse_duration = 0.9
		_:
			pulse_duration = 1.1
	
	# Create looping pulse tween on the panel's modulate property
	# SUBTLE pulse - just a slight brightness variation
	var tween: Tween = panel.create_tween()
	tween.set_loops()
	# Very subtle brightness pulse (1.08 to 0.95 = only 0.13 swing)
	tween.tween_property(panel, "modulate", Color(1.08, 1.08, 1.08, 1.0), pulse_duration * 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(panel, "modulate", Color(0.95, 0.95, 0.95, 1.0), pulse_duration * 0.5).set_ease(Tween.EASE_IN_OUT)
	
	_danger_glow_tweens[key] = tween


func _remove_danger_glow(key: String) -> void:
	"""Remove danger highlighting from an enemy panel."""
	# Kill tween
	if _danger_glow_tweens.has(key):
		var tween: Tween = _danger_glow_tweens[key]
		if tween and tween.is_valid():
			tween.kill()
		_danger_glow_tweens.erase(key)
	
	# Remove from tracking (panel itself is NOT freed - it's the enemy panel)
	_danger_glow_panels.erase(key)


func _update_all_danger_highlights() -> void:
	"""Update danger highlighting for all visible enemies."""
	# Update individual enemy panels
	for instance_id: int in enemy_visuals.keys():
		var visual: Panel = enemy_visuals[instance_id]
		if not is_instance_valid(visual):
			continue
		var enemy = visual.get_meta("enemy_instance", null)
		if enemy:
			_apply_danger_highlighting(visual, enemy, "enemy_" + str(instance_id))
	
	# Update stack panels
	for stack_key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[stack_key]
		var panel: Panel = stack_data.panel
		if not is_instance_valid(panel):
			continue
		var enemies: Array = stack_data.enemies
		if enemies.size() > 0:
			# Use highest danger level among stacked enemies
			var highest_danger: DangerLevel = DangerLevel.NONE
			var representative_enemy = null
			for enemy in enemies:
				var danger: DangerLevel = _get_enemy_danger_level(enemy)
				if danger > highest_danger:
					highest_danger = danger
					representative_enemy = enemy
			if representative_enemy:
				_apply_danger_highlighting(panel, representative_enemy, "stack_" + stack_key)


func _generate_group_id() -> String:
	"""Generate a unique group ID."""
	_next_group_id += 1
	return "group_" + str(_next_group_id)


func _create_enemy_group(ring: int, enemy_id: String, enemies: Array) -> String:
	"""Create a new persistent group and assign enemies to it."""
	var group_id: String = _generate_group_id()
	enemy_groups[group_id] = {
		"ring": ring,
		"enemy_id": enemy_id,
		"enemies": enemies
	}
	
	# Assign group_id to all enemies in the group
	for enemy in enemies:
		enemy.group_id = group_id
	
	return group_id


func _add_enemy_to_group(enemy, group_id: String) -> void:
	"""Add an enemy to an existing group."""
	if not enemy_groups.has(group_id):
		push_error("[BattlefieldArena] Cannot add enemy to non-existent group: " + group_id)
		return
	
	enemy.group_id = group_id
	enemy_groups[group_id].enemies.append(enemy)


func _remove_enemy_from_group(enemy) -> void:
	"""Remove an enemy from its group when killed. Group stays intact even if empty."""
	if enemy.group_id.is_empty():
		return
	
	var group_id: String = enemy.group_id
	if not enemy_groups.has(group_id):
		return
	
	var group: Dictionary = enemy_groups[group_id]
	var enemies: Array = group.enemies
	
	# Remove enemy from group's enemy list, but keep the group
	enemies.erase(enemy)
	
	# Clear enemy's group_id
	enemy.group_id = ""


func _get_enemy_groups_in_ring(ring: int) -> Dictionary:
	"""
	Get persistent groups in a ring.
	Returns: Dictionary { group_id: {ring: int, enemy_id: String, enemies: Array} }
	"""
	var groups: Dictionary = {}
	
	for group_id: String in enemy_groups.keys():
		var group: Dictionary = enemy_groups[group_id]
		# Check enemies' current rings instead of stored group.ring
		# This ensures groups are found even after enemies move
		var alive_enemies_in_ring: Array = []
		for enemy in group.enemies:
			if enemy.is_alive() and enemy.ring == ring:
				alive_enemies_in_ring.append(enemy)
		
		# Include group if it has at least one alive enemy in this ring
		if not alive_enemies_in_ring.is_empty():
			groups[group_id] = {
				"ring": ring,  # Use current ring, not stored group.ring
				"enemy_id": group.enemy_id,
				"enemies": alive_enemies_in_ring
			}
	
	return groups


func _get_persistent_groups_by_type(ring: int) -> Dictionary:
	"""
	Get persistent groups grouped by enemy type for display purposes.
	Returns: Dictionary { enemy_id: Array[Dictionary] } where each dict is a group
	"""
	var result: Dictionary = {}
	
	var groups: Dictionary = _get_enemy_groups_in_ring(ring)
	for group_id: String in groups.keys():
		var group: Dictionary = groups[group_id]
		var enemy_id: String = group.enemy_id
		
		if not result.has(enemy_id):
			result[enemy_id] = []
		
		result[enemy_id].append(group)
	
	return result


func _should_stack_in_ring(ring: int) -> bool:
	"""Check if stacking should be applied in this ring."""
	if not CombatManager.battlefield:
		return false
	
	var total: int = CombatManager.battlefield.get_enemies_in_ring(ring).size()
	return total > MAX_TOTAL_BEFORE_STACKING


func _ring_stacking_changed(ring: int) -> bool:
	"""Check if the stacking state of a ring has changed (needs full refresh)."""
	if not CombatManager.battlefield:
		return false
	
	var should_stack: bool = _should_stack_in_ring(ring)
	var has_stacks: bool = false
	
	# Check if any stacks exist for this ring
	for key: String in stack_visuals.keys():
		if key.begins_with(str(ring) + "_"):
			has_stacks = true
			break
	
	# If stacking state changed, need full refresh
	return should_stack != has_stacks


# Track which rings have pending deferred refreshes to avoid duplicates
var _pending_ring_refreshes: Dictionary = {}


func _deferred_refresh_ring(ring: int) -> void:
	"""Deferred refresh of a ring to batch multiple calls in one frame."""
	# Check if we already have a pending refresh for this ring this frame
	var frame: int = Engine.get_process_frames()
	var key: String = str(ring) + "_" + str(frame)
	
	if _pending_ring_refreshes.has(key):
		return  # Already scheduled for this frame
	
	_pending_ring_refreshes[key] = true
	_refresh_ring_visuals(ring)
	
	# Clean up old frame entries (keep dictionary from growing forever)
	var keys_to_remove: Array = []
	for k: String in _pending_ring_refreshes.keys():
		if not k.ends_with("_" + str(frame)):
			keys_to_remove.append(k)
	for k: String in keys_to_remove:
		_pending_ring_refreshes.erase(k)


func _get_stack_key(ring: int, enemy_id: String) -> String:
	"""Generate unique key for a stack."""
	return str(ring) + "_" + enemy_id


func _get_stack_key_for_enemy(enemy) -> String:
	"""Get the stack key for an enemy based on its group, searching stack_visuals."""
	# First check if enemy is in a persistent group
	if not enemy.group_id.is_empty() and enemy_groups.has(enemy.group_id):
		var group: Dictionary = enemy_groups[enemy.group_id]
		var group_key: String = str(group.ring) + "_" + group.enemy_id + "_" + enemy.group_id
		# Check if this stack exists
		if stack_visuals.has(group_key):
			return group_key
	
	# Search through existing stacks to find which one contains this enemy
	for stack_key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[stack_key]
		if stack_data.has("enemies"):
			for stacked_enemy in stack_data.enemies:
				if stacked_enemy.instance_id == enemy.instance_id:
					return stack_key
	
	# Fallback - return empty string (enemy is not in a stack)
	return ""


func _refresh_ring_visuals(ring: int) -> void:
	"""Refresh all enemy visuals in a ring, using persistent groups."""
	if not CombatManager.battlefield:
		return
	
	var enemies_in_ring: Array = CombatManager.battlefield.get_enemies_in_ring(ring)
	var persistent_groups: Dictionary = _get_enemy_groups_in_ring(ring)
	
	# Track which enemies are in groups
	var enemies_in_groups: Dictionary = {}  # instance_id -> true
	
	# PRESERVE old positions before clearing stacks - these will be used as starting positions
	# for new panels to avoid flying from (0,0)
	var preserved_positions: Dictionary = {}  # stack_key -> Vector2
	
	# Clear existing stacks for this ring (including mini-panels!)
	var keys_to_remove: Array = []
	for key: String in stack_visuals.keys():
		if key.begins_with(str(ring) + "_"):
			var stack_data: Dictionary = stack_visuals[key]
			
			# Preserve the position of the stack panel before destroying it
			if _stack_base_positions.has(key):
				preserved_positions[key] = _stack_base_positions[key]
			elif stack_data.has("panel") and is_instance_valid(stack_data.panel):
				preserved_positions[key] = stack_data.panel.position
			
			# Kill any active position tween for this stack
			if _stack_position_tweens.has(key):
				var old_tween: Tween = _stack_position_tweens[key]
				if old_tween and old_tween.is_valid():
					old_tween.kill()
				_stack_position_tweens.erase(key)
			# Kill any active scale tween for this stack
			if _stack_scale_tweens.has(key):
				var old_tween: Tween = _stack_scale_tweens[key]
				if old_tween and old_tween.is_valid():
					old_tween.kill()
				_stack_scale_tweens.erase(key)
			# DON'T erase base position tracking yet - we preserved it above
			_stack_base_positions.erase(key)
			# Clean up mini-panels first
			if stack_data.has("mini_panels"):
				for mini_panel in stack_data.mini_panels:
					if is_instance_valid(mini_panel):
						mini_panel.queue_free()
				stack_data.mini_panels.clear()
			# Then clean up main panel
			if stack_data.has("panel") and is_instance_valid(stack_data.panel):
				stack_data.panel.queue_free()
			keys_to_remove.append(key)
	for key: String in keys_to_remove:
		stack_visuals.erase(key)
	
	# Show all persistent groups as stacks (even if only 1 enemy)
	for group_id: String in persistent_groups.keys():
		var group: Dictionary = persistent_groups[group_id]
		var group_enemies: Array = group.enemies
		var enemy_id: String = group.enemy_id
		
		if not group_enemies.is_empty():
			# Create/update stack visual for this group (even if size 1)
			# Use a unique key that includes group_id to handle multiple groups of same type
			var stack_key: String = str(ring) + "_" + enemy_id + "_" + group_id
			
			# Restore preserved position so new panel starts from old position
			if preserved_positions.has(stack_key):
				_stack_base_positions[stack_key] = preserved_positions[stack_key]
			
			_create_stack_visual_for_group(ring, enemy_id, group_enemies, stack_key)
			
			# Hide individual visuals for stacked enemies
			for grouped_enemy in group_enemies:
				enemies_in_groups[grouped_enemy.instance_id] = true
				if enemy_visuals.has(grouped_enemy.instance_id):
					var visual: Panel = enemy_visuals[grouped_enemy.instance_id]
					visual.visible = false
	
	# Show ungrouped enemies individually
	for enemy in enemies_in_ring:
		if not enemies_in_groups.has(enemy.instance_id):
			if not enemy_visuals.has(enemy.instance_id):
				_create_enemy_visual(enemy)
			else:
				enemy_visuals[enemy.instance_id].visible = true
			_update_enemy_position(enemy)


func _create_stack_visual_for_group(ring: int, enemy_id: String, enemies: Array, stack_key: String) -> void:
	"""Create a stack visual for a persistent group using the provided stack_key."""
	if enemies.is_empty():
		return
	_create_stack_visual(ring, enemy_id, enemies, stack_key)


func _create_stack_visual(ring: int, enemy_id: String, enemies: Array, stack_key: String = "") -> void:
	"""Create a collapsed stack panel representing multiple enemies."""
	if enemies.is_empty():
		return
	
	if stack_key.is_empty():
		stack_key = _get_stack_key(ring, enemy_id)
	var _representative = enemies[0]  # Kept for potential future use
	var enemy_def = EnemyDatabase.get_enemy(enemy_id)
	
	# Create stack panel
	var panel: Panel = Panel.new()
	var visual_size: Vector2 = _get_enemy_visual_size()
	panel.custom_minimum_size = visual_size
	panel.size = visual_size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# Set anchors to disable anchor-based positioning (use absolute positioning)
	# This prevents the position from resetting to (0,0) during layout updates
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Store stack data
	panel.set_meta("is_stack", true)
	panel.set_meta("stack_key", stack_key)
	panel.set_meta("enemy_id", enemy_id)
	panel.set_meta("ring", ring)
	
	# Style the panel with a slightly different border to indicate stack
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	style.border_color = Color(1.0, 0.85, 0.4, 0.9)  # Gold border for stacks
	panel.add_theme_stylebox_override("panel", style)
	
	var width: float = visual_size.x
	var height: float = visual_size.y
	
	# Behavior badge (top-left corner)
	if enemy_def:
		var badge: Panel = _create_behavior_badge(enemy_def)
		badge.position = Vector2(4, 4)
		panel.add_child(badge)
	
	# Turn countdown badge (below behavior badge on left side) - large and prominent
	# Use first enemy in stack since they're all at same position
	var countdown_badge: Panel = _create_turn_countdown_badge(enemies[0])
	countdown_badge.position = Vector2(2, 26)
	panel.add_child(countdown_badge)
	
	# Enemy icon
	var icon_label: Label = Label.new()
	icon_label.position = Vector2((width - 30.0) * 0.5, 4.0)
	icon_label.size = Vector2(30, 30)
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.text = "👤" if not enemy_def else enemy_def.display_icon
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon_label)
	
	# Stack count badge
	var count_badge: Panel = Panel.new()
	count_badge.name = "CountBadge"
	count_badge.custom_minimum_size = Vector2(28, 22)
	count_badge.size = Vector2(28, 22)
	count_badge.position = Vector2(width - 32, 2)
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.9, 0.2, 0.2, 1.0)
	badge_style.set_corner_radius_all(6)
	count_badge.add_theme_stylebox_override("panel", badge_style)
	count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(count_badge)
	
	var count_label: Label = Label.new()
	count_label.name = "CountLabel"
	count_label.text = "x" + str(enemies.size())
	count_label.position = Vector2(0, 1)
	count_label.size = Vector2(28, 20)
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_badge.add_child(count_label)
	
	# Aggregate damage indicator
	var damage_label: Label = Label.new()
	damage_label.name = "DamageLabel"
	damage_label.position = Vector2(0.0, height * 0.38)
	damage_label.size = Vector2(width, 20.0)
	damage_label.add_theme_font_size_override("font_size", 12)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if enemy_def:
		var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
		damage_label.text = "⚔ " + str(dmg) + " each"
	panel.add_child(damage_label)
	
	# HP bar background (aggregate)
	var hp_bg: ColorRect = ColorRect.new()
	hp_bg.position = Vector2(4.0, height * 0.58)
	hp_bg.size = Vector2(width - 8.0, 10.0)
	hp_bg.color = Color(0.1, 0.1, 0.1, 1.0)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hp_bg)
	
	# Calculate aggregate HP
	var total_hp: int = 0
	var total_max_hp: int = 0
	for e in enemies:
		total_hp += e.current_hp
		total_max_hp += e.max_hp
	
	# HP bar fill (aggregate)
	var hp_fill: ColorRect = ColorRect.new()
	hp_fill.name = "HPFill"
	hp_fill.position = hp_bg.position
	var hp_percent: float = float(total_hp) / float(total_max_hp) if total_max_hp > 0 else 1.0
	hp_fill.size = Vector2(hp_bg.size.x * hp_percent, hp_bg.size.y)
	hp_fill.set_meta("max_width", hp_bg.size.x)
	hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hp_fill)
	
	# HP text (aggregate)
	var hp_text: Label = Label.new()
	hp_text.name = "HPText"
	hp_text.position = Vector2(0.0, height * 0.72)
	hp_text.size = Vector2(width, 18.0)
	hp_text.add_theme_font_size_override("font_size", 11)
	hp_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.text = str(total_hp) + "/" + str(total_max_hp) + " total"
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hp_text)
	
	# Enemy type name
	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(0.0, height * 0.86)
	name_label.size = Vector2(width, 18.0)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = enemy_id if not enemy_def else enemy_def.enemy_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_label)
	
	# Connect hover signals for expand behavior
	panel.mouse_entered.connect(_on_stack_hover_enter.bind(panel, stack_key))
	panel.mouse_exited.connect(_on_stack_hover_exit.bind(panel, stack_key))
	
	enemy_container.add_child(panel)
	
	# Store stack data
	stack_visuals[stack_key] = {
		"panel": panel,
		"enemies": enemies,
		"expanded": false,
		"mini_panels": []
	}
	
	# Position the stack
	_update_stack_position(stack_key)
	
	# Apply danger highlighting based on highest threat in stack
	if enemies.size() > 0:
		# Find enemy with highest danger level
		var highest_danger: DangerLevel = DangerLevel.NONE
		var most_dangerous_enemy = enemies[0]
		for enemy in enemies:
			var danger: DangerLevel = _get_enemy_danger_level(enemy)
			if danger > highest_danger:
				highest_danger = danger
				most_dangerous_enemy = enemy
		_apply_danger_highlighting(panel, most_dangerous_enemy, "stack_" + stack_key)


func _update_stack_position(stack_key: String) -> void:
	"""Update position of a stack panel."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	if stack_data.enemies.is_empty():
		return
	
	var representative = stack_data.enemies[0]
	var panel: Panel = stack_data.panel
	
	# Use representative's position
	var target_pos: Vector2 = _get_enemy_position(representative)
	target_pos -= panel.size / 2
	
	# Get the starting position - use stored base position, or current panel position
	# This prevents flying from (0,0) when panel is newly created
	var start_pos: Vector2 = _stack_base_positions.get(stack_key, panel.position)
	
	# If panel is at (0,0) but we have a stored position, use the stored position
	# This handles the case where panel was just created and hasn't been positioned yet
	if panel.position.length() < 1.0 and start_pos.length() > 1.0:
		panel.position = start_pos
	elif start_pos.length() < 1.0 and panel.position.length() > 1.0:
		start_pos = panel.position
	
	# Check if already at target position (within tolerance) - skip animation
	if start_pos.distance_to(target_pos) < 2.0:
		# Already at target, just ensure position is exact
		panel.position = target_pos
		_stack_base_positions[stack_key] = target_pos
		return
	
	# Set panel to start position before animating (in case it's at 0,0)
	panel.position = start_pos
	
	# Store the TARGET base position for this stack (used by shake animations)
	_stack_base_positions[stack_key] = target_pos
	
	# Kill any existing position tween to prevent conflicts
	if _stack_position_tweens.has(stack_key):
		var old_tween: Tween = _stack_position_tweens[stack_key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Animate movement - use simple ease out without bounce-back
	var tween: Tween = create_tween()
	tween.tween_property(panel, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Track the tween
	_stack_position_tweens[stack_key] = tween


func _update_stack_hp_display(stack_key: String) -> void:
	"""Update HP display for a stack."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var panel: Panel = stack_data.panel
	var enemies: Array = stack_data.enemies
	
	# Update count badge
	var count_badge: Panel = panel.get_node_or_null("CountBadge")
	if count_badge:
		var count_label: Label = count_badge.get_node_or_null("CountLabel")
		if count_label:
			count_label.text = "x" + str(enemies.size())
	
	# Calculate aggregate HP
	var total_hp: int = 0
	var total_max_hp: int = 0
	for e in enemies:
		total_hp += e.current_hp
		total_max_hp += e.max_hp
	
	var hp_fill: ColorRect = panel.get_node_or_null("HPFill")
	if hp_fill:
		var hp_percent: float = float(total_hp) / float(total_max_hp) if total_max_hp > 0 else 1.0
		var max_width: float = float(hp_fill.get_meta("max_width", hp_fill.size.x))
		hp_fill.size.x = max_width * hp_percent
		hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	
	var hp_text: Label = panel.get_node_or_null("HPText")
	if hp_text:
		hp_text.text = str(total_hp) + "/" + str(total_max_hp) + " total"
	
	# Update turn countdown badge (use first enemy in stack since they're all at same position)
	if enemies.size() > 0:
		_update_turn_countdown_badge(panel, enemies[0])
	
	# Update danger highlighting (use highest threat among stacked enemies)
	if enemies.size() > 0:
		var highest_danger: DangerLevel = DangerLevel.NONE
		var most_dangerous_enemy = enemies[0]
		for enemy in enemies:
			var danger: DangerLevel = _get_enemy_danger_level(enemy)
			if danger > highest_danger:
				highest_danger = danger
				most_dangerous_enemy = enemy
		_apply_danger_highlighting(panel, most_dangerous_enemy, "stack_" + stack_key)


# ============== STACK EXPAND-ON-HOVER SYSTEM ==============

var _stack_collapse_timer: SceneTreeTimer = null

func _on_stack_hover_enter(panel: Panel, stack_key: String) -> void:
	"""Show info card for a stack on hover (no longer expands mini-panels on battlefield)."""
	# Cancel any pending collapse
	_stack_collapse_timer = null
	
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var enemy_id: String = panel.get_meta("enemy_id", "")
	
	# Check if stack has danger highlighting
	var danger_key: String = "stack_" + stack_key
	var has_danger: bool = _danger_glow_panels.has(danger_key)
	
	# Get the danger color if applicable
	var border_color: Color = Color(1.0, 1.0, 0.5, 1.0)  # Default gold hover
	if has_danger and stack_data.enemies.size() > 0:
		var danger_level: DangerLevel = _get_enemy_danger_level(stack_data.enemies[0])
		if danger_level != DangerLevel.NONE:
			border_color = DANGER_GLOW_COLORS[danger_level]
	
	# Highlight the stack panel - preserve danger color if present
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3)).lightened(0.15)
	style.set_corner_radius_all(8)
	style.set_border_width_all(4 if has_danger else 3)
	style.border_color = border_color
	if has_danger:
		style.shadow_color = border_color
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 0)
	panel.add_theme_stylebox_override("panel", style)
	
	# Kill any existing scale tween to prevent conflicts
	if _stack_scale_tweens.has(stack_key):
		var old_tween: Tween = _stack_scale_tweens[stack_key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Scale up the main panel slightly
	var tween: Tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)
	_stack_scale_tweens[stack_key] = tween
	panel.z_index = 15
	
	# Show info card with all enemies in the stack (type card + mini cards above)
	var enemies: Array = stack_data.enemies
	if enemies.size() > 0:
		_show_enemy_info_card(panel, enemies[0], enemies)


func _on_stack_hover_exit(panel: Panel, stack_key: String) -> void:
	"""Hide info card when mouse exits stack."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var enemy_id: String = panel.get_meta("enemy_id", "")
	
	# Check if stack has danger highlighting - if so, reapply it
	var danger_key: String = "stack_" + stack_key
	if _danger_glow_panels.has(danger_key) and stack_data.enemies.size() > 0:
		# Reapply danger highlighting
		var highest_danger: DangerLevel = DangerLevel.NONE
		var most_dangerous_enemy = stack_data.enemies[0]
		for enemy in stack_data.enemies:
			var danger: DangerLevel = _get_enemy_danger_level(enemy)
			if danger > highest_danger:
				highest_danger = danger
				most_dangerous_enemy = enemy
		_apply_danger_highlighting(panel, most_dangerous_enemy, danger_key)
	else:
		# Reset to default gold stack border
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))
		style.set_corner_radius_all(8)
		style.set_border_width_all(3)
		style.border_color = Color(1.0, 0.85, 0.4, 0.9)
		panel.add_theme_stylebox_override("panel", style)
	
	# Kill any existing scale tween to prevent conflicts
	if _stack_scale_tweens.has(stack_key):
		var old_tween: Tween = _stack_scale_tweens[stack_key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Scale back
	var tween: Tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.1)
	_stack_scale_tweens[stack_key] = tween
	panel.z_index = 0
	
	# Hide info card
	_hide_enemy_info_card()


func _expand_stack(stack_key: String) -> void:
	"""Create mini-panels showing individual enemies in a stack."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	if stack_data.expanded:
		return
	
	stack_data.expanded = true
	var enemies: Array = stack_data.enemies
	var main_panel: Panel = stack_data.panel
	var mini_panels: Array = []
	
	# Use tracked base position if available, to avoid calculating from mid-animation position
	var panel_pos: Vector2
	if _stack_base_positions.has(stack_key):
		panel_pos = _stack_base_positions[stack_key]
	else:
		panel_pos = main_panel.position
	
	var mini_size: Vector2 = _get_enemy_visual_size(true)
	var spacing: float = mini_size.x + 8
	var total_width: float = spacing * enemies.size() - 8
	var start_x: float = panel_pos.x + main_panel.size.x / 2 - total_width / 2
	var base_y: float = panel_pos.y - mini_size.y - 15
	
	for i: int in range(enemies.size()):
		var enemy = enemies[i]
		var mini_panel: Panel = _create_mini_panel(enemy, mini_size)
		mini_panel.position = Vector2(start_x + i * spacing, base_y)
		mini_panel.modulate.a = 0.0
		mini_panel.scale = Vector2(0.5, 0.5)
		
		# Store reference to stack for hover handling
		mini_panel.set_meta("stack_key", stack_key)
		mini_panel.mouse_entered.connect(_on_mini_panel_hover_enter.bind(mini_panel, enemy, stack_key))
		mini_panel.mouse_exited.connect(_on_mini_panel_hover_exit.bind(mini_panel, stack_key))
		
		enemy_container.add_child(mini_panel)
		mini_panels.append(mini_panel)
		
		# Animate in with stagger
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(mini_panel, "modulate:a", 1.0, 0.15).set_delay(i * 0.03)
		tween.tween_property(mini_panel, "scale", Vector2.ONE, 0.2).set_delay(i * 0.03).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	stack_data.mini_panels = mini_panels


func _collapse_stack(stack_key: String) -> void:
	"""Collapse expanded stack back to single panel with animation."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	if not stack_data.expanded:
		# Even if not marked as expanded, clean up any stray mini-panels
		if stack_data.has("mini_panels"):
			for mini_panel in stack_data.mini_panels:
				if is_instance_valid(mini_panel):
					mini_panel.queue_free()
			stack_data.mini_panels = []
		return
	
	stack_data.expanded = false
	
	# Animate out and remove mini-panels
	for i: int in range(stack_data.mini_panels.size()):
		var mini_panel: Panel = stack_data.mini_panels[i]
		if is_instance_valid(mini_panel):
			var tween: Tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(mini_panel, "modulate:a", 0.0, 0.08)
			tween.tween_property(mini_panel, "scale", Vector2(0.5, 0.5), 0.08)
			tween.chain().tween_callback(mini_panel.queue_free)
	
	stack_data.mini_panels = []


func _force_collapse_stack(stack_key: String) -> void:
	"""Force collapse a stack immediately, cleaning up all mini-panels."""
	if not stack_visuals.has(stack_key):
		# Stack doesn't exist anymore, just cleanup orphans
		_cleanup_orphaned_mini_panels()
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	stack_data.expanded = false
	
	# Immediately remove all mini-panels (no animation)
	# Filter out invalid panels first to avoid accessing freed instances
	if stack_data.has("mini_panels"):
		var valid_panels: Array = []
		for mini_panel in stack_data.mini_panels:
			if is_instance_valid(mini_panel):
				valid_panels.append(mini_panel)
		
		# Free all valid panels
		for mini_panel in valid_panels:
			mini_panel.queue_free()
		
		stack_data.mini_panels = []


func _create_mini_panel(enemy, panel_size: Vector2) -> Panel:
	"""Create a mini-panel for an individual enemy in an expanded stack."""
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 20
	
	panel.set_meta("enemy_instance", enemy)
	panel.set_meta("enemy_id", enemy.enemy_id)
	panel.set_meta("instance_id", enemy.instance_id)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy.enemy_id, Color(0.8, 0.3, 0.3))
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.4, 0.45, 1.0)
	panel.add_theme_stylebox_override("panel", style)
	
	var width: float = panel_size.x
	var height: float = panel_size.y
	
	# Behavior badge (smaller, top-left corner)
	if enemy_def:
		var badge: Panel = _create_behavior_badge(enemy_def, true)
		badge.position = Vector2(2, 2)
		panel.add_child(badge)
	
	# Turn countdown badge (smaller but still visible, top-right corner)
	var countdown_badge: Panel = _create_turn_countdown_badge(enemy, true)
	countdown_badge.position = Vector2(width - 28, 2)
	panel.add_child(countdown_badge)
	
	# Enemy icon (smaller)
	var icon_label: Label = Label.new()
	icon_label.position = Vector2((width - 20.0) * 0.5, 2.0)
	icon_label.size = Vector2(20, 20)
	icon_label.add_theme_font_size_override("font_size", 16)
	icon_label.text = "👤" if not enemy_def else enemy_def.display_icon
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon_label)
	
	# HP bar background
	var hp_bg: ColorRect = ColorRect.new()
	hp_bg.position = Vector2(3.0, height * 0.45)
	hp_bg.size = Vector2(width - 6.0, 6.0)
	hp_bg.color = Color(0.1, 0.1, 0.1, 1.0)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hp_bg)
	
	# HP bar fill
	var hp_fill: ColorRect = ColorRect.new()
	hp_fill.name = "HPFill"
	hp_fill.position = hp_bg.position
	var hp_percent: float = enemy.get_hp_percentage()
	hp_fill.size = Vector2(hp_bg.size.x * hp_percent, hp_bg.size.y)
	hp_fill.set_meta("max_width", hp_bg.size.x)
	hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hp_fill)
	
	# HP text
	var hp_text: Label = Label.new()
	hp_text.name = "HPText"
	hp_text.position = Vector2(0.0, height * 0.6)
	hp_text.size = Vector2(width, 14.0)
	hp_text.add_theme_font_size_override("font_size", 9)
	hp_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.text = str(enemy.current_hp) + "/" + str(enemy.max_hp)
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hp_text)
	
	# Hex indicator
	var hex_stacks: int = enemy.get_status_value("hex")
	if hex_stacks > 0:
		var hex_label: Label = Label.new()
		hex_label.name = "HexLabel"
		hex_label.position = Vector2(0.0, height * 0.78)
		hex_label.size = Vector2(width, 14.0)
		hex_label.add_theme_font_size_override("font_size", 9)
		hex_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0, 1.0))
		hex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hex_label.text = "☠️" + str(hex_stacks)
		hex_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(hex_label)
	
	return panel


func _on_mini_panel_hover_enter(panel: Panel, enemy, _stack_key: String) -> void:
	"""Handle hover on individual mini-panel within expanded stack."""
	# Cancel collapse timer
	_stack_collapse_timer = null
	
	# Highlight mini-panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy.enemy_id, Color(0.8, 0.3, 0.3)).lightened(0.2)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.9, 0.4, 1.0)
	panel.add_theme_stylebox_override("panel", style)
	
	var tween: Tween = create_tween()
	tween.tween_property(panel, "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT)
	panel.z_index = 25
	
	# Show info card for this specific enemy (single enemy, no stack cards)
	_show_enemy_info_card(panel, enemy, [enemy])


func _on_mini_panel_hover_exit(panel: Panel, stack_key: String) -> void:
	"""Handle hover exit from mini-panel."""
	# Reset style
	var enemy_id: String = panel.get_meta("enemy_id", "")
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.4, 0.45, 1.0)
	panel.add_theme_stylebox_override("panel", style)
	
	var tween: Tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.1)
	panel.z_index = 20
	
	_hide_enemy_info_card()
	
	# Start collapse timer
	_stack_collapse_timer = get_tree().create_timer(0.3)
	_stack_collapse_timer.timeout.connect(_collapse_stack.bind(stack_key))


func _show_damage_on_enemy(enemy, amount: int) -> void:
	"""Show damage number directly on the enemy that was hit."""
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	
	var label: Label = Label.new()
	label.text = "-" + str(amount)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	
	# Position above the enemy
	label.position = visual.position + Vector2(visual.size.x / 2 - 20, -20)
	
	damage_numbers.add_child(label)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)


func _show_damage_on_stacked_enemy(enemy, amount: int, stack_key: String, is_hex: bool = false) -> void:
	"""Show damage on an enemy that's part of a stack - show on the mini-card if expanded."""
	if not stack_visuals.has(stack_key):
		return
	
	# Store instance_id immediately to avoid accessing freed enemy instance later
	var target_instance_id: int = enemy.instance_id if enemy != null else -1
	if target_instance_id == -1:
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var main_panel: Panel = stack_data.panel
	
	# Update the stack's aggregate HP display
	_update_stack_hp_display(stack_key)
	
	# Check if stack is expanded (from targeting) - if so, show damage on mini-card
	if stack_data.expanded:
		var mini_panels: Array = stack_data.get("mini_panels", [])
		var target_mini_panel: Panel = null
		
		for mini_panel: Panel in mini_panels:
			if not is_instance_valid(mini_panel):
				continue
			# Get instance_id from meta to avoid accessing potentially freed enemy instance
			var mini_enemy_instance_id: int = mini_panel.get_meta("instance_id", -1)
			if mini_enemy_instance_id == target_instance_id:
				target_mini_panel = mini_panel
				break
		
		if target_mini_panel:
			# Flash the mini-card
			var flash_color: Color = Color(0.8, 0.3, 1.0, 1.0) if is_hex else Color(1.5, 0.5, 0.5, 1.0)
			var flash_tween: Tween = target_mini_panel.create_tween()
			flash_tween.tween_property(target_mini_panel, "modulate", flash_color, 0.05)
			flash_tween.tween_property(target_mini_panel, "modulate", Color.WHITE, 0.15)
			
			# Show damage number above the mini-card
			_show_damage_number_at_position(
				target_mini_panel.position + Vector2(target_mini_panel.size.x / 2 - 15, -10),
				amount,
				is_hex
			)
			
			# Update HP on the mini-card - only if enemy is still valid
			if is_instance_valid(enemy):
				_update_mini_panel_hp(target_mini_panel, enemy)
			return
	
	# Fallback: if not expanded or mini-card not found, expand and show damage
	if not stack_data.expanded:
		# target_instance_id already stored at function start
		
		# Quick expand to show which enemy was hit
		_expand_stack(stack_key)
		
		# Wait briefly then show damage on mini-card
		await get_tree().create_timer(0.1).timeout
		
		# Re-check that stack still exists after await (it might have been refreshed/destroyed)
		if not stack_visuals.has(stack_key):
			return
		
		var stack_data_after_await: Dictionary = stack_visuals[stack_key]
		if not stack_data_after_await.has("mini_panels"):
			return
		
		var mini_panels: Array = stack_data_after_await.get("mini_panels", [])
		
		# Filter out invalid panels before iterating to avoid freed instance errors
		var valid_mini_panels: Array = []
		for panel in mini_panels:
			if is_instance_valid(panel):
				valid_mini_panels.append(panel)
		
		var found_target: bool = false
		for mini_panel: Panel in valid_mini_panels:
			# Get instance_id from meta to avoid accessing potentially freed enemy instance
			var mini_enemy_instance_id: int = mini_panel.get_meta("instance_id", -1)
			if mini_enemy_instance_id == target_instance_id:
					# Flash and show damage
					var flash_color: Color = Color(0.8, 0.3, 1.0, 1.0) if is_hex else Color(1.5, 0.5, 0.5, 1.0)
					var flash_tween: Tween = mini_panel.create_tween()
					flash_tween.tween_property(mini_panel, "modulate", flash_color, 0.05)
					flash_tween.tween_property(mini_panel, "modulate", Color.WHITE, 0.15)
					
					_show_damage_number_at_position(
						mini_panel.position + Vector2(mini_panel.size.x / 2 - 15, -10),
						amount,
						is_hex
					)
					# Skip updating HP if enemy was killed during the delay
					# We can't safely access enemy properties after async delay
					found_target = true
					break
		
		# Auto-collapse after showing damage (only if we found the target)
		if found_target:
			await get_tree().create_timer(0.4).timeout
			# Re-check that stack still exists before collapsing
			if stack_visuals.has(stack_key):
				_force_collapse_stack(stack_key)
	else:
		# Stack is expanded but we couldn't find the mini-card - show on main panel as fallback
		if is_instance_valid(main_panel):
			var flash_tween: Tween = create_tween()
			flash_tween.tween_property(main_panel, "modulate", Color(1.5, 0.5, 0.5, 1.0), 0.05)
			flash_tween.tween_property(main_panel, "modulate", Color.WHITE, 0.15)
			
			_show_damage_number_at_position(
				main_panel.position + Vector2(main_panel.size.x / 2 - 15, -15),
				amount,
				is_hex
			)


func _expand_stack_briefly(stack_key: String, damaged_enemy) -> void:
	"""Briefly expand a stack to show damage, then collapse."""
	_expand_stack(stack_key)
	
	# Find and highlight the damaged enemy's mini-panel
	await get_tree().process_frame
	
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	for mini_panel: Panel in stack_data.mini_panels:
		if not is_instance_valid(mini_panel):
			continue
		# Use instance_id from meta to avoid accessing potentially freed enemy instance
		var mini_enemy_instance_id: int = mini_panel.get_meta("instance_id", -1)
		if mini_enemy_instance_id == damaged_enemy.instance_id:
			# Flash this mini-panel
			var flash: Tween = create_tween()
			flash.tween_property(mini_panel, "modulate", Color(1.5, 0.4, 0.4, 1.0), 0.05)
			flash.tween_property(mini_panel, "modulate", Color.WHITE, 0.3)
			
			# Update HP display on mini-panel
			var hp_fill: ColorRect = mini_panel.get_node_or_null("HPFill")
			if hp_fill:
				var hp_percent: float = damaged_enemy.get_hp_percentage()
				var max_width: float = float(hp_fill.get_meta("max_width", hp_fill.size.x))
				hp_fill.size.x = max_width * hp_percent
				hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
			
			var hp_text: Label = mini_panel.get_node_or_null("HPText")
			if hp_text:
				hp_text.text = str(damaged_enemy.current_hp) + "/" + str(damaged_enemy.max_hp)
			break
	
	# Auto-collapse after a delay
	await get_tree().create_timer(1.5).timeout
	if stack_visuals.has(stack_key) and stack_visuals[stack_key].expanded:
		_collapse_stack(stack_key)


func _show_player_damage(amount: int) -> void:
	_recalculate_layout()
	
	var label: Label = Label.new()
	label.text = "-" + str(amount)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	label.position = center + Vector2(-25, -20)
	
	damage_numbers.add_child(label)
	
	# Screen shake effect
	var original_pos: Vector2 = position
	var shake_tween: Tween = create_tween()
	for i: int in range(6):
		var offset: Vector2 = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		shake_tween.tween_property(self, "position", original_pos + offset, 0.04)
	shake_tween.tween_property(self, "position", original_pos, 0.04)
	
	# Flash warden red
	modulate = Color(1.2, 0.5, 0.5, 1.0)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Fade out damage number
	var label_tween: Tween = create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(label, "position:y", label.position.y - 50, 0.7)
	label_tween.tween_property(label, "modulate:a", 0.0, 0.7)
	label_tween.chain().tween_callback(label.queue_free)


func refresh_all_enemies() -> void:
	"""Refresh all enemy visuals from current battlefield state."""
	for visual: Panel in enemy_visuals.values():
		visual.queue_free()
	enemy_visuals.clear()
	
	if CombatManager.battlefield:
		for enemy in CombatManager.battlefield.get_all_enemies():
			_create_enemy_visual(enemy)
	
	queue_redraw()


func update_enemy_hp(enemy) -> void:  # enemy: EnemyInstance
	"""Update HP display for a specific enemy."""
	if enemy_visuals.has(enemy.instance_id):
		var visual: Panel = enemy_visuals[enemy.instance_id]
		_update_enemy_hp_display(enemy, visual)


# ============== ENEMY HOVER INFO CARD SYSTEM ==============

var current_info_card: Control = null
var current_individual_cards: Array = []  # Mini cards for each enemy in a stack

func _on_enemy_hover_enter(visual: Panel, enemy) -> void:
	# Highlight the enemy panel directly
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy.enemy_id, Color(0.8, 0.3, 0.3)).lightened(0.15)
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	style.border_color = Color(1.0, 0.9, 0.4, 1.0)
	visual.add_theme_stylebox_override("panel", style)
	
	# Kill any existing scale tween to prevent conflicts
	if _enemy_scale_tweens.has(enemy.instance_id):
		var old_tween: Tween = _enemy_scale_tweens[enemy.instance_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Scale up slightly
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.2, 1.2), 0.12).set_ease(Tween.EASE_OUT)
	_enemy_scale_tweens[enemy.instance_id] = tween
	
	# Bring to front
	visual.z_index = 10
	
	# Show info card (single enemy)
	_show_enemy_info_card(visual, enemy, [enemy])


func _on_enemy_hover_exit(visual: Panel) -> void:
	var enemy_id: String = visual.get_meta("enemy_id", "")
	var instance_id: int = visual.get_meta("instance_id", -1)
	
	# Check if this enemy has danger highlighting - if so, reapply it
	var danger_key: String = "enemy_" + str(instance_id)
	if _danger_glow_panels.has(danger_key):
		# Reapply danger style instead of default
		var enemy = visual.get_meta("enemy_instance", null)
		if enemy:
			_apply_danger_highlighting(visual, enemy, danger_key)
	else:
		# Reset to default style
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.border_color = Color(0.3, 0.3, 0.35, 1.0)
		visual.add_theme_stylebox_override("panel", style)
	
	# Kill any existing scale tween to prevent conflicts
	if instance_id >= 0 and _enemy_scale_tweens.has(instance_id):
		var old_tween: Tween = _enemy_scale_tweens[instance_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Scale back
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector2.ONE, 0.1)
	if instance_id >= 0:
		_enemy_scale_tweens[instance_id] = tween
	
	# Reset z-index
	visual.z_index = 0
	
	# Hide info card
	_hide_enemy_info_card()


func _show_enemy_info_card(visual: Panel, enemy, all_enemies: Array) -> void:
	"""Show enemy TYPE info card to the right, with mini cards centered above the enemy."""
	_hide_enemy_info_card()
	
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	if not enemy_def:
		return
	
	# Create main info card container
	current_info_card = Control.new()
	current_info_card.z_index = 100
	current_info_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create the enemy TYPE info card (shows base stats, not instance-specific)
	var main_card: PanelContainer = _create_enemy_type_card(enemy_def)
	main_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_info_card.add_child(main_card)
	
	# Add to root for proper global positioning
	get_tree().root.add_child(current_info_card)
	
	await get_tree().process_frame
	
	# Get screen size for boundary checking
	var screen_size: Vector2 = get_viewport_rect().size
	
	# Position info card to the right of the enemy
	var card_pos: Vector2 = visual.global_position + Vector2(visual.size.x * visual.scale.x + 15, 0)
	
	# Adjust if too close to right edge
	if card_pos.x + main_card.size.x > screen_size.x - 10:
		card_pos.x = visual.global_position.x - main_card.size.x - 15
	
	# Adjust vertical position
	if card_pos.y + main_card.size.y > screen_size.y - 10:
		card_pos.y = screen_size.y - main_card.size.y - 10
	if card_pos.y < 10:
		card_pos.y = 10
	
	main_card.global_position = card_pos
	
	# Show mini cards centered above the enemy/stack on the battlefield
	_create_individual_enemy_cards(all_enemies, visual)
	
	# Fade in animation
	current_info_card.modulate.a = 0.0
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(current_info_card, "modulate:a", 1.0, 0.15)


func _create_enemy_type_card(enemy_def) -> PanelContainer:
	"""Create a card-style panel displaying enemy TYPE information (base stats, not instance-specific)."""
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 280)
	
	# Card background style - similar to player cards
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.15, 0.98)
	
	# Border color based on enemy type
	if enemy_def.is_boss:
		style.border_color = Color(1.0, 0.3, 0.3, 1.0)  # Red for boss
	elif enemy_def.is_elite:
		style.border_color = Color(1.0, 0.8, 0.2, 1.0)  # Gold for elite
	else:
		style.border_color = ENEMY_COLORS.get(enemy_def.enemy_id, Color(0.5, 0.4, 0.6))
	
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	card.add_theme_stylebox_override("panel", style)
	
	# Main container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	# Header row with behavior badge and name
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)
	
	# Behavior badge
	var badge_panel: Panel = Panel.new()
	var badge_size: float = 28.0
	badge_panel.custom_minimum_size = Vector2(badge_size, badge_size)
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	badge_style.set_corner_radius_all(int(badge_size / 2))
	badge_style.set_border_width_all(2)
	badge_style.border_color = enemy_def.get_behavior_badge_color()
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	
	var badge_icon: Label = Label.new()
	badge_icon.text = enemy_def.get_behavior_badge_icon()
	badge_icon.add_theme_font_size_override("font_size", 14)
	badge_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_icon.size = Vector2(badge_size, badge_size)
	badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.add_child(badge_icon)
	header.add_child(badge_panel)
	
	# Name and type
	var name_vbox: VBoxContainer = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 0)
	name_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(name_vbox)
	
	var name_label: Label = Label.new()
	name_label.text = enemy_def.enemy_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", ENEMY_COLORS.get(enemy_def.enemy_id, Color.WHITE))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.add_child(name_label)
	
	var type_label: Label = Label.new()
	if enemy_def.is_boss:
		type_label.text = "💀 BOSS"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif enemy_def.is_elite:
		type_label.text = "⭐ ELITE"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		type_label.text = enemy_def.enemy_type.to_upper()
		type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.add_child(type_label)
	
	# Large enemy icon
	var icon_label: Label = Label.new()
	icon_label.text = enemy_def.display_icon
	icon_label.add_theme_font_size_override("font_size", 42)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)
	
	# Base stats row (showing BASE stats, not instance-specific)
	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 12)
	stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_row)
	
	# Base HP stat
	var hp_label: Label = Label.new()
	var scaled_hp: int = enemy_def.get_scaled_hp(RunManager.current_wave)
	hp_label.text = "❤️ " + str(scaled_hp)
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.add_child(hp_label)
	
	# Damage stat
	var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
	var dmg_label: Label = Label.new()
	dmg_label.text = "⚔️ " + str(dmg)
	dmg_label.add_theme_font_size_override("font_size", 14)
	dmg_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	dmg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.add_child(dmg_label)
	
	# Armor stat (if any)
	if enemy_def.armor > 0:
		var armor_label: Label = Label.new()
		armor_label.text = "🛡️ " + str(enemy_def.armor)
		armor_label.add_theme_font_size_override("font_size", 14)
		armor_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		armor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_row.add_child(armor_label)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)
	
	# Attack info
	var attack_label: Label = Label.new()
	var attack_text: String = "🎯 " + enemy_def.attack_type.capitalize()
	if enemy_def.attack_type == "ranged":
		attack_text += " (range " + str(enemy_def.attack_range) + ")"
	elif enemy_def.attack_type == "suicide":
		attack_text = "💥 Suicide (" + str(enemy_def.buff_amount) + " dmg)"
	attack_label.text = attack_text
	attack_label.add_theme_font_size_override("font_size", 12)
	attack_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
	attack_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(attack_label)
	
	# Speed and target
	var movement_label: Label = Label.new()
	movement_label.text = "💨 Speed: " + str(enemy_def.movement_speed) + " │ 📍 Target: " + RING_NAMES[enemy_def.target_ring]
	movement_label.add_theme_font_size_override("font_size", 11)
	movement_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	movement_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(movement_label)
	
	# Behavior tooltip
	var behavior_label: Label = Label.new()
	behavior_label.text = enemy_def.get_behavior_tooltip()
	behavior_label.add_theme_font_size_override("font_size", 11)
	behavior_label.add_theme_color_override("font_color", enemy_def.get_behavior_badge_color())
	behavior_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	behavior_label.custom_minimum_size.x = 180
	behavior_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(behavior_label)
	
	# Special ability (if any)
	if enemy_def.special_ability != "":
		var sep2: HSeparator = HSeparator.new()
		sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(sep2)
		
		var ability_label: Label = Label.new()
		ability_label.add_theme_font_size_override("font_size", 11)
		ability_label.add_theme_color_override("font_color", Color(0.9, 0.6, 1.0))
		ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		ability_label.custom_minimum_size.x = 180
		ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		match enemy_def.special_ability:
			"explode_on_death":
				ability_label.text = "💥 Explodes on death for " + str(enemy_def.buff_amount) + " damage!"
			"buff_allies":
				ability_label.text = "✨ Buffs allies +" + str(enemy_def.buff_amount) + " damage"
			"spawn_minions":
				ability_label.text = "🔮 Spawns " + str(enemy_def.spawn_count) + "x " + enemy_def.spawn_enemy_id
			_:
				ability_label.text = "⚡ " + enemy_def.special_ability
		vbox.add_child(ability_label)
	
	# Description (if any)
	if enemy_def.description != "":
		var sep3: HSeparator = HSeparator.new()
		sep3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(sep3)
		
		var desc_label: Label = Label.new()
		desc_label.text = enemy_def.description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size.x = 180
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(desc_label)
	
	return card


func _create_enemy_instance_mini_card(enemy) -> PanelContainer:
	"""Create a small mini card showing an individual enemy instance's current state."""
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	if not enemy_def:
		return PanelContainer.new()
	
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(55, 70)
	
	# Check if this enemy has danger highlighting
	var danger_level: DangerLevel = _get_enemy_danger_level(enemy)
	var has_danger: bool = danger_level != DangerLevel.NONE
	
	# Card background style - apply danger color if applicable
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.12, 0.95)
	
	if has_danger:
		var danger_color: Color = DANGER_GLOW_COLORS[danger_level]
		style.border_color = danger_color
		style.set_border_width_all(3)
		style.shadow_color = danger_color
		style.shadow_size = 6
	else:
		style.border_color = ENEMY_COLORS.get(enemy.enemy_id, Color(0.5, 0.4, 0.6))
		style.set_border_width_all(2)
		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = 2
	
	style.set_corner_radius_all(5)
	style.set_content_margin_all(3)
	card.add_theme_stylebox_override("panel", style)
	
	# Main container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	# Enemy icon
	var icon_label: Label = Label.new()
	icon_label.text = enemy_def.display_icon
	icon_label.add_theme_font_size_override("font_size", 18)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)
	
	# HP bar background
	var hp_bar_bg: ColorRect = ColorRect.new()
	hp_bar_bg.custom_minimum_size = Vector2(48, 5)
	hp_bar_bg.color = Color(0.15, 0.1, 0.1, 1.0)
	hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hp_bar_bg)
	
	# HP bar fill
	var hp_percent: float = enemy.get_hp_percentage()
	var hp_bar_fill: ColorRect = ColorRect.new()
	hp_bar_fill.custom_minimum_size = Vector2(48 * hp_percent, 5)
	hp_bar_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_fill.position = hp_bar_bg.position
	hp_bar_bg.add_child(hp_bar_fill)
	
	# HP text
	var hp_label: Label = Label.new()
	hp_label.text = str(enemy.current_hp)
	hp_label.add_theme_font_size_override("font_size", 9)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hp_label)
	
	# Damage display
	var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
	var dmg_label: Label = Label.new()
	dmg_label.text = "⚔️" + str(dmg)
	dmg_label.add_theme_font_size_override("font_size", 9)
	dmg_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	dmg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(dmg_label)
	
	# Status effects (hex indicator - compact)
	if enemy.has_status("hex"):
		var hex_label: Label = Label.new()
		hex_label.text = "☠" + str(enemy.get_status_value("hex"))
		hex_label.add_theme_font_size_override("font_size", 8)
		hex_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0))
		hex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hex_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(hex_label)
	
	return card


func _create_individual_enemy_cards(enemies: Array, visual: Panel) -> void:
	"""Create small mini cards for each individual enemy, centered above the enemy/stack."""
	var mini_card_size: Vector2 = Vector2(55, 70)
	var spacing: float = 6.0
	
	# Calculate total width of all mini cards
	var total_width: float = (mini_card_size.x + spacing) * enemies.size() - spacing
	
	# Center above the visual panel
	var visual_center_x: float = visual.global_position.x + (visual.size.x * visual.scale.x) / 2.0
	var start_x: float = visual_center_x - total_width / 2.0
	var base_y: float = visual.global_position.y - mini_card_size.y - 12
	
	# Clamp to screen bounds
	var screen_size: Vector2 = get_viewport_rect().size
	if start_x < 10:
		start_x = 10
	if start_x + total_width > screen_size.x - 10:
		start_x = screen_size.x - total_width - 10
	if base_y < 10:
		base_y = 10
	
	for i: int in range(enemies.size()):
		var enemy = enemies[i]
		
		# Create mini card showing individual enemy's current state
		var mini_card: PanelContainer = _create_enemy_instance_mini_card(enemy)
		mini_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		current_info_card.add_child(mini_card)
		current_individual_cards.append(mini_card)
		
		# Position the mini card
		var card_x: float = start_x + i * (mini_card_size.x + spacing)
		mini_card.global_position = Vector2(card_x, base_y)
		
		# Animate in with stagger
		mini_card.modulate.a = 0.0
		mini_card.scale = Vector2(0.5, 0.5)
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(mini_card, "modulate:a", 1.0, 0.12).set_delay(i * 0.025)
		tween.tween_property(mini_card, "scale", Vector2.ONE, 0.15).set_delay(i * 0.025).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _show_enemy_tooltip(visual: Panel, enemy) -> void:
	"""Legacy function - redirects to new info card system."""
	_show_enemy_info_card(visual, enemy, [enemy])


func _create_stat_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	return label


func _hide_enemy_tooltip() -> void:
	"""Legacy function - redirects to new info card hide."""
	_hide_enemy_info_card()


func _hide_enemy_info_card() -> void:
	"""Hide the enemy info card with reverse fade animation."""
	if not current_info_card or not is_instance_valid(current_info_card):
		current_individual_cards.clear()
		return
	
	# Store reference before clearing
	var info_card_ref: Control = current_info_card
	var mini_cards_ref: Array = current_individual_cards.duplicate()
	
	# Clear references immediately to prevent double-hide
	current_info_card = null
	current_individual_cards.clear()
	
	# Animate mini cards out in reverse order (right to left)
	var total_mini: int = mini_cards_ref.size()
	for i: int in range(total_mini - 1, -1, -1):
		var mini_card = mini_cards_ref[i]
		if is_instance_valid(mini_card):
			var reverse_index: int = total_mini - 1 - i
			var tween: Tween = info_card_ref.create_tween()
			tween.set_parallel(true)
			tween.tween_property(mini_card, "modulate:a", 0.0, 0.1).set_delay(reverse_index * 0.02)
			tween.tween_property(mini_card, "scale", Vector2(0.5, 0.5), 0.1).set_delay(reverse_index * 0.02)
	
	# Fade out main card (first child is the type card)
	var main_card_delay: float = mini_cards_ref.size() * 0.02
	var fade_tween: Tween = info_card_ref.create_tween()
	fade_tween.tween_property(info_card_ref, "modulate:a", 0.0, 0.12).set_delay(main_card_delay)
	fade_tween.tween_callback(info_card_ref.queue_free)


func clear_all_hover_states() -> void:
	"""Clear all hover states - call when turn ends or phase changes to prevent orphaned UI."""
	# Hide enemy info card and mini cards
	_hide_enemy_info_card()
	
	# Clear any pending attack indicators
	_clear_attack_indicator()
	
	# Clear all active weapon reticles (from persistent weapons)
	for reticle: Control in _active_weapon_reticles:
		if is_instance_valid(reticle):
			reticle.queue_free()
	_active_weapon_reticles.clear()
	
	# Force collapse ALL expanded stacks and clean up ALL mini panels
	for stack_key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[stack_key]
		# Force cleanup of mini-panels regardless of expanded state
		if stack_data.has("mini_panels"):
			for mini_panel in stack_data.mini_panels:
				if is_instance_valid(mini_panel):
					mini_panel.queue_free()
			stack_data.mini_panels = []
		stack_data.expanded = false
	
	# Cancel any pending collapse timers
	_stack_collapse_timer = null
	
	# Scan enemy_container for any orphaned mini-panels and clean them up
	_cleanup_orphaned_mini_panels()
	
	# Reset visual scales on any enemy panels that might be in hover state
	for instance_id: int in enemy_visuals.keys():
		var visual: Panel = enemy_visuals[instance_id]
		if is_instance_valid(visual):
			visual.scale = Vector2.ONE
			visual.z_index = 0
			# Don't reset modulate if danger pulse is active
			var danger_key: String = "enemy_" + str(instance_id)
			if not _danger_glow_panels.has(danger_key):
				visual.modulate = Color.WHITE
				# Reset panel style to default only if no danger highlighting
				var enemy_id: String = visual.get_meta("enemy_id", "")
				var style: StyleBoxFlat = StyleBoxFlat.new()
				style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))
				style.set_corner_radius_all(8)
				style.set_border_width_all(2)
				style.border_color = Color(0.3, 0.3, 0.35, 1.0)
				visual.add_theme_stylebox_override("panel", style)
	
	# Reset stack visual scales
	for stack_key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[stack_key]
		if is_instance_valid(stack_data.panel):
			stack_data.panel.scale = Vector2.ONE
			stack_data.panel.z_index = 0
			# Don't reset modulate if danger pulse is active
			var danger_key: String = "stack_" + stack_key
			if not _danger_glow_panels.has(danger_key):
				stack_data.panel.modulate = Color.WHITE
				# Reset panel style to default only if no danger highlighting
				var enemy_id: String = stack_data.panel.get_meta("enemy_id", "")
				var style: StyleBoxFlat = StyleBoxFlat.new()
				style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))
				style.set_corner_radius_all(8)
				style.set_border_width_all(3)
				style.border_color = Color(1.0, 0.85, 0.4, 0.9)
				stack_data.panel.add_theme_stylebox_override("panel", style)


func _cleanup_orphaned_mini_panels() -> void:
	"""Clean up any mini-panels that might be orphaned in the enemy_container."""
	if not enemy_container:
		return
	
	# Collect all known panels (enemy visuals + stack panels)
	var known_panels: Array = []
	for visual in enemy_visuals.values():
		known_panels.append(visual)
	for stack_key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[stack_key]
		if stack_data.has("panel"):
			known_panels.append(stack_data.panel)
	
	# Any panel in enemy_container that isn't in known_panels is orphaned
	for child in enemy_container.get_children():
		if child is Panel and child not in known_panels:
			# This is likely an orphaned mini-panel
			child.queue_free()


# ============== RING DETECTION FOR DRAG-DROP ==============

func get_ring_at_position(global_pos: Vector2) -> int:
	"""
	Determine which ring a global position falls into.
	Returns -1 if outside all rings, or 0-3 for MELEE/CLOSE/MID/FAR.
	"""
	_recalculate_layout()
	
	# Convert global position to local
	var local_pos: Vector2 = global_pos - global_position
	
	# Calculate distance from center
	var distance: float = local_pos.distance_to(center)
	
	# Check if position is in the upper semicircle (where enemies are)
	var dir: Vector2 = (local_pos - center).normalized()
	var angle: float = atan2(dir.y, dir.x)
	
	# Only accept drops in upper semicircle (PI to 2*PI, which is negative y)
	# Angle range: PI (left) to 2*PI or 0 (right), going through 1.5*PI (top)
	var is_in_arena: bool = angle <= 0 or angle >= PI
	
	if not is_in_arena:
		# Below the center line - not a valid target area
		return -1
	
	# Determine which ring based on distance
	for ring in range(4):
		var ring_radius: float = max_radius * RING_PROPORTIONS[ring]
		if distance <= ring_radius:
			return ring
	
	# Outside FAR ring
	return -1


func highlight_ring(ring: int, highlight: bool) -> void:
	"""Highlight a ring to show it's a valid drop target."""
	# This triggers a redraw with highlighted ring
	_highlighted_rings.clear()
	if highlight and ring >= 0:
		_highlighted_rings.append(ring)
	queue_redraw()


func highlight_all_rings(highlight: bool) -> void:
	"""Highlight all rings to show entire battlefield is targeted."""
	_highlighted_rings.clear()
	if highlight:
		_highlighted_rings = [0, 1, 2, 3]
	queue_redraw()


func highlight_rings(rings: Array, highlight: bool) -> void:
	"""Highlight specific rings to show they are valid targets."""
	_highlighted_rings.clear()
	if highlight:
		for ring in rings:
			if ring >= 0 and ring <= 3:
				_highlighted_rings.append(ring)
	queue_redraw()


var _highlighted_rings: Array = []


func _draw_ring(ring_index: int, radius: float) -> void:
	var color: Color = RING_COLORS[ring_index]
	var border_color: Color = get_ring_threat_color(ring_index)  # Use threat-based color
	var border_width: float = get_ring_threat_border_width(ring_index)
	
	# Check if this ring has a barrier
	var has_barrier: bool = ring_barriers.has(ring_index)
	
	# Brighten if highlighted for card targeting - make it much more visible
	var is_highlighted: bool = ring_index in _highlighted_rings
	if is_highlighted:
		# Create a bright highlight with increased alpha
		color = Color(1.0, 0.9, 0.3, 0.35)  # Bright gold fill
		border_color = Color(1.0, 1.0, 0.4, 1.0)  # Gold highlight border
		border_width = 4.0
	elif has_barrier:
		# Barrier ring - green pulsing effect
		var barrier_pulse: float = (sin(_barrier_pulse_time) + 1.0) / 2.0
		color = Color(0.2, 0.5, 0.3, 0.25 + barrier_pulse * 0.15)
		border_color = Color(0.3, 1.0, 0.5, 0.8 + barrier_pulse * 0.2)
		border_width = 4.0 + barrier_pulse * 2.0
	
	# Draw filled ring area (as semicircle facing upward - enemies come from top)
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 48
	
	# Create arc for the ring (top half where enemies come from)
	for i: int in range(segments + 1):
		var angle: float = PI + (float(i) / float(segments)) * PI
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	# Close the shape
	if ring_index > 0:
		var inner_radius: float = max_radius * RING_PROPORTIONS[ring_index - 1]
		for i: int in range(segments, -1, -1):
			var angle: float = PI + (float(i) / float(segments)) * PI
			points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)
	else:
		# For melee ring, close to center
		points.append(center)
	
	if points.size() >= 3:
		draw_colored_polygon(points, color)
	
	# Draw ring border arc
	var arc_points: int = 64
	for i: int in range(arc_points):
		var angle1: float = PI + (float(i) / float(arc_points)) * PI
		var angle2: float = PI + (float(i + 1) / float(arc_points)) * PI
		var p1: Vector2 = center + Vector2(cos(angle1), sin(angle1)) * radius
		var p2: Vector2 = center + Vector2(cos(angle2), sin(angle2)) * radius
		draw_line(p1, p2, border_color, border_width, true)
	
	# Draw barrier indicator if present
	if has_barrier:
		_draw_barrier_indicator(ring_index, radius)
	
	# Draw ring label
	var label_pos: Vector2 = center + Vector2(radius - 30, 20)
	var ring_name: String = RING_NAMES[ring_index]
	draw_string(ThemeDB.fallback_font, label_pos, ring_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, border_color)


func _draw_barrier_indicator(ring_index: int, radius: float) -> void:
	"""Draw barrier visual elements on a ring."""
	if not ring_barriers.has(ring_index):
		return
	
	var barrier_data: Dictionary = ring_barriers[ring_index]
	var damage: int = barrier_data.get("damage", 0)
	var duration: int = barrier_data.get("duration", 0)
	
	# Draw barrier icon and stats at multiple positions along the ring
	var num_icons: int = 3
	for i: int in range(num_icons):
		var angle: float = PI + (float(i + 1) / float(num_icons + 1)) * PI
		var icon_radius: float = radius - 15
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * icon_radius
		
		# Draw barrier icon
		draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 5), "🚧", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.3, 1.0, 0.5, 0.9))
	
	# Draw damage and duration at center of ring arc
	var center_angle: float = PI + PI * 0.5
	var info_radius: float = radius - 35
	var info_pos: Vector2 = center + Vector2(cos(center_angle), sin(center_angle)) * info_radius
	
	# Background for readability
	draw_circle(info_pos + Vector2(0, 5), 24, Color(0.0, 0.0, 0.0, 0.7))
	
	# Damage text
	var dmg_text: String = "⚔" + str(damage)
	draw_string(ThemeDB.fallback_font, info_pos + Vector2(-12, 0), dmg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.4, 0.4, 1.0))
	
	# Duration text
	var dur_text: String = "⏱" + str(duration)
	draw_string(ThemeDB.fallback_font, info_pos + Vector2(-12, 14), dur_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.8, 0.8, 0.9))


## ============== BARRIER MANAGEMENT ==============

func set_ring_barrier(ring: int, damage: int, duration: int) -> void:
	"""Set a barrier on a ring with damage and duration."""
	ring_barriers[ring] = {
		"damage": damage,
		"duration": duration
	}
	queue_redraw()


func update_barrier_duration(ring: int, new_duration: int) -> void:
	"""Update a barrier's remaining duration."""
	if ring_barriers.has(ring):
		if new_duration <= 0:
			ring_barriers.erase(ring)
		else:
			ring_barriers[ring].duration = new_duration
		queue_redraw()


func clear_ring_barrier(ring: int) -> void:
	"""Remove a barrier from a ring."""
	if ring_barriers.has(ring):
		ring_barriers.erase(ring)
		queue_redraw()


func clear_all_barriers() -> void:
	"""Clear all barriers (e.g., at end of combat)."""
	ring_barriers.clear()
	queue_redraw()


func get_barrier_damage(ring: int) -> int:
	"""Get the damage a barrier on a ring deals."""
	if ring_barriers.has(ring):
		return ring_barriers[ring].get("damage", 0)
	return 0


## ============== ATTACK INDICATOR SYSTEM ==============

func show_attack_indicator(enemy, duration: float = 0.3) -> void:
	"""Show a targeting reticle on an enemy before they're hit."""
	# Check if enemy is in a stack
	var stack_key: String = str(enemy.ring) + "_" + enemy.enemy_id
	
	if stack_visuals.has(stack_key):
		_show_stack_attack_indicator(enemy, stack_key, duration)
	elif enemy_visuals.has(enemy.instance_id):
		_show_individual_attack_indicator(enemy, duration)


func _show_individual_attack_indicator(enemy, duration: float) -> void:
	"""Show attack indicator on an individual enemy."""
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	
	# Create targeting reticle
	var reticle: Control = _create_attack_reticle(visual.size)
	reticle.position = visual.position - (reticle.size - visual.size) / 2
	reticle.z_index = 50
	
	enemy_container.add_child(reticle)
	_active_weapon_reticles.append(reticle)
	
	# Store for cleanup
	_pending_attack_indicator = {
		"reticle": reticle,
		"enemy": enemy
	}
	
	# Animate
	var tween: Tween = create_tween()
	tween.tween_property(reticle, "modulate:a", 0.5, duration * 0.5)
	tween.tween_property(reticle, "modulate:a", 1.0, duration * 0.5)
	tween.tween_callback(_clear_attack_indicator)


func _show_stack_attack_indicator(enemy, stack_key: String, duration: float) -> void:
	"""Show attack indicator on a stacked enemy - expand and highlight."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var main_panel: Panel = stack_data.panel
	
	# Create reticle on main panel
	var reticle: Control = _create_attack_reticle(main_panel.size)
	reticle.position = main_panel.position - (reticle.size - main_panel.size) / 2
	reticle.z_index = 50
	
	enemy_container.add_child(reticle)
	_active_weapon_reticles.append(reticle)
	
	_pending_attack_indicator = {
		"reticle": reticle,
		"enemy": enemy,
		"stack_key": stack_key
	}
	
	# Expand the stack to show which enemy is targeted
	_expand_stack(stack_key)
	
	# Find and highlight the specific mini-panel after brief delay
	var highlight_timer: SceneTreeTimer = get_tree().create_timer(0.1)
	highlight_timer.timeout.connect(func() -> void:
		if not stack_visuals.has(stack_key):
			return
		var mini_panels: Array = stack_data.get("mini_panels", [])
		for mini_panel: Panel in mini_panels:
			if not is_instance_valid(mini_panel):
				continue
			# Use instance_id from meta to avoid accessing potentially freed enemy instance
			var mini_enemy_instance_id: int = mini_panel.get_meta("instance_id", -1)
			if mini_enemy_instance_id == enemy.instance_id:
				# Create mini reticle
				var mini_reticle: Control = _create_attack_reticle(mini_panel.size, true)
				mini_reticle.position = mini_panel.position - (mini_reticle.size - mini_panel.size) / 2
				mini_reticle.z_index = 55
				enemy_container.add_child(mini_reticle)
				_active_weapon_reticles.append(mini_reticle)
				
				_pending_attack_indicator["mini_reticle"] = mini_reticle
				
				# Pulse animation
				if is_instance_valid(mini_panel):
					var pulse_tween: Tween = mini_panel.create_tween()
					pulse_tween.tween_property(mini_panel, "modulate", Color(1.5, 0.5, 0.5, 1.0), duration * 0.4)
					pulse_tween.tween_property(mini_panel, "modulate", Color.WHITE, duration * 0.4)
				break
	)
	
	# Cleanup after duration
	var cleanup_timer: SceneTreeTimer = get_tree().create_timer(duration)
	cleanup_timer.timeout.connect(_clear_attack_indicator)


func _create_attack_reticle(panel_size: Vector2, is_mini: bool = false) -> Control:
	"""Create a targeting reticle control."""
	var reticle: Control = Control.new()
	var size_mult: float = 1.4 if not is_mini else 1.3
	reticle.size = panel_size * size_mult
	
	# Add corner brackets
	var corners: Array[String] = ["┌", "┐", "└", "┘"]
	var offsets: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(reticle.size.x - 16, 0),
		Vector2(0, reticle.size.y - 20),
		Vector2(reticle.size.x - 16, reticle.size.y - 20)
	]
	
	for i: int in range(4):
		var corner: Label = Label.new()
		corner.text = corners[i]
		corner.add_theme_font_size_override("font_size", 24 if not is_mini else 18)
		corner.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		corner.position = offsets[i]
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reticle.add_child(corner)
		
		# Pulse animation
		var tween: Tween = corner.create_tween()
		tween.set_loops()
		tween.tween_property(corner, "modulate:a", 0.4, 0.12)
		tween.tween_property(corner, "modulate:a", 1.0, 0.12)
	
	return reticle


func _clear_attack_indicator() -> void:
	"""Clear the current attack indicator."""
	if _pending_attack_indicator.has("reticle"):
		var reticle: Control = _pending_attack_indicator.reticle
		if is_instance_valid(reticle):
			reticle.queue_free()
			_active_weapon_reticles.erase(reticle)
	
	if _pending_attack_indicator.has("mini_reticle"):
		var mini_reticle: Control = _pending_attack_indicator.mini_reticle
		if is_instance_valid(mini_reticle):
			mini_reticle.queue_free()
			_active_weapon_reticles.erase(mini_reticle)
	
	# Collapse stack if we expanded it
	if _pending_attack_indicator.has("stack_key"):
		var sk: String = _pending_attack_indicator.stack_key
		if stack_visuals.has(sk) and stack_visuals[sk].get("expanded", false):
			# Delay collapse slightly
			var collapse_timer: SceneTreeTimer = get_tree().create_timer(0.5)
			collapse_timer.timeout.connect(func() -> void:
				if stack_visuals.has(sk):
					_collapse_stack(sk)
			)
	
	_pending_attack_indicator.clear()


## ============== ENEMY SHAKE EFFECT ==============

func shake_enemy(enemy, intensity: float = 8.0, duration: float = 0.25) -> void:
	"""Shake an enemy visual to show they're being hit."""
	var stack_key: String = str(enemy.ring) + "_" + enemy.enemy_id
	
	if stack_visuals.has(stack_key):
		_shake_stack(stack_key, intensity, duration)
	elif enemy_visuals.has(enemy.instance_id):
		_shake_individual(enemy.instance_id, intensity, duration)


func _shake_individual(instance_id: int, intensity: float, duration: float) -> void:
	"""Shake an individual enemy panel."""
	if not enemy_visuals.has(instance_id):
		return
	
	var visual: Panel = enemy_visuals[instance_id]
	
	# Use tracked base position if available, otherwise use current position
	var base_pos: Vector2
	if _enemy_base_positions.has(instance_id):
		base_pos = _enemy_base_positions[instance_id]
	else:
		base_pos = visual.position
		_enemy_base_positions[instance_id] = base_pos
	
	# Kill any existing position tween to prevent conflicts
	if _enemy_position_tweens.has(instance_id):
		var old_tween: Tween = _enemy_position_tweens[instance_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Immediately set to base position to ensure we shake from the right place
	visual.position = base_pos
	
	# Create shake tween - fewer iterations, shorter duration
	var tween: Tween = create_tween()
	var shake_count: int = 4
	var step_time: float = duration / float(shake_count + 1)
	for i: int in range(shake_count):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(visual, "position", base_pos + offset, step_time)
	tween.tween_property(visual, "position", base_pos, step_time)
	
	# Track this tween (shake ends at base position, so it counts as the position tween)
	_enemy_position_tweens[instance_id] = tween


func _shake_stack(stack_key: String, intensity: float, duration: float) -> void:
	"""Shake a stack panel."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var panel: Panel = stack_data.panel
	
	# Use tracked base position if available, otherwise use current position
	var base_pos: Vector2
	if _stack_base_positions.has(stack_key):
		base_pos = _stack_base_positions[stack_key]
	else:
		base_pos = panel.position
		_stack_base_positions[stack_key] = base_pos
	
	# Kill any existing position tween to prevent conflicts
	if _stack_position_tweens.has(stack_key):
		var old_tween: Tween = _stack_position_tweens[stack_key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Immediately set to base position to ensure we shake from the right place
	panel.position = base_pos
	
	# Create shake tween - fewer iterations, shorter duration
	var tween: Tween = create_tween()
	var shake_count: int = 4
	var step_time: float = duration / float(shake_count + 1)
	for i: int in range(shake_count):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(panel, "position", base_pos + offset, step_time)
	tween.tween_property(panel, "position", base_pos, step_time)
	
	# Track this tween
	_stack_position_tweens[stack_key] = tween


## ============== FLASH EFFECT ==============

func flash_enemy(enemy, color: Color = Color(1.5, 0.4, 0.4, 1.0), duration: float = 0.15) -> void:
	"""Flash an enemy a specific color."""
	var stack_key: String = str(enemy.ring) + "_" + enemy.enemy_id
	
	if stack_visuals.has(stack_key):
		var panel: Panel = stack_visuals[stack_key].panel
		_flash_panel(panel, color, duration)
	elif enemy_visuals.has(enemy.instance_id):
		var visual: Panel = enemy_visuals[enemy.instance_id]
		_flash_panel(visual, color, duration)


func _flash_panel(panel: Panel, color: Color, duration: float) -> void:
	"""Flash a panel a specific color."""
	var tween: Tween = panel.create_tween()
	tween.tween_property(panel, "modulate", color, duration * 0.4)
	tween.tween_property(panel, "modulate", Color.WHITE, duration * 0.6)


## ============== PROJECTILE FROM CENTER ==============

func _expand_stack_and_fire(enemy, stack_key: String, damage_amount: int = 0, is_hex: bool = false) -> void:
	"""Expand a stack first, then fire at the specific enemy's mini-card."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var main_panel: Panel = stack_data.panel
	var _enemy_id: String = main_panel.get_meta("enemy_id", "")
	
	# Expand the stack FIRST if not already expanded (fast)
	if not stack_data.expanded:
		_expand_stack(stack_key)
	
	# Brief wait for mini-cards to appear (fast)
	await get_tree().create_timer(0.1).timeout
	
	if not stack_visuals.has(stack_key):
		_cleanup_orphaned_mini_panels()
		return
	
	# Find the specific mini-card for this enemy
	var mini_panels: Array = stack_visuals[stack_key].get("mini_panels", [])
	var target_mini_panel: Panel = null
	
	# Filter out invalid instances first to avoid "freed instance" errors in typed for loop
	var valid_panels: Array = mini_panels.filter(func(p: Variant) -> bool: return is_instance_valid(p))
	
	for mini_panel in valid_panels:
		# Use instance_id from meta to avoid accessing potentially freed enemy instance
		var mini_enemy_instance_id: int = mini_panel.get_meta("instance_id", -1)
		if mini_enemy_instance_id == enemy.instance_id:
			target_mini_panel = mini_panel
			break
	
	if target_mini_panel:
		# Fire the projectile at the specific mini-card (fast projectile)
		var mini_center: Vector2 = target_mini_panel.position + target_mini_panel.size / 2
		var projectile_color: Color = Color(0.8, 0.3, 1.0) if is_hex else Color(1.0, 0.9, 0.3)
		_fire_fast_projectile_to_position(mini_center, projectile_color)
		
		# Wait for projectile to hit (short)
		await get_tree().create_timer(0.15).timeout
		
		# Flash the mini-card and show damage number ON the mini-card
		if is_instance_valid(target_mini_panel):
			var flash_color: Color = Color(0.8, 0.3, 1.0, 1.0) if is_hex else Color(1.5, 0.5, 0.5, 1.0)
			var flash_tween: Tween = target_mini_panel.create_tween()
			flash_tween.tween_property(target_mini_panel, "modulate", flash_color, 0.05)
			flash_tween.tween_property(target_mini_panel, "modulate", Color.WHITE, 0.1)
			
			# Show damage number floating above the mini-card
			if damage_amount > 0:
				_show_damage_number_at_position(target_mini_panel.position + Vector2(target_mini_panel.size.x / 2 - 15, -10), damage_amount, is_hex)
			
			# Update HP display on the mini-card
			_update_mini_panel_hp(target_mini_panel, enemy)
		
		# Auto-collapse after brief delay
		await get_tree().create_timer(0.35).timeout
		_force_collapse_stack(stack_key)
	else:
		# Fallback: fire at the stack panel
		if is_instance_valid(main_panel):
			var panel_center: Vector2 = main_panel.position + main_panel.size / 2
			_fire_fast_projectile_to_position(panel_center, Color(1.0, 0.9, 0.3))
		
		await get_tree().create_timer(0.25).timeout
		_force_collapse_stack(stack_key)


func _fire_projectile_to_position(to_pos: Vector2, projectile_color: Color = Color(1.0, 0.9, 0.3)) -> void:
	"""Fire a projectile from the warden (center) to a specific position."""
	_recalculate_layout()
	
	var from_pos: Vector2 = center
	
	# Create projectile
	var projectile: ColorRect = ColorRect.new()
	projectile.size = Vector2(12, 4)
	projectile.color = projectile_color
	projectile.position = from_pos - projectile.size / 2
	projectile.z_index = 45
	
	# Rotate to face target
	var angle: float = from_pos.angle_to_point(to_pos)
	projectile.pivot_offset = projectile.size / 2
	projectile.rotation = angle
	
	effects_container.add_child(projectile)
	
	# Calculate travel time based on distance
	var distance: float = from_pos.distance_to(to_pos)
	var travel_time: float = distance / 600.0  # 600 pixels per second
	
	# Animate
	var tween: Tween = create_tween()
	tween.tween_property(projectile, "position", to_pos - projectile.size / 2, travel_time).set_ease(Tween.EASE_OUT)
	tween.tween_callback(projectile.queue_free)
	
	# Create impact flash at destination after travel
	var impact_timer: SceneTreeTimer = get_tree().create_timer(travel_time)
	impact_timer.timeout.connect(func() -> void:
		_create_impact_flash(to_pos, projectile_color)
	)


func _fire_fast_projectile_to_position(to_pos: Vector2, projectile_color: Color = Color(1.0, 0.9, 0.3)) -> void:
	"""Fire a FAST projectile from the warden (center) to a specific position."""
	_recalculate_layout()
	
	var from_pos: Vector2 = center
	
	# Create projectile (slightly larger for visibility at speed)
	var projectile: ColorRect = ColorRect.new()
	projectile.size = Vector2(16, 5)
	projectile.color = projectile_color
	projectile.position = from_pos - projectile.size / 2
	projectile.z_index = 45
	
	# Rotate to face target
	var angle: float = from_pos.angle_to_point(to_pos)
	projectile.pivot_offset = projectile.size / 2
	projectile.rotation = angle
	
	effects_container.add_child(projectile)
	
	# FAST travel time - 1500 pixels per second
	var distance: float = from_pos.distance_to(to_pos)
	var travel_time: float = distance / 1500.0
	
	# Animate
	var tween: Tween = create_tween()
	tween.tween_property(projectile, "position", to_pos - projectile.size / 2, travel_time).set_ease(Tween.EASE_OUT)
	tween.tween_callback(projectile.queue_free)
	
	# Create impact flash at destination after travel
	var impact_timer: SceneTreeTimer = get_tree().create_timer(travel_time)
	impact_timer.timeout.connect(func() -> void:
		_create_impact_flash(to_pos, projectile_color)
	)


func _show_damage_number_at_position(pos: Vector2, amount: int, is_hex: bool = false) -> void:
	"""Show a floating damage number at a specific position."""
	var label: Label = Label.new()
	label.text = "-" + str(amount)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0, 1.0) if is_hex else Color(1.0, 0.3, 0.3, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 60
	label.position = pos
	
	damage_numbers.add_child(label)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(label.queue_free)


func _update_mini_panel_hp(mini_panel: Panel, enemy) -> void:
	"""Update the HP display on a mini-panel."""
	if not is_instance_valid(mini_panel):
		return
	
	# Safety check - verify enemy instance_id matches before accessing properties
	# This prevents errors when enemy instance has been freed
	var stored_instance_id: int = mini_panel.get_meta("instance_id", -1)
	if stored_instance_id == -1 or enemy == null:
		return
	
	# Check if enemy instance_id matches before accessing - avoid accessing freed instances
	# We check stored_instance_id first to avoid accessing enemy.instance_id if enemy is freed
	if stored_instance_id != enemy.instance_id:
		return
	
	var hp_fill: ColorRect = mini_panel.get_node_or_null("HPFill")
	var hp_text: Label = mini_panel.get_node_or_null("HPText")
	
	if hp_fill:
		var hp_percent: float = enemy.get_hp_percentage()
		var max_width: float = float(hp_fill.get_meta("max_width", hp_fill.size.x))
		hp_fill.size.x = max_width * hp_percent
		hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	
	if hp_text:
		hp_text.text = str(enemy.current_hp) + "/" + str(enemy.max_hp)


func fire_projectile_to_enemy(enemy, projectile_color: Color = Color(1.0, 0.9, 0.3)) -> void:
	"""Fire a projectile from the warden (center) to an enemy."""
	var to_pos: Vector2 = _get_enemy_center_position(enemy)
	
	if to_pos == Vector2.ZERO:
		return
	
	_fire_projectile_to_position(to_pos, projectile_color)


func _fire_fast_projectile_to_enemy(enemy, projectile_color: Color = Color(1.0, 0.9, 0.3)) -> void:
	"""Fire a FAST projectile from the warden (center) to an enemy."""
	var to_pos: Vector2 = _get_enemy_center_position(enemy)
	
	if to_pos == Vector2.ZERO:
		return
	
	_fire_fast_projectile_to_position(to_pos, projectile_color)


func _expand_stack_and_show_hex(enemy, stack_key: String, hex_amount: int) -> void:
	"""Expand a stack and show hex effect on the specific enemy's mini-card with purple shake."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	
	# Expand the stack if not already expanded
	if not stack_data.expanded:
		_expand_stack(stack_key)
	
	# Brief wait for mini-cards to appear
	await get_tree().create_timer(0.1).timeout
	
	if not stack_visuals.has(stack_key):
		_cleanup_orphaned_mini_panels()
		return
	
	# Find the specific mini-card
	var mini_panels: Array = stack_visuals[stack_key].get("mini_panels", [])
	var target_mini_panel: Panel = null
	
	for mini_panel: Panel in mini_panels:
		if not is_instance_valid(mini_panel):
			continue
		# Use instance_id from meta to avoid accessing potentially freed enemy instance
		var mini_enemy_instance_id: int = mini_panel.get_meta("instance_id", -1)
		if mini_enemy_instance_id == enemy.instance_id:
			target_mini_panel = mini_panel
			break
	
	if target_mini_panel and is_instance_valid(target_mini_panel):
		# Purple shake effect on the mini-card (no projectile)
		var base_pos: Vector2 = target_mini_panel.position
		var shake_tween: Tween = target_mini_panel.create_tween()
		
		# Tint purple and shake horizontally
		shake_tween.tween_property(target_mini_panel, "modulate", Color(0.8, 0.3, 1.0, 1.0), 0.05)
		shake_tween.parallel().tween_property(target_mini_panel, "position:x", base_pos.x + 4, 0.05)
		shake_tween.tween_property(target_mini_panel, "position:x", base_pos.x - 4, 0.05)
		shake_tween.tween_property(target_mini_panel, "position:x", base_pos.x + 3, 0.05)
		shake_tween.tween_property(target_mini_panel, "position:x", base_pos.x - 3, 0.05)
		shake_tween.tween_property(target_mini_panel, "position:x", base_pos.x + 2, 0.05)
		shake_tween.tween_property(target_mini_panel, "position:x", base_pos.x, 0.05)
		shake_tween.parallel().tween_property(target_mini_panel, "modulate", Color.WHITE, 0.15)
		
		# Show hex amount floating above
		_show_hex_number_at_position(
			target_mini_panel.position + Vector2(target_mini_panel.size.x / 2 - 15, -10),
			hex_amount
		)
		
		# Update hex display on the mini-card
		_update_mini_panel_hex(target_mini_panel, enemy)
		
		# Auto-collapse after brief delay
		await get_tree().create_timer(0.5).timeout
		_force_collapse_stack(stack_key)
	else:
		# Fallback - shake main panel purple
		var main_panel: Panel = stack_data.panel
		if is_instance_valid(main_panel):
			var base_pos: Vector2 = main_panel.position
			var shake_tween: Tween = main_panel.create_tween()
			shake_tween.tween_property(main_panel, "modulate", Color(0.8, 0.3, 1.0, 1.0), 0.05)
			shake_tween.parallel().tween_property(main_panel, "position:x", base_pos.x + 4, 0.05)
			shake_tween.tween_property(main_panel, "position:x", base_pos.x - 4, 0.05)
			shake_tween.tween_property(main_panel, "position:x", base_pos.x + 2, 0.05)
			shake_tween.tween_property(main_panel, "position:x", base_pos.x, 0.05)
			shake_tween.parallel().tween_property(main_panel, "modulate", Color.WHITE, 0.15)
		
		await get_tree().create_timer(0.4).timeout
		_force_collapse_stack(stack_key)


func _show_hex_effect_on_enemy(enemy, hex_amount: int) -> void:
	"""Show hex effect on an individual (non-stacked) enemy with purple shake."""
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	
	if not is_instance_valid(visual):
		return
	
	# Purple shake effect (no projectile)
	var base_pos: Vector2 = visual.position
	var shake_tween: Tween = visual.create_tween()
	
	# Tint purple and shake horizontally
	shake_tween.tween_property(visual, "modulate", Color(0.8, 0.3, 1.0, 1.0), 0.05)
	shake_tween.parallel().tween_property(visual, "position:x", base_pos.x + 5, 0.05)
	shake_tween.tween_property(visual, "position:x", base_pos.x - 5, 0.05)
	shake_tween.tween_property(visual, "position:x", base_pos.x + 4, 0.05)
	shake_tween.tween_property(visual, "position:x", base_pos.x - 4, 0.05)
	shake_tween.tween_property(visual, "position:x", base_pos.x + 2, 0.05)
	shake_tween.tween_property(visual, "position:x", base_pos.x, 0.05)
	shake_tween.parallel().tween_property(visual, "modulate", Color.WHITE, 0.15)
	
	# Show hex amount floating above
	_show_hex_number_at_position(
		visual.position + Vector2(visual.size.x / 2 - 15, -15),
		hex_amount
	)
	
	# Update hex indicator on the enemy visual
	_update_enemy_hp_display(enemy, visual)


func _show_hex_number_at_position(pos: Vector2, amount: int) -> void:
	"""Show a floating hex number at a specific position."""
	var label: Label = Label.new()
	label.text = "+☠" + str(amount)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 60
	label.position = pos
	
	damage_numbers.add_child(label)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 35, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(label.queue_free)


func _update_mini_panel_hex(mini_panel: Panel, enemy) -> void:
	"""Update or add hex display on a mini-panel."""
	if not is_instance_valid(mini_panel):
		return
	
	var hex_stacks: int = enemy.get_status_value("hex")
	var hex_label: Label = mini_panel.get_node_or_null("HexLabel")
	
	if hex_stacks > 0:
		if hex_label:
			hex_label.text = "☠️" + str(hex_stacks)
			hex_label.visible = true
		else:
			# Create hex label if it doesn't exist
			hex_label = Label.new()
			hex_label.name = "HexLabel"
			hex_label.position = Vector2(0.0, mini_panel.size.y * 0.78)
			hex_label.size = Vector2(mini_panel.size.x, 14.0)
			hex_label.add_theme_font_size_override("font_size", 9)
			hex_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0, 1.0))
			hex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hex_label.text = "☠️" + str(hex_stacks)
			hex_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini_panel.add_child(hex_label)
	elif hex_label:
		hex_label.visible = false


func _get_enemy_center_position(enemy) -> Vector2:
	"""Get the center position of an enemy's visual."""
	var stack_key: String = str(enemy.ring) + "_" + enemy.enemy_id
	
	if stack_visuals.has(stack_key):
		var panel: Panel = stack_visuals[stack_key].panel
		return panel.position + panel.size / 2
	elif enemy_visuals.has(enemy.instance_id):
		var visual: Panel = enemy_visuals[enemy.instance_id]
		return visual.position + visual.size / 2
	
	return Vector2.ZERO


func _create_impact_flash(pos: Vector2, color: Color) -> void:
	"""Create a small impact flash at a position."""
	var flash: ColorRect = ColorRect.new()
	flash.size = Vector2(20, 20)
	flash.color = color
	flash.position = pos - flash.size / 2
	flash.z_index = 46
	
	effects_container.add_child(flash)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(2.5, 2.5), 0.15)
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(flash.queue_free)


## ============== ENEMY TURN VISUAL FEEDBACK ==============

func show_enemy_attack_intent(enemy, damage: int) -> void:
	"""Show visual feedback that an enemy is about to attack."""
	var stack_key: String = str(enemy.ring) + "_" + enemy.enemy_id
	var target_panel: Panel = null
	
	# Find the visual for this enemy
	if stack_visuals.has(stack_key):
		target_panel = stack_visuals[stack_key].panel
	elif enemy_visuals.has(enemy.instance_id):
		target_panel = enemy_visuals[enemy.instance_id]
	
	if not target_panel or not is_instance_valid(target_panel):
		return
	
	# Create attack intent indicator
	var intent_label: Label = Label.new()
	intent_label.text = "⚔️ " + str(damage)
	intent_label.add_theme_font_size_override("font_size", 18)
	intent_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	intent_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	intent_label.add_theme_constant_override("outline_size", 2)
	intent_label.z_index = 60
	intent_label.position = target_panel.position + Vector2(target_panel.size.x / 2 - 20, -25)
	
	enemy_container.add_child(intent_label)
	
	# Flash the enemy panel red
	var original_modulate: Color = target_panel.modulate
	var flash_tween: Tween = target_panel.create_tween()
	flash_tween.tween_property(target_panel, "modulate", Color(1.5, 0.4, 0.4, 1.0), 0.1)
	flash_tween.tween_property(target_panel, "modulate", original_modulate, 0.1)
	
	# Animate intent label
	var label_tween: Tween = intent_label.create_tween()
	label_tween.tween_property(intent_label, "position:y", intent_label.position.y - 15, 0.3)
	label_tween.parallel().tween_property(intent_label, "modulate:a", 0.0, 0.3).set_delay(0.15)
	label_tween.tween_callback(intent_label.queue_free)


func update_enemy_ring(_enemy, _from_ring: int, _to_ring: int) -> void:
	"""Update enemy visual when they move between rings."""
	# The existing enemy display system handles movement via signal connections
	# Just trigger a redraw to update positions
	queue_redraw()


func _on_enemy_move_debug_tick(timer: Timer) -> void:
	"""Debug callback for enemy movement tracking."""
	var visual: Panel = timer.get_meta("visual", null)
	var tween: Tween = timer.get_meta("tween", null)
	var enemy_id: String = timer.get_meta("enemy_id", "unknown")
	var target_pos: Vector2 = timer.get_meta("target_pos", Vector2.ZERO)
	var instance_id: int = timer.get_meta("instance_id", -1)
	var frame_count: int = timer.get_meta("frame_count", 0)
	frame_count += 1
	timer.set_meta("frame_count", frame_count)
	
	# Stop timer if tween is invalid or visual is invalid
	if not is_instance_valid(visual) or not tween or not tween.is_valid():
		# Clean up the timer
		timer.stop()
		timer.queue_free()
		if instance_id >= 0 and _enemy_debug_timers.has(instance_id):
			_enemy_debug_timers.erase(instance_id)
		return
	
	print("[BattlefieldArena DEBUG] Enemy moving [frame ", frame_count, "] - ", enemy_id, 
		  " | pos: ", visual.position, " | global: ", visual.global_position,
		  " | target: ", target_pos, " | distance to target: ", visual.position.distance_to(target_pos))
	print("[BattlefieldArena DEBUG]   -> Tween is valid")


func _on_enemy_move_tween_finished(instance_id: int, target_pos: Vector2, debug_timer: Timer) -> void:
	"""Debug callback when enemy movement tween finishes."""
	var visual: Panel = null
	var enemy_id: String = "unknown"
	if is_instance_valid(debug_timer):
		visual = debug_timer.get_meta("visual", null)
		enemy_id = debug_timer.get_meta("enemy_id", "unknown")
	print("[BattlefieldArena DEBUG] Enemy movement tween finished - ", enemy_id, 
		  " | final pos: ", visual.position if is_instance_valid(visual) else Vector2.ZERO,
		  " | target was: ", target_pos)
	
	# Clean up debug timer
	if is_instance_valid(debug_timer):
		debug_timer.stop()
		debug_timer.queue_free()
	
	if _enemy_debug_timers.has(instance_id):
		_enemy_debug_timers.erase(instance_id)
	
	if _enemy_position_tweens.has(instance_id):
		_enemy_position_tweens.erase(instance_id)
