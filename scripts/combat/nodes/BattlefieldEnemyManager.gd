extends Control
class_name BattlefieldEnemyManager
## Manages individual enemy visuals on the battlefield.
## Owns enemy_visuals dictionary and handles creation, positioning, updating, and death.
## V2: Horizontal lane layout - enemies positioned within horizontal lane bands.

signal enemy_hover_entered(visual: Panel, enemy)
signal enemy_hover_exited(visual: Panel)
signal enemy_death_started(enemy, visual: Panel)
signal enemy_death_finished(enemy)

const IndividualEnemyPanelScene = preload("res://scenes/combat/components/IndividualEnemyPanel.tscn")
const BattlefieldEffectsHelper = preload("res://scripts/combat/BattlefieldEffects.gd")

# Total horizontal slots (matches stack system)
const TOTAL_SLOTS: int = 12

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
	"weakling": Color(0.5, 0.5, 0.5),
	"mite": Color(0.45, 0.35, 0.3),
	"swarmling": Color(0.55, 0.4, 0.35),
	"drone": Color(0.4, 0.4, 0.45)
}

# State
var enemy_visuals: Dictionary = {}  # instance_id -> Panel
var destroyed_visuals: Dictionary = {}  # instance_id -> Panel (destroyed enemies that remain visible)

# Position tracking to prevent animation conflicts
var _enemy_base_positions: Dictionary = {}  # instance_id -> Vector2
var _enemy_position_tweens: Dictionary = {}  # instance_id -> Tween
var _enemy_scale_tweens: Dictionary = {}  # instance_id -> Tween

# Slot tracking for individual enemy placement (horizontal position)
var _enemy_slots: Dictionary = {}  # instance_id -> int (0-11)

# Legacy angular position tracking (converted to/from slots)
var _enemy_angular_positions: Dictionary = {}  # instance_id -> float (for compatibility)

# Lane tracking for individual enemies (to ensure consistency with stack system)
var _enemy_lanes: Dictionary = {}  # instance_id -> int

# Layout info (set by parent) - V2 uses lane rectangles
var arena_center: Vector2 = Vector2.ZERO  # Kept for compatibility
var arena_max_radius: float = 200.0  # Kept for compatibility
var lane_rects: Array[Rect2] = []  # Lane rectangles [MELEE, CLOSE, MID, FAR]
var arena_padding: float = 10.0

# Z-index values per ring (Melee renders above Close, etc.)
const RING_Z_INDEX: Array[int] = [4, 3, 2, 1]  # Melee, Close, Mid, Far


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func get_enemy_color(enemy_id: String) -> Color:
	"""Get the color for an enemy type."""
	return ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))


func set_enemy_slot(instance_id: int, slot: int) -> void:
	"""Set the horizontal slot for an enemy (0-11, left to right)."""
	_enemy_slots[instance_id] = clampi(slot, 0, TOTAL_SLOTS - 1)


func get_enemy_slot(instance_id: int) -> int:
	"""Get the horizontal slot for an enemy. Returns center slot (6) if not set."""
	@warning_ignore("integer_division")
	return _enemy_slots.get(instance_id, TOTAL_SLOTS / 2)


func set_enemy_angular_position(instance_id: int, angle: float) -> void:
	"""DEPRECATED: V2 uses horizontal slots. Converts angle to slot for compatibility."""
	_enemy_angular_positions[instance_id] = angle
	# Convert angle to slot: PI (left) = 0, 2*PI (right) = TOTAL_SLOTS-1
	var normalized: float = (angle - PI) / PI
	var slot: int = clampi(roundi(normalized * float(TOTAL_SLOTS - 1)), 0, TOTAL_SLOTS - 1)
	_enemy_slots[instance_id] = slot


func get_enemy_angular_position(instance_id: int) -> float:
	"""DEPRECATED: V2 uses horizontal slots. Returns fake angle for compatibility."""
	if _enemy_angular_positions.has(instance_id):
		return _enemy_angular_positions[instance_id]
	# Convert slot back to angle
	var slot: int = get_enemy_slot(instance_id)
	return PI + (float(slot) / float(TOTAL_SLOTS - 1)) * PI


func set_enemy_lane(instance_id: int, lane: int) -> void:
	"""Set the slot for an enemy (alias for backward compatibility)."""
	set_enemy_slot(instance_id, lane)


func get_enemy_lane(instance_id: int) -> int:
	"""Get the slot for an enemy (alias for backward compatibility)."""
	return get_enemy_slot(instance_id)


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
	
	# Set z_index based on ring (Melee renders above Close, etc.)
	visual.z_index = _get_ring_z_index(enemy.ring)
	
	# Set initial position
	update_enemy_position(enemy)
	
	return visual


func _get_ring_z_index(ring: int) -> int:
	"""Get the z_index for a given ring. Melee (0) is highest, Far (3) is lowest."""
	if ring >= 0 and ring < RING_Z_INDEX.size():
		return RING_Z_INDEX[ring]
	return 1  # Default to Far's z_index


func update_enemy_position(enemy, animate: bool = false) -> void:
	"""Update an enemy's visual position based on their ring."""
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	var target_pos: Vector2 = _calculate_enemy_position(enemy)
	
	# Store base position
	_enemy_base_positions[enemy.instance_id] = target_pos
	
	# Update z_index when ring changes
	visual.z_index = _get_ring_z_index(enemy.ring)
	
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
	_enemy_angular_positions.clear()
	_enemy_slots.clear()
	_enemy_lanes.clear()
	
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
	"""Calculate the position for an enemy based on their ring and horizontal slot.
	V2: Uses horizontal positioning within lane rectangles."""
	var ring: int = enemy.ring
	
	# Get lane rectangle for this ring
	var lane_rect: Rect2 = _get_lane_rect_for_ring(ring)
	
	# Get slot position
	var slot: int = get_enemy_slot(enemy.instance_id)
	
	# Convert slot to X position within the lane
	var x_pos: float = _slot_to_x_position(slot, lane_rect)
	
	# Y position is centered in the lane
	var visual_size: Vector2 = _get_enemy_visual_size()
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
	"""Convert a slot index (0-11) to an X position within the lane."""
	slot = clampi(slot, 0, TOTAL_SLOTS - 1)
	var usable_width: float = lane_rect.size.x - 40  # Padding on edges
	var x_start: float = lane_rect.position.x + 20
	return x_start + (float(slot) / float(TOTAL_SLOTS - 1)) * usable_width


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
