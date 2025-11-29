extends Node
## CombatManager - Combat turn flow orchestration
## Now using real BattlefieldState and DeckManager

# Preload combat classes
const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")
const DeckManagerScript = preload("res://scripts/combat/DeckManager.gd")
const CardResolver = preload("res://scripts/combat/CardEffectResolver.gd")

signal phase_changed(new_phase: int)
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal energy_changed(current: int, max_energy: int)
signal card_played(card, tier: int)
signal enemy_spawned(enemy)
signal enemy_killed(enemy)
signal enemy_moved(enemy, from_ring: int, to_ring: int)
signal damage_dealt_to_enemies(amount: int, ring: int)
signal player_damaged(amount: int, source: String)
signal wave_ended(success: bool)

enum CombatPhase { INACTIVE, WAVE_START, DRAW_PHASE, PLAYER_PHASE, END_PLAYER_PHASE, ENEMY_PHASE, WAVE_CHECK }

# Current combat state
var current_phase: int = CombatPhase.INACTIVE
var current_turn: int = 0
var current_energy: int = 0
var max_energy: int = 3
var turn_limit: int = 5

# Combat objects
var battlefield = null  # BattlefieldState
var deck_manager = null  # DeckManager
var current_wave_def = null
var active_weapons: Array = []


func _ready() -> void:
	print("[CombatManager] Initialized")


func initialize_combat(wave_def) -> void:
	print("[CombatManager] Initializing combat for wave")
	current_wave_def = wave_def
	current_turn = 0
	turn_limit = wave_def.turn_limit if wave_def else 5
	max_energy = RunManager.base_energy
	active_weapons.clear()
	
	# Create real battlefield
	battlefield = BattlefieldStateScript.new()
	
	# Create real deck manager with player's deck
	deck_manager = DeckManagerScript.new()
	deck_manager.initialize(RunManager.deck.duplicate(true))
	
	# Spawn initial enemies from wave definition
	if wave_def and wave_def.initial_spawns:
		for spawn: Dictionary in wave_def.initial_spawns:
			_spawn_enemies(spawn.enemy_id, spawn.count, spawn.ring)
	
	current_phase = CombatPhase.WAVE_START
	phase_changed.emit(current_phase)
	
	# Start first turn
	start_player_turn()


func start_player_turn() -> void:
	current_turn += 1
	turn_started.emit(current_turn)
	
	# Refill energy
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)
	
	# Draw cards
	current_phase = CombatPhase.DRAW_PHASE
	phase_changed.emit(current_phase)
	
	var cards_to_draw: int = RunManager.current_warden.hand_size if RunManager.current_warden else 5
	for i in range(cards_to_draw):
		deck_manager.draw_card()
	
	# Enter player phase
	current_phase = CombatPhase.PLAYER_PHASE
	phase_changed.emit(current_phase)


func can_play_card(card_def, _tier: int) -> bool:
	if current_phase != CombatPhase.PLAYER_PHASE:
		return false
	if not card_def:
		return false
	return current_energy >= card_def.base_cost


func play_card(hand_index: int, target_ring: int = -1) -> bool:
	if current_phase != CombatPhase.PLAYER_PHASE:
		return false
	
	if hand_index < 0 or hand_index >= deck_manager.hand.size():
		return false
	
	var card_entry: Dictionary = deck_manager.hand[hand_index]
	var card_def = CardDatabase.get_card(card_entry.card_id)
	var tier: int = card_entry.tier
	
	if not card_def:
		return false
	
	var cost: int = card_def.base_cost
	if current_energy < cost:
		return false
	
	# Spend energy
	current_energy -= cost
	energy_changed.emit(current_energy, max_energy)
	
	# Remove from hand and add to discard
	deck_manager.play_card(hand_index)
	
	# Execute card effect (simplified for now)
	_execute_card_effect(card_def, tier, target_ring)
	
	card_played.emit(card_def, tier)
	return true


func _execute_card_effect(card_def, tier: int, target_ring: int) -> void:
	print("[CombatManager] Executing card: ", card_def.card_name, " (effect: ", card_def.effect_type, ")")
	
	# Use CardResolver for all card effects
	CardResolver.resolve(card_def, tier, target_ring, self)


func end_player_turn() -> void:
	if current_phase != CombatPhase.PLAYER_PHASE:
		return
	
	print("[CombatManager] Ending player turn")
	current_phase = CombatPhase.END_PLAYER_PHASE
	phase_changed.emit(current_phase)
	
	# Discard remaining hand
	deck_manager.discard_hand()
	
	# Process enemy phase
	_process_enemy_phase()


