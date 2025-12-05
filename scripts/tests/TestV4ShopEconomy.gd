extends Node
## TestV4ShopEconomy - Automated tests for V4 shop economy changes
## Tests reroll cost scaling and shop-clearing reward

var test_passed: bool = true
var tests_run: int = 0
var tests_passed: int = 0


func _ready() -> void:
	print("[TEST] V4 Shop Economy Tests Starting...")
	await get_tree().process_frame
	
	_test_reroll_cost_scaling()
	_test_shop_clearing_reward()
	_test_reroll_count_reset()
	
	_report_results()


func _test_reroll_cost_scaling() -> void:
	"""Test V4 reroll cost formula: base_wave_cost + 2 * reroll_count"""
	print("\n[TEST] Testing reroll cost scaling...")
	tests_run += 1
	
	# Reset state
	ShopGenerator.reset_shop_reroll_count()
	
	# Test wave 1, reroll 0: base = 3 + floor(0/3) = 3, total = 3 + 0 = 3
	var cost_w1_r0: int = ShopGenerator.get_reroll_cost(1, 0)
	if cost_w1_r0 != 3:
		print("[TEST] FAIL: Wave 1, Reroll 0 should be 3, got %d" % cost_w1_r0)
		test_passed = false
	else:
		print("[TEST] PASS: Wave 1, Reroll 0 = %d" % cost_w1_r0)
	
	# Test wave 1, reroll 1: 3 + 2*1 = 5
	var cost_w1_r1: int = ShopGenerator.get_reroll_cost(1, 1)
	if cost_w1_r1 != 5:
		print("[TEST] FAIL: Wave 1, Reroll 1 should be 5, got %d" % cost_w1_r1)
		test_passed = false
	else:
		print("[TEST] PASS: Wave 1, Reroll 1 = %d" % cost_w1_r1)
	
	# Test wave 1, reroll 3: 3 + 2*3 = 9
	var cost_w1_r3: int = ShopGenerator.get_reroll_cost(1, 3)
	if cost_w1_r3 != 9:
		print("[TEST] FAIL: Wave 1, Reroll 3 should be 9, got %d" % cost_w1_r3)
		test_passed = false
	else:
		print("[TEST] PASS: Wave 1, Reroll 3 = %d" % cost_w1_r3)
	
	# Test wave 4, reroll 0: base = 3 + floor(3/3) = 4, total = 4
	var cost_w4_r0: int = ShopGenerator.get_reroll_cost(4, 0)
	if cost_w4_r0 != 4:
		print("[TEST] FAIL: Wave 4, Reroll 0 should be 4, got %d" % cost_w4_r0)
		test_passed = false
	else:
		print("[TEST] PASS: Wave 4, Reroll 0 = %d" % cost_w4_r0)
	
	# Test wave 7, reroll 2: base = 3 + floor(6/3) = 5, total = 5 + 4 = 9
	var cost_w7_r2: int = ShopGenerator.get_reroll_cost(7, 2)
	if cost_w7_r2 != 9:
		print("[TEST] FAIL: Wave 7, Reroll 2 should be 9, got %d" % cost_w7_r2)
		test_passed = false
	else:
		print("[TEST] PASS: Wave 7, Reroll 2 = %d" % cost_w7_r2)
	
	# Test wave 10, reroll 0: base = 3 + floor(9/3) = 6
	var cost_w10_r0: int = ShopGenerator.get_reroll_cost(10, 0)
	if cost_w10_r0 != 6:
		print("[TEST] FAIL: Wave 10, Reroll 0 should be 6, got %d" % cost_w10_r0)
		test_passed = false
	else:
		print("[TEST] PASS: Wave 10, Reroll 0 = %d" % cost_w10_r0)
	
	if test_passed:
		tests_passed += 1
		print("[TEST] Reroll cost scaling: PASSED")
	else:
		print("[TEST] Reroll cost scaling: FAILED")


