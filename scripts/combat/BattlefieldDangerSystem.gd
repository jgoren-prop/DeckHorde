extends RefCounted
class_name BattlefieldDangerSystem
## Manages danger highlighting and pulsing glow effects on high-priority threats.

# EnemyDatabase is an autoload singleton

# Danger level system
enum DangerLevel { NONE, LOW, MEDIUM, HIGH, CRITICAL }

const DANGER_GLOW_COLORS: Dictionary = {
	DangerLevel.NONE: Color(0.0, 0.0, 0.0, 0.0),
	DangerLevel.LOW: Color(0.3, 0.9, 0.9, 0.6),
	DangerLevel.MEDIUM: Color(0.7, 0.3, 1.0, 0.7),
	DangerLevel.HIGH: Color(1.0, 0.5, 0.1, 0.8),
	DangerLevel.CRITICAL: Color(1.0, 0.2, 0.1, 0.9)
}

# Tracking
var _danger_glow_tweens: Dictionary = {}
var _danger_glow_panels: Dictionary = {}


func get_danger_level_int(level: DangerLevel) -> int:
	"""Convert DangerLevel enum to int for external use."""
	return level


func get_glow_color(level: DangerLevel) -> Color:
	"""Get the glow color for a danger level."""
	return DANGER_GLOW_COLORS.get(level, Color.TRANSPARENT)


func get_enemy_danger_level(enemy) -> DangerLevel:
	"""Calculate the danger level for an enemy based on threat priority."""
	var enemy_def: EnemyDefinition = EnemyDatabase.get_enemy(enemy.enemy_id)
	if not enemy_def:
		return DangerLevel.NONE
	
	var turns_until_melee: int = enemy.get_turns_until_melee()
	
	# CRITICAL: Bomber about to reach melee or in melee
	if enemy_def.enemy_type == "bomber" or enemy_def.special_ability == "explode_on_death":
		if turns_until_melee <= 1:
			return DangerLevel.CRITICAL
		elif turns_until_melee <= 2:
			return DangerLevel.HIGH
	
	# HIGH: Enemy reaching melee next turn
	if turns_until_melee <= 1:
		return DangerLevel.HIGH
	
	# MEDIUM: Active buffer/spawner that can affect the battle
	if enemy_def.special_ability in ["buff_allies", "spawn_minions"]:
		return DangerLevel.MEDIUM
	
	# LOW: Fast enemy that will reach melee soon
	if enemy_def.movement_speed >= 2 and turns_until_melee <= 2:
		return DangerLevel.LOW
	
	return DangerLevel.NONE


func apply_danger_highlighting(visual: Panel, enemy, key: String, arena: Node) -> void:
	"""Apply danger highlighting to a panel based on enemy threat."""
	var danger_level: DangerLevel = get_enemy_danger_level(enemy)
	
	if danger_level == DangerLevel.NONE:
		_remove_danger_glow(key)
		return
	
	_start_danger_pulse(key, visual, DANGER_GLOW_COLORS[danger_level], danger_level, arena)


func reset_panel_style(visual: Panel, enemy_id: String, enemy_colors: Dictionary) -> void:
	"""Reset panel style to default (non-danger) appearance."""
	var style: StyleBoxFlat = visual.get_theme_stylebox("panel")
	if style:
		style = style.duplicate()
		style.border_color = enemy_colors.get(enemy_id, Color(0.8, 0.3, 0.3))
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 3
		visual.add_theme_stylebox_override("panel", style)


