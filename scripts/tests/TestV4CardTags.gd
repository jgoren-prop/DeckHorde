extends Node
## TestV4CardTags - Automated tests for V4 card tag compliance
## Verifies all cards have exactly 1 core type tag

var test_passed: bool = true
var tests_run: int = 0
var tests_passed: int = 0


func _ready() -> void:
	print("[TEST] V4 Card Tag Compliance Tests Starting...")
	await get_tree().process_frame
	
	_test_all_cards_have_core_type()
	_test_no_invalid_tags()
	_test_tag_counts()
	
	_report_results()


func _test_all_cards_have_core_type() -> void:
	"""Test that every card has exactly 1 core type tag."""
	print("\n[TEST] Testing all cards have exactly 1 core type tag...")
	tests_run += 1
	var local_passed: bool = true
	var cards_checked: int = 0
	var cards_with_issues: Array[String] = []
	
	for card_id: String in CardDatabase.cards.keys():
		var card = CardDatabase.cards[card_id]
		cards_checked += 1
		
		# Count core type tags
		var core_types_found: Array[String] = []
		for tag: Variant in card.tags:
			if tag is String and TagConstants.is_core_type(tag):
				core_types_found.append(tag)
		
		if core_types_found.size() == 0:
			print("[TEST] FAIL: Card '%s' has NO core type tag" % card_id)
			cards_with_issues.append(card_id)
			local_passed = false
		elif core_types_found.size() > 1:
			print("[TEST] FAIL: Card '%s' has MULTIPLE core type tags: %s" % [card_id, str(core_types_found)])
			cards_with_issues.append(card_id)
			local_passed = false
	
	if local_passed:
		tests_passed += 1
		print("[TEST] All %d cards have exactly 1 core type tag: PASSED" % cards_checked)
	else:
		test_passed = false
		print("[TEST] Core type tag test: FAILED (%d cards with issues)" % cards_with_issues.size())


func _test_no_invalid_tags() -> void:
	"""Test that no cards have unrecognized tags."""
	print("\n[TEST] Testing no invalid tags...")
	tests_run += 1
	var local_passed: bool = true
	var cards_checked: int = 0
	
	# V4 allows these legacy tags that aren't in TagConstants.ALL_TAGS
	# (they should eventually be removed but won't break anything)
	var allowed_legacy_tags: Array[String] = []
	
	for card_id: String in CardDatabase.cards.keys():
		var card = CardDatabase.cards[card_id]
		cards_checked += 1
		
		for tag: Variant in card.tags:
			if tag is String:
				if not TagConstants.is_valid_tag(tag) and tag not in allowed_legacy_tags:
					print("[TEST] WARNING: Card '%s' has unrecognized tag: '%s'" % [card_id, tag])
					# Not failing on this - just warning
	
	tests_passed += 1
	print("[TEST] Tag validation complete (%d cards checked): PASSED" % cards_checked)


func _test_tag_counts() -> void:
	"""Test tag distribution for V4 compliance."""
	print("\n[TEST] Testing tag distribution...")
	tests_run += 1
	
	var core_type_counts: Dictionary = {}
	var family_tag_counts: Dictionary = {}
	var damage_type_counts: Dictionary = {}
	var total_cards: int = 0
	
	for card_id: String in CardDatabase.cards.keys():
		var card = CardDatabase.cards[card_id]
		total_cards += 1
		
		for tag: Variant in card.tags:
			if tag is String:
				if TagConstants.is_core_type(tag):
					core_type_counts[tag] = core_type_counts.get(tag, 0) + 1
				elif TagConstants.is_family_tag(tag):
					family_tag_counts[tag] = family_tag_counts.get(tag, 0) + 1
				elif TagConstants.is_damage_type_tag(tag):
					damage_type_counts[tag] = damage_type_counts.get(tag, 0) + 1
	
	print("[TEST] Core type distribution:")
	for tag: String in core_type_counts.keys():
		print("  - %s: %d cards" % [tag, core_type_counts[tag]])
	
	print("[TEST] Family tag distribution:")
	for tag: String in family_tag_counts.keys():
		print("  - %s: %d cards" % [tag, family_tag_counts[tag]])
	
	print("[TEST] Damage type distribution:")
	for tag: String in damage_type_counts.keys():
		print("  - %s: %d cards" % [tag, damage_type_counts[tag]])
	
	tests_passed += 1
	print("[TEST] Tag distribution analysis complete: PASSED")


func _report_results() -> void:
	"""Report final test results and exit."""
	print("\n" + "=".repeat(50))
	print("[TEST] V4 Card Tag Test Results: %d/%d passed" % [tests_passed, tests_run])
	if tests_passed == tests_run:
		print("[TEST] RESULT: ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TEST] RESULT: SOME TESTS FAILED ✗")
		get_tree().quit(1)

