extends Control
## BattlefieldArena - Visual representation of the ring-based battlefield
## Shows concentric rings with the Warden at center and enemies in rings

signal ring_clicked(ring: int)
signal enemy_clicked(enemy)  # enemy: EnemyInstance

@onready var rings_container: Control = $RingsContainer
@onready var enemy_container: Control = $EnemyContainer
@onready var effects_container: Control = $EffectsContainer
@onready var damage_numbers: Control = $DamageNumbers

# Ring configuration - proportions of the available space (made larger)
const RING_PROPORTIONS: Array[float] = [0.18, 0.42, 0.68, 0.95]  # MELEE, CLOSE, MID, FAR
const RING_COLORS: Array[Color] = [
	Color(1.0, 0.2, 0.2, 0.25),   # MELEE - Red danger zone
	Color(1.0, 0.5, 0.2, 0.20),   # CLOSE - Orange warning
	Color(0.9, 0.8, 0.2, 0.15),   # MID - Yellow caution
	Color(0.3, 0.5, 1.0, 0.10)    # FAR - Blue safe(r)
]
const RING_NAMES: Array[String] = ["MELEE", "CLOSE", "MID", "FAR"]
const RING_BORDER_COLORS: Array[Color] = [
	Color(1.0, 0.3, 0.3, 0.8),
	Color(1.0, 0.6, 0.3, 0.6),
	Color(0.9, 0.8, 0.3, 0.5),
	Color(0.4, 0.6, 1.0, 0.4)
]

const ENEMY_COLORS: Dictionary = {
	"husk": Color(0.7, 0.4, 0.3),
	"spinecrawler": Color(0.8, 0.3, 0.5),
	"torchbearer": Color(1.0, 0.6, 0.2),
	"spitter": Color(0.3, 0.7, 0.4),
	"shell_titan": Color(0.5, 0.5, 0.65),
	"bomber": Color(1.0, 0.3, 0.1),
	"channeler": Color(0.6, 0.3, 0.8),
	"ember_saint": Color(1.0, 0.5, 0.0),
	"cultist": Color(0.5, 0.4, 0.6),
	"stalker": Color(0.3, 0.3, 0.4)
}

var enemy_visuals: Dictionary = {}  # instance_id -> Control
var center: Vector2 = Vector2.ZERO
var max_radius: float = 200.0


func _ready() -> void:
	_connect_signals()
	# Ensure we redraw when ready
	queue_redraw()


func _process(_delta: float) -> void:
	# Continuously redraw to ensure rings are visible
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalculate_layout()
		queue_redraw()


func _recalculate_layout() -> void:
	# The arena draws as a top-half semicircle, so its visual center is halfway
	# between the warden (bottom) and the top of the FAR ring.
	# Offset the draw center downward by half the radius so the visual midpoint
	# of the arena aligns with the screen center.
	max_radius = min(size.x, size.y) * 0.58
	center = Vector2(size.x / 2.0, size.y / 2.0 + max_radius * 0.5)


func _draw() -> void:
	_recalculate_layout()
	
	# Debug: print size to ensure we have valid dimensions
	if size.x < 10 or size.y < 10:
		print("[BattlefieldArena] Warning: Size too small: ", size)
		return
	
	# Draw background
	var bg_rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, Color(0.06, 0.04, 0.09, 1.0))
	
	# Draw rings from outer to inner
	for i: int in range(RING_PROPORTIONS.size() - 1, -1, -1):
		var radius: float = max_radius * RING_PROPORTIONS[i]
		_draw_ring(i, radius)
	
	# Draw warden at center
	_draw_warden()


