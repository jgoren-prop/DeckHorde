extends Control
class_name BattlefieldEnemyManager
## Manages individual enemy visuals on the battlefield.
## Owns enemy_visuals dictionary and handles creation, positioning, updating, and death.

signal enemy_hover_entered(visual: Panel, enemy)
signal enemy_hover_exited(visual: Panel)
signal enemy_death_started(enemy, visual: Panel)
signal enemy_death_finished(enemy)

const IndividualEnemyPanelScene = preload("res://scenes/combat/components/IndividualEnemyPanel.tscn")
const BattlefieldEffectsHelper = preload("res://scripts/combat/BattlefieldEffects.gd")

# Enemy colors - shared constant
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
var enemy_visuals: Dictionary = {}  # instance_id -> Panel
var destroyed_visuals: Dictionary = {}  # instance_id -> Panel (destroyed enemies that remain visible)

# Position tracking to prevent animation conflicts
var _enemy_base_positions: Dictionary = {}  # instance_id -> Vector2
var _enemy_position_tweens: Dictionary = {}  # instance_id -> Tween
var _enemy_scale_tweens: Dictionary = {}  # instance_id -> Tween

# Layout info (set by parent)
var arena_center: Vector2 = Vector2.ZERO
var arena_max_radius: float = 200.0
var ring_proportions: Array[float] = [0.18, 0.42, 0.68, 0.95]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func get_enemy_color(enemy_id: String) -> Color:
	"""Get the color for an enemy type."""
	return ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))


func create_enemy_visual(enemy) -> Panel:
	"""Create a visual panel for an individual enemy."""
	var visual_size: Vector2 = _get_enemy_visual_size()
	var color: Color = get_enemy_color(enemy.enemy_id)
	
	var visual: Panel = IndividualEnemyPanelScene.instantiate()
	visual.setup(enemy, color, visual_size)
	
	# Connect to panel's hover signals
	visual.hover_entered.connect(_on_panel_hover_entered)
	visual.hover_exited.connect(_on_panel_hover_exited)
	
	add_child(visual)
	enemy_visuals[enemy.instance_id] = visual
	
	# Set initial position
	update_enemy_position(enemy)
	
	return visual


func update_enemy_position(enemy, animate: bool = false) -> void:
	"""Update an enemy's visual position based on their ring."""
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	var target_pos: Vector2 = _calculate_enemy_position(enemy)
	
	# Store base position
	_enemy_base_positions[enemy.instance_id] = target_pos
	
	if animate:
		_animate_to_position(enemy.instance_id, visual, target_pos)
	else:
		visual.position = target_pos


func update_enemy_hp(enemy) -> void:
	"""Update the HP display for an enemy."""
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	if visual.has_method("update_hp"):
		visual.update_hp()
		visual.update_hex()
		visual.update_intent()


func get_enemy_visual(instance_id: int) -> Panel:
	"""Get the visual panel for an enemy."""
	return enemy_visuals.get(instance_id, null)


func get_enemy_center_position(instance_id: int) -> Vector2:
	"""Get the center position of an enemy's visual via its instance_id."""
	if enemy_visuals.has(instance_id):
		var visual: Panel = enemy_visuals[instance_id]
		return visual.position + visual.size / 2
	
	if destroyed_visuals.has(instance_id):
		var destroyed_visual: Panel = destroyed_visuals[instance_id]
		return destroyed_visual.position + destroyed_visual.size / 2
	
	return Vector2.ZERO


func has_enemy_visual(instance_id: int) -> bool:
	"""Check if we have a visual for this enemy."""
	return enemy_visuals.has(instance_id)


func hide_enemy_visual(instance_id: int) -> void:
	"""Hide an enemy's visual (used when stacking)."""
	if enemy_visuals.has(instance_id):
		enemy_visuals[instance_id].visible = false


func show_enemy_visual(instance_id: int) -> void:
	"""Show an enemy's visual."""
	if enemy_visuals.has(instance_id):
		enemy_visuals[instance_id].visible = true


func play_death_animation(enemy) -> void:
	"""Play death animation for an enemy."""
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	enemy_death_started.emit(enemy, visual)
	
	# Kill any active tweens
	_kill_enemy_tweens(enemy.instance_id)
	
	# Store in destroyed visuals
	destroyed_visuals[enemy.instance_id] = visual
	enemy_visuals.erase(enemy.instance_id)
	
	# Get position for particles
	var death_pos: Vector2 = visual.position + visual.size / 2
	var color: Color = get_enemy_color(enemy.enemy_id)
	
	# Spawn death particles
	BattlefieldEffectsHelper.spawn_death_particles(self, death_pos, color)
	
	# Animate destruction
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "modulate", Color(1.5, 0.5, 0.5, 0.0), 0.4)
	tween.tween_property(visual, "scale", Vector2(0.3, 0.3), 0.4).set_ease(Tween.EASE_IN)
	tween.tween_property(visual, "rotation", randf_range(-0.5, 0.5), 0.4)
	tween.set_parallel(false)
	tween.tween_callback(func():
		if is_instance_valid(visual):
			visual.queue_free()
		destroyed_visuals.erase(enemy.instance_id)
		enemy_death_finished.emit(enemy)
	)


