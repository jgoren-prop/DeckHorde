extends Node
## TestV5DamageFormula - Tests V5 damage calculation formula
## Verifies: Final = (Base + Stat Scaling) × Type Multiplier × Global Multiplier × Crit

const CardDef = preload("res://scripts/resources/CardDefinition.gd")
const PlayerStatsClass = preload("res://scripts/resources/PlayerStats.gd")

var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestV5DamageFormula] Starting V5 damage formula tests...")
	await get_tree().process_frame
	
	_test_basic_damage_calculation()
	_test_stat_scaling()
	_test_type_multiplier()
	_test_tier_scaling()
	_test_crit_calculation()
	_test_siege_cannon_example()
	
	print("")
	print("=" .repeat(50))
	print("[TestV5DamageFormula] Tests complete: %d passed, %d failed" % [tests_passed, tests_failed])
	print("=" .repeat(50))
	
	if tests_failed == 0:
		print("[TestV5DamageFormula] RESULT: ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TestV5DamageFormula] RESULT: SOME TESTS FAILED ✗")
		get_tree().quit(1)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  ✓ " + test_name)
		tests_passed += 1
	else:
		print("  ✗ FAILED: " + test_name)
		tests_failed += 1


func _create_test_card() -> CardDef:
	"""Create a basic test card."""
	var card := CardDef.new()
	card.card_id = "test_card"
	card.card_name = "Test Card"
	card.base_damage = 5
	card.damage_type = "kinetic"
	card.categories = ["Kinetic"]
	card.tier = 1
	return card


func _test_basic_damage_calculation() -> void:
	print("\n[Test] Basic Damage Calculation")
	
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	
	var card := _create_test_card()
	card.base_damage = 5
	card.kinetic_scaling = 0  # No scaling
	
	var result: Dictionary = card.calculate_damage(stats)
	
	_assert(result.base == 5, "Base damage is 5")
	_assert(result.scaling_total == 0, "No scaling bonus")
	_assert(result.subtotal == 5, "Subtotal = base + scaling = 5")
	_assert(abs(result.type_mult - 1.0) < 0.01, "Type multiplier at 100%")
	_assert(result.final == 5, "Final damage is 5")


func _test_stat_scaling() -> void:
	print("\n[Test] Stat Scaling")
	
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	stats.kinetic = 10  # 10 flat kinetic
	
	var card := _create_test_card()
	card.base_damage = 2
	card.kinetic_scaling = 100  # 100% of kinetic stat
	
	var result: Dictionary = card.calculate_damage(stats)
	
	# Expected: base 2 + (10 * 100%) = 2 + 10 = 12
	_assert(result.base == 2, "Base damage is 2")
	_assert(result.scaling_total == 10, "Kinetic scaling: 10 * 100% = 10")
	_assert(result.subtotal == 12, "Subtotal: 2 + 10 = 12")
	_assert(result.final == 12, "Final damage is 12")
	
	# Test partial scaling
	var card2 := _create_test_card()
	card2.base_damage = 3
	card2.kinetic_scaling = 80  # 80% of kinetic stat
	
	var result2: Dictionary = card2.calculate_damage(stats)
	
	# Expected: base 3 + (10 * 80%) = 3 + 8 = 11
	_assert(result2.scaling_total == 8, "Kinetic scaling: 10 * 80% = 8")
	_assert(result2.subtotal == 11, "Subtotal: 3 + 8 = 11")


func _test_type_multiplier() -> void:
	print("\n[Test] Type Multiplier")
	
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	stats.kinetic_percent = 130.0  # +30% kinetic damage
	
	var card := _create_test_card()
	card.base_damage = 10
	card.damage_type = "kinetic"
	
	var result: Dictionary = card.calculate_damage(stats)
	
	# Expected: 10 * 1.30 = 13
	_assert(abs(result.type_mult - 1.30) < 0.01, "Type multiplier is 1.30")
	_assert(result.final == 13, "Final: 10 * 1.30 = 13")
	
	# Test thermal type
	stats.thermal_percent = 120.0
	var card2 := _create_test_card()
	card2.base_damage = 10
	card2.damage_type = "thermal"
	
	var result2: Dictionary = card2.calculate_damage(stats)
	_assert(abs(result2.type_mult - 1.20) < 0.01, "Thermal multiplier is 1.20")
	_assert(result2.final == 12, "Final: 10 * 1.20 = 12")


