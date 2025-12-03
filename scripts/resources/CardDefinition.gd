extends Resource
class_name CardDefinition
## CardDefinition - Data resource for card definitions

# V2: Preload TagConstants to ensure it's available
const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")

@export var card_id: String = ""
@export var card_name: String = ""
@export_multiline var description: String = ""

# Explicit effect descriptions (displayed with labels)
@export_multiline var instant_description: String = ""  # "Instant: ___" effect
@export_multiline var persistent_description: String = ""  # "Persistent: ___" effect

# Card classification
@export_enum("weapon", "skill", "hex", "defense", "curse") var card_type: String = "weapon"
@export var tags: Array = []  # Array[String]
@export var rarity: int = 1  # 1 = common, 2 = uncommon, 3 = rare

# Cost
@export var base_cost: int = 1

# Effect type determines how the card is resolved
@export_enum("instant_damage", "weapon_persistent", "heal", "buff", "apply_hex", "apply_hex_multi", "gain_armor", "ring_barrier", "damage_and_heal", "damage_and_armor", "armor_and_lifesteal", "draw_cards", "push_enemies") var effect_type: String = "instant_damage"

# Damage effects
@export var base_damage: int = 0
@export var hex_damage: int = 0
@export var self_damage: int = 0  # V2: Damage dealt to player (for volatile cards)

# Healing effects
@export var heal_amount: int = 0
@export var lifesteal_on_kill: int = 0

# Defense effects
@export var armor_amount: int = 0
@export var shield_amount: int = 0

# Buff effects
@export var buff_type: String = ""
@export var buff_value: int = 0

# Duration (for persistent effects)
@export var duration: int = -1  # -1 = rest of wave (legacy, use duration_type now)

# V2 Duration System - flexible weapon lifespans
@export_enum("infinite", "turns", "kills", "burn_out") var duration_type: String = "infinite"
@export var duration_turns: int = -1  # Number of turns weapon lasts (-1 = infinite)
@export var duration_kills: int = -1  # Number of kills before weapon expires (-1 = infinite)
@export_enum("discard", "banish", "destroy") var on_expire: String = "discard"  # What happens when weapon expires

# Targeting
@export_enum("self", "ring", "all_rings", "random_enemy", "all_enemies") var target_type: String = "ring"
@export var target_rings: Array = []  # Array[int] - Which rings can be targeted
@export var target_count: int = 1  # For multi-target effects
@export var requires_target: bool = false  # If true, player must select a ring

# Weapon-specific
@export var weapon_trigger: String = ""  # "turn_start", "turn_end", "on_play"

# Card draw effects
@export var cards_to_draw: int = 0

# Push/pull effects
@export var push_amount: int = 0  # Positive = push outward, negative = pull inward

# V2: Generic effect parameters dictionary for flexible effects
@export var effect_params: Dictionary = {}

# V2: Damage-type specific values
@export var splash_damage: int = 0  # For explosive effects
@export var chain_count: int = 0  # For beam effects (number of targets to chain)
@export var armor_shred: int = 0  # For corrosive effects

# Tier scaling - defines how values change per tier
# Format: {tier_number: {property_name: value}}
@export var tier_scaling: Dictionary = {}

# Brotato Economy: Starter weapon flag
@export var is_starter_weapon: bool = false


func get_scaled_value(property: String, tier: int) -> Variant:
	"""Get the value of a property scaled to the given tier."""
	if tier_scaling.has(tier) and tier_scaling[tier].has(property):
		return tier_scaling[tier][property]
	
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
		"duration":
			return duration
		"target_count":
			return target_count
		"splash_damage":
			return splash_damage
		"chain_count":
			return chain_count
		"armor_shred":
			return armor_shred
		_:
			return 0


func get_description_with_values(tier: int) -> String:
	"""Get the description with actual values filled in."""
	var desc: String = description
	
	# Replace placeholders with actual values
	desc = desc.replace("{damage}", str(get_scaled_value("damage", tier)))
	desc = desc.replace("{hex_damage}", str(get_scaled_value("hex_damage", tier)))
	desc = desc.replace("{heal_amount}", str(get_scaled_value("heal_amount", tier)))
	desc = desc.replace("{armor}", str(get_scaled_value("armor_amount", tier)))
	desc = desc.replace("{buff_value}", str(get_scaled_value("buff_value", tier)))
	desc = desc.replace("{duration}", str(get_scaled_value("duration", tier)))
	desc = desc.replace("{lifesteal}", str(heal_amount))
	
	return desc


func get_tier_name(tier: int) -> String:
	match tier:
		1:
			return ""
		2:
			return "+"
		3:
			return "++"
		_:
			return ""


# =============================================================================
# V2 TAG HELPERS
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
	return has_tag(TagConstantsClass.TAG_GUN)


func is_hex() -> bool:
	"""Check if this is a hex card."""
	return has_tag(TagConstantsClass.TAG_HEX)


func is_barrier() -> bool:
	"""Check if this is a barrier card."""
	return has_tag(TagConstantsClass.TAG_BARRIER)


func is_defense() -> bool:
	"""Check if this is a defense card."""
	return has_tag(TagConstantsClass.TAG_DEFENSE)


func is_skill() -> bool:
	"""Check if this is a skill card."""
	return has_tag(TagConstantsClass.TAG_SKILL)


func is_engine() -> bool:
	"""Check if this is an engine card."""
	return has_tag(TagConstantsClass.TAG_ENGINE)


func get_tags_display() -> String:
	"""Get tags formatted for UI display."""
	return TagConstantsClass.format_tags_for_display(tags)


# =============================================================================
# V2 DURATION HELPERS
# =============================================================================

func is_persistent() -> bool:
	"""Check if this card is a persistent weapon that stays deployed."""
	return has_tag("persistent") or effect_type == "weapon_persistent"


func has_duration_limit() -> bool:
	"""Check if this weapon has a limited duration."""
	if duration_type == "infinite":
		return false
	if duration_type == "turns" and duration_turns > 0:
		return true
	if duration_type == "kills" and duration_kills > 0:
		return true
	if duration_type == "burn_out":
		return true
	return false


func get_duration_display() -> String:
	"""Get human-readable duration text for UI."""
	match duration_type:
		"infinite":
			return "Permanent"
		"turns":
			if duration_turns > 0:
				return "%d turn%s" % [duration_turns, "s" if duration_turns > 1 else ""]
			return "Permanent"
		"kills":
			if duration_kills > 0:
				return "%d kill%s" % [duration_kills, "s" if duration_kills > 1 else ""]
			return "Permanent"
		"burn_out":
			var turns: int = duration_turns if duration_turns > 0 else 2
			return "%d turns then banished" % turns
		_:
			return "Permanent"

