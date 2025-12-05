extends Node
## EnemyDatabase - V5 Enemy definitions
## 11 enemies with new armor mechanic (hit removes 1 armor)

signal enemies_loaded()

var enemies: Dictionary = {}  # enemy_id -> EnemyDefinition
var enemies_by_type: Dictionary = {}
var enemies_by_archetype: Dictionary = {}

const EnemyDef = preload("res://scripts/resources/EnemyDefinition.gd")


func _ready() -> void:
	_create_v5_enemies()
	print("[EnemyDatabase] V5 Initialized with ", enemies.size(), " enemies")


func _create_v5_enemies() -> void:
	"""Create all V5 enemies."""
	_create_grunt_enemies()
	_create_elite_enemies()
	_create_boss_enemies()
	enemies_loaded.emit()


func _create_grunt_enemies() -> void:
	# === V5 GRUNT ENEMIES ===
	
	# Weakling (Swarm archetype) - HP: 3, Dmg: 2, Speed: 1
	var weakling := EnemyDef.new()
	weakling.enemy_id = "weakling"
	weakling.enemy_name = "Weakling"
	weakling.description = "Swarm. Weak but numerous. Perfect target for AOE."
	weakling.enemy_type = "grunt"
	weakling.behavior_type = EnemyDef.BehaviorType.RUSHER
	weakling.base_hp = 3
	weakling.base_damage = 2
	weakling.armor = 0
	weakling.movement_speed = 1
	weakling.target_ring = 0
	weakling.attack_type = "melee"
	weakling.scrap_value = 3
	weakling.xp_value = 1
	weakling.icon_color = Color(0.5, 0.5, 0.4)
	weakling.display_icon = "🐀"
	_register_enemy(weakling, "swarm")
	
	# Husk (Rusher archetype) - HP: 8, Dmg: 4, Speed: 1
	var husk := EnemyDef.new()
	husk.enemy_id = "husk"
	husk.enemy_name = "Husk"
	husk.description = "Rusher. Basic melee enemy. Advances every turn."
	husk.enemy_type = "grunt"
	husk.behavior_type = EnemyDef.BehaviorType.RUSHER
	husk.base_hp = 8
	husk.base_damage = 4
	husk.armor = 0
	husk.movement_speed = 1
	husk.target_ring = 0
	husk.attack_type = "melee"
	husk.scrap_value = 4
	husk.xp_value = 2
	husk.icon_color = Color(0.8, 0.3, 0.3)
	husk.display_icon = "💀"
	_register_enemy(husk, "rusher")
	
	# Cultist (Swarm archetype) - HP: 4, Dmg: 2, Speed: 1
	var cultist := EnemyDef.new()
	cultist.enemy_id = "cultist"
	cultist.enemy_name = "Cultist"
	cultist.description = "Swarm. Weak melee enemy. Spawns in large groups."
	cultist.enemy_type = "grunt"
	cultist.behavior_type = EnemyDef.BehaviorType.RUSHER
	cultist.base_hp = 4
	cultist.base_damage = 2
	cultist.armor = 0
	cultist.movement_speed = 1
	cultist.target_ring = 0
	cultist.attack_type = "melee"
	cultist.scrap_value = 2
	cultist.xp_value = 1
	cultist.icon_color = Color(0.4, 0.3, 0.5)
	cultist.display_icon = "👤"
	_register_enemy(cultist, "swarm")
	
	# Spinecrawler (Fast archetype) - HP: 6, Dmg: 3, Speed: 2
	var spinecrawler := EnemyDef.new()
	spinecrawler.enemy_id = "spinecrawler"
	spinecrawler.enemy_name = "Spinecrawler"
	spinecrawler.description = "Fast. Moves 2 rings per turn. Kill it before it reaches you."
	spinecrawler.enemy_type = "grunt"
	spinecrawler.behavior_type = EnemyDef.BehaviorType.FAST
	spinecrawler.base_hp = 6
	spinecrawler.base_damage = 3
	spinecrawler.armor = 0
	spinecrawler.movement_speed = 2
	spinecrawler.target_ring = 0
	spinecrawler.attack_type = "melee"
	spinecrawler.scrap_value = 5
	spinecrawler.xp_value = 2
	spinecrawler.icon_color = Color(0.6, 0.2, 0.6)
	spinecrawler.display_icon = "🕷️"
	_register_enemy(spinecrawler, "fast")
	
	# Spitter (Ranged archetype) - HP: 7, Dmg: 3, Speed: 1
	var spitter := EnemyDef.new()
	spitter.enemy_id = "spitter"
	spitter.enemy_name = "Spitter"
	spitter.description = "Ranged. Stops at Mid ring and attacks from there."
	spitter.enemy_type = "grunt"
	spitter.behavior_type = EnemyDef.BehaviorType.RANGED
	spitter.base_hp = 7
	spitter.base_damage = 3
	spitter.armor = 0
	spitter.movement_speed = 1
	spitter.target_ring = 2  # Stops at Mid
	spitter.attack_type = "ranged"
	spitter.attack_range = 2
	spitter.scrap_value = 4
	spitter.xp_value = 2
	spitter.icon_color = Color(0.4, 0.7, 0.3)
	spitter.display_icon = "🦎"
	_register_enemy(spitter, "ranged")


