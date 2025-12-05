extends Node
## CombatManager - Combat turn flow orchestration
## V3: Staging system - queue cards to lane, then execute all at once

# Preload combat classes
const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")
const DeckManagerScript = preload("res://scripts/combat/DeckManager.gd")
const CardResolver = preload("res://scripts/combat/CardEffectResolver.gd")

# Core signals
signal phase_changed(new_phase: int)
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal energy_changed(current: int, max_energy: int)
signal card_played(card, tier: int)
signal enemy_spawned(enemy)
signal enemy_killed(enemy)
signal enemy_damaged(enemy, amount: int, hex_triggered: bool)
signal enemy_moved(enemy, from_ring: int, to_ring: int)
signal _enemies_spawned_together(enemies: Array, ring: int, enemy_id: String)
signal damage_dealt_to_enemies(amount: int, ring: int)
signal player_damaged(amount: int, source: String)
signal wave_ended(success: bool)

# Enemy interaction signals
signal enemy_ability_triggered(enemy, ability: String, value: int)
signal enemy_targeted(enemy)
@warning_ignore("unused_signal")
signal enemy_hexed(enemy, hex_amount: int)
@warning_ignore("unused_signal")
signal barrier_placed(ring: int, damage: int, duration: int)
signal barrier_triggered(enemy, ring: int, damage: int)
signal barrier_consumed(ring: int)  # Emitted when a barrier's uses reach 0
signal ring_phase_started(ring: int, ring_name: String)
signal ring_phase_ended(ring: int)
signal enemy_attacking(enemy, damage: int)

# V3 Staging System Signals
signal card_staged(card_def, tier: int, lane_index: int)
signal card_unstaged(lane_index: int)
signal cards_reordered()
signal execution_started()
signal execution_completed()
signal card_executing(card_def, tier: int, lane_index: int)
signal card_executed(card_def, tier: int)
signal instant_card_played(card_def, tier: int)  # For instant cards that resolve immediately
signal tag_played(tag: String)  # Emitted when a tag is played (for tag tracker)
signal lane_buff_applied(buff_type: String, buff_value: int, tag_filter: String)  # When a lane buff affects staged cards
signal staged_card_buffed(lane_index: int, buff_type: String, buff_value: int)  # When a specific staged card receives a buff

# V2 artifact signals (kept for compatibility)
@warning_ignore("unused_signal")
signal gun_fired(card_def, damage: int)
signal self_damage_dealt(amount: int)
@warning_ignore("unused_signal")
signal explosive_hit(damage: int, ring: int, splash_damage: int)
@warning_ignore("unused_signal")
signal beam_chain(damage: int, chain_index: int)
@warning_ignore("unused_signal")
signal piercing_overflow(damage: int, overflow: int)
@warning_ignore("unused_signal")
signal shock_hit(damage: int, target)
@warning_ignore("unused_signal")
signal corrosive_hit(damage: int, shred: int, target)
signal overkill(damage: int, overkill_amount: int, target)

enum CombatPhase { INACTIVE, WAVE_START, DRAW_PHASE, PLAYER_PHASE, EXECUTION_PHASE, ENEMY_PHASE, WAVE_CHECK }

# Current combat state
var current_phase: int = CombatPhase.INACTIVE
var current_turn: int = 0
var current_energy: int = 0
var max_energy: int = 3
var turn_limit: int = 5
var kills_this_turn: int = 0

# Breach Penalty System: Track enemies that reach melee and attack
var breaches_this_wave: int = 0  # Each melee attack = 1 breach
signal breach_occurred(breach_count: int, total_breaches: int)

# V3 Staging System
var staged_cards: Array[Dictionary] = []  # {card_def, tier, hand_index, lane_buffs: Dictionary}
var lane_buffs: Dictionary = {}  # Active buffs applied to staged cards: {buff_type: value}

# V3 Execution Context (tracked during execute phase)
var execution_context: Dictionary = {
	"guns_fired": 0,
	"cards_played": 0,
	"damage_dealt": 0,
	"last_damaged_enemy": null
}

# Current executing card lane index (for weapon visual targeting)
var current_executing_lane_index: int = -1

# Tag tracking for Tag Tracker UI
var tags_played_this_combat: Dictionary = {}  # tag_name -> count

# Combat objects
var battlefield = null  # BattlefieldState
var deck_manager = null  # DeckManager
var current_wave_def = null

# Spawn batch tracking
var _spawn_batch_counter: int = 0


func _ready() -> void:
	print("[CombatManager] V3 Staging System Initialized")


func initialize_combat(wave_def) -> void:
	print("[CombatManager] Initializing combat for wave")
	current_wave_def = wave_def
	current_turn = 0
	turn_limit = 5 if not wave_def else wave_def.turn_limit
	max_energy = RunManager.base_energy
	kills_this_turn = 0
	breaches_this_wave = 0  # Reset breach counter for new wave
	_spawn_batch_counter = 0
	
	# Reset staging system
	staged_cards.clear()
	lane_buffs.clear()
	_reset_execution_context()
	
	# Reset tag tracking
	tags_played_this_combat.clear()
	
	# Reset per-wave state
	RunManager.reset_wave_state()
	
	# Create real battlefield
	battlefield = BattlefieldStateScript.new()
	battlefield.barrier_consumed.connect(_on_barrier_consumed)
	
	# Create real deck manager with player's deck
	deck_manager = DeckManagerScript.new()
	deck_manager.initialize(RunManager.deck.duplicate(true))
	print("[CombatManager] Deck initialized with ", deck_manager.deck.size(), " cards")
	
	# Trigger on_wave_start artifacts
	ArtifactManager.trigger_artifacts("on_wave_start", {})
	
	# V5: Spawn turn 1 enemies from turn_spawns
	if wave_def and wave_def.turn_spawns:
		for spawn: Dictionary in wave_def.turn_spawns:
			if spawn.get("turn", 1) == 1:
				_spawn_enemies(spawn.enemy_id, spawn.count, spawn.ring)
		print("[CombatManager] Spawned turn 1 enemies from V5 turn_spawns")
	# Legacy fallback: Spawn initial enemies from initial_spawns
	elif wave_def and wave_def.initial_spawns:
		for spawn: Dictionary in wave_def.initial_spawns:
			_spawn_enemies(spawn.enemy_id, spawn.count, spawn.ring)
	
	current_phase = CombatPhase.WAVE_START
	phase_changed.emit(current_phase)
	
	# Start first turn
	start_player_turn()


