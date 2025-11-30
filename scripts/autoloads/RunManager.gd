extends Node
## RunManager - Current run state
## MINIMAL STUB for testing - will be expanded later

signal hp_changed(current: int, max_hp: int)
signal health_changed(current: int, max_hp: int)  # Alias for hp_changed
signal armor_changed(amount: int)
signal scrap_changed(amount: int)
signal wave_changed(wave: int)

# Constants
const MAX_WAVES: int = 12

# Run state
var current_wave: int = 1
var max_waves: int = MAX_WAVES
var danger_level: int = 1
var enemies_killed: int = 0
var essence_earned: int = 0

# Player stats
var current_hp: int = 60
var max_hp: int = 60
var armor: int = 0
var scrap: int = 0

# Energy
var base_energy: int = 3
var max_energy: int = 3

# Deck (array of {card_id: String, tier: int})
var deck: Array = []

# Current warden (set via set_warden)
var current_warden = null

# Damage multiplier
var damage_multiplier: float = 1.0

# Warden passive state
var cheat_death_available: bool = true  # Glass Warden: survive fatal hit once


func _ready() -> void:
	print("[RunManager] Initialized")


func reset_run() -> void:
	current_wave = 1
	current_hp = max_hp
	armor = 0
	scrap = 0
	deck.clear()
	damage_multiplier = 1.0
	enemies_killed = 0
	essence_earned = 0


func set_warden(warden) -> void:
	current_warden = warden
	if warden:
		max_hp = warden.max_hp
		current_hp = max_hp
		armor = warden.base_armor
		base_energy = warden.base_energy
		max_energy = base_energy
		damage_multiplier = warden.damage_multiplier


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
	
	# Check Glass Warden passive: survive fatal hit at 1 HP
	if new_hp <= 0 and cheat_death_available and _has_warden_passive("cheat_death"):
		new_hp = 1
		cheat_death_available = false
		print("[RunManager] Glass Warden passive: Cheated death! HP set to 1")
	
	current_hp = max(0, new_hp)
	hp_changed.emit(current_hp, max_hp)
	health_changed.emit(current_hp, max_hp)
	if remaining_damage > 0:
		AudioManager.play_damage_taken()


func add_armor(amount: int) -> void:
	armor += amount
	armor_changed.emit(armor)
	AudioManager.play_armor_gain()


func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)
	AudioManager.play_heal()


func add_scrap(amount: int) -> void:
	scrap += amount
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


func _has_warden_passive(passive_id: String) -> bool:
	"""Check if the current warden has a specific passive."""
	if current_warden == null:
		return false
	if current_warden is Dictionary:
		return current_warden.get("passive_id", "") == passive_id
	return false


func get_warden_tag_bonus(tag: String) -> float:
	"""Get the damage bonus for a specific card tag (e.g., 'gun' -> 0.15)."""
	if current_warden == null:
		return 0.0
	if current_warden is Dictionary:
		var bonuses: Dictionary = current_warden.get("tag_damage_bonuses", {})
		return bonuses.get(tag, 0.0)
	return 0.0


func reset_wave_state() -> void:
	"""Reset per-wave state (call at wave start)."""
	cheat_death_available = true
