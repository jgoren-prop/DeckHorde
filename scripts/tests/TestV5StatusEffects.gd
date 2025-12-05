extends Node
## TestV5StatusEffects - Unit tests for V5 Hex, Burn, Barrier status effects

var tests_passed: int = 0
var tests_failed: int = 0
var current_test: String = ""


func _ready() -> void:
	print("\n========================================")
	print("V5 STATUS EFFECTS TESTS")
	print("========================================\n")
	
	# Wait for autoloads to initialize
	await get_tree().process_frame
	
	run_all_tests()
	
	print("\n========================================")
	print("RESULTS: ", tests_passed, " passed, ", tests_failed, " failed")
	print("========================================\n")
	
	if tests_failed > 0:
		print("[TEST] RESULT: FAILED ✗")
		get_tree().quit(1)
	else:
		print("[TEST] RESULT: PASSED ✓")
		get_tree().quit(0)


func run_all_tests() -> void:
	# Hex tests
	test_hex_stacking()
	test_hex_triggers_on_damage()
	test_hex_consumed_on_trigger()
	test_hex_potency_scaling()
	test_hex_blocked_by_armor()
	
	# Burn tests
	test_burn_stacking()
	test_burn_tick_damage()
	test_burn_reduces_by_one()
	test_burn_potency_scaling()
	test_burn_expires_at_zero()
	
	# Armor tests
	test_armor_absorbs_hit()
	test_armor_removes_one_per_hit()
	test_multi_hit_strips_armor()
	
	# Barrier stat tests
	test_barrier_damage_bonus()
	test_barrier_uses_bonus()


# === Helper to create test enemy ===

func create_test_enemy(hp: int = 20, armor: int = 0) -> EnemyInstance:
	var enemy := EnemyInstance.new()
	enemy.enemy_id = "test_enemy"
	enemy.current_hp = hp
	enemy.max_hp = hp
	enemy.armor = armor
	return enemy


# === Hex Tests ===

func test_hex_stacking() -> void:
	start_test("Hex stacking")
	var enemy := create_test_enemy()
	
	enemy.apply_status("hex", 5)
	assert_equal(enemy.get_status_value("hex"), 5, "First hex should be 5")
	
	enemy.apply_status("hex", 3)
	assert_equal(enemy.get_status_value("hex"), 8, "Hex should stack to 8")
	
	end_test()


func test_hex_triggers_on_damage() -> void:
	start_test("Hex triggers on damage")
	var enemy := create_test_enemy(20)
	
	# Apply 5 hex
	enemy.apply_status("hex", 5)
	
	# Reset potency to 0 for clean test
	RunManager.player_stats.hex_potency = 0.0
	
	# Deal 3 base damage - should trigger hex for +5
	var result: Dictionary = enemy.take_damage(3)
	
	assert_true(result.hex_triggered, "Hex should have triggered")
	assert_equal(result.hex_bonus, 5, "Hex bonus should be 5")
	assert_equal(result.total_damage, 8, "Total damage should be 3 + 5 = 8")
	assert_equal(enemy.current_hp, 12, "HP should be 20 - 8 = 12")
	
	end_test()


func test_hex_consumed_on_trigger() -> void:
	start_test("Hex consumed on trigger")
	var enemy := create_test_enemy()
	
	enemy.apply_status("hex", 5)
	assert_true(enemy.has_status("hex"), "Should have hex")
	
	RunManager.player_stats.hex_potency = 0.0
	enemy.take_damage(1)
	
	assert_false(enemy.has_status("hex"), "Hex should be consumed after trigger")
	
	end_test()


func test_hex_potency_scaling() -> void:
	start_test("Hex potency scaling")
	var enemy := create_test_enemy(100)
	
	# Apply 10 hex stacks
	enemy.apply_status("hex", 10)
	
	# Set hex potency to +50%
	RunManager.player_stats.hex_potency = 50.0
	
	# Deal 0 base damage to isolate hex effect
	var result: Dictionary = enemy.take_damage(0)
	
	# Hex bonus should be 10 * 1.5 = 15
	assert_equal(result.hex_bonus, 15, "Hex bonus with 50% potency should be 15")
	assert_equal(result.total_damage, 15, "Total damage should be 15")
	
	# Reset
	RunManager.player_stats.hex_potency = 0.0
	
	end_test()