func start_player_turn() -> void:
	current_turn += 1
	kills_this_turn = 0
	
	# Clear staging for new turn
	staged_cards.clear()
	lane_buffs.clear()
	_reset_execution_context()
	
	turn_started.emit(current_turn)
	AudioManager.play_turn_start()
	
	# V5: Spawn enemies for this turn (turn 2+ spawns)
	if current_turn > 1 and current_wave_def and current_wave_def.turn_spawns:
		var spawns_this_turn: Array = []
		for spawn: Dictionary in current_wave_def.turn_spawns:
			if spawn.get("turn", 1) == current_turn:
				spawns_this_turn.append(spawn)
		
		if spawns_this_turn.size() > 0:
			print("[CombatManager] Spawning enemies for turn ", current_turn)
			for spawn: Dictionary in spawns_this_turn:
				_spawn_enemies(spawn.enemy_id, spawn.count, spawn.ring)
	
	# Trigger on_turn_start artifacts
	var turn_start_effects: Dictionary = ArtifactManager.trigger_artifacts("on_turn_start", {})
	
	# Hex Amplifier: deal damage to hexed enemies
	var hex_tick: int = turn_start_effects.get("hex_tick_damage", 0)
	if hex_tick > 0:
		_deal_hex_tick_damage(hex_tick)
	
	# Refill energy
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)
	
	# Draw cards
	current_phase = CombatPhase.DRAW_PHASE
	phase_changed.emit(current_phase)
	
	var cards_to_draw: int = 5 if not RunManager.current_warden else RunManager.current_warden.hand_size
	cards_to_draw += turn_start_effects.get("draw_cards", 0)
	print("[CombatManager] Drawing ", cards_to_draw, " cards")
	for i in range(cards_to_draw):
		deck_manager.draw_card()
	
	# Enter player phase
	current_phase = CombatPhase.PLAYER_PHASE
	phase_changed.emit(current_phase)


func _reset_execution_context() -> void:
	"""Reset the execution context for a new execution."""
	execution_context = {
		"guns_fired": 0,
		"cards_played": 0,
		"damage_dealt": 0,
		"last_damaged_enemy": null
	}


# =============================================================================
# V3 STAGING SYSTEM
# =============================================================================

func can_stage_card(card_def, _tier: int) -> bool:
	"""Check if a card can be staged to the lane."""
	if current_phase != CombatPhase.PLAYER_PHASE:
		return false
	if not card_def:
		return false
	if current_energy < card_def.base_cost:
		return false
	return true


func can_play_card(card_def, tier: int) -> bool:
	"""Alias for can_stage_card for V2 compatibility."""
	return can_stage_card(card_def, tier)


func stage_card(hand_index: int, target_ring: int = -1) -> bool:
	"""Stage a card from hand to the combat lane, or play instantly if instant card. 
	For instant cards that require ring targeting, pass target_ring.
	Returns true if successful."""
	if current_phase != CombatPhase.PLAYER_PHASE:
		return false
	
	if hand_index < 0 or hand_index >= deck_manager.hand.size():
		return false
	
	var card_entry: Dictionary = deck_manager.hand[hand_index]
	var card_def = CardDatabase.get_card(card_entry.card_id)
	var tier: int = card_entry.tier
	
	if not card_def:
		return false
	
	if current_energy < card_def.base_cost:
		return false
	
	# Spend energy
	current_energy -= card_def.base_cost
	energy_changed.emit(current_energy, max_energy)
	
	# Remove from hand
	deck_manager.remove_from_hand(hand_index)
	
	# Track tags played
	_track_tags_played(card_def)
	
	# INSTANT CARDS: Execute immediately, don't go to staging lane
	if card_def.is_instant():
		var ring_str: String = " (Ring %d)" % target_ring if target_ring >= 0 else ""
		print("[CombatManager] Playing INSTANT card: ", card_def.card_name, ring_str)
		
		# If this is a buff card, apply buff to cards already in lane
		if card_def.is_lane_buff():
			_apply_lane_buff(card_def, tier)
		
		# Execute the card immediately (pass target_ring for ring-targeting cards)
		CardResolver.resolve(card_def, tier, target_ring, self)
		
		# Discard the card
		deck_manager.discard_by_id(card_entry.card_id, tier)
		
		instant_card_played.emit(card_def, tier)
		card_played.emit(card_def, tier)
		AudioManager.play_card_play()
		
		return true
	
	# COMBAT CARDS: Stage to the lane
	# Create staged card entry
	var staged_entry: Dictionary = {
		"card_def": card_def,
		"tier": tier,
		"card_id": card_entry.card_id,
		"applied_buffs": {}  # Track buffs applied to this card
	}
	
	# Apply current lane buffs to this card
	staged_entry.applied_buffs = lane_buffs.duplicate()
	
	staged_cards.append(staged_entry)
	
	var lane_index: int = staged_cards.size() - 1
	card_staged.emit(card_def, tier, lane_index)
	card_played.emit(card_def, tier)
	AudioManager.play_card_play()
	
	print("[CombatManager] Staged COMBAT card: ", card_def.card_name, " at lane index ", lane_index)
	return true


