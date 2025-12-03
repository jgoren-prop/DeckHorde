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
# V2 DAMAGE-TYPE STATS
# =============================================================================

## Explosive damage multiplier - affects splash damage to adjacent rings (100.0 = 100%)
@export var explosive_damage_percent: float = 100.0

## Piercing damage multiplier - affects overkill overflow damage (100.0 = 100%)
@export var piercing_damage_percent: float = 100.0

## Beam damage multiplier - affects chaining damage through targets (100.0 = 100%)
@export var beam_damage_percent: float = 100.0

## Shock damage multiplier - affects slow/stun damage (100.0 = 100%)
@export var shock_damage_percent: float = 100.0

## Corrosive damage multiplier - affects armor shred damage (100.0 = 100%)
@export var corrosive_damage_percent: float = 100.0

## Deployed gun damage multiplier - affects all persistent guns on board (100.0 = 100%)
@export var deployed_gun_damage_percent: float = 100.0

## Engine damage multiplier - affects all engine card effects (100.0 = 100%)
@export var engine_damage_percent: float = 100.0

# =============================================================================
# DEFENSE & SUSTAIN STATS
# =============================================================================

## Maximum HP (Brotato Economy: start with 50, was 70)
@export var max_hp: int = 50

## Armor gained multiplier (100.0 = 100%)
@export var armor_gain_percent: float = 100.0

## Healing power multiplier (100.0 = 100%)
@export var heal_power_percent: float = 100.0

## Barrier strength/duration multiplier (100.0 = 100%)
@export var barrier_strength_percent: float = 100.0

# =============================================================================
# XP / LEVELING STATS (Brotato-style)
# =============================================================================

## Current XP accumulated this run
@export var current_xp: int = 0

## Current player level (starts at 0)
@export var current_level: int = 0

## XP gain multiplier (100.0 = 100%)
@export var xp_gain_percent: float = 100.0

# =============================================================================
# ECONOMY / TEMPO STATS
# =============================================================================

## Energy gained per turn (Brotato Economy: start with 1, was 3)
@export var energy_per_turn: int = 1

## Cards drawn per turn (Brotato Economy: start with 1, was 5)
@export var draw_per_turn: int = 1

## Maximum hand size
@export var hand_size_max: int = 7

## DEPRECATED: V2 removes weapon slot limit
## Kept for backwards compatibility but no longer used
@export var weapon_slots_max: int = 999  # Effectively unlimited

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


func get_explosive_damage_multiplier() -> float:
	return explosive_damage_percent / 100.0


func get_piercing_damage_multiplier() -> float:
	return piercing_damage_percent / 100.0


func get_beam_damage_multiplier() -> float:
	return beam_damage_percent / 100.0


func get_shock_damage_multiplier() -> float:
	return shock_damage_percent / 100.0


func get_corrosive_damage_multiplier() -> float:
	return corrosive_damage_percent / 100.0


func get_deployed_gun_damage_multiplier() -> float:
	return deployed_gun_damage_percent / 100.0


func get_engine_damage_multiplier() -> float:
	return engine_damage_percent / 100.0


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


func get_xp_gain_multiplier() -> float:
	return xp_gain_percent / 100.0


func get_xp_required_for_level(level: int) -> int:
	"""Brotato XP formula: (level + 3)²"""
	return (level + 3) * (level + 3)


func get_xp_for_next_level() -> int:
	"""Get XP required to reach the next level."""
	return get_xp_required_for_level(current_level + 1)


func get_xp_progress() -> float:
	"""Get progress to next level as 0.0-1.0"""
	var required: int = get_xp_for_next_level()
	var previous: int = 0 if current_level == 0 else get_xp_required_for_level(current_level)
	var progress_xp: int = current_xp - previous
	var level_xp: int = required - previous
	if level_xp <= 0:
		return 1.0
	return clampf(float(progress_xp) / float(level_xp), 0.0, 1.0)


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
		"explosive_damage_percent":
			explosive_damage_percent += value
		"piercing_damage_percent":
			piercing_damage_percent += value
		"beam_damage_percent":
			beam_damage_percent += value
		"shock_damage_percent":
			shock_damage_percent += value
		"corrosive_damage_percent":
			corrosive_damage_percent += value
		"deployed_gun_damage_percent":
			deployed_gun_damage_percent += value
		"engine_damage_percent":
			engine_damage_percent += value
		"weapon_slots_max":
			weapon_slots_max += int(value)
		"xp_gain_percent":
			xp_gain_percent += value
		"current_xp":
			current_xp += int(value)
		"current_level":
			current_level += int(value)
		_:
			push_warning("[PlayerStats] Unknown stat: " + stat_name)


