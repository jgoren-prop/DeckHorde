extends Control
## PistolVisual3D - A stylized 2.5D/3D-looking pistol visual for gun cards
## Creates a pseudo-3D pistol that can rotate and fire with visual effects

signal fire_completed()

# Visual components
var pistol_container: Control = null
var pistol_body: Polygon2D = null
var pistol_barrel: Polygon2D = null
var pistol_grip: Polygon2D = null
var pistol_hammer: Polygon2D = null
var pistol_trigger_guard: Polygon2D = null
var muzzle_flash: Control = null
var smoke_particles: Array[Control] = []

# Animation state
var is_firing: bool = false
var target_position: Vector2 = Vector2.ZERO
var original_rotation: float = 0.0

# Visual settings
const PISTOL_SCALE: float = 1.0
const FIRE_ROTATION_SPEED: float = 0.15  # Time to rotate to target
const RECOIL_DURATION: float = 0.08  # Quick recoil
const RETURN_DURATION: float = 0.2  # Return to rest position
const MUZZLE_FLASH_DURATION: float = 0.08

# Colors for the metallic 3D effect
var body_color: Color = Color(0.35, 0.32, 0.3, 1.0)  # Dark gunmetal
var body_highlight: Color = Color(0.55, 0.52, 0.5, 1.0)  # Highlight
var body_shadow: Color = Color(0.2, 0.18, 0.17, 1.0)  # Shadow
var barrel_color: Color = Color(0.25, 0.23, 0.22, 1.0)  # Darker barrel
var grip_color: Color = Color(0.4, 0.25, 0.15, 1.0)  # Wood/brown grip
var rust_color: Color = Color(0.5, 0.3, 0.2, 1.0)  # Rusty tint


func _ready() -> void:
	_create_pistol_visual()


