extends RefCounted
class_name BattlefieldEffects
## BattlefieldEffects - Visual effects for the battlefield (projectiles, particles, damage numbers)
## Extracted from BattlefieldArena.gd to improve code organization


static func create_projectile(parent: Control, from_pos: Vector2, to_pos: Vector2, color: Color, duration: float = 0.25) -> Control:
	"""Create and animate a projectile from one position to another."""
	var projectile: Panel = Panel.new()
	projectile.custom_minimum_size = Vector2(8, 8)
	projectile.size = Vector2(8, 8)
	projectile.position = from_pos - Vector2(4, 4)
	projectile.z_index = 100
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	projectile.add_theme_stylebox_override("panel", style)
	parent.add_child(projectile)
	
	# Animate projectile
	var tween: Tween = parent.create_tween()
	tween.tween_property(projectile, "position", to_pos - Vector2(4, 4), duration)
	tween.tween_callback(projectile.queue_free)
	
	return projectile


static func create_fast_projectile(parent: Control, from_pos: Vector2, to_pos: Vector2, color: Color, bullet_count: int = 3) -> void:
	"""Create a burst of fast projectiles."""
	for i: int in range(bullet_count):
		var delay: float = float(i) * 0.05
		
		# Create bullet with slight random offset
		var offset: Vector2 = Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		
		# Delay each bullet slightly
		var timer: SceneTreeTimer = parent.get_tree().create_timer(delay)
		timer.timeout.connect(func():
			if is_instance_valid(parent):
				_spawn_single_bullet(parent, from_pos, to_pos + offset, color)
		)


static func _spawn_single_bullet(parent: Control, from_pos: Vector2, to_pos: Vector2, color: Color) -> void:
	"""Spawn a single bullet projectile."""
	var bullet: Panel = Panel.new()
	bullet.custom_minimum_size = Vector2(6, 6)
	bullet.size = Vector2(6, 6)
	bullet.position = from_pos - Vector2(3, 3)
	bullet.z_index = 100
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	bullet.add_theme_stylebox_override("panel", style)
	parent.add_child(bullet)
	
	# Fast animation
	var tween: Tween = parent.create_tween()
	tween.tween_property(bullet, "position", to_pos - Vector2(3, 3), 0.15)
	tween.tween_callback(bullet.queue_free)


static func create_impact_flash(parent: Control, pos: Vector2, color: Color, size: float = 30.0) -> void:
	"""Create an impact flash effect at a position."""
	var flash: Panel = Panel.new()
	flash.custom_minimum_size = Vector2(size, size)
	flash.size = Vector2(size, size)
	flash.position = pos - Vector2(size / 2, size / 2)
	flash.z_index = 99
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(size / 2))
	flash.add_theme_stylebox_override("panel", style)
	parent.add_child(flash)
	
	# Expand and fade
	var tween: Tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.set_parallel(false)
	tween.tween_callback(flash.queue_free)


static func create_damage_number(parent: Control, pos: Vector2, amount: int, is_hex: bool = false) -> Label:
	"""Create a floating damage number at a position."""
	var label: Label = Label.new()
	label.text = str(amount)
	label.position = pos
	label.z_index = 110
	
	if is_hex:
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
		label.text = "☠" + str(amount)
	else:
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	
	# Float up and fade
	var tween: Tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 40.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
	
	return label


static func create_hex_number(parent: Control, pos: Vector2, amount: int) -> Label:
	"""Create a floating hex number at a position."""
	var label: Label = Label.new()
	label.text = "+☠" + str(amount)
	label.position = pos - Vector2(20, 30)
	label.z_index = 110
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.7, 0.3, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
	
	# Float up and fade
	var tween: Tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 60.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
	
	return label


static func create_player_damage_number(parent: Control, amount: int, viewport_size: Vector2) -> Label:
	"""Create a large damage number for player damage."""
	var label: Label = Label.new()
	label.text = "-" + str(amount)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(viewport_size.x / 2 - 40, viewport_size.y - 100)
	label.z_index = 120
	parent.add_child(label)
	
	# Scale up and fade
	var tween: Tween = parent.create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(0.3)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)
	
	return label


