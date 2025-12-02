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
signal enemy_damaged(enemy, amount: int, hex_triggered: bool)  # Specific enemy took damage
signal enemy_moved(enemy, from_ring: int, to_ring: int)
signal _enemies_spawned_together(enemies: Array, ring: int, enemy_id: String)  # Internal: enemies spawned in same batch
signal damage_dealt_to_enemies(amount: int, ring: int)
signal player_damaged(amount: int, source: String)
signal wave_ended(success: bool)
signal weapon_triggered(card_name: String, damage: int, weapon_index: int)  # Persistent weapon fired
signal enemy_ability_triggered(enemy, ability: String, value: int)  # Special ability fired
signal enemy_targeted(enemy)  # Enemy is about to be attacked (for visual indicator)
signal enemy_hexed(enemy, hex_amount: int)  # Enemy received hex (for visual indicator)
signal barrier_placed(ring: int, damage: int, duration: int)  # Barrier created
signal barrier_triggered(enemy, ring: int, damage: int)  # Barrier dealt damage to enemy
signal ring_phase_started(ring: int, ring_name: String)  # Ring is being processed
signal ring_phase_ended(ring: int)  # Ring processing complete
signal enemy_attacking(enemy, damage: int)  # Enemy is about to attack
signal weapons_phase_started()  # Persistent weapons starting to fire
signal weapons_phase_ended()  # All persistent weapons finished firing

enum CombatPhase { INACTIVE, WAVE_START, DRAW_PHASE, PLAYER_PHASE, END_PLAYER_PHASE, ENEMY_PHASE, WAVE_CHECK }

# Current combat state
var current_phase: int = CombatPhase.INACTIVE
var current_turn: int = 0
var current_energy: int = 0
var max_energy: int = 3
var turn_limit: int = 5
var kills_this_turn: int = 0  # Track kills for Leech Tooth artifact
var gun_played_this_turn: bool = false  # Track for Gun Harness cost reduction

# Combat objects
var battlefield = null  # BattlefieldState
var deck_manager = null  # DeckManager
var current_wave_def = null
var active_weapons: Array = []
var current_firing_weapon_index: int = -1  # Track which weapon INDEX is currently firing for projectile origin


func _ready() -> void:
	print("[CombatManager] Initialized")


func initialize_combat(wave_def) -> void:
	print("[CombatManager] Initializing combat for wave")
	current_wave_def = wave_def
	current_turn = 0
	turn_limit = 5 if not wave_def else wave_def.turn_limit
	max_energy = RunManager.base_energy
	active_weapons.clear()
	kills_this_turn = 0
	
	# Reset per-wave state (Glass Warden cheat death, etc.)
	RunManager.reset_wave_state()
	
	# Create real battlefield
	battlefield = BattlefieldStateScript.new()
	
	# Create real deck manager with player's deck
	deck_manager = DeckManagerScript.new()
	deck_manager.initialize(RunManager.deck.duplicate(true))
	print("[CombatManager] Deck initialized with ", deck_manager.deck.size(), " cards")
	
	# Trigger on_wave_start artifacts (e.g., Iron Shell)
	ArtifactManager.trigger_artifacts("on_wave_start", {})
	
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
	kills_this_turn = 0
	gun_played_this_turn = false
	turn_started.emit(current_turn)
	AudioManager.play_turn_start()
	
	# Trigger on_turn_start artifacts (Quick Draw, Hex Amplifier)
	var turn_start_effects: Dictionary = ArtifactManager.trigger_artifacts("on_turn_start", {})
	
	# Hex Amplifier: deal damage to hexed enemies
	if turn_start_effects.has("hex_tick_damage") and turn_start_effects.hex_tick_damage > 0:
		_deal_hex_tick_damage(turn_start_effects.hex_tick_damage)
	
	# Refill energy
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)
	
	# Draw cards
	current_phase = CombatPhase.DRAW_PHASE
	phase_changed.emit(current_phase)
	
	var cards_to_draw: int = 5 if not RunManager.current_warden else RunManager.current_warden.hand_size
	# Add bonus draws from artifacts (Quick Draw)
	cards_to_draw += turn_start_effects.draw_cards
	print("[CombatManager] Drawing ", cards_to_draw, " cards (deck: ", deck_manager.deck.size(), ", hand: ", deck_manager.hand.size(), ")")
	for i in range(cards_to_draw):
		deck_manager.draw_card()
	print("[CombatManager] After draw - hand size: ", deck_manager.hand.size())
	
	# Enter player phase
	current_phase = CombatPhase.PLAYER_PHASE
	phase_changed.emit(current_phase)


