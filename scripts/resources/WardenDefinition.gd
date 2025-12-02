extends Resource
class_name WardenDefinition
## WardenDefinition - Data resource for Warden (character) definitions
## V2: Uses stat_modifiers for Brotato-style stat scaling

@export var warden_id: String = ""
@export var warden_name: String = ""
@export_multiline var description: String = ""
@export_multiline var passive_description: String = ""

# Base stats (V2 defaults)
@export var max_hp: int = 70
@export var base_armor: int = 0
@export var base_energy: int = 3
@export var hand_size: int = 5

# V2: Stat modifiers applied to PlayerStats (ADDITIVE)
# Format: {"stat_name": modifier_value}
# Example: {"gun_damage_percent": 20.0} adds +20% gun damage
# See PlayerStats.gd for available stat names
@export var stat_modifiers: Dictionary = {}

# Passive ability identifier (temporary - will be replaced by V2 passive system)
# Currently only used for: "cheat_death" (Glass Warden)
@export var passive_id: String = ""

# Starting deck - Array of {card_id: String, tier: int, count: int}
@export var starting_deck: Array[Dictionary] = []

# Visual
@export var portrait_color: Color = Color.WHITE
@export var icon: String = "🛡"

# Unlock
@export var is_unlocked_by_default: bool = false
@export var unlock_cost: int = 100  # Essence cost


func get_starting_deck_expanded() -> Array[Dictionary]:
	"""Expand starting deck with count into individual entries."""
	var result: Array[Dictionary] = []
	for entry: Dictionary in starting_deck:
		var count: int = entry.get("count", 1)
		for i: int in range(count):
			result.append({
				"card_id": entry.card_id,
				"tier": entry.get("tier", 1)
			})
	return result















