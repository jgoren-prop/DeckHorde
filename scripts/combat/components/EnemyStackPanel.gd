extends Panel
class_name EnemyStackPanel
## A panel representing a stack of enemies (multiple enemies of the same type).
## Shows aggregate HP, damage info, count, and intent indicators.

signal hover_entered(panel: Panel, stack_key: String)
signal hover_exited(panel: Panel, stack_key: String)

const BattlefieldInfoCardsHelper = preload("res://scripts/combat/BattlefieldInfoCards.gd")

# Node references - obtained in _ensure_nodes() since setup may be called before _ready
var icon_label: Label
var count_badge: Panel
var count_label: Label
var damage_label: Label
var hp_background: ColorRect
var hp_fill: ColorRect
var hp_text: Label
var name_label: Label
var intent_indicator: Control

# Stored data
var enemy_id: String = ""
var ring: int = 0
var stack_key: String = ""
var enemy_color: Color = Color(0.8, 0.3, 0.3)
var enemies: Array = []
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
		count_badge = $CountBadge
		count_label = $CountBadge/CountLabel
		damage_label = $DamageLabel
		hp_background = $HPBackground
		hp_fill = $HPFill
		hp_text = $HPText
		name_label = $NameLabel
		intent_indicator = $IntentIndicator


func setup(p_enemy_id: String, p_ring: int, p_enemies: Array, p_color: Color, p_stack_key: String, visual_size: Vector2) -> void:
	"""Initialize the stack panel with enemy data."""
	# Ensure node references are valid
	_ensure_nodes()
	
	enemy_id = p_enemy_id
	ring = p_ring
	enemies = p_enemies.duplicate()
	enemy_color = p_color
	stack_key = p_stack_key
	
	# Store metadata
	set_meta("is_stack", true)
	set_meta("stack_key", stack_key)
	set_meta("enemy_id", enemy_id)
	set_meta("ring", ring)
	if not enemies.is_empty():
		set_meta("representative_enemy", enemies[0])
	
	# Set panel size
	custom_minimum_size = visual_size
	size = visual_size
	
	# Apply panel style
	_apply_default_style()
	
	# Position elements based on panel size
	var width: float = visual_size.x
	var height: float = visual_size.y
	
	# Get enemy definition - EnemyDatabase is a global autoload
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
	icon_label.position = Vector2((width - 30.0) * 0.5, 4.0)
	icon_label.size = Vector2(30, 30)
	icon_label.text = "👤" if not enemy_def else enemy_def.display_icon
	
	# Position count badge
	count_badge.position = Vector2(width - 32, 2)
	count_label.text = "x" + str(enemies.size())
	_apply_count_badge_style()
	
	# Position damage label
	damage_label.position = Vector2(0.0, height * 0.38)
	damage_label.size = Vector2(width, 20.0)
	_apply_damage_label_style()
	if enemy_def:
		var wave: int = RunManager.current_wave
		var dmg: int = enemy_def.get_scaled_damage(wave)
		damage_label.text = "⚔ " + str(dmg) + " each"
	
	# Position HP bar
	hp_background.position = Vector2(4.0, height * 0.58)
	hp_background.size = Vector2(width - 8.0, 10.0)
	hp_fill.position = hp_background.position
	hp_max_width = hp_background.size.x
	hp_fill.set_meta("max_width", hp_max_width)
	
	# Position HP text
	hp_text.position = Vector2(0.0, height * 0.72)
	hp_text.size = Vector2(width, 18.0)
	
	# Position name label
	name_label.position = Vector2(0.0, height * 0.86)
	name_label.size = Vector2(width, 18.0)
	name_label.text = enemy_id if not enemy_def else enemy_def.enemy_name
	
	# Setup intent indicator
	_setup_intent_indicator(enemy_def, width)
	
	# Initial HP update
	update_aggregate_hp()


func update_aggregate_hp() -> void:
	"""Update the aggregate HP display for all enemies in the stack."""
	var total_hp: int = 0
	var total_max_hp: int = 0
	
	for e in enemies:
		if is_instance_valid(e):
			total_hp += e.current_hp
			total_max_hp += e.max_hp
	
	if total_max_hp > 0:
		var hp_percent: float = float(total_hp) / float(total_max_hp)
		hp_fill.size.x = hp_max_width * hp_percent
		hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
		hp_text.text = str(total_hp) + "/" + str(total_max_hp) + " total"


func update_count(new_enemies: Array) -> void:
	"""Update the enemy count when enemies are added or removed."""
	enemies = new_enemies.duplicate()
	count_label.text = "x" + str(enemies.size())
	if not enemies.is_empty():
		set_meta("representative_enemy", enemies[0])
	update_aggregate_hp()


func _apply_default_style() -> void:
	"""Apply the default (non-hovered) panel style."""
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = enemy_color
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	style.border_color = Color(1.0, 0.85, 0.4, 0.9)  # Gold border for stacks
	add_theme_stylebox_override("panel", style)


func _apply_count_badge_style() -> void:
	"""Apply style to the count badge."""
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.9, 0.2, 0.2, 1.0)
	badge_style.set_corner_radius_all(6)
	count_badge.add_theme_stylebox_override("panel", badge_style)


func _apply_damage_label_style() -> void:
	"""Apply dark background style to damage label for legibility."""
	var dmg_bg_style: StyleBoxFlat = StyleBoxFlat.new()
	dmg_bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	dmg_bg_style.set_corner_radius_all(3)
	dmg_bg_style.content_margin_left = 4
	dmg_bg_style.content_margin_right = 4
	dmg_bg_style.content_margin_top = 1
	dmg_bg_style.content_margin_bottom = 1
	damage_label.add_theme_stylebox_override("normal", dmg_bg_style)