func _start_danger_pulse(key: String, panel: Panel, glow_color: Color, danger_level: DangerLevel, arena: Node) -> void:
	"""Start a pulsing glow effect on a panel."""
	# Kill existing tween
	if _danger_glow_tweens.has(key):
		var old_tween: Tween = _danger_glow_tweens[key]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	# Apply initial glow to panel style
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
	if style:
		style = style.duplicate()
		style.border_color = glow_color
		style.shadow_color = glow_color
		style.shadow_size = 8 if danger_level >= DangerLevel.HIGH else 5
		panel.add_theme_stylebox_override("panel", style)
	
	# Create pulsing tween
	var tween: Tween = arena.create_tween()
	tween.set_loops()
	
	var pulse_speed: float = 2.0 if danger_level >= DangerLevel.CRITICAL else 1.5
	
	# Pulse between bright and dim
	tween.tween_method(
		func(t: float) -> void:
			if is_instance_valid(panel):
				var s: StyleBoxFlat = panel.get_theme_stylebox("panel")
				if s:
					s = s.duplicate()
					s.border_color = glow_color.lerp(glow_color * 0.5, t)
					s.shadow_color = glow_color.lerp(glow_color * 0.3, t)
					s.shadow_size = int(lerp(8.0, 4.0, t)) if danger_level >= DangerLevel.HIGH else int(lerp(5.0, 3.0, t))
					panel.add_theme_stylebox_override("panel", s),
		0.0, 1.0, 0.5 / pulse_speed
	)
	tween.tween_method(
		func(t: float) -> void:
			if is_instance_valid(panel):
				var s: StyleBoxFlat = panel.get_theme_stylebox("panel")
				if s:
					s = s.duplicate()
					s.border_color = glow_color.lerp(glow_color * 0.5, 1.0 - t)
					s.shadow_color = glow_color.lerp(glow_color * 0.3, 1.0 - t)
					s.shadow_size = int(lerp(8.0, 4.0, 1.0 - t)) if danger_level >= DangerLevel.HIGH else int(lerp(5.0, 3.0, 1.0 - t))
					panel.add_theme_stylebox_override("panel", s),
		0.0, 1.0, 0.5 / pulse_speed
	)
	
	_danger_glow_tweens[key] = tween


func _remove_danger_glow(key: String) -> void:
	"""Remove danger glow from a panel."""
	if _danger_glow_tweens.has(key):
		var tween: Tween = _danger_glow_tweens[key]
		if tween and tween.is_valid():
			tween.kill()
		_danger_glow_tweens.erase(key)
	
	if _danger_glow_panels.has(key):
		var panel: Panel = _danger_glow_panels[key]
		if is_instance_valid(panel):
			panel.queue_free()
		_danger_glow_panels.erase(key)


func update_all_danger_highlights(enemy_visuals: Dictionary, stack_visuals: Dictionary, arena: Node, _enemy_colors: Dictionary) -> void:
	"""Update danger highlighting for all visible enemies."""
	# Update individual enemy visuals
	for instance_id: int in enemy_visuals.keys():
		var visual: Panel = enemy_visuals[instance_id]
		if not is_instance_valid(visual) or not visual.visible:
			continue
		
		var enemy = visual.get_meta("enemy_ref", null)
		if enemy and enemy.is_alive():
			apply_danger_highlighting(visual, enemy, str(instance_id), arena)
	
	# Update stack visuals
	for stack_key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[stack_key]
		var panel: Panel = stack_data.get("panel")
		var enemies: Array = stack_data.get("enemies", [])
		
		if not is_instance_valid(panel) or enemies.is_empty():
			continue
		
		# Find highest danger in stack
		var highest_danger: DangerLevel = DangerLevel.NONE
		var most_dangerous_enemy = enemies[0]
		for enemy in enemies:
			var danger: DangerLevel = get_enemy_danger_level(enemy)
			if danger > highest_danger:
				highest_danger = danger
				most_dangerous_enemy = enemy
		
		apply_danger_highlighting(panel, most_dangerous_enemy, "stack_" + stack_key, arena)


func clear_all() -> void:
	"""Clear all danger highlighting."""
	for key: String in _danger_glow_tweens.keys():
		var tween: Tween = _danger_glow_tweens[key]
		if tween and tween.is_valid():
			tween.kill()
	_danger_glow_tweens.clear()
	
	for key: String in _danger_glow_panels.keys():
		var panel: Panel = _danger_glow_panels[key]
		if is_instance_valid(panel):
			panel.queue_free()
	_danger_glow_panels.clear()

