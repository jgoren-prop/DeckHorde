extends Node
## TestV5Merge - Tests V5 2-to-1 merge system with 4 tiers

var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestV5Merge] Starting V5 merge system tests...")
	await get_tree().process_frame
	
	_test_merge_constants()
	_test_cannot_merge_single()
	_test_can_merge_two()
	_test_execute_merge()
	_test_cascade_merge()
	_test_instant_cannot_merge()
	_test_tier_colors()
	
	print("")
	print("=" .repeat(50))
	print("[TestV5Merge] Tests complete: %d passed, %d failed" % [tests_passed, tests_failed])
	print("=" .repeat(50))
	
	if tests_failed == 0:
		print("[TestV5Merge] RESULT: ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TestV5Merge] RESULT: SOME TESTS FAILED ✗")
		get_tree().quit(1)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  ✓ " + test_name)
		tests_passed += 1
	else:
		print("  ✗ FAILED: " + test_name)
		tests_failed += 1


func _setup() -> void:
	"""Reset deck before each test."""
	RunManager.deck.clear()
	FamilyBuffManager.reset()
	RunManager.player_stats.reset_to_defaults()


func _test_merge_constants() -> void:
	print("\n[Test] V5 Merge Constants")
	_assert(MergeManager.MAX_TIER == 4, "MAX_TIER is 4")
	_assert(MergeManager.COPIES_REQUIRED == 2, "COPIES_REQUIRED is 2")


func _test_cannot_merge_single() -> void:
	print("\n[Test] Cannot Merge Single Card")
	_setup()
	
	RunManager.deck.append({"card_id": "pistol", "tier": 1})
	_assert(not MergeManager.can_merge("pistol", 1), "Cannot merge with only 1 copy")


func _test_can_merge_two() -> void:
	print("\n[Test] Can Merge Two Cards")
	_setup()
	
	RunManager.deck.append({"card_id": "pistol", "tier": 1})
	RunManager.deck.append({"card_id": "pistol", "tier": 1})
	
	_assert(MergeManager.can_merge("pistol", 1), "Can merge with 2 copies")
	
	# Check mergeable list
	var mergeable: Array = MergeManager.check_for_merges()
	_assert(mergeable.size() == 1, "Found 1 mergeable set")
	_assert(mergeable[0].card_id == "pistol", "Mergeable card is pistol")
	_assert(mergeable[0].tier == 1, "Mergeable tier is 1")


func _test_execute_merge() -> void:
	print("\n[Test] Execute Merge")
	_setup()
	
	RunManager.deck.append({"card_id": "pistol", "tier": 1})
	RunManager.deck.append({"card_id": "pistol", "tier": 1})
	
	_assert(RunManager.deck.size() == 2, "Deck has 2 cards before merge")
	
	var success: bool = MergeManager.execute_merge("pistol", 1)
	
	_assert(success, "Merge executed successfully")
	_assert(RunManager.deck.size() == 1, "Deck has 1 card after merge")
	_assert(RunManager.deck[0].tier == 2, "New card is tier 2")


func _test_cascade_merge() -> void:
	print("\n[Test] Cascade Merge (T1->T2->T3->T4)")
	_setup()
	
	# Add 8 T1 pistols (enough for 2^3 = 8 -> 4 -> 2 -> 1 T4)
	for i in range(8):
		RunManager.deck.append({"card_id": "pistol", "tier": 1})
	
	_assert(RunManager.deck.size() == 8, "Deck has 8 T1 cards")
	
	# Auto-merge all
	var merges: int = MergeManager.auto_merge_all()
	
	print("  Merges performed: ", merges)
	print("  Final deck size: ", RunManager.deck.size())
	print("  Final card tier: ", RunManager.deck[0].tier if RunManager.deck.size() > 0 else "none")
	
	_assert(RunManager.deck.size() == 1, "Deck has 1 card after cascade")
	_assert(RunManager.deck[0].tier == 4, "Final card is T4")
	_assert(merges == 7, "7 total merges (4+2+1)")


func _test_instant_cannot_merge() -> void:
	print("\n[Test] Instants Cannot Merge")
	_setup()
	
	RunManager.deck.append({"card_id": "bandage", "tier": 1})
	RunManager.deck.append({"card_id": "bandage", "tier": 1})
	
	_assert(not MergeManager.can_merge("bandage", 1), "Cannot merge instant cards")
	
	var mergeable: Array = MergeManager.check_for_merges()
	_assert(mergeable.size() == 0, "No mergeable sets for instants")


func _test_tier_colors() -> void:
	print("\n[Test] Tier Colors")
	
	var t1_color: Color = MergeManager.get_tier_color(1)
	var t2_color: Color = MergeManager.get_tier_color(2)
	var t3_color: Color = MergeManager.get_tier_color(3)
	var t4_color: Color = MergeManager.get_tier_color(4)
	
	_assert(t1_color != t2_color, "T1 and T2 have different colors")
	_assert(t2_color != t3_color, "T2 and T3 have different colors")
	_assert(t3_color != t4_color, "T3 and T4 have different colors")
	
	# Verify tier names
	_assert(MergeManager.get_tier_name(1) == "T1", "Tier 1 name is T1")
	_assert(MergeManager.get_tier_name(4) == "T4", "Tier 4 name is T4")