func _create_pistol_visual() -> void:
	"""Create the 3D-looking pistol using layered polygons."""
	# Container for all pistol parts
	pistol_container = Control.new()
	pistol_container.name = "PistolContainer"
	pistol_container.size = Vector2(80, 60)
	pistol_container.pivot_offset = Vector2(25, 30)  # Pivot at grip/handle area
	add_child(pistol_container)
	
	# === Create shadow layer (gives depth) ===
	var shadow: Polygon2D = _create_pistol_shadow()
	shadow.position = Vector2(3, 3)  # Offset shadow
	pistol_container.add_child(shadow)
	
	# === Main body (slide) ===
	pistol_body = Polygon2D.new()
	pistol_body.name = "Body"
	# Chunky slide with slight perspective
	pistol_body.polygon = PackedVector2Array([
		Vector2(10, 15),   # Top left
		Vector2(65, 12),   # Top right (slightly higher for perspective)
		Vector2(70, 18),   # Front top bevel
		Vector2(70, 28),   # Front bottom bevel
		Vector2(65, 32),   # Bottom right
		Vector2(10, 35),   # Bottom left
		Vector2(5, 30),    # Rear bevel bottom
		Vector2(5, 20),    # Rear bevel top
	])
	pistol_body.color = body_color
	pistol_container.add_child(pistol_body)
	
	# === Body highlight (top edge for 3D effect) ===
	var body_top: Polygon2D = Polygon2D.new()
	body_top.name = "BodyHighlight"
	body_top.polygon = PackedVector2Array([
		Vector2(10, 15),
		Vector2(65, 12),
		Vector2(65, 16),
		Vector2(10, 19),
	])
	body_top.color = body_highlight
	pistol_container.add_child(body_top)
	
	# === Barrel (extending from body) ===
	pistol_barrel = Polygon2D.new()
	pistol_barrel.name = "Barrel"
	pistol_barrel.polygon = PackedVector2Array([
		Vector2(65, 16),   # Connect to body top
		Vector2(85, 15),   # Barrel tip top
		Vector2(88, 18),   # Barrel tip front bevel
		Vector2(88, 27),   # Barrel tip front bottom
		Vector2(85, 30),   # Barrel tip bottom
		Vector2(65, 29),   # Connect to body bottom
	])
	pistol_barrel.color = barrel_color
	pistol_container.add_child(pistol_barrel)
	
	# === Barrel bore (dark hole at end) ===
	var barrel_bore: Polygon2D = Polygon2D.new()
	barrel_bore.name = "BarrelBore"
	barrel_bore.polygon = PackedVector2Array([
		Vector2(85, 18),
		Vector2(87, 19),
		Vector2(87, 25),
		Vector2(85, 26),
	])
	barrel_bore.color = Color(0.1, 0.1, 0.1, 1.0)  # Very dark
	pistol_container.add_child(barrel_bore)
	
	# === Grip (handle) ===
	pistol_grip = Polygon2D.new()
	pistol_grip.name = "Grip"
	pistol_grip.polygon = PackedVector2Array([
		Vector2(15, 35),   # Top left (connects to body)
		Vector2(30, 35),   # Top right
		Vector2(32, 38),   # Transition
		Vector2(28, 60),   # Bottom right
		Vector2(22, 62),   # Bottom tip
		Vector2(12, 58),   # Bottom left
		Vector2(10, 38),   # Transition left
	])
	pistol_grip.color = grip_color
	pistol_container.add_child(pistol_grip)
	
	# === Grip texture lines ===
	for i: int in range(4):
		var grip_line: ColorRect = ColorRect.new()
		grip_line.size = Vector2(12, 2)
		grip_line.position = Vector2(14, 42 + i * 4)
		grip_line.rotation = 0.1  # Slight angle
		grip_line.color = Color(0.3, 0.18, 0.1, 0.6)
		pistol_container.add_child(grip_line)
	
	# === Trigger guard ===
	pistol_trigger_guard = Polygon2D.new()
	pistol_trigger_guard.name = "TriggerGuard"
	pistol_trigger_guard.polygon = PackedVector2Array([
		Vector2(28, 35),
		Vector2(45, 35),
		Vector2(45, 37),
		Vector2(42, 48),
		Vector2(35, 50),
		Vector2(28, 48),
		Vector2(28, 37),
	])
	pistol_trigger_guard.color = body_color
	pistol_container.add_child(pistol_trigger_guard)
	
	# === Trigger ===
	var trigger: Polygon2D = Polygon2D.new()
	trigger.name = "Trigger"
	trigger.polygon = PackedVector2Array([
		Vector2(35, 38),
		Vector2(38, 38),
		Vector2(38, 46),
		Vector2(35, 44),
	])
	trigger.color = body_shadow
	pistol_container.add_child(trigger)
	
	# === Hammer (rear sight area) ===
	pistol_hammer = Polygon2D.new()
	pistol_hammer.name = "Hammer"
	pistol_hammer.polygon = PackedVector2Array([
		Vector2(5, 8),
		Vector2(15, 8),
		Vector2(15, 15),
		Vector2(5, 15),
	])
	pistol_hammer.color = body_shadow
	pistol_container.add_child(pistol_hammer)
	
	# === Front sight ===
	var front_sight: ColorRect = ColorRect.new()
	front_sight.name = "FrontSight"
	front_sight.size = Vector2(4, 5)
	front_sight.position = Vector2(72, 8)
	front_sight.color = body_shadow
	pistol_container.add_child(front_sight)
	
	# === Add rust spots for "Rusty Pistol" aesthetic ===
	_add_rust_details()
	
	# === Create muzzle flash (hidden initially) ===
	_create_muzzle_flash()
	
	# Center the pistol
	pistol_container.position = -pistol_container.pivot_offset


