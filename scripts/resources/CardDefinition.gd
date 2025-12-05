extends Resource
class_name CardDefinition
## CardDefinition - Data resource for card definitions
## V5: New damage system with 3 types, 8 categories, and stat-based scaling

# V5: Preload TagConstants to ensure it's available
const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")

@export var card_id: String = ""
@export var card_name: String = ""
@export_multiline var description: String = ""
@export_multiline var instant_description: String = ""  # Labeled instant effect description
@export_multiline var persistent_description: String = ""  # Labeled persistent effect description

# =============================================================================
# V5 CARD CLASSIFICATION
# =============================================================================

## V5: Damage type determines which % multipliers apply
@export_enum("kinetic", "thermal", "arcane", "none") var damage_type: String = "kinetic"

## V5: Categories (1-2) determine family buff eligibility and scaling
@export var categories: Array[String] = []

## V5: Card tier (1-4) for merging and scaling
@export var tier: int = 1

## V5: Is this an instant (non-weapon) card? Instants cannot be merged
@export var is_instant_card: bool = false

## Rarity: 1=common, 2=uncommon, 3=rare, 4=legendary
@export var rarity: int = 1

# Legacy card classification (kept for compatibility)
@export_enum("weapon", "skill", "hex", "defense", "buff") var card_type: String = "weapon"
@export_enum("combat", "instant") var play_mode: String = "combat"  # combat = goes to staging lane, instant = resolves immediately
@export var tags: Array = []  # Array[String] - Legacy tags

# Cost
@export var base_cost: int = 1

# Effect type determines how the card is resolved
@export_enum("instant_damage", "heal", "buff", "apply_hex", "apply_hex_multi", "gain_armor", "ring_barrier", "damage_and_heal", "damage_and_armor", "armor_and_lifesteal", "draw_cards", "push_enemies", "lane_buff", "scaling_damage", "apply_burn", "apply_burn_multi", "v5_damage", "v5_multi_hit", "v5_aoe", "v5_ring_damage", "splash_damage", "last_damaged", "explosive_damage", "beam_damage", "piercing_damage", "shock_damage", "corrosive_damage", "energy_refund", "hex_transfer", "armor_and_heal", "damage_and_draw", "scatter_damage", "energy_and_draw", "gambit", "damage_and_hex", "shield_bash", "targeted_group_damage", "apply_execute", "v6_ripple_damage") var effect_type: String = "instant_damage"

# =============================================================================
# V5 DAMAGE AND SCALING
# =============================================================================

## V5: Base damage before scaling (at Tier 1)
@export var base_damage: int = 0

## V5: Scaling percentages - how much of each stat is added to damage
## Format: percent as int (e.g., 100 = 100% of stat added)
@export var kinetic_scaling: int = 0
@export var thermal_scaling: int = 0
@export var arcane_scaling: int = 0
@export var armor_start_scaling: int = 0
@export var crit_damage_scaling: int = 0
@export var missing_hp_scaling: int = 0
@export var cards_played_scaling: int = 0  # Flat bonus per card played
@export var barriers_scaling: int = 0  # Flat bonus per barrier

## V5: Card-specific crit modifiers
@export var crit_chance_bonus: float = 0.0  # Added to base crit chance (e.g., 10.0 = +10%)
@export var crit_damage_bonus: float = 0.0  # Added to base crit damage (e.g., 50.0 = +50%)

## V5: Hit count for multi-hit weapons
@export var hit_count: int = 1

## V5: Can hits repeat on same target?
@export var can_repeat_target: bool = true

# =============================================================================
# V6 HORDE COMBAT: Execute and Ripple
# =============================================================================

## V6: Execute threshold (%) - if enemy HP is at or below this %, instant kill on hit
@export var execute_threshold: int = 0  # 0 = disabled, e.g. 20 = execute enemies at 20% HP or below

## V6: Ripple effect type - triggered when an enemy is killed by this card
@export_enum("none", "chain_damage", "group_damage", "aoe_damage", "spread_damage") var ripple_type: String = "none"

## V6: Ripple value - damage amount or multiplier for ripple effect
@export var ripple_damage: int = 0

## V6: Ripple hits - number of additional targets for chain effects
@export var ripple_count: int = 1

