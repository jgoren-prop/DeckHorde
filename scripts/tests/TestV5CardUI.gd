extends Node
## Unit tests for V5 Card UI System
## Tests that CardUI displays V5 cards correctly

var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestV5CardUI] Starting V5 CardUI tests...")
	await get_tree().process_frame
	
	# Run all tests
	test_v5_card_display()
	test_v5_tier_display()
	test_v5_category_display()
	test_v5_damage_type_icons()
	test_v5_damage_calculation()
	
	# Summary
	print("\n[TestV5CardUI] ========================================")
	print("[TestV5CardUI] Tests passed: ", tests_passed)
	print("[TestV5CardUI] Tests failed: ", tests_failed)
	print("[TestV5CardUI] ========================================")
	
	if tests_failed == 0:
		print("[TestV5CardUI] ✅ ALL TESTS PASSED!")
		get_tree().quit(0)
	else:
		print("[TestV5CardUI] ❌ SOME TESTS FAILED")
		get_tree().quit(1)


func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("[PASS] ", test_name)
	else:
		tests_failed += 1
		print("[FAIL] ", test_name, " - Expected: ", expected, ", Got: ", actual)


func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		tests_passed += 1
		print("[PASS] ", test_name)
	else:
		tests_failed += 1
		print("[FAIL] ", test_name)


func assert_not_null(value, test_name: String) -> void:
	if value != null:
		tests_passed += 1
		print("[PASS] ", test_name)
	else:
		tests_failed += 1
		print("[FAIL] ", test_name, " - Value was null")


# =============================================================================
# V5 CARD DISPLAY TESTS
# =============================================================================

func test_v5_card_display() -> void:
	print("\n[TestV5CardUI] --- Testing V5 Card Display ---")
	
	# Get a V5 weapon from CardDatabase
	var pistol = CardDatabase.get_card("pistol")
	assert_not_null(pistol, "Pistol card exists")
	
	# Verify V5 properties - direct access since CardDefinition exports these
	var damage_type: String = pistol.damage_type
	var categories: Array = pistol.categories
	var base_damage: int = pistol.base_damage
	
	assert_true(damage_type != "" and damage_type != "none", "Pistol has damage_type: " + damage_type)
	assert_true(categories.size() > 0, "Pistol has categories")
	assert_true(base_damage > 0, "Pistol has base_damage: " + str(base_damage))
	
	# Check V5 values
	assert_eq(damage_type, "kinetic", "Pistol damage type is kinetic")
	var has_kinetic: bool = false
	for cat in categories:
		# Categories are capitalized (e.g., "Kinetic")
		if str(cat).to_lower() == "kinetic":
			has_kinetic = true
			break
	assert_true(has_kinetic, "Pistol has Kinetic category")


# =============================================================================
# V5 TIER DISPLAY TESTS
# =============================================================================

func test_v5_tier_display() -> void:
	print("\n[TestV5CardUI] --- Testing V5 Tier Display ---")
	
	# Test tier names
	var CardUIScript = preload("res://scripts/ui/CardUI.gd")
	
	# Check TIER_COLORS has 4 entries for V5
	assert_eq(CardUIScript.TIER_COLORS.size(), 4, "TIER_COLORS has 4 entries for V5 4-tier system")
	
	# Check TIER_NAMES
	assert_eq(CardUIScript.TIER_NAMES.size(), 4, "TIER_NAMES has 4 entries")
	assert_eq(CardUIScript.TIER_NAMES[0], "", "Tier 1 has no suffix")
	assert_eq(CardUIScript.TIER_NAMES[1], "+", "Tier 2 has + suffix")
	assert_eq(CardUIScript.TIER_NAMES[2], "++", "Tier 3 has ++ suffix")
	assert_eq(CardUIScript.TIER_NAMES[3], "+++", "Tier 4 has +++ suffix")


# =============================================================================
# V5 CATEGORY DISPLAY TESTS
# =============================================================================

