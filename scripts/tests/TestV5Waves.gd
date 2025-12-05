extends Node
## TestV5Waves - Unit tests for V5 wave compositions and spawn timing

var tests_passed: int = 0
var tests_failed: int = 0
var current_test: String = ""


func _ready() -> void:
	print("\n========================================")
	print("V5 WAVE SYSTEM TESTS")
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
	# Basic wave tests
	test_wave_count()
	test_all_waves_have_spawns()
	
	# Specific wave tests
	test_wave_1_tutorial()
	test_wave_10_horde()
	test_wave_11_tank()
	test_wave_12_ambush()
	test_wave_20_boss()
	
	# Turn-based spawn tests
	test_turn_based_spawns()
	test_get_spawns_for_turn()
	
	# Wave band tests
	test_wave_bands()
	test_wave_band_names()
	
	# Enemy distribution tests
	test_enemy_counts()


# === Basic Tests ===

func test_wave_count() -> void:
	start_test("Wave count")
	# Can create all 20 waves
	for i: int in range(1, 21):
		var wave: WaveDefinition = WaveDefinition.create_wave(i)
		assert_not_null(wave, "Wave " + str(i) + " should be creatable")
	end_test()


func test_all_waves_have_spawns() -> void:
	start_test("All waves have spawns")
	for i: int in range(1, 21):
		var wave: WaveDefinition = WaveDefinition.create_wave(i)
		assert_true(wave.turn_spawns.size() > 0, "Wave " + str(i) + " should have turn_spawns")
	end_test()


# === Specific Wave Tests ===

func test_wave_1_tutorial() -> void:
	start_test("Wave 1 - Tutorial")
	var wave: WaveDefinition = WaveDefinition.create_wave(1)
	
	assert_equal(wave.wave_name, "Wave 1 - Tutorial", "Should be tutorial wave")
	assert_false(wave.is_elite_wave, "Should not be elite")
	assert_false(wave.is_boss_wave, "Should not be boss")
	
	# Check spawns - should only have weaklings
	var has_weakling: bool = false
	for spawn: Dictionary in wave.turn_spawns:
		if spawn.enemy_id == "weakling":
			has_weakling = true
	assert_true(has_weakling, "Should have weaklings")
	
	# Total count should be 3
	assert_equal(wave.get_total_enemy_count(), 3, "Should have 3 enemies")
	
	end_test()


func test_wave_10_horde() -> void:
	start_test("Wave 10 - Horde wave")
	var wave: WaveDefinition = WaveDefinition.create_wave(10)
	
	assert_true(wave.is_horde_wave, "Should be horde wave")
	assert_true(wave.is_elite_wave, "Should be elite wave")
	
	# Check for channeler
	var has_channeler: bool = false
	for spawn: Dictionary in wave.turn_spawns:
		if spawn.enemy_id == "channeler":
			has_channeler = true
	assert_true(has_channeler, "Wave 10 should introduce Channeler")
	
	end_test()


func test_wave_11_tank() -> void:
	start_test("Wave 11 - Tank introduction")
	var wave: WaveDefinition = WaveDefinition.create_wave(11)
	
	assert_true(wave.is_elite_wave, "Should be elite wave")
	
	# Check for shell titan
	var has_titan: bool = false
	for spawn: Dictionary in wave.turn_spawns:
		if spawn.enemy_id == "shell_titan":
			has_titan = true
	assert_true(has_titan, "Wave 11 should introduce Shell Titan")
	
	end_test()


func test_wave_12_ambush() -> void:
	start_test("Wave 12 - Ambush wave")
	var wave: WaveDefinition = WaveDefinition.create_wave(12)
	
	# Check for stalker in Close ring
	var has_close_stalker: bool = false
	for spawn: Dictionary in wave.turn_spawns:
		if spawn.enemy_id == "stalker" and spawn.ring == BattlefieldState.Ring.CLOSE:
			has_close_stalker = true
	assert_true(has_close_stalker, "Wave 12 should have Stalkers in Close ring")
	
	end_test()


func test_wave_20_boss() -> void:
	start_test("Wave 20 - Boss wave")
	var wave: WaveDefinition = WaveDefinition.create_wave(20)
	
	assert_true(wave.is_boss_wave, "Should be boss wave")
	assert_equal(wave.turn_limit, 8, "Boss wave should have extended turn limit")
	
	# Check for Ember Saint
	var has_boss: bool = false
	for spawn: Dictionary in wave.turn_spawns:
		if spawn.enemy_id == "ember_saint":
			has_boss = true
	assert_true(has_boss, "Wave 20 should have Ember Saint boss")
	
	end_test()


