extends Resource
class_name PlayerStats
## PlayerStats - V5 player stat sheet for Brotato-style build scaling
## Based on DESIGN_V5.md damage system with 3 damage types and 8 weapon categories
## All percentage values are stored as floats where 100.0 = 100%

# =============================================================================
# V5 FLAT DAMAGE STATS (For Weapon Scaling)
# =============================================================================

## Flat Kinetic damage added to weapons that scale with Kinetic
@export var kinetic: int = 0

## Flat Thermal damage added to weapons that scale with Thermal
@export var thermal: int = 0

## Flat Arcane damage added to weapons that scale with Arcane
@export var arcane: int = 0

# =============================================================================
# V5 PERCENTAGE MULTIPLIERS (Applied to Final Damage)
# =============================================================================

## Multiplier on Kinetic-type damage (100.0 = 100%)
@export var kinetic_percent: float = 100.0

## Multiplier on Thermal-type damage (100.0 = 100%)
@export var thermal_percent: float = 100.0

## Multiplier on Arcane-type damage (100.0 = 100%)
@export var arcane_percent: float = 100.0

## Multiplier on ALL damage (100.0 = 100%)
@export var damage_percent: float = 100.0

## Multiplier on AOE attacks (100.0 = 100%)
@export var aoe_percent: float = 100.0

# =============================================================================
# V5 TARGETING DAMAGE MULTIPLIERS (vs Enemy Type / Ring)
# =============================================================================

## Multiplier vs Melee enemies (100.0 = 100%)
@export var damage_vs_melee_percent: float = 100.0

## Multiplier vs enemies in Close ring (100.0 = 100%)
@export var damage_vs_close_percent: float = 100.0

## Multiplier vs enemies in Mid ring (100.0 = 100%)
@export var damage_vs_mid_percent: float = 100.0

## Multiplier vs enemies in Far ring (100.0 = 100%)
@export var damage_vs_far_percent: float = 100.0

# =============================================================================
# V5 CRIT STATS
# =============================================================================

## Chance to crit (5.0 = 5%)
@export var crit_chance: float = 5.0

## Damage multiplier on crit (150.0 = 150%)
@export var crit_damage: float = 150.0

# =============================================================================
# V5 STATUS EFFECT STATS
# =============================================================================

## Bonus damage from Hex stacks (0.0 = +0%)
@export var hex_potency: float = 0.0

## Bonus damage from Burn ticks (0.0 = +0%)
@export var burn_potency: float = 0.0

## Heal for X% of damage dealt (0.0 = 0%)
@export var lifesteal_percent: float = 0.0

# =============================================================================
# V5 BARRIER STATS
# =============================================================================

## Flat damage added to barrier hits
@export var barrier_damage_bonus: int = 0

## Extra uses for barriers you place
@export var barrier_uses_bonus: int = 0

# =============================================================================
# V5 DEFENSE STATS
# =============================================================================

## Maximum health
@export var max_hp: int = 50

## Current armor (blocks damage)
@export var armor: int = 0

## Armor gained at wave start
@export var armor_start: int = 0

## Reduce self-damage by X
@export var self_damage_reduction: int = 0

# =============================================================================
# V5 ECONOMY / TEMPO STATS
# =============================================================================

## Cards drawn at turn start
@export var draw_per_turn: int = 5

## Energy per turn
@export var energy_per_turn: int = 3

## Maximum hand size
@export var hand_size: int = 7

## Scrap gain multiplier (100.0 = 100%)
@export var scrap_gain_percent: float = 100.0

## Shop price multiplier (100.0 = 100%, lower is cheaper)
@export var shop_price_percent: float = 100.0

## Base cost for rerolling shop
@export var reroll_base_cost: int = 2

# =============================================================================
# V5 SPECIAL STATS (For Scaling - Updated at Runtime)
# =============================================================================

## Cards played this turn (resets each turn)
@export var cards_played: int = 0

## Number of active barriers
@export var barriers: int = 0

## Missing HP (Max HP - Current HP, calculated)
@export var missing_hp: int = 0

## Enemies killed this turn (resets each turn)
@export var kills_this_turn: int = 0

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
# LEGACY COMPATIBILITY (will be removed after full V5 migration)
# =============================================================================

## DEPRECATED: V5 replaces with kinetic_percent/thermal_percent/arcane_percent
@export var gun_damage_percent: float = 100.0
@export var hex_damage_percent: float = 100.0
@export var barrier_damage_percent: float = 100.0
@export var generic_damage_percent: float = 100.0
@export var armor_gain_percent: float = 100.0
@export var heal_power_percent: float = 100.0
@export var barrier_strength_percent: float = 100.0
@export var hand_size_max: int = 7