func _create_pistol_shadow() -> Polygon2D:
	"""Create a shadow polygon for depth effect."""
	var shadow: Polygon2D = Polygon2D.new()
	shadow.name = "Shadow"
	shadow.polygon = PackedVector2Array([
		Vector2(10, 15),
		Vector2(88, 12),
		Vector2(90, 28),
		Vector2(65, 32),
		Vector2(30, 35),
		Vector2(28, 62),
		Vector2(12, 58),
		Vector2(5, 35),
		Vector2(5, 20),
	])
	shadow.color = Color(0.0, 0.0, 0.0, 0.3)
	return shadow


func _add_rust_details() -> void:
	"""Add rust spots for the rusty pistol aesthetic."""
	var rust_spots: Array[Vector2] = [
		Vector2(25, 20),
		Vector2(45, 25),
		Vector2(55, 18),
		Vector2(12, 28),
		Vector2(70, 20),
	]
	
	for spot: Vector2 in rust_spots:
		var rust: ColorRect = ColorRect.new()
		rust.size = Vector2(randf_range(3, 6), randf_range(2, 4))
		rust.position = spot
		rust.color = rust_color
		rust.color.a = randf_range(0.3, 0.6)
		rust.rotation = randf_range(-0.3, 0.3)
		pistol_container.add_child(rust)


func _create_muzzle_flash() -> void:
	"""Create the muzzle flash visual (hidden until firing)."""
	muzzle_flash = Control.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.visible = false
	muzzle_flash.z_index = 10
	
	# Central flash (bright yellow/white)
	var flash_core: Polygon2D = Polygon2D.new()
	flash_core.name = "FlashCore"
	flash_core.polygon = PackedVector2Array([
		Vector2(0, -8),
		Vector2(25, -4),
		Vector2(35, 0),
		Vector2(25, 4),
		Vector2(0, 8),
	])
	flash_core.color = Color(1.0, 1.0, 0.8, 1.0)
	muzzle_flash.add_child(flash_core)
	
	# Outer flash (orange/yellow)
	var flash_outer: Polygon2D = Polygon2D.new()
	flash_outer.name = "FlashOuter"
	flash_outer.polygon = PackedVector2Array([
		Vector2(-5, -12),
		Vector2(30, -8),
		Vector2(45, 0),
		Vector2(30, 8),
		Vector2(-5, 12),
	])
	flash_outer.color = Color(1.0, 0.7, 0.2, 0.8)
	flash_outer.z_index = -1
	muzzle_flash.add_child(flash_outer)
	
	# Spark particles
	for i: int in range(5):
		var spark: ColorRect = ColorRect.new()
		spark.size = Vector2(4, 2)
		spark.position = Vector2(randf_range(15, 40), randf_range(-15, 15))
		spark.rotation = randf_range(-0.5, 0.5)
		spark.color = Color(1.0, 0.9, 0.4, 0.9)
		muzzle_flash.add_child(spark)
	
	muzzle_flash.position = Vector2(88, 22)  # At barrel tip
	pistol_container.add_child(muzzle_flash)


func fire_at_target(target_global_pos: Vector2) -> void:
	"""Animate the pistol to aim at target and fire."""
	if is_firing:
		return
	
	is_firing = true
	target_position = target_global_pos
	original_rotation = pistol_container.rotation
	
	# Calculate angle to target from the pistol's global position
	var pistol_global_pos: Vector2 = pistol_container.global_position + pistol_container.pivot_offset * pistol_container.scale
	var angle_to_target: float = pistol_global_pos.angle_to_point(target_global_pos)
	
	# Clamp rotation to reasonable range (-45 to +45 degrees from original)
	var rotation_diff: float = angle_to_target - original_rotation
	rotation_diff = clampf(rotation_diff, -PI/4, PI/4)
	var target_rotation: float = original_rotation + rotation_diff
	
	# Create the fire sequence
	var tween: Tween = create_tween()
	
	# 1. Rotate to aim at target
	tween.tween_property(pistol_container, "rotation", target_rotation, FIRE_ROTATION_SPEED)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	# 2. Show muzzle flash and recoil
	tween.tween_callback(_show_muzzle_flash)
	tween.tween_callback(_play_recoil)
	
	# 3. Wait for flash
	tween.tween_interval(MUZZLE_FLASH_DURATION)
	
	# 4. Hide flash
	tween.tween_callback(_hide_muzzle_flash)
	
	# 5. Return to original rotation
	tween.tween_property(pistol_container, "rotation", original_rotation, RETURN_DURATION)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# 6. Signal completion
	tween.tween_callback(_on_fire_completed)