# Legacy damage fields (kept for compatibility)
@export var hex_damage: int = 0
@export var self_damage: int = 0  # Damage dealt to player (for volatile cards)
@export var burn_damage: int = 0  # Burn stacks to apply

# Healing effects
@export var heal_amount: int = 0
@export var lifesteal_on_kill: int = 0

# Defense effects
@export var armor_amount: int = 0
@export var shield_amount: int = 0

# Buff effects (for player buffs)
@export var buff_type: String = ""
@export var buff_value: int = 0

# Targeting
@export_enum("self", "ring", "all_rings", "random_enemy", "all_enemies", "last_damaged") var target_type: String = "ring"
@export var target_rings: Array = []  # Array[int] - Which rings can be targeted
@export var target_count: int = 1  # For multi-target effects
@export var requires_target: bool = false  # If true, player must select a ring

# Card draw effects
@export var cards_to_draw: int = 0

# Push/pull effects
@export var push_amount: int = 0  # Positive = push outward, negative = pull inward

# Generic effect parameters dictionary for flexible effects
@export var effect_params: Dictionary = {}

# Damage-type specific values
@export var splash_damage: int = 0  # For explosive/splash effects
@export var chain_count: int = 0  # For beam effects (number of targets to chain)
@export var armor_shred: int = 0  # For corrosive effects

# Legacy tier scaling - defines how values change per tier
# V5 uses the formula-based tier system instead
@export var tier_scaling: Dictionary = {}

# =============================================================================
# V3 LANE STAGING SYSTEM (kept for combat UI flow)
# =============================================================================

# Lane buff fields - for cards that buff other cards in the staging lane
@export_enum("none", "gun_damage", "all_damage", "armor_gain", "double_fire", "next_weapon_effect") var lane_buff_type: String = "none"
@export var lane_buff_value: int = 0  # Magnitude of the buff
@export var lane_buff_tag_filter: String = ""  # Only buff cards with this tag (empty = all cards)

# Scaling based on lane state - for cards like "Armored Tank"
@export var scales_with_lane: bool = false  # If true, damage scales with lane context
@export_enum("none", "guns_fired", "cards_played", "damage_dealt") var scaling_type: String = "none"
@export var scaling_value: int = 0  # Bonus per unit (e.g., +2 damage per gun fired)


# =============================================================================
# V5 TIER SCALING FORMULAS
# =============================================================================

const TIER_BASE_MULTIPLIERS: Array[float] = [1.0, 1.5, 2.0, 2.5]  # Tiers 1-4: +0%/+50%/+100%/+150%
const TIER_SCALING_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.5, 1.75]  # Tiers 1-4: +0%/+25%/+50%/+75%


func get_tier_base_multiplier() -> float:
	"""Get the base damage multiplier for this card's tier."""
	var index: int = clampi(tier - 1, 0, TIER_BASE_MULTIPLIERS.size() - 1)
	return TIER_BASE_MULTIPLIERS[index]


func get_tier_scaling_multiplier() -> float:
	"""Get the scaling bonus multiplier for this card's tier."""
	var index: int = clampi(tier - 1, 0, TIER_SCALING_MULTIPLIERS.size() - 1)
	return TIER_SCALING_MULTIPLIERS[index]


func get_tiered_base_damage() -> int:
	"""Get base damage adjusted for tier."""
	return int(float(base_damage) * get_tier_base_multiplier())


func get_tiered_scaling(scaling_percent: int) -> int:
	"""Get a scaling percentage adjusted for tier."""
	return int(float(scaling_percent) * get_tier_scaling_multiplier())


# =============================================================================
# V5 DAMAGE CALCULATION
# =============================================================================

