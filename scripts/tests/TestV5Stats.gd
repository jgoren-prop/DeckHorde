extends Node
## TestV5Stats - Unit tests for V5 PlayerStats and TagConstants
## Run via: scenes/tests/TestV5Stats.tscn

const PlayerStatsClass = preload("res://scripts/resources/PlayerStats.gd")
const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")

var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestV5Stats] Starting V5 stat system tests...")
	await get_tree().process_frame
	
	_test_default_stats()
	_test_flat_damage_stats()
	_test_percentage_multipliers()
	_test_crit_stats()
	_test_stat_modification()
	_test_family_buff_tiers()
	_test_category_helpers()
	_test_damage_type_helpers()
	
	print("")
	print("=" .repeat(50))
	print("[TestV5Stats] Tests complete: %d passed, %d failed" % [tests_passed, tests_failed])
	print("=" .repeat(50))
	
	if tests_failed == 0:
		print("[TestV5Stats] RESULT: ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TestV5Stats] RESULT: SOME TESTS FAILED ✗")
		get_tree().quit(1)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  ✓ " + test_name)
		tests_passed += 1
	else:
		print("  ✗ FAILED: " + test_name)
		tests_failed += 1


func _test_default_stats() -> void:
	print("\n[Test] Default V5 Stats")
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	
	# V5 Flat damage stats default to 0
	_assert(stats.kinetic == 0, "kinetic defaults to 0")
	_assert(stats.thermal == 0, "thermal defaults to 0")
	_assert(stats.arcane == 0, "arcane defaults to 0")
	
	# V5 Percentage multipliers default to 100%
	_assert(stats.kinetic_percent == 100.0, "kinetic_percent defaults to 100%")
	_assert(stats.thermal_percent == 100.0, "thermal_percent defaults to 100%")
	_assert(stats.arcane_percent == 100.0, "arcane_percent defaults to 100%")
	_assert(stats.damage_percent == 100.0, "damage_percent defaults to 100%")
	
	# V5 Crit stats
	_assert(stats.crit_chance == 5.0, "crit_chance defaults to 5%")
	_assert(stats.crit_damage == 150.0, "crit_damage defaults to 150%")
	
	# V5 Economy stats
	_assert(stats.draw_per_turn == 5, "draw_per_turn defaults to 5")
	_assert(stats.energy_per_turn == 3, "energy_per_turn defaults to 3")
	_assert(stats.hand_size == 7, "hand_size defaults to 7")
	_assert(stats.max_hp == 50, "max_hp defaults to 50")


func _test_flat_damage_stats() -> void:
	print("\n[Test] Flat Damage Stats")
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	
	# Test getting flat stats
	_assert(stats.get_flat_damage_stat("kinetic") == 0, "get_flat_damage_stat kinetic")
	_assert(stats.get_flat_damage_stat("thermal") == 0, "get_flat_damage_stat thermal")
	_assert(stats.get_flat_damage_stat("arcane") == 0, "get_flat_damage_stat arcane")
	
	# Modify and test
	stats.kinetic = 10
	stats.thermal = 5
	stats.arcane = 8
	
	_assert(stats.get_flat_damage_stat("kinetic") == 10, "kinetic after modification")
	_assert(stats.get_flat_damage_stat("thermal") == 5, "thermal after modification")
	_assert(stats.get_flat_damage_stat("arcane") == 8, "arcane after modification")


func _test_percentage_multipliers() -> void:
	print("\n[Test] Percentage Multipliers")
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	
	# Test multiplier getters (100% = 1.0)
	_assert(abs(stats.get_kinetic_multiplier() - 1.0) < 0.001, "kinetic multiplier at 100%")
	_assert(abs(stats.get_thermal_multiplier() - 1.0) < 0.001, "thermal multiplier at 100%")
	_assert(abs(stats.get_damage_multiplier() - 1.0) < 0.001, "damage multiplier at 100%")
	
	# Test type multiplier helper
	_assert(abs(stats.get_type_multiplier("kinetic") - 1.0) < 0.001, "get_type_multiplier kinetic")
	_assert(abs(stats.get_type_multiplier("thermal") - 1.0) < 0.001, "get_type_multiplier thermal")
	_assert(abs(stats.get_type_multiplier("arcane") - 1.0) < 0.001, "get_type_multiplier arcane")
	
	# Modify and test
	stats.kinetic_percent = 130.0  # +30%
	_assert(abs(stats.get_kinetic_multiplier() - 1.3) < 0.001, "kinetic multiplier at 130%")


func _test_crit_stats() -> void:
	print("\n[Test] Crit Stats")
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	
	# Test crit chance (5% = 0.05)
	_assert(abs(stats.get_crit_chance() - 0.05) < 0.001, "crit chance 5% = 0.05")
	
	# Test crit damage (150% = 1.5)
	_assert(abs(stats.get_crit_multiplier() - 1.5) < 0.001, "crit damage 150% = 1.5")
	
	# Modify and test
	stats.crit_chance = 20.0
	stats.crit_damage = 200.0
	_assert(abs(stats.get_crit_chance() - 0.20) < 0.001, "crit chance 20%")
	_assert(abs(stats.get_crit_multiplier() - 2.0) < 0.001, "crit damage 200%")


