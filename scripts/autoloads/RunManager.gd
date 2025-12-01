extends Node
## RunManager - Current run state
## V2: Now uses PlayerStats for Brotato-style stat scaling

# V2: Preload dependencies to ensure they're available at autoload time
const PlayerStatsClass = preload("res://scripts/resources/PlayerStats.gd")
const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")

signal hp_changed(current: int, max_hp: int)
signal health_changed(current: int, max_hp: int)  # Alias for hp_changed
signal armor_changed(amount: int)
signal scrap_changed(amount: int)
signal wave_changed(wave: int)
signal stats_changed()  # V2: Emitted when player stats change

# Constants
const MAX_WAVES: int = 12

# Run state
var current_wave: int = 1
var max_waves: int = MAX_WAVES
var danger_level: int = 1
var enemies_killed: int = 0
var essence_earned: int = 0

# V2: Player stats resource (replaces individual stat vars)
var player_stats = PlayerStatsClass.new()

# Player state (runtime values, not base stats)
var current_hp: int = 70
var armor: int = 0
var scrap: int = 0

# Deck (array of {card_id: String, tier: int})
var deck: Array = []

# Current warden (set via set_warden)
var current_warden = null

# V2 Warden passive state (will be replaced by proper V2 passive system in Phase 7+)
# For now, keeping cheat_death for Glass Warden compatibility
var cheat_death_available: bool = true

# =============================================================================
# V2 STAT ACCESSORS (delegate to PlayerStats)
# =============================================================================

## Get max HP from player stats
var max_hp: int:
	get:
		return player_stats.max_hp
	set(value):
		player_stats.max_hp = value

## Get base energy per turn from player stats
var base_energy: int:
	get:
		return player_stats.energy_per_turn
	set(value):
		player_stats.energy_per_turn = value

## Get max energy (same as base for now, no carryover)
var max_energy: int:
	get:
		return player_stats.energy_per_turn
	set(value):
		player_stats.energy_per_turn = value

## Get cards drawn per turn
var draw_per_turn: int:
	get:
		return player_stats.draw_per_turn

## Get max hand size
var hand_size_max: int:
	get:
		return player_stats.hand_size_max


func _ready() -> void:
	print("[RunManager] V2 Initialized with PlayerStats")


func reset_run() -> void:
	current_wave = 1
	player_stats.reset_to_defaults()
	current_hp = player_stats.max_hp
	armor = 0
	scrap = 0
	deck.clear()
	enemies_killed = 0
	essence_earned = 0
	cheat_death_available = true
	stats_changed.emit()


func set_warden(warden) -> void:
	"""Set the current warden and apply their stat modifiers.
	V2: Wardens must be WardenDefinition resources with stat_modifiers.
	"""
	current_warden = warden
	
	# Reset to defaults first
	player_stats.reset_to_defaults()
	cheat_death_available = true
	
	if warden and warden is WardenDefinition:
		# Apply warden's base stats
		player_stats.max_hp = warden.max_hp
		player_stats.energy_per_turn = warden.base_energy
		if warden.hand_size > 0:
			player_stats.draw_per_turn = warden.hand_size
		
		# V2: Apply stat modifiers from warden (additive bonuses)
		if warden.stat_modifiers.size() > 0:
			player_stats.apply_modifiers(warden.stat_modifiers)
		
		current_hp = player_stats.max_hp
		armor = warden.base_armor
		
		# V2 Passive check: Glass Warden cheat_death (temporary until V2 passive system)
		if warden.passive_id == "cheat_death":
			cheat_death_available = true
	
	stats_changed.emit()


# =============================================================================
# V2 STAT MULTIPLIER GETTERS
# =============================================================================

func get_gun_damage_multiplier() -> float:
	"""Get gun damage multiplier from player stats."""
	return player_stats.get_gun_damage_multiplier()


func get_hex_damage_multiplier() -> float:
	"""Get hex damage multiplier from player stats."""
	return player_stats.get_hex_damage_multiplier()


func get_barrier_damage_multiplier() -> float:
	"""Get barrier damage multiplier from player stats."""
	return player_stats.get_barrier_damage_multiplier()


func get_generic_damage_multiplier() -> float:
	"""Get generic damage multiplier from player stats."""
	return player_stats.get_generic_damage_multiplier()


func get_armor_gain_multiplier() -> float:
	"""Get armor gain multiplier from player stats."""
	return player_stats.get_armor_gain_multiplier()


func get_heal_power_multiplier() -> float:
	"""Get heal power multiplier from player stats."""
	return player_stats.get_heal_power_multiplier()


func get_barrier_strength_multiplier() -> float:
	"""Get barrier strength multiplier from player stats."""
	return player_stats.get_barrier_strength_multiplier()


func get_scrap_gain_multiplier() -> float:
	"""Get scrap gain multiplier from player stats."""
	return player_stats.get_scrap_gain_multiplier()


func get_ring_damage_multiplier(ring: int) -> float:
	"""Get damage multiplier for a specific ring."""
	return player_stats.get_ring_damage_multiplier(ring)