func calculate_damage(stats) -> Dictionary:
	"""Calculate final damage using V5 formula.
	Returns: {base: int, scaling_total: int, subtotal: int, type_mult: float, 
	          global_mult: float, final: int, crit_chance: float, crit_mult: float,
	          breakdown: Dictionary}
	"""
	var result: Dictionary = {
		"base": get_tiered_base_damage(),
		"scaling_total": 0,
		"subtotal": 0,
		"type_mult": 1.0,
		"global_mult": 1.0,
		"aoe_mult": 1.0,
		"final": 0,
		"crit_chance": 0.0,
		"crit_mult": 1.5,
		"breakdown": {}
	}
	
	# Calculate scaling from stats
	var scaling_breakdown: Dictionary = {}
	
	if kinetic_scaling > 0:
		var stat_val: int = stats.get_flat_damage_stat("kinetic")
		var tiered_scaling: int = get_tiered_scaling(kinetic_scaling)
		var bonus: int = int(float(stat_val) * float(tiered_scaling) / 100.0)
		result.scaling_total += bonus
		scaling_breakdown["kinetic"] = {"stat": stat_val, "percent": tiered_scaling, "bonus": bonus}
	
	if thermal_scaling > 0:
		var stat_val: int = stats.get_flat_damage_stat("thermal")
		var tiered_scaling: int = get_tiered_scaling(thermal_scaling)
		var bonus: int = int(float(stat_val) * float(tiered_scaling) / 100.0)
		result.scaling_total += bonus
		scaling_breakdown["thermal"] = {"stat": stat_val, "percent": tiered_scaling, "bonus": bonus}
	
	if arcane_scaling > 0:
		var stat_val: int = stats.get_flat_damage_stat("arcane")
		var tiered_scaling: int = get_tiered_scaling(arcane_scaling)
		var bonus: int = int(float(stat_val) * float(tiered_scaling) / 100.0)
		result.scaling_total += bonus
		scaling_breakdown["arcane"] = {"stat": stat_val, "percent": tiered_scaling, "bonus": bonus}
	
	if armor_start_scaling > 0:
		var stat_val: int = stats.get_flat_damage_stat("armor_start")
		var tiered_scaling: int = get_tiered_scaling(armor_start_scaling)
		var bonus: int = int(float(stat_val) * float(tiered_scaling) / 100.0)
		result.scaling_total += bonus
		scaling_breakdown["armor_start"] = {"stat": stat_val, "percent": tiered_scaling, "bonus": bonus}
	
	if crit_damage_scaling > 0:
		var stat_val: int = stats.get_flat_damage_stat("crit_damage")
		var tiered_scaling: int = get_tiered_scaling(crit_damage_scaling)
		var bonus: int = int(float(stat_val) * float(tiered_scaling) / 100.0)
		result.scaling_total += bonus
		scaling_breakdown["crit_damage"] = {"stat": stat_val, "percent": tiered_scaling, "bonus": bonus}
	
	if missing_hp_scaling > 0:
		var stat_val: int = stats.get_flat_damage_stat("missing_hp")
		var tiered_scaling: int = get_tiered_scaling(missing_hp_scaling)
		var bonus: int = int(float(stat_val) * float(tiered_scaling) / 100.0)
		result.scaling_total += bonus
		scaling_breakdown["missing_hp"] = {"stat": stat_val, "percent": tiered_scaling, "bonus": bonus}
	
	if cards_played_scaling > 0:
		var stat_val: int = stats.get_flat_damage_stat("cards_played")
		var bonus: int = stat_val * cards_played_scaling  # Flat bonus per card
		result.scaling_total += bonus
		scaling_breakdown["cards_played"] = {"stat": stat_val, "per_card": cards_played_scaling, "bonus": bonus}
	
	if barriers_scaling > 0:
		var stat_val: int = stats.get_flat_damage_stat("barriers")
		var bonus: int = stat_val * barriers_scaling  # Flat bonus per barrier
		result.scaling_total += bonus
		scaling_breakdown["barriers"] = {"stat": stat_val, "per_barrier": barriers_scaling, "bonus": bonus}
	
	result.breakdown = scaling_breakdown
	
	# Subtotal = Base + Scaling
	result.subtotal = result.base + result.scaling_total
	
	# Get type multiplier
	result.type_mult = stats.get_type_multiplier(damage_type)
	
	# Get global damage multiplier
	result.global_mult = stats.get_damage_multiplier()
	
	# Get AOE multiplier if this is an AOE card
	if is_aoe():
		result.aoe_mult = stats.get_aoe_multiplier()
	
	# Calculate final damage (before crit)
	var final_float: float = float(result.subtotal) * result.type_mult * result.global_mult * result.aoe_mult
	result.final = maxi(0, int(final_float))
	
	# Calculate crit chance and multiplier
	result.crit_chance = stats.get_crit_chance() + (crit_chance_bonus / 100.0)
	result.crit_mult = stats.get_crit_multiplier() + (crit_damage_bonus / 100.0)
	
	return result