func _trigger_persistent_weapons() -> void:
	"""Trigger all registered persistent weapons with visual feedback."""
	if active_weapons.is_empty():
		return
	
	# Signal that weapons phase is starting (BattlefieldArena will hold stacks open)
	weapons_phase_started.emit()
	
	# Process each weapon with delay for visual clarity
	for i: int in range(active_weapons.size()):
		var weapon: Dictionary = active_weapons[i]
		var card_def = weapon.card_def
		var tier: int = weapon.tier
		
		print("[CombatManager] Triggering persistent weapon: ", card_def.card_name)
		
		# Track which weapon INDEX is firing (for BattlefieldArena to get projectile origin)
		# The index in active_weapons matches the index in CombatLane.deployed_weapons
		current_firing_weapon_index = i
		
		# Emit signal for visual feedback (flash icon) - include index for correct card targeting
		var damage: int = card_def.get_scaled_value("damage", tier)
		weapon_triggered.emit(card_def.card_name, damage, i)
		
		# Small delay for visual clarity between weapons (Slay the Spire style)
		await get_tree().create_timer(0.15).timeout
		
		# Use the CardResolver to trigger the weapon effect
		# Note: resolve_weapon_effect -> deal_damage_to_random_enemy handles enemy_targeted emit
		CardResolver.resolve_weapon_effect(card_def, tier, self)
		
		# Wait for projectile animation to complete before clearing weapon index
		# (The projectile fires asynchronously via signal handlers that may have awaits)
		await get_tree().create_timer(0.5).timeout
		
		# Clear weapon tracking after firing animation completes
		current_firing_weapon_index = -1
		
		# Decrement triggers remaining if not infinite (-1)
		if weapon.triggers_remaining > 0:
			weapon.triggers_remaining -= 1
		
		# Delay between weapons
		if i < active_weapons.size() - 1:
			await get_tree().create_timer(0.3).timeout
	
	# Wait for final weapon animations to complete (projectile travel + hit effect + viewing time)
	await get_tree().create_timer(1.2).timeout
	
	# Signal that weapons phase is ending (BattlefieldArena can release holds)
	weapons_phase_ended.emit()
	
	# Remove expired weapons
	active_weapons = active_weapons.filter(func(w: Dictionary) -> bool: return w.triggers_remaining != 0)


func _get_weapon_target(card_def) -> Variant:
	"""Get the target for a weapon (for visual indicator)."""
	if not battlefield:
		return null
	
	# Build ring mask from target_rings
	var ring_mask: int = 0
	for ring: int in card_def.target_rings:
		ring_mask |= (1 << ring)
	
	if ring_mask == 0:
		ring_mask = 0b1111  # All rings
	
	# Find candidates
	var candidates: Array = []
	for ring: int in range(4):
		if ring_mask & (1 << ring):
			candidates.append_array(battlefield.get_enemies_in_ring(ring))
	
	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]
	
	return null


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
	AudioManager.play_card_play()
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
	
	# Trigger persistent weapons at end of player turn (before enemy phase)
	await _trigger_persistent_weapons()
	
	# Trigger on_turn_end artifacts (Leech Tooth)
	var context: Dictionary = {}
	if kills_this_turn > 0:
		context["condition"] = "killed_this_turn"
	ArtifactManager.trigger_artifacts("on_turn_end", context)
	
	# Discard remaining hand
	deck_manager.discard_hand()
	
	# Process enemy phase
	_process_enemy_phase()


