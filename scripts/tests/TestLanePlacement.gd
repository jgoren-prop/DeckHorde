extends Node
## Automated tests for the lane-based group placement system.
## Tests:
## 1. Multiple groups spawn in different lanes without overlap
## 2. Groups moving Far → Mid → Close → Melee preserve lane (stay far-left/far-right)
## 3. Stress test: fill all 12 lanes, verify spacing
## 4. Adding/removing groups preserves ordering

const STACK_SYSTEM_SCENE: PackedScene = preload("res://scenes/combat/nodes/BattlefieldStackSystem.tscn")


class StubEnemy:
	extends RefCounted
	var enemy_id: String
	var instance_id: int
	var current_hp: int
	var max_hp: int
	var ring: int
	var group_id: String = ""
	var spawn_batch_id: int = 0
	
	func _init(id: String, inst_id: int, hp: int, max_health: int, ring_idx: int, batch_id: int = 0) -> void:
		enemy_id = id
		instance_id = inst_id
		current_hp = hp
		max_hp = max_health
		ring = ring_idx
		spawn_batch_id = batch_id
	
	func get_hp_percentage() -> float:
		return float(current_hp) / float(max_hp)
	
	func get_status_value(_status: String) -> int:
		return 0
	
	func is_alive() -> bool:
		return current_hp > 0
	
	func will_attack_this_turn(_enemy_def = null) -> bool:
		return ring == 0


var _stack_system: BattlefieldStackSystem = null


func _ready() -> void:
	await get_tree().process_frame
	
	var test1_passed: bool = await _test_no_overlap_multiple_groups()
	print("[TEST] Multiple groups no overlap: ", "PASSED ✓" if test1_passed else "FAILED ✗")
	
	var test2_passed: bool = await _test_lane_preserved_across_rings()
	print("[TEST] Lane preserved across rings: ", "PASSED ✓" if test2_passed else "FAILED ✗")
	
	var test3_passed: bool = await _test_fill_all_lanes()
	print("[TEST] Fill all 12 lanes: ", "PASSED ✓" if test3_passed else "FAILED ✗")
	
	var test4_passed: bool = await _test_z_order_by_ring()
	print("[TEST] Z-order by ring: ", "PASSED ✓" if test4_passed else "FAILED ✗")
	
	var all_passed: bool = test1_passed and test2_passed and test3_passed and test4_passed
	print("[TEST] OVERALL RESULT: ", "PASSED ✓" if all_passed else "FAILED ✗")
	get_tree().quit(0 if all_passed else 1)


func _setup_stack_system() -> BattlefieldStackSystem:
	var stack_system: BattlefieldStackSystem = STACK_SYSTEM_SCENE.instantiate()
	stack_system.arena_center = Vector2(600, 500)
	stack_system.arena_max_radius = 400.0
	add_child(stack_system)
	return stack_system


func _cleanup_stack_system(stack_system: BattlefieldStackSystem) -> void:
	if stack_system:
		stack_system.queue_free()
	await get_tree().process_frame


func _make_stub_enemies(count: int, ring: int, enemy_id: String = "husk", batch_id: int = 0, start_instance: int = 100) -> Array:
	var enemies: Array = []
	for i: int in range(count):
		enemies.append(StubEnemy.new(enemy_id, start_instance + i, 8, 8, ring, batch_id))
	return enemies


func _test_no_overlap_multiple_groups() -> bool:
	"""Test that multiple groups spawn in different lanes without overlap."""
	_stack_system = _setup_stack_system()
	
	# Create 4 groups of different enemy types in the same ring
	var group1_enemies: Array = _make_stub_enemies(3, 3, "husk", 1, 100)
	var group2_enemies: Array = _make_stub_enemies(3, 3, "spitter", 2, 200)
	var group3_enemies: Array = _make_stub_enemies(3, 3, "bomber", 3, 300)
	var group4_enemies: Array = _make_stub_enemies(3, 3, "cultist", 4, 400)
	
	# Assign lanes and create stacks
	var key1: String = "3_husk_group_1"
	var key2: String = "3_spitter_group_2"
	var key3: String = "3_bomber_group_3"
	var key4: String = "3_cultist_group_4"
	
	_stack_system.assign_random_lane(3, "group_1")
	_stack_system.assign_random_lane(3, "group_2")
	_stack_system.assign_random_lane(3, "group_3")
	_stack_system.assign_random_lane(3, "group_4")
	
	_stack_system.create_stack(3, "husk", group1_enemies, key1)
	_stack_system.create_stack(3, "spitter", group2_enemies, key2)
	_stack_system.create_stack(3, "bomber", group3_enemies, key3)
	_stack_system.create_stack(3, "cultist", group4_enemies, key4)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that all groups have different lanes
	var lanes_used: Array[int] = []
	for gid: String in ["group_1", "group_2", "group_3", "group_4"]:
		var lane: int = _stack_system.get_group_lane(gid)
		print("[TEST DEBUG] Group ", gid, " assigned lane: ", lane)
		if lane in lanes_used:
			print("[TEST DEBUG] DUPLICATE LANE FOUND!")
			await _cleanup_stack_system(_stack_system)
			return false
		lanes_used.append(lane)
	
	# Check for visual overlap by comparing panel positions
	var panels: Array[Panel] = []
	for key: String in [key1, key2, key3, key4]:
		var panel: Panel = _stack_system.get_stack_panel(key)
		if is_instance_valid(panel):
			panels.append(panel)
	
	for i: int in range(panels.size()):
		for j: int in range(i + 1, panels.size()):
			var rect_a: Rect2 = Rect2(panels[i].position, panels[i].size)
			var rect_b: Rect2 = Rect2(panels[j].position, panels[j].size)
			if rect_a.intersects(rect_b):
				print("[TEST DEBUG] Panels overlap! Panel ", i, " and Panel ", j)
				await _cleanup_stack_system(_stack_system)
				return false
	
	await _cleanup_stack_system(_stack_system)
	return true