# =============================================================================
# V5 MULTIPLIER GETTERS
# =============================================================================

func get_kinetic_multiplier() -> float:
	return kinetic_percent / 100.0


func get_thermal_multiplier() -> float:
	return thermal_percent / 100.0


func get_arcane_multiplier() -> float:
	return arcane_percent / 100.0


func get_damage_multiplier() -> float:
	return damage_percent / 100.0


func get_aoe_multiplier() -> float:
	return aoe_percent / 100.0


func get_damage_vs_melee_multiplier() -> float:
	return damage_vs_melee_percent / 100.0


func get_damage_vs_close_multiplier() -> float:
	return damage_vs_close_percent / 100.0


func get_damage_vs_mid_multiplier() -> float:
	return damage_vs_mid_percent / 100.0


func get_damage_vs_far_multiplier() -> float:
	return damage_vs_far_percent / 100.0


func get_crit_chance() -> float:
	"""Get crit chance as a 0.0-1.0 value."""
	return crit_chance / 100.0


func get_crit_multiplier() -> float:
	"""Get crit damage as a multiplier."""
	return crit_damage / 100.0


func get_hex_potency_multiplier() -> float:
	"""Get hex potency bonus as a multiplier (1.0 + potency%)."""
	return 1.0 + (hex_potency / 100.0)


func get_burn_potency_multiplier() -> float:
	"""Get burn potency bonus as a multiplier (1.0 + potency%)."""
	return 1.0 + (burn_potency / 100.0)


func get_lifesteal_percent() -> float:
	"""Get lifesteal as a 0.0-1.0 value."""
	return lifesteal_percent / 100.0


func get_type_multiplier(damage_type: String) -> float:
	"""Get the type-specific damage multiplier."""
	match damage_type:
		"kinetic":
			return get_kinetic_multiplier()
		"thermal":
			return get_thermal_multiplier()
		"arcane":
			return get_arcane_multiplier()
		_:
			return 1.0


func get_flat_damage_stat(stat_name: String) -> int:
	"""Get a flat damage stat by name."""
	match stat_name:
		"kinetic":
			return kinetic
		"thermal":
			return thermal
		"arcane":
			return arcane
		"armor_start":
			return armor_start
		"crit_damage":
			return int(crit_damage)
		"missing_hp":
			return missing_hp
		"cards_played":
			return cards_played
		"barriers":
			return barriers
		"kills_this_turn":
			return kills_this_turn
		_:
			return 0


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


# =============================================================================
# LEGACY GETTERS (for backward compatibility during migration)
# =============================================================================

func get_gun_damage_multiplier() -> float:
	# Map to kinetic for V5
	return get_kinetic_multiplier()


func get_hex_damage_multiplier() -> float:
	# Map to arcane for V5
	return get_arcane_multiplier()


func get_barrier_damage_multiplier() -> float:
	return barrier_damage_percent / 100.0


func get_generic_damage_multiplier() -> float:
	return get_damage_multiplier()


func get_armor_gain_multiplier() -> float:
	return armor_gain_percent / 100.0


func get_heal_power_multiplier() -> float:
	return heal_power_percent / 100.0


func get_barrier_strength_multiplier() -> float:
	return barrier_strength_percent / 100.0


# =============================================================================
# V5 STAT MODIFICATION
# =============================================================================