func test_hex_blocked_by_armor() -> void:
	start_test("Hex bonus blocked by armor")
	var enemy := create_test_enemy(20, 2)  # 2 armor
	
	# Apply 10 hex
	enemy.apply_status("hex", 10)
	
	RunManager.player_stats.hex_potency = 0.0
	
	# Deal damage - should be blocked by armor
	var result: Dictionary = enemy.take_damage(5)
	
	# Hex still triggers but damage is blocked
	assert_true(result.hex_triggered, "Hex should trigger")
	assert_true(result.armor_absorbed, "Armor should absorb")
	assert_equal(result.total_damage, 0, "No damage dealt due to armor")
	assert_equal(enemy.current_hp, 20, "HP unchanged")
	assert_equal(enemy.armor, 1, "Armor should be 1")
	
	end_test()


# === Burn Tests ===

func test_burn_stacking() -> void:
	start_test("Burn stacking")
	var enemy := create_test_enemy()
	
	enemy.apply_status("burn", 3)
	assert_equal(enemy.get_status_value("burn"), 3, "First burn should be 3")
	
	enemy.apply_status("burn", 2)
	assert_equal(enemy.get_status_value("burn"), 5, "Burn should stack to 5")
	
	end_test()


func test_burn_tick_damage() -> void:
	start_test("Burn tick damage")
	var enemy := create_test_enemy(20)
	
	enemy.apply_status("burn", 4)
	
	# Reset potency to 0
	RunManager.player_stats.burn_potency = 0.0
	
	var result: Dictionary = enemy.tick_status_effects()
	
	assert_equal(result.burn_damage, 4, "Burn tick should deal 4 damage")
	assert_equal(enemy.current_hp, 16, "HP should be 20 - 4 = 16")
	
	end_test()


func test_burn_reduces_by_one() -> void:
	start_test("Burn reduces by 1 each tick")
	var enemy := create_test_enemy(100)
	
	enemy.apply_status("burn", 3)
	
	RunManager.player_stats.burn_potency = 0.0
	
	# First tick
	enemy.tick_status_effects()
	assert_equal(enemy.get_status_value("burn"), 2, "Burn should be 2 after first tick")
	
	# Second tick
	enemy.tick_status_effects()
	assert_equal(enemy.get_status_value("burn"), 1, "Burn should be 1 after second tick")
	
	# Third tick
	enemy.tick_status_effects()
	assert_false(enemy.has_status("burn"), "Burn should expire after third tick")
	
	end_test()


func test_burn_potency_scaling() -> void:
	start_test("Burn potency scaling")
	var enemy := create_test_enemy(100)
	
	enemy.apply_status("burn", 4)
	
	# Set burn potency to +25%
	RunManager.player_stats.burn_potency = 25.0
	
	var result: Dictionary = enemy.tick_status_effects()
	
	# Burn damage should be 4 * 1.25 = 5
	assert_equal(result.burn_damage, 5, "Burn tick with 25% potency should deal 5")
	assert_equal(enemy.current_hp, 95, "HP should be 100 - 5 = 95")
	
	# Reset
	RunManager.player_stats.burn_potency = 0.0
	
	end_test()


func test_burn_expires_at_zero() -> void:
	start_test("Burn expires at zero stacks")
	var enemy := create_test_enemy(100)
	
	enemy.apply_status("burn", 1)
	assert_true(enemy.has_status("burn"), "Should have burn")
	
	RunManager.player_stats.burn_potency = 0.0
	
	var result: Dictionary = enemy.tick_status_effects()
	
	assert_true("burn" in result.effects_expired, "Burn should be in expired effects")
	assert_false(enemy.has_status("burn"), "Burn should be removed")
	
	end_test()


# === Armor Tests ===

