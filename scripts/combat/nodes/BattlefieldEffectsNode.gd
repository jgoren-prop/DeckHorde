extends Control
class_name BattlefieldEffectsNode
## Handles all visual effects on the battlefield: projectiles, impacts, damage numbers.

const DamageNumberClass = preload("res://scripts/combat/components/DamageNumber.gd")
const BattlefieldEffectsHelper = preload("res://scripts/combat/BattlefieldEffects.gd")

# Layout info (set by parent)
var arena_center: Vector2 = Vector2.ZERO

# Reference to combat_lane for weapon positions
var combat_lane: Control = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func fire_projectile_to_position(to_pos: Vector2, color: Color = Color(1.0, 0.9, 0.3)) -> void:
	"""Fire a projectile from center to a position."""
	var from_pos: Vector2 = arena_center
	
	var projectile: ColorRect = ColorRect.new()
	projectile.size = Vector2(12, 4)
	projectile.color = color
	projectile.position = from_pos - projectile.size / 2
	projectile.z_index = 45
	
	var angle: float = from_pos.angle_to_point(to_pos)
	projectile.pivot_offset = projectile.size / 2
	projectile.rotation = angle
	
	add_child(projectile)
	
	var distance: float = from_pos.distance_to(to_pos)
	var travel_time: float = distance / 600.0
	
	var tween: Tween = create_tween()
	tween.tween_property(projectile, "position", to_pos - projectile.size / 2, travel_time).set_ease(Tween.EASE_OUT)
	tween.tween_callback(projectile.queue_free)
	
	# Impact flash
	var impact_timer: SceneTreeTimer = get_tree().create_timer(travel_time)
	impact_timer.timeout.connect(func():
		create_impact_flash(to_pos, color)
	)


func fire_fast_projectile_to_position(to_pos: Vector2, color: Color = Color(1.0, 0.9, 0.3), weapon_index: int = -1) -> void:
	"""Fire a fast projectile, optionally from a weapon card."""
	var from_pos: Vector2 = arena_center
	
	# Get weapon position if available
	if weapon_index >= 0 and combat_lane:
		if combat_lane.has_method("animate_pistol_fire_at_index"):
			var target_global: Vector2 = to_pos + global_position
			await combat_lane.animate_pistol_fire_at_index(weapon_index, target_global)
		
		if combat_lane.has_method("get_pistol_barrel_position"):
			var barrel_pos: Vector2 = combat_lane.get_pistol_barrel_position(weapon_index)
			if barrel_pos != Vector2.ZERO:
				from_pos = barrel_pos - global_position
			elif combat_lane.has_method("get_weapon_position_by_index"):
				var weapon_pos: Vector2 = combat_lane.get_weapon_position_by_index(weapon_index)
				if weapon_pos != Vector2.ZERO:
					from_pos = weapon_pos - global_position
		elif combat_lane.has_method("get_weapon_position_by_index"):
			var weapon_pos: Vector2 = combat_lane.get_weapon_position_by_index(weapon_index)
			if weapon_pos != Vector2.ZERO:
				from_pos = weapon_pos - global_position
	
	var projectile: ColorRect = ColorRect.new()
	projectile.size = Vector2(16, 5)
	projectile.color = color
	projectile.position = from_pos - projectile.size / 2
	projectile.z_index = 45
	
	var angle: float = from_pos.angle_to_point(to_pos)
	projectile.pivot_offset = projectile.size / 2
	projectile.rotation = angle
	
	add_child(projectile)
	
	var distance: float = from_pos.distance_to(to_pos)
	var travel_time: float = distance / 1500.0
	
	var tween: Tween = create_tween()
	tween.tween_property(projectile, "position", to_pos - projectile.size / 2, travel_time).set_ease(Tween.EASE_OUT)
	tween.tween_callback(projectile.queue_free)
	
	var impact_timer: SceneTreeTimer = get_tree().create_timer(travel_time)
	impact_timer.timeout.connect(func():
		create_impact_flash(to_pos, color)
	)


func create_impact_flash(pos: Vector2, color: Color) -> void:
	"""Create an impact flash effect."""
	var flash: Panel = Panel.new()
	flash.custom_minimum_size = Vector2(20, 20)
	flash.size = Vector2(20, 20)
	flash.position = pos - Vector2(10, 10)
	flash.z_index = 50
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color.lightened(0.3)
	style.set_corner_radius_all(10)
	flash.add_theme_stylebox_override("panel", style)
	
	add_child(flash)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.15)
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.set_parallel(false)
	tween.tween_callback(flash.queue_free)


func show_damage_number(pos: Vector2, amount: int, is_hex: bool = false) -> void:
	"""Show a floating damage number."""
	DamageNumberClass.create_at(self, pos, amount, is_hex)


func show_hex_stack_number(pos: Vector2, amount: int) -> void:
	"""Show a hex stack number."""
	DamageNumberClass.create_hex_stack_at(self, pos, amount)


func show_player_damage(amount: int) -> void:
	"""Show player damage number at bottom of screen."""
	var pos: Vector2 = Vector2(size.x / 2 - 20, size.y - 80)
	DamageNumberClass.create_player_damage_at(self, pos, amount)


func spawn_death_particles(pos: Vector2, color: Color, count: int = 12) -> void:
	"""Spawn death particle effects."""
	BattlefieldEffectsHelper.spawn_death_particles(self, pos, color, count)


func fire_barrier_sparks(from_pos: Vector2, to_pos: Vector2) -> void:
	"""Fire barrier trigger sparks."""
	BattlefieldEffectsHelper.create_barrier_sparks(self, from_pos, to_pos)


func create_attack_reticle(panel_size: Vector2, is_mini: bool = false) -> Control:
	"""Create an attack targeting reticle."""
	var reticle: Control = Control.new()
	var size_mult: float = 1.4 if not is_mini else 1.3
	reticle.size = panel_size * size_mult
	
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
		
		var tween: Tween = corner.create_tween()
		tween.set_loops()
		tween.tween_property(corner, "modulate:a", 0.4, 0.12)
		tween.tween_property(corner, "modulate:a", 1.0, 0.12)
	
	add_child(reticle)
	return reticle