func apply_modifiers(modifiers: Dictionary) -> void:
	"""Apply multiple modifiers from a dictionary. Format: {stat_name: value}"""
	for stat_name: String in modifiers:
		apply_modifier(stat_name, modifiers[stat_name])


func reset_to_defaults() -> void:
	"""Reset all stats to Brotato Economy defaults."""
	# XP stats
	current_xp = 0
	current_level = 0
	xp_gain_percent = 100.0
	# Offense stats
	gun_damage_percent = 100.0
	hex_damage_percent = 100.0
	barrier_damage_percent = 100.0
	generic_damage_percent = 100.0
	max_hp = 50  # Brotato Economy: was 70
	armor_gain_percent = 100.0
	heal_power_percent = 100.0
	barrier_strength_percent = 100.0
	energy_per_turn = 1  # Brotato Economy: was 3
	draw_per_turn = 1  # Brotato Economy: was 5
	hand_size_max = 7
	weapon_slots_max = 999  # V2: No weapon slot limit
	scrap_gain_percent = 100.0
	shop_price_percent = 100.0
	reroll_base_cost = 5
	damage_vs_melee_percent = 100.0
	damage_vs_close_percent = 100.0
	damage_vs_mid_percent = 100.0
	damage_vs_far_percent = 100.0
	# V2 damage-type stats
	explosive_damage_percent = 100.0
	piercing_damage_percent = 100.0
	beam_damage_percent = 100.0
	shock_damage_percent = 100.0
	corrosive_damage_percent = 100.0
	deployed_gun_damage_percent = 100.0
	engine_damage_percent = 100.0


func clone():
	"""Create a copy of this PlayerStats."""
	var copy = get_script().new()
	# XP stats
	copy.current_xp = current_xp
	copy.current_level = current_level
	copy.xp_gain_percent = xp_gain_percent
	# Offense stats
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
	copy.weapon_slots_max = weapon_slots_max
	copy.scrap_gain_percent = scrap_gain_percent
	copy.shop_price_percent = shop_price_percent
	copy.reroll_base_cost = reroll_base_cost
	copy.damage_vs_melee_percent = damage_vs_melee_percent
	copy.damage_vs_close_percent = damage_vs_close_percent
	copy.damage_vs_mid_percent = damage_vs_mid_percent
	copy.damage_vs_far_percent = damage_vs_far_percent
	# V2 damage-type stats
	copy.explosive_damage_percent = explosive_damage_percent
	copy.piercing_damage_percent = piercing_damage_percent
	copy.beam_damage_percent = beam_damage_percent
	copy.shock_damage_percent = shock_damage_percent
	copy.corrosive_damage_percent = corrosive_damage_percent
	copy.deployed_gun_damage_percent = deployed_gun_damage_percent
	copy.engine_damage_percent = engine_damage_percent
	return copy


# =============================================================================
# DEBUG / DISPLAY
# =============================================================================

func get_stat_summary() -> Dictionary:
	"""Return all stats as a dictionary for debug display."""
	return {
		"current_xp": current_xp,
		"current_level": current_level,
		"xp_gain_percent": xp_gain_percent,
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
		"weapon_slots_max": weapon_slots_max,
		"scrap_gain_percent": scrap_gain_percent,
		"shop_price_percent": shop_price_percent,
		"reroll_base_cost": reroll_base_cost,
		"damage_vs_melee_percent": damage_vs_melee_percent,
		"damage_vs_close_percent": damage_vs_close_percent,
		"damage_vs_mid_percent": damage_vs_mid_percent,
		"damage_vs_far_percent": damage_vs_far_percent,
		# V2 damage-type stats
		"explosive_damage_percent": explosive_damage_percent,
		"piercing_damage_percent": piercing_damage_percent,
		"beam_damage_percent": beam_damage_percent,
		"shock_damage_percent": shock_damage_percent,
		"corrosive_damage_percent": corrosive_damage_percent,
		"deployed_gun_damage_percent": deployed_gun_damage_percent,
		"engine_damage_percent": engine_damage_percent,
	}