func _process_enemy_phase() -> void:
	current_phase = CombatPhase.ENEMY_PHASE
	phase_changed.emit(current_phase)
	
	print("[CombatManager] Enemy phase - processing ring by ring")
	
	# Get buffer amount ONCE at the start (in case Torchbearers die during phase)
	var buff_amount: int = _get_torchbearer_buff()
	
	# Process each ring from innermost (Melee) to outermost (Far)
	# Ring order: 0 (Melee) -> 1 (Close) -> 2 (Mid) -> 3 (Far)
	for ring: int in range(4):
		await _process_ring_phase(ring, buff_amount)
	
	# Process enemy special abilities (spawning, etc.) after movement
	await _process_enemy_abilities_visual()
	
	# Spawn reinforcements from wave definition
	if current_wave_def and current_wave_def.phase_spawns:
		ring_phase_started.emit(-1, "Reinforcements")
		await get_tree().create_timer(0.3).timeout
		for spawn: Dictionary in current_wave_def.phase_spawns:
			_spawn_enemies(spawn.enemy_id, spawn.count, spawn.ring)
		await get_tree().create_timer(0.5).timeout
		ring_phase_ended.emit(-1)
	
	turn_ended.emit(current_turn)
	
	# Check wave end conditions
	_check_wave_end()


func _process_ring_phase(ring: int, buff_amount: int) -> void:
	"""Process a single ring's enemy actions with visual feedback."""
	var ring_names: Array[String] = ["Melee", "Close", "Mid", "Far"]
	var enemies_in_ring: Array = battlefield.get_enemies_in_ring(ring)
	
	# Skip empty rings (but still show briefly for context)
	if enemies_in_ring.is_empty():
		return
	
	# Signal that we're processing this ring
	ring_phase_started.emit(ring, ring_names[ring])
	print("[CombatManager] Processing ring: ", ring_names[ring], " (", enemies_in_ring.size(), " enemies)")
	
	# Brief pause to show which ring we're processing
	await get_tree().create_timer(0.3).timeout
	
	# MELEE RING: Enemies attack!
	if ring == BattlefieldStateScript.Ring.MELEE:
		await _process_melee_attacks(enemies_in_ring, buff_amount)
	
	# ALL RINGS: Check for ranged attackers at their target ring
	await _process_ranged_attacks_in_ring(ring, buff_amount)
	
	# Brief pause after attacks
	await get_tree().create_timer(0.2).timeout
	
	# ALL RINGS: Move enemies that want to move inward
	await _process_enemy_movement_from_ring(ring)
	
	# Signal ring processing complete
	ring_phase_ended.emit(ring)
	
	# Pause between rings so player can see each step
	await get_tree().create_timer(0.5).timeout


func _process_melee_attacks(melee_enemies: Array, buff_amount: int) -> void:
	"""Process attacks from melee enemies with visual feedback."""
	var total_damage: int = 0
	var total_armor_shred: int = 0  # V2: Armor Reaver shred
	
	for enemy in melee_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.attack_type != "suicide":  # Bombers don't attack
			var base_dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
			var final_dmg: int = base_dmg + buff_amount
			
			# Signal that this enemy is attacking
			enemy_attacking.emit(enemy, final_dmg)
			await get_tree().create_timer(0.15).timeout
			
			total_damage += final_dmg
			print("[CombatManager] ", enemy_def.enemy_name, " attacks for ", final_dmg)
			
			# V2: Armor Reaver shreds additional armor
			if enemy_def.armor_shred > 0:
				total_armor_shred += enemy_def.armor_shred
				enemy_ability_triggered.emit(enemy, "armor_shred", enemy_def.armor_shred)
				print("[CombatManager] ", enemy_def.enemy_name, " shreds ", enemy_def.armor_shred, " armor!")
	
	if total_damage > 0:
		await get_tree().create_timer(0.1).timeout
		RunManager.take_damage(total_damage)
		player_damaged.emit(total_damage, "melee_enemies")
	
	# V2: Apply armor shred AFTER damage (removes armor directly)
	if total_armor_shred > 0:
		var actual_shred: int = mini(RunManager.armor, total_armor_shred)
		if actual_shred > 0:
			RunManager.armor -= actual_shred
			RunManager.armor_changed.emit(RunManager.armor)
			print("[CombatManager] Armor shredded! -", actual_shred, " armor (now ", RunManager.armor, ")")


