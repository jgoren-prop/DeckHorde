extends Node
## CombatAnimationManager - Handles all combat visual effects with Slay the Spire-style timing
## Provides sequenced animations for attacks, weapons, barriers, and card plays

signal animation_started(animation_type: String)
signal animation_completed(animation_type: String)
signal all_animations_completed()

# Animation timing constants (similar to Slay the Spire)
const CARD_PLAY_DELAY: float = 0.15       # Brief pause before card effect
const TARGET_HIGHLIGHT_DURATION: float = 0.25  # Time target is highlighted before hit
const DAMAGE_FLASH_DURATION: float = 0.12  # Flash duration when taking damage
const SHAKE_DURATION: float = 0.25        # How long enemies shake when hit
const PROJECTILE_SPEED: float = 800.0     # Pixels per second for projectiles
const WEAPON_TRIGGER_DELAY: float = 0.4   # Delay between each weapon trigger
const STACK_EXPAND_DURATION: float = 1.2  # How long stack stays expanded when member is hit
const BARRIER_PULSE_DURATION: float = 0.5 # Visual feedback when barrier triggers

# Animation queuing
var animation_queue: Array[Dictionary] = []
var is_processing_queue: bool = false
var current_animation_node: Control = null

# References (set by CombatScreen)
var battlefield_arena: Control = null
var combat_screen: Control = null

# Active effects tracking
var active_barriers: Dictionary = {}  # ring -> {damage: int, duration: int, visual: Control}
var active_weapon_icons: Array[Control] = []


func _ready() -> void:
	print("[CombatAnimationManager] Initialized")


func set_references(arena: Control, screen: Control) -> void:
	"""Set references to the UI components."""
	battlefield_arena = arena
	combat_screen = screen


## ============== ANIMATION QUEUE SYSTEM ==============

func queue_animation(animation_data: Dictionary) -> void:
	"""Add an animation to the queue."""
	animation_queue.append(animation_data)
	if not is_processing_queue:
		_process_animation_queue()


func _process_animation_queue() -> void:
	"""Process animations sequentially."""
	if animation_queue.is_empty():
		is_processing_queue = false
		all_animations_completed.emit()
		return
	
	is_processing_queue = true
	var anim: Dictionary = animation_queue.pop_front()
	
	animation_started.emit(anim.type)
	
	match anim.type:
		"target_highlight":
			await _play_target_highlight(anim)
		"damage_enemy":
			await _play_damage_enemy(anim)
		"projectile":
			await _play_projectile(anim)
		"weapon_trigger":
			await _play_weapon_trigger(anim)
		"barrier_trigger":
			await _play_barrier_trigger(anim)
		"card_fly":
			await _play_card_fly(anim)
		"stack_expand":
			await _play_stack_expand(anim)
		_:
			await get_tree().create_timer(0.1).timeout
	
	animation_completed.emit(anim.type)
	_process_animation_queue()


func clear_queue() -> void:
	"""Clear all pending animations."""
	animation_queue.clear()
	is_processing_queue = false


## ============== CARD PLAY ANIMATION ==============

func play_card_effect(card_def, tier: int, target_ring: int, target_enemy = null) -> void:
	"""Play the full animation sequence for a card being played."""
	# Determine what kind of visual effect to show based on card
	var effect_type: String = card_def.effect_type
	
	match effect_type:
		"instant_damage", "scatter_damage", "damage_and_draw", "damage_and_heal", "damage_and_hex", "shield_bash":
			# Damage cards - show targeting then impact
			await _show_damage_card_effect(card_def, tier, target_ring, target_enemy)
		
		"weapon_persistent":
			# Persistent weapon - show weapon being equipped
			await _show_weapon_equip_effect(card_def, tier)
		
		"apply_hex", "apply_hex_multi":
			# Hex application
			await _show_hex_application_effect(card_def, tier, target_ring)
		
		"ring_barrier":
			# Barrier creation
			await _show_barrier_creation_effect(card_def, tier, target_ring)
		
		"gain_armor":
			# Armor gain
			await _show_armor_gain_effect(card_def, tier)
		
		_:
			# Generic effect - brief pause
			await get_tree().create_timer(CARD_PLAY_DELAY).timeout


