extends Node
## EnemyDatabase - Enemy definitions lookup
## Contains all enemy definitions for the game

signal enemies_loaded()

var enemies: Dictionary = {}  # enemy_id -> EnemyDefinition
var enemies_by_type: Dictionary = {}

const EnemyDef = preload("res://scripts/resources/EnemyDefinition.gd")


func _ready() -> void:
	_create_default_enemies()
	print("[EnemyDatabase] Initialized with ", enemies.size(), " enemies")


func _create_default_enemies() -> void:
	_create_grunt_enemies()
	_create_elite_enemies()
	_create_boss_enemies()
	enemies_loaded.emit()


func _create_grunt_enemies() -> void:
	# === GRUNT ENEMIES ===
	
	# Weakling - Brotato Economy: trivially easy Wave 1 enemy
	var weakling := EnemyDef.new()
	weakling.enemy_id = "weakling"
	weakling.enemy_name = "Weakling"
	weakling.description = "Barely a threat. Perfect for learning your starter weapon."
	weakling.enemy_type = "grunt"
	weakling.behavior_type = EnemyDef.BehaviorType.RUSHER
	weakling.base_hp = 3
	weakling.base_damage = 2
	weakling.movement_speed = 1
	weakling.target_ring = 0  # Goes to Melee
	weakling.attack_type = "melee"
	weakling.scrap_value = 5  # Good scrap for early economy
	weakling.xp_value = 1  # Minimal XP
	weakling.icon_color = Color(0.5, 0.5, 0.4)
	weakling.display_icon = "🐀"
	_register_enemy(weakling)
	
	# Husk - basic melee enemy
	var husk := EnemyDef.new()
	husk.enemy_id = "husk"
	husk.enemy_name = "Husk"
	husk.description = "Basic melee enemy. Walks toward player."
	husk.enemy_type = "grunt"
	husk.behavior_type = EnemyDef.BehaviorType.RUSHER
	husk.base_hp = 8
	husk.base_damage = 4
	husk.movement_speed = 1
	husk.target_ring = 0  # Goes to Melee
	husk.attack_type = "melee"
	husk.scrap_value = 2
	husk.xp_value = 2  # Basic grunt
	husk.icon_color = Color(0.8, 0.3, 0.3)
	husk.display_icon = "💀"
	_register_enemy(husk)
	
	# Spitter - ranged enemy that stops at Mid
	var spitter := EnemyDef.new()
	spitter.enemy_id = "spitter"
	spitter.enemy_name = "Spitter"
	spitter.description = "Ranged enemy. Stops at Mid ring and attacks from there."
	spitter.enemy_type = "grunt"
	spitter.behavior_type = EnemyDef.BehaviorType.RANGED
	spitter.base_hp = 7  # V2: was 6
	spitter.base_damage = 3
	spitter.movement_speed = 1
	spitter.target_ring = 2  # Stops at Mid
	spitter.attack_type = "ranged"
	spitter.attack_range = 2  # Can attack from Mid
	spitter.scrap_value = 2
	spitter.xp_value = 2  # Basic ranged
	spitter.icon_color = Color(0.4, 0.7, 0.3)
	spitter.display_icon = "🦎"
	_register_enemy(spitter)
	
	# Spinecrawler - fast melee enemy
	var spinecrawler := EnemyDef.new()
	spinecrawler.enemy_id = "spinecrawler"
	spinecrawler.enemy_name = "Spinecrawler"
	spinecrawler.description = "Fast melee enemy. Moves 2 rings per turn."
	spinecrawler.enemy_type = "grunt"
	spinecrawler.behavior_type = EnemyDef.BehaviorType.FAST
	spinecrawler.base_hp = 6
	spinecrawler.base_damage = 3
	spinecrawler.movement_speed = 2  # Fast!
	spinecrawler.target_ring = 0
	spinecrawler.attack_type = "melee"
	spinecrawler.scrap_value = 3
	spinecrawler.xp_value = 3  # Fast threat
	spinecrawler.icon_color = Color(0.6, 0.2, 0.6)
	spinecrawler.display_icon = "🕷️"
	_register_enemy(spinecrawler)
	
	# Bomber - explodes on death
	var bomber := EnemyDef.new()
	bomber.enemy_id = "bomber"
	bomber.enemy_name = "Bomber"
	bomber.description = "Explodes on death: 6 dmg to player, 4 dmg to ring enemies."
	bomber.enemy_type = "grunt"
	bomber.behavior_type = EnemyDef.BehaviorType.BOMBER
	bomber.base_hp = 9  # V2: was 8
	bomber.base_damage = 0  # No regular attack
	bomber.movement_speed = 1
	bomber.target_ring = 0
	bomber.attack_type = "suicide"
	bomber.special_ability = "explode_on_death"
	bomber.buff_amount = 6  # Explosion damage to player
	bomber.aoe_damage = 4  # V2: Explosion damage to other enemies in ring
	bomber.scrap_value = 3
	bomber.xp_value = 3  # Risky target
	bomber.icon_color = Color(0.9, 0.5, 0.1)
	bomber.display_icon = "💣"
	_register_enemy(bomber)
	
	# Cultist - weak but numerous
	var cultist := EnemyDef.new()
	cultist.enemy_id = "cultist"
	cultist.enemy_name = "Cultist"
	cultist.description = "Weak melee enemy. Spawns in groups."
	cultist.enemy_type = "grunt"
	cultist.behavior_type = EnemyDef.BehaviorType.RUSHER
	cultist.base_hp = 4
	cultist.base_damage = 2
	cultist.movement_speed = 1
	cultist.target_ring = 0
	cultist.attack_type = "melee"
	cultist.scrap_value = 1
	cultist.xp_value = 1  # Fodder
	cultist.icon_color = Color(0.4, 0.3, 0.5)
	cultist.display_icon = "👤"
	_register_enemy(cultist)


