extends Node
## TestV5Enemies - Unit tests for V5 enemy system and armor mechanic

var tests_passed: int = 0
var tests_failed: int = 0
var current_test: String = ""


func _ready() -> void:
	print("\n========================================")
	print("V5 ENEMY SYSTEM TESTS")
	print("========================================\n")
	
	# Wait for EnemyDatabase to initialize
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
	# Enemy count tests
	test_total_enemy_count()
	test_grunt_enemy_count()
	test_elite_enemy_count()
	test_boss_enemy_count()
	
	# Specific enemy tests
	test_weakling_stats()
	test_husk_stats()
	test_cultist_stats()
	test_spinecrawler_stats()
	test_spitter_stats()
	test_shell_titan_stats()
	test_bomber_stats()
	test_torchbearer_stats()
	test_channeler_stats()
	test_stalker_stats()
	test_armor_reaver_stats()
	test_ember_saint_stats()
	
	# Archetype tests
	test_swarm_archetype()
	test_rusher_archetype()
	test_fast_archetype()
	test_ranged_archetype()
	test_tank_archetype()
	test_bomber_archetype()
	test_buffer_archetype()
	test_spawner_archetype()
	test_ambusher_archetype()
	test_armor_reaver_archetype()
	test_boss_archetype()
	
	# Scaling tests
	test_hp_scaling()
	test_damage_scaling()
	
	# Behavior badge tests
	test_behavior_badges()
	test_behavior_colors()


# === Enemy Count Tests ===

func test_total_enemy_count() -> void:
	start_test("Total enemy count")
	var enemies: Array = EnemyDatabase.get_all_enemies()
	# 6 grunts + 5 elites + 1 boss = 12 total
	assert_equal(enemies.size(), 12, "Should have 12 V5 enemies")
	end_test()


func test_grunt_enemy_count() -> void:
	start_test("Grunt enemy count")
	var grunts: Array = EnemyDatabase.get_enemies_by_type("grunt")
	# Grunts: weakling, husk, cultist, spinecrawler, spitter, bomber
	assert_equal(grunts.size(), 6, "Should have 6 grunt enemies")
	end_test()


func test_elite_enemy_count() -> void:
	start_test("Elite enemy count")
	var elites: Array = EnemyDatabase.get_enemies_by_type("elite")
	# Elites: shell_titan, torchbearer, channeler, stalker, armor_reaver
	assert_equal(elites.size(), 5, "Should have 5 elite enemies")
	end_test()


func test_boss_enemy_count() -> void:
	start_test("Boss enemy count")
	var bosses: Array = EnemyDatabase.get_enemies_by_type("boss")
	# Boss: ember_saint
	assert_equal(bosses.size(), 1, "Should have 1 boss enemy")
	end_test()


# === Specific Enemy Stat Tests ===

func test_weakling_stats() -> void:
	start_test("Weakling stats")
	var enemy = EnemyDatabase.get_enemy("weakling")
	assert_not_null(enemy, "Weakling should exist")
	assert_equal(enemy.base_hp, 3, "Weakling HP should be 3")
	assert_equal(enemy.base_damage, 2, "Weakling damage should be 2")
	assert_equal(enemy.armor, 0, "Weakling armor should be 0")
	assert_equal(enemy.movement_speed, 1, "Weakling speed should be 1")
	assert_equal(enemy.scrap_value, 3, "Weakling scrap should be 3")
	end_test()


func test_husk_stats() -> void:
	start_test("Husk stats")
	var enemy = EnemyDatabase.get_enemy("husk")
	assert_not_null(enemy, "Husk should exist")
	assert_equal(enemy.base_hp, 8, "Husk HP should be 8")
	assert_equal(enemy.base_damage, 4, "Husk damage should be 4")
	assert_equal(enemy.armor, 0, "Husk armor should be 0")
	assert_equal(enemy.scrap_value, 4, "Husk scrap should be 4")
	end_test()