func get_damage_multiplier_for_card(card_def, target_ring: int = -1) -> float:
	"""Get the total damage multiplier for a card based on its tags and target ring.
	
	Uses ADDITIVE stacking:
	- Base = 100%
	- Gun at 120% adds +20%
	- Ring at 115% adds +15%
	- Total = 100% + 20% + 15% = 135% = 1.35x
	"""
	# Start with base 100%
	var total_percent: float = 100.0
	
	# Add type-specific bonus (stat - 100 = bonus percentage)
	if card_def.has_tag(TagConstantsClass.TAG_GUN):
		total_percent += player_stats.gun_damage_percent - 100.0
	elif card_def.has_tag(TagConstantsClass.TAG_HEX):
		total_percent += player_stats.hex_damage_percent - 100.0
	elif card_def.has_tag(TagConstantsClass.TAG_BARRIER):
		total_percent += player_stats.barrier_damage_percent - 100.0
	else:
		total_percent += player_stats.generic_damage_percent - 100.0
	
	# Add ring-specific bonus if we know the target
	if target_ring >= 0 and target_ring <= 3:
		var ring_percent: float = 100.0
		match target_ring:
			0:
				ring_percent = player_stats.damage_vs_melee_percent
			1:
				ring_percent = player_stats.damage_vs_close_percent
			2:
				ring_percent = player_stats.damage_vs_mid_percent
			3:
				ring_percent = player_stats.damage_vs_far_percent
		total_percent += ring_percent - 100.0
	
	# Convert to multiplier (135% -> 1.35)
	return total_percent / 100.0


func take_damage(amount: int) -> void:
	# Armor absorbs damage first
	var damage_to_armor: int = mini(armor, amount)
	var old_armor: int = armor
	armor -= damage_to_armor
	var remaining_damage: int = amount - damage_to_armor
	
	# Emit armor changed if armor was consumed
	if old_armor != armor:
		armor_changed.emit(armor)
	
	# Remaining damage hits HP
	var new_hp: int = current_hp - remaining_damage
	
	# V2: Glass Warden passive - survive fatal hit at 1 HP
	# (Will be replaced by proper V2 passive system in Phase 7+)
	if new_hp <= 0 and cheat_death_available and _has_cheat_death_passive():
		new_hp = 1
		cheat_death_available = false
		print("[RunManager] Glass Warden passive: Cheated death! HP set to 1")
	
	current_hp = max(0, new_hp)
	hp_changed.emit(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
	if remaining_damage > 0:
		AudioManager.play_damage_taken()


func add_armor(amount: int) -> void:
	# V2: Apply armor gain multiplier
	var scaled_amount: int = int(float(amount) * get_armor_gain_multiplier())
	armor += scaled_amount
	armor_changed.emit(armor)
	AudioManager.play_armor_gain()


func heal(amount: int) -> void:
	# V2: Apply heal power multiplier
	var scaled_amount: int = int(float(amount) * get_heal_power_multiplier())
	current_hp = min(max_hp, current_hp + scaled_amount)
	hp_changed.emit(current_hp, max_hp)
	AudioManager.play_heal()


func add_scrap(amount: int) -> void:
	# V2: Apply scrap gain multiplier
	var scaled_amount: int = int(float(amount) * get_scrap_gain_multiplier())
	scrap += scaled_amount
	scrap_changed.emit(scrap)


func spend_scrap(amount: int) -> bool:
	if scrap >= amount:
		scrap -= amount
		scrap_changed.emit(scrap)
		return true
	return false


func advance_wave() -> void:
	current_wave += 1
	wave_changed.emit(current_wave)


func is_run_over() -> bool:
	return current_hp <= 0 or current_wave > max_waves


func start_wave() -> void:
	print("[RunManager] Starting wave ", current_wave)


func is_elite_wave() -> bool:
	return current_wave in [4, 8]


func is_boss_wave() -> bool:
	return current_wave == MAX_WAVES


func record_enemy_kill() -> void:
	enemies_killed += 1
	# Calculate essence based on kills and waves
	essence_earned = enemies_killed * 2 + current_wave * 5


func add_card_to_deck(card_id: String, tier: int) -> void:
	deck.append({"card_id": card_id, "tier": tier})
	print("[RunManager] Added card to deck: ", card_id)


func remove_card_from_deck(index: int) -> void:
	if index >= 0 and index < deck.size():
		var removed: Dictionary = deck[index]
		deck.remove_at(index)
		print("[RunManager] Removed card from deck: ", removed.card_id)


func _has_cheat_death_passive() -> bool:
	"""V2: Check if current warden has cheat_death passive.
	Temporary implementation until V2 passive system in Phase 7+.
	"""
	if current_warden == null:
		return false
	if current_warden is WardenDefinition:
		return current_warden.passive_id == "cheat_death"
	return false


func reset_wave_state() -> void:
	"""Reset per-wave state (call at wave start)."""
	# Reset cheat_death if warden has the passive
	if _has_cheat_death_passive():
		cheat_death_available = true