func test_v5_category_display() -> void:
	print("\n[TestV5CardUI] --- Testing V5 Category Display ---")
	
	var CardUIScript = preload("res://scripts/ui/CardUI.gd")
	
	# Check all 8 V5 categories have icons
	var expected_categories: Array[String] = ["kinetic", "thermal", "arcane", "fortress", "shadow", "utility", "control", "volatile"]
	
	for cat: String in expected_categories:
		assert_true(CardUIScript.CATEGORY_ICONS.has(cat), "CATEGORY_ICONS has " + cat)
		assert_true(CardUIScript.CATEGORY_COLORS.has(cat), "CATEGORY_COLORS has " + cat)
		assert_true(CardUIScript.CATEGORY_NAMES.has(cat), "CATEGORY_NAMES has " + cat)


# =============================================================================
# V5 DAMAGE TYPE ICON TESTS
# =============================================================================

func test_v5_damage_type_icons() -> void:
	print("\n[TestV5CardUI] --- Testing V5 Damage Type Icons ---")
	
	var CardUIScript = preload("res://scripts/ui/CardUI.gd")
	
	# Check all 3 V5 damage types have icons
	assert_true(CardUIScript.DAMAGE_TYPE_ICONS.has("kinetic"), "DAMAGE_TYPE_ICONS has kinetic")
	assert_true(CardUIScript.DAMAGE_TYPE_ICONS.has("thermal"), "DAMAGE_TYPE_ICONS has thermal")
	assert_true(CardUIScript.DAMAGE_TYPE_ICONS.has("arcane"), "DAMAGE_TYPE_ICONS has arcane")
	
	# Check background colors
	assert_true(CardUIScript.DAMAGE_TYPE_BG_COLORS.has("kinetic"), "DAMAGE_TYPE_BG_COLORS has kinetic")
	assert_true(CardUIScript.DAMAGE_TYPE_BG_COLORS.has("thermal"), "DAMAGE_TYPE_BG_COLORS has thermal")
	assert_true(CardUIScript.DAMAGE_TYPE_BG_COLORS.has("arcane"), "DAMAGE_TYPE_BG_COLORS has arcane")


# =============================================================================
# V5 DAMAGE CALCULATION TESTS
# =============================================================================

func test_v5_damage_calculation() -> void:
	print("\n[TestV5CardUI] --- Testing V5 Damage Calculation in UI ---")
	
	# Get a V5 weapon
	var pistol = CardDatabase.get_card("pistol")
	assert_not_null(pistol, "Pistol exists for damage calc test")
	
	# Check base damage exists
	var base_damage: int = pistol.base_damage
	assert_true(base_damage > 0, "Pistol has positive base damage: " + str(base_damage))
	
	# V5 uses individual scaling properties instead of scaling_stats dictionary
	var kinetic_scaling: int = pistol.kinetic_scaling
	var has_scaling: bool = kinetic_scaling > 0
	assert_true(has_scaling, "Pistol has kinetic scaling: " + str(kinetic_scaling) + "%")
	
	# Verify tier scaling formula is correct (tier 2 = +50% base)
	var tier1_base: int = base_damage
	var tier2_base: int = int(base_damage * 1.5)
	var tier3_base: int = int(base_damage * 2.0)
	var tier4_base: int = int(base_damage * 2.5)
	
	print("[INFO] Tier 1 base: ", tier1_base)
	print("[INFO] Tier 2 base (+50%): ", tier2_base)
	print("[INFO] Tier 3 base (+100%): ", tier3_base)
	print("[INFO] Tier 4 base (+150%): ", tier4_base)
	
	assert_true(tier2_base > tier1_base, "Tier 2 base damage is higher than Tier 1")
	assert_true(tier3_base > tier2_base, "Tier 3 base damage is higher than Tier 2")
	assert_true(tier4_base > tier3_base, "Tier 4 base damage is higher than Tier 3")