func _track_tags_played(card_def) -> void:
	"""Track tags when a card is played (for tag tracker UI)."""
	for tag: Variant in card_def.tags:
		if tag is String:
			if not tags_played_this_combat.has(tag):
				tags_played_this_combat[tag] = 0
			tags_played_this_combat[tag] += 1
			tag_played.emit(tag)


func get_tags_played() -> Dictionary:
	"""Get the dictionary of tags played this combat."""
	return tags_played_this_combat


func unstage_card(lane_index: int) -> bool:
	"""Remove a card from the staging lane and refund its cost. Returns card to hand."""
	if lane_index < 0 or lane_index >= staged_cards.size():
		return false
	
	var staged_entry: Dictionary = staged_cards[lane_index]
	var card_def = staged_entry.card_def
	
	# Refund energy
	current_energy += card_def.base_cost
	energy_changed.emit(current_energy, max_energy)
	
	# Return card to hand
	deck_manager.add_to_hand(staged_entry.card_id, staged_entry.tier)
	
	# If this was a buff card, we need to recalculate lane buffs
	if card_def.is_lane_buff():
		_recalculate_lane_buffs()
	
	staged_cards.remove_at(lane_index)
	card_unstaged.emit(lane_index)
	
	print("[CombatManager] Unstaged card: ", card_def.card_name)
	return true


func reorder_staged_cards(from_index: int, to_index: int) -> bool:
	"""Reorder cards in the staging lane."""
	if from_index < 0 or from_index >= staged_cards.size():
		return false
	if to_index < 0 or to_index >= staged_cards.size():
		return false
	if from_index == to_index:
		return false
	
	var card: Dictionary = staged_cards[from_index]
	staged_cards.remove_at(from_index)
	staged_cards.insert(to_index, card)
	
	cards_reordered.emit()
	print("[CombatManager] Reordered cards: ", from_index, " -> ", to_index)
	return true


func _apply_lane_buff(card_def, tier: int) -> void:
	"""Apply a lane buff from a buff card."""
	var buff_type: String = card_def.lane_buff_type
	var buff_value: int = card_def.get_scaled_value("lane_buff_value", tier)
	var tag_filter: String = card_def.lane_buff_tag_filter
	
	# Store the buff with its filter
	var buff_key: String = buff_type + "_" + tag_filter
	if not lane_buffs.has(buff_key):
		lane_buffs[buff_key] = {"type": buff_type, "value": 0, "tag_filter": tag_filter}
	lane_buffs[buff_key].value += buff_value
	
	print("[CombatManager] Applied lane buff: ", buff_type, " +", buff_value, " (filter: ", tag_filter, ")")
	
	# Emit general buff applied signal
	lane_buff_applied.emit(buff_type, buff_value, tag_filter)
	
	# Update buffs on already-staged cards and emit per-card signals
	for i: int in range(staged_cards.size()):
		var staged_entry: Dictionary = staged_cards[i]
		var staged_def = staged_entry.card_def
		if tag_filter.is_empty() or staged_def.has_tag(tag_filter):
			staged_entry.applied_buffs[buff_key] = lane_buffs[buff_key].duplicate()
			# Emit signal for this specific card being buffed
			staged_card_buffed.emit(i, buff_type, buff_value)


func _recalculate_lane_buffs() -> void:
	"""Recalculate all lane buffs after a buff card is removed."""
	lane_buffs.clear()
	
	# Re-apply buffs from all staged buff cards
	for staged_entry: Dictionary in staged_cards:
		var card_def = staged_entry.card_def
		if card_def.is_lane_buff():
			_apply_lane_buff(card_def, staged_entry.tier)
	
	# Update applied buffs on all staged cards
	for staged_entry: Dictionary in staged_cards:
		staged_entry.applied_buffs.clear()
		for buff_key: String in lane_buffs.keys():
			var buff_data: Dictionary = lane_buffs[buff_key]
			var card_def = staged_entry.card_def
			if buff_data.tag_filter.is_empty() or card_def.has_tag(buff_data.tag_filter):
				staged_entry.applied_buffs[buff_key] = buff_data.duplicate()


func get_staged_card_count() -> int:
	"""Get number of cards currently staged."""
	return staged_cards.size()


func get_staged_cards() -> Array[Dictionary]:
	"""Get all staged cards."""
	return staged_cards


func get_buff_for_card(card_def, buff_type: String) -> int:
	"""Get the total buff value for a card of a specific buff type."""
	var total: int = 0
	for buff_key: String in lane_buffs.keys():
		var buff_data: Dictionary = lane_buffs[buff_key]
		if buff_data.type == buff_type:
			if buff_data.tag_filter.is_empty() or card_def.has_tag(buff_data.tag_filter):
				total += buff_data.value
	return total


# =============================================================================
# EXECUTION PHASE
# =============================================================================

