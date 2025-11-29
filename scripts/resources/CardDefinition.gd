extends Resource
class_name CardDefinition
## CardDefinition - Data resource for card definitions

@export var card_id: String = ""
@export var card_name: String = ""
@export_multiline var description: String = ""

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
@export var duration: int = -1  # -1 = rest of wave

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

# Tier scaling - defines how values change per tier
# Format: {tier_number: {property_name: value}}
@export var tier_scaling: Dictionary = {}


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