func shake_enemy(instance_id: int, intensity: float = 8.0, duration: float = 0.25) -> void:
	"""Shake an enemy visual."""
	if not enemy_visuals.has(instance_id):
		return
	
	var visual: Panel = enemy_visuals[instance_id]
	var base_pos: Vector2 = _enemy_base_positions.get(instance_id, visual.position)
	
	# Kill existing position tween
	if _enemy_position_tweens.has(instance_id):
		var old_tween: Tween = _enemy_position_tweens[instance_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	visual.position = base_pos
	
	var tween: Tween = create_tween()
	var shake_count: int = 4
	var step_time: float = duration / float(shake_count + 1)
	for i: int in range(shake_count):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(visual, "position", base_pos + offset, step_time)
	tween.tween_property(visual, "position", base_pos, step_time)
	
	_enemy_position_tweens[instance_id] = tween


func flash_enemy(instance_id: int, color: Color = Color(1.5, 0.4, 0.4, 1.0), duration: float = 0.15) -> void:
	"""Flash an enemy visual."""
	if not enemy_visuals.has(instance_id):
		return
	
	var visual: Panel = enemy_visuals[instance_id]
	var tween: Tween = visual.create_tween()
	tween.tween_property(visual, "modulate", color, duration * 0.4)
	tween.tween_property(visual, "modulate", Color.WHITE, duration * 0.6)


func clear_all() -> void:
	"""Clear all enemy visuals."""
	for instance_id: int in enemy_visuals.keys():
		_kill_enemy_tweens(instance_id)
		var visual: Panel = enemy_visuals[instance_id]
		if is_instance_valid(visual):
			visual.queue_free()
	enemy_visuals.clear()
	_enemy_base_positions.clear()
	
	for instance_id: int in destroyed_visuals.keys():
		var visual: Panel = destroyed_visuals[instance_id]
		if is_instance_valid(visual):
			visual.queue_free()
	destroyed_visuals.clear()


func clear_destroyed_visuals() -> void:
	"""Clear only destroyed enemy visuals."""
	for instance_id: int in destroyed_visuals.keys():
		var visual: Panel = destroyed_visuals[instance_id]
		if is_instance_valid(visual):
			visual.queue_free()
	destroyed_visuals.clear()


# ============== PRIVATE METHODS ==============

func _get_enemy_visual_size() -> Vector2:
	"""Get the standard size for enemy visuals."""
	return Vector2(110, 120)


func _calculate_enemy_position(enemy) -> Vector2:
	"""Calculate the position for an enemy based on their ring and index."""
	var ring: int = enemy.ring
	
	# Get ring radius
	var outer_radius: float = arena_max_radius * ring_proportions[ring]
	var inner_radius: float = 0.0
	if ring > 0:
		inner_radius = arena_max_radius * ring_proportions[ring - 1]
	var ring_radius: float = (inner_radius + outer_radius) / 2.0
	
	# Use stored angular position if available, otherwise calculate
	var angle: float = PI * 1.5  # Default to top
	
	# Calculate position
	var offset: Vector2 = Vector2(cos(angle), sin(angle)) * ring_radius
	var visual_size: Vector2 = _get_enemy_visual_size()
	
	return arena_center + offset - visual_size / 2


func _animate_to_position(instance_id: int, visual: Panel, target_pos: Vector2) -> void:
	"""Animate an enemy to a new position."""
	# Kill existing tween
	if _enemy_position_tweens.has(instance_id):
		var old_tween: Tween = _enemy_position_tweens[instance_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	var tween: Tween = create_tween()
	tween.tween_property(visual, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_enemy_position_tweens[instance_id] = tween


func _kill_enemy_tweens(instance_id: int) -> void:
	"""Kill all tweens for an enemy."""
	if _enemy_position_tweens.has(instance_id):
		var tween: Tween = _enemy_position_tweens[instance_id]
		if tween and tween.is_valid():
			tween.kill()
		_enemy_position_tweens.erase(instance_id)
	
	if _enemy_scale_tweens.has(instance_id):
		var tween: Tween = _enemy_scale_tweens[instance_id]
		if tween and tween.is_valid():
			tween.kill()
		_enemy_scale_tweens.erase(instance_id)


func _on_panel_hover_entered(panel: Panel, enemy) -> void:
	"""Forward hover enter signal."""
	enemy_hover_entered.emit(panel, enemy)


func _on_panel_hover_exited(panel: Panel) -> void:
	"""Forward hover exit signal."""
	enemy_hover_exited.emit(panel)