func _create_elite_enemies() -> void:
	# === ELITE ENEMIES ===
	
	# Shell Titan - high HP tank
	var titan := EnemyDef.new()
	titan.enemy_id = "shell_titan"
	titan.enemy_name = "Shell Titan"
	titan.description = "High HP tank. Slow but devastating."
	titan.enemy_type = "elite"
	titan.behavior_type = EnemyDef.BehaviorType.TANK
	titan.is_elite = true
	titan.base_hp = 22  # V2: was 20
	titan.base_damage = 8
	titan.armor = 3  # V2: was 2
	titan.movement_speed = 1
	titan.target_ring = 0
	titan.attack_type = "melee"
	titan.scrap_value = 8
	titan.xp_value = 8  # Elite tank
	titan.icon_color = Color(0.5, 0.5, 0.6)
	titan.display_icon = "🛡️"
	_register_enemy(titan)
	
	# Torchbearer - buffs nearby enemies
	var torchbearer := EnemyDef.new()
	torchbearer.enemy_id = "torchbearer"
	torchbearer.enemy_name = "Torchbearer"
	torchbearer.description = "Support enemy. Buffs nearby enemies +2 damage."
	torchbearer.enemy_type = "elite"
	torchbearer.behavior_type = EnemyDef.BehaviorType.BUFFER
	torchbearer.is_elite = true
	torchbearer.base_hp = 10
	torchbearer.base_damage = 2
	torchbearer.movement_speed = 1
	torchbearer.target_ring = 1  # Stays at Close
	torchbearer.attack_type = "melee"
	torchbearer.special_ability = "buff_allies"
	torchbearer.buff_amount = 2
	torchbearer.scrap_value = 6
	torchbearer.xp_value = 6  # Elite buffer
	torchbearer.icon_color = Color(0.9, 0.7, 0.2)
	torchbearer.display_icon = "🔥"
	_register_enemy(torchbearer)
	
	# Channeler - spawns husks
	var channeler := EnemyDef.new()
	channeler.enemy_id = "channeler"
	channeler.enemy_name = "Channeler"
	channeler.description = "Elite caster. Spawns 1 Husk each turn. Stays at Close."
	channeler.enemy_type = "elite"
	channeler.behavior_type = EnemyDef.BehaviorType.SPAWNER
	channeler.is_elite = true
	channeler.base_hp = 12
	channeler.base_damage = 3
	channeler.movement_speed = 1
	channeler.target_ring = 1  # Stays at Close
	channeler.attack_type = "ranged"
	channeler.special_ability = "spawn_minions"
	channeler.spawn_enemy_id = "husk"
	channeler.spawn_count = 1
	channeler.scrap_value = 8
	channeler.xp_value = 8  # Elite spawner
	channeler.icon_color = Color(0.3, 0.3, 0.8)
	channeler.display_icon = "🧙"
	_register_enemy(channeler)
	
	# Stalker - appears directly in Close
	var stalker := EnemyDef.new()
	stalker.enemy_id = "stalker"
	stalker.enemy_name = "Stalker"
	stalker.description = "Ambush enemy. Spawns directly in Close ring."
	stalker.enemy_type = "elite"
	stalker.behavior_type = EnemyDef.BehaviorType.AMBUSH
	stalker.is_elite = true
	stalker.base_hp = 9  # V2: was 8
	stalker.base_damage = 6  # V2: was 5
	stalker.movement_speed = 1
	stalker.target_ring = 0
	stalker.attack_type = "melee"
	stalker.scrap_value = 5
	stalker.xp_value = 5  # Mid-tier threat
	stalker.icon_color = Color(0.2, 0.2, 0.3)
	stalker.display_icon = "👁️"
	_register_enemy(stalker)
	
	# Armor Reaver - V2 armor/barrier shredder
	var reaver := EnemyDef.new()
	reaver.enemy_id = "armor_reaver"
	reaver.enemy_name = "Armor Reaver"
	reaver.description = "Shredder. Deals 3 dmg + removes 3 armor. +1 dmg to barriers."
	reaver.enemy_type = "elite"
	reaver.behavior_type = EnemyDef.BehaviorType.SHREDDER
	reaver.is_elite = true
	reaver.base_hp = 10
	reaver.base_damage = 3
	reaver.armor_shred = 3  # V2: Extra armor removed on hit
	reaver.barrier_bonus_damage = 1  # V2: Extra damage to barriers
	reaver.movement_speed = 1
	reaver.target_ring = 0
	reaver.attack_type = "melee"
	reaver.special_ability = "armor_shred"
	reaver.scrap_value = 6
	reaver.xp_value = 6  # Elite shredder
	reaver.icon_color = Color(0.7, 0.2, 0.2)
	reaver.display_icon = "🪓"
	_register_enemy(reaver)


