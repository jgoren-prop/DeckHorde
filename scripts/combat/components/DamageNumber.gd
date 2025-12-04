extends Label
class_name DamageNumber
## A floating damage number that animates upward and fades out.
## Automatically frees itself after the animation completes.

# Colors for different damage types
const COLOR_NORMAL: Color = Color(1.0, 0.3, 0.3, 1.0)  # Red for normal damage
const COLOR_HEX: Color = Color(0.8, 0.3, 1.0, 1.0)     # Purple for hex damage
const COLOR_HEAL: Color = Color(0.3, 1.0, 0.3, 1.0)    # Green for healing
const COLOR_PLAYER_DAMAGE: Color = Color(1.0, 0.2, 0.2, 1.0)  # Bright red for player damage

# Animation settings
const FLOAT_DISTANCE: float = 40.0
const FLOAT_DISTANCE_HEX_STACK: float = 35.0
const ANIMATION_DURATION: float = 0.6
const ANIMATION_DURATION_HEX_STACK: float = 0.5


func _ready() -> void:
	# Default styling (can be overridden by setup)
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	add_theme_constant_override("outline_size", 3)
	z_index = 60


func setup(amount: int, is_hex: bool = false, is_heal: bool = false) -> void:
	"""Configure the damage number with amount and type."""
	if is_heal:
		text = "+" + str(amount)
		add_theme_color_override("font_color", COLOR_HEAL)
	else:
		text = "-" + str(amount)
		add_theme_color_override("font_color", COLOR_HEX if is_hex else COLOR_NORMAL)


func setup_hex_stack(amount: int) -> void:
	"""Configure as a hex stack indicator (shows +☠X)."""
	text = "+☠" + str(amount)
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_color", COLOR_HEX)


func setup_player_damage(amount: int) -> void:
	"""Configure as player damage (larger, brighter)."""
	text = "-" + str(amount)
	add_theme_font_size_override("font_size", 36)
	add_theme_color_override("font_color", COLOR_PLAYER_DAMAGE)
	add_theme_constant_override("outline_size", 4)


func play_animation(float_distance: float = FLOAT_DISTANCE, duration: float = ANIMATION_DURATION) -> void:
	"""Start the float-up and fade animation. Automatically frees when done."""
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - float_distance, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)


func setup_and_play(amount: int, is_hex: bool = false, is_heal: bool = false) -> void:
	"""Convenience method to setup and immediately start animation."""
	setup(amount, is_hex, is_heal)
	play_animation()


# ============== STATIC FACTORY METHODS ==============

static func create_at(parent: Node, pos: Vector2, amount: int, is_hex: bool = false, is_heal: bool = false) -> DamageNumber:
	"""Factory method to create, position, and start a damage number."""
	var scene: PackedScene = preload("res://scenes/combat/components/DamageNumber.tscn")
	var instance: DamageNumber = scene.instantiate()
	instance.position = pos
	parent.add_child(instance)
	instance.setup_and_play(amount, is_hex, is_heal)
	return instance


static func create_hex_stack_at(parent: Node, pos: Vector2, amount: int) -> DamageNumber:
	"""Factory method to create a hex stack indicator."""
	var scene: PackedScene = preload("res://scenes/combat/components/DamageNumber.tscn")
	var instance: DamageNumber = scene.instantiate()
	instance.position = pos
	parent.add_child(instance)
	instance.setup_hex_stack(amount)
	instance.play_animation(FLOAT_DISTANCE_HEX_STACK, ANIMATION_DURATION_HEX_STACK)
	return instance


static func create_player_damage_at(parent: Node, pos: Vector2, amount: int) -> DamageNumber:
	"""Factory method to create player damage number."""
	var scene: PackedScene = preload("res://scenes/combat/components/DamageNumber.tscn")
	var instance: DamageNumber = scene.instantiate()
	instance.position = pos
	parent.add_child(instance)
	instance.setup_player_damage(amount)
	instance.play_animation(50.0, 0.7)  # Player damage floats further
	return instance