static func spawn_death_particles(parent: Control, pos: Vector2, color: Color, count: int = 12) -> void:
	"""Spawn death particle effects at a position."""
	for i: int in range(count):
		var particle: Panel = Panel.new()
		particle.custom_minimum_size = Vector2(6, 6)
		particle.size = Vector2(6, 6)
		particle.position = pos
		particle.z_index = 90
		
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(3)
		particle.add_theme_stylebox_override("panel", style)
		parent.add_child(particle)
		
		# Random direction and speed
		var angle: float = randf() * TAU
		var speed: float = randf_range(80.0, 180.0)
		var end_pos: Vector2 = pos + Vector2(cos(angle), sin(angle)) * speed
		var duration: float = randf_range(0.4, 0.8)
		
		# Animate particle
		var tween: Tween = parent.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", end_pos, duration).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "scale", Vector2(0.3, 0.3), duration)
		tween.set_parallel(false)
		tween.tween_callback(particle.queue_free)


static func spawn_death_particles_small(parent: Control, pos: Vector2, color: Color, count: int = 6) -> void:
	"""Spawn smaller death particles for mini panels."""
	spawn_death_particles(parent, pos, color, count)


static func create_barrier_sparks(parent: Control, from_pos: Vector2, to_pos: Vector2, color: Color = Color(0.4, 0.9, 0.6)) -> void:
	"""Create sparks from a barrier trigger."""
	var spark_count: int = 5
	
	for i: int in range(spark_count):
		var delay: float = float(i) * 0.03
		var timer: SceneTreeTimer = parent.get_tree().create_timer(delay)
		timer.timeout.connect(func():
			if is_instance_valid(parent):
				_spawn_single_spark(parent, from_pos, to_pos, color)
		)


static func _spawn_single_spark(parent: Control, from_pos: Vector2, to_pos: Vector2, color: Color) -> void:
	"""Spawn a single barrier spark."""
	var spark: Panel = Panel.new()
	spark.custom_minimum_size = Vector2(4, 4)
	spark.size = Vector2(4, 4)
	spark.position = from_pos
	spark.z_index = 95
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	spark.add_theme_stylebox_override("panel", style)
	parent.add_child(spark)
	
	# Arc toward target with slight randomness
	var mid_point: Vector2 = from_pos.lerp(to_pos, 0.5)
	mid_point += Vector2(randf_range(-20.0, 20.0), randf_range(-30.0, -10.0))
	
	var tween: Tween = parent.create_tween()
	tween.tween_property(spark, "position", mid_point, 0.1)
	tween.tween_property(spark, "position", to_pos, 0.1)
	tween.tween_callback(spark.queue_free)


static func create_attack_reticle(panel_size: Vector2, is_mini: bool = false) -> Control:
	"""Create a targeting reticle overlay for attacks."""
	var reticle: Control = Control.new()
	reticle.name = "AttackReticle"
	reticle.size = panel_size
	reticle.z_index = 50
	
	# Create corner markers
	var corner_size: float = 10.0 if is_mini else 16.0
	var line_width: float = 2.0 if is_mini else 3.0
	var reticle_color: Color = Color(1.0, 0.3, 0.2, 0.9)
	
	# Top-left corner
	var tl: Panel = _create_corner_panel(corner_size, line_width, reticle_color, true, true)
	tl.position = Vector2(0, 0)
	reticle.add_child(tl)
	
	# Top-right corner
	var top_right: Panel = _create_corner_panel(corner_size, line_width, reticle_color, false, true)
	top_right.position = Vector2(panel_size.x - corner_size, 0)
	reticle.add_child(top_right)
	
	# Bottom-left corner
	var bl: Panel = _create_corner_panel(corner_size, line_width, reticle_color, true, false)
	bl.position = Vector2(0, panel_size.y - corner_size)
	reticle.add_child(bl)
	
	# Bottom-right corner
	var br: Panel = _create_corner_panel(corner_size, line_width, reticle_color, false, false)
	br.position = Vector2(panel_size.x - corner_size, panel_size.y - corner_size)
	reticle.add_child(br)
	
	return reticle


static func _create_corner_panel(size: float, width: float, color: Color, is_left: bool, is_top: bool) -> Panel:
	"""Create a corner panel for the attack reticle."""
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(size, size)
	panel.size = Vector2(size, size)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)  # Transparent
	style.border_color = color
	
	# Only draw borders on appropriate sides
	if is_left:
		style.border_width_left = int(width)
	else:
		style.border_width_right = int(width)
	
	if is_top:
		style.border_width_top = int(width)
	else:
		style.border_width_bottom = int(width)
	
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func flash_panel(panel: Panel, color: Color, duration: float = 0.15) -> void:
	"""Flash a panel with a color overlay."""
	if not is_instance_valid(panel):
		return
	
	# Store original modulate
	var original_modulate: Color = panel.modulate
	panel.modulate = color
	
	# Create tween to restore
	var tween: Tween = panel.create_tween()
	tween.tween_property(panel, "modulate", original_modulate, duration)