func _draw_ring(ring_index: int, radius: float) -> void:
	var color: Color = RING_COLORS[ring_index]
	var border_color: Color = RING_BORDER_COLORS[ring_index]
	
	# Draw filled ring area (as semicircle facing upward - enemies come from top)
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 48
	
	# Create arc for the ring (top half where enemies come from)
	for i: int in range(segments + 1):
		var angle: float = PI + (float(i) / float(segments)) * PI
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	# Close the shape
	if ring_index > 0:
		var inner_radius: float = max_radius * RING_PROPORTIONS[ring_index - 1]
		for i: int in range(segments, -1, -1):
			var angle: float = PI + (float(i) / float(segments)) * PI
			points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)
	else:
		# For melee ring, close to center
		points.append(center)
	
	if points.size() >= 3:
		draw_colored_polygon(points, color)
	
	# Draw ring border arc
	var arc_points: int = 64
	for i: int in range(arc_points):
		var angle1: float = PI + (float(i) / float(arc_points)) * PI
		var angle2: float = PI + (float(i + 1) / float(arc_points)) * PI
		var p1: Vector2 = center + Vector2(cos(angle1), sin(angle1)) * radius
		var p2: Vector2 = center + Vector2(cos(angle2), sin(angle2)) * radius
		draw_line(p1, p2, border_color, 2.0, true)
	
	# Draw ring label
	var label_pos: Vector2 = center + Vector2(radius - 30, 20)
	var ring_name: String = RING_NAMES[ring_index]
	draw_string(ThemeDB.fallback_font, label_pos, ring_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, border_color)


func _draw_warden() -> void:
	# Draw warden glow
	var glow_color: Color = Color(0.9, 0.7, 0.3, 0.3)
	draw_circle(center, 35.0, glow_color)
	
	# Draw warden body
	var body_color: Color = Color(0.95, 0.8, 0.5, 1.0)
	draw_circle(center, 25.0, body_color)
	
	# Draw inner highlight
	var highlight_color: Color = Color(1.0, 0.9, 0.6, 1.0)
	draw_circle(center, 15.0, highlight_color)
	
	# Draw warden icon
	var icon_color: Color = Color(0.3, 0.2, 0.1, 1.0)
	draw_circle(center, 8.0, icon_color)


func _connect_signals() -> void:
	# Connect to CombatManager signals
	if CombatManager:
		CombatManager.enemy_spawned.connect(_on_enemy_spawned)
		CombatManager.enemy_killed.connect(_on_enemy_killed)
		CombatManager.enemy_moved.connect(_on_enemy_moved)
		CombatManager.damage_dealt_to_enemies.connect(_on_damage_dealt)
		CombatManager.player_damaged.connect(_on_player_damaged)


func _on_enemy_spawned(enemy) -> void:  # enemy: EnemyInstance
	_create_enemy_visual(enemy)


func _on_enemy_killed(enemy) -> void:  # enemy: EnemyInstance
	_remove_enemy_visual(enemy)


func _on_enemy_moved(enemy, _from_ring: int, _to_ring: int) -> void:  # enemy: EnemyInstance
	_update_enemy_position(enemy)


func _on_damage_dealt(amount: int, ring: int) -> void:
	_show_damage_number(amount, ring)


func _on_player_damaged(amount: int, _source: String) -> void:
	_show_player_damage(amount)