func execute_staged_cards() -> void:
	"""Execute all staged cards from left to right."""
	if current_phase != CombatPhase.PLAYER_PHASE:
		print("[CombatManager] Cannot execute - not in player phase")
		return
	
	if staged_cards.is_empty():
		print("[CombatManager] No cards to execute - ending turn")
		_finish_player_turn()
		return
	
	print("[CombatManager] Starting execution of ", staged_cards.size(), " staged cards")
	
	current_phase = CombatPhase.EXECUTION_PHASE
	phase_changed.emit(current_phase)
	execution_started.emit()
	
	_reset_execution_context()
	
	# Execute each card left to right - SNAPPY timing
	for i: int in range(staged_cards.size()):
		var staged_entry: Dictionary = staged_cards[i]
		var card_def = staged_entry.card_def
		var tier: int = staged_entry.tier
		
		# Track current executing lane for weapon visual targeting
		current_executing_lane_index = i
		
		card_executing.emit(card_def, tier, i)
		print("[CombatManager] Executing card ", i, ": ", card_def.card_name)
		
		# Brief pause to show card highlight (snappy!)
		await get_tree().create_timer(0.12).timeout
		
		# Execute the card with the current execution context
		# Must await because multi-hit cards use await internally
		await _execute_staged_card(staged_entry, i)
		
		# Update execution context
		execution_context.cards_played += 1
		if card_def.is_gun():
			execution_context.guns_fired += 1
		
		card_executed.emit(card_def, tier)
		
		# Reset lane index after execution
		current_executing_lane_index = -1
		
		# Short delay between card executions - snappy but readable
		await get_tree().create_timer(0.18).timeout
		
		# Check if all enemies died - can stop early
		if battlefield.get_total_enemy_count() == 0:
			print("[CombatManager] All enemies defeated during execution!")
			break
	
	# All staged cards go to discard after execution
	for staged_entry: Dictionary in staged_cards:
		deck_manager.discard_by_id(staged_entry.card_id, staged_entry.tier)
	
	staged_cards.clear()
	lane_buffs.clear()
	
	execution_completed.emit()
	
	# Wait a moment then finish turn
	await get_tree().create_timer(0.2).timeout
	_finish_player_turn()


func _execute_staged_card(staged_entry: Dictionary, lane_index: int) -> void:
	"""Execute a single staged card."""
	var card_def = staged_entry.card_def
	var tier: int = staged_entry.tier
	var applied_buffs: Dictionary = staged_entry.applied_buffs
	
	# Calculate final damage with lane buffs and scaling
	var bonus_damage: int = 0
	
	# Apply damage buffs
	for buff_key: String in applied_buffs.keys():
		var buff_data: Dictionary = applied_buffs[buff_key]
		if buff_data.type == "gun_damage" or buff_data.type == "all_damage":
			bonus_damage += buff_data.value
	
	# Apply scaling bonuses
	if card_def.scales_with_lane:
		match card_def.scaling_type:
			"guns_fired":
				bonus_damage += execution_context.guns_fired * card_def.scaling_value
			"cards_played":
				bonus_damage += execution_context.cards_played * card_def.scaling_value
			"damage_dealt":
				bonus_damage += (execution_context.damage_dealt / 10) * card_def.scaling_value
	
	# Store bonus damage in effect_params for CardResolver to use
	var modified_params: Dictionary = card_def.effect_params.duplicate()
	modified_params["lane_bonus_damage"] = bonus_damage
	modified_params["lane_index"] = lane_index
	modified_params["execution_context"] = execution_context
	
	# Temporarily set effect_params (CardResolver will use this)
	var original_params: Dictionary = card_def.effect_params
	card_def.effect_params = modified_params
	
	# Special handling for multi-hit cards - execute with visible delays between shots
	if card_def.effect_type == "v5_multi_hit" and card_def.hit_count > 1:
		await _execute_multi_hit_card(card_def, tier, lane_index)
	else:
		# Use CardResolver to execute the effect
		CardResolver.resolve(card_def, tier, -1, self)
	
	# Restore original params
	card_def.effect_params = original_params


func _execute_multi_hit_card(card_def, _tier: int, _lane_index: int) -> void:
	"""Execute a multi-hit card with visible delays between each shot.
	This allows players to see each bullet/projectile distinctly."""
	var hit_count: int = card_def.hit_count
	if hit_count <= 0:
		hit_count = 1
	
	var ring_mask: int = CardResolver._build_ring_mask(card_def.target_rings)
	var total_damage: int = 0
	var crit_count: int = 0
	
	# Handle self-damage first (only once, not per-hit)
	if card_def.self_damage > 0:
		var self_dmg: int = card_def.self_damage
		self_dmg = maxi(0, self_dmg - RunManager.player_stats.self_damage_reduction)
		if self_dmg > 0:
			RunManager.take_damage(self_dmg)
	
	# Execute each hit with a delay between them
	for i: int in range(hit_count):
		var damage_result: Dictionary = CardResolver.calculate_v5_damage(card_def, true)
		var damage: int = damage_result.damage
		var is_crit: bool = damage_result.is_crit
		
		if is_crit:
			crit_count += 1
		
		# Deal damage to closest enemy
		var enemy = battlefield.get_closest_enemy_in_rings(ring_mask)
		if enemy:
			enemy_targeted.emit(enemy)
			
			var result: Dictionary = enemy.take_damage(damage)
			var dealt_damage: int = result.total_damage
			
			enemy_damaged.emit(enemy, dealt_damage, result.hex_triggered)
			
			if enemy.current_hp <= 0:
				_handle_enemy_death(enemy, result.hex_triggered)
				RunManager.player_stats.kills_this_turn += 1
			
			damage_dealt_to_enemies.emit(dealt_damage, enemy.ring)
			total_damage += dealt_damage
		
		# Delay between shots (except after the last one)
		# 0.25s delay lets you see each bullet distinctly without being too slow
		if i < hit_count - 1:
			await get_tree().create_timer(0.25).timeout
	
	print("[CombatManager] Multi-hit: ", hit_count, " hits, ", total_damage, " total damage, ", crit_count, " crits")
	RunManager.player_stats.cards_played += 1