func _test_tier_scaling() -> void:
	print("\n[Test] Tier Scaling")
	
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	stats.kinetic = 10
	
	# Tier 1: Base x1.0, Scaling x1.0
	var card1 := _create_test_card()
	card1.base_damage = 4
	card1.kinetic_scaling = 100
	card1.tier = 1
	
	var result1: Dictionary = card1.calculate_damage(stats)
	# Base: 4 * 1.0 = 4, Scaling: 10 * 100% * 1.0 = 10, Total: 14
	_assert(result1.base == 4, "Tier 1 base: 4 * 1.0 = 4")
	_assert(result1.scaling_total == 10, "Tier 1 scaling: 10 * 100% = 10")
	_assert(result1.final == 14, "Tier 1 final: 14")
	
	# Tier 2: Base x1.5, Scaling x1.25
	var card2 := _create_test_card()
	card2.base_damage = 4
	card2.kinetic_scaling = 100
	card2.tier = 2
	
	var result2: Dictionary = card2.calculate_damage(stats)
	# Base: 4 * 1.5 = 6, Scaling: 10 * 125% = 12, Total: 18
	_assert(result2.base == 6, "Tier 2 base: 4 * 1.5 = 6")
	_assert(result2.scaling_total == 12, "Tier 2 scaling: 10 * 125% = 12")
	_assert(result2.final == 18, "Tier 2 final: 18")
	
	# Tier 3: Base x2.0, Scaling x1.5
	var card3 := _create_test_card()
	card3.base_damage = 4
	card3.kinetic_scaling = 100
	card3.tier = 3
	
	var result3: Dictionary = card3.calculate_damage(stats)
	# Base: 4 * 2.0 = 8, Scaling: 10 * 150% = 15, Total: 23
	_assert(result3.base == 8, "Tier 3 base: 4 * 2.0 = 8")
	_assert(result3.scaling_total == 15, "Tier 3 scaling: 10 * 150% = 15")
	_assert(result3.final == 23, "Tier 3 final: 23")
	
	# Tier 4: Base x2.5, Scaling x1.75
	var card4 := _create_test_card()
	card4.base_damage = 4
	card4.kinetic_scaling = 100
	card4.tier = 4
	
	var result4: Dictionary = card4.calculate_damage(stats)
	# Base: 4 * 2.5 = 10, Scaling: 10 * 175% = 17, Total: 27
	_assert(result4.base == 10, "Tier 4 base: 4 * 2.5 = 10")
	_assert(result4.scaling_total == 17, "Tier 4 scaling: 10 * 175% = 17")
	_assert(result4.final == 27, "Tier 4 final: 27")


func _test_crit_calculation() -> void:
	print("\n[Test] Crit Calculation")
	
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	
	var card := _create_test_card()
	card.base_damage = 10
	
	var result: Dictionary = card.calculate_damage(stats)
	
	# Default crit: 5% chance, 150% damage
	_assert(abs(result.crit_chance - 0.05) < 0.001, "Default crit chance: 5%")
	_assert(abs(result.crit_mult - 1.5) < 0.01, "Default crit mult: 150%")
	
	# Test card-specific crit bonus
	var card2 := _create_test_card()
	card2.base_damage = 10
	card2.crit_chance_bonus = 15.0  # +15% crit chance
	card2.crit_damage_bonus = 50.0  # +50% crit damage
	
	var result2: Dictionary = card2.calculate_damage(stats)
	
	# Should be: 5% + 15% = 20% chance, 150% + 50% = 200% damage
	_assert(abs(result2.crit_chance - 0.20) < 0.001, "Card crit chance: 5% + 15% = 20%")
	_assert(abs(result2.crit_mult - 2.0) < 0.01, "Card crit mult: 150% + 50% = 200%")


func _test_siege_cannon_example() -> void:
	print("\n[Test] Siege Cannon Example from DESIGN_V5")
	
	# From DESIGN_V5.md:
	# Siege Cannon: Base 3 + (80% Kinetic) + (50% ArmorStart)
	# Player has: Kinetic=20, ArmorStart=12, kinetic_percent=+30%
	# Expected: 3 + 16 + 6 = 25, then * 1.30 = 32.5 → 32
	
	var stats := PlayerStatsClass.new()
	stats.reset_to_defaults()
	stats.kinetic = 20
	stats.armor_start = 12
	stats.kinetic_percent = 130.0  # +30%
	
	var siege_cannon := CardDef.new()
	siege_cannon.card_id = "siege_cannon"
	siege_cannon.card_name = "Siege Cannon"
	siege_cannon.base_damage = 3
	siege_cannon.damage_type = "kinetic"
	siege_cannon.categories = ["Fortress", "Volatile"]
	siege_cannon.kinetic_scaling = 80  # 80% of Kinetic
	siege_cannon.armor_start_scaling = 50  # 50% of ArmorStart
	siege_cannon.tier = 1
	
	var result: Dictionary = siege_cannon.calculate_damage(stats)
	
	# Verify breakdown
	_assert(result.base == 3, "Siege Cannon base: 3")
	
	var kinetic_bonus: int = result.breakdown.get("kinetic", {}).get("bonus", 0)
	_assert(kinetic_bonus == 16, "Kinetic scaling: 20 * 80% = 16")
	
	var armor_bonus: int = result.breakdown.get("armor_start", {}).get("bonus", 0)
	_assert(armor_bonus == 6, "ArmorStart scaling: 12 * 50% = 6")
	
	_assert(result.scaling_total == 22, "Total scaling: 16 + 6 = 22")
	_assert(result.subtotal == 25, "Subtotal: 3 + 22 = 25")
	_assert(abs(result.type_mult - 1.30) < 0.01, "Kinetic multiplier: 130%")
	_assert(result.final == 32, "Final: 25 * 1.30 = 32")
	
	print("  [Siege Cannon Breakdown]")
	print("    Base: 3")
	print("    + Kinetic (20 × 80%%): +16")
	print("    + ArmorStart (12 × 50%%): +6")
	print("    = Subtotal: 25")
	print("    × Kinetic Bonus (130%%): ×1.30")
	print("    = Final: 32")



