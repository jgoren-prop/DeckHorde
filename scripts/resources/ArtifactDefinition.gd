extends Resource
class_name ArtifactDefinition
## ArtifactDefinition - Data resource for artifact (passive item) definitions

@export var artifact_id: String = ""
@export var artifact_name: String = ""
@export_multiline var description: String = ""

# Rarity affects shop price and appearance rate
@export var rarity: int = 1  # 1 = common, 2 = uncommon, 3 = rare

# Cost in shop
@export var base_cost: int = 50

# Effect type determines when/how the artifact triggers
@export_enum("passive", "on_card_play", "on_kill", "on_damage_taken", "on_turn_start", "on_turn_end", "on_wave_start", "on_wave_end") var trigger_type: String = "passive"

# Filter for when the artifact triggers (e.g., only on Gun cards)
@export var trigger_tag: String = ""  # Card tag filter
@export var trigger_condition: String = ""  # Additional condition

# Effect parameters
@export var effect_type: String = ""  # What the artifact does
@export var effect_value: int = 0  # Numeric value for the effect
@export var effect_params: Dictionary = {}  # Additional parameters

# Visual
@export var icon: String = "💎"
@export var icon_color: Color = Color.GOLD

# Unlock
@export var is_unlocked_by_default: bool = true
@export var unlock_cost: int = 50


func get_description_with_values() -> String:
	"""Get description with actual values filled in."""
	var desc: String = description
	desc = desc.replace("{value}", str(effect_value))
	return desc










