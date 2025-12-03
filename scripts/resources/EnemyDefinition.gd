extends Resource
class_name EnemyDefinition
## EnemyDefinition - Data resource for enemy definitions

## Behavior archetypes for visual badges
enum BehaviorType {
	RUSHER,   # 🏃 Moves every turn until melee
	FAST,     # ⚡ Moves 2+ rings per turn
	RANGED,   # 🏹 Stops early and attacks from distance
	BOMBER,   # 💣 Explodes on death
	BUFFER,   # 📢 Strengthens nearby enemies
	SPAWNER,  # ⚙️ Creates additional enemies
	TANK,     # 🛡️ High HP/armor, slow threat
	AMBUSH,   # 🗡️ Spawns close to player
	SHREDDER, # ⚔️ Destroys armor/barriers efficiently (V2)
	BOSS      # 👑 Special mechanics, high danger
}

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export_multiline var description: String = ""

# Enemy classification
@export_enum("grunt", "elite", "boss") var enemy_type: String = "grunt"
@export var is_elite: bool = false
@export var is_boss: bool = false

# Behavior archetype for visual badge
@export var behavior_type: BehaviorType = BehaviorType.RUSHER

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
@export var aoe_damage: int = 0  # V2: Damage to other enemies (e.g., Bomber explosion)
@export var armor_shred: int = 0  # V2: Extra armor removed on hit (Armor Reaver)
@export var barrier_bonus_damage: int = 0  # V2: Extra damage to barriers (Armor Reaver)

# Economy
@export var scrap_value: int = 2
@export var xp_value: int = 1  # XP awarded when killed (Brotato-style leveling)

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


func get_behavior_badge_icon() -> String:
	"""Get the emoji icon for this enemy's behavior type."""
	match behavior_type:
		BehaviorType.RUSHER:
			return "🏃"
		BehaviorType.FAST:
			return "⚡"
		BehaviorType.RANGED:
			return "🏹"
		BehaviorType.BOMBER:
			return "💣"
		BehaviorType.BUFFER:
			return "📢"
		BehaviorType.SPAWNER:
			return "⚙️"
		BehaviorType.TANK:
			return "🛡️"
		BehaviorType.AMBUSH:
			return "🗡️"
		BehaviorType.SHREDDER:
			return "⚔️"
		BehaviorType.BOSS:
			return "👑"
		_:
			return "🏃"


func get_behavior_badge_color() -> Color:
	"""Get the color associated with this enemy's behavior type."""
	match behavior_type:
		BehaviorType.RUSHER:
			return Color(0.9, 0.3, 0.3)  # Red
		BehaviorType.FAST:
			return Color(1.0, 0.6, 0.2)  # Orange
		BehaviorType.RANGED:
			return Color(0.4, 0.6, 1.0)  # Blue
		BehaviorType.BOMBER:
			return Color(1.0, 0.85, 0.2)  # Yellow
		BehaviorType.BUFFER:
			return Color(0.7, 0.4, 1.0)  # Purple
		BehaviorType.SPAWNER:
			return Color(0.3, 0.9, 0.9)  # Cyan
		BehaviorType.TANK:
			return Color(0.6, 0.6, 0.7)  # Gray
		BehaviorType.AMBUSH:
			return Color(0.9, 0.5, 0.7)  # Pink
		BehaviorType.SHREDDER:
			return Color(0.8, 0.2, 0.2)  # Dark Red
		BehaviorType.BOSS:
			return Color(1.0, 0.8, 0.2)  # Gold
		_:
			return Color(0.9, 0.3, 0.3)


func get_behavior_tooltip() -> String:
	"""Get tooltip text explaining this enemy's behavior."""
	match behavior_type:
		BehaviorType.RUSHER:
			return "Rusher - Advances every turn until reaching melee"
		BehaviorType.FAST:
			return "Fast - Moves 2 rings per turn"
		BehaviorType.RANGED:
			return "Ranged - Stops at distance and attacks from afar"
		BehaviorType.BOMBER:
			return "Bomber - Explodes when killed, dealing damage"
		BehaviorType.BUFFER:
			return "Buffer - Increases nearby enemy damage"
		BehaviorType.SPAWNER:
			return "Spawner - Creates additional enemies each turn"
		BehaviorType.TANK:
			return "Tank - High health and armor, slow but deadly"
		BehaviorType.AMBUSH:
			return "Ambush - Spawns directly in close range"
		BehaviorType.SHREDDER:
			return "Shredder - Destroys armor and barriers efficiently"
		BehaviorType.BOSS:
			return "Boss - Powerful enemy with special abilities"
		_:
			return "Unknown behavior"







