extends Resource
class_name EnemyDefinition
## EnemyDefinition - Data resource for enemy definitions

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export_multiline var description: String = ""

# Enemy classification
@export_enum("grunt", "elite", "boss") var enemy_type: String = "grunt"
@export var is_elite: bool = false
@export var is_boss: bool = false

# Base stats
@export var base_hp: int = 10
@export var base_damage: int = 3
@export var armor: int = 0

# Movement
@export var movement_speed: int = 1  # Rings moved per enemy phase
@export var target_ring: int = 0  # Ring they try to reach (0 = MELEE)

# Attack behavior
@export_enum("melee", "ranged", "suicide") var attack_type: String = "melee"
@export var attack_range: int = 0  # For ranged: max ring they can attack from

# Special abilities
@export var special_ability: String = ""  # Ability identifier
@export var buff_amount: int = 0  # For support enemies
@export var spawn_enemy_id: String = ""  # For spawning enemies
@export var spawn_count: int = 0

# Economy
@export var scrap_value: int = 2

# Visual/UI
@export var icon_color: Color = Color.RED
@export var display_icon: String = "⚔"  # Emoji or icon identifier


func get_scaled_hp(wave: int) -> int:
	"""Get HP scaled by wave number."""
	var scale: float = 1.0 + (wave - 1) * 0.15
	return int(base_hp * scale)


func get_scaled_damage(wave: int) -> int:
	"""Get damage scaled by wave number."""
	var scale: float = 1.0 + (wave - 1) * 0.1
	return int(base_damage * scale)