func roll_crit(stats) -> Dictionary:
	"""Roll for crit and return damage info.
	Returns: {damage: int, is_crit: bool, crit_mult: float}
	"""
	var calc: Dictionary = calculate_damage(stats)
	var is_crit: bool = randf() < calc.crit_chance
	var final_damage: int = calc.final
	
	if is_crit:
		final_damage = int(float(calc.final) * calc.crit_mult)
	
	return {
		"damage": final_damage,
		"is_crit": is_crit,
		"crit_mult": calc.crit_mult if is_crit else 1.0,
		"base_damage": calc.final
	}


# =============================================================================
# V5 HELPERS
# =============================================================================

func is_weapon() -> bool:
	"""Check if this is a weapon card (can be merged, has tiers)."""
	return not is_instant_card


func is_aoe() -> bool:
	"""Check if this is an AOE card."""
	return target_type == "all_enemies" or target_type == "all_rings" or hit_count > 3 or splash_damage > 0


func has_category(category: String) -> bool:
	"""Check if this card has a specific category."""
	return category in categories


func get_primary_category() -> String:
	"""Get the first/primary category."""
	return categories[0] if categories.size() > 0 else ""


func get_categories_display() -> String:
	"""Get categories formatted for UI display."""
	return TagConstantsClass.format_categories_for_display(categories)


func get_damage_type_icon() -> String:
	"""Get the icon for this card's damage type."""
	return TagConstantsClass.get_damage_type_icon(damage_type)


func get_tier_color() -> Color:
	"""Get the border color for this card's tier."""
	match tier:
		1:
			return Color(0.7, 0.7, 0.7)  # Gray
		2:
			return Color(0.3, 0.8, 0.3)  # Green
		3:
			return Color(0.3, 0.5, 1.0)  # Blue
		4:
			return Color(1.0, 0.8, 0.2)  # Gold
		_:
			return Color(0.7, 0.7, 0.7)


func get_tier_name_v5() -> String:
	"""Get the tier display name for V5."""
	match tier:
		1:
			return "T1"
		2:
			return "T2"
		3:
			return "T3"
		4:
			return "T4"
		_:
			return "T1"


# =============================================================================
# LEGACY VALUE GETTERS (for compatibility)
# =============================================================================

func get_scaled_value(property: String, tier_param: int) -> Variant:
	"""Get the value of a property scaled to the given tier.
	V5: Uses tier formulas for damage, keeps legacy for others."""
	# V5: For damage, use the tier formula
	if property == "damage":
		var old_tier: int = tier
		tier = tier_param
		var result: int = get_tiered_base_damage()
		tier = old_tier
		return result
	
	# Legacy tier_scaling dictionary
	if tier_scaling.has(tier_param) and tier_scaling[tier_param].has(property):
		return tier_scaling[tier_param][property]
	
	# Return base value if no scaling defined
	match property:
		"damage":
			return base_damage
		"hex_damage":
			return hex_damage
		"heal_amount":
			return heal_amount
		"armor_amount":
			return armor_amount
		"buff_value":
			return buff_value
		"target_count":
			return target_count
		"splash_damage":
			return splash_damage
		"chain_count":
			return chain_count
		"armor_shred":
			return armor_shred
		"lane_buff_value":
			return lane_buff_value
		"scaling_value":
			return scaling_value
		"burn_damage":
			return burn_damage
		_:
			return 0


func get_description_with_values(tier_param: int) -> String:
	"""Get the description with actual values filled in."""
	var desc: String = description
	
	# Replace placeholders with actual values
	desc = desc.replace("{damage}", str(get_scaled_value("damage", tier_param)))
	desc = desc.replace("{hex_damage}", str(get_scaled_value("hex_damage", tier_param)))
	desc = desc.replace("{heal_amount}", str(get_scaled_value("heal_amount", tier_param)))
	desc = desc.replace("{armor}", str(get_scaled_value("armor_amount", tier_param)))
	desc = desc.replace("{buff_value}", str(get_scaled_value("buff_value", tier_param)))
	desc = desc.replace("{lifesteal}", str(heal_amount))
	desc = desc.replace("{splash}", str(get_scaled_value("splash_damage", tier_param)))
	desc = desc.replace("{scaling}", str(get_scaled_value("scaling_value", tier_param)))
	desc = desc.replace("{lane_buff_value}", str(get_scaled_value("lane_buff_value", tier_param)))
	desc = desc.replace("{burn}", str(get_scaled_value("burn_damage", tier_param)))
	desc = desc.replace("{hit_count}", str(hit_count))
	desc = desc.replace("{self_damage}", str(self_damage))
	
	return desc