func _process_ranged_attacks_in_ring(ring: int, buff_amount: int) -> void:
	"""Process ranged attacks from enemies in this ring."""
	var enemies_in_ring: Array = battlefield.get_enemies_in_ring(ring)
	var total_ranged_damage: int = 0
	
	for enemy in enemies_in_ring:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.attack_type == "ranged":
			# Ranged enemies attack if at their target ring and player is in range
			if enemy.ring == enemy_def.target_ring and enemy_def.attack_range >= enemy.ring:
				var base_dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
				var final_dmg: int = base_dmg + buff_amount
				
				# Signal that this enemy is attacking
				enemy_attacking.emit(enemy, final_dmg)
				await get_tree().create_timer(0.2).timeout
				
				total_ranged_damage += final_dmg
				print("[CombatManager] Ranged attack from ", enemy_def.enemy_name, " in ring ", ring, " for ", final_dmg)
	
	if total_ranged_damage > 0:
		await get_tree().create_timer(0.1).timeout
		RunManager.take_damage(total_ranged_damage)
		player_damaged.emit(total_ranged_damage, "ranged_enemies")


func _process_enemy_movement_from_ring(ring: int) -> void:
	"""Process enemy movement from a specific ring."""
	# Get fresh list of enemies (some may have died)
	var enemies_in_ring: Array = battlefield.get_enemies_in_ring(ring)
	
	# Group enemies by their group_id for synchronized movement
	var groups_to_move: Dictionary = {}  # group_id -> Array of {enemy, old_ring, new_ring}
	var ungrouped_to_move: Array = []  # Array of {enemy, old_ring, new_ring}
	
	for enemy in enemies_in_ring:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy.ring > enemy_def.target_ring:
			var new_ring: int = max(enemy_def.target_ring, enemy.ring - enemy_def.movement_speed)
			if new_ring != enemy.ring:
				var move_data: Dictionary = {
					"enemy": enemy,
					"old_ring": enemy.ring,
					"new_ring": new_ring
				}
				
				if not enemy.group_id.is_empty():
					# This enemy is part of a group - batch with others in same group
					if not groups_to_move.has(enemy.group_id):
						groups_to_move[enemy.group_id] = []
					groups_to_move[enemy.group_id].append(move_data)
				else:
					# Ungrouped enemy - move individually
					ungrouped_to_move.append(move_data)
	
	# Move grouped enemies together (all enemies in a group move at once)
	for group_id: String in groups_to_move.keys():
		var group_moves: Array = groups_to_move[group_id]
		var barrier_results: Array = []  # Store results for visual feedback
		
		# Move all enemies in the group without delay between them
		for move_data: Dictionary in group_moves:
			var result: Dictionary = battlefield.move_enemy(move_data.enemy, move_data.new_ring)
			barrier_results.append({"enemy": move_data.enemy, "result": result, "move_data": move_data})
		
		# First pass: emit barrier_triggered signals for enemies that took barrier damage (triggers stack popup)
		var any_barrier_damage: bool = false
		for i: int in range(group_moves.size()):
			var barrier_info: Dictionary = barrier_results[i]
			var result: Dictionary = barrier_info.result
			var move_data: Dictionary = barrier_info.move_data
			if result.barrier_damage > 0:
				# Use barrier_triggered signal (not enemy_targeted) so it shows barrier animation, not gun animation
				barrier_triggered.emit(barrier_info.enemy, move_data.old_ring, result.barrier_damage)
				any_barrier_damage = true
		
		# Wait for stack expansion animation if any barrier damage occurred
		if any_barrier_damage:
			await get_tree().create_timer(0.3).timeout
		
		# Second pass: emit damage and movement signals
		for i: int in range(group_moves.size()):
			var move_data: Dictionary = group_moves[i]
			var barrier_info: Dictionary = barrier_results[i]
			var result: Dictionary = barrier_info.result
			
			# Handle barrier damage visual feedback
			if result.barrier_damage > 0:
				enemy_damaged.emit(move_data.enemy, result.barrier_damage, false)  # false = not hex
				print("[CombatManager] Barrier dealt ", result.barrier_damage, " to ", move_data.enemy.enemy_id)
			
			# Handle barrier kill
			if result.killed_by_barrier:
				print("[CombatManager] ", move_data.enemy.enemy_id, " killed by barrier!")
				_handle_enemy_death(move_data.enemy, false)
			else:
				enemy_moved.emit(move_data.enemy, move_data.old_ring, move_data.new_ring)
				# Check if bomber entered melee - show warning banner
				_check_bomber_melee_warning(move_data.enemy, move_data.new_ring)
		
		# Delay after the whole group moves
		if not group_moves.is_empty():
			await get_tree().create_timer(0.15).timeout
	
	# Move ungrouped enemies one at a time with delays
	for move_data: Dictionary in ungrouped_to_move:
		var result: Dictionary = battlefield.move_enemy(move_data.enemy, move_data.new_ring)
		
		# Handle barrier damage visual feedback
		if result.barrier_damage > 0:
			# Emit barrier_triggered first to trigger stack popup with barrier animation (not gun animation)
			barrier_triggered.emit(move_data.enemy, move_data.old_ring, result.barrier_damage)
			await get_tree().create_timer(0.3).timeout  # Wait for stack expansion
			enemy_damaged.emit(move_data.enemy, result.barrier_damage, false)  # false = not hex
			print("[CombatManager] Barrier dealt ", result.barrier_damage, " to ", move_data.enemy.enemy_id)
		
		# Handle barrier kill
		if result.killed_by_barrier:
			print("[CombatManager] ", move_data.enemy.enemy_id, " killed by barrier!")
			_handle_enemy_death(move_data.enemy, false)
		else:
			enemy_moved.emit(move_data.enemy, move_data.old_ring, move_data.new_ring)
			# Check if bomber entered melee - show warning banner
			_check_bomber_melee_warning(move_data.enemy, move_data.new_ring)
		
		await get_tree().create_timer(0.1).timeout