func test_cultist_stats() -> void:
	start_test("Cultist stats")
	var enemy = EnemyDatabase.get_enemy("cultist")
	assert_not_null(enemy, "Cultist should exist")
	assert_equal(enemy.base_hp, 4, "Cultist HP should be 4")
	assert_equal(enemy.base_damage, 2, "Cultist damage should be 2")
	assert_equal(enemy.armor, 0, "Cultist armor should be 0")
	assert_equal(enemy.scrap_value, 2, "Cultist scrap should be 2")
	end_test()


func test_spinecrawler_stats() -> void:
	start_test("Spinecrawler stats")
	var enemy = EnemyDatabase.get_enemy("spinecrawler")
	assert_not_null(enemy, "Spinecrawler should exist")
	assert_equal(enemy.base_hp, 6, "Spinecrawler HP should be 6")
	assert_equal(enemy.base_damage, 3, "Spinecrawler damage should be 3")
	assert_equal(enemy.movement_speed, 2, "Spinecrawler speed should be 2")
	assert_equal(enemy.scrap_value, 5, "Spinecrawler scrap should be 5")
	end_test()


func test_spitter_stats() -> void:
	start_test("Spitter stats")
	var enemy = EnemyDatabase.get_enemy("spitter")
	assert_not_null(enemy, "Spitter should exist")
	assert_equal(enemy.base_hp, 7, "Spitter HP should be 7")
	assert_equal(enemy.base_damage, 3, "Spitter damage should be 3")
	assert_equal(enemy.target_ring, 2, "Spitter should stop at Mid ring")
	assert_equal(enemy.attack_type, "ranged", "Spitter should be ranged")
	end_test()


func test_shell_titan_stats() -> void:
	start_test("Shell Titan stats (V5 armor)")
	var enemy = EnemyDatabase.get_enemy("shell_titan")
	assert_not_null(enemy, "Shell Titan should exist")
	assert_equal(enemy.base_hp, 20, "Shell Titan HP should be 20")
	assert_equal(enemy.base_damage, 6, "Shell Titan damage should be 6")
	assert_equal(enemy.armor, 5, "Shell Titan armor should be 5")
	assert_equal(enemy.is_elite, true, "Shell Titan should be elite")
	assert_equal(enemy.scrap_value, 10, "Shell Titan scrap should be 10")
	end_test()


func test_bomber_stats() -> void:
	start_test("Bomber stats")
	var enemy = EnemyDatabase.get_enemy("bomber")
	assert_not_null(enemy, "Bomber should exist")
	assert_equal(enemy.base_hp, 9, "Bomber HP should be 9")
	assert_equal(enemy.base_damage, 0, "Bomber should have no regular damage")
	assert_equal(enemy.buff_amount, 6, "Bomber explosion to player should be 6")
	assert_equal(enemy.aoe_damage, 4, "Bomber explosion to enemies should be 4")
	assert_equal(enemy.special_ability, "explode_on_death", "Bomber should explode")
	end_test()


func test_torchbearer_stats() -> void:
	start_test("Torchbearer stats")
	var enemy = EnemyDatabase.get_enemy("torchbearer")
	assert_not_null(enemy, "Torchbearer should exist")
	assert_equal(enemy.base_hp, 10, "Torchbearer HP should be 10")
	assert_equal(enemy.buff_amount, 2, "Torchbearer buff should be +2")
	assert_equal(enemy.special_ability, "buff_allies", "Torchbearer should buff")
	assert_equal(enemy.is_elite, true, "Torchbearer should be elite")
	end_test()


func test_channeler_stats() -> void:
	start_test("Channeler stats")
	var enemy = EnemyDatabase.get_enemy("channeler")
	assert_not_null(enemy, "Channeler should exist")
	assert_equal(enemy.base_hp, 12, "Channeler HP should be 12")
	assert_equal(enemy.spawn_enemy_id, "cultist", "Channeler should spawn cultists")
	assert_equal(enemy.spawn_count, 1, "Channeler should spawn 1 per turn")
	assert_equal(enemy.special_ability, "spawn_minions", "Channeler should spawn")
	end_test()


