extends Node
## TestV5Economy - Unit tests for V5 economy system

var tests_passed: int = 0
var tests_failed: int = 0
var current_test: String = ""


func _ready() -> void:
	print("\n========================================")
	print("V5 ECONOMY SYSTEM TESTS")
	print("========================================\n")
	
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
	# Interest system tests
	test_interest_calculation()
	test_interest_cap()
	
	# Card pricing tests
	test_card_pricing_by_rarity()
	test_card_pricing_by_tier()
	
	# Reroll cost tests
	test_reroll_cost_base()
	test_reroll_cost_scaling()
	
	# Remove card cost tests
	test_remove_card_cost()
	
	# Stat upgrade tests
	test_stat_upgrades_exist()
	test_stat_upgrade_pricing()
	test_stat_upgrade_purchase()
	
	# Category tracking tests
	test_category_tracking()


# === Interest System Tests ===

func test_interest_calculation() -> void:
	start_test("Interest calculation (5%)")
	
	# 40 scrap = 2 interest
	var interest1: int = ShopGenerator.calculate_interest(40)
	assert_equal(interest1, 2, "40 scrap should give 2 interest")
	
	# 100 scrap = 5 interest
	var interest2: int = ShopGenerator.calculate_interest(100)
	assert_equal(interest2, 5, "100 scrap should give 5 interest")
	
	# 200 scrap = 10 interest
	var interest3: int = ShopGenerator.calculate_interest(200)
	assert_equal(interest3, 10, "200 scrap should give 10 interest")
	
	end_test()


func test_interest_cap() -> void:
	start_test("Interest cap (25 max)")
	
	# 500 scrap = 25 interest (capped)
	var interest1: int = ShopGenerator.calculate_interest(500)
	assert_equal(interest1, 25, "500 scrap should give 25 interest (cap)")
	
	# 1000 scrap = still 25 (capped)
	var interest2: int = ShopGenerator.calculate_interest(1000)
	assert_equal(interest2, 25, "1000 scrap should still give 25 interest (cap)")
	
	end_test()


# === Card Pricing Tests ===

func test_card_pricing_by_rarity() -> void:
	start_test("Card pricing by rarity")
	
	# Common base price = 15
	var common_price: int = ShopGenerator.RARITY_BASE_PRICES.get(0, 0)
	assert_equal(common_price, 15, "Common base price should be 15")
	
	# Uncommon base price = 38
	var uncommon_price: int = ShopGenerator.RARITY_BASE_PRICES.get(1, 0)
	assert_equal(uncommon_price, 38, "Uncommon base price should be 38")
	
	# Rare base price = 75
	var rare_price: int = ShopGenerator.RARITY_BASE_PRICES.get(2, 0)
	assert_equal(rare_price, 75, "Rare base price should be 75")
	
	end_test()


func test_card_pricing_by_tier() -> void:
	start_test("Card pricing by tier")
	
	# Tier 1 = 1.0x
	var tier1_mult: float = ShopGenerator.TIER_PRICE_MULTIPLIERS.get(1, 0.0)
	assert_equal(tier1_mult, 1.0, "Tier 1 multiplier should be 1.0")
	
	# Tier 2 = 1.8x
	var tier2_mult: float = ShopGenerator.TIER_PRICE_MULTIPLIERS.get(2, 0.0)
	assert_equal(tier2_mult, 1.8, "Tier 2 multiplier should be 1.8")
	
	# Tier 3 = 3.0x
	var tier3_mult: float = ShopGenerator.TIER_PRICE_MULTIPLIERS.get(3, 0.0)
	assert_equal(tier3_mult, 3.0, "Tier 3 multiplier should be 3.0")
	
	# Tier 4 = 4.5x
	var tier4_mult: float = ShopGenerator.TIER_PRICE_MULTIPLIERS.get(4, 0.0)
	assert_equal(tier4_mult, 4.5, "Tier 4 multiplier should be 4.5")
	
	end_test()


# === Reroll Cost Tests ===

func test_reroll_cost_base() -> void:
	start_test("Reroll cost base")
	
	# Reset reroll count
	ShopGenerator.reset_shop_reroll_count()
	
	# First reroll = base 2
	var cost: int = ShopGenerator.get_reroll_cost(1, 0)
	assert_equal(cost, 2, "First reroll should cost 2")
	
	end_test()


