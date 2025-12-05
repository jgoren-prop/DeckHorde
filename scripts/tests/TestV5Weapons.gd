extends Node
## TestV5Weapons - Validates all 54 V5 weapons in CardDatabase

const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")

var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestV5Weapons] Starting V5 weapon validation...")
	await get_tree().process_frame
	
	_test_weapon_count()
	_test_instant_count()
	_test_all_weapons_have_categories()
	_test_all_weapons_have_damage_type()
	_test_category_distribution()
	_test_starter_deck_exists()
	_test_sample_damage_calculations()
	
	print("")
	print("=" .repeat(50))
	print("[TestV5Weapons] Tests complete: %d passed, %d failed" % [tests_passed, tests_failed])
	print("=" .repeat(50))
	
	if tests_failed == 0:
		print("[TestV5Weapons] RESULT: ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TestV5Weapons] RESULT: SOME TESTS FAILED ✗")
		get_tree().quit(1)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		print("  ✓ " + test_name)
		tests_passed += 1
	else:
		print("  ✗ FAILED: " + test_name)
		tests_failed += 1


func _test_weapon_count() -> void:
	print("\n[Test] Weapon Count")
	var weapons: Array = CardDatabase.get_weapons()
	_assert(weapons.size() == 54, "54 weapons exist (found: %d)" % weapons.size())
	
	# Count by category
	var kinetic: int = 0
	var thermal: int = 0
	var arcane: int = 0
	var fortress: int = 0
	var shadow: int = 0
	var utility: int = 0
	var control: int = 0
	var volatile: int = 0
	
	for weapon in weapons:
		for cat: String in weapon.categories:
			match cat:
				"Kinetic": kinetic += 1
				"Thermal": thermal += 1
				"Arcane": arcane += 1
				"Fortress": fortress += 1
				"Shadow": shadow += 1
				"Utility": utility += 1
				"Control": control += 1
				"Volatile": volatile += 1
	
	print("  Category totals (cards can count multiple times):")
	print("    Kinetic: %d, Thermal: %d, Arcane: %d, Fortress: %d" % [kinetic, thermal, arcane, fortress])
	print("    Shadow: %d, Utility: %d, Control: %d, Volatile: %d" % [shadow, utility, control, volatile])


func _test_instant_count() -> void:
	print("\n[Test] Instant Count")
	var instants: Array = CardDatabase.get_instants()
	_assert(instants.size() == 24, "24 instants exist (found: %d)" % instants.size())
	
	# Count universal vs category
	var universal: int = 0
	var with_category: int = 0
	for instant in instants:
		if instant.categories.size() == 0:
			universal += 1
		else:
			with_category += 1
	
	_assert(universal == 4, "4 universal instants (found: %d)" % universal)
	_assert(with_category == 20, "20 category instants (found: %d)" % with_category)


func _test_all_weapons_have_categories() -> void:
	print("\n[Test] All Weapons Have Categories")
	var weapons: Array = CardDatabase.get_weapons()
	var missing: int = 0
	
	for weapon in weapons:
		if weapon.categories.size() == 0:
			print("  Missing categories: " + weapon.card_id)
			missing += 1
	
	_assert(missing == 0, "All weapons have at least 1 category")


func _test_all_weapons_have_damage_type() -> void:
	print("\n[Test] All Weapons Have Damage Type")
	var weapons: Array = CardDatabase.get_weapons()
	var invalid: int = 0
	
	for weapon in weapons:
		if weapon.damage_type == "" or weapon.damage_type == "none":
			print("  Missing damage type: " + weapon.card_id)
			invalid += 1
		elif not TagConstantsClass.is_valid_damage_type(weapon.damage_type):
			print("  Invalid damage type '%s': %s" % [weapon.damage_type, weapon.card_id])
			invalid += 1
	
	_assert(invalid == 0, "All weapons have valid damage type")