func _finish_player_turn() -> void:
	"""Finish the player turn and proceed to enemy phase."""
	print("[CombatManager] Finishing player turn")
	
	# Trigger on_turn_end artifacts
	var context: Dictionary = {}
	if kills_this_turn > 0:
		context["condition"] = "killed_this_turn"
	ArtifactManager.trigger_artifacts("on_turn_end", context)
	
	# Discard remaining hand
	deck_manager.discard_hand()
	
	# Check if all enemies are already defeated
	if battlefield.get_total_enemy_count() == 0:
		print("[CombatManager] All enemies defeated - skipping enemy phase")
		turn_ended.emit(current_turn)
		_check_wave_end()
		return
	
	# Process enemy phase
	_process_enemy_phase()


func end_player_turn() -> void:
	"""Called when player clicks End Turn - triggers execution."""
	if current_phase != CombatPhase.PLAYER_PHASE:
		return
	
	# Execute all staged cards (this will call _finish_player_turn when done)
	execute_staged_cards()


# =============================================================================
# ENEMY PHASE (unchanged from original)
# =============================================================================

func _process_enemy_phase() -> void:
	current_phase = CombatPhase.ENEMY_PHASE
	phase_changed.emit(current_phase)
	
	print("[CombatManager] Enemy phase - processing ring by ring")
	
	var buff_amount: int = _get_torchbearer_buff()
	
	for ring: int in range(4):
		await _process_ring_phase(ring, buff_amount)
	
	await _process_enemy_abilities_visual()
	
	if current_wave_def and current_wave_def.phase_spawns:
		ring_phase_started.emit(-1, "Reinforcements")
		await get_tree().create_timer(0.3).timeout
		for spawn: Dictionary in current_wave_def.phase_spawns:
			_spawn_enemies(spawn.enemy_id, spawn.count, spawn.ring)
		await get_tree().create_timer(0.5).timeout
		ring_phase_ended.emit(-1)
	
	turn_ended.emit(current_turn)
	_check_wave_end()


func _process_ring_phase(ring: int, buff_amount: int) -> void:
	var ring_names: Array[String] = ["Melee", "Close", "Mid", "Far"]
	var enemies_in_ring: Array = battlefield.get_enemies_in_ring(ring)
	
	if enemies_in_ring.is_empty():
		return
	
	ring_phase_started.emit(ring, ring_names[ring])
	print("[CombatManager] Processing ring: ", ring_names[ring])
	
	await get_tree().create_timer(0.3).timeout
	
	if ring == BattlefieldStateScript.Ring.MELEE:
		await _process_melee_attacks(enemies_in_ring, buff_amount)
	
	await _process_ranged_attacks_in_ring(ring, buff_amount)
	await get_tree().create_timer(0.2).timeout
	await _process_enemy_movement_from_ring(ring)
	
	ring_phase_ended.emit(ring)
	await get_tree().create_timer(0.5).timeout


func _process_melee_attacks(melee_enemies: Array, buff_amount: int) -> void:
	var total_damage: int = 0
	var total_armor_shred: int = 0
	var attacks_this_round: int = 0  # Track breaches
	
	for enemy in melee_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.attack_type != "suicide":
			var base_dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
			var final_dmg: int = base_dmg + buff_amount
			
			enemy_attacking.emit(enemy, final_dmg)
			await get_tree().create_timer(0.15).timeout
			
			total_damage += final_dmg
			attacks_this_round += 1  # Each melee attack = 1 breach
			
			if enemy_def.armor_shred > 0:
				total_armor_shred += enemy_def.armor_shred
				enemy_ability_triggered.emit(enemy, "armor_shred", enemy_def.armor_shred)
	
	# Track breaches (enemies that reached melee and attacked)
	if attacks_this_round > 0:
		breaches_this_wave += attacks_this_round
		breach_occurred.emit(attacks_this_round, breaches_this_wave)
		print("[CombatManager] Breaches: +%d (total: %d)" % [attacks_this_round, breaches_this_wave])
	
	if total_damage > 0:
		await get_tree().create_timer(0.1).timeout
		RunManager.take_damage(total_damage)
		player_damaged.emit(total_damage, "melee_enemies")
	
	if total_armor_shred > 0:
		var actual_shred: int = mini(RunManager.armor, total_armor_shred)
		if actual_shred > 0:
			RunManager.armor -= actual_shred
			RunManager.armor_changed.emit(RunManager.armor)


func _process_ranged_attacks_in_ring(ring: int, buff_amount: int) -> void:
	var enemies_in_ring: Array = battlefield.get_enemies_in_ring(ring)
	var total_ranged_damage: int = 0
	
	for enemy in enemies_in_ring:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.attack_type == "ranged":
			if enemy.ring == enemy_def.target_ring and enemy_def.attack_range >= enemy.ring:
				var base_dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
				var final_dmg: int = base_dmg + buff_amount
				
				enemy_attacking.emit(enemy, final_dmg)
				await get_tree().create_timer(0.2).timeout
				
				total_ranged_damage += final_dmg
	
	if total_ranged_damage > 0:
		await get_tree().create_timer(0.1).timeout
		RunManager.take_damage(total_ranged_damage)
		player_damaged.emit(total_ranged_damage, "ranged_enemies")