func get_tier_name(tier_param: int) -> String:
	"""Legacy tier name getter."""
	match tier_param:
		1:
			return ""
		2:
			return "+"
		3:
			return "++"
		4:
			return "+++"
		_:
			return ""


# =============================================================================
# TAG HELPERS (Legacy + V5 Category mapping)
# =============================================================================

func has_tag(tag: String) -> bool:
	"""Check if this card has a specific tag."""
	return tag in tags


func get_core_type() -> String:
	"""Get the core type tag (gun, hex, barrier, defense, skill, engine)."""
	return TagConstantsClass.get_core_type_from_list(tags)


func get_family_tags() -> Array[String]:
	"""Get all build-family tags on this card."""
	return TagConstantsClass.get_family_tags_from_list(tags)


func is_gun() -> bool:
	"""Check if this is a gun card."""
	return has_tag(TagConstantsClass.TAG_GUN) or has_category(TagConstantsClass.CAT_KINETIC)


func is_hex() -> bool:
	"""Check if this is a hex card."""
	return has_tag(TagConstantsClass.TAG_HEX) or has_category(TagConstantsClass.CAT_ARCANE)


func is_barrier() -> bool:
	"""Check if this is a barrier card."""
	return has_tag(TagConstantsClass.TAG_BARRIER) or has_category(TagConstantsClass.CAT_CONTROL)


func is_defense() -> bool:
	"""Check if this is a defense card."""
	return has_tag(TagConstantsClass.TAG_DEFENSE) or has_category(TagConstantsClass.CAT_FORTRESS)


func is_skill() -> bool:
	"""Check if this is a skill card."""
	return has_tag(TagConstantsClass.TAG_SKILL) or is_instant_card


func is_buff() -> bool:
	"""Check if this is a lane buff card."""
	return lane_buff_type != "none" or has_tag("buff")


func is_instant() -> bool:
	"""Check if this card resolves instantly (doesn't go to staging lane)."""
	return play_mode == "instant" or is_instant_card


func is_combat() -> bool:
	"""Check if this card goes to the staging lane for execution."""
	return play_mode == "combat" and not is_instant_card


func requires_ring_target() -> bool:
	"""Check if this card is an instant that requires the player to choose a ring.
	These cards should be dragged to the battlefield and dropped on a ring."""
	return play_mode == "instant" and target_type == "ring" and requires_target


func get_tags_display() -> String:
	"""Get tags formatted for UI display."""
	return TagConstantsClass.format_tags_for_display(tags)


# =============================================================================
# LANE STAGING HELPERS (unchanged for combat UI compatibility)
# =============================================================================

func is_lane_buff() -> bool:
	"""Check if this card buffs other cards in the staging lane."""
	return lane_buff_type != "none"


func get_lane_buff_description() -> String:
	"""Get human-readable description of lane buff effect."""
	if lane_buff_type == "none":
		return ""
	
	var filter_text: String = ""
	if not lane_buff_tag_filter.is_empty():
		filter_text = lane_buff_tag_filter + " "
	
	match lane_buff_type:
		"gun_damage":
			return "All %scards gain +%d damage" % [filter_text, lane_buff_value]
		"all_damage":
			return "All %scards gain +%d damage" % [filter_text, lane_buff_value]
		"armor_gain":
			return "All %scards gain +%d armor" % [filter_text, lane_buff_value]
		"double_fire":
			return "Next %scard fires twice" % filter_text
		"next_weapon_effect":
			return "Next weapon: %s" % effect_params.get("effect_description", "special effect")
		_:
			return ""


func get_scaling_description() -> String:
	"""Get human-readable description of lane scaling effect."""
	if not scales_with_lane or scaling_type == "none":
		return ""
	
	match scaling_type:
		"guns_fired":
			return "+%d damage per gun already fired" % scaling_value
		"cards_played":
			return "+%d damage per card already played" % scaling_value
		"damage_dealt":
			return "+%d damage per 10 damage dealt this execution" % scaling_value
		_:
			return ""
