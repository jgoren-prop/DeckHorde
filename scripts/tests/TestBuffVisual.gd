extends Control
## TestBuffVisual - Test scene for lane buff visual feedback
## Tests that cards visually update when buffs are applied

const CardUIScene: PackedScene = preload("res://scenes/ui/CardUI.tscn")

var test_passed: bool = true
var test_log: Array[String] = []

@onready var result_label: Label = $ResultLabel
@onready var card_container: HBoxContainer = $CardContainer


func _ready() -> void:
	_log("[TEST] Starting Buff Visual Feedback Test")
	
	# Wait for UI to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Run tests
	await _run_tests()
	
	# Show results
	_show_results()


func _log(message: String) -> void:
	print(message)
	test_log.append(message)


func _run_tests() -> void:
	_log("[TEST] === Test 1: Basic CardUI Buff Display ===")
	await _test_card_ui_buff()
	
	_log("[TEST] === Test 2: Multiple Buffs Stack ===")
	await _test_multiple_buffs()
	
	_log("[TEST] === Test 3: Buff Animation Creates Floater ===")
	await _test_buff_animation()


func _test_card_ui_buff() -> void:
	"""Test that CardUI correctly displays buffed stats."""
	# Get pistol card def
	var pistol = CardDatabase.get_card("pistol")
	if not pistol:
		_log("[TEST] FAILED: Could not find pistol card")
		test_passed = false
		return
	
	# Create card UI
	var card_ui: Control = CardUIScene.instantiate()
	card_container.add_child(card_ui)
	card_ui.check_playability = false
	card_ui.setup(pistol, 1, 0)
	
	await get_tree().process_frame
	
	# Check initial damage
	var initial_damage: int = card_ui.base_damage_display
	_log("[TEST] Initial damage: %d" % initial_damage)
	
	if initial_damage != 4:  # Pistol base damage is 4
		_log("[TEST] FAILED: Expected initial damage 4, got %d" % initial_damage)
		test_passed = false
		return
	
	# Apply a buff
	card_ui.apply_buff("gun_damage", 2, "gun")
	
	await get_tree().process_frame
	
	# Check buffed damage
	var buffed_damage: int = card_ui.get_total_damage_with_buffs()
	_log("[TEST] Buffed damage: %d" % buffed_damage)
	
	if buffed_damage != 6:  # 4 + 2 = 6
		_log("[TEST] FAILED: Expected buffed damage 6, got %d" % buffed_damage)
		test_passed = false
		return
	
	# Check that has_buffs returns true
	if not card_ui.has_buffs():
		_log("[TEST] FAILED: has_buffs() should return true")
		test_passed = false
		return
	
	_log("[TEST] PASSED: Basic buff display works correctly")
	
	# Clean up
	card_ui.queue_free()
	await get_tree().process_frame


func _test_multiple_buffs() -> void:
	"""Test that multiple buffs stack correctly."""
	var pistol = CardDatabase.get_card("pistol")
	if not pistol:
		_log("[TEST] FAILED: Could not find pistol card")
		test_passed = false
		return
	
	var card_ui: Control = CardUIScene.instantiate()
	card_container.add_child(card_ui)
	card_ui.check_playability = false
	card_ui.setup(pistol, 1, 0)
	
	await get_tree().process_frame
	
	# Apply multiple buffs
	card_ui.apply_buff("gun_damage", 2, "gun")
	card_ui.apply_buff("all_damage", 3, "")
	
	await get_tree().process_frame
	
	# Check total damage (4 base + 2 gun_damage + 3 all_damage = 9)
	var buffed_damage: int = card_ui.get_total_damage_with_buffs()
	_log("[TEST] Stacked buff damage: %d" % buffed_damage)
	
	if buffed_damage != 9:
		_log("[TEST] FAILED: Expected stacked damage 9, got %d" % buffed_damage)
		test_passed = false
		return
	
	_log("[TEST] PASSED: Multiple buffs stack correctly")
	
	# Clean up
	card_ui.queue_free()
	await get_tree().process_frame


func _test_buff_animation() -> void:
	"""Test that buff animation creates visual feedback elements."""
	var pistol = CardDatabase.get_card("pistol")
	if not pistol:
		_log("[TEST] FAILED: Could not find pistol card")
		test_passed = false
		return
	
	var card_ui: Control = CardUIScene.instantiate()
	card_container.add_child(card_ui)
	card_ui.check_playability = false
	card_ui.setup(pistol, 1, 0)
	
	await get_tree().process_frame
	
	# Count children before buff
	var children_before: int = card_ui.get_child_count()
	
	# Apply buff (should create floater)
	card_ui.apply_buff("gun_damage", 2, "gun")
	
	await get_tree().process_frame
	
	# Count children after buff (floater label should be added)
	var children_after: int = card_ui.get_child_count()
	
	if children_after <= children_before:
		_log("[TEST] FAILED: No floater was created. Children before: %d, after: %d" % [children_before, children_after])
		test_passed = false
		return
	
	_log("[TEST] PASSED: Buff animation creates floater. Children: %d -> %d" % [children_before, children_after])
	
	# Wait for animation to complete
	await get_tree().create_timer(1.5).timeout
	
	# Clean up
	card_ui.queue_free()
	await get_tree().process_frame


func _show_results() -> void:
	var result_text: String = ""
	
	for log_entry: String in test_log:
		result_text += log_entry + "\n"
	
	result_text += "\n"
	
	if test_passed:
		result_text += "=== ALL TESTS PASSED ✓ ==="
		_log("[TEST] RESULT: PASSED ✓")
	else:
		result_text += "=== TESTS FAILED ✗ ==="
		_log("[TEST] RESULT: FAILED ✗")
	
	if result_label:
		result_label.text = result_text
	
	# Exit after showing results (for automated testing)
	await get_tree().create_timer(2.0).timeout
	get_tree().quit(0 if test_passed else 1)