func _create_enemy_visual(enemy) -> void:  # enemy: EnemyInstance
	_recalculate_layout()
	
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	
	# Use a Panel as the base - it handles mouse events better
	var visual: Panel = Panel.new()
	var enemy_visual_size: Vector2 = _get_enemy_visual_size()
	var width: float = enemy_visual_size.x
	var height: float = enemy_visual_size.y
	visual.custom_minimum_size = enemy_visual_size
	visual.size = enemy_visual_size
	visual.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Store enemy reference for hover
	visual.set_meta("enemy_instance", enemy)
	visual.set_meta("enemy_id", enemy.enemy_id)
	
	# Style the panel directly
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy.enemy_id, Color(0.8, 0.3, 0.3))
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.3, 0.35, 1.0)
	visual.add_theme_stylebox_override("panel", style)
	
	# Enemy icon
	var icon_label: Label = Label.new()
	icon_label.position = Vector2((width - 30.0) * 0.5, 6.0)
	icon_label.size = Vector2(30, 30)
	icon_label.add_theme_font_size_override("font_size", 26)
	icon_label.text = enemy_def.display_icon if enemy_def else "👤"
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(icon_label)
	
	# Damage indicator (shows how much damage this enemy deals)
	var damage_label: Label = Label.new()
	damage_label.name = "DamageLabel"
	damage_label.position = Vector2(0.0, height * 0.42)
	damage_label.size = Vector2(width, 20.0)
	damage_label.add_theme_font_size_override("font_size", 12)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if enemy_def:
		var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
		damage_label.text = "⚔ " + str(dmg)
	visual.add_child(damage_label)
	
	# HP bar background
	var hp_bg: ColorRect = ColorRect.new()
	hp_bg.position = Vector2(4.0, height * 0.68)
	hp_bg.size = Vector2(width - 8.0, 10.0)
	hp_bg.color = Color(0.1, 0.1, 0.1, 1.0)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(hp_bg)
	
	# HP bar fill
	var hp_fill: ColorRect = ColorRect.new()
	hp_fill.name = "HPFill"
	hp_fill.position = hp_bg.position
	hp_fill.size = hp_bg.size
	hp_fill.set_meta("max_width", hp_bg.size.x)
	hp_fill.color = Color(0.2, 0.85, 0.2, 1.0)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(hp_fill)
	
	# HP text
	var hp_text: Label = Label.new()
	hp_text.name = "HPText"
	hp_text.position = Vector2(0.0, height * 0.8)
	hp_text.size = Vector2(width, 18.0)
	hp_text.add_theme_font_size_override("font_size", 11)
	hp_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.text = str(enemy.current_hp)
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(hp_text)
	
	# Intent indicator for melee enemies
	if enemy_def and enemy.ring == 0:  # In melee range
		var intent: Label = Label.new()
		intent.name = "IntentIcon"
		intent.position = Vector2(width - 20.0, -10.0)
		intent.add_theme_font_size_override("font_size", 16)
		intent.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		intent.text = "⚔️"
		intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(intent)
	
	# Connect hover signals
	visual.mouse_entered.connect(_on_enemy_hover_enter.bind(visual, enemy))
	visual.mouse_exited.connect(_on_enemy_hover_exit.bind(visual))
	
	enemy_container.add_child(visual)
	enemy_visuals[enemy.instance_id] = visual
	
	# Set initial position and update
	_update_enemy_position(enemy)
	_update_enemy_hp_display(enemy, visual)