func test_stalker_stats() -> void:
	start_test("Stalker stats")
	var enemy = EnemyDatabase.get_enemy("stalker")
	assert_not_null(enemy, "Stalker should exist")
	assert_equal(enemy.base_hp, 9, "Stalker HP should be 9")
	assert_equal(enemy.base_damage, 5, "Stalker damage should be 5")
	assert_equal(enemy.is_elite, true, "Stalker should be elite")
	end_test()


func test_armor_reaver_stats() -> void:
	start_test("Armor Reaver stats")
	var enemy = EnemyDatabase.get_enemy("armor_reaver")
	assert_not_null(enemy, "Armor Reaver should exist")
	assert_equal(enemy.base_hp, 10, "Armor Reaver HP should be 10")
	assert_equal(enemy.base_damage, 3, "Armor Reaver damage should be 3")
	assert_equal(enemy.armor_shred, 3, "Armor Reaver shred should be 3")
	assert_equal(enemy.special_ability, "armor_shred", "Armor Reaver should shred")
	end_test()


func test_ember_saint_stats() -> void:
	start_test("Ember Saint (boss) stats")
	var enemy = EnemyDatabase.get_enemy("ember_saint")
	assert_not_null(enemy, "Ember Saint should exist")
	assert_equal(enemy.base_hp, 100, "Boss HP should be 100")
	assert_equal(enemy.base_damage, 10, "Boss damage should be 10")
	assert_equal(enemy.armor, 5, "Boss armor should be 5")
	assert_equal(enemy.is_boss, true, "Should be marked as boss")
	assert_equal(enemy.target_ring, 3, "Boss should stay at Far")
	assert_equal(enemy.movement_speed, 0, "Boss should not move")
	assert_equal(enemy.spawn_enemy_id, "bomber", "Boss should spawn bombers")
	end_test()


# === Archetype Tests ===

func test_swarm_archetype() -> void:
	start_test("Swarm archetype")
	var swarm: Array = EnemyDatabase.get_enemies_by_archetype("swarm")
	assert_true(swarm.has("weakling"), "Weakling should be swarm")
	assert_true(swarm.has("cultist"), "Cultist should be swarm")
	end_test()


func test_rusher_archetype() -> void:
	start_test("Rusher archetype")
	var rusher: Array = EnemyDatabase.get_enemies_by_archetype("rusher")
	assert_true(rusher.has("husk"), "Husk should be rusher")
	end_test()


func test_fast_archetype() -> void:
	start_test("Fast archetype")
	var fast: Array = EnemyDatabase.get_enemies_by_archetype("fast")
	assert_true(fast.has("spinecrawler"), "Spinecrawler should be fast")
	end_test()


func test_ranged_archetype() -> void:
	start_test("Ranged archetype")
	var ranged: Array = EnemyDatabase.get_enemies_by_archetype("ranged")
	assert_true(ranged.has("spitter"), "Spitter should be ranged")
	end_test()


func test_tank_archetype() -> void:
	start_test("Tank archetype")
	var tanks: Array = EnemyDatabase.get_enemies_by_archetype("tank")
	assert_true(tanks.has("shell_titan"), "Shell Titan should be tank")
	end_test()


func test_bomber_archetype() -> void:
	start_test("Bomber archetype")
	var bombers: Array = EnemyDatabase.get_enemies_by_archetype("bomber")
	assert_true(bombers.has("bomber"), "Bomber should be bomber archetype")
	end_test()


func test_buffer_archetype() -> void:
	start_test("Buffer archetype")
	var buffers: Array = EnemyDatabase.get_enemies_by_archetype("buffer")
	assert_true(buffers.has("torchbearer"), "Torchbearer should be buffer")
	end_test()


func test_spawner_archetype() -> void:
	start_test("Spawner archetype")
	var spawners: Array = EnemyDatabase.get_enemies_by_archetype("spawner")
	assert_true(spawners.has("channeler"), "Channeler should be spawner")
	end_test()


