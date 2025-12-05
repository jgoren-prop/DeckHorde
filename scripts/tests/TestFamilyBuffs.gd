extends Node
## TestFamilyBuffs - Tests V5 Family Buff System
## Verifies category counting and tier-based stat bonuses

const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")
const CardDef = preload("res://scripts/resources/CardDefinition.gd")
const PlayerStatsClass = preload("res://scripts/resources/PlayerStats.gd")

var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestFamilyBuffs] Starting V5 family buff tests...")
	await get_tree().process_frame
	
	_test_category_counting()
	_test_tier_thresholds()
	_test_kinetic_buff()
	_test_shadow_buff()
	_test_multiple_categories()
	_test_remove_card()
	
	print("")
	print("=" .repeat(50))
	print("[TestFamilyBuffs] Tests complete: %d passed, %d failed" % [tests_passed, tests_failed])
	print("=" .repeat(50))
	
	if tests_failed == 0:
		print("[TestFamilyBuffs] RESULT: ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TestFamilyBuffs] RESULT: SOME TESTS FAILED ✗")
		get_tree().quit(1)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  ✓ " + test_name)
		tests_passed += 1
	else:
		print("  ✗ FAILED: " + test_name)
		tests_failed += 1


func _setup() -> void:
	"""Reset state before each test."""
	FamilyBuffManager.reset()
	RunManager.player_stats.reset_to_defaults()
	RunManager.deck.clear()


func _create_test_card(categories: Array[String]) -> CardDef:
	"""Create a test card with specified categories."""
	var card := CardDef.new()
	card.card_id = "test_" + str(randi())
	card.card_name = "Test Card"
	card.categories = categories
	card.damage_type = "kinetic"
	return card


func _test_category_counting() -> void:
	print("\n[Test] Category Counting")
	_setup()
	
	# Add 3 Kinetic cards
	for i in range(3):
		var card := _create_test_card(["Kinetic"])
		FamilyBuffManager.add_card(card)
	
	_assert(FamilyBuffManager.get_category_count("Kinetic") == 3, "3 Kinetic cards counted")
	_assert(FamilyBuffManager.get_category_count("Thermal") == 0, "0 Thermal cards counted")
	
	# Add 2 Thermal cards
	for i in range(2):
		var card := _create_test_card(["Thermal"])
		FamilyBuffManager.add_card(card)
	
	_assert(FamilyBuffManager.get_category_count("Kinetic") == 3, "Still 3 Kinetic cards")
	_assert(FamilyBuffManager.get_category_count("Thermal") == 2, "2 Thermal cards counted")


func _test_tier_thresholds() -> void:
	print("\n[Test] Tier Thresholds")
	_setup()
	
	# 0 cards = Tier 0
	_assert(FamilyBuffManager.get_buff_tier("Kinetic") == 0, "0 cards = Tier 0")
	
	# 2 cards = still Tier 0
	for i in range(2):
		FamilyBuffManager.add_card(_create_test_card(["Kinetic"]))
	_assert(FamilyBuffManager.get_buff_tier("Kinetic") == 0, "2 cards = Tier 0")
	
	# 3 cards = Tier 1
	FamilyBuffManager.add_card(_create_test_card(["Kinetic"]))
	_assert(FamilyBuffManager.get_buff_tier("Kinetic") == 1, "3 cards = Tier 1")
	
	# 6 cards = Tier 2
	for i in range(3):
		FamilyBuffManager.add_card(_create_test_card(["Kinetic"]))
	_assert(FamilyBuffManager.get_buff_tier("Kinetic") == 2, "6 cards = Tier 2")
	
	# 9 cards = Tier 3
	for i in range(3):
		FamilyBuffManager.add_card(_create_test_card(["Kinetic"]))
	_assert(FamilyBuffManager.get_buff_tier("Kinetic") == 3, "9 cards = Tier 3")