func _show_damage_card_effect(card_def, tier: int, target_ring: int, target_enemy = null) -> void:
	"""Show damage card visual effect."""
	if not battlefield_arena:
		return
	
	var _damage: int = card_def.get_scaled_value("damage", tier)
	
	# For random target cards, we need to show which enemy will be hit
	if card_def.target_type == "random_enemy" or target_enemy != null:
		if target_enemy:
			# Show target highlight
			await _highlight_enemy_target(target_enemy, TARGET_HIGHLIGHT_DURATION)
	elif card_def.target_type == "ring" and target_ring >= 0:
		# Highlight the entire ring
		await _highlight_ring_target(target_ring, TARGET_HIGHLIGHT_DURATION)
	elif card_def.target_type == "all_enemies" or card_def.target_type == "all_rings":
		# Highlight all rings
		await _highlight_all_rings_target(TARGET_HIGHLIGHT_DURATION)


func _show_weapon_equip_effect(card_def, _tier: int) -> void:
	"""Show persistent weapon being equipped."""
	if not combat_screen:
		return
	
	# Flash the weapon panel
	_create_weapon_equip_flash(card_def.card_name)
	await get_tree().create_timer(0.3).timeout


func _show_hex_application_effect(card_def, tier: int, target_ring: int) -> void:
	"""Show hex being applied to enemies."""
	if not battlefield_arena:
		return
	
	var _hex_amount: int = card_def.get_scaled_value("hex_damage", tier)
	
	# Create purple hex particles/effect on affected ring
	if card_def.target_type == "all_enemies":
		_create_hex_effect_all_enemies(_hex_amount)
	else:
		_create_hex_effect_ring(target_ring, _hex_amount)
	
	await get_tree().create_timer(0.35).timeout


func _show_barrier_creation_effect(card_def, tier: int, target_ring: int) -> void:
	"""Show barrier being placed on a ring."""
	if not battlefield_arena:
		return
	
	var damage: int = card_def.get_scaled_value("damage", tier)
	var duration: int = card_def.get_scaled_value("duration", tier)
	
	# Create barrier visual
	_create_barrier_visual(target_ring, damage, duration)
	
	await get_tree().create_timer(0.4).timeout


func _show_armor_gain_effect(_card_def, _tier: int) -> void:
	"""Show armor gain effect on player."""
	if not combat_screen:
		return
	
	# Flash the armor section
	_create_armor_flash()
	await get_tree().create_timer(0.25).timeout


## ============== TARGET HIGHLIGHTING ==============

func _highlight_enemy_target(enemy, duration: float) -> void:
	"""Highlight a specific enemy before attacking it."""
	if not battlefield_arena:
		return
	
	# Check if enemy is in a stack
	var stack_key: String = str(enemy.ring) + "_" + enemy.enemy_id
	
	if battlefield_arena.stack_visuals.has(stack_key):
		# Enemy is in a stack - expand and highlight
		await _highlight_stacked_enemy(enemy, stack_key, duration)
	else:
		# Individual enemy - highlight directly
		if battlefield_arena.enemy_visuals.has(enemy.instance_id):
			var visual: Panel = battlefield_arena.enemy_visuals[enemy.instance_id]
			await _highlight_individual_enemy(visual, duration)