# === Turn-Based Spawn Tests ===

func test_turn_based_spawns() -> void:
	start_test("Turn-based spawns")
	var wave: WaveDefinition = WaveDefinition.create_wave(3)
	
	# Wave 3 should have spawns on turn 1 and turn 3
	var turns_with_spawns: Dictionary = {}
	for spawn: Dictionary in wave.turn_spawns:
		var turn: int = spawn.get("turn", 1)
		turns_with_spawns[turn] = true
	
	assert_true(turns_with_spawns.has(1), "Should have turn 1 spawns")
	assert_true(turns_with_spawns.has(3), "Should have turn 3 spawns")
	
	end_test()


func test_get_spawns_for_turn() -> void:
	start_test("Get spawns for specific turn")
	var wave: WaveDefinition = WaveDefinition.create_wave(7)  # Bomber wave
	
	var turn1_spawns: Array[Dictionary] = wave.get_spawns_for_turn(1)
	var turn5_spawns: Array[Dictionary] = wave.get_spawns_for_turn(5)
	
	assert_true(turn1_spawns.size() > 0, "Should have turn 1 spawns")
	
	# Turn 5 should have bomber
	var has_bomber_turn5: bool = false
	for spawn: Dictionary in turn5_spawns:
		if spawn.enemy_id == "bomber":
			has_bomber_turn5 = true
	assert_true(has_bomber_turn5, "Turn 5 should spawn bomber")
	
	end_test()


# === Wave Band Tests ===

func test_wave_bands() -> void:
	start_test("Wave bands")
	# Test band assignments
	assert_equal(WaveDefinition.get_wave_band(1), 1, "Wave 1 should be band 1")
	assert_equal(WaveDefinition.get_wave_band(3), 1, "Wave 3 should be band 1")
	assert_equal(WaveDefinition.get_wave_band(4), 2, "Wave 4 should be band 2")
	assert_equal(WaveDefinition.get_wave_band(7), 3, "Wave 7 should be band 3")
	assert_equal(WaveDefinition.get_wave_band(10), 4, "Wave 10 should be band 4")
	assert_equal(WaveDefinition.get_wave_band(13), 5, "Wave 13 should be band 5")
	assert_equal(WaveDefinition.get_wave_band(17), 6, "Wave 17 should be band 6")
	assert_equal(WaveDefinition.get_wave_band(20), 6, "Wave 20 should be band 6")
	end_test()


func test_wave_band_names() -> void:
	start_test("Wave band names")
	assert_equal(WaveDefinition.get_wave_band_name(1), "Onboarding", "Band 1 name")
	assert_equal(WaveDefinition.get_wave_band_name(5), "Build Check", "Band 2 name")
	assert_equal(WaveDefinition.get_wave_band_name(8), "Stress Test", "Band 3 name")
	assert_equal(WaveDefinition.get_wave_band_name(11), "Late Game", "Band 4 name")
	assert_equal(WaveDefinition.get_wave_band_name(15), "Endgame", "Band 5 name")
	assert_equal(WaveDefinition.get_wave_band_name(20), "Boss Rush", "Band 6 name")
	end_test()


# === Enemy Distribution Tests ===

func test_enemy_counts() -> void:
	start_test("Enemy counts per wave")
	
	# Early waves should have fewer enemies
	var wave1: WaveDefinition = WaveDefinition.create_wave(1)
	var wave10: WaveDefinition = WaveDefinition.create_wave(10)
	var wave18: WaveDefinition = WaveDefinition.create_wave(18)
	
	var count1: int = wave1.get_total_enemy_count()
	var count10: int = wave10.get_total_enemy_count()
	var count18: int = wave18.get_total_enemy_count()
	
	print("  Wave 1 enemies: ", count1)
	print("  Wave 10 enemies: ", count10)
	print("  Wave 18 enemies: ", count18)
	
	assert_true(count1 < count10, "Wave 10 should have more enemies than wave 1")
	assert_true(count10 < count18, "Wave 18 should have more enemies than wave 10")
	
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


func assert_not_null(value, message: String) -> void:
	if value != null:
		tests_passed += 1
		print("  ✓ ", current_test, ": ", message)
	else:
		tests_failed += 1
		print("  ✗ ", current_test, ": ", message, " (was null)")