func _process_enemy_movement_from_ring(ring: int) -> void:
	var enemies_in_ring: Array = battlefield.get_enemies_in_ring(ring)
	var groups_to_move: Dictionary = {}
	var ungrouped_to_move: Array = []
	
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
					if not groups_to_move.has(enemy.group_id):
						groups_to_move[enemy.group_id] = []
					groups_to_move[enemy.group_id].append(move_data)
				else:
					ungrouped_to_move.append(move_data)
	
	for group_id: String in groups_to_move.keys():
		var group_moves: Array = groups_to_move[group_id]
		var barrier_results: Array = []
		
		for move_data: Dictionary in group_moves:
			var result: Dictionary = battlefield.move_enemy(move_data.enemy, move_data.new_ring)
			barrier_results.append({"enemy": move_data.enemy, "result": result, "move_data": move_data})
		
		var any_barrier_damage: bool = false
		for i: int in range(group_moves.size()):
			var barrier_info: Dictionary = barrier_results[i]
			var result: Dictionary = barrier_info.result
			var move_data: Dictionary = barrier_info.move_data
			if result.barrier_damage > 0:
				barrier_triggered.emit(barrier_info.enemy, move_data.old_ring, result.barrier_damage)
				any_barrier_damage = true
		
		if any_barrier_damage:
			await get_tree().create_timer(0.3).timeout
		
		for i: int in range(group_moves.size()):
			var move_data: Dictionary = group_moves[i]
			var barrier_info: Dictionary = barrier_results[i]
			var result: Dictionary = barrier_info.result
			
			if result.barrier_damage > 0:
				enemy_damaged.emit(move_data.enemy, result.barrier_damage, false)
			
			if result.killed_by_barrier:
				_handle_enemy_death(move_data.enemy, false)
			else:
				enemy_moved.emit(move_data.enemy, move_data.old_ring, move_data.new_ring)
				_check_bomber_melee_warning(move_data.enemy, move_data.new_ring)
		
		if not group_moves.is_empty():
			await get_tree().create_timer(0.15).timeout
	
	for move_data: Dictionary in ungrouped_to_move:
		var result: Dictionary = battlefield.move_enemy(move_data.enemy, move_data.new_ring)
		
		if result.barrier_damage > 0:
			barrier_triggered.emit(move_data.enemy, move_data.old_ring, result.barrier_damage)
			await get_tree().create_timer(0.3).timeout
			enemy_damaged.emit(move_data.enemy, result.barrier_damage, false)
		
		if result.killed_by_barrier:
			_handle_enemy_death(move_data.enemy, false)
		else:
			enemy_moved.emit(move_data.enemy, move_data.old_ring, move_data.new_ring)
			_check_bomber_melee_warning(move_data.enemy, move_data.new_ring)
		
		await get_tree().create_timer(0.1).timeout


func _check_bomber_melee_warning(enemy, new_ring: int) -> void:
	if new_ring != 0:
		return
	
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	if not enemy_def:
		return
	
	if enemy_def.special_ability == "explode_on_death" or enemy_def.behavior_type == EnemyDefinition.BehaviorType.BOMBER:
		var explosion_damage: int = enemy_def.buff_amount if enemy_def.buff_amount > 0 else 5
		enemy_ability_triggered.emit(enemy, "bomber_melee_warning", explosion_damage)


func _process_enemy_abilities_visual() -> void:
	var all_enemies: Array = battlefield.get_all_enemies()
	var spawners: Array = []
	
	for enemy in all_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if not enemy_def or enemy_def.special_ability.is_empty():
			continue
		
		if enemy_def.special_ability == "spawn_minions":
			spawners.append({"enemy": enemy, "def": enemy_def})
	
	if spawners.size() > 0:
		ring_phase_started.emit(-2, "Spawning")
		await get_tree().create_timer(0.3).timeout
		
		for spawner_data: Dictionary in spawners:
			var enemy = spawner_data.enemy
			var enemy_def = spawner_data.def
			
			if enemy_def.spawn_enemy_id and enemy_def.spawn_count > 0:
				var spawn_ring: int = BattlefieldStateScript.Ring.FAR
				
				enemy_ability_triggered.emit(enemy, "spawn_minions", enemy_def.spawn_count)
				await get_tree().create_timer(0.2).timeout
				
				_spawn_batch_counter += 1
				var batch_id: int = _spawn_batch_counter
				
				var spawned_minions: Array = []
				for i: int in range(enemy_def.spawn_count):
					var spawned = battlefield.spawn_enemy(enemy_def.spawn_enemy_id, spawn_ring)
					if spawned:
						spawned.spawn_batch_id = batch_id
						spawned_minions.append(spawned)
						enemy_spawned.emit(spawned)
					await get_tree().create_timer(0.15).timeout
				
				if spawned_minions.size() > 0:
					_enemies_spawned_together.emit(spawned_minions, spawn_ring, enemy_def.spawn_enemy_id)
		
		ring_phase_ended.emit(-2)
		await get_tree().create_timer(0.3).timeout


func _check_wave_end() -> void:
	current_phase = CombatPhase.WAVE_CHECK
	phase_changed.emit(current_phase)
	
	if battlefield.get_total_enemy_count() == 0:
		print("[CombatManager] Wave cleared!")
		AudioManager.play_wave_complete()
		wave_ended.emit(true)
		return
	
	if RunManager.current_hp <= 0:
		print("[CombatManager] Player defeated!")
		AudioManager.play_wave_fail()
		wave_ended.emit(false)
		return
	
	start_player_turn()