func _check_bomber_melee_warning(enemy, new_ring: int) -> void:
	"""Check if a bomber entered melee ring and emit warning."""
	if new_ring != 0:
		return
	
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	if not enemy_def:
		return
	
	# Check if this is a bomber (suicide attack type with explode_on_death)
	if enemy_def.special_ability == "explode_on_death" or enemy_def.behavior_type == EnemyDefinition.BehaviorType.BOMBER:
		var explosion_damage: int = enemy_def.buff_amount if enemy_def.buff_amount > 0 else 5
		enemy_ability_triggered.emit(enemy, "bomber_melee_warning", explosion_damage)
		print("[CombatManager] BOMBER WARNING: ", enemy_def.enemy_name, " entered melee!")


func _process_enemy_abilities_visual() -> void:
	"""Process special abilities for all enemies with visual feedback."""
	var all_enemies: Array = battlefield.get_all_enemies()
	var spawners: Array = []
	
	# Collect spawners
	for enemy in all_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if not enemy_def or enemy_def.special_ability.is_empty():
			continue
		
		if enemy_def.special_ability == "spawn_minions":
			spawners.append({"enemy": enemy, "def": enemy_def})
	
	# Process spawners with visual feedback
	if spawners.size() > 0:
		ring_phase_started.emit(-2, "Spawning")
		await get_tree().create_timer(0.3).timeout
		
		for spawner_data: Dictionary in spawners:
			var enemy = spawner_data.enemy
			var enemy_def = spawner_data.def
			
			if enemy_def.spawn_enemy_id and enemy_def.spawn_count > 0:
				# Spawn at Far ring
				var spawn_ring: int = BattlefieldStateScript.Ring.FAR
				
				enemy_ability_triggered.emit(enemy, "spawn_minions", enemy_def.spawn_count)
				await get_tree().create_timer(0.2).timeout
				
				# Spawn all minions and create a group for them
				var spawned_minions: Array = []
				for i: int in range(enemy_def.spawn_count):
					var spawned = battlefield.spawn_enemy(enemy_def.spawn_enemy_id, spawn_ring)
					if spawned:
						spawned_minions.append(spawned)
						enemy_spawned.emit(spawned)
						print("[CombatManager] ", enemy_def.enemy_name, " spawned ", enemy_def.spawn_enemy_id)
					await get_tree().create_timer(0.15).timeout
				
				# Create a group for spawned minions
				if spawned_minions.size() > 0:
					_enemies_spawned_together.emit(spawned_minions, spawn_ring, enemy_def.spawn_enemy_id)
		
		ring_phase_ended.emit(-2)
		await get_tree().create_timer(0.3).timeout