func _setup_intent_indicator(enemy_def, _panel_width: float) -> void:
	"""Setup the intent indicator showing movement and/or attack intents."""
	# Clear existing children
	for child in intent_indicator.get_children():
		child.queue_free()
	
	if not enemy_def or enemies.is_empty():
		return
	
	var representative = enemies[0]
	if representative == null:
		return
	
	var current_ring: int = representative.ring
	var enemy_count: int = enemies.size()
	
	# Calculate movement intent
	var will_move: bool = current_ring > enemy_def.target_ring
	var move_distance: int = 0
	if will_move:
		move_distance = min(enemy_def.movement_speed, current_ring - enemy_def.target_ring)
	
	# Calculate attack intent
	var will_attack: bool = representative.will_attack_this_turn(enemy_def)
	var total_attack_damage: int = 0
	var wave: int = RunManager.current_wave
	var damage_per_enemy: int = enemy_def.get_scaled_damage(wave)
	
	if will_attack:
		total_attack_damage = damage_per_enemy * enemy_count
	
	var y_offset: float = 0.0
	var intent_x: float = -38.0
	
	# Movement intent
	if will_move and move_distance > 0:
		var move_panel: PanelContainer = _create_move_intent_panel(move_distance)
		move_panel.position = Vector2(intent_x, y_offset + 8)
		intent_indicator.add_child(move_panel)
		y_offset += 42.0
	
	# Attack intent
	if will_attack and total_attack_damage > 0:
		var attack_panel: PanelContainer = _create_attack_intent_panel(total_attack_damage)
		attack_panel.position = Vector2(intent_x, y_offset + 8)
		intent_indicator.add_child(attack_panel)


func _create_move_intent_panel(move_distance: int) -> PanelContainer:
	"""Create a movement intent indicator panel."""
	var move_panel: PanelContainer = PanelContainer.new()
	move_panel.name = "MoveIntent"
	
	var move_style: StyleBoxFlat = StyleBoxFlat.new()
	move_style.bg_color = Color(0.15, 0.12, 0.08, 0.95)
	move_style.border_color = Color(1.0, 0.8, 0.3, 0.9)
	move_style.set_border_width_all(1)
	move_style.set_corner_radius_all(6)
	move_style.content_margin_left = 6.0
	move_style.content_margin_right = 6.0
	move_style.content_margin_top = 2.0
	move_style.content_margin_bottom = 2.0
	move_panel.add_theme_stylebox_override("panel", move_style)
	move_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var move_vbox: VBoxContainer = VBoxContainer.new()
	move_vbox.add_theme_constant_override("separation", -2)
	move_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_panel.add_child(move_vbox)
	
	var dist_label: Label = Label.new()
	dist_label.text = str(move_distance)
	dist_label.add_theme_font_size_override("font_size", 14)
	dist_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dist_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_vbox.add_child(dist_label)
	
	var arrow_label: Label = Label.new()
	arrow_label.text = "|\n▼"
	arrow_label.add_theme_font_size_override("font_size", 18)
	arrow_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.add_theme_constant_override("line_spacing", -8)
	arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_vbox.add_child(arrow_label)
	
	return move_panel


func _create_attack_intent_panel(total_damage: int) -> PanelContainer:
	"""Create an attack intent indicator panel."""
	var attack_panel: PanelContainer = PanelContainer.new()
	attack_panel.name = "AttackIntent"
	
	var attack_style: StyleBoxFlat = StyleBoxFlat.new()
	attack_style.bg_color = Color(0.2, 0.08, 0.08, 0.95)
	attack_style.border_color = Color(1.0, 0.4, 0.4, 0.9)
	attack_style.set_border_width_all(1)
	attack_style.set_corner_radius_all(6)
	attack_style.content_margin_left = 6.0
	attack_style.content_margin_right = 6.0
	attack_style.content_margin_top = 2.0
	attack_style.content_margin_bottom = 2.0
	attack_panel.add_theme_stylebox_override("panel", attack_style)
	attack_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var attack_vbox: VBoxContainer = VBoxContainer.new()
	attack_vbox.add_theme_constant_override("separation", -2)
	attack_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attack_panel.add_child(attack_vbox)
	
	var dmg_label: Label = Label.new()
	dmg_label.text = str(total_damage)
	dmg_label.add_theme_font_size_override("font_size", 14)
	dmg_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	dmg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attack_vbox.add_child(dmg_label)
	
	var sword_label: Label = Label.new()
	sword_label.text = "⚔️"
	sword_label.add_theme_font_size_override("font_size", 20)
	sword_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sword_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attack_vbox.add_child(sword_label)
	
	return attack_panel


func _on_mouse_entered() -> void:
	"""Handle mouse enter - emit signal for expansion."""
	hover_entered.emit(self, stack_key)


func _on_mouse_exited() -> void:
	"""Handle mouse exit - emit signal for collapse timer."""
	hover_exited.emit(self, stack_key)


# ============== STATIC FACTORY METHOD ==============

static func create(p_enemy_id: String, p_ring: int, p_enemies: Array, p_color: Color, p_stack_key: String, visual_size: Vector2) -> EnemyStackPanel:
	"""Factory method to create and setup an enemy stack panel."""
	var scene: PackedScene = preload("res://scenes/combat/components/EnemyStackPanel.tscn")
	var instance: EnemyStackPanel = scene.instantiate()
	instance.call_deferred("setup", p_enemy_id, p_ring, p_enemies, p_color, p_stack_key, visual_size)
	return instance