func test_ambusher_archetype() -> void:
	start_test("Ambusher archetype")
	var ambushers: Array = EnemyDatabase.get_enemies_by_archetype("ambusher")
	assert_true(ambushers.has("stalker"), "Stalker should be ambusher")
	end_test()


func test_armor_reaver_archetype() -> void:
	start_test("Armor Reaver archetype")
	var reavers: Array = EnemyDatabase.get_enemies_by_archetype("armor_reaver")
	assert_true(reavers.has("armor_reaver"), "Armor Reaver should be armor_reaver")
	end_test()


func test_boss_archetype() -> void:
	start_test("Boss archetype")
	var bosses: Array = EnemyDatabase.get_enemies_by_archetype("boss")
	assert_true(bosses.has("ember_saint"), "Ember Saint should be boss archetype")
	end_test()


# === Scaling Tests ===

func test_hp_scaling() -> void:
	start_test("HP scaling")
	var husk = EnemyDatabase.get_enemy("husk")
	var wave1_hp: int = husk.get_scaled_hp(1)
	var wave5_hp: int = husk.get_scaled_hp(5)
	var wave10_hp: int = husk.get_scaled_hp(10)
	
	# Base HP = 8, Scale = 1.0 + (wave-1)*0.15
	# Wave 1: 8 * 1.0 = 8
	# Wave 5: 8 * 1.6 = 12.8 -> 12
	# Wave 10: 8 * 2.35 = 18.8 -> 18
	assert_equal(wave1_hp, 8, "Wave 1 HP should be 8")
	assert_equal(wave5_hp, 12, "Wave 5 HP should be 12")
	assert_equal(wave10_hp, 18, "Wave 10 HP should be 18")
	end_test()


func test_damage_scaling() -> void:
	start_test("Damage scaling")
	var husk = EnemyDatabase.get_enemy("husk")
	var wave1_dmg: int = husk.get_scaled_damage(1)
	var wave5_dmg: int = husk.get_scaled_damage(5)
	var wave10_dmg: int = husk.get_scaled_damage(10)
	
	# Base Damage = 4, Scale = 1.0 + (wave-1)*0.1
	# Wave 1: 4 * 1.0 = 4
	# Wave 5: 4 * 1.4 = 5.6 -> 5
	# Wave 10: 4 * 1.9 = 7.6 -> 7
	assert_equal(wave1_dmg, 4, "Wave 1 damage should be 4")
	assert_equal(wave5_dmg, 5, "Wave 5 damage should be 5")
	assert_equal(wave10_dmg, 7, "Wave 10 damage should be 7")
	end_test()


# === Behavior Badge Tests ===

func test_behavior_badges() -> void:
	start_test("Behavior badges")
	var husk = EnemyDatabase.get_enemy("husk")
	var spinecrawler = EnemyDatabase.get_enemy("spinecrawler")
	var spitter = EnemyDatabase.get_enemy("spitter")
	var shell_titan = EnemyDatabase.get_enemy("shell_titan")
	var bomber = EnemyDatabase.get_enemy("bomber")
	
	assert_equal(husk.get_behavior_badge_icon(), "🏃", "Husk should be rusher")
	assert_equal(spinecrawler.get_behavior_badge_icon(), "⚡", "Spinecrawler should be fast")
	assert_equal(spitter.get_behavior_badge_icon(), "🏹", "Spitter should be ranged")
	assert_equal(shell_titan.get_behavior_badge_icon(), "🛡️", "Shell Titan should be tank")
	assert_equal(bomber.get_behavior_badge_icon(), "💣", "Bomber should be bomber")
	end_test()


func test_behavior_colors() -> void:
	start_test("Behavior colors")
	var husk = EnemyDatabase.get_enemy("husk")
	var color: Color = husk.get_behavior_badge_color()
	
	# Rusher should be red-ish
	assert_true(color.r > 0.5, "Rusher color should have red")
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


func assert_not_null(value, message: String) -> void:
	if value != null:
		tests_passed += 1
		print("  ✓ ", current_test, ": ", message)
	else:
		tests_failed += 1
		print("  ✗ ", current_test, ": ", message, " (was null)")