func _test_category_distribution() -> void:
	print("\n[Test] Category Distribution")
	
	# Expected: 10 Kinetic-primary, 7 Thermal, 7 Arcane, 6 each for rest
	var primary_counts: Dictionary = {}
	var weapons: Array = CardDatabase.get_weapons()
	
	for weapon in weapons:
		if weapon.categories.size() > 0:
			var primary: String = weapon.categories[0]
			primary_counts[primary] = primary_counts.get(primary, 0) + 1
	
	print("  Primary category counts:")
	for cat: String in primary_counts.keys():
		print("    %s: %d" % [cat, primary_counts[cat]])
	
	_assert(primary_counts.get("Kinetic", 0) == 10, "10 Kinetic-primary (found: %d)" % primary_counts.get("Kinetic", 0))
	_assert(primary_counts.get("Thermal", 0) == 7, "7 Thermal-primary (found: %d)" % primary_counts.get("Thermal", 0))
	_assert(primary_counts.get("Arcane", 0) == 7, "7 Arcane-primary (found: %d)" % primary_counts.get("Arcane", 0))
	_assert(primary_counts.get("Fortress", 0) == 6, "6 Fortress-primary (found: %d)" % primary_counts.get("Fortress", 0))
	_assert(primary_counts.get("Shadow", 0) == 6, "6 Shadow-primary (found: %d)" % primary_counts.get("Shadow", 0))
	_assert(primary_counts.get("Utility", 0) == 6, "6 Utility-primary (found: %d)" % primary_counts.get("Utility", 0))
	_assert(primary_counts.get("Control", 0) == 6, "6 Control-primary (found: %d)" % primary_counts.get("Control", 0))
	_assert(primary_counts.get("Volatile", 0) == 6, "6 Volatile-primary (found: %d)" % primary_counts.get("Volatile", 0))


func _test_starter_deck_exists() -> void:
	print("\n[Test] Starter Deck Cards Exist")
	var starter: Array = CardDatabase.get_veteran_starter_deck()
	var all_exist: bool = true
	
	for entry: Dictionary in starter:
		var card_id: String = entry.get("card_id", "")
		var card = CardDatabase.get_card(card_id)
		if card == null:
			print("  Missing starter card: " + card_id)
			all_exist = false
	
	_assert(all_exist, "All starter deck cards exist in database")
	
	# Count total cards in starter
	var total: int = 0
	for entry: Dictionary in starter:
		total += entry.get("count", 1)
	_assert(total == 10, "Starter deck has 10 cards (found: %d)" % total)


func _test_sample_damage_calculations() -> void:
	print("\n[Test] Sample Damage Calculations")
	
	RunManager.player_stats.reset_to_defaults()
	RunManager.player_stats.kinetic = 10  # 10 flat kinetic
	
	# Test Pistol: Base 2 + 100% of 10 = 12
	var pistol = CardDatabase.get_card("pistol")
	var pistol_calc: Dictionary = pistol.calculate_damage(RunManager.player_stats)
	_assert(pistol_calc.final == 12, "Pistol: 2 + (10 × 100%%) = 12 (got: %d)" % pistol_calc.final)
	
	# Test with type multiplier
	RunManager.player_stats.kinetic_percent = 120.0  # +20%
	var pistol_calc2: Dictionary = pistol.calculate_damage(RunManager.player_stats)
	# 12 * 1.20 = 14.4 -> 14
	_assert(pistol_calc2.final == 14, "Pistol with +20%% kinetic: 12 × 1.20 = 14 (got: %d)" % pistol_calc2.final)
	
	# Reset and test Shadow weapon crit
	RunManager.player_stats.reset_to_defaults()
	var killing_blow = CardDatabase.get_card("killing_blow")
	var kb_calc: Dictionary = killing_blow.calculate_damage(RunManager.player_stats)
	
	# Killing Blow: Base 2, 35% crit chance (5 base + 30 bonus), 250% crit damage
	_assert(abs(kb_calc.crit_chance - 0.35) < 0.01, "Killing Blow: 35%% crit chance (got: %.2f)" % kb_calc.crit_chance)
	_assert(abs(kb_calc.crit_mult - 2.5) < 0.01, "Killing Blow: 250%% crit damage (got: %.2f)" % kb_calc.crit_mult)



