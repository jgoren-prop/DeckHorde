extends Control
class_name CardArtwork
## CardArtwork - Handles 2D card artwork display using weapon sprites
## Displays weapon sprite images from textures/weapons/ folder

signal artwork_ready()

# Artwork components
var _texture: Texture2D = null
var _background_rect: ColorRect = null  # Dark background
var _weapon_rect: TextureRect = null    # Weapon sprite

# Card info
var _card_id: String = ""
var _card_name: String = ""
var _damage_type: String = "kinetic"
var _categories: Array[String] = []

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

# Background colors by damage type (darker versions for card bg)
const TYPE_BG_COLORS: Dictionary = {
	"kinetic": Color(0.12, 0.14, 0.18),
	"thermal": Color(0.18, 0.10, 0.08),
	"arcane": Color(0.14, 0.08, 0.18),
	"none": Color(0.12, 0.12, 0.14)
}


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	# Dark background
	_background_rect = ColorRect.new()
	_background_rect.name = "Background"
	_background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_rect.color = Color(0.12, 0.12, 0.14)
	add_child(_background_rect)
	
	# Weapon sprite
	_weapon_rect = TextureRect.new()
	_weapon_rect.name = "WeaponSprite"
	_weapon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_weapon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weapon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_weapon_rect)


func setup(card_def) -> void:
	"""Setup artwork for a card definition."""
	if not card_def:
		return
	
	_card_id = card_def.card_id
	_card_name = card_def.card_name
	_damage_type = card_def.damage_type
	_categories.clear()
	for cat in card_def.categories:
		_categories.append(str(cat))
	
	# Set background color based on damage type
	if _background_rect:
		_background_rect.color = TYPE_BG_COLORS.get(_damage_type, TYPE_BG_COLORS["none"])
	
	# Try to load custom card artwork first
	var texture_path: String = "res://textures/cards/" + _card_id + ".png"
	if ResourceLoader.exists(texture_path):
		_texture = load(texture_path)
		_display_custom_texture()
	else:
		# Load weapon sprite
		_load_weapon_sprite()
	
	artwork_ready.emit()


func _display_custom_texture() -> void:
	"""Display custom card texture if available."""
	if _weapon_rect and _texture:
		_weapon_rect.texture = _texture
		_weapon_rect.visible = true


func _load_weapon_sprite() -> void:
	"""Load and display the weapon sprite for this card."""
	if not _weapon_rect:
		return
	
	# Determine sprite filename from card_id
	var sprite_name: String = WEAPON_SPRITES.get(_card_id, "pistol")
	var sprite_path: String = "res://textures/weapons/" + sprite_name + ".png"
	
	# Try to load the weapon sprite
	if ResourceLoader.exists(sprite_path):
		_texture = load(sprite_path)
		_weapon_rect.texture = _texture
		_weapon_rect.visible = true
	else:
		# Fallback to pistol
		var fallback_path: String = "res://textures/weapons/pistol.png"
		if ResourceLoader.exists(fallback_path):
			_texture = load(fallback_path)
			_weapon_rect.texture = _texture
			_weapon_rect.visible = true


func get_artwork_texture() -> Texture2D:
	"""Get the current artwork texture."""
	if _texture:
		return _texture
	if _weapon_rect and _weapon_rect.texture:
		return _weapon_rect.texture
	return null


func get_weapon_sprite_name() -> String:
	"""Get the weapon sprite name for this card."""
	return WEAPON_SPRITES.get(_card_id, "pistol")


func set_artwork_size(new_size: Vector2) -> void:
	"""Update the artwork size."""
	size = new_size
	custom_minimum_size = new_size


func play_pulse_effect(color: Color = Color.WHITE) -> void:
	"""Play a pulse effect on the artwork."""
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", color * 1.5, 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)


func get_weapon_rect() -> TextureRect:
	"""Get the weapon sprite TextureRect for external manipulation."""
	return _weapon_rect