func _test_lane_preserved_across_rings() -> bool:
	"""Test that a group moving from Far → Melee stays in the same lane (far-left position)."""
	_stack_system = _setup_stack_system()
	
	# Create a group in Far ring at lane 0 (far left)
	var enemies: Array = _make_stub_enemies(3, 3, "husk", 1, 100)
	var group_id: String = "group_test"
	var key: String = "3_husk_" + group_id
	
	# Force assign to lane 0 (far left)
	_stack_system.set_group_lane(group_id, 0, 3)
	_stack_system.create_stack(3, "husk", enemies, key)
	
	await get_tree().process_frame
	
	# Get initial position
	var initial_lane: int = _stack_system.get_group_lane(group_id)
	var panel: Panel = _stack_system.get_stack_panel(key)
	var initial_x: float = panel.position.x if is_instance_valid(panel) else 0.0
	print("[TEST DEBUG] Initial lane: ", initial_lane, ", initial x: ", initial_x)
	
	# Simulate movement through rings: Far (3) → Mid (2) → Close (1) → Melee (0)
	for new_ring: int in [2, 1, 0]:
		# Release from old ring, occupy new ring (same lane)
		_stack_system.release_lane(group_id, new_ring + 1)
		_stack_system.set_group_lane(group_id, initial_lane, new_ring)
		_stack_system.update_stack_ring(key, new_ring, false)
		await get_tree().process_frame
	
	# Verify lane is still 0
	var final_lane: int = _stack_system.get_group_lane(group_id)
	var final_panel: Panel = _stack_system.get_stack_panel(key)
	var final_x: float = final_panel.position.x if is_instance_valid(final_panel) else 0.0
	print("[TEST DEBUG] Final lane: ", final_lane, ", final x: ", final_x)
	
	# Lane should be preserved
	var lane_preserved: bool = final_lane == initial_lane
	
	# X position should still be on the left side (roughly)
	# Since we're in lane 0, x should be relatively small (left side of semicircle)
	var still_on_left: bool = final_x < _stack_system.arena_center.x
	
	await _cleanup_stack_system(_stack_system)
	return lane_preserved and still_on_left


func _test_fill_all_lanes() -> bool:
	"""Test filling all 12 lanes and verify spacing."""
	_stack_system = _setup_stack_system()
	
	# Create 12 groups, one per lane
	for i: int in range(12):
		var enemies: Array = _make_stub_enemies(3, 2, "husk", i + 100, i * 100)
		var group_id: String = "group_" + str(i)
		var key: String = "2_husk_" + group_id
		
		# Force each group into a specific lane
		_stack_system.set_group_lane(group_id, i, 2)
		_stack_system.create_stack(2, "husk", enemies, key)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify all 12 lanes are occupied
	var lanes_occupied: int = _stack_system.get_groups_in_ring(2)
	print("[TEST DEBUG] Lanes occupied: ", lanes_occupied)
	
	if lanes_occupied != 12:
		await _cleanup_stack_system(_stack_system)
		return false
	
	# Get all panel positions and verify they're ordered left-to-right
	var positions: Array[float] = []
	for i: int in range(12):
		var key: String = "2_husk_group_" + str(i)
		var panel: Panel = _stack_system.get_stack_panel(key)
		if is_instance_valid(panel):
			positions.append(panel.position.x)
	
	# Verify ordering (each lane's x should be >= previous)
	# Allow larger tolerance (50px) for collision adjustment when many groups exist
	var ordered: bool = true
	for i: int in range(1, positions.size()):
		if positions[i] < positions[i - 1] - 50.0:
			print("[TEST DEBUG] Not ordered! Position ", i - 1, " (", positions[i - 1], ") > Position ", i, " (", positions[i], ")")
			ordered = false
	
	# Verify scale factor is applied (should be < 1.0 with 12 groups)
	var scale_factor: float = _stack_system.get_scale_factor_for_ring(2)
	print("[TEST DEBUG] Scale factor for 12 groups: ", scale_factor)
	var scale_reduced: bool = scale_factor < 1.0
	
	await _cleanup_stack_system(_stack_system)
	return ordered and scale_reduced


func _test_z_order_by_ring() -> bool:
	"""Test that z_index is correct per ring (Melee > Close > Mid > Far)."""
	_stack_system = _setup_stack_system()
	
	# Create one group per ring
	var z_indices: Dictionary = {}
	for ring: int in range(4):
		var enemies: Array = _make_stub_enemies(3, ring, "husk", ring + 1, ring * 100)
		var group_id: String = "group_ring_" + str(ring)
		var key: String = str(ring) + "_husk_" + group_id
		
		_stack_system.assign_random_lane(ring, group_id)
		_stack_system.create_stack(ring, "husk", enemies, key)
		
		var panel: Panel = _stack_system.get_stack_panel(key)
		if is_instance_valid(panel):
			z_indices[ring] = panel.z_index
			print("[TEST DEBUG] Ring ", ring, " z_index: ", panel.z_index)
	
	await get_tree().process_frame
	
	# Verify z_index ordering: ring 0 (Melee) should have highest z_index
	var z_order_correct: bool = true
	
	# Expected: Melee (ring 0) = 4, Close (ring 1) = 3, Mid (ring 2) = 2, Far (ring 3) = 1
	if z_indices.size() != 4:
		z_order_correct = false
	else:
		z_order_correct = (z_indices[0] > z_indices[1]) and (z_indices[1] > z_indices[2]) and (z_indices[2] > z_indices[3])
	
	await _cleanup_stack_system(_stack_system)
	return z_order_correct

