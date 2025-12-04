extends Resource
class_name CardDefinition
## CardDefinition - Data resource for card definitions
## V3: Staging system - all cards are one-shot, execute in sequence

# V2: Preload TagConstants to ensure it's available
const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")

@export var card_id: String = ""
@export var card_name: String = ""
@export_multiline var description: String = ""
@export_multiline var instant_description: String = ""  # Labeled instant effect description
@export_multiline var persistent_description: String = ""  # Labeled persistent effect description

# Card classification
@export_enum("weapon", "skill", "hex", "defense", "buff") var card_type: String = "weapon"
@export_enum("combat", "instant") var play_mode: String = "combat"  # combat = goes to staging lane, instant = resolves immediately
@export var tags: Array = []  # Array[String]
@export var rarity: int = 1  # 1 = common, 2 = uncommon, 3 = rare, 4 = legendary

# Cost
@export var base_cost: int = 1

# Effect type determines how the card is resolved
@export_enum("instant_damage", "heal", "buff", "apply_hex", "apply_hex_multi", "gain_armor", "ring_barrier", "damage_and_heal", "damage_and_armor", "armor_and_lifesteal", "draw_cards", "push_enemies", "lane_buff", "scaling_damage") var effect_type: String = "instant_damage"

# Damage effects
@export var base_damage: int = 0
@export var hex_damage: int = 0
@export var self_damage: int = 0  # Damage dealt to player (for volatile cards)

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

# Tier scaling - defines how values change per tier
# Format: {tier_number: {property_name: value}}
@export var tier_scaling: Dictionary = {}

# =============================================================================
# V3 LANE STAGING SYSTEM
# =============================================================================

# Lane buff fields - for cards that buff other cards in the staging lane
@export_enum("none", "gun_damage", "all_damage", "armor_gain", "double_fire") var lane_buff_type: String = "none"
@export var lane_buff_value: int = 0  # Magnitude of the buff
@export var lane_buff_tag_filter: String = ""  # Only buff cards with this tag (empty = all cards)

# Scaling based on lane state - for cards like "Armored Tank"
@export var scales_with_lane: bool = false  # If true, damage scales with lane context
@export_enum("none", "guns_fired", "cards_played", "damage_dealt") var scaling_type: String = "none"
@export var scaling_value: int = 0  # Bonus per unit (e.g., +2 damage per gun fired)


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
	desc = desc.replace("{lifesteal}", str(heal_amount))
	desc = desc.replace("{splash}", str(get_scaled_value("splash_damage", tier)))
	desc = desc.replace("{scaling}", str(get_scaled_value("scaling_value", tier)))
	desc = desc.replace("{lane_buff_value}", str(get_scaled_value("lane_buff_value", tier)))
	
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
# TAG HELPERS
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


func is_buff() -> bool:
	"""Check if this is a lane buff card."""
	return lane_buff_type != "none" or has_tag("buff")


func is_instant() -> bool:
	"""Check if this card resolves instantly (doesn't go to staging lane)."""
	return play_mode == "instant"


func is_combat() -> bool:
	"""Check if this card goes to the staging lane for execution."""
	return play_mode == "combat"


func requires_ring_target() -> bool:
	"""Check if this card is an instant that requires the player to choose a ring.
	These cards should be dragged to the battlefield and dropped on a ring."""
	return play_mode == "instant" and target_type == "ring" and requires_target


func get_tags_display() -> String:
	"""Get tags formatted for UI display."""
	return TagConstantsClass.format_tags_for_display(tags)


# =============================================================================
# LANE STAGING HELPERS
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
