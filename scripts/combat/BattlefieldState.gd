extends RefCounted
class_name BattlefieldState
## BattlefieldState - Manages the ring-based battlefield model
## Tracks all enemies in their respective rings

# Preload to avoid class_name resolution issues
const EnemyInstanceScript = preload("res://scripts/combat/EnemyInstance.gd")

enum Ring {
	MELEE = 0,
	CLOSE = 1,
	MID = 2,
	FAR = 3
}

signal enemy_added(enemy, ring: int)  # enemy: EnemyInstance
signal enemy_removed(enemy)  # enemy: EnemyInstance
signal enemy_moved(enemy, from_ring: int, to_ring: int)  # enemy: EnemyInstance
signal barrier_consumed(ring: int)  # Emitted when a barrier's uses reach 0

# Enemies stored by ring
var rings: Array[Array] = [[], [], [], []]  # MELEE, CLOSE, MID, FAR

# Ring barriers (damage enemies crossing them)
var ring_barriers: Dictionary = {}  # ring -> {damage: int, turns_remaining: int}


func _init() -> void:
	# Initialize empty rings
	for i: int in range(4):
		rings[i] = []


func spawn_enemy(enemy_id: String, ring: int):  # -> EnemyInstance
	"""Spawn a new enemy in the specified ring."""
	var enemy_def = EnemyDatabase.get_enemy(enemy_id)  # EnemyDefinition
	if not enemy_def:
		push_error("[BattlefieldState] Unknown enemy: " + enemy_id)
		return null
	
	var enemy = EnemyInstanceScript.new()  # EnemyInstance
	enemy.enemy_id = enemy_id
	enemy.ring = ring
	enemy.current_hp = enemy_def.get_scaled_hp(RunManager.current_wave)
	enemy.max_hp = enemy.current_hp
	
	rings[ring].append(enemy)
	enemy_added.emit(enemy, ring)
	
	return enemy


func remove_enemy(enemy) -> void:  # enemy: EnemyInstance
	"""Remove an enemy from the battlefield."""
	if enemy.ring >= 0 and enemy.ring < rings.size():
		rings[enemy.ring].erase(enemy)
	enemy_removed.emit(enemy)


func move_enemy(enemy, new_ring: int) -> Dictionary:  # enemy: EnemyInstance
	"""Move an enemy to a new ring. Returns info about barrier damage dealt."""
	var old_ring: int = enemy.ring
	var result: Dictionary = {
		"barrier_damage": 0,
		"killed_by_barrier": false
	}
	
	if old_ring == new_ring:
		return result
	
	# Remove from old ring
	if old_ring >= 0 and old_ring < rings.size():
		rings[old_ring].erase(enemy)
	
	# Check for barrier damage when moving inward
	if new_ring < old_ring:
		for check_ring: int in range(new_ring, old_ring):
			if ring_barriers.has(check_ring):
				var barrier: Dictionary = ring_barriers[check_ring]
				result.barrier_damage += barrier.damage
				enemy.current_hp -= barrier.damage
				
				# Consume one use of the barrier
				barrier.turns_remaining -= 1
				if barrier.turns_remaining <= 0:
					ring_barriers.erase(check_ring)
					barrier_consumed.emit(check_ring)
					# V5: Decrement active barrier count
					if RunManager and RunManager.player_stats:
						RunManager.player_stats.barriers = maxi(0, RunManager.player_stats.barriers - 1)
				
				if enemy.current_hp <= 0:
					result.killed_by_barrier = true
					enemy_removed.emit(enemy)
					return result
	
	# Add to new ring
	enemy.ring = new_ring
	if new_ring >= 0 and new_ring < rings.size():
		rings[new_ring].append(enemy)
	
	enemy_moved.emit(enemy, old_ring, new_ring)
	return result


func get_enemies_in_ring(ring: int) -> Array:  # Array[EnemyInstance]
	"""Get all enemies in a specific ring."""
	var result: Array = []
	if ring >= 0 and ring < rings.size():
		for enemy in rings[ring]:
			result.append(enemy)
	return result


func get_all_enemies() -> Array:  # Array[EnemyInstance]
	"""Get all enemies on the battlefield."""
	var result: Array = []
	for ring: Array in rings:
		for enemy in ring:
			result.append(enemy)
	return result


func get_total_enemy_count() -> int:
	"""Get total number of enemies on battlefield."""
	var count: int = 0
	for ring: Array in rings:
		count += ring.size()
	return count


func get_enemy_count_in_ring(ring: int) -> int:
	"""Get number of enemies in a specific ring."""
	if ring >= 0 and ring < rings.size():
		return rings[ring].size()
	return 0


func get_enemies_by_type(enemy_id: String) -> Array:  # Array[EnemyInstance]
	"""Get all enemies of a specific type."""
	var result: Array = []
	for ring: Array in rings:
		for enemy in ring:
			if enemy.enemy_id == enemy_id:
				result.append(enemy)
	return result


func get_random_enemy_in_rings(ring_mask: int):  # -> EnemyInstance or null
	"""Get a random enemy from rings specified by bitmask.
	ring_mask: Bitmask where bit 0 = Melee, bit 1 = Close, bit 2 = Mid, bit 3 = Far"""
	var candidates: Array = []
	for ring_idx: int in range(4):
		if ring_mask & (1 << ring_idx):
			candidates.append_array(rings[ring_idx])
	
	if candidates.is_empty():
		return null
	
	return candidates[randi() % candidates.size()]


func get_enemies_in_rings(ring_mask: int) -> Array:  # Array[EnemyInstance]
	"""Get all enemies from rings specified by bitmask.
	ring_mask: Bitmask where bit 0 = Melee, bit 1 = Close, bit 2 = Mid, bit 3 = Far"""
	var result: Array = []
	for ring_idx: int in range(4):
		if ring_mask & (1 << ring_idx):
			result.append_array(rings[ring_idx])
	return result


func add_ring_barrier(ring: int, damage: int, duration: int) -> void:
	"""Add a barrier to a ring that damages enemies passing through."""
	ring_barriers[ring] = {
		"damage": damage,
		"turns_remaining": duration
	}


func tick_status_effects() -> void:
	"""Process status effect durations."""
	# Tick down ring barriers
	var expired_barriers: Array[int] = []
	for ring: int in ring_barriers.keys():
		ring_barriers[ring].turns_remaining -= 1
		if ring_barriers[ring].turns_remaining <= 0:
			expired_barriers.append(ring)
	
	for ring: int in expired_barriers:
		ring_barriers.erase(ring)
		barrier_consumed.emit(ring)
		# V5: Decrement active barrier count
		if RunManager and RunManager.player_stats:
			RunManager.player_stats.barriers = maxi(0, RunManager.player_stats.barriers - 1)
	
	# Tick down enemy status effects
	for enemy in get_all_enemies():
		enemy.tick_status_effects()


func get_ring_name(ring: int) -> String:
	"""Get human-readable name for a ring."""
	match ring:
		Ring.MELEE:
			return "Melee"
		Ring.CLOSE:
			return "Close"
		Ring.MID:
			return "Mid"
		Ring.FAR:
			return "Far"
		_:
			return "Unknown"


static func ring_from_name(name: String) -> int:
	"""Get ring enum from name."""
	match name.to_lower():
		"melee":
			return Ring.MELEE
		"close":
			return Ring.CLOSE
		"mid":
			return Ring.MID
		"far":
			return Ring.FAR
		_:
			return -1
