extends Panel
class_name IndividualEnemyPanel
## A panel representing a single enemy instance.
## Shows enemy icon, damage, HP bar, intent, and hex status.

signal hover_entered(panel: Panel, enemy)
signal hover_exited(panel: Panel)

const BattlefieldInfoCardsHelper = preload("res://scripts/combat/BattlefieldInfoCards.gd")

# Node references - obtained in _ensure_nodes()
var icon_label: Label
var damage_label: Label
var hp_background: ColorRect
var hp_fill: ColorRect
var hp_text: Label
var intent_icon: Label
var hex_label: Label

# Stored data
var enemy_instance  # The enemy this panel represents
var enemy_id: String = ""
var instance_id: int = -1
var enemy_color: Color = Color(0.8, 0.3, 0.3)
var hp_max_width: float = 0.0

# Behavior badge reference
var behavior_badge: Panel = null


func _ready() -> void:
	z_index = 15
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Disable anchor-based positioning
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	# Connect hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _ensure_nodes() -> void:
	"""Ensure node references are valid. Called at start of setup."""
	if icon_label == null:
		icon_label = $IconLabel
		damage_label = $DamageLabel
		hp_background = $HPBackground
		hp_fill = $HPFill
		hp_text = $HPText
		intent_icon = $IntentIcon
		hex_label = $HexLabel


func setup(enemy, color: Color, visual_size: Vector2) -> void:
	"""Initialize the panel with enemy data."""
	_ensure_nodes()
	
	enemy_instance = enemy
	enemy_id = enemy.enemy_id
	instance_id = enemy.instance_id
	enemy_color = color
	
	# Store metadata
	set_meta("enemy_instance", enemy)
	set_meta("enemy_id", enemy_id)
	set_meta("instance_id", instance_id)
	
	# Set panel size
	custom_minimum_size = visual_size
	size = visual_size
	
	# Apply panel style
	_apply_default_style()
	
	# Position elements based on panel size
	var width: float = visual_size.x
	var height: float = visual_size.y
	
	# Get enemy definition
	var enemy_def = EnemyDatabase.get_enemy(enemy_id)
	
	# Create behavior badge
	if enemy_def and not behavior_badge:
		behavior_badge = BattlefieldInfoCardsHelper.create_behavior_badge(enemy_def, false)
		behavior_badge.position = Vector2(4, 4)
		behavior_badge.mouse_filter = Control.MOUSE_FILTER_PASS
		behavior_badge.z_index = 5
		behavior_badge.set_meta("tooltip_text", enemy_def.get_behavior_tooltip())
		add_child(behavior_badge)
		move_child(behavior_badge, 0)
	
	# Position icon
	icon_label.position = Vector2((width - 36.0) * 0.5, 6.0)
	icon_label.size = Vector2(36, 36)
	icon_label.text = "👤" if not enemy_def else enemy_def.display_icon
	
	# Position damage label
	damage_label.position = Vector2(0.0, height * 0.40)
	damage_label.size = Vector2(width, 22.0)
	if enemy_def:
		var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
		damage_label.text = "⚔ " + str(dmg)
	
	# Position HP bar
	hp_background.position = Vector2(4.0, height * 0.66)
	hp_background.size = Vector2(width - 8.0, 12.0)
	hp_fill.position = hp_background.position
	hp_fill.size = hp_background.size
	hp_max_width = hp_background.size.x
	hp_fill.set_meta("max_width", hp_max_width)
	
	# Position HP text
	hp_text.position = Vector2(0.0, height * 0.78)
	hp_text.size = Vector2(width, 20.0)
	hp_text.text = str(enemy.current_hp)
	
	# Position intent icon
	intent_icon.position = Vector2(width - 22.0, -12.0)
	intent_icon.visible = enemy_def and enemy.ring == 0  # Show if in melee
	
	# Position hex label
	hex_label.position = Vector2(0.0, -14.0)
	hex_label.size = Vector2(width, 22.0)
	hex_label.visible = false
	
	# Initial update
	update_hp()
	update_hex()


func update_hp() -> void:
	"""Update HP bar and text display."""
	if not is_instance_valid(enemy_instance):
		return
	
	_ensure_nodes()
	
	var hp_percent: float = enemy_instance.get_hp_percentage()
	hp_fill.size.x = hp_max_width * hp_percent
	hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	hp_text.text = str(enemy_instance.current_hp)


func update_hex() -> void:
	"""Update hex status display."""
	if not is_instance_valid(enemy_instance):
		return
	
	_ensure_nodes()
	
	var hex_stacks: int = enemy_instance.get_status_value("hex")
	if hex_stacks > 0:
		hex_label.visible = true
		hex_label.text = "☠️ " + str(hex_stacks)
	else:
		hex_label.visible = false


func update_intent() -> void:
	"""Update intent indicator based on enemy position."""
	if not is_instance_valid(enemy_instance):
		return
	
	_ensure_nodes()
	
	var enemy_def = EnemyDatabase.get_enemy(enemy_id)
	intent_icon.visible = enemy_def and enemy_instance.ring == 0


func _apply_default_style() -> void:
	"""Apply the default panel style."""
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = enemy_color
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.3, 0.35, 1.0)
	add_theme_stylebox_override("panel", style)


func apply_danger_style(border_color: Color, shadow_color: Color) -> void:
	"""Apply danger highlighting style."""
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = enemy_color
	style.set_corner_radius_all(8)
	style.set_border_width_all(4)
	style.border_color = border_color
	style.shadow_color = shadow_color
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 0)
	add_theme_stylebox_override("panel", style)


func _on_mouse_entered() -> void:
	"""Handle mouse enter - emit signal."""
	hover_entered.emit(self, enemy_instance)


func _on_mouse_exited() -> void:
	"""Handle mouse exit - emit signal."""
	hover_exited.emit(self)


# ============== STATIC FACTORY METHOD ==============

static func create(enemy, color: Color, visual_size: Vector2) -> IndividualEnemyPanel:
	"""Factory method to create and setup an individual enemy panel."""
	var scene: PackedScene = preload("res://scenes/combat/components/IndividualEnemyPanel.tscn")
	var instance: IndividualEnemyPanel = scene.instantiate()
	instance.call_deferred("setup", enemy, color, visual_size)
	return instance