func _create_elite_enemies() -> void:
	# === V5 ELITE ENEMIES ===
	
	# Shell Titan (Tank archetype) - HP: 20, Dmg: 6, Armor: 5
	var titan := EnemyDef.new()
	titan.enemy_id = "shell_titan"
	titan.enemy_name = "Shell Titan"
	titan.description = "Tank. 5 armor (each hit removes 1). Use multi-hit weapons!"
	titan.enemy_type = "elite"
	titan.behavior_type = EnemyDef.BehaviorType.TANK
	titan.is_elite = true
	titan.base_hp = 20
	titan.base_damage = 6
	titan.armor = 5  # V5: Takes 5 hits to strip armor
	titan.movement_speed = 1
	titan.target_ring = 0
	titan.attack_type = "melee"
	titan.scrap_value = 10
	titan.xp_value = 8
	titan.icon_color = Color(0.5, 0.5, 0.6)
	titan.display_icon = "🛡️"
	_register_enemy(titan, "tank")
	
	# Bomber (Bomber archetype) - HP: 9, Dmg: 6 (explode), Speed: 1
	var bomber := EnemyDef.new()
	bomber.enemy_id = "bomber"
	bomber.enemy_name = "Bomber"
	bomber.description = "Bomber. Explodes on death: 6 dmg to player, 4 dmg to ring enemies."
	bomber.enemy_type = "grunt"  # Listed as grunt for spawn purposes
	bomber.behavior_type = EnemyDef.BehaviorType.BOMBER
	bomber.base_hp = 9
	bomber.base_damage = 0  # No regular attack
	bomber.armor = 0
	bomber.movement_speed = 1
	bomber.target_ring = 0
	bomber.attack_type = "suicide"
	bomber.special_ability = "explode_on_death"
	bomber.buff_amount = 6  # Explosion damage to player
	bomber.aoe_damage = 4   # Explosion damage to other enemies
	bomber.scrap_value = 5
	bomber.xp_value = 3
	bomber.icon_color = Color(0.9, 0.5, 0.1)
	bomber.display_icon = "💣"
	_register_enemy(bomber, "bomber")
	
	# Torchbearer (Buffer archetype) - HP: 10, Dmg: 2
	var torchbearer := EnemyDef.new()
	torchbearer.enemy_id = "torchbearer"
	torchbearer.enemy_name = "Torchbearer"
	torchbearer.description = "Buffer. Gives all enemies in same ring +2 damage."
	torchbearer.enemy_type = "elite"
	torchbearer.behavior_type = EnemyDef.BehaviorType.BUFFER
	torchbearer.is_elite = true
	torchbearer.base_hp = 10
	torchbearer.base_damage = 2
	torchbearer.armor = 0
	torchbearer.movement_speed = 1
	torchbearer.target_ring = 1  # Stays at Close
	torchbearer.attack_type = "melee"
	torchbearer.special_ability = "buff_allies"
	torchbearer.buff_amount = 2
	torchbearer.scrap_value = 8
	torchbearer.xp_value = 6
	torchbearer.icon_color = Color(0.9, 0.7, 0.2)
	torchbearer.display_icon = "🔥"
	_register_enemy(torchbearer, "buffer")
	
	# Channeler (Spawner archetype) - HP: 12, Dmg: 2
	var channeler := EnemyDef.new()
	channeler.enemy_id = "channeler"
	channeler.enemy_name = "Channeler"
	channeler.description = "Spawner. Spawns 1 Cultist each turn. Kill it fast!"
	channeler.enemy_type = "elite"
	channeler.behavior_type = EnemyDef.BehaviorType.SPAWNER
	channeler.is_elite = true
	channeler.base_hp = 12
	channeler.base_damage = 2
	channeler.armor = 0
	channeler.movement_speed = 1
	channeler.target_ring = 1  # Stays at Close
	channeler.attack_type = "ranged"
	channeler.special_ability = "spawn_minions"
	channeler.spawn_enemy_id = "cultist"
	channeler.spawn_count = 1
	channeler.scrap_value = 10
	channeler.xp_value = 8
	channeler.icon_color = Color(0.3, 0.3, 0.8)
	channeler.display_icon = "🧙"
	_register_enemy(channeler, "spawner")
	
	# Stalker (Ambusher archetype) - HP: 9, Dmg: 5, spawns at Close
	var stalker := EnemyDef.new()
	stalker.enemy_id = "stalker"
	stalker.enemy_name = "Stalker"
	stalker.description = "Ambusher. Spawns directly in Close ring. Immediate threat!"
	stalker.enemy_type = "elite"
	stalker.behavior_type = EnemyDef.BehaviorType.AMBUSH
	stalker.is_elite = true
	stalker.base_hp = 9
	stalker.base_damage = 5
	stalker.armor = 0
	stalker.movement_speed = 1
	stalker.target_ring = 0
	stalker.attack_type = "melee"
	stalker.scrap_value = 7
	stalker.xp_value = 5
	stalker.icon_color = Color(0.2, 0.2, 0.3)
	stalker.display_icon = "👁️"
	_register_enemy(stalker, "ambusher")
	
	# Armor Reaver (Armor Reaver archetype) - HP: 10, Dmg: 3, shreds 3 player armor
	var reaver := EnemyDef.new()
	reaver.enemy_id = "armor_reaver"
	reaver.enemy_name = "Armor Reaver"
	reaver.description = "Armor Reaver. On hit: 3 dmg + removes 3 of YOUR armor."
	reaver.enemy_type = "elite"
	reaver.behavior_type = EnemyDef.BehaviorType.SHREDDER
	reaver.is_elite = true
	reaver.base_hp = 10
	reaver.base_damage = 3
	reaver.armor_shred = 3  # Removes player armor
	reaver.armor = 0
	reaver.movement_speed = 1
	reaver.target_ring = 0
	reaver.attack_type = "melee"
	reaver.special_ability = "armor_shred"
	reaver.scrap_value = 8
	reaver.xp_value = 6
	reaver.icon_color = Color(0.7, 0.2, 0.2)
	reaver.display_icon = "🪓"
	_register_enemy(reaver, "armor_reaver")