func _check_wave_end() -> void:
	current_phase = CombatPhase.WAVE_CHECK
	phase_changed.emit(current_phase)
	
	# Win: all enemies dead
	if battlefield.get_total_enemy_count() == 0:
		print("[CombatManager] Wave cleared!")
		AudioManager.play_wave_complete()
		wave_ended.emit(true)
		return
	
	# Lose: player dead (only way to lose - no turn limit)
	if RunManager.current_hp <= 0:
		print("[CombatManager] Player defeated!")
		AudioManager.play_wave_fail()
		wave_ended.emit(false)
		return
	
	# Continue to next turn
	start_player_turn()


func _spawn_enemies(enemy_id: String, count: int, ring: int) -> void:
	"""Spawn multiple enemies and create a persistent group for them."""
	var spawned_enemies: Array = []
	
	# Spawn all enemies first
	for i in range(count):
		var enemy = battlefield.spawn_enemy(enemy_id, ring)
		if enemy:
			spawned_enemies.append(enemy)
			enemy_spawned.emit(enemy)
			print("[CombatManager] Spawned ", enemy_id, " in ring ", ring)
	
	# Create a persistent group for all enemies of the same type spawned together
	# This allows groups to persist even when enemies die
	if spawned_enemies.size() > 0:
		_enemies_spawned_together.emit(spawned_enemies, ring, enemy_id)




func _calculate_enemy_attack_damage() -> int:
	"""Calculate total damage from enemies, including Torchbearer buffs."""
	var total_damage: int = 0
	
	# Check if any Torchbearer is present for damage buff
	var buff_amount: int = _get_torchbearer_buff()
	
	# Melee enemies attack (in Melee ring)
	var melee_enemies: Array = battlefield.get_enemies_in_ring(BattlefieldStateScript.Ring.MELEE)
	for enemy in melee_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.attack_type != "suicide":  # Bombers don't attack
			var base_dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
			total_damage += base_dmg + buff_amount
	
	# Ranged enemies attack from their position if in range
	var all_enemies: Array = battlefield.get_all_enemies()
	for enemy in all_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.attack_type == "ranged":
			# Ranged enemies attack if at their target ring and player is in range
			if enemy.ring == enemy_def.target_ring and enemy_def.attack_range >= enemy.ring:
				var base_dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
				total_damage += base_dmg + buff_amount
				print("[CombatManager] Ranged attack from ", enemy_def.enemy_name, " in ring ", enemy.ring)
	
	return total_damage


