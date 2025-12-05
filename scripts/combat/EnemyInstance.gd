extends RefCounted
class_name EnemyInstance
## EnemyInstance - Runtime instance of an enemy on the battlefield
## V5: New armor mechanic - each hit removes 1 armor, no damage spillover

var enemy_id: String = ""
var ring: int = 3  # Current ring (FAR by default)
var current_hp: int = 10
var max_hp: int = 10

# V5: Armor system - each HIT removes 1 armor
var armor: int = 0

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


# =============================================================================
# V5 STATUS EFFECTS
# =============================================================================

func apply_status(effect_name: String, value: int, duration: int = -1) -> void:
	"""Apply a status effect to this enemy.
	V5: Hex and Burn both stack.
	"""
	if status_effects.has(effect_name):
		# Stack effects
		match effect_name:
			"hex":
				# Hex stacks damage
				status_effects[effect_name].value += value
			"burn":
				# Burn stacks
				status_effects[effect_name].value += value
			_:
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


func clear_status(effect_name: String) -> void:
	"""Alias for remove_status."""
	remove_status(effect_name)


func tick_status_effects() -> Dictionary:
	"""Process status effect durations at end of turn.
	V5: Burn deals damage (scaled by burn_potency) and reduces by 1.
	Returns: {burn_damage: int, effects_expired: Array[String]}
	"""
	var result: Dictionary = {
		"burn_damage": 0,
		"effects_expired": []
	}
	
	var expired: Array[String] = []
	
	for effect_name: String in status_effects.keys():
		var effect: Dictionary = status_effects[effect_name]
		
		# V5: Burn deals damage at end of turn (scaled by burn_potency)
		if effect_name == "burn":
			var base_burn: int = effect.value
			if base_burn > 0:
				# V5: Apply burn_potency to tick damage
				var burn_potency_mult: float = 1.0
				if RunManager and RunManager.player_stats:
					burn_potency_mult = RunManager.player_stats.get_burn_potency_multiplier()
				
				var burn_dmg: int = int(float(base_burn) * burn_potency_mult)
				current_hp -= burn_dmg
				result.burn_damage = burn_dmg
				
				# Reduce burn stacks by 1
				effect.value -= 1
				if effect.value <= 0:
					expired.append(effect_name)
				print("[EnemyInstance V5] Burn tick: ", burn_dmg, " damage (", base_burn, " stacks × ", burn_potency_mult, " potency) to ", enemy_id, " (", effect.value, " remaining)")
		elif effect.duration > 0:
			effect.duration -= 1
			if effect.duration <= 0:
				expired.append(effect_name)
	
	for effect_name: String in expired:
		status_effects.erase(effect_name)
		result.effects_expired.append(effect_name)
	
	return result


# =============================================================================
# V5 DAMAGE SYSTEM
# =============================================================================

func take_damage(base_damage: int, ignore_armor: bool = false) -> Dictionary:
	"""
	Apply damage to this enemy.
	V5 Armor mechanic: Each HIT removes 1 armor. No damage spillover.
	V5 Hex: When hexed enemy takes damage, +damage equal to Hex stacks (scaled by hex_potency), then consumed.
	
	Returns: {total_damage: int, hex_triggered: bool, hex_bonus: int, armor_absorbed: bool}
	"""
	var hex_bonus: int = 0
	var hex_triggered: bool = false
	
	# Check for hex stacks (V5: triggers before armor, scaled by hex_potency)
	if has_status("hex"):
		var base_hex: int = get_status_value("hex")
		hex_triggered = true
		remove_status("hex")  # Consume hex on damage
		
		# V5: Apply hex_potency to bonus damage
		var hex_potency_mult: float = 1.0
		if RunManager and RunManager.player_stats:
			hex_potency_mult = RunManager.player_stats.get_hex_potency_multiplier()
		
		hex_bonus = int(float(base_hex) * hex_potency_mult)
		print("[EnemyInstance V5] Hex triggered on ", enemy_id, ": +", hex_bonus, " bonus damage (", base_hex, " stacks × ", hex_potency_mult, " potency)")
	
	var total_damage: int = base_damage + hex_bonus
	
	# V5: Armor absorbs the hit completely
	if armor > 0 and not ignore_armor:
		armor -= 1  # Each hit removes 1 armor
		print("[EnemyInstance V5] Armor absorbed hit (", armor, " armor remaining)")
		# No damage dealt to HP when armor absorbs
		return {
			"total_damage": 0,
			"hex_triggered": hex_triggered,
			"hex_bonus": hex_bonus,
			"armor_absorbed": true,
			"armor_remaining": armor
		}
	
	# Apply damage to HP
	current_hp -= total_damage
	
	# Clamp HP to 0 (never show negative HP)
	if current_hp < 0:
		current_hp = 0
	
	return {
		"total_damage": total_damage,
		"hex_triggered": hex_triggered,
		"hex_bonus": hex_bonus,
		"armor_absorbed": false,
		"armor_remaining": armor
	}


func take_multi_hit_damage(damage_per_hit: int, hit_count: int, ignore_armor: bool = false) -> Dictionary:
	"""
	Apply multiple hits of damage (for multi-hit weapons).
	V5: Multi-hit weapons are effective against armor since each hit removes 1 armor.
	
	Returns: {total_damage: int, hits_dealt: int, armor_stripped: int, hex_triggered: bool}
	"""
	var total_damage: int = 0
	var hits_dealt: int = 0
	var armor_stripped: int = 0
	var hex_triggered: bool = false
	
	for i: int in range(hit_count):
		if current_hp <= 0:
			break  # Stop if dead
		
		var result: Dictionary = take_damage(damage_per_hit, ignore_armor)
		
		if result.armor_absorbed:
			armor_stripped += 1
		else:
			total_damage += result.total_damage
			hits_dealt += 1
		
		if result.hex_triggered:
			hex_triggered = true
	
	return {
		"total_damage": total_damage,
		"hits_dealt": hits_dealt,
		"armor_stripped": armor_stripped,
		"hex_triggered": hex_triggered
	}


# =============================================================================
# QUERY METHODS
# =============================================================================

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


func get_display_info() -> Dictionary:
	"""Get info for UI display."""
	var enemy_def = get_definition()
	return {
		"name": enemy_def.enemy_name if enemy_def else enemy_id,
		"hp": current_hp,
		"max_hp": max_hp,
		"armor": armor,
		"ring": ring,
		"hex": get_status_value("hex"),
		"burn": get_status_value("burn"),
		"is_elite": enemy_def.is_elite if enemy_def else false,
		"is_boss": enemy_def.is_boss if enemy_def else false,
	}