func _spawn_enemies(enemy_id: String, count: int, ring: int) -> void:
	var spawned_enemies: Array = []
	
	_spawn_batch_counter += 1
	var batch_id: int = _spawn_batch_counter
	
	for i in range(count):
		var enemy = battlefield.spawn_enemy(enemy_id, ring)
		if enemy:
			enemy.spawn_batch_id = batch_id
			spawned_enemies.append(enemy)
			enemy_spawned.emit(enemy)
	
	if spawned_enemies.size() > 0:
		_enemies_spawned_together.emit(spawned_enemies, ring, enemy_id)


func _get_torchbearer_buff() -> int:
	var buff: int = 0
	var all_enemies: Array = battlefield.get_all_enemies()
	var torchbearers: Array = []
	
	for enemy in all_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.special_ability == "buff_allies":
			buff += enemy_def.buff_amount
			torchbearers.append({"enemy": enemy, "amount": enemy_def.buff_amount})
	
	for tb: Dictionary in torchbearers:
		enemy_ability_triggered.emit(tb.enemy, "buff_allies", tb.amount)
	
	return buff


# =============================================================================
# BARRIER HANDLING
# =============================================================================

func _on_barrier_consumed(ring: int) -> void:
	"""Handle when a barrier's uses reach 0."""
	print("[CombatManager] Barrier consumed on ring ", ring)
	barrier_consumed.emit(ring)


# =============================================================================
# DAMAGE AND DEATH HANDLING
# =============================================================================

func _handle_enemy_death(enemy, hex_was_triggered: bool = false) -> void:
	var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
	
	_trigger_death_effect(enemy, enemy_def)
	
	if hex_was_triggered and _has_warden_passive("hex_lifesteal"):
		RunManager.heal(1)
	
	# Store ring before removing enemy for overkill bonus check
	var death_ring: int = enemy.ring
	
	battlefield.remove_enemy(enemy)
	enemy_killed.emit(enemy)
	AudioManager.play_enemy_death()
	
	kills_this_turn += 1
	
	var kill_effects: Dictionary = ArtifactManager.trigger_artifacts("on_kill", {})
	
	var scrap_reward: int = 2 if not enemy_def else enemy_def.scrap_value
	scrap_reward += kill_effects.bonus_scrap
	
	# OVERKILL BONUS: +1 scrap for kills in Mid (ring 2) or Far (ring 3)
	# Rewards players for killing enemies at range before they breach
	if death_ring >= 2:
		scrap_reward += 1
	
	RunManager.add_scrap(scrap_reward)
	
	var xp_reward: int = 1 if not enemy_def else enemy_def.xp_value
	RunManager.add_xp(xp_reward)
	
	RunManager.record_enemy_kill()
	
	_check_instant_wave_clear()


func _has_warden_passive(passive_id: String) -> bool:
	if RunManager.current_warden == null:
		return false
	if RunManager.current_warden is Dictionary:
		return RunManager.current_warden.get("passive_id", "") == passive_id
	return false


func _check_instant_wave_clear() -> void:
	if not battlefield:
		return
	
	if current_phase != CombatPhase.PLAYER_PHASE and current_phase != CombatPhase.EXECUTION_PHASE:
		return
	
	if battlefield.get_total_enemy_count() == 0:
		print("[CombatManager] All enemies defeated! Wave cleared instantly!")
		current_phase = CombatPhase.WAVE_CHECK
		phase_changed.emit(current_phase)
		AudioManager.play_wave_complete()
		wave_ended.emit(true)


func _trigger_death_effect(enemy, enemy_def) -> void:
	if not enemy_def or enemy_def.special_ability.is_empty():
		return
	
	match enemy_def.special_ability:
		"explode_on_death":
			var player_damage: int = enemy_def.buff_amount
			var aoe_damage: int = enemy_def.aoe_damage if enemy_def.aoe_damage > 0 else 0
			
			RunManager.take_damage(player_damage)
			player_damaged.emit(player_damage, "bomber_explosion")
			enemy_ability_triggered.emit(enemy, "explode_on_death", player_damage)
			
			if aoe_damage > 0:
				var ring_enemies: Array = battlefield.get_enemies_in_ring(enemy.ring)
				var enemies_to_damage: Array = []
				for ring_enemy in ring_enemies:
					if ring_enemy.instance_id != enemy.instance_id:
						enemies_to_damage.append(ring_enemy)
				
				for target_enemy in enemies_to_damage:
					target_enemy.current_hp -= aoe_damage
					enemy_damaged.emit(target_enemy, aoe_damage, false)
					
					if target_enemy.current_hp <= 0:
						call_deferred("_handle_enemy_death", target_enemy, false)


func _deal_hex_tick_damage(damage: int) -> void:
	if not battlefield:
		return
	
	var all_enemies: Array = battlefield.get_all_enemies()
	var enemies_to_kill: Array = []
	
	for enemy in all_enemies:
		if enemy.has_status("hex"):
			enemy.current_hp -= damage
			enemy_damaged.emit(enemy, damage, false)
			
			if enemy.current_hp <= 0:
				enemies_to_kill.append(enemy)
	
	for enemy in enemies_to_kill:
		_handle_enemy_death(enemy)


func deal_damage_to_ring(ring: int, damage: int) -> void:
	var enemies: Array = battlefield.get_enemies_in_ring(ring)
	for enemy in enemies:
		var result: Dictionary = enemy.take_damage(damage)
		var total_damage: int = result.total_damage
		
		enemy_damaged.emit(enemy, total_damage, result.hex_triggered)
		
		# Track damage in execution context
		execution_context.damage_dealt += total_damage
		execution_context.last_damaged_enemy = enemy
		
		if enemy.current_hp <= 0:
			_handle_enemy_death(enemy, result.hex_triggered)
	
	damage_dealt_to_enemies.emit(damage, ring)