func _highlight_stacked_enemy(enemy, stack_key: String, duration: float) -> void:
	"""Expand a stack and highlight the specific enemy being targeted."""
	if not battlefield_arena.stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = battlefield_arena.stack_visuals[stack_key]
	var main_panel: Panel = stack_data.panel
	
	# Create targeting reticle on the stack
	var reticle: Control = _create_targeting_reticle(main_panel)
	
	# Expand the stack
	battlefield_arena._expand_stack(stack_key)
	
	await get_tree().create_timer(0.15).timeout
	
	# Find and highlight the specific mini-panel
	for mini_panel: Panel in stack_data.get("mini_panels", []):
		if not is_instance_valid(mini_panel):
			continue
		var mini_enemy = mini_panel.get_meta("enemy_instance", null)
		if mini_enemy and mini_enemy.instance_id == enemy.instance_id:
			# Add targeting highlight to this specific mini-panel
			var mini_reticle: Control = _create_targeting_reticle(mini_panel, true)
			
			# Pulse animation
			var tween: Tween = mini_panel.create_tween()
			tween.tween_property(mini_panel, "modulate", Color(1.5, 0.5, 0.5, 1.0), duration * 0.3)
			tween.tween_property(mini_panel, "modulate", Color.WHITE, duration * 0.3)
			
			await get_tree().create_timer(duration * 0.6).timeout
			
			if is_instance_valid(mini_reticle):
				mini_reticle.queue_free()
			break
	
	# Clean up
	if is_instance_valid(reticle):
		reticle.queue_free()


func _highlight_individual_enemy(visual: Panel, duration: float) -> void:
	"""Highlight an individual enemy panel."""
	# Create targeting reticle
	var reticle: Control = _create_targeting_reticle(visual)
	
	# Pulse/flash animation
	var tween: Tween = visual.create_tween()
	tween.tween_property(visual, "modulate", Color(1.5, 0.7, 0.7, 1.0), duration * 0.4)
	tween.tween_property(visual, "modulate", Color.WHITE, duration * 0.3)
	
	await get_tree().create_timer(duration * 0.7).timeout
	
	if is_instance_valid(reticle):
		reticle.queue_free()


func _highlight_ring_target(ring: int, duration: float) -> void:
	"""Highlight an entire ring before attacking it."""
	if not battlefield_arena:
		return
	
	# Use battlefield arena's highlight system with enhanced effect
	battlefield_arena.highlight_ring(ring, true)
	
	# Create ring pulse effect
	_create_ring_pulse_effect(ring)
	
	await get_tree().create_timer(duration).timeout
	
	battlefield_arena.highlight_ring(-1, false)


func _highlight_all_rings_target(duration: float) -> void:
	"""Highlight all rings before attacking."""
	if not battlefield_arena:
		return
	
	battlefield_arena.highlight_all_rings(true)
	
	# Create pulse effect on all rings
	for ring: int in range(4):
		_create_ring_pulse_effect(ring)
	
	await get_tree().create_timer(duration).timeout
	
	battlefield_arena.highlight_all_rings(false)


func _create_targeting_reticle(panel: Panel, is_mini: bool = false) -> Control:
	"""Create a targeting reticle around a panel."""
	var reticle: Control = Control.new()
	reticle.z_index = 100
	
	var size_mult: float = 1.4 if not is_mini else 1.3
	var reticle_size: Vector2 = panel.size * size_mult
	
	# Add pulsing corners
	var corners: Array[String] = ["↖", "↗", "↙", "↘"]
	var positions: Array[Vector2] = [
		Vector2(-8, -8),
		Vector2(reticle_size.x - 12, -8),
		Vector2(-8, reticle_size.y - 12),
		Vector2(reticle_size.x - 12, reticle_size.y - 12)
	]
	
	for i: int in range(4):
		var corner: Label = Label.new()
		corner.text = corners[i]
		corner.add_theme_font_size_override("font_size", 20 if not is_mini else 14)
		corner.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		corner.position = positions[i]
		reticle.add_child(corner)
		
		# Animate corners
		var tween: Tween = corner.create_tween()
		tween.set_loops()
		tween.tween_property(corner, "modulate:a", 0.5, 0.15)
		tween.tween_property(corner, "modulate:a", 1.0, 0.15)
	
	reticle.position = panel.global_position - (reticle_size - panel.size) / 2
	
	if battlefield_arena:
		battlefield_arena.get_tree().root.add_child(reticle)
	
	return reticle


