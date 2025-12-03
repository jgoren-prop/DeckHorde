extends Resource
class_name ArtifactDefinition
## ArtifactDefinition - V2 Brotato-style artifact/item definitions
## Artifacts now use stat_modifiers for PlayerStats integration

@export var artifact_id: String = ""
@export var artifact_name: String = ""
@export_multiline var description: String = ""

# Rarity affects shop price and appearance rate
@export var rarity: int = 1  # 1 = common, 2 = uncommon, 3 = rare, 4 = legendary

# Cost in shop
@export var base_cost: int = 50

# V2: Stackability - can you own multiple copies?
@export var stackable: bool = true  # Most V2 artifacts are stackable

# V2: Stat modifiers applied to PlayerStats (ADDITIVE, like wardens)
# Format: {"stat_name": modifier_value}
# Example: {"gun_damage_percent": 10.0} adds +10% gun damage
@export var stat_modifiers: Dictionary = {}

# V2: Tag requirements - artifact only affects cards with these tags
@export var required_tags: Array = []  # e.g., ["gun"] for gun-only bonuses

# Effect type determines when/how the artifact triggers
# V1 triggers: passive, on_card_play, on_kill, on_damage_taken, on_turn_start, on_turn_end, on_wave_start, on_wave_end, on_heal, on_hex_consumed, on_barrier_trigger
# V2 triggers: on_explosive_hit, on_piercing_overflow, on_beam_chain, on_shock_hit, on_corrosive_hit, on_gun_deploy, on_gun_fire, on_gun_out_of_ammo, on_engine_trigger, on_self_damage, on_overkill
@export_enum("passive", "on_card_play", "on_kill", "on_damage_taken", "on_turn_start", "on_turn_end", "on_wave_start", "on_wave_end", "on_heal", "on_hex_consumed", "on_barrier_trigger", "on_explosive_hit", "on_piercing_overflow", "on_beam_chain", "on_shock_hit", "on_corrosive_hit", "on_gun_deploy", "on_gun_fire", "on_gun_out_of_ammo", "on_engine_trigger", "on_self_damage", "on_overkill") var trigger_type: String = "passive"

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
















