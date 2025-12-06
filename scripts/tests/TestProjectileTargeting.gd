extends Control
## Automated test for projectile targeting - verifies mini-panel positions are correct

var stack_system: Control
var test_passed: bool = true
var test_errors: Array[String] = []

# Mock enemy class for testing
class MockEnemy:
	var enemy_id: String = "husk"
	var instance_id: int = 0
	var ring: int = 2
	var max_hp: int = 10
	var current_hp: int = 10
	var status_effects: Dictionary = {}
	var movement_cooldown: int = 0
	
	func get_hp_percentage() -> float:
		return float(current_hp) / float(max_hp)
	
	func get_status_value(_status_name: String) -> int:
		return 0
	
	func will_attack_this_turn(_enemy_def = null) -> bool:
		return ring == 0
	
	func will_move_this_turn(_enemy_def = null) -> bool:
		return movement_cooldown <= 0


func _ready() -> void:
	print("[TEST] ========================================")
	print("[TEST] TestProjectileTargeting starting...")
	
	await get_tree().process_frame
	await _run_tests()
	
	print("[TEST] ========================================")
	if test_passed:
		print("[TEST] RESULT: ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TEST] RESULT: TESTS FAILED ✗")
		for error in test_errors:
			print("[TEST] ERROR: ", error)
		get_tree().quit(1)


func _run_tests() -> void:
	# Test 1: MiniEnemyPanel metadata is set immediately
	await _test_mini_panel_metadata_immediate()
	
	# Test 2: Stack expansion creates mini-panels with correct metadata
	await _test_stack_expansion_metadata()
	
	# Test 3: get_enemy_mini_panel_position returns correct position
	await _test_mini_panel_position()


func _test_mini_panel_metadata_immediate() -> void:
	print("[TEST] Test 1: MiniEnemyPanel metadata set immediately")
	
	var MiniEnemyPanelScene: PackedScene = load("res://scenes/combat/components/MiniEnemyPanel.tscn")
	var mini_panel: Panel = MiniEnemyPanelScene.instantiate()
	
	# Create a test enemy
	var test_enemy: MockEnemy = MockEnemy.new()
	test_enemy.instance_id = 12345
	
	# Call setup BEFORE adding to tree
	mini_panel.setup(test_enemy, Vector2(60, 70), Color.RED, "test_stack")
	
	# Check metadata is set IMMEDIATELY (before adding to tree)
	var meta_enemy = mini_panel.get_meta("enemy_instance", null)
	if meta_enemy == null:
		test_passed = false
		test_errors.append("Test 1: Metadata not set before add_child")
		print("[TEST] Test 1 FAILED: Metadata not set immediately")
	elif meta_enemy.instance_id != 12345:
		test_passed = false
		test_errors.append("Test 1: Wrong instance_id in metadata")
		print("[TEST] Test 1 FAILED: Wrong instance_id")
	else:
		print("[TEST] Test 1 PASSED: Metadata set immediately (instance_id=", meta_enemy.instance_id, ")")
	
	# Cleanup
	mini_panel.queue_free()


func _test_stack_expansion_metadata() -> void:
	print("[TEST] Test 2: Stack expansion creates mini-panels with metadata")
	
	# Load and instantiate stack system
	var StackSystemScene: PackedScene = load("res://scenes/combat/nodes/BattlefieldStackSystem.tscn")
	stack_system = StackSystemScene.instantiate()
	add_child(stack_system)
	stack_system.size = Vector2(800, 600)
	
	await get_tree().process_frame
	
	# Create test enemies using mock
	var enemies: Array = []
	for i in range(3):
		var enemy: MockEnemy = MockEnemy.new()
		enemy.instance_id = 100 + i
		enemy.enemy_id = "husk"
		enemy.ring = 2
		enemies.append(enemy)
	
	# Create a stack (ring, enemy_id, enemies, optional_stack_key)
	var stack_key: String = stack_system.create_stack(2, "husk", enemies)
	print("[TEST] Created stack: ", stack_key)
	
	await get_tree().process_frame
	
	# Expand the stack
	stack_system.expand_stack(stack_key)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify mini-panels were created with correct metadata
	var stack_data: Dictionary = stack_system.stack_visuals.get(stack_key, {})
	var mini_panels: Array = stack_data.get("mini_panels", [])
	
	print("[TEST] Mini panels count: ", mini_panels.size())
	
	if mini_panels.size() != 3:
		test_passed = false
		test_errors.append("Test 2: Expected 3 mini-panels, got " + str(mini_panels.size()))
		print("[TEST] Test 2 FAILED: Wrong mini-panel count")
	else:
		var all_meta_set: bool = true
		for i in range(mini_panels.size()):
			var panel = mini_panels[i]
			var meta = panel.get_meta("enemy_instance", null)
			if meta == null:
				all_meta_set = false
				print("[TEST] Panel ", i, " has no metadata!")
			else:
				print("[TEST] Panel ", i, " has metadata for instance_id=", meta.instance_id)
		
		if all_meta_set:
			print("[TEST] Test 2 PASSED: All mini-panels have metadata")
		else:
			test_passed = false
			test_errors.append("Test 2: Some mini-panels missing metadata")
			print("[TEST] Test 2 FAILED: Missing metadata")


func _test_mini_panel_position() -> void:
	print("[TEST] Test 3: get_enemy_mini_panel_position returns correct position")
	
	if not is_instance_valid(stack_system):
		test_passed = false
		test_errors.append("Test 3: Stack system not valid")
		return
	
	# Find the stack we created
	var stack_keys: Array = stack_system.stack_visuals.keys()
	if stack_keys.is_empty():
		test_passed = false
		test_errors.append("Test 3: No stacks found")
		return
	
	var stack_key: String = stack_keys[0]
	var stack_data: Dictionary = stack_system.stack_visuals[stack_key]
	var enemies: Array = stack_data.enemies
	
	# Test getting position for each enemy
	var all_positions_valid: bool = true
	var stack_center: Vector2 = stack_system.get_stack_center_position(stack_key)
	print("[TEST] Stack center position: ", stack_center)
	
	for enemy in enemies:
		var pos: Vector2 = stack_system.get_enemy_mini_panel_position(enemy)
		print("[TEST] Enemy ", enemy.instance_id, " mini-panel position: ", pos)
		
		if pos == Vector2.ZERO:
			all_positions_valid = false
			print("[TEST] ERROR: Got ZERO position for enemy ", enemy.instance_id)
	
	if all_positions_valid:
		print("[TEST] Test 3 PASSED: All enemies have valid mini-panel positions")
	else:
		test_passed = false
		test_errors.append("Test 3: Some enemies returned ZERO position")
		print("[TEST] Test 3 FAILED: Invalid positions")
	
	# Cleanup
	stack_system.queue_free()