func _get_torchbearer_buff() -> int:
	"""Get the damage buff from any alive Torchbearers."""
	var buff: int = 0
	var all_enemies: Array = battlefield.get_all_enemies()
	var torchbearers: Array = []
	
	for enemy in all_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.special_ability == "buff_allies":
			buff += enemy_def.buff_amount
			torchbearers.append({"enemy": enemy, "amount": enemy_def.buff_amount})
			print("[CombatManager] Torchbearer buffing allies: +", enemy_def.buff_amount, " damage")
	
	# Emit ability triggered for each torchbearer (for event banners)
	for tb: Dictionary in torchbearers:
		enemy_ability_triggered.emit(tb.enemy, "buff_allies", tb.amount)
	
	return buff


func _handle_enemy_death(enemy, hex_was_triggered: bool = false) -> void:
	"""Handle all logic when an enemy dies."""
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	
	# Trigger death effects BEFORE removing from battlefield
	_trigger_death_effect(enemy, enemy_def)
	
	# Gloom Warden passive: Heal 1 HP when hexed enemy dies
	if hex_was_triggered and _has_warden_passive("hex_lifesteal"):
		RunManager.heal(1)
		print("[CombatManager] Gloom Warden passive: Healed 1 HP from hexed enemy death")
	
	# Remove from battlefield
	battlefield.remove_enemy(enemy)
	enemy_killed.emit(enemy)
	AudioManager.play_enemy_death()
	
	# Track kills this turn for Leech Tooth
	kills_this_turn += 1
	
	# Trigger on_kill artifacts (Blood Sigil, Scavenger's Eye)
	var kill_effects: Dictionary = ArtifactManager.trigger_artifacts("on_kill", {})
	
	# Give scrap based on enemy definition + artifact bonus
	var scrap_reward: int = 2 if not enemy_def else enemy_def.scrap_value
	scrap_reward += kill_effects.bonus_scrap
	RunManager.add_scrap(scrap_reward)
	RunManager.record_enemy_kill()
	
	# Check if all enemies are dead - auto-end wave immediately
	_check_instant_wave_clear()


func _has_warden_passive(passive_id: String) -> bool:
	"""Check if the current warden has a specific passive."""
	if RunManager.current_warden == null:
		return false
	if RunManager.current_warden is Dictionary:
		return RunManager.current_warden.get("passive_id", "") == passive_id
	return false


func _check_instant_wave_clear() -> void:
	"""Check if all enemies are dead and end wave immediately if so."""
	if not battlefield:
		return
	
	# Only check during player phase (not during enemy phase which has its own check)
	if current_phase != CombatPhase.PLAYER_PHASE:
		return
	
	if battlefield.get_total_enemy_count() == 0:
		print("[CombatManager] All enemies defeated! Wave cleared instantly!")
		current_phase = CombatPhase.WAVE_CHECK
		phase_changed.emit(current_phase)
		AudioManager.play_wave_complete()
		wave_ended.emit(true)


func _trigger_death_effect(enemy, enemy_def) -> void:
	"""Trigger any special effects when an enemy dies."""
	if not enemy_def or enemy_def.special_ability.is_empty():
		return
	
	match enemy_def.special_ability:
		"explode_on_death":
			# V2 Bomber: Deals damage to player AND other enemies in same ring
			var player_damage: int = enemy_def.buff_amount
			var aoe_damage: int = enemy_def.aoe_damage if enemy_def.aoe_damage > 0 else 0
			
			# Damage to player
			RunManager.take_damage(player_damage)
			player_damaged.emit(player_damage, "bomber_explosion")
			enemy_ability_triggered.emit(enemy, "explode_on_death", player_damage)
			print("[CombatManager] BOMBER EXPLODED! Dealt ", player_damage, " to player")
			
			# V2: AoE damage to other enemies in same ring
			if aoe_damage > 0:
				var ring_enemies: Array = battlefield.get_enemies_in_ring(enemy.ring)
				var enemies_to_damage: Array = []
				for ring_enemy in ring_enemies:
					if ring_enemy.instance_id != enemy.instance_id:
						enemies_to_damage.append(ring_enemy)
				
				for target_enemy in enemies_to_damage:
					target_enemy.current_hp -= aoe_damage
					enemy_damaged.emit(target_enemy, aoe_damage, false)
					print("[CombatManager] Bomber AoE dealt ", aoe_damage, " to ", target_enemy.enemy_id)
					
					if target_enemy.current_hp <= 0:
						# Queue for death after iteration (avoid modifying array during iteration)
						call_deferred("_handle_enemy_death", target_enemy, false)


