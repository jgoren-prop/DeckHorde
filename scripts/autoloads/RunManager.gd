extends Node
## RunManager - Current run state
## MINIMAL STUB for testing - will be expanded later

signal hp_changed(current: int, max_hp: int)
signal health_changed(current: int, max_hp: int)  # Alias for hp_changed
signal scrap_changed(amount: int)
signal wave_changed(wave: int)

# Constants
const MAX_WAVES: int = 12

# Run state
var current_wave: int = 1
var max_waves: int = MAX_WAVES
var danger_level: int = 1

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


func _ready() -> void:
	print("[RunManager] Initialized")


func reset_run() -> void:
	current_wave = 1
	current_hp = max_hp
	armor = 0
	scrap = 0
	deck.clear()
	damage_multiplier = 1.0


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
	var actual_damage: int = max(0, amount - armor)
	current_hp = max(0, current_hp - actual_damage)
	hp_changed.emit(current_hp, max_hp)


func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)


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