func test_reroll_cost_scaling() -> void:
	start_test("Reroll cost scaling (+2 per reroll)")
	
	# Second reroll = 2 + 2 = 4
	var cost1: int = ShopGenerator.get_reroll_cost(1, 1)
	assert_equal(cost1, 4, "Second reroll should cost 4")
	
	# Third reroll = 2 + 4 = 6
	var cost2: int = ShopGenerator.get_reroll_cost(1, 2)
	assert_equal(cost2, 6, "Third reroll should cost 6")
	
	# Fifth reroll = 2 + 8 = 10
	var cost3: int = ShopGenerator.get_reroll_cost(1, 4)
	assert_equal(cost3, 10, "Fifth reroll should cost 10")
	
	end_test()


# === Remove Card Cost Tests ===

func test_remove_card_cost() -> void:
	start_test("Remove card cost (15 + wave × 3)")
	
	# Wave 1 = 15 + 3 = 18
	var cost1: int = ShopGenerator.get_remove_card_cost(1)
	assert_equal(cost1, 18, "Wave 1 remove cost should be 18")
	
	# Wave 5 = 15 + 15 = 30
	var cost2: int = ShopGenerator.get_remove_card_cost(5)
	assert_equal(cost2, 30, "Wave 5 remove cost should be 30")
	
	# Wave 10 = 15 + 30 = 45
	var cost3: int = ShopGenerator.get_remove_card_cost(10)
	assert_equal(cost3, 45, "Wave 10 remove cost should be 45")
	
	end_test()


# === Stat Upgrade Tests ===

func test_stat_upgrades_exist() -> void:
	start_test("V5 stat upgrades exist")
	
	# Check key V5 upgrades exist
	assert_true(ShopGenerator.V5_STAT_UPGRADES.has("kinetic_up"), "Kinetic upgrade should exist")
	assert_true(ShopGenerator.V5_STAT_UPGRADES.has("thermal_up"), "Thermal upgrade should exist")
	assert_true(ShopGenerator.V5_STAT_UPGRADES.has("arcane_up"), "Arcane upgrade should exist")
	assert_true(ShopGenerator.V5_STAT_UPGRADES.has("crit_chance_up"), "Crit chance upgrade should exist")
	assert_true(ShopGenerator.V5_STAT_UPGRADES.has("damage_percent_up"), "Damage percent upgrade should exist")
	
	end_test()


func test_stat_upgrade_pricing() -> void:
	start_test("Stat upgrade pricing")
	
	# Kinetic: base 12, +4 per buy
	var kinetic: Dictionary = ShopGenerator.V5_STAT_UPGRADES.get("kinetic_up", {})
	assert_equal(kinetic.base_price, 12, "Kinetic base price should be 12")
	assert_equal(kinetic.price_increment, 4, "Kinetic increment should be 4")
	
	# Draw: base 45, +20 per buy
	var draw: Dictionary = ShopGenerator.V5_STAT_UPGRADES.get("draw_up", {})
	assert_equal(draw.base_price, 45, "Draw base price should be 45")
	assert_equal(draw.price_increment, 20, "Draw increment should be 20")
	
	end_test()


func test_stat_upgrade_purchase() -> void:
	start_test("Stat upgrade purchase")
	
	# Reset shop state
	ShopGenerator.reset_shop_state()
	
	# Ensure player has scrap
	var initial_scrap: int = RunManager.scrap
	RunManager.add_scrap(100)
	
	var initial_kinetic: int = RunManager.player_stats.kinetic
	
	# Purchase kinetic upgrade
	var success: bool = ShopGenerator.purchase_stat_upgrade("kinetic_up")
	assert_true(success, "Kinetic upgrade should succeed")
	
	var new_kinetic: int = RunManager.player_stats.kinetic
	assert_equal(new_kinetic, initial_kinetic + 3, "Kinetic should increase by 3")
	
	# Restore scrap
	RunManager.scrap = initial_scrap
	RunManager.player_stats.kinetic = initial_kinetic
	ShopGenerator.reset_shop_state()
	
	end_test()


# === Category Tracking Tests ===

func test_category_tracking() -> void:
	start_test("Category tracking")
	
	var counts: Dictionary = ShopGenerator.get_owned_category_counts()
	
	# Should have all 8 categories tracked
	assert_true(counts.has("kinetic"), "Should track kinetic")
	assert_true(counts.has("thermal"), "Should track thermal")
	assert_true(counts.has("arcane"), "Should track arcane")
	assert_true(counts.has("fortress"), "Should track fortress")
	assert_true(counts.has("shadow"), "Should track shadow")
	assert_true(counts.has("utility"), "Should track utility")
	assert_true(counts.has("control"), "Should track control")
	assert_true(counts.has("volatile"), "Should track volatile")
	
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