func _deal_hex_tick_damage(damage: int) -> void:
	"""Deal damage to all enemies with Hex status (Hex Amplifier artifact)."""
	if not battlefield:
		return
	
	var all_enemies: Array = battlefield.get_all_enemies()
	var enemies_to_kill: Array = []
	
	for enemy in all_enemies:
		if enemy.has_status("hex"):
			# Deal damage WITHOUT consuming hex (just tick damage)
			enemy.current_hp -= damage
			enemy_damaged.emit(enemy, damage, false)  # Not a hex trigger, just tick damage
			print("[CombatManager] Hex Amplifier dealt ", damage, " to ", enemy.enemy_id)
			
			if enemy.current_hp <= 0:
				enemies_to_kill.append(enemy)
	
	# Handle deaths after iterating
	for enemy in enemies_to_kill:
		_handle_enemy_death(enemy)


func deal_damage_to_ring(ring: int, damage: int) -> void:
	var enemies: Array = battlefield.get_enemies_in_ring(ring)
	for enemy in enemies:
		# Use take_damage to handle hex triggering
		var result: Dictionary = enemy.take_damage(damage)
		var total_damage: int = result.total_damage
		
		# Emit damage signal for visual feedback (with hex_triggered info)
		enemy_damaged.emit(enemy, total_damage, result.hex_triggered)
		
		if result.hex_triggered:
			print("[CombatManager] Hex triggered! ", damage, " + ", result.hex_bonus, " = ", total_damage)
		
		if enemy.current_hp <= 0:
			_handle_enemy_death(enemy, result.hex_triggered)
	
	damage_dealt_to_enemies.emit(damage, ring)


func deal_damage_to_random_enemy(ring_mask: int, damage: int, show_targeting: bool = true) -> void:
	var candidates: Array = []
	for ring in range(4):
		if ring_mask & (1 << ring):
			candidates.append_array(battlefield.get_enemies_in_ring(ring))
	
	if candidates.size() > 0:
		var target = candidates[randi() % candidates.size()]
		
		# Emit targeting signal BEFORE damage (for visual indicator)
		if show_targeting:
			enemy_targeted.emit(target)
			# Brief delay for targeting visual (stack expand + fast projectile)
			await get_tree().create_timer(0.3).timeout
		
		# Use take_damage to handle hex triggering
		var result: Dictionary = target.take_damage(damage)
		var total_damage: int = result.total_damage
		
		if result.hex_triggered:
			print("[CombatManager] Hex triggered on ", target.enemy_id, "! ", damage, " + ", result.hex_bonus, " = ", total_damage)
		
		print("[CombatManager] Dealt ", total_damage, " damage to ", target.enemy_id, " in ring ", target.ring, " (HP: ", target.current_hp + total_damage, " -> ", target.current_hp, ")")
		
		# Emit signal with the specific enemy instance for visual updates (with hex_triggered info)
		enemy_damaged.emit(target, total_damage, result.hex_triggered)
		
		if target.current_hp <= 0:
			print("[CombatManager] Enemy killed: ", target.enemy_id)
			_handle_enemy_death(target, result.hex_triggered)
	else:
		print("[CombatManager] No valid targets found for damage (ring_mask: ", ring_mask, ")")


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
