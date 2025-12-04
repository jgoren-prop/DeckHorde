extends Panel
class_name MiniEnemyPanel
## A mini panel representing an individual enemy within an expanded stack.
## Shows enemy icon, HP bar, and hex status. Handles hover interactions.

signal hover_entered(panel: MiniEnemyPanel, enemy, stack_key: String)
signal hover_exited(panel: MiniEnemyPanel, stack_key: String)

const BattlefieldInfoCardsHelper = preload("res://scripts/combat/BattlefieldInfoCards.gd")

# Node references
@onready var icon_label: Label = $IconLabel
@onready var hp_background: ColorRect = $HPBackground
@onready var hp_fill: ColorRect = $HPFill
@onready var hp_text: Label = $HPText
@onready var hex_label: Label = $HexLabel

# Stored data
var enemy_instance  # The enemy this panel represents
var enemy_id: String = ""
var instance_id: int = -1
var stack_key: String = ""
var enemy_color: Color = Color(0.8, 0.3, 0.3)
var hp_max_width: float = 0.0

# Behavior badge reference
var behavior_badge: Panel = null


func _ready() -> void:
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(enemy, panel_size: Vector2, color: Color, key: String = "") -> void:
	"""Initialize the mini panel with enemy data."""
	enemy_instance = enemy
	enemy_id = enemy.enemy_id
	instance_id = enemy.instance_id
	stack_key = key
	enemy_color = color
	
	# Store metadata for external lookups
	set_meta("enemy_instance", enemy)
	set_meta("enemy_id", enemy_id)
	set_meta("instance_id", instance_id)
	
	# Set panel size
	custom_minimum_size = panel_size
	size = panel_size
	
	# Apply panel style
	_apply_default_style()
	
	# Position elements based on panel size
	var width: float = panel_size.x
	var height: float = panel_size.y
	
	# Get enemy definition
	var enemy_db = Engine.get_singleton("EnemyDatabase")
	var enemy_def = enemy_db.get_enemy(enemy_id) if enemy_db else null
	
	# Create behavior badge
	if enemy_def and not behavior_badge:
		behavior_badge = BattlefieldInfoCardsHelper.create_behavior_badge(enemy_def, true)
		behavior_badge.position = Vector2(2, 2)
		behavior_badge.mouse_filter = Control.MOUSE_FILTER_PASS
		behavior_badge.z_index = 5
		behavior_badge.set_meta("tooltip_text", enemy_def.get_behavior_tooltip())
		add_child(behavior_badge)
		move_child(behavior_badge, 0)  # Put at back
	
	# Position icon
	icon_label.position = Vector2((width - 20.0) * 0.5, 2.0)
	icon_label.size = Vector2(20, 20)
	icon_label.text = "👤" if not enemy_def else enemy_def.display_icon
	
	# Position HP bar
	hp_background.position = Vector2(3.0, height * 0.45)
	hp_background.size = Vector2(width - 6.0, 6.0)
	hp_fill.position = hp_background.position
	hp_max_width = hp_background.size.x
	hp_fill.set_meta("max_width", hp_max_width)
	
	# Position HP text
	hp_text.position = Vector2(0.0, height * 0.6)
	hp_text.size = Vector2(width, 14.0)
	
	# Position hex label
	hex_label.position = Vector2(0.0, height * 0.78)
	hex_label.size = Vector2(width, 14.0)
	
	# Initial update
	update_hp()
	update_hex()


func update_hp() -> void:
	"""Update HP bar and text display."""
	if not is_instance_valid(enemy_instance):
		return
	
	var hp_percent: float = enemy_instance.get_hp_percentage()
	hp_fill.size.x = hp_max_width * hp_percent
	hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	hp_text.text = str(enemy_instance.current_hp) + "/" + str(enemy_instance.max_hp)


func update_hex() -> void:
	"""Update hex status display."""
	if not is_instance_valid(enemy_instance):
		hex_label.visible = false
		return
	
	var hex_stacks: int = enemy_instance.get_status_value("hex")
	if hex_stacks > 0:
		hex_label.visible = true
		hex_label.text = "☠️" + str(hex_stacks)
	else:
		hex_label.visible = false


func _apply_default_style() -> void:
	"""Apply the default (non-hovered) panel style."""
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = enemy_color
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.4, 0.45, 1.0)
	add_theme_stylebox_override("panel", style)


func _apply_hover_style() -> void:
	"""Apply the hovered panel style."""
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = enemy_color.lightened(0.2)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.9, 0.4, 1.0)
	add_theme_stylebox_override("panel", style)


func _on_mouse_entered() -> void:
	"""Handle mouse enter - highlight and emit signal."""
	_apply_hover_style()
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT)
	z_index = 25
	
	hover_entered.emit(self, enemy_instance, stack_key)


func _on_mouse_exited() -> void:
	"""Handle mouse exit - reset and emit signal."""
	_apply_default_style()
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	z_index = 20
	
	hover_exited.emit(self, stack_key)


# ============== STATIC FACTORY METHOD ==============

static func create(enemy, panel_size: Vector2, color: Color, key: String = "") -> MiniEnemyPanel:
	"""Factory method to create and setup a mini enemy panel."""
	var scene: PackedScene = preload("res://scenes/combat/components/MiniEnemyPanel.tscn")
	var instance: MiniEnemyPanel = scene.instantiate()
	# Defer setup until node is ready
	instance.call_deferred("setup", enemy, panel_size, color, key)
	return instance