## ============== DAMAGE EFFECTS ==============

func show_enemy_hit(enemy, damage: int, is_hex_trigger: bool = false) -> void:
	"""Show the enemy being hit with damage - shake and flash."""
	if not battlefield_arena:
		return
	
	var stack_key: String = str(enemy.ring) + "_" + enemy.enemy_id
	
	if battlefield_arena.stack_visuals.has(stack_key):
		# Hit enemy in stack
		await _show_stacked_enemy_hit(enemy, damage, stack_key, is_hex_trigger)
	elif battlefield_arena.enemy_visuals.has(enemy.instance_id):
		# Hit individual enemy
		var visual: Panel = battlefield_arena.enemy_visuals[enemy.instance_id]
		await _show_individual_enemy_hit(visual, damage, is_hex_trigger)


func _show_individual_enemy_hit(visual: Panel, damage: int, is_hex_trigger: bool) -> void:
	"""Shake and flash an individual enemy."""
	# Get instance_id from visual metadata
	var instance_id: int = visual.get_meta("instance_id", -1)
	
	# Get base position from battlefield arena's tracking to avoid tween conflicts
	var base_pos: Vector2
	if battlefield_arena and instance_id >= 0 and battlefield_arena._enemy_base_positions.has(instance_id):
		base_pos = battlefield_arena._enemy_base_positions[instance_id]
	else:
		base_pos = visual.position
	
	# Determine flash color
	var flash_color: Color = Color(0.8, 0.3, 1.0, 1.0) if is_hex_trigger else Color(1.5, 0.4, 0.4, 1.0)
	
	# Flash (modulate doesn't conflict with position tweens)
	var flash_tween: Tween = visual.create_tween()
	flash_tween.tween_property(visual, "modulate", flash_color, DAMAGE_FLASH_DURATION * 0.4)
	flash_tween.tween_property(visual, "modulate", Color.WHITE, DAMAGE_FLASH_DURATION * 0.6)
	
	# Kill any existing position tween to prevent spazzing
	if battlefield_arena and instance_id >= 0 and battlefield_arena._enemy_position_tweens.has(instance_id):
		var old_tween: Tween = battlefield_arena._enemy_position_tweens[instance_id]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Shake using base position
	var shake_tween: Tween = visual.create_tween()
	var shake_intensity: float = min(8.0 + damage * 0.3, 15.0)
	for i: int in range(6):
		var offset: Vector2 = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_tween.tween_property(visual, "position", base_pos + offset, SHAKE_DURATION / 7.0)
	shake_tween.tween_property(visual, "position", base_pos, SHAKE_DURATION / 7.0)
	
	# Track this tween in battlefield arena
	if battlefield_arena and instance_id >= 0:
		battlefield_arena._enemy_position_tweens[instance_id] = shake_tween
	
	await get_tree().create_timer(SHAKE_DURATION).timeout


