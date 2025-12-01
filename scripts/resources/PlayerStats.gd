extends Resource
class_name PlayerStats
## PlayerStats - V2 player stat sheet for Brotato-style build scaling
## All percentage values are stored as floats where 100.0 = 100%

# =============================================================================
# OFFENSE STATS
# =============================================================================

## Gun card damage multiplier (100.0 = 100%)
@export var gun_damage_percent: float = 100.0

## Hex card damage/stacks multiplier (100.0 = 100%)
@export var hex_damage_percent: float = 100.0

## Barrier damage multiplier (100.0 = 100%)
@export var barrier_damage_percent: float = 100.0

## Fallback damage multiplier for cards without specific tags (100.0 = 100%)
@export var generic_damage_percent: float = 100.0

# =============================================================================
# DEFENSE & SUSTAIN STATS
# =============================================================================

## Maximum HP
@export var max_hp: int = 70

## Armor gained multiplier (100.0 = 100%)
@export var armor_gain_percent: float = 100.0

## Healing power multiplier (100.0 = 100%)
@export var heal_power_percent: float = 100.0

## Barrier strength/duration multiplier (100.0 = 100%)
@export var barrier_strength_percent: float = 100.0

# =============================================================================
# ECONOMY / TEMPO STATS
# =============================================================================

## Energy gained per turn
@export var energy_per_turn: int = 3

## Cards drawn per turn
@export var draw_per_turn: int = 5

## Maximum hand size
@export var hand_size_max: int = 7

## Scrap gain multiplier (100.0 = 100%)
@export var scrap_gain_percent: float = 100.0

## Shop price multiplier (100.0 = 100%, lower is cheaper)
@export var shop_price_percent: float = 100.0

## Base cost for rerolling shop
@export var reroll_base_cost: int = 5

# =============================================================================
# RING INTERACTION STATS
# =============================================================================

## Damage vs enemies in Melee ring (100.0 = 100%)
@export var damage_vs_melee_percent: float = 100.0

## Damage vs enemies in Close ring (100.0 = 100%)
@export var damage_vs_close_percent: float = 100.0

## Damage vs enemies in Mid ring (100.0 = 100%)
@export var damage_vs_mid_percent: float = 100.0

## Damage vs enemies in Far ring (100.0 = 100%)
@export var damage_vs_far_percent: float = 100.0

# =============================================================================
# MULTIPLIER GETTERS (convert percent to multiplier)
# =============================================================================

func get_gun_damage_multiplier() -> float:
	return gun_damage_percent / 100.0


func get_hex_damage_multiplier() -> float:
	return hex_damage_percent / 100.0


func get_barrier_damage_multiplier() -> float:
	return barrier_damage_percent / 100.0


func get_generic_damage_multiplier() -> float:
	return generic_damage_percent / 100.0


func get_armor_gain_multiplier() -> float:
	return armor_gain_percent / 100.0


func get_heal_power_multiplier() -> float:
	return heal_power_percent / 100.0


func get_barrier_strength_multiplier() -> float:
	return barrier_strength_percent / 100.0


func get_scrap_gain_multiplier() -> float:
	return scrap_gain_percent / 100.0


func get_shop_price_multiplier() -> float:
	return shop_price_percent / 100.0


func get_ring_damage_multiplier(ring: int) -> float:
	"""Get damage multiplier for a specific ring (0=Melee, 1=Close, 2=Mid, 3=Far)."""
	match ring:
		0:
			return damage_vs_melee_percent / 100.0
		1:
			return damage_vs_close_percent / 100.0
		2:
			return damage_vs_mid_percent / 100.0
		3:
			return damage_vs_far_percent / 100.0
		_:
			return 1.0


# =============================================================================
# STAT MODIFICATION
# =============================================================================

