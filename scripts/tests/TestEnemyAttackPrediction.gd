extends Node
## TestEnemyAttackPrediction - Validates EnemyInstance threat helpers.

const EnemyInstanceClass: GDScript = preload("res://scripts/combat/EnemyInstance.gd")

var all_passed: bool = true


func _ready() -> void:
	print("[TEST] ========================================")
	print("[TEST] Starting EnemyAttackPrediction Test")
	print("[TEST] ========================================")
	
	_run_melee_tests()
	_run_ranged_tests()
	_run_suicide_tests()
	
	print("[TEST] RESULT: ", "PASSED ✓" if all_passed else "FAILED ✗")
	get_tree().quit(0 if all_passed else 1)


func _run_melee_tests() -> void:
	var melee_enemy: EnemyInstance = EnemyInstanceClass.new()
	melee_enemy.enemy_id = "husk"
	melee_enemy.ring = 0
	var melee_def: EnemyDefinition = EnemyDatabase.get_enemy("husk")
	var will_attack: bool = melee_enemy.will_attack_this_turn(melee_def)
	_check(will_attack, "Husk attacks in melee ring")
	
	var wave: int = 1
	var predicted_damage: int = melee_enemy.get_predicted_attack_damage(wave, melee_def)
	var expected_damage: int = melee_def.get_scaled_damage(wave)
	_check(predicted_damage == expected_damage, "Predicted melee damage matches definition")


func _run_ranged_tests() -> void:
	var ranged_enemy: EnemyInstance = EnemyInstanceClass.new()
	ranged_enemy.enemy_id = "spitter"
	var ranged_def: EnemyDefinition = EnemyDatabase.get_enemy("spitter")
	ranged_enemy.ring = ranged_def.target_ring
	_check(ranged_enemy.will_attack_this_turn(ranged_def), "Spitter attacks at target ring")
	
	var wave: int = 1
	var predicted_damage: int = ranged_enemy.get_predicted_attack_damage(wave, ranged_def)
	var expected_damage: int = ranged_def.get_scaled_damage(wave)
	_check(predicted_damage == expected_damage, "Predicted ranged damage matches definition")
	
	ranged_enemy.ring = ranged_def.target_ring + 1
	_check(not ranged_enemy.will_attack_this_turn(ranged_def), "Spitter stops attacking outside target ring")


func _run_suicide_tests() -> void:
	var bomber_enemy: EnemyInstance = EnemyInstanceClass.new()
	bomber_enemy.enemy_id = "bomber"
	bomber_enemy.ring = 0
	var bomber_def: EnemyDefinition = EnemyDatabase.get_enemy("bomber")
	_check(not bomber_enemy.will_attack_this_turn(bomber_def), "Bomber never appears as attacker")
	_check(bomber_enemy.get_predicted_attack_damage(1, bomber_def) == 0, "Bomber predicted damage is zero")


func _check(condition: bool, description: String) -> void:
	print("[TEST] ", description, ": ", "OK" if condition else "FAIL")
	if not condition:
		all_passed = false