func _show_muzzle_flash() -> void:
	"""Show the muzzle flash with a quick pop animation."""
	if muzzle_flash:
		muzzle_flash.visible = true
		muzzle_flash.scale = Vector2(0.5, 0.5)
		muzzle_flash.modulate = Color.WHITE
		
		var tween: Tween = muzzle_flash.create_tween()
		tween.tween_property(muzzle_flash, "scale", Vector2(1.2, 1.2), MUZZLE_FLASH_DURATION * 0.4)
		tween.tween_property(muzzle_flash, "scale", Vector2(0.8, 0.8), MUZZLE_FLASH_DURATION * 0.6)
	
	# Spawn smoke puffs
	_spawn_smoke()


func _hide_muzzle_flash() -> void:
	"""Hide the muzzle flash."""
	if muzzle_flash:
		muzzle_flash.visible = false


func _play_recoil() -> void:
	"""Quick recoil animation."""
	if pistol_container:
		var original_pos: Vector2 = pistol_container.position
		
		var tween: Tween = pistol_container.create_tween()
		tween.tween_property(pistol_container, "position", original_pos + Vector2(-8, 0), RECOIL_DURATION * 0.4)
		tween.tween_property(pistol_container, "position", original_pos, RECOIL_DURATION * 0.6)


func _spawn_smoke() -> void:
	"""Spawn smoke particles from the barrel."""
	var barrel_tip: Vector2 = pistol_container.position + Vector2(88, 22)
	
	for i: int in range(3):
		var smoke: ColorRect = ColorRect.new()
		smoke.size = Vector2(8, 8)
		smoke.color = Color(0.6, 0.6, 0.6, 0.6)
		smoke.position = barrel_tip + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		add_child(smoke)
		
		var tween: Tween = smoke.create_tween()
		tween.set_parallel(true)
		tween.tween_property(smoke, "position", smoke.position + Vector2(randf_range(20, 40), randf_range(-20, -10)), 0.4)
		tween.tween_property(smoke, "scale", Vector2(2, 2), 0.4)
		tween.tween_property(smoke, "modulate:a", 0.0, 0.4)
		tween.chain().tween_callback(smoke.queue_free)


func _on_fire_completed() -> void:
	"""Called when fire animation completes."""
	is_firing = false
	fire_completed.emit()


func get_barrel_tip_position() -> Vector2:
	"""Get the global position of the barrel tip for projectile spawning."""
	if pistol_container:
		# Barrel tip is at local position (88, 22) in pistol_container
		var local_tip: Vector2 = Vector2(88, 22)
		# Transform to global, accounting for rotation
		var rotated_offset: Vector2 = local_tip.rotated(pistol_container.rotation) * pistol_container.scale
		return pistol_container.global_position + rotated_offset
	return global_position


func morph_from_emoji(emoji_position: Vector2, duration: float = 0.4) -> void:
	"""Animate morphing from the emoji position to the 3D pistol."""
	# Start scaled down and positioned at emoji location
	pistol_container.scale = Vector2(0.3, 0.3)
	pistol_container.modulate.a = 0.0
	pistol_container.position = emoji_position - pistol_container.pivot_offset
	
	# Morph animation
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Scale up with overshoot
	tween.tween_property(pistol_container, "scale", Vector2(1.0, 1.0), duration)
	# Fade in
	tween.tween_property(pistol_container, "modulate:a", 1.0, duration * 0.5)
	# Move to center
	tween.tween_property(pistol_container, "position", -pistol_container.pivot_offset, duration)


