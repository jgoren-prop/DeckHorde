extends Control
class_name Weapon2DDisplay
## Weapon2DDisplay - Displays a 2D weapon sprite with targeting and firing animations
## Replaces Weapon3DDisplay with recognizable 2D sprites

signal weapon_ready()
signal fire_started()
signal fire_completed()

# Display components
var _weapon_sprite: TextureRect = null
var _muzzle_flash: ColorRect = null

# Weapon info
var _card_id: String = ""
var _card_name: String = ""
var _damage_type: String = "kinetic"

# Animation state
var _target_position: Vector2 = Vector2.ZERO
var _is_firing: bool = false
var _idle_tween: Tween = null

# Weapon type to sprite mapping (maps card_id to sprite filename)
const WEAPON_SPRITES: Dictionary = {
	# Kinetic weapons - guns
	"pistol": "pistol",
	"heavy_pistol": "pistol",
	"shotgun": "shotgun",
	"assault_rifle": "rifle",
	"sniper_rifle": "rifle",
	"burst_fire": "pistol",
	"chain_gun": "minigun",
	"double_tap": "pistol",
	"marksman": "rifle",
	"railgun": "railgun",
	# Thermal weapons - explosives/fire
	"frag_grenade": "grenade",
	"rocket": "launcher",
	"incendiary": "flamethrower",
	"firebomb": "grenade",
	"cluster_bomb": "launcher",
	"inferno": "flamethrower",
	"napalm_strike": "launcher",
	# Arcane weapons - magical
	"hex_bolt": "wand",
	"curse_wave": "staff",
	"soul_drain": "orb",
	"hex_detonation": "wand",
	"life_siphon": "orb",
	"dark_ritual": "staff",
	"spreading_plague": "staff",
	# Fortress weapons - defensive
	"shield_bash": "shield",
	"iron_volley": "shield",
	"bulwark_shot": "shield",
	"fortified_barrage": "cannon",
	"reactive_shell": "shield",
	"siege_cannon": "cannon",
	# Shadow weapons - precision
	"assassins_strike": "dagger",
	"shadow_bolt": "crossbow",
	"precision_shot": "rifle",
	"backstab": "dagger",
	"killing_blow": "dagger",
	"shadow_barrage": "crossbow",
	# Utility weapons
	"quick_shot": "pistol",
	"flurry": "pistol",
	"chain_strike": "pistol",
	"momentum": "pistol",
	"rapid_fire": "minigun",
	"overdrive": "pistol",
	# Control weapons
	"repulsor": "gauntlet",
	"barrier_shot": "gauntlet",
	"lockdown": "cannon",
	"far_strike": "crossbow",
	"killzone": "cannon",
	"perimeter": "gauntlet",
	# Volatile weapons
	"overcharge": "pistol",
	"reckless_blast": "launcher",
	"blood_rocket": "launcher",
	"unstable_core": "orb",
	"kamikaze_swarm": "launcher",
	"desperation": "pistol",
}

# Muzzle flash colors by damage type
const MUZZLE_COLORS: Dictionary = {
	"kinetic": Color(1.0, 0.9, 0.6),
	"thermal": Color(1.0, 0.5, 0.2),
	"arcane": Color(0.8, 0.4, 1.0),
	"none": Color(1.0, 1.0, 1.0)
}

# Tint colors by damage type (applied to sprite modulate)
const TYPE_TINTS: Dictionary = {
	"kinetic": Color(0.9, 0.95, 1.0),  # Slight blue tint
	"thermal": Color(1.0, 0.85, 0.7),  # Warm orange tint
	"arcane": Color(0.9, 0.8, 1.0),    # Purple tint
	"none": Color(1.0, 1.0, 1.0)       # No tint
}


func _ready() -> void:
	_setup_display()


func _setup_display() -> void:
	"""Setup the 2D weapon display components."""
	# Create weapon sprite
	_weapon_sprite = TextureRect.new()
	_weapon_sprite.name = "WeaponSprite"
	_weapon_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_weapon_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weapon_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_weapon_sprite)
	
	# Create muzzle flash overlay (hidden initially)
	_muzzle_flash = ColorRect.new()
	_muzzle_flash.name = "MuzzleFlash"
	_muzzle_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_muzzle_flash.color = Color(1.0, 0.9, 0.6, 0.0)  # Start transparent
	_muzzle_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_muzzle_flash)
	
	# Set pivot for rotation (will be updated when size is known)
	await get_tree().process_frame
	if _weapon_sprite:
		_weapon_sprite.pivot_offset = _weapon_sprite.size / 2.0


func setup(card_def) -> void:
	"""Setup the 2D weapon for a card definition."""
	if not card_def:
		return
	
	_card_id = card_def.card_id
	_card_name = card_def.card_name
	_damage_type = card_def.damage_type
	
	# Load the weapon sprite
	_load_weapon_sprite()
	
	# Apply damage type tint
	_apply_type_tint()
	
	# Set muzzle flash color
	var flash_color: Color = MUZZLE_COLORS.get(_damage_type, MUZZLE_COLORS["none"])
	if _muzzle_flash:
		_muzzle_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	
	weapon_ready.emit()


func _load_weapon_sprite() -> void:
	"""Load the appropriate weapon sprite texture."""
	if not _weapon_sprite:
		return
	
	# Determine sprite filename
	var sprite_name: String = WEAPON_SPRITES.get(_card_id, "pistol")
	var sprite_path: String = "res://textures/weapons/" + sprite_name + ".png"
	
	# Try to load the texture
	if ResourceLoader.exists(sprite_path):
		var texture: Texture2D = load(sprite_path)
		_weapon_sprite.texture = texture
	else:
		# Fallback to pistol if specific sprite not found
		var fallback_path: String = "res://textures/weapons/pistol.png"
		if ResourceLoader.exists(fallback_path):
			_weapon_sprite.texture = load(fallback_path)
		else:
			push_warning("Weapon2DDisplay: No sprite found for " + _card_id)