func apply_modifier(stat_name: String, value: float) -> void:
	"""Apply a modifier to a stat. For percentage stats, this adds to the current value."""
	match stat_name:
		"gun_damage_percent":
			gun_damage_percent += value
		"hex_damage_percent":
			hex_damage_percent += value
		"barrier_damage_percent":
			barrier_damage_percent += value
		"generic_damage_percent":
			generic_damage_percent += value
		"max_hp":
			max_hp += int(value)
		"armor_gain_percent":
			armor_gain_percent += value
		"heal_power_percent":
			heal_power_percent += value
		"barrier_strength_percent":
			barrier_strength_percent += value
		"energy_per_turn":
			energy_per_turn += int(value)
		"draw_per_turn":
			draw_per_turn += int(value)
		"hand_size_max":
			hand_size_max += int(value)
		"scrap_gain_percent":
			scrap_gain_percent += value
		"shop_price_percent":
			shop_price_percent += value
		"reroll_base_cost":
			reroll_base_cost += int(value)
		"damage_vs_melee_percent":
			damage_vs_melee_percent += value
		"damage_vs_close_percent":
			damage_vs_close_percent += value
		"damage_vs_mid_percent":
			damage_vs_mid_percent += value
		"damage_vs_far_percent":
			damage_vs_far_percent += value
		_:
			push_warning("[PlayerStats] Unknown stat: " + stat_name)


func apply_modifiers(modifiers: Dictionary) -> void:
	"""Apply multiple modifiers from a dictionary. Format: {stat_name: value}"""
	for stat_name: String in modifiers:
		apply_modifier(stat_name, modifiers[stat_name])


func reset_to_defaults() -> void:
	"""Reset all stats to default V2 baseline (Veteran Warden stats)."""
	gun_damage_percent = 100.0
	hex_damage_percent = 100.0
	barrier_damage_percent = 100.0
	generic_damage_percent = 100.0
	max_hp = 70
	armor_gain_percent = 100.0
	heal_power_percent = 100.0
	barrier_strength_percent = 100.0
	energy_per_turn = 3
	draw_per_turn = 5
	hand_size_max = 7
	scrap_gain_percent = 100.0
	shop_price_percent = 100.0
	reroll_base_cost = 5
	damage_vs_melee_percent = 100.0
	damage_vs_close_percent = 100.0
	damage_vs_mid_percent = 100.0
	damage_vs_far_percent = 100.0


func clone():
	"""Create a copy of this PlayerStats."""
	var copy = get_script().new()
	copy.gun_damage_percent = gun_damage_percent
	copy.hex_damage_percent = hex_damage_percent
	copy.barrier_damage_percent = barrier_damage_percent
	copy.generic_damage_percent = generic_damage_percent
	copy.max_hp = max_hp
	copy.armor_gain_percent = armor_gain_percent
	copy.heal_power_percent = heal_power_percent
	copy.barrier_strength_percent = barrier_strength_percent
	copy.energy_per_turn = energy_per_turn
	copy.draw_per_turn = draw_per_turn
	copy.hand_size_max = hand_size_max
	copy.scrap_gain_percent = scrap_gain_percent
	copy.shop_price_percent = shop_price_percent
	copy.reroll_base_cost = reroll_base_cost
	copy.damage_vs_melee_percent = damage_vs_melee_percent
	copy.damage_vs_close_percent = damage_vs_close_percent
	copy.damage_vs_mid_percent = damage_vs_mid_percent
	copy.damage_vs_far_percent = damage_vs_far_percent
	return copy


# =============================================================================
# DEBUG / DISPLAY
# =============================================================================

func get_stat_summary() -> Dictionary:
	"""Return all stats as a dictionary for debug display."""
	return {
		"gun_damage_percent": gun_damage_percent,
		"hex_damage_percent": hex_damage_percent,
		"barrier_damage_percent": barrier_damage_percent,
		"generic_damage_percent": generic_damage_percent,
		"max_hp": max_hp,
		"armor_gain_percent": armor_gain_percent,
		"heal_power_percent": heal_power_percent,
		"barrier_strength_percent": barrier_strength_percent,
		"energy_per_turn": energy_per_turn,
		"draw_per_turn": draw_per_turn,
		"hand_size_max": hand_size_max,
		"scrap_gain_percent": scrap_gain_percent,
		"shop_price_percent": shop_price_percent,
		"reroll_base_cost": reroll_base_cost,
		"damage_vs_melee_percent": damage_vs_melee_percent,
		"damage_vs_close_percent": damage_vs_close_percent,
		"damage_vs_mid_percent": damage_vs_mid_percent,
		"damage_vs_far_percent": damage_vs_far_percent,
	}