func _show_stacked_enemy_hit(enemy, damage: int, stack_key: String, is_hex_trigger: bool) -> void:
	"""Show damage to an enemy in a stack - expand, highlight, shake."""
	if not battlefield_arena.stack_visuals.has(stack_key):
		return
	
	var stack_data: Dictionary = battlefield_arena.stack_visuals[stack_key]
	var main_panel: Panel = stack_data.panel
	
	# Get base position from battlefield arena's tracking to avoid tween conflicts
	var base_pos: Vector2
	if battlefield_arena._stack_base_positions.has(stack_key):
		base_pos = battlefield_arena._stack_base_positions[stack_key]
	else:
		base_pos = main_panel.position
	
	# Flash and shake the main stack panel
	var flash_color: Color = Color(0.8, 0.3, 1.0, 1.0) if is_hex_trigger else Color(1.5, 0.4, 0.4, 1.0)
	
	var flash_tween: Tween = main_panel.create_tween()
	flash_tween.tween_property(main_panel, "modulate", flash_color, DAMAGE_FLASH_DURATION * 0.4)
	flash_tween.tween_property(main_panel, "modulate", Color.WHITE, DAMAGE_FLASH_DURATION * 0.6)
	
	# Kill any existing position tween to prevent spazzing
	if battlefield_arena._stack_position_tweens.has(stack_key):
		var old_tween: Tween = battlefield_arena._stack_position_tweens[stack_key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Shake main panel using base position
	var shake_tween: Tween = main_panel.create_tween()
	var shake_intensity: float = min(6.0 + damage * 0.2, 12.0)
	for i: int in range(5):
		var offset: Vector2 = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_tween.tween_property(main_panel, "position", base_pos + offset, SHAKE_DURATION / 6.0)
	shake_tween.tween_property(main_panel, "position", base_pos, SHAKE_DURATION / 6.0)
	
	# Track this tween in battlefield arena
	battlefield_arena._stack_position_tweens[stack_key] = shake_tween
	
	# Expand briefly to show which enemy was hit
	if not stack_data.get("expanded", false):
		battlefield_arena._expand_stack_briefly(stack_key, enemy)
	
	await get_tree().create_timer(SHAKE_DURATION).timeout


## ============== PROJECTILE EFFECTS ==============

func show_projectile(from_pos: Vector2, to_pos: Vector2, projectile_type: String = "bullet") -> void:
	"""Show a projectile traveling from one position to another."""
	if not battlefield_arena:
		return
	
	var projectile: Control = _create_projectile(projectile_type)
	battlefield_arena.add_child(projectile)
	projectile.global_position = from_pos
	
	var distance: float = from_pos.distance_to(to_pos)
	var travel_time: float = distance / PROJECTILE_SPEED
	
	# Rotate projectile to face target
	var angle: float = from_pos.angle_to_point(to_pos)
	projectile.rotation = angle
	
	# Animate travel
	var tween: Tween = projectile.create_tween()
	tween.tween_property(projectile, "global_position", to_pos, travel_time).set_ease(Tween.EASE_OUT)
	tween.tween_callback(projectile.queue_free)
	
	await get_tree().create_timer(travel_time).timeout


func _create_projectile(projectile_type: String) -> Control:
	"""Create a projectile visual."""
	var projectile: Control = Control.new()
	projectile.z_index = 50
	
	var shape: ColorRect = ColorRect.new()
	
	match projectile_type:
		"bullet":
			shape.size = Vector2(12, 4)
			shape.color = Color(1.0, 0.9, 0.3, 1.0)
		"hex":
			shape.size = Vector2(10, 10)
			shape.color = Color(0.7, 0.3, 1.0, 1.0)
		"fire":
			shape.size = Vector2(14, 8)
			shape.color = Color(1.0, 0.5, 0.1, 1.0)
		_:
			shape.size = Vector2(8, 8)
			shape.color = Color(1.0, 1.0, 1.0, 1.0)
	
	shape.position = -shape.size / 2
	projectile.add_child(shape)
	
	# Add trail effect
	var trail: ColorRect = ColorRect.new()
	trail.size = Vector2(shape.size.x * 2, shape.size.y * 0.6)
	trail.color = shape.color
	trail.color.a = 0.4
	trail.position = Vector2(-trail.size.x, -trail.size.y / 2)
	projectile.add_child(trail)
	
	return projectile


## ============== WEAPON TRIGGER EFFECTS ==============

func show_weapon_trigger(card_def, tier: int, target_enemy = null) -> void:
	"""Show a persistent weapon triggering - projectile from center to target."""
	if not battlefield_arena:
		return
	
	var _damage: int = card_def.get_scaled_value("damage", tier)
	var weapon_name: String = card_def.card_name
	
	# Get center position (warden)
	var from_pos: Vector2 = battlefield_arena.center + battlefield_arena.global_position
	
	# Show weapon name
	_show_weapon_fire_label(weapon_name, from_pos)
	
	await get_tree().create_timer(0.1).timeout
	
	# If we have a target, show projectile
	if target_enemy:
		var target_pos: Vector2 = _get_enemy_global_position(target_enemy)
		await show_projectile(from_pos, target_pos, "bullet")
		
		# Flash the weapon icon in the UI
		_pulse_weapon_icon(weapon_name)


func _show_weapon_fire_label(weapon_name: String, pos: Vector2) -> void:
	"""Show weapon name when it fires."""
	if not battlefield_arena:
		return
	
	var label: Label = Label.new()
	label.text = "🔫 " + weapon_name + "!"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = pos + Vector2(-50, -50)
	label.z_index = 60
	
	battlefield_arena.add_child(label)
	
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 30, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


func _pulse_weapon_icon(weapon_name: String) -> void:
	"""Pulse the weapon icon in the weapons panel when it fires."""
	for icon: Control in active_weapon_icons:
		if is_instance_valid(icon) and icon.get_meta("weapon_name", "") == weapon_name:
			var tween: Tween = icon.create_tween()
			tween.tween_property(icon, "scale", Vector2(1.3, 1.3), 0.1)
			tween.tween_property(icon, "modulate", Color(1.5, 1.2, 0.5, 1.0), 0.1)
			tween.tween_property(icon, "scale", Vector2.ONE, 0.15)
			tween.tween_property(icon, "modulate", Color.WHITE, 0.15)
			break


## ============== BARRIER EFFECTS ==============

func _create_barrier_visual(ring: int, damage: int, duration: int) -> void:
	"""Create a visual indicator for a barrier on a ring."""
	if not battlefield_arena:
		return
	
	# Store barrier data
	active_barriers[ring] = {
		"damage": damage,
		"duration": duration,
		"visual": null
	}
	
	# The barrier visual will be drawn as part of the ring


func show_barrier_trigger(ring: int, enemy) -> void:
	"""Show barrier triggering when an enemy passes through."""
	if not battlefield_arena:
		return
	
	if not active_barriers.has(ring):
		return
	
	var barrier_data: Dictionary = active_barriers[ring]
	var damage: int = barrier_data.damage
	
	# Create barrier flash effect
	_create_barrier_flash(ring)
	
	# Show damage going to enemy
	var enemy_pos: Vector2 = _get_enemy_global_position(enemy)
	var ring_center: Vector2 = battlefield_arena.center + battlefield_arena.global_position
	
	# Create damage spark effect
	_create_barrier_damage_spark(ring_center, enemy_pos, damage)
	
	await get_tree().create_timer(BARRIER_PULSE_DURATION).timeout


func _create_barrier_flash(_ring: int) -> void:
	"""Create a flash effect on the barrier ring."""
	if not battlefield_arena:
		return
	
	# This would ideally flash the ring - queue redraw with special state
	# For now, create a visual overlay
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(0.3, 1.0, 0.5, 0.4)
	flash.size = battlefield_arena.size
	flash.z_index = 5
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	battlefield_arena.add_child(flash)
	
	var tween: Tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, BARRIER_PULSE_DURATION)
	tween.tween_callback(flash.queue_free)