func _apply_type_tint() -> void:
	"""Apply damage type color tint to the sprite."""
	if not _weapon_sprite:
		return
	
	var tint: Color = TYPE_TINTS.get(_damage_type, TYPE_TINTS["none"])
	_weapon_sprite.modulate = tint


# Rotation state
var _current_rotation: float = 0.0
var _rotation_tween: Tween = null

# =============================================================================
# ANIMATION METHODS - Compatible with Weapon3DDisplay interface
# =============================================================================

func set_target_direction(target_pos: Vector2, animate: bool = true) -> void:
	"""Set the direction the weapon should face (rotate sprite)."""
	_target_position = target_pos
	_update_weapon_rotation(animate)


func _update_weapon_rotation(animate: bool = true) -> void:
	"""Update weapon rotation to face target."""
	if not _weapon_sprite:
		return
	
	# Make sure pivot is set to center
	_weapon_sprite.pivot_offset = _weapon_sprite.size / 2.0
	
	# Calculate angle from center of control to target
	var center: Vector2 = global_position + size / 2.0
	var direction: Vector2 = _target_position - center
	
	# Skip if no meaningful direction
	if direction.length_squared() < 1.0:
		return
	
	# Add 180 degrees so barrel faces target (sprites face right by default)
	var target_angle: float = rad_to_deg(atan2(direction.y, direction.x)) + 180.0
	
	# Kill any existing rotation tween
	if _rotation_tween and _rotation_tween.is_valid():
		_rotation_tween.kill()
		_rotation_tween = null
	
	if animate:
		# Smooth rotation animation
		_rotation_tween = create_tween()
		_rotation_tween.set_ease(Tween.EASE_OUT)
		_rotation_tween.set_trans(Tween.TRANS_QUAD)
		_rotation_tween.tween_property(_weapon_sprite, "rotation_degrees", target_angle, 0.15)
		_rotation_tween.tween_callback(func(): _current_rotation = target_angle)
	else:
		# Instant rotation
		_weapon_sprite.rotation_degrees = target_angle
		_current_rotation = target_angle


func play_fire_animation() -> void:
	"""Play the weapon firing animation with muzzle flash."""
	if _is_firing:
		return
	
	_is_firing = true
	fire_started.emit()
	
	# Stop idle animation during fire
	stop_idle_animation()
	
	# Wait for rotation to complete if needed
	if _rotation_tween and _rotation_tween.is_valid():
		await _rotation_tween.finished
	
	# Muzzle flash effect
	if _muzzle_flash:
		var flash_color: Color = _muzzle_flash.color
		_muzzle_flash.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.6)
		
		var flash_tween: Tween = create_tween()
		flash_tween.tween_property(_muzzle_flash, "color:a", 0.0, 0.15)
	
	# Recoil animation on sprite
	if _weapon_sprite:
		var original_scale: Vector2 = Vector2.ONE
		var tween: Tween = create_tween()
		
		# Quick scale punch for recoil feel
		tween.tween_property(_weapon_sprite, "scale", Vector2(0.85, 1.1), 0.05)
		tween.tween_property(_weapon_sprite, "scale", original_scale, 0.15).set_ease(Tween.EASE_OUT)
		
		# Slight brightness flash
		var bright_tint: Color = _weapon_sprite.modulate.lightened(0.3)
		var original_tint: Color = TYPE_TINTS.get(_damage_type, TYPE_TINTS["none"])
		
		_weapon_sprite.modulate = bright_tint
		await tween.finished
		_weapon_sprite.modulate = original_tint
	else:
		await get_tree().create_timer(0.2).timeout
	
	_is_firing = false
	fire_completed.emit()


func get_muzzle_global_position() -> Vector2:
	"""Get the global 2D position of the muzzle point (right edge of sprite)."""
	# Muzzle is at the right edge of the weapon sprite, adjusted for rotation
	var center: Vector2 = global_position + size / 2.0
	var angle: float = deg_to_rad(_current_rotation)
	
	# Offset from center toward the muzzle direction
	var muzzle_offset: float = min(size.x, size.y) * 0.4
	var muzzle_direction: Vector2 = Vector2(cos(angle), sin(angle))
	
	return center + muzzle_direction * muzzle_offset


func get_current_rotation() -> float:
	"""Get the current rotation in degrees."""
	return _current_rotation


func play_idle_animation() -> void:
	"""Play subtle idle animation (gentle bob/pulse)."""
	if not _weapon_sprite:
		return
	
	# Kill existing idle tween
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	_idle_tween.set_ease(Tween.EASE_IN_OUT)
	_idle_tween.set_trans(Tween.TRANS_SINE)
	
	# Gentle scale pulse
	_idle_tween.tween_property(_weapon_sprite, "scale", Vector2(1.02, 1.02), 0.8)
	_idle_tween.tween_property(_weapon_sprite, "scale", Vector2(0.98, 0.98), 0.8)


func stop_idle_animation() -> void:
	"""Stop idle animation."""
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
		_idle_tween = null
	
	if _weapon_sprite:
		_weapon_sprite.scale = Vector2.ONE


func get_weapon_sprite() -> TextureRect:
	"""Get the weapon sprite node for external access."""
	return _weapon_sprite