func _remove_enemy_visual(enemy) -> void:  # enemy: EnemyInstance
	if not enemy_visuals.has(enemy.instance_id):
		return
		
	var visual: Panel = enemy_visuals[enemy.instance_id]
	var death_pos: Vector2 = visual.global_position + visual.size / 2
	
	# Spawn death particles
	_spawn_death_particles(death_pos, ENEMY_COLORS.get(enemy.enemy_id, Color.RED))
	
	# Death animation
	var tween: Tween = create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.05)
	tween.tween_property(visual, "modulate", Color.RED, 0.1)
	tween.tween_property(visual, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(visual.queue_free)
	
	enemy_visuals.erase(enemy.instance_id)


func _spawn_death_particles(pos: Vector2, color: Color) -> void:
	for i: int in range(12):
		var particle: ColorRect = ColorRect.new()
		particle.size = Vector2(8, 8)
		particle.color = color
		particle.position = pos - particle.size / 2
		effects_container.add_child(particle)
		
		var dir: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var speed: float = randf_range(80, 180)
		var target_pos: Vector2 = particle.position + dir * speed
		
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_property(particle, "size", Vector2.ZERO, 0.5)
		tween.chain().tween_callback(particle.queue_free)


func _update_enemy_position(enemy) -> void:  # enemy: EnemyInstance
	if not enemy_visuals.has(enemy.instance_id):
		return
	
	_recalculate_layout()
	
	var visual: Panel = enemy_visuals[enemy.instance_id]
	var target_pos: Vector2 = _get_enemy_position(enemy)
	
	# Offset by half the visual size to center it
	target_pos -= visual.size / 2
	
	# Animate movement
	var tween: Tween = create_tween()
	tween.tween_property(visual, "position", target_pos, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Update HP display
	_update_enemy_hp_display(enemy, visual)


func _update_enemy_hp_display(enemy, visual: Panel) -> void:
	var hp_fill: ColorRect = visual.get_node_or_null("HPFill")
	var hp_text: Label = visual.get_node_or_null("HPText")
	
	if hp_fill:
		var hp_percent: float = enemy.get_hp_percentage()
		var max_width: float = float(hp_fill.get_meta("max_width", hp_fill.size.x))
		hp_fill.size.x = max_width * hp_percent
		hp_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	
	if hp_text:
		hp_text.text = str(enemy.current_hp)
	
	# Update intent indicator based on ring
	var intent: Label = visual.get_node_or_null("IntentIcon")
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	
	if enemy_def:
		if intent == null and enemy.ring == 0:
			# Add attack intent for melee enemies
			intent = Label.new()
			intent.name = "IntentIcon"
			var panel_width: float = visual.custom_minimum_size.x
			intent.position = Vector2(panel_width - 20.0, -10.0)
			intent.add_theme_font_size_override("font_size", 16)
			intent.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			intent.text = "⚔️"
			intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
			visual.add_child(intent)
		elif intent and enemy.ring != 0:
			intent.queue_free()
		
		# Show movement intent if not at target ring
		if enemy.ring > enemy_def.target_ring:
			var move_intent: Label = visual.get_node_or_null("MoveIntent")
			if move_intent == null:
				move_intent = Label.new()
				move_intent.name = "MoveIntent"
				move_intent.position = Vector2(-8, -8)
				move_intent.add_theme_font_size_override("font_size", 16)
				move_intent.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
				move_intent.text = "→"
				move_intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
				visual.add_child(move_intent)


func _get_enemy_position(enemy) -> Vector2:  # enemy: EnemyInstance
	var ring_radius: float = max_radius * RING_PROPORTIONS[enemy.ring]
	
	# Get enemies in this ring for distribution
	var enemies_in_ring: Array = CombatManager.battlefield.get_enemies_in_ring(enemy.ring)
	var index: int = 0
	for i: int in range(enemies_in_ring.size()):
		if enemies_in_ring[i].instance_id == enemy.instance_id:
			index = i
			break
	
	var count: int = enemies_in_ring.size()
	
	# Distribute enemies in upper arc (where they come from)
	var angle_start: float = PI + PI * 0.15  # Start slightly past left
	var angle_end: float = 2 * PI - PI * 0.15  # End slightly before right
	var angle_spread: float = angle_end - angle_start
	
	var angle: float = angle_start + angle_spread / 2.0  # Default to center
	if count > 1:
		angle = angle_start + (angle_spread / float(count - 1)) * float(index)
	elif count == 1:
		angle = angle_start + angle_spread / 2.0
	
	return center + Vector2(cos(angle), sin(angle)) * ring_radius


func _get_enemy_visual_size() -> Vector2:
	var shortest_side: float = min(size.x, size.y)
	if shortest_side <= 0.0:
		return Vector2(80.0, 110.0)
	var width: float = clamp(shortest_side * 0.11, 70.0, 150.0)
	var height: float = clamp(width * 1.25, 90.0, 190.0)
	return Vector2(width, height)


func _show_damage_number(amount: int, ring: int) -> void:
	_recalculate_layout()
	
	var label: Label = Label.new()
	label.text = "-" + str(amount)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	
	var ring_radius: float = max_radius * RING_PROPORTIONS[ring]
	label.position = center + Vector2(randf_range(-50, 50), -ring_radius - 20)
	
	damage_numbers.add_child(label)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)


func _show_player_damage(amount: int) -> void:
	_recalculate_layout()
	
	var label: Label = Label.new()
	label.text = "-" + str(amount)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	label.position = center + Vector2(-25, -20)
	
	damage_numbers.add_child(label)
	
	# Screen shake effect
	var original_pos: Vector2 = position
	var shake_tween: Tween = create_tween()
	for i: int in range(6):
		var offset: Vector2 = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		shake_tween.tween_property(self, "position", original_pos + offset, 0.04)
	shake_tween.tween_property(self, "position", original_pos, 0.04)
	
	# Flash warden red
	modulate = Color(1.2, 0.5, 0.5, 1.0)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Fade out damage number
	var label_tween: Tween = create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(label, "position:y", label.position.y - 50, 0.7)
	label_tween.tween_property(label, "modulate:a", 0.0, 0.7)
	label_tween.chain().tween_callback(label.queue_free)


func refresh_all_enemies() -> void:
	"""Refresh all enemy visuals from current battlefield state."""
	for visual: Panel in enemy_visuals.values():
		visual.queue_free()
	enemy_visuals.clear()
	
	if CombatManager.battlefield:
		for enemy in CombatManager.battlefield.get_all_enemies():
			_create_enemy_visual(enemy)
	
	queue_redraw()


func update_enemy_hp(enemy) -> void:  # enemy: EnemyInstance
	"""Update HP display for a specific enemy."""
	if enemy_visuals.has(enemy.instance_id):
		var visual: Panel = enemy_visuals[enemy.instance_id]
		_update_enemy_hp_display(enemy, visual)


# ============== ENEMY HOVER TOOLTIP SYSTEM ==============

var current_tooltip: PanelContainer = null

func _on_enemy_hover_enter(visual: Panel, enemy) -> void:
	# Highlight the enemy panel directly
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy.enemy_id, Color(0.8, 0.3, 0.3)).lightened(0.15)
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	style.border_color = Color(1.0, 0.9, 0.4, 1.0)
	visual.add_theme_stylebox_override("panel", style)
	
	# Scale up slightly
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector2(1.2, 1.2), 0.12).set_ease(Tween.EASE_OUT)
	
	# Bring to front
	visual.z_index = 10
	
	# Show tooltip
	_show_enemy_tooltip(visual, enemy)