func _test_kinetic_buff() -> void:
	print("\n[Test] Kinetic Family Buff")
	_setup()
	
	var initial_kinetic: int = RunManager.player_stats.kinetic
	_assert(initial_kinetic == 0, "Initial kinetic stat is 0")
	
	# Add 3 Kinetic cards -> Tier 1 (+3 Kinetic)
	for i in range(3):
		FamilyBuffManager.add_card(_create_test_card(["Kinetic"]))
	
	_assert(RunManager.player_stats.kinetic == 3, "Tier 1: +3 Kinetic applied")
	
	# Add 3 more -> Tier 2 (+6 Kinetic total, so delta of +3)
	for i in range(3):
		FamilyBuffManager.add_card(_create_test_card(["Kinetic"]))
	
	_assert(RunManager.player_stats.kinetic == 6, "Tier 2: +6 Kinetic applied")
	
	# Add 3 more -> Tier 3 (+10 Kinetic total, so delta of +4)
	for i in range(3):
		FamilyBuffManager.add_card(_create_test_card(["Kinetic"]))
	
	_assert(RunManager.player_stats.kinetic == 10, "Tier 3: +10 Kinetic applied")


func _test_shadow_buff() -> void:
	print("\n[Test] Shadow Family Buff (Crit)")
	_setup()
	
	var initial_crit: float = RunManager.player_stats.crit_chance
	_assert(abs(initial_crit - 5.0) < 0.01, "Initial crit chance is 5%")
	
	# Add 3 Shadow cards -> Tier 1 (+5% Crit)
	for i in range(3):
		FamilyBuffManager.add_card(_create_test_card(["Shadow"]))
	
	_assert(abs(RunManager.player_stats.crit_chance - 10.0) < 0.01, "Tier 1: 5% + 5% = 10% crit")
	
	# Add 3 more -> Tier 2 (+10% Crit total)
	for i in range(3):
		FamilyBuffManager.add_card(_create_test_card(["Shadow"]))
	
	_assert(abs(RunManager.player_stats.crit_chance - 15.0) < 0.01, "Tier 2: 5% + 10% = 15% crit")
	
	# Add 3 more -> Tier 3 (+15% Crit total)
	for i in range(3):
		FamilyBuffManager.add_card(_create_test_card(["Shadow"]))
	
	_assert(abs(RunManager.player_stats.crit_chance - 20.0) < 0.01, "Tier 3: 5% + 15% = 20% crit")


func _test_multiple_categories() -> void:
	print("\n[Test] Multiple Categories (Dual-Category Cards)")
	_setup()
	
	# Add 3 cards with both Kinetic and Fortress
	for i in range(3):
		var card := _create_test_card(["Kinetic", "Fortress"])
		FamilyBuffManager.add_card(card)
	
	_assert(FamilyBuffManager.get_category_count("Kinetic") == 3, "3 Kinetic counted")
	_assert(FamilyBuffManager.get_category_count("Fortress") == 3, "3 Fortress counted")
	_assert(FamilyBuffManager.get_buff_tier("Kinetic") == 1, "Kinetic at Tier 1")
	_assert(FamilyBuffManager.get_buff_tier("Fortress") == 1, "Fortress at Tier 1")
	
	# Verify both buffs applied
	_assert(RunManager.player_stats.kinetic == 3, "Kinetic buff: +3")
	_assert(RunManager.player_stats.armor_start == 3, "Fortress buff: +3 armor_start")


func _test_remove_card() -> void:
	print("\n[Test] Remove Card")
	_setup()
	
	# Add 4 Kinetic cards -> Tier 1
	var cards: Array[CardDef] = []
	for i in range(4):
		var card := _create_test_card(["Kinetic"])
		cards.append(card)
		FamilyBuffManager.add_card(card)
	
	_assert(FamilyBuffManager.get_buff_tier("Kinetic") == 1, "4 cards = Tier 1")
	_assert(RunManager.player_stats.kinetic == 3, "Buff: +3 Kinetic")
	
	# Remove 2 cards -> back to Tier 0
	FamilyBuffManager.remove_card(cards[0])
	FamilyBuffManager.remove_card(cards[1])
	
	_assert(FamilyBuffManager.get_category_count("Kinetic") == 2, "2 cards after removal")
	_assert(FamilyBuffManager.get_buff_tier("Kinetic") == 0, "2 cards = Tier 0")
	_assert(RunManager.player_stats.kinetic == 0, "Buff removed: 0 Kinetic")