func _create_boss_enemies() -> void:
	# === V5 BOSS ENEMIES ===
	
	# Ember Saint - Wave 20 final boss
	var ember_saint := EnemyDef.new()
	ember_saint.enemy_id = "ember_saint"
	ember_saint.enemy_name = "Ember Saint"
	ember_saint.description = "BOSS. Stays at Far. AoE attacks all rings. Spawns Bombers."
	ember_saint.enemy_type = "boss"
	ember_saint.behavior_type = EnemyDef.BehaviorType.BOSS
	ember_saint.is_boss = true
	ember_saint.base_hp = 100
	ember_saint.base_damage = 10
	ember_saint.armor = 5
	ember_saint.movement_speed = 0  # Doesn't move
	ember_saint.target_ring = 3  # Stays at Far
	ember_saint.attack_type = "ranged"
	ember_saint.attack_range = 3
	ember_saint.special_ability = "spawn_minions"
	ember_saint.spawn_enemy_id = "bomber"
	ember_saint.spawn_count = 1
	ember_saint.scrap_value = 100
	ember_saint.xp_value = 50
	ember_saint.icon_color = Color(1.0, 0.3, 0.1)
	ember_saint.display_icon = "👹"
	_register_enemy(ember_saint, "boss")


func _register_enemy(enemy, archetype: String = "") -> void:
	"""Register an enemy in all indexes."""
	enemies[enemy.enemy_id] = enemy
	
	# Index by type
	if not enemies_by_type.has(enemy.enemy_type):
		enemies_by_type[enemy.enemy_type] = []
	enemies_by_type[enemy.enemy_type].append(enemy.enemy_id)
	
	# Index by archetype
	if not archetype.is_empty():
		if not enemies_by_archetype.has(archetype):
			enemies_by_archetype[archetype] = []
		enemies_by_archetype[archetype].append(enemy.enemy_id)


func get_enemy(enemy_id: String):
	return enemies.get(enemy_id, null)


func get_enemies_by_type(enemy_type: String) -> Array:
	"""Get all enemy IDs of a given type."""
	if enemies_by_type.has(enemy_type):
		return enemies_by_type[enemy_type].duplicate()
	return []


func get_enemies_by_archetype(archetype: String) -> Array:
	"""Get all enemy IDs of a given archetype."""
	if enemies_by_archetype.has(archetype):
		return enemies_by_archetype[archetype].duplicate()
	return []


func get_random_grunt() -> String:
	"""Get a random grunt enemy ID."""
	var grunts: Array = get_enemies_by_type("grunt")
	if grunts.size() > 0:
		return grunts[randi() % grunts.size()]
	return "husk"


func get_random_elite() -> String:
	"""Get a random elite enemy ID."""
	var elites: Array = get_enemies_by_type("elite")
	if elites.size() > 0:
		return elites[randi() % elites.size()]
	return "shell_titan"


func get_all_enemies() -> Array:
	"""Get all enemy IDs."""
	return enemies.keys()