func apply_modifier(stat_name: String, value: float) -> void:
	"""Apply a modifier to a stat. For percentage stats, this adds to the current value."""
	match stat_name:
		# V5 Flat damage stats
		"kinetic":
			kinetic += int(value)
		"thermal":
			thermal += int(value)
		"arcane":
			arcane += int(value)
		# V5 Percentage multipliers
		"kinetic_percent":
			kinetic_percent += value
		"thermal_percent":
			thermal_percent += value
		"arcane_percent":
			arcane_percent += value
		"damage_percent":
			damage_percent += value
		"aoe_percent":
			aoe_percent += value
		# V5 Targeting damage multipliers
		"damage_vs_melee_percent":
			damage_vs_melee_percent += value
		"damage_vs_close_percent":
			damage_vs_close_percent += value
		"damage_vs_mid_percent":
			damage_vs_mid_percent += value
		"damage_vs_far_percent":
			damage_vs_far_percent += value
		# V5 Crit stats
		"crit_chance":
			crit_chance += value
		"crit_damage":
			crit_damage += value
		# V5 Status stats
		"hex_potency":
			hex_potency += value
		"burn_potency":
			burn_potency += value
		"lifesteal_percent":
			lifesteal_percent += value
		# V5 Barrier stats
		"barrier_damage_bonus":
			barrier_damage_bonus += int(value)
		"barrier_uses_bonus":
			barrier_uses_bonus += int(value)
		# V5 Defense stats
		"max_hp":
			max_hp += int(value)
		"armor":
			armor += int(value)
		"armor_start":
			armor_start += int(value)
		"self_damage_reduction":
			self_damage_reduction += int(value)
		# V5 Economy stats
		"draw_per_turn":
			draw_per_turn += int(value)
		"energy_per_turn":
			energy_per_turn += int(value)
		"hand_size":
			hand_size += int(value)
		"scrap_gain_percent":
			scrap_gain_percent += value
		"shop_price_percent":
			shop_price_percent += value
		"reroll_base_cost":
			reroll_base_cost += int(value)
		# XP stats
		"xp_gain_percent":
			xp_gain_percent += value
		"current_xp":
			current_xp += int(value)
		"current_level":
			current_level += int(value)
		# Legacy compatibility
		"gun_damage_percent":
			gun_damage_percent += value
			kinetic_percent += value  # Also apply to V5 stat
		"hex_damage_percent":
			hex_damage_percent += value
			arcane_percent += value  # Also apply to V5 stat
		"barrier_damage_percent":
			barrier_damage_percent += value
		"generic_damage_percent":
			generic_damage_percent += value
			damage_percent += value  # Also apply to V5 stat
		"armor_gain_percent":
			armor_gain_percent += value
		"heal_power_percent":
			heal_power_percent += value
		"barrier_strength_percent":
			barrier_strength_percent += value
		"hand_size_max":
			hand_size_max += int(value)
			hand_size += int(value)  # Also apply to V5 stat
		_:
			push_warning("[PlayerStats] Unknown stat: " + stat_name)


func apply_modifiers(modifiers: Dictionary) -> void:
	"""Apply multiple modifiers from a dictionary. Format: {stat_name: value}"""
	for stat_name: String in modifiers:
		apply_modifier(stat_name, modifiers[stat_name])


func reset_to_defaults() -> void:
	"""Reset all stats to V5 defaults."""
	# V5 Flat damage stats
	kinetic = 0
	thermal = 0
	arcane = 0
	# V5 Percentage multipliers
	kinetic_percent = 100.0
	thermal_percent = 100.0
	arcane_percent = 100.0
	damage_percent = 100.0
	aoe_percent = 100.0
	# V5 Targeting damage multipliers
	damage_vs_melee_percent = 100.0
	damage_vs_close_percent = 100.0
	damage_vs_mid_percent = 100.0
	damage_vs_far_percent = 100.0
	# V5 Crit stats
	crit_chance = 5.0
	crit_damage = 150.0
	# V5 Status stats
	hex_potency = 0.0
	burn_potency = 0.0
	lifesteal_percent = 0.0
	# V5 Barrier stats
	barrier_damage_bonus = 0
	barrier_uses_bonus = 0
	# V5 Defense stats
	max_hp = 50
	armor = 0
	armor_start = 0
	self_damage_reduction = 0
	# V5 Economy stats
	draw_per_turn = 5
	energy_per_turn = 3
	hand_size = 7
	scrap_gain_percent = 100.0
	shop_price_percent = 100.0
	reroll_base_cost = 2
	# V5 Special stats
	cards_played = 0
	barriers = 0
	missing_hp = 0
	kills_this_turn = 0
	# XP stats
	current_xp = 0
	current_level = 0
	xp_gain_percent = 100.0
	# Legacy stats
	gun_damage_percent = 100.0
	hex_damage_percent = 100.0
	barrier_damage_percent = 100.0
	generic_damage_percent = 100.0
	armor_gain_percent = 100.0
	heal_power_percent = 100.0
	barrier_strength_percent = 100.0
	hand_size_max = 7


func reset_turn_stats() -> void:
	"""Reset stats that reset each turn."""
	cards_played = 0
	kills_this_turn = 0


func update_missing_hp(current_hp: int) -> void:
	"""Update missing_hp based on current HP."""
	missing_hp = maxi(0, max_hp - current_hp)