func _test_shop_clearing_reward() -> void:
	"""Test V4 shop-clearing reward system"""
	print("\n[TEST] Testing shop-clearing reward...")
	tests_run += 1
	var local_passed: bool = true
	
	# Reset state
	ShopGenerator.reset_shop_reroll_count()
	
	# Initially no reward available
	if ShopGenerator.has_shop_clearing_reward():
		print("[TEST] FAIL: Shop clearing reward should not be available initially")
		local_passed = false
	else:
		print("[TEST] PASS: No reward available initially")
	
	# Shop with items - no reward
	var result1: bool = ShopGenerator.check_shop_clearing_reward(2, 1)
	if result1:
		print("[TEST] FAIL: Reward should not trigger with items remaining")
		local_passed = false
	else:
		print("[TEST] PASS: No reward with items remaining")
	
	# Shop cleared - reward triggered
	var result2: bool = ShopGenerator.check_shop_clearing_reward(0, 0)
	if not result2:
		print("[TEST] FAIL: Reward should trigger when shop is cleared")
		local_passed = false
	else:
		print("[TEST] PASS: Reward triggered when shop cleared")
	
	# Check reward is available
	if not ShopGenerator.has_shop_clearing_reward():
		print("[TEST] FAIL: Reward should be available after clearing")
		local_passed = false
	else:
		print("[TEST] PASS: Reward is available")
	
	# Consume reward
	var consumed: bool = ShopGenerator.consume_shop_clearing_reward()
	if not consumed:
		print("[TEST] FAIL: Reward consumption should succeed")
		local_passed = false
	else:
		print("[TEST] PASS: Reward consumed successfully")
	
	# Reward should no longer be available
	if ShopGenerator.has_shop_clearing_reward():
		print("[TEST] FAIL: Reward should not be available after consumption")
		local_passed = false
	else:
		print("[TEST] PASS: No reward after consumption")
	
	# Cannot consume again
	var consumed2: bool = ShopGenerator.consume_shop_clearing_reward()
	if consumed2:
		print("[TEST] FAIL: Should not be able to consume reward twice")
		local_passed = false
	else:
		print("[TEST] PASS: Cannot consume twice")
	
	if local_passed:
		tests_passed += 1
		print("[TEST] Shop-clearing reward: PASSED")
	else:
		test_passed = false
		print("[TEST] Shop-clearing reward: FAILED")


func _test_reroll_count_reset() -> void:
	"""Test that reroll count properly resets"""
	print("\n[TEST] Testing reroll count reset...")
	tests_run += 1
	var local_passed: bool = true
	
	# Reset state
	ShopGenerator.reset_shop_reroll_count()
	
	# Initial count should be 0
	if ShopGenerator.current_shop_reroll_count != 0:
		print("[TEST] FAIL: Initial reroll count should be 0, got %d" % ShopGenerator.current_shop_reroll_count)
		local_passed = false
	else:
		print("[TEST] PASS: Initial reroll count is 0")
	
	# Increment count
	ShopGenerator.increment_reroll_count()
	ShopGenerator.increment_reroll_count()
	if ShopGenerator.current_shop_reroll_count != 2:
		print("[TEST] FAIL: After 2 increments, count should be 2, got %d" % ShopGenerator.current_shop_reroll_count)
		local_passed = false
	else:
		print("[TEST] PASS: Count incremented to 2")
	
	# Test that get_reroll_cost uses current count when not specified
	var cost_auto: int = ShopGenerator.get_reroll_cost(1)  # Wave 1, auto count = 2
	var cost_explicit: int = ShopGenerator.get_reroll_cost(1, 2)  # Wave 1, explicit count = 2
	if cost_auto != cost_explicit:
		print("[TEST] FAIL: Auto count and explicit count should match: %d vs %d" % [cost_auto, cost_explicit])
		local_passed = false
	else:
		print("[TEST] PASS: Auto count matches explicit: %d" % cost_auto)
	
	# Reset and verify
	ShopGenerator.reset_shop_reroll_count()
	if ShopGenerator.current_shop_reroll_count != 0:
		print("[TEST] FAIL: After reset, count should be 0, got %d" % ShopGenerator.current_shop_reroll_count)
		local_passed = false
	else:
		print("[TEST] PASS: Count reset to 0")
	
	if local_passed:
		tests_passed += 1
		print("[TEST] Reroll count reset: PASSED")
	else:
		test_passed = false
		print("[TEST] Reroll count reset: FAILED")


func _report_results() -> void:
	"""Report final test results and exit"""
	print("\n" + "=".repeat(50))
	print("[TEST] V4 Shop Economy Test Results: %d/%d passed" % [tests_passed, tests_run])
	if tests_passed == tests_run:
		print("[TEST] RESULT: ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TEST] RESULT: SOME TESTS FAILED ✗")
		get_tree().quit(1)