func test_armor_absorbs_hit() -> void:
	start_test("V5 armor absorbs hit completely")
	var enemy := create_test_enemy(20, 3)  # 3 armor
	
	var result: Dictionary = enemy.take_damage(10)
	
	assert_true(result.armor_absorbed, "Armor should absorb")
	assert_equal(result.total_damage, 0, "No damage dealt")
	assert_equal(enemy.current_hp, 20, "HP unchanged")
	assert_equal(enemy.armor, 2, "Armor should be 2")
	
	end_test()


func test_armor_removes_one_per_hit() -> void:
	start_test("Armor removes 1 per hit")
	var enemy := create_test_enemy(20, 3)
	
	# First hit
	enemy.take_damage(5)
	assert_equal(enemy.armor, 2, "Armor should be 2 after first hit")
	
	# Second hit
	enemy.take_damage(5)
	assert_equal(enemy.armor, 1, "Armor should be 1 after second hit")
	
	# Third hit
	enemy.take_damage(5)
	assert_equal(enemy.armor, 0, "Armor should be 0 after third hit")
	
	# Fourth hit - no armor, damage goes through
	var result: Dictionary = enemy.take_damage(5)
	assert_false(result.armor_absorbed, "No armor to absorb")
	assert_equal(result.total_damage, 5, "5 damage dealt")
	assert_equal(enemy.current_hp, 15, "HP should be 20 - 5 = 15")
	
	end_test()


func test_multi_hit_strips_armor() -> void:
	start_test("Multi-hit strips armor efficiently")
	var enemy := create_test_enemy(20, 3)
	
	# 5 hits of 2 damage each
	var result: Dictionary = enemy.take_multi_hit_damage(2, 5)
	
	# First 3 hits strip armor, last 2 deal damage (2 × 2 = 4)
	assert_equal(result.armor_stripped, 3, "Should strip 3 armor")
	assert_equal(result.hits_dealt, 2, "2 hits should deal damage")
	assert_equal(result.total_damage, 4, "Total damage should be 4")
	assert_equal(enemy.current_hp, 16, "HP should be 20 - 4 = 16")
	
	end_test()


# === Barrier Stat Tests ===

func test_barrier_damage_bonus() -> void:
	start_test("Barrier damage bonus stat")
	# Test that barrier_damage_bonus is tracked in PlayerStats
	var initial_bonus: int = RunManager.player_stats.barrier_damage_bonus
	
	RunManager.player_stats.apply_modifier("barrier_damage_bonus", 3)
	assert_equal(RunManager.player_stats.barrier_damage_bonus, initial_bonus + 3, "Barrier damage bonus should increase by 3")
	
	# Reset
	RunManager.player_stats.barrier_damage_bonus = initial_bonus
	
	end_test()


func test_barrier_uses_bonus() -> void:
	start_test("Barrier uses bonus stat")
	# Test that barrier_uses_bonus is tracked in PlayerStats
	var initial_bonus: int = RunManager.player_stats.barrier_uses_bonus
	
	RunManager.player_stats.apply_modifier("barrier_uses_bonus", 2)
	assert_equal(RunManager.player_stats.barrier_uses_bonus, initial_bonus + 2, "Barrier uses bonus should increase by 2")
	
	# Reset
	RunManager.player_stats.barrier_uses_bonus = initial_bonus
	
	end_test()


# === Test Helpers ===

func start_test(name: String) -> void:
	current_test = name


func end_test() -> void:
	pass


func assert_equal(actual, expected, message: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("  ✓ ", current_test, ": ", message)
	else:
		tests_failed += 1
		print("  ✗ ", current_test, ": ", message)
		print("    Expected: ", expected, ", Got: ", actual)


func assert_true(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("  ✓ ", current_test, ": ", message)
	else:
		tests_failed += 1
		print("  ✗ ", current_test, ": ", message)


func assert_false(condition: bool, message: String) -> void:
	if not condition:
		tests_passed += 1
		print("  ✓ ", current_test, ": ", message)
	else:
		tests_failed += 1
		print("  ✗ ", current_test, ": ", message)