func clone():
	"""Create a copy of this PlayerStats."""
	var copy = get_script().new()
	# V5 Flat damage stats
	copy.kinetic = kinetic
	copy.thermal = thermal
	copy.arcane = arcane
	# V5 Percentage multipliers
	copy.kinetic_percent = kinetic_percent
	copy.thermal_percent = thermal_percent
	copy.arcane_percent = arcane_percent
	copy.damage_percent = damage_percent
	copy.aoe_percent = aoe_percent
	# V5 Targeting damage multipliers
	copy.damage_vs_melee_percent = damage_vs_melee_percent
	copy.damage_vs_close_percent = damage_vs_close_percent
	copy.damage_vs_mid_percent = damage_vs_mid_percent
	copy.damage_vs_far_percent = damage_vs_far_percent
	# V5 Crit stats
	copy.crit_chance = crit_chance
	copy.crit_damage = crit_damage
	# V5 Status stats
	copy.hex_potency = hex_potency
	copy.burn_potency = burn_potency
	copy.lifesteal_percent = lifesteal_percent
	# V5 Barrier stats
	copy.barrier_damage_bonus = barrier_damage_bonus
	copy.barrier_uses_bonus = barrier_uses_bonus
	# V5 Defense stats
	copy.max_hp = max_hp
	copy.armor = armor
	copy.armor_start = armor_start
	copy.self_damage_reduction = self_damage_reduction
	# V5 Economy stats
	copy.draw_per_turn = draw_per_turn
	copy.energy_per_turn = energy_per_turn
	copy.hand_size = hand_size
	copy.scrap_gain_percent = scrap_gain_percent
	copy.shop_price_percent = shop_price_percent
	copy.reroll_base_cost = reroll_base_cost
	# V5 Special stats
	copy.cards_played = cards_played
	copy.barriers = barriers
	copy.missing_hp = missing_hp
	copy.kills_this_turn = kills_this_turn
	# XP stats
	copy.current_xp = current_xp
	copy.current_level = current_level
	copy.xp_gain_percent = xp_gain_percent
	# Legacy stats
	copy.gun_damage_percent = gun_damage_percent
	copy.hex_damage_percent = hex_damage_percent
	copy.barrier_damage_percent = barrier_damage_percent
	copy.generic_damage_percent = generic_damage_percent
	copy.armor_gain_percent = armor_gain_percent
	copy.heal_power_percent = heal_power_percent
	copy.barrier_strength_percent = barrier_strength_percent
	copy.hand_size_max = hand_size_max
	return copy


# =============================================================================
# DEBUG / DISPLAY
# =============================================================================

func get_stat_summary() -> Dictionary:
	"""Return all V5 stats as a dictionary for debug display."""
	return {
		# V5 Flat damage
		"kinetic": kinetic,
		"thermal": thermal,
		"arcane": arcane,
		# V5 Percentages
		"kinetic_percent": kinetic_percent,
		"thermal_percent": thermal_percent,
		"arcane_percent": arcane_percent,
		"damage_percent": damage_percent,
		"aoe_percent": aoe_percent,
		# V5 Targeting damage multipliers
		"damage_vs_melee_percent": damage_vs_melee_percent,
		"damage_vs_close_percent": damage_vs_close_percent,
		"damage_vs_mid_percent": damage_vs_mid_percent,
		"damage_vs_far_percent": damage_vs_far_percent,
		# V5 Crit
		"crit_chance": crit_chance,
		"crit_damage": crit_damage,
		# V5 Status
		"hex_potency": hex_potency,
		"burn_potency": burn_potency,
		"lifesteal_percent": lifesteal_percent,
		# V5 Barrier
		"barrier_damage_bonus": barrier_damage_bonus,
		"barrier_uses_bonus": barrier_uses_bonus,
		# V5 Defense
		"max_hp": max_hp,
		"armor": armor,
		"armor_start": armor_start,
		"self_damage_reduction": self_damage_reduction,
		# V5 Economy
		"draw_per_turn": draw_per_turn,
		"energy_per_turn": energy_per_turn,
		"hand_size": hand_size,
		"scrap_gain_percent": scrap_gain_percent,
		"shop_price_percent": shop_price_percent,
		# V5 Special
		"cards_played": cards_played,
		"barriers": barriers,
		"missing_hp": missing_hp,
		"kills_this_turn": kills_this_turn,
		# XP
		"current_xp": current_xp,
		"current_level": current_level,
		"xp_gain_percent": xp_gain_percent,
	}