func _on_enemy_hover_exit(visual: Panel) -> void:
	# Reset highlight
	var enemy_id: String = visual.get_meta("enemy_id", "")
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ENEMY_COLORS.get(enemy_id, Color(0.8, 0.3, 0.3))
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.3, 0.35, 1.0)
	visual.add_theme_stylebox_override("panel", style)
	
	# Scale back
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector2.ONE, 0.1)
	
	# Reset z-index
	visual.z_index = 0
	
	# Hide tooltip
	_hide_enemy_tooltip()


func _show_enemy_tooltip(visual: Panel, enemy) -> void:
	_hide_enemy_tooltip()
	
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	if not enemy_def:
		return
	
	# Create tooltip panel
	current_tooltip = PanelContainer.new()
	current_tooltip.z_index = 100
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.98)
	style.set_border_width_all(2)
	style.border_color = Color(0.5, 0.4, 0.6, 1.0)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	current_tooltip.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	current_tooltip.add_child(vbox)
	
	# Enemy name
	var name_label: Label = Label.new()
	name_label.text = enemy_def.display_icon + " " + enemy_def.enemy_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", ENEMY_COLORS.get(enemy.enemy_id, Color.WHITE))
	vbox.add_child(name_label)
	
	# Type badge
	var type_label: Label = Label.new()
	var type_text: String = enemy_def.enemy_type.to_upper()
	if enemy_def.is_elite:
		type_text = "⭐ ELITE"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	elif enemy_def.is_boss:
		type_text = "💀 BOSS"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	type_label.text = type_text
	type_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(type_label)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Stats
	var stats_grid: GridContainer = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 15)
	stats_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(stats_grid)
	
	# HP
	var hp_icon: Label = _create_stat_label("❤️ HP:", Color(0.7, 0.7, 0.7))
	var hp_value: Label = _create_stat_label("%d/%d" % [enemy.current_hp, enemy.max_hp], Color(0.3, 0.9, 0.3))
	stats_grid.add_child(hp_icon)
	stats_grid.add_child(hp_value)
	
	# Damage
	var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
	var dmg_icon: Label = _create_stat_label("⚔️ Damage:", Color(0.7, 0.7, 0.7))
	var dmg_value: Label = _create_stat_label(str(dmg), Color(1.0, 0.4, 0.4))
	stats_grid.add_child(dmg_icon)
	stats_grid.add_child(dmg_value)
	
	# Speed
	var speed_icon: Label = _create_stat_label("💨 Speed:", Color(0.7, 0.7, 0.7))
	var speed_value: Label = _create_stat_label(str(enemy_def.movement_speed) + " ring/turn", Color(0.5, 0.8, 1.0))
	stats_grid.add_child(speed_icon)
	stats_grid.add_child(speed_value)
	
	# Target ring
	var target_icon: Label = _create_stat_label("🎯 Target:", Color(0.7, 0.7, 0.7))
	var target_value: Label = _create_stat_label(RING_NAMES[enemy_def.target_ring], RING_BORDER_COLORS[enemy_def.target_ring])
	stats_grid.add_child(target_icon)
	stats_grid.add_child(target_value)
	
	# Separator
	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)
	
	# Intent section
	var intent_label: Label = Label.new()
	intent_label.add_theme_font_size_override("font_size", 12)
	intent_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	
	if enemy.ring == 0:  # In melee
		intent_label.text = "⚔️ ATTACKING for " + str(dmg) + " damage!"
	elif enemy.ring > enemy_def.target_ring:
		intent_label.text = "→ Moving to " + RING_NAMES[maxi(0, enemy.ring - enemy_def.movement_speed)]
	else:
		intent_label.text = "⚔️ Attacking from range"
	vbox.add_child(intent_label)
	
	# Description
	if enemy_def.description != "":
		var desc_label: Label = Label.new()
		desc_label.text = enemy_def.description
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size.x = 180
		vbox.add_child(desc_label)
	
	# Position tooltip near the enemy - add to root for proper global positioning
	get_tree().root.add_child(current_tooltip)
	
	await get_tree().process_frame
	
	# Get screen size for boundary checking
	var screen_size: Vector2 = get_viewport_rect().size
	
	var tooltip_pos: Vector2 = visual.global_position + Vector2(visual.size.x * visual.scale.x + 10, -20)
	# Keep on screen using actual screen boundaries
	if tooltip_pos.x + current_tooltip.size.x > screen_size.x - 10:
		tooltip_pos.x = visual.global_position.x - current_tooltip.size.x - 10
	if tooltip_pos.y + current_tooltip.size.y > screen_size.y - 10:
		tooltip_pos.y = screen_size.y - current_tooltip.size.y - 10
	if tooltip_pos.y < 10:
		tooltip_pos.y = 10
	if tooltip_pos.x < 10:
		tooltip_pos.x = 10
	
	current_tooltip.global_position = tooltip_pos
	
	# Fade in
	current_tooltip.modulate.a = 0.0
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(current_tooltip, "modulate:a", 1.0, 0.15)


func _create_stat_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	return label


func _hide_enemy_tooltip() -> void:
	if current_tooltip and is_instance_valid(current_tooltip):
		current_tooltip.queue_free()
		current_tooltip = null
