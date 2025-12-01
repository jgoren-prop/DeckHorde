extends Resource
class_name WardenDefinition
## WardenDefinition - Data resource for Warden (character) definitions

@export var warden_id: String = ""
@export var warden_name: String = ""
@export_multiline var description: String = ""
@export_multiline var passive_description: String = ""
@export_multiline var drawback_description: String = ""

# Base stats
@export var max_hp: int = 60
@export var base_armor: int = 0
@export var damage_multiplier: float = 1.0
@export var base_energy: int = 3
@export var hand_size: int = 5

# Tag bonuses (e.g., "gun" -> 0.15 means +15% damage with Gun cards)
@export var tag_damage_bonuses: Dictionary = {}

# Passive ability identifiers
@export var passive_id: String = ""
@export var passive_params: Dictionary = {}

# Drawback identifiers
@export var drawback_id: String = ""
@export var drawback_params: Dictionary = {}

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











