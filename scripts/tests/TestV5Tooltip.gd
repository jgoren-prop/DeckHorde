extends Node
## Unit tests for V5 Damage Tooltip System

var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestV5Tooltip] Starting V5 tooltip tests...")
	await get_tree().process_frame
	
	# Run all tests
	test_tooltip_scene_exists()
	test_tooltip_calculation()
	test_tooltip_effects()
	
	# Summary
	print("\n[TestV5Tooltip] ========================================")
	print("[TestV5Tooltip] Tests passed: ", tests_passed)
	print("[TestV5Tooltip] Tests failed: ", tests_failed)
	print("[TestV5Tooltip] ========================================")
	
	if tests_failed == 0:
		print("[TestV5Tooltip] ✅ ALL TESTS PASSED!")
		get_tree().quit(0)
	else:
		print("[TestV5Tooltip] ❌ SOME TESTS FAILED")
		get_tree().quit(1)


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
# TOOLTIP TESTS
# =============================================================================

func test_tooltip_scene_exists() -> void:
	print("\n[TestV5Tooltip] --- Testing Tooltip Scene ---")
	
	# Check that tooltip scene can be loaded
	var tooltip_scene = load("res://scenes/ui/DamageTooltip.tscn")
	assert_not_null(tooltip_scene, "DamageTooltip scene can be loaded")
	
	# Instantiate and verify nodes exist
	var tooltip = tooltip_scene.instantiate()
	assert_not_null(tooltip, "DamageTooltip can be instantiated")
	
	# Check required nodes exist
	assert_true(tooltip.has_node("Background"), "Tooltip has Background node")
	assert_true(tooltip.has_node("Background/Content"), "Tooltip has Content node")
	assert_true(tooltip.has_node("Background/Content/TitleLabel"), "Tooltip has TitleLabel")
	assert_true(tooltip.has_node("Background/Content/BreakdownLabel"), "Tooltip has BreakdownLabel")
	assert_true(tooltip.has_node("Background/Content/EffectsLabel"), "Tooltip has EffectsLabel")
	assert_true(tooltip.has_node("Background/Content/CloseButton"), "Tooltip has CloseButton")
	
	tooltip.queue_free()


func test_tooltip_calculation() -> void:
	print("\n[TestV5Tooltip] --- Testing Tooltip Calculations ---")
	
	# Get a weapon with scaling
	var pistol = CardDatabase.get_card("pistol")
	assert_not_null(pistol, "Pistol card exists for tooltip test")
	
	# Check card has base_damage for tooltip to calculate
	assert_true(pistol.base_damage > 0, "Pistol has base_damage for tooltip: " + str(pistol.base_damage))
	
	# Check card has kinetic_scaling for tooltip to show
	assert_true(pistol.kinetic_scaling > 0, "Pistol has kinetic_scaling for tooltip: " + str(pistol.kinetic_scaling) + "%")
	
	# Check damage type exists for tooltip multiplier section
	assert_true(pistol.damage_type == "kinetic", "Pistol has damage_type for tooltip")
	
	# Check crit stats exist for tooltip
	var crit_chance: float = 5.0 + pistol.crit_chance_bonus
	var crit_damage: float = 150.0 + pistol.crit_damage_bonus
	assert_true(crit_chance >= 5.0, "Pistol crit chance is at least base: " + str(crit_chance) + "%")
	assert_true(crit_damage >= 150.0, "Pistol crit damage is at least base: " + str(crit_damage) + "%")


func test_tooltip_effects() -> void:
	print("\n[TestV5Tooltip] --- Testing Tooltip Effect Display ---")
	
	# Get a card with hex effect
	var hex_bolt = CardDatabase.get_card("hex_bolt")
	assert_not_null(hex_bolt, "Hex Bolt card exists for tooltip test")
	
	# Check hex_stacks or hex_damage exists
	var hex_stacks: int = hex_bolt.hex_stacks if hex_bolt.get("hex_stacks") else hex_bolt.hex_damage
	assert_true(hex_stacks > 0, "Hex Bolt has hex stacks for tooltip: " + str(hex_stacks))
	
	# Get a card with burn effect
	var frag_grenade = CardDatabase.get_card("frag_grenade")
	assert_not_null(frag_grenade, "Frag Grenade card exists for tooltip test")
	
	# Check burn_stacks or burn_damage exists
	var burn_stacks: int = frag_grenade.burn_stacks if frag_grenade.get("burn_stacks") else frag_grenade.burn_damage
	# Frag Grenade may not have burn, let's check incendiary instead
	
	var incendiary = CardDatabase.get_card("incendiary")
	assert_not_null(incendiary, "Incendiary card exists for tooltip test")
	burn_stacks = incendiary.burn_stacks if incendiary.get("burn_stacks") else incendiary.burn_damage
	assert_true(burn_stacks > 0, "Incendiary has burn stacks for tooltip: " + str(burn_stacks))
	
	# Get a card with self-damage
	var reckless_blast = CardDatabase.get_card("reckless_blast")
	assert_not_null(reckless_blast, "Reckless Blast card exists for tooltip test")
	assert_true(reckless_blast.self_damage > 0, "Reckless Blast has self_damage for tooltip: " + str(reckless_blast.self_damage))

