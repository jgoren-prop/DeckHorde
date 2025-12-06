extends Control
## TestEnemyCenterPosition - Ensures BattlefieldEnemyManager returns center positions for instance_ids.

const EnemyManagerScene: PackedScene = preload("res://scenes/combat/nodes/BattlefieldEnemyManager.tscn")
const EnemyInstanceClass: GDScript = preload("res://scripts/combat/EnemyInstance.gd")

var enemy_manager: BattlefieldEnemyManager = null
var test_enemy: EnemyInstance = null
var center_position: Vector2 = Vector2.ZERO
var test_passed: bool = false


func _ready() -> void:
	print("[TEST] ========================================")
	print("[TEST] Starting EnemyCenterPosition Test")
	print("[TEST] ========================================")
	
	await get_tree().process_frame
	await _setup_enemy_visual()
	await get_tree().process_frame
	_verify_center_position()
	await _report_and_exit()


func _setup_enemy_visual() -> void:
	print("[TEST] Spawning BattlefieldEnemyManager...")
	enemy_manager = EnemyManagerScene.instantiate()
	add_child(enemy_manager)
	enemy_manager.arena_center = Vector2(200, 200)
	enemy_manager.arena_max_radius = 150.0
	
	await get_tree().process_frame
	
	print("[TEST] Creating EnemyInstance...")
	test_enemy = EnemyInstanceClass.new()
	test_enemy.enemy_id = "husk"
	test_enemy.ring = 1
	test_enemy.max_hp = 15
	test_enemy.current_hp = 15
	enemy_manager.create_enemy_visual(test_enemy)
	
	await get_tree().process_frame
	
	center_position = enemy_manager.get_enemy_center_position(test_enemy.instance_id)
	print("[TEST] Retrieved center position: ", center_position)


func _verify_center_position() -> void:
	var visual: Panel = enemy_manager.get_enemy_visual(test_enemy.instance_id)
	# Now returns global position, so compare with global_position
	var expected_center: Vector2 = visual.global_position + visual.size / 2 if visual else Vector2.ZERO
	var distance: float = center_position.distance_to(expected_center)
	print("[TEST] Expected center (global): ", expected_center)
	print("[TEST] Distance between expected and actual: ", distance)
	
	test_passed = distance < 0.01 and center_position != Vector2.ZERO
	print("[TEST] RESULT: ", "PASSED ✓" if test_passed else "FAILED ✗")


func _report_and_exit() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if test_passed else 1)


