extends Node
## Test script to verify Shield Barrier visual effects

var rings: Control = null
var battlefield_arena: Control = null

func _ready() -> void:
	print("[TEST] TestBarrierVisual starting...")
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find the BattlefieldArena and its BattlefieldRings child
	battlefield_arena = _find_node_by_name(get_tree().root, "BattlefieldArena")
	if battlefield_arena:
		print("[TEST] Found BattlefieldArena")
		rings = battlefield_arena.get_node_or_null("BattlefieldRings")
		if rings:
			print("[TEST] Found BattlefieldRings")
		else:
			print("[TEST] ERROR: BattlefieldRings not found!")
	else:
		print("[TEST] ERROR: BattlefieldArena not found!")
	
	# Wait a bit more for everything to initialize
	await get_tree().create_timer(0.5).timeout
	
	_run_tests()


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result: Node = _find_node_by_name(child, target_name)
		if result:
			return result
	return null


func _run_tests() -> void:
	print("\n[TEST] === Testing Barrier Visual System ===\n")
	
	# Test 1: Verify ring_barriers dictionary is accessible
	print("[TEST] Test 1: Verify BattlefieldRings is accessible")
	if rings:
		print("[TEST] PASS: rings node exists")
		print("[TEST] - Ring barriers before: ", rings.ring_barriers)
	else:
		print("[TEST] FAIL: rings node is null")
		get_tree().quit(1)
		return
	
	# Test 2: Set a barrier directly on BattlefieldRings
	print("\n[TEST] Test 2: Setting barrier directly on BattlefieldRings")
	rings.set_barrier(1, 5, 2)  # Ring 1 (Close), 5 damage, 2 uses
	print("[TEST] - Ring barriers after set_barrier: ", rings.ring_barriers)
	
	if rings.ring_barriers.has(1):
		print("[TEST] PASS: Barrier added to dictionary")
		print("[TEST] - Barrier data: ", rings.ring_barriers[1])
	else:
		print("[TEST] FAIL: Barrier not in dictionary")
		get_tree().quit(1)
		return
	
	# Test 3: Verify signal connection
	print("\n[TEST] Test 3: Testing barrier_placed signal")
	print("[TEST] - CombatManager exists: ", CombatManager != null)
	print("[TEST] - barrier_placed signal connections: ", CombatManager.barrier_placed.get_connections())
	
	# Clear the barrier and test via signal
	rings.clear_barrier(1)
	print("[TEST] - Cleared barrier, barriers now: ", rings.ring_barriers)
	
	# Emit the signal directly to test the signal path
	print("[TEST] - Emitting barrier_placed signal for ring 2...")
	CombatManager.barrier_placed.emit(2, 10, 3)  # Ring 2, 10 damage, 3 uses
	
	# Wait for signal handling
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("[TEST] - Ring barriers after signal: ", rings.ring_barriers)
	
	if rings.ring_barriers.has(2):
		print("[TEST] PASS: Signal handler set barrier correctly")
	else:
		print("[TEST] FAIL: Signal handler did NOT set barrier!")
		print("[TEST] - This means _on_barrier_placed in BattlefieldArena is not working")
	
	# Test 4: Check the BattlefieldArena signal connection
	print("\n[TEST] Test 4: Verify BattlefieldArena signal connections")
	if battlefield_arena:
		print("[TEST] - BattlefieldArena.rings: ", battlefield_arena.rings)
		if battlefield_arena.rings:
			print("[TEST] - Arena's rings reference valid: PASS")
		else:
			print("[TEST] - Arena's rings reference is null: FAIL")
	
	# Wait a bit to see the visual
	print("\n[TEST] Tests complete. Setting a visible barrier for visual inspection...")
	rings.set_barrier(2, 8, 4)  # Ring 2 (Mid), 8 damage, 4 uses
	
	# Keep the scene open for 3 seconds to see the visual
	await get_tree().create_timer(3.0).timeout
	
	print("\n[TEST] Final ring_barriers state: ", rings.ring_barriers)
	print("[TEST] All tests complete!")
	get_tree().quit(0)



