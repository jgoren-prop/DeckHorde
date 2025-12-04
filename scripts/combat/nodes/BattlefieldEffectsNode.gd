extends Control
class_name BattlefieldEffectsNode
## Handles all visual effects on the battlefield: projectiles, impacts, damage numbers.

signal projectile_hit_enemy(enemy, impact_pos: Vector2)

const DamageNumberClass = preload("res://scripts/combat/components/DamageNumber.gd")
const BattlefieldEffectsHelper = preload("res://scripts/combat/BattlefieldEffects.gd")

# Layout info (set by parent)
var arena_center: Vector2 = Vector2.ZERO

# Reference to combat_lane for weapon positions
var combat_lane: Control = null

# Pending projectile data for synchronized damage
var _pending_projectile_enemy = null


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
	"""Fire a fast projectile, optionally from a weapon card. Non-blocking version."""
	await _fire_projectile_internal(to_pos, color, weapon_index, null)


func fire_weapon_projectile_at_enemy(enemy, to_pos: Vector2, color: Color, weapon_index: int) -> float:
	"""Fire a weapon projectile at an enemy. Returns total animation time.
	The projectile_hit_enemy signal will be emitted when the projectile hits."""
	_pending_projectile_enemy = enemy
	return await _fire_projectile_internal(to_pos, color, weapon_index, enemy)


func _fire_projectile_internal(to_pos: Vector2, color: Color, weapon_index: int, enemy) -> float:
	"""Internal projectile firing logic. Returns total animation time."""
	var from_pos: Vector2 = arena_center
	var gun_anim_time: float = 0.0
	
	# Get weapon position and animate gun if available
	if weapon_index >= 0 and combat_lane:
		if combat_lane.has_method("animate_pistol_fire_at_index"):
			var target_global: Vector2 = to_pos + global_position
			# Gun animation takes ~0.4s (aim + fire + return)
			gun_anim_time = 0.4
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
	
	# Schedule impact effects and signal
	var impact_timer: SceneTreeTimer = get_tree().create_timer(travel_time)
	var captured_enemy = enemy
	impact_timer.timeout.connect(func():
		create_impact_flash(to_pos, color)
		if captured_enemy != null:
			projectile_hit_enemy.emit(captured_enemy, to_pos)
	)
	
	# Return total animation time for caller to await if needed
	return gun_anim_time + travel_time


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


func spawn_hex_particles(pos: Vector2, count: int = 8) -> void:
	"""Spawn purple hex particles around a position."""
	var hex_color: Color = Color(0.7, 0.3, 1.0, 1.0)
	
	for i: int in range(count):
		var particle: ColorRect = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = hex_color
		particle.z_index = 50
		
		# Random position around center
		var angle: float = (float(i) / float(count)) * TAU + randf_range(-0.3, 0.3)
		var radius: float = randf_range(10, 30)
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * radius
		particle.position = pos + offset - particle.size / 2
		
		add_child(particle)
		
		# Animate particle: float up and fade out
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:y", particle.position.y - randf_range(25, 45), 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5).set_delay(0.15)
		tween.tween_property(particle, "scale", Vector2(0.3, 0.3), 0.5)
		tween.set_parallel(false)
		tween.tween_callback(particle.queue_free)


func fire_barrier_sparks(from_pos: Vector2, to_pos: Vector2) -> void:
	"""Fire barrier trigger sparks."""
	BattlefieldEffectsHelper.create_barrier_sparks(self, from_pos, to_pos)


func create_barrier_wave(center_pos: Vector2, radius: float, arc_start: float = PI, arc_end: float = TAU) -> void:
	"""Create an expanding wave effect along a ring arc when barrier is placed."""
	var wave_color: Color = Color(0.3, 0.9, 0.5, 0.8)
	var segment_count: int = 16
	
	for i: int in range(segment_count):
		var progress: float = float(i) / float(segment_count - 1)
		var angle: float = arc_start + progress * (arc_end - arc_start)
		var pos: Vector2 = center_pos + Vector2(cos(angle), sin(angle)) * radius
		
		var spark: ColorRect = ColorRect.new()
		spark.size = Vector2(8, 8)
		spark.color = wave_color
		spark.position = pos - spark.size / 2
		spark.z_index = 50
		spark.modulate.a = 0.0
		
		add_child(spark)
		
		# Staggered animation - wave travels along the arc
		var delay: float = float(i) * 0.03
		var tween: Tween = create_tween()
		tween.tween_property(spark, "modulate:a", 1.0, 0.1).set_delay(delay)
		tween.tween_property(spark, "scale", Vector2(2.0, 2.0), 0.2)
		tween.tween_property(spark, "modulate:a", 0.0, 0.2)
		tween.tween_callback(spark.queue_free)


func create_barrier_hit_effect(pos: Vector2, damage: int) -> void:
	"""Create visual effect when barrier damages an enemy."""
	# Shield burst effect
	var burst_color: Color = Color(0.3, 0.9, 0.5, 1.0)
	
	# Central flash
	var flash: Panel = Panel.new()
	flash.custom_minimum_size = Vector2(30, 30)
	flash.size = Vector2(30, 30)
	flash.position = pos - Vector2(15, 15)
	flash.z_index = 55
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = burst_color
	style.set_corner_radius_all(15)
	flash.add_theme_stylebox_override("panel", style)
	
	add_child(flash)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(2.5, 2.5), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.25)
	tween.set_parallel(false)
	tween.tween_callback(flash.queue_free)
	
	# Spawn shield shards
	var shard_count: int = 6
	for i: int in range(shard_count):
		var shard: ColorRect = ColorRect.new()
		shard.size = Vector2(6, 12)
		shard.color = burst_color.lightened(0.3)
		shard.position = pos - shard.size / 2
		shard.z_index = 54
		
		add_child(shard)
		
		var shard_angle: float = TAU * float(i) / float(shard_count) + randf_range(-0.2, 0.2)
		var end_pos: Vector2 = pos + Vector2(cos(shard_angle), sin(shard_angle)) * randf_range(40, 70)
		
		var shard_tween: Tween = create_tween()
		shard_tween.set_parallel(true)
		shard_tween.tween_property(shard, "position", end_pos - shard.size / 2, 0.3).set_ease(Tween.EASE_OUT)
		shard_tween.tween_property(shard, "rotation", randf_range(-PI, PI), 0.3)
		shard_tween.tween_property(shard, "modulate:a", 0.0, 0.3).set_delay(0.1)
		shard_tween.set_parallel(false)
		shard_tween.tween_callback(shard.queue_free)
	
	# Show damage text with shield icon
	var dmg_label: Label = Label.new()
	dmg_label.text = "🛡️ -" + str(damage)
	dmg_label.position = pos + Vector2(-20, -30)
	dmg_label.z_index = 60
	dmg_label.add_theme_font_size_override("font_size", 18)
	dmg_label.add_theme_color_override("font_color", burst_color)
	dmg_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	dmg_label.add_theme_constant_override("outline_size", 2)
	
	add_child(dmg_label)
	
	var label_tween: Tween = create_tween()
	label_tween.tween_property(dmg_label, "position:y", pos.y - 60, 0.6).set_ease(Tween.EASE_OUT)
	label_tween.parallel().tween_property(dmg_label, "modulate:a", 0.0, 0.4).set_delay(0.3)
	label_tween.tween_callback(dmg_label.queue_free)


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


