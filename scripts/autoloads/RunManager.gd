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
signal xp_changed(current: int, required: int, level: int)  # XP system
signal level_up(new_level: int, hp_gained: int)  # Level up notification

# Constants (Brotato Economy: 20 waves for full economy experience)
const MAX_WAVES: int = 20

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

## Get max weapon slots (Brotato Economy)
var weapon_slots_max: int:
	get:
		return player_stats.weapon_slots_max

## Get current XP
var current_xp: int:
	get:
		return player_stats.current_xp

## Get current level
var current_level: int:
	get:
		return player_stats.current_level

# XP tracking for wave summary
var xp_gained_this_wave: int = 0
var levels_gained_this_wave: int = 0


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
	
	# XP tracking
	xp_gained_this_wave = 0
	levels_gained_this_wave = 0
	
	# Brotato Economy: Reset shop state
	ShopGenerator.reset_shop_state()
	
	stats_changed.emit()


func set_warden(warden) -> void:
	"""Set the current warden and apply their stat modifiers.
	Brotato Economy: Wardens apply MODIFIERS on top of base stats, not replace them.
	"""
	current_warden = warden
	
	# Reset to Brotato Economy defaults first (50 HP, 1 energy, 1 draw)
	player_stats.reset_to_defaults()
	cheat_death_available = true
	
	if warden and warden is WardenDefinition:
		# Brotato Economy: Apply stat modifiers from warden (additive bonuses)
		# Wardens no longer set base stats directly - they modify the defaults
		if warden.stat_modifiers.size() > 0:
			player_stats.apply_modifiers(warden.stat_modifiers)
		
		current_hp = player_stats.max_hp
		armor = warden.base_armor
		
		# Passive check: Glass Warden cheat_death
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


func heal(amount: int) -> void:
	"""Restore HP by the requested amount (scaled by heal power)."""
	if amount <= 0:
		return
	
	var scaled_amount: int = int(float(amount) * get_heal_power_multiplier())
	if scaled_amount <= 0:
		return
	
	var new_hp: int = mini(current_hp + scaled_amount, player_stats.max_hp)
	if new_hp == current_hp:
		return
	
	current_hp = new_hp
	hp_changed.emit(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
	AudioManager.play_heal()


func add_armor(amount: int) -> void:
	# V2: Apply armor gain multiplier
	var scaled_amount: int = int(float(amount) * get_armor_gain_multiplier())
	armor += scaled_amount
	armor_changed.emit(armor)
	AudioManager.play_armor_gain()


func restore_hp_to_full() -> void:
	"""Restore HP to full. Called after each successful wave."""
	if current_hp < max_hp:
		current_hp = max_hp
		hp_changed.emit(current_hp, max_hp)
		health_changed.emit(current_hp, max_hp)
		print("[RunManager] HP restored to full: %d/%d" % [current_hp, max_hp])


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


# =============================================================================
# BROTATO ECONOMY: INTEREST SYSTEM
# =============================================================================

signal interest_applied(amount: int)

func calculate_interest() -> int:
	"""Calculate interest on current scrap holdings.
	Returns 5% of scrap, capped at 25.
	"""
	var interest: int = int(floor(float(scrap) * 0.05))
	return mini(interest, 25)


func apply_interest() -> int:
	"""Apply interest to scrap and return the amount added."""
	var interest: int = calculate_interest()
	if interest > 0:
		scrap += interest
		scrap_changed.emit(scrap)
		interest_applied.emit(interest)
		print("[RunManager] Interest applied: +%d scrap (total: %d)" % [interest, scrap])
	return interest


func get_interest_preview() -> Dictionary:
	"""Get interest preview for UI display."""
	var interest: int = calculate_interest()
	return {
		"current_scrap": scrap,
		"interest": interest,
		"max_interest": 25,
		"interest_rate": 5  # 5%
	}


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
	
	# Reset XP tracking for this wave
	xp_gained_this_wave = 0
	levels_gained_this_wave = 0


# =============================================================================
# BROTATO ECONOMY: XP / LEVELING SYSTEM
# =============================================================================

func add_xp(base_amount: int) -> void:
	"""Add XP with scaling from xp_gain_percent. Checks for level up."""
	# Apply XP gain multiplier
	var scaled_xp: int = int(float(base_amount) * player_stats.get_xp_gain_multiplier())
	player_stats.current_xp += scaled_xp
	xp_gained_this_wave += scaled_xp
	
	# Check for level up(s)
	_check_level_up()
	
	# Emit XP changed signal
	xp_changed.emit(player_stats.current_xp, player_stats.get_xp_for_next_level(), player_stats.current_level)


func _check_level_up() -> void:
	"""Check if player has enough XP to level up. Can level multiple times."""
	var leveled: bool = true
	while leveled:
		var required: int = player_stats.get_xp_for_next_level()
		if player_stats.current_xp >= required:
			_perform_level_up()
		else:
			leveled = false


func _perform_level_up() -> void:
	"""Perform a level up: increase level, add max HP, heal that amount."""
	player_stats.current_level += 1
	levels_gained_this_wave += 1
	
	# Brotato-style: +1 Max HP per level, and heal that amount
	var hp_gained: int = 1
	player_stats.max_hp += hp_gained
	current_hp = mini(current_hp + hp_gained, player_stats.max_hp)
	
	print("[RunManager] LEVEL UP! Now level %d. Max HP: %d" % [player_stats.current_level, player_stats.max_hp])
	
	level_up.emit(player_stats.current_level, hp_gained)
	hp_changed.emit(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
	stats_changed.emit()


func get_xp_info() -> Dictionary:
	"""Get XP info for UI display."""
	return {
		"current_xp": player_stats.current_xp,
		"required_xp": player_stats.get_xp_for_next_level(),
		"level": player_stats.current_level,
		"progress": player_stats.get_xp_progress(),
		"xp_gain_percent": player_stats.xp_gain_percent,
		"xp_this_wave": xp_gained_this_wave,
		"levels_this_wave": levels_gained_this_wave
	}
