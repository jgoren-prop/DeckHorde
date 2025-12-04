extends RefCounted
class_name BattlefieldTargetingHints
## Manages card targeting hint display - shows which enemies would be hit on card hover.

# EnemyDatabase is accessed via Engine.get_singleton at runtime

# Colors
const TARGETING_HINT_COLOR: Color = Color(1.0, 0.95, 0.4, 0.3)
const KILL_INDICATOR_COLOR: Color = Color(1.0, 0.2, 0.2, 0.8)

# State
var _targeting_hint_overlays: Dictionary = {}
var _targeting_hint_active: bool = false


func is_active() -> bool:
	"""Check if targeting hints are currently active."""
	return _targeting_hint_active


func show_card_targeting_hints(card_def, tier: int, battlefield, enemy_visuals: Dictionary, stack_visuals: Dictionary, arena: Node) -> void:
	"""Show targeting hints for a card being hovered."""
	clear_card_targeting_hints()
	
	if not card_def or not battlefield:
		return
	
	_targeting_hint_active = true
	
	# Get targeted enemies based on card's targeting
	var targets: Array = _get_targeted_enemies(card_def, battlefield)
	
	# Calculate damage and hex for each target
	var base_damage: int = card_def.get_damage(tier) if card_def.has_method("get_damage") else card_def.damage
	var hex_damage: int = card_def.hex if "hex" in card_def else 0
	
	# Show hints on each target
	for enemy in targets:
		_show_targeting_hint_for_enemy(enemy, base_damage, hex_damage, enemy_visuals, stack_visuals, arena)


func clear_card_targeting_hints() -> void:
	"""Clear all targeting hints."""
	_targeting_hint_active = false
	
	for key: String in _targeting_hint_overlays.keys():
		var overlay: Control = _targeting_hint_overlays[key]
		if is_instance_valid(overlay):
			overlay.queue_free()
	_targeting_hint_overlays.clear()


func show_for_card(_card_def, _tier: int, _enemy_groups: Dictionary, _center: Vector2) -> void:
	"""Simplified interface for showing card targeting hints.
	Called from BattlefieldArena. Currently a stub - full implementation pending."""
	# TODO: Implement this when we have full targeting hints working
	pass


func clear() -> void:
	"""Alias for clear_card_targeting_hints."""
	clear_card_targeting_hints()


func _get_targeted_enemies(card_def, battlefield) -> Array:
	"""Get enemies that would be targeted by a card."""
	var targets: Array = []
	
	var targeting: String = card_def.targeting if "targeting" in card_def else "single"
	var target_ring: int = card_def.target_ring if "target_ring" in card_def else -1
	
	match targeting:
		"all":
			# All enemies on the battlefield
			for ring: int in range(4):
				targets.append_array(battlefield.get_enemies_in_ring(ring))
		
		"ring":
			# All enemies in a specific ring
			if target_ring >= 0:
				targets.append_array(battlefield.get_enemies_in_ring(target_ring))
		
		"closest":
			# Closest enemy
			var closest = battlefield.get_closest_enemy()
			if closest:
				targets.append(closest)
		
		"farthest":
			# Farthest enemy
			var farthest = battlefield.get_farthest_enemy()
			if farthest:
				targets.append(farthest)
		
		"random":
			# Show all potential targets (random will pick one)
			for ring: int in range(4):
				targets.append_array(battlefield.get_enemies_in_ring(ring))
		
		"melee":
			# Melee ring only
			targets.append_array(battlefield.get_enemies_in_ring(0))
		
		"close":
			# Close ring
			targets.append_array(battlefield.get_enemies_in_ring(1))
		
		"front":
			# Front row (melee + close)
			targets.append_array(battlefield.get_enemies_in_ring(0))
			targets.append_array(battlefield.get_enemies_in_ring(1))
		
		"back":
			# Back row (mid + far)
			targets.append_array(battlefield.get_enemies_in_ring(2))
			targets.append_array(battlefield.get_enemies_in_ring(3))
		
		_:
			# Default: closest enemy for single target
			var closest = battlefield.get_closest_enemy()
			if closest:
				targets.append(closest)
	
	return targets


func _show_targeting_hint_for_enemy(enemy, damage: int, hex_damage: int, enemy_visuals: Dictionary, stack_visuals: Dictionary, arena: Node) -> void:
	"""Show targeting hint on an enemy."""
	var visual: Panel = null
	var key: String = ""
	
	# Check if enemy is in a stack
	var stack_key: String = _find_enemy_stack_key(enemy, stack_visuals)
	if not stack_key.is_empty() and stack_visuals.has(stack_key):
		visual = stack_visuals[stack_key].get("panel")
		key = "stack_" + stack_key
	elif enemy_visuals.has(enemy.instance_id):
		visual = enemy_visuals[enemy.instance_id]
		key = str(enemy.instance_id)
	
	if not is_instance_valid(visual):
		return
	
	# Skip if already showing hint for this key
	if _targeting_hint_overlays.has(key):
		return
	
	# Create hint overlay
	var overlay: Control = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Check if this would kill the enemy
	var total_damage: int = damage + hex_damage
	var would_kill: bool = enemy.current_hp <= total_damage
	
	# Highlight panel
	var highlight: Panel = Panel.new()
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = KILL_INDICATOR_COLOR if would_kill else TARGETING_HINT_COLOR
	style.set_corner_radius_all(6)
	highlight.add_theme_stylebox_override("panel", style)
	overlay.add_child(highlight)
	
	# Damage preview label
	var damage_label: Label = Label.new()
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	damage_label.set_anchors_preset(Control.PRESET_CENTER)
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var text: String = ""
	if damage > 0:
		text = str(damage)
	if hex_damage > 0:
		text += (" + " if text.length() > 0 else "") + "☠" + str(hex_damage)
	if would_kill:
		text += " 💀"
	
	damage_label.text = text
	damage_label.add_theme_font_size_override("font_size", 14)
	damage_label.add_theme_color_override("font_color", Color.WHITE)
	damage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	damage_label.add_theme_constant_override("outline_size", 2)
	
	# Center the label
	damage_label.position = Vector2(visual.size.x / 2 - 30, visual.size.y / 2 - 10)
	damage_label.size = Vector2(60, 20)
	overlay.add_child(damage_label)
	
	visual.add_child(overlay)
	_targeting_hint_overlays[key] = overlay
	
	# Animate in
	overlay.modulate.a = 0.0
	var tween: Tween = arena.create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.15)


func _find_enemy_stack_key(enemy, stack_visuals: Dictionary) -> String:
	"""Find the stack key for an enemy."""
	for stack_key: String in stack_visuals.keys():
		var stack_data: Dictionary = stack_visuals[stack_key]
		if stack_data.has("enemies"):
			for stacked_enemy in stack_data.enemies:
				if stacked_enemy.instance_id == enemy.instance_id:
					return stack_key
	return ""