func _create_barrier_damage_spark(from_pos: Vector2, to_pos: Vector2, _damage: int) -> void:
	"""Create sparks traveling from barrier to enemy."""
	if not battlefield_arena:
		return
	
	for i: int in range(5):
		var spark: ColorRect = ColorRect.new()
		spark.size = Vector2(6, 6)
		spark.color = Color(0.4, 1.0, 0.6, 1.0)
		spark.z_index = 55
		
		# Randomize starting position slightly
		var start: Vector2 = from_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		spark.global_position = start
		
		battlefield_arena.add_child(spark)
		
		var tween: Tween = spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", to_pos, 0.3).set_delay(i * 0.03)
		tween.tween_property(spark, "modulate:a", 0.0, 0.3).set_delay(i * 0.03 + 0.15)
		tween.chain().tween_callback(spark.queue_free)


func update_barrier_duration(ring: int, new_duration: int) -> void:
	"""Update a barrier's remaining duration."""
	if active_barriers.has(ring):
		active_barriers[ring].duration = new_duration
		if new_duration <= 0:
			_remove_barrier_visual(ring)


func _remove_barrier_visual(ring: int) -> void:
	"""Remove a barrier's visual when it expires."""
	if active_barriers.has(ring):
		var visual: Control = active_barriers[ring].get("visual")
		if is_instance_valid(visual):
			visual.queue_free()
		active_barriers.erase(ring)