func deal_damage_to_closest_enemy(ring_mask: int, damage: int, show_targeting: bool = true) -> void:
	"""Deal damage to the closest enemy in the specified rings.
	Prioritizes enemies in closer rings (Melee > Close > Mid > Far)."""
	var target = battlefield.get_closest_enemy_in_rings(ring_mask)
	
	if target:
		if show_targeting:
			enemy_targeted.emit(target)
			await get_tree().create_timer(0.4).timeout
		
		var result: Dictionary = target.take_damage(damage)
		var total_damage: int = result.total_damage
		
		# Track damage in execution context
		execution_context.damage_dealt += total_damage
		execution_context.last_damaged_enemy = target
		
		enemy_damaged.emit(target, total_damage, result.hex_triggered)
		
		if target.current_hp <= 0:
			_handle_enemy_death(target, result.hex_triggered)


func deal_damage_to_random_enemy(ring_mask: int, damage: int, show_targeting: bool = true) -> void:
	"""Deal damage to a random enemy in the specified rings (legacy - use deal_damage_to_closest_enemy)."""
	deal_damage_to_closest_enemy(ring_mask, damage, show_targeting)


func deal_damage_to_last_damaged(damage: int) -> void:
	"""Deal damage to the last damaged enemy (for reactive cards like Armored Tank)."""
	var target = execution_context.last_damaged_enemy
	if not target or not is_instance_valid(target):
		# Fall back to closest enemy
		deal_damage_to_closest_enemy(0b1111, damage, true)
		return
	
	enemy_targeted.emit(target)
	await get_tree().create_timer(0.3).timeout
	
	var result: Dictionary = target.take_damage(damage)
	var total_damage: int = result.total_damage
	
	execution_context.damage_dealt += total_damage
	
	enemy_damaged.emit(target, total_damage, result.hex_triggered)
	
	if target.current_hp <= 0:
		_handle_enemy_death(target, result.hex_triggered)


# =============================================================================
# UTILITY
# =============================================================================

func calculate_incoming_damage() -> Dictionary:
	var total: int = 0
	var breakdown: Array = []
	
	if not battlefield:
		return {"total": 0, "breakdown": []}
	
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
	var close_enemies: Array = battlefield.get_enemies_in_ring(BattlefieldStateScript.Ring.CLOSE)
	for enemy in close_enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def and enemy_def.target_ring == BattlefieldStateScript.Ring.MELEE:
			count += 1
	
	return count


func get_spawns_for_next_turn() -> Array[Dictionary]:
	"""Get all enemy spawns scheduled for the next turn.
	Returns an array of {enemy_id: String, count: int, ring: int, enemy_name: String}"""
	var result: Array[Dictionary] = []
	
	if not current_wave_def:
		return result
	
	var next_turn: int = current_turn + 1
	
	# Get spawns from turn_spawns
	for spawn: Dictionary in current_wave_def.turn_spawns:
		if spawn.get("turn", 1) == next_turn:
			var enemy_def = EnemyDatabase.get_enemy(spawn.enemy_id)
			var enemy_name: String = spawn.enemy_id.capitalize()
			if enemy_def:
				enemy_name = enemy_def.enemy_name
			
			result.append({
				"enemy_id": spawn.enemy_id,
				"count": spawn.get("count", 1),
				"ring": spawn.get("ring", 3),
				"enemy_name": enemy_name
			})
	
	return result


func get_total_spawns_remaining() -> int:
	"""Get total number of enemies still to spawn in remaining turns."""
	if not current_wave_def:
		return 0
	
	var total: int = 0
	for spawn: Dictionary in current_wave_def.turn_spawns:
		if spawn.get("turn", 1) > current_turn:
			total += spawn.get("count", 1)
	
	return total


func cleanup_combat() -> void:
	battlefield = null
	deck_manager = null
	current_wave_def = null
	staged_cards.clear()
	lane_buffs.clear()
	_reset_execution_context()
	current_phase = CombatPhase.INACTIVE


func deal_self_damage(amount: int, source: String = "card") -> void:
	RunManager.take_damage(amount)
	self_damage_dealt.emit(amount)
	
	var effects: Dictionary = ArtifactManager.trigger_artifacts("on_self_damage", {
		"damage": amount,
		"source": source
	})
	
	if effects.has("reflect_damage") and effects.reflect_damage > 0:
		deal_damage_to_closest_enemy(0b0011, effects.reflect_damage, false)


func record_overkill(damage: int, overkill_amount: int, target) -> void:
	overkill.emit(damage, overkill_amount, target)
	ArtifactManager.trigger_artifacts("on_overkill", {
		"damage": damage,
		"overkill": overkill_amount,
		"target_ring": target.ring if target else -1
	})


func get_breaches_this_wave() -> int:
	"""Get the number of breaches (melee attacks on player) this wave."""
	return breaches_this_wave


func get_breach_penalty_percent() -> float:
	"""Get the wave bonus penalty from breaches.
	Each breach reduces bonus by 5%, capped at 50% loss.
	Returns a multiplier (1.0 = no penalty, 0.5 = 50% penalty)."""
	var penalty_percent: float = float(breaches_this_wave) * 5.0
	penalty_percent = minf(penalty_percent, 50.0)  # Cap at 50% loss
	return 1.0 - (penalty_percent / 100.0)
