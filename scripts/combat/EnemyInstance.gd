extends RefCounted
class_name EnemyInstance
## EnemyInstance - Runtime instance of an enemy on the battlefield

var enemy_id: String = ""
var ring: int = 3  # Current ring (FAR by default)
var current_hp: int = 10
var max_hp: int = 10

# Persistent group tracking - enemies stay in groups even when count drops
var group_id: String = ""  # Empty string means not in a group

# Spawn batch tracking - enemies spawned together share a batch ID
# Used to prevent merging groups from different spawn waves
var spawn_batch_id: int = 0

# Status effects: Dictionary of effect_name -> {value: int, duration: int}
var status_effects: Dictionary = {}

# Unique instance ID for tracking
var instance_id: int = 0
static var _next_instance_id: int = 0


func _init() -> void:
	_next_instance_id += 1
	instance_id = _next_instance_id


func apply_status(effect_name: String, value: int, duration: int = -1) -> void:
	"""Apply a status effect to this enemy."""
	if status_effects.has(effect_name):
		# Stack or refresh based on effect type
		if effect_name == "hex":
			# Hex stacks damage
			status_effects[effect_name].value += value
		else:
			# Other effects refresh duration
			status_effects[effect_name].duration = duration
	else:
		status_effects[effect_name] = {
			"value": value,
			"duration": duration
		}


func has_status(effect_name: String) -> bool:
	"""Check if enemy has a specific status effect."""
	return status_effects.has(effect_name)


func get_status_value(effect_name: String) -> int:
	"""Get the value of a status effect."""
	if status_effects.has(effect_name):
		return status_effects[effect_name].value
	return 0


func remove_status(effect_name: String) -> void:
	"""Remove a status effect from this enemy."""
	status_effects.erase(effect_name)


func tick_status_effects() -> void:
	"""Process status effect durations at end of turn."""
	var expired: Array[String] = []
	
	for effect_name: String in status_effects.keys():
		var effect: Dictionary = status_effects[effect_name]
		if effect.duration > 0:
			effect.duration -= 1
			if effect.duration <= 0:
				expired.append(effect_name)
	
	for effect_name: String in expired:
		status_effects.erase(effect_name)


func take_damage(base_damage: int) -> Dictionary:
	"""
	Apply damage to this enemy, triggering hex if present.
	Returns: {total_damage: int, hex_triggered: bool, hex_bonus: int}
	"""
	var hex_bonus: int = 0
	var hex_triggered: bool = false
	
	# Check for hex stacks
	if has_status("hex"):
		hex_bonus = get_status_value("hex")
		hex_triggered = true
		remove_status("hex")  # Consume hex on damage
		print("[EnemyInstance] Hex triggered on ", enemy_id, ": ", hex_bonus, " bonus damage")
	
	var total_damage: int = base_damage + hex_bonus
	current_hp -= total_damage
	
	# Clamp HP to 0 (never show negative HP)
	if current_hp < 0:
		current_hp = 0
	
	return {
		"total_damage": total_damage,
		"hex_triggered": hex_triggered,
		"hex_bonus": hex_bonus
	}


func get_hp_percentage() -> float:
	"""Get current HP as a percentage of max HP."""
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)


func is_alive() -> bool:
	"""Check if enemy is still alive."""
	return current_hp > 0


func get_definition():  # -> EnemyDefinition
	"""Get the EnemyDefinition for this instance."""
	return EnemyDatabase.get_enemy(enemy_id)


func get_turns_until_melee() -> int:
	"""Calculate how many turns until this enemy reaches melee (ring 0).
	Returns -1 if enemy won't reach melee (e.g., ranged enemies)."""
	var enemy_def = get_definition()
	if not enemy_def:
		return -1
	
	# Already in melee
	if ring == 0:
		return 0
	
	# Ranged enemies that stop before melee
	if enemy_def.target_ring > 0 and ring <= enemy_def.target_ring:
		return -1  # Won't advance further
	
	# Calculate turns based on movement speed
	var rings_to_travel: int = ring - enemy_def.target_ring
	var speed: int = max(enemy_def.movement_speed, 1)
	
	# Round up: if 3 rings at speed 2, takes 2 turns (ceil(3/2) = 2)
	var turns: int = int(ceil(float(rings_to_travel) / float(speed)))
	return turns


func will_attack_this_turn(enemy_def: EnemyDefinition = null) -> bool:
	"""Predict whether this enemy will attempt an attack this turn."""
	var resolved_def: EnemyDefinition = enemy_def
	if resolved_def == null:
		resolved_def = get_definition()
	if resolved_def == null:
		return false
	if resolved_def.attack_type == "suicide":
		return false
	if ring == 0:
		return true
	if resolved_def.attack_type == "ranged":
		var is_at_target_ring: bool = ring == resolved_def.target_ring
		var within_attack_range: bool = ring <= resolved_def.attack_range
		return is_at_target_ring and within_attack_range
	return false


func get_predicted_attack_damage(wave: int, enemy_def: EnemyDefinition = null) -> int:
	"""Return the damage this enemy would deal if it attacks this turn."""
	var resolved_def: EnemyDefinition = enemy_def
	if resolved_def == null:
		resolved_def = get_definition()
	if resolved_def == null:
		return 0
	if not will_attack_this_turn(resolved_def):
		return 0
	return resolved_def.get_scaled_damage(wave)