## ============== MISC VISUAL HELPERS ==============

func _create_ring_pulse_effect(_ring: int) -> void:
	"""Create a pulse effect on a ring."""
	if not battlefield_arena:
		return
	
	# The actual pulse happens via the highlight system in BattlefieldArena
	pass


func _create_hex_effect_ring(ring: int, _hex_amount: int) -> void:
	"""Create hex visual effect on a ring."""
	if not battlefield_arena:
		return
	
	# Create purple particles on the ring
	var center: Vector2 = battlefield_arena.center
	var radius: float = battlefield_arena.max_radius * battlefield_arena.RING_PROPORTIONS[ring]
	
	for i: int in range(8):
		var particle: ColorRect = ColorRect.new()
		particle.size = Vector2(10, 10)
		particle.color = Color(0.7, 0.3, 1.0, 0.8)
		particle.z_index = 40
		
		var angle: float = PI + (float(i) / 8.0) * PI
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius * 0.7
		particle.position = pos
		
		battlefield_arena.add_child(particle)
		
		var tween: Tween = particle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:y", particle.position.y - 20, 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_property(particle, "scale", Vector2(0.5, 0.5), 0.5)
		tween.chain().tween_callback(particle.queue_free)


func _create_hex_effect_all_enemies(_hex_amount: int) -> void:
	"""Create hex effect on all enemies."""
	for ring: int in range(4):
		_create_hex_effect_ring(ring, _hex_amount)


func _create_weapon_equip_flash(weapon_name: String) -> void:
	"""Flash effect when equipping a persistent weapon."""
	if not combat_screen:
		return
	
	# Create flash label
	var label: Label = Label.new()
	label.text = "⚡ " + weapon_name + " EQUIPPED!"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_CENTER
	label.z_index = 100
	
	combat_screen.add_child(label)
	
	var screen_size: Vector2 = combat_screen.get_viewport_rect().size
	label.position = Vector2(screen_size.x / 2 - 100, screen_size.y / 3)
	
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(label.queue_free)


func _create_armor_flash() -> void:
	"""Flash effect when gaining armor."""
	if not combat_screen:
		return
	
	# Find the armor section and flash it
	var armor_section: Control = combat_screen.get_node_or_null("PlayerStatsPanel/StatsVBox/ArmorSection")
	if armor_section:
		var tween: Tween = armor_section.create_tween()
		tween.tween_property(armor_section, "modulate", Color(0.4, 1.0, 1.5, 1.0), 0.1)
		tween.tween_property(armor_section, "modulate", Color.WHITE, 0.2)


func _get_enemy_global_position(enemy) -> Vector2:
	"""Get the global position of an enemy for projectile targeting."""
	if not battlefield_arena:
		return Vector2.ZERO
	
	var stack_key: String = str(enemy.ring) + "_" + enemy.enemy_id
	
	if battlefield_arena.stack_visuals.has(stack_key):
		var stack_data: Dictionary = battlefield_arena.stack_visuals[stack_key]
		var panel: Panel = stack_data.panel
		return panel.global_position + panel.size / 2
	elif battlefield_arena.enemy_visuals.has(enemy.instance_id):
		var visual: Panel = battlefield_arena.enemy_visuals[enemy.instance_id]
		return visual.global_position + visual.size / 2
	
	return battlefield_arena.center + battlefield_arena.global_position


## ============== QUEUE-BASED ANIMATION IMPLEMENTATIONS ==============

func _play_target_highlight(anim: Dictionary) -> void:
	var enemy = anim.get("enemy")
	var duration: float = anim.get("duration", TARGET_HIGHLIGHT_DURATION)
	if enemy:
		await _highlight_enemy_target(enemy, duration)