func _process_enemy_phase() -> void:
	current_phase = CombatPhase.ENEMY_PHASE
	phase_changed.emit(current_phase)
	
	print("[CombatManager] Enemy phase")
	
	# Move enemies
	var all_enemies: Array = battlefield.get_all_enemies()
	for enemy in all_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy.ring > enemy_def.target_ring:
			var new_ring: int = max(enemy_def.target_ring, enemy.ring - enemy_def.movement_speed)
			if new_ring != enemy.ring:
				var old_ring: int = enemy.ring
				battlefield.move_enemy(enemy, new_ring)
				enemy_moved.emit(enemy, old_ring, new_ring)
	
	# Enemies attack
	var melee_enemies: Array = battlefield.get_enemies_in_ring(BattlefieldStateScript.Ring.MELEE)
	var total_damage: int = 0
	for enemy in melee_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def:
			total_damage += enemy_def.get_scaled_damage(RunManager.current_wave)
	
	if total_damage > 0:
		RunManager.take_damage(total_damage)
		player_damaged.emit(total_damage, "enemies")
	
	# Spawn reinforcements
	if current_wave_def and current_wave_def.phase_spawns:
		for spawn: Dictionary in current_wave_def.phase_spawns:
			_spawn_enemies(spawn.enemy_id, spawn.count, spawn.ring)
	
	turn_ended.emit(current_turn)
	
	# Check wave end conditions
	_check_wave_end()


func _check_wave_end() -> void:
	current_phase = CombatPhase.WAVE_CHECK
	phase_changed.emit(current_phase)
	
	# Win: all enemies dead
	if battlefield.get_total_enemy_count() == 0:
		print("[CombatManager] Wave cleared!")
		wave_ended.emit(true)
		return
	
	# Lose: player dead
	if RunManager.current_hp <= 0:
		print("[CombatManager] Player defeated!")
		wave_ended.emit(false)
		return
	
	# Lose: turn limit reached with enemies remaining
	if current_turn >= turn_limit:
		print("[CombatManager] Turn limit reached!")
		wave_ended.emit(false)
		return
	
	# Continue to next turn
	start_player_turn()


func _spawn_enemies(enemy_id: String, count: int, ring: int) -> void:
	for i in range(count):
		var enemy = battlefield.spawn_enemy(enemy_id, ring)
		if enemy:
			enemy_spawned.emit(enemy)
			print("[CombatManager] Spawned ", enemy_id, " in ring ", ring)


func deal_damage_to_ring(ring: int, damage: int) -> void:
	var enemies: Array = battlefield.get_enemies_in_ring(ring)
	for enemy in enemies:
		enemy.current_hp -= damage
		if enemy.current_hp <= 0:
			battlefield.remove_enemy(enemy)
			enemy_killed.emit(enemy)
			RunManager.add_scrap(2)  # Scrap for kills
	
	damage_dealt_to_enemies.emit(damage, ring)


func deal_damage_to_random_enemy(ring_mask: int, damage: int) -> void:
	var candidates: Array = []
	for ring in range(4):
		if ring_mask & (1 << ring):
			candidates.append_array(battlefield.get_enemies_in_ring(ring))
	
	if candidates.size() > 0:
		var target = candidates[randi() % candidates.size()]
		target.current_hp -= damage
		if target.current_hp <= 0:
			battlefield.remove_enemy(target)
			enemy_killed.emit(target)
			RunManager.add_scrap(2)
		damage_dealt_to_enemies.emit(damage, target.ring)


func register_weapon(card_def, tier: int, duration: int = -1) -> void:
	active_weapons.append({
		"card_def": card_def,
		"tier": tier,
		"triggers_remaining": duration
	})


func calculate_incoming_damage() -> Dictionary:
	var total: int = 0
	var breakdown: Array = []
	
	if not battlefield:
		return {"total": 0, "breakdown": []}
	
	# Calculate damage from melee enemies
	var melee_enemies: Array = battlefield.get_enemies_in_ring(BattlefieldStateScript.Ring.MELEE)
	for enemy in melee_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def:
			var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
			total += dmg
			breakdown.append({
				"name": enemy_def.enemy_name,
				"count": 1,
				"ring": enemy.ring,
				"damage": dmg
			})
	
	return {"total": total, "breakdown": breakdown}


func get_incoming_damage() -> Dictionary:
	return calculate_incoming_damage()


func get_enemies_moving_to_melee() -> int:
	if not battlefield:
		return 0
	
	var count: int = 0
	# Check Close ring - they'll move to Melee next turn
	var close_enemies: Array = battlefield.get_enemies_in_ring(BattlefieldStateScript.Ring.CLOSE)
	for enemy in close_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.target_ring == BattlefieldStateScript.Ring.MELEE:
			count += 1
	
	return count


func cleanup_combat() -> void:
	battlefield = null
	deck_manager = null
	current_wave_def = null
	active_weapons.clear()
	current_phase = CombatPhase.INACTIVE