func _test_stat_modification() -> void:
	print("\n[Test] Stat Modification")
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	
	# Test apply_modifier for V5 stats
	stats.apply_modifier("kinetic", 5)
	_assert(stats.kinetic == 5, "apply_modifier kinetic +5")
	
	stats.apply_modifier("kinetic_percent", 15.0)
	_assert(stats.kinetic_percent == 115.0, "apply_modifier kinetic_percent +15")
	
	stats.apply_modifier("crit_chance", 10.0)
	_assert(stats.crit_chance == 15.0, "apply_modifier crit_chance +10")
	
	stats.apply_modifier("max_hp", 20)
	_assert(stats.max_hp == 70, "apply_modifier max_hp +20")
	
	# Test apply_modifiers with dictionary
	stats.apply_modifiers({
		"thermal": 3,
		"arcane": 7,
		"damage_percent": 10.0,
	})
	_assert(stats.thermal == 3, "apply_modifiers thermal")
	_assert(stats.arcane == 7, "apply_modifiers arcane")
	_assert(stats.damage_percent == 110.0, "apply_modifiers damage_percent")


func _test_family_buff_tiers() -> void:
	print("\n[Test] Family Buff Tiers")
	
	# Test tier thresholds
	_assert(TagConstantsClass.get_family_buff_tier(0) == 0, "0 cards = tier 0")
	_assert(TagConstantsClass.get_family_buff_tier(2) == 0, "2 cards = tier 0")
	_assert(TagConstantsClass.get_family_buff_tier(3) == 1, "3 cards = tier 1")
	_assert(TagConstantsClass.get_family_buff_tier(5) == 1, "5 cards = tier 1")
	_assert(TagConstantsClass.get_family_buff_tier(6) == 2, "6 cards = tier 2")
	_assert(TagConstantsClass.get_family_buff_tier(8) == 2, "8 cards = tier 2")
	_assert(TagConstantsClass.get_family_buff_tier(9) == 3, "9 cards = tier 3")
	_assert(TagConstantsClass.get_family_buff_tier(15) == 3, "15 cards = tier 3")
	
	# Test Kinetic family buff values
	_assert(TagConstantsClass.get_family_buff_value("Kinetic", 1) == 3, "Kinetic tier 1 = +3")
	_assert(TagConstantsClass.get_family_buff_value("Kinetic", 2) == 6, "Kinetic tier 2 = +6")
	_assert(TagConstantsClass.get_family_buff_value("Kinetic", 3) == 10, "Kinetic tier 3 = +10")
	
	# Test Shadow family buff (crit)
	_assert(TagConstantsClass.get_family_buff_value("Shadow", 1) == 5, "Shadow tier 1 = +5% crit")
	_assert(TagConstantsClass.get_family_buff_value("Shadow", 2) == 10, "Shadow tier 2 = +10% crit")
	_assert(TagConstantsClass.get_family_buff_value("Shadow", 3) == 15, "Shadow tier 3 = +15% crit")
	
	# Test buff stat names
	_assert(TagConstantsClass.get_family_buff_stat("Kinetic") == "kinetic", "Kinetic buff stat")
	_assert(TagConstantsClass.get_family_buff_stat("Shadow") == "crit_chance", "Shadow buff stat")
	_assert(TagConstantsClass.get_family_buff_stat("Volatile") == "max_hp", "Volatile buff stat")


func _test_category_helpers() -> void:
	print("\n[Test] Category Helpers")
	
	# Test valid categories
	_assert(TagConstantsClass.is_valid_category("Kinetic"), "Kinetic is valid category")
	_assert(TagConstantsClass.is_valid_category("Shadow"), "Shadow is valid category")
	_assert(TagConstantsClass.is_valid_category("Volatile"), "Volatile is valid category")
	_assert(not TagConstantsClass.is_valid_category("invalid"), "invalid is not valid category")
	
	# Test category icons
	_assert(TagConstantsClass.get_category_icon("Kinetic") == "🔫", "Kinetic icon")
	_assert(TagConstantsClass.get_category_icon("Thermal") == "🔥", "Thermal icon")
	_assert(TagConstantsClass.get_category_icon("Arcane") == "✨", "Arcane icon")
	
	# Test category colors exist
	var kinetic_color: Color = TagConstantsClass.get_category_color("Kinetic")
	_assert(kinetic_color != Color.BLACK, "Kinetic color exists")


func _test_damage_type_helpers() -> void:
	print("\n[Test] Damage Type Helpers")
	
	# Test valid damage types
	_assert(TagConstantsClass.is_valid_damage_type("kinetic"), "kinetic is valid damage type")
	_assert(TagConstantsClass.is_valid_damage_type("thermal"), "thermal is valid damage type")
	_assert(TagConstantsClass.is_valid_damage_type("arcane"), "arcane is valid damage type")
	_assert(not TagConstantsClass.is_valid_damage_type("invalid"), "invalid is not valid damage type")
	
	# Test damage type icons
	_assert(TagConstantsClass.get_damage_type_icon("kinetic") == "🔫", "kinetic damage icon")
	_assert(TagConstantsClass.get_damage_type_icon("thermal") == "🔥", "thermal damage icon")
	_assert(TagConstantsClass.get_damage_type_icon("arcane") == "✨", "arcane damage icon")