func _create_boss_enemies() -> void:
	# === BOSS ENEMIES ===
	
	# Ember Saint - Wave 12 boss
	var ember_saint := EnemyDef.new()
	ember_saint.enemy_id = "ember_saint"
	ember_saint.enemy_name = "Ember Saint"
	ember_saint.description = "BOSS: Stays at Far. AoE attacks. Spawns Bombers + Husks."
	ember_saint.enemy_type = "boss"
	ember_saint.behavior_type = EnemyDef.BehaviorType.BOSS
	ember_saint.is_boss = true
	ember_saint.base_hp = 60  # V2: was 50
	ember_saint.base_damage = 10
	ember_saint.armor = 4  # V2: was 3
	ember_saint.movement_speed = 0  # Doesn't move
	ember_saint.target_ring = 3  # Stays at Far
	ember_saint.attack_type = "ranged"
	ember_saint.attack_range = 3  # Attacks from Far
	ember_saint.special_ability = "spawn_minions"
	ember_saint.spawn_enemy_id = "bomber"
	ember_saint.spawn_count = 1
	ember_saint.scrap_value = 50
	ember_saint.xp_value = 50  # Boss - massive XP
	ember_saint.icon_color = Color(1.0, 0.3, 0.1)
	ember_saint.display_icon = "👹"
	_register_enemy(ember_saint)


func _register_enemy(enemy) -> void:
	enemies[enemy.enemy_id] = enemy
	
	if not enemies_by_type.has(enemy.enemy_type):
		enemies_by_type[enemy.enemy_type] = []
	enemies_by_type[enemy.enemy_type].append(enemy.enemy_id)


func get_enemy(enemy_id: String):
	return enemies.get(enemy_id, null)


func get_enemies_by_type(enemy_type: String) -> Array:
	"""Get all enemy IDs of a given type."""
	if enemies_by_type.has(enemy_type):
		return enemies_by_type[enemy_type].duplicate()
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