func _play_damage_enemy(anim: Dictionary) -> void:
	var enemy = anim.get("enemy")
	var damage: int = anim.get("damage", 0)
	var is_hex: bool = anim.get("is_hex", false)
	if enemy:
		await show_enemy_hit(enemy, damage, is_hex)


func _play_projectile(anim: Dictionary) -> void:
	var from: Vector2 = anim.get("from", Vector2.ZERO)
	var to: Vector2 = anim.get("to", Vector2.ZERO)
	var projectile_type: String = anim.get("projectile_type", "bullet")
	await show_projectile(from, to, projectile_type)


func _play_weapon_trigger(anim: Dictionary) -> void:
	var card_def = anim.get("card_def")
	var tier: int = anim.get("tier", 1)
	var target = anim.get("target")
	if card_def:
		await show_weapon_trigger(card_def, tier, target)


func _play_barrier_trigger(anim: Dictionary) -> void:
	var ring: int = anim.get("ring", -1)
	var enemy = anim.get("enemy")
	if ring >= 0 and enemy:
		await show_barrier_trigger(ring, enemy)


func _play_card_fly(_anim: Dictionary) -> void:
	# Card flying animation would be implemented here
	await get_tree().create_timer(0.2).timeout


func _play_stack_expand(anim: Dictionary) -> void:
	var stack_key: String = anim.get("stack_key", "")
	var duration: float = anim.get("duration", STACK_EXPAND_DURATION)
	
	if stack_key != "" and battlefield_arena and battlefield_arena.stack_visuals.has(stack_key):
		battlefield_arena._expand_stack(stack_key)
		await get_tree().create_timer(duration).timeout
		if battlefield_arena.stack_visuals.has(stack_key):
			battlefield_arena._collapse_stack(stack_key)


## ============== WEAPON ICON MANAGEMENT ==============

func create_weapon_icon(weapon_name: String, icon_parent: Control) -> Control:
	"""Create an active weapon icon for the UI."""
	var icon_container: PanelContainer = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(40, 40)
	icon_container.set_meta("weapon_name", weapon_name)
	
	# Style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.08, 0.95)
	style.border_color = Color(1.0, 0.75, 0.3, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	icon_container.add_theme_stylebox_override("panel", style)
	
	# Icon
	var icon_label: Label = Label.new()
	icon_label.text = "🔫"
	icon_label.add_theme_font_size_override("font_size", 22)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_container.add_child(icon_label)
	
	# Tooltip showing weapon name
	icon_container.tooltip_text = weapon_name + " (fires each turn)"
	
	icon_parent.add_child(icon_container)
	active_weapon_icons.append(icon_container)
	
	# Entrance animation
	icon_container.scale = Vector2(0.5, 0.5)
	icon_container.modulate.a = 0.0
	var tween: Tween = icon_container.create_tween()
	tween.set_parallel(true)
	tween.tween_property(icon_container, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(icon_container, "modulate:a", 1.0, 0.15)
	
	return icon_container


func remove_weapon_icon(weapon_name: String) -> void:
	"""Remove a weapon icon when weapon expires."""
	for i: int in range(active_weapon_icons.size() - 1, -1, -1):
		var icon: Control = active_weapon_icons[i]
		if is_instance_valid(icon) and icon.get_meta("weapon_name", "") == weapon_name:
			var tween: Tween = icon.create_tween()
			tween.tween_property(icon, "scale", Vector2(0.5, 0.5), 0.15)
			tween.parallel().tween_property(icon, "modulate:a", 0.0, 0.15)
			tween.tween_callback(icon.queue_free)
			active_weapon_icons.remove_at(i)
			break


func clear_all_weapon_icons() -> void:
	"""Clear all weapon icons (e.g., at end of combat)."""
	for icon: Control in active_weapon_icons:
		if is_instance_valid(icon):
			icon.queue_free()
	active_weapon_icons.clear()

