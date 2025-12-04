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
var _group_angular_positions: Dictionary = {}  # group_id -> float

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
	
	return stack_key


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


func update_stack_hp(stack_key: String) -> void:
	"""Update HP display for a stack."""
	if not stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = stack_visuals[stack_key]
	var panel: Panel = stack_data.panel
	
	if is_instance_valid(panel) and panel.has_method("update_hp"):
		panel.update_hp()


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
	var mini_size: Vector2 = Vector2(55, 50)
	var spacing: float = mini_size.x + 6
	var total_width: float = spacing * enemies.size() - 6
	var start_x: float = panel.position.x + panel.size.x / 2 - total_width / 2
	var base_y: float = panel.position.y + panel.size.y + 8
	
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


func clear_all() -> void:
	"""Clear all stacks."""
	for stack_key: String in stack_visuals.keys():
		remove_stack(stack_key)
	stack_visuals.clear()
	enemy_groups.clear()
	_stack_base_positions.clear()
	_group_positions.clear()
	_group_angular_positions.clear()


# ============== PRIVATE METHODS ==============

func _get_stack_visual_size() -> Vector2:
	"""Get the standard size for stack visuals."""
	return Vector2(110, 120)


func _generate_stack_key(ring: int, enemy_id: String) -> String:
	"""Generate a unique stack key."""
	_next_group_id += 1
	return str(ring) + "_" + enemy_id + "_group_" + str(_next_group_id)


func _calculate_stack_position(ring: int, stack_key: String) -> Vector2:
	"""Calculate position for a stack based on ring."""
	var outer_radius: float = arena_max_radius * ring_proportions[ring]
	var inner_radius: float = 0.0
	if ring > 0:
		inner_radius = arena_max_radius * ring_proportions[ring - 1]
	var ring_radius: float = (inner_radius + outer_radius) / 2.0
	
	# Use stored angular position or default to top
	var angle: float = _group_angular_positions.get(stack_key, PI * 1.5)
	
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * ring_radius
	var visual_size: Vector2 = _get_stack_visual_size()
	
	return arena_center + offset - visual_size / 2


func _animate_stack_to_position(stack_key: String, panel: Panel, target_pos: Vector2) -> void:
	"""Animate a stack to a new position."""
	if _stack_position_tweens.has(stack_key):
		var old_tween: Tween = _stack_position_tweens[stack_key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	var tween: Tween = create_tween()
	tween.tween_property(panel, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_stack_position_tweens[stack_key] = tween


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
	# Schedule collapse after delay
	if not _in_weapons_phase:
		var timer: SceneTreeTimer = get_tree().create_timer(0.3)
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

