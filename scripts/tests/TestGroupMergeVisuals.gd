extends Node
## Automated test for group visual cleanup after death
## Tests that when a group is killed, it stays dead after enemy turn

const STACK_THRESHOLD: int = 2

var battlefield_arena: Control
var stack_system: Control
var test_passed: bool = true
var test_step: int = 0


func _ready() -> void:
	print("[TEST] ==========================================")
	print("[TEST] TestGroupMergeVisuals - Dead Group Stays Dead")
	print("[TEST] ==========================================")
	
	# Wait for scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get references - CombatScreen is the instanced scene, BattlefieldArena is a direct child
	var combat_screen: Control = get_node_or_null("CombatScreen")
	if combat_screen:
		battlefield_arena = combat_screen.get_node_or_null("BattlefieldArena")
	if battlefield_arena:
		stack_system = battlefield_arena.get_node_or_null("BattlefieldStackSystem")
	
	print("[TEST] combat_screen: ", combat_screen)
	print("[TEST] battlefield_arena: ", battlefield_arena)
	print("[TEST] stack_system: ", stack_system)
	
	if not battlefield_arena or not stack_system:
		print("[TEST] FAILED: Could not find BattlefieldArena or StackSystem")
		_end_test(false)
		return
	
	print("[TEST] Found BattlefieldArena and StackSystem")
	
	# Initialize combat
	_setup_test_combat()
	
	await get_tree().create_timer(0.5).timeout
	
	# Run the DEAD GROUP test first
	await _run_dead_group_test()
	
	# Then run the merge test
	#await _run_merge_test()


func _setup_test_combat() -> void:
	"""Setup a test combat scenario with multiple groups in different rings."""
	print("[TEST] Setting up test combat...")
	
	# Clear visual state only (don't touch BattlefieldState - it's managed by CombatManager)
	battlefield_arena.enemy_groups.clear()
	stack_system.clear_all()
	
	# Remove all existing enemies from BattlefieldState
	var all_enemies: Array = CombatManager.battlefield.get_all_enemies().duplicate()
	for enemy in all_enemies:
		CombatManager.battlefield.remove_enemy(enemy)
	
	print("[TEST] Cleared state, spawning test enemies...")
	
	# Spawn group 1: 3 weaklings in ring 1 (Close)
	print("[TEST] Spawning group 1: 3 weaklings in ring 1 (Close)")
	for i in range(3):
		var enemy = CombatManager.battlefield.spawn_enemy("weakling", 1)
		battlefield_arena._create_or_update_enemy_visual(enemy)
	
	# Spawn group 2: 3 weaklings in ring 2 (Mid)
	print("[TEST] Spawning group 2: 3 weaklings in ring 2 (Mid)")
	for i in range(3):
		var enemy = CombatManager.battlefield.spawn_enemy("weakling", 2)
		battlefield_arena._create_or_update_enemy_visual(enemy)
	
	await get_tree().process_frame


func _run_dead_group_test() -> void:
	"""Test that a killed group doesn't reappear after enemy turn."""
	print("[TEST] ==========================================")
	print("[TEST] DEAD GROUP TEST: Kill group, simulate enemy turn")
	print("[TEST] ==========================================")
	
	# Setup: Create one group in ring 2 (Mid)
	battlefield_arena.enemy_groups.clear()
	stack_system.clear_all()
	
	var all_enemies: Array = CombatManager.battlefield.get_all_enemies().duplicate()
	for enemy in all_enemies:
		CombatManager.battlefield.remove_enemy(enemy)
	
	print("[TEST] Spawning group: 3 weaklings in ring 2 (Mid)")
	var spawned_enemies: Array = []
	for i in range(3):
		var enemy = CombatManager.battlefield.spawn_enemy("weakling", 2)
		battlefield_arena._create_or_update_enemy_visual(enemy)
		spawned_enemies.append(enemy)
	
	await get_tree().process_frame
	
	# Check initial state
	var initial_stack_count: int = stack_system.stack_visuals.size()
	print("[TEST] Initial stack count: ", initial_stack_count)
	print("[TEST] Initial stack keys: ", stack_system.stack_visuals.keys())
	print("[TEST] Initial enemy_groups: ")
	for gid in battlefield_arena.enemy_groups.keys():
		var g: Dictionary = battlefield_arena.enemy_groups[gid]
		print("[TEST]   ", gid, ": ring=", g.ring, " count=", g.enemies.size())
	
	if initial_stack_count != 1:
		print("[TEST] FAILED: Expected 1 stack initially, got ", initial_stack_count)
		_end_test(false)
		return
	
	var original_stack_key: String = stack_system.stack_visuals.keys()[0]
	print("[TEST] Original stack key: ", original_stack_key)
	
	# STEP 1: Kill all enemies in the group
	print("[TEST] ==========================================")
	print("[TEST] Step 1: Kill all enemies in the group")
	print("[TEST] ==========================================")
	
	for enemy in spawned_enemies:
		print("[TEST]   Killing enemy instance_id=", enemy.instance_id)
		CombatManager.battlefield.remove_enemy(enemy)
		CombatManager.enemy_killed.emit(enemy)
	
	# Wait for death animations and delayed stack removal
	await get_tree().create_timer(0.6).timeout
	
	var after_kill_stack_count: int = stack_system.stack_visuals.size()
	print("[TEST] Stack count after kills (after 0.6s delay): ", after_kill_stack_count)
	print("[TEST] Stack keys after kills: ", stack_system.stack_visuals.keys())
	print("[TEST] enemy_groups after kills: ")
	for gid in battlefield_arena.enemy_groups.keys():
		var g: Dictionary = battlefield_arena.enemy_groups[gid]
		print("[TEST]   ", gid, ": ring=", g.ring, " count=", g.enemies.size())
	
	if after_kill_stack_count != 0:
		print("[TEST] FAILED: Expected 0 stacks after killing all enemies, got ", after_kill_stack_count)
		_end_test(false)
		return
	
	print("[TEST] Stack properly removed after kills")
	
	# STEP 2: Simulate enemy turn - spawn new enemies in a different ring and move them
	print("[TEST] ==========================================")
	print("[TEST] Step 2: Simulate enemy turn (spawn + move)")
	print("[TEST] ==========================================")
	
	# Spawn new enemies in ring 3 (Far)
	print("[TEST] Spawning new group: 2 weaklings in ring 3 (Far)")
	var new_enemies: Array = []
	for i in range(2):
		var enemy = CombatManager.battlefield.spawn_enemy("weakling", 3)
		battlefield_arena._create_or_update_enemy_visual(enemy)
		new_enemies.append(enemy)
	
	await get_tree().process_frame
	
	print("[TEST] After spawning new enemies:")
	print("[TEST]   Stack count: ", stack_system.stack_visuals.size())
	print("[TEST]   Stack keys: ", stack_system.stack_visuals.keys())
	
	# Simulate enemy movement: move new enemies from ring 3 to ring 2
	print("[TEST] Moving new enemies from ring 3 to ring 2")
	for enemy in new_enemies:
		var from_ring: int = enemy.ring
		CombatManager.battlefield.move_enemy(enemy, 2)
		CombatManager.enemy_moved.emit(enemy, from_ring, 2)
	
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	
	# STEP 3: Verify final state
	print("[TEST] ==========================================")
	print("[TEST] Step 3: Verify dead group didn't reappear")
	print("[TEST] ==========================================")
	
	var final_stack_count: int = stack_system.stack_visuals.size()
	print("[TEST] Final stack count: ", final_stack_count)
	print("[TEST] Final stack keys: ", stack_system.stack_visuals.keys())
	print("[TEST] Final enemy_groups: ")
	for gid in battlefield_arena.enemy_groups.keys():
		var g: Dictionary = battlefield_arena.enemy_groups[gid]
		print("[TEST]   ", gid, ": ring=", g.ring, " count=", g.enemies.size())
	
	# Count visible panel children
	var visible_panels: int = 0
	for child in stack_system.get_children():
		if child is Panel and child.visible:
			visible_panels += 1
			print("[TEST]   Visible panel: ", child.name, " at ", child.position)
	
	print("[TEST] Visible panel children in StackSystem: ", visible_panels)
	
	# Verify the original killed stack didn't come back
	if stack_system.stack_visuals.has(original_stack_key):
		print("[TEST] FAILED: Original killed stack '", original_stack_key, "' reappeared!")
		_end_test(false)
		return
	
	# Should have exactly 1 stack for the new enemies
	if final_stack_count != 1:
		print("[TEST] FAILED: Expected 1 stack, got ", final_stack_count)
		_end_test(false)
		return
	
	if visible_panels != 1:
		print("[TEST] FAILED: Expected 1 visible panel, got ", visible_panels)
		_end_test(false)
		return
	
	print("[TEST] PASSED: Dead group stayed dead!")
	_end_test(true)


func _run_merge_test() -> void:
	"""Run the merge test sequence."""
	print("[TEST] ==========================================")
	print("[TEST] Step 1: Verify initial state")
	print("[TEST] ==========================================")
	
	# Check initial stack count
	var initial_stack_count: int = stack_system.stack_visuals.size()
	print("[TEST] Initial stack count: ", initial_stack_count)
	print("[TEST] Stack keys: ", stack_system.stack_visuals.keys())
	
	# Should have 2 stacks (one for each ring)
	if initial_stack_count != 2:
		print("[TEST] FAILED: Expected 2 stacks, got ", initial_stack_count)
		_end_test(false)
		return
	
	# Find the stack in ring 1
	var ring1_stack_key: String = ""
	var ring2_stack_key: String = ""
	for key in stack_system.stack_visuals.keys():
		var stack_data: Dictionary = stack_system.stack_visuals[key]
		if stack_data.ring == 1:
			ring1_stack_key = key
		elif stack_data.ring == 2:
			ring2_stack_key = key
	
	print("[TEST] Ring 1 stack key: ", ring1_stack_key)
	print("[TEST] Ring 2 stack key: ", ring2_stack_key)
	
	if ring1_stack_key.is_empty() or ring2_stack_key.is_empty():
		print("[TEST] FAILED: Could not find stacks for both rings")
		_end_test(false)
		return
	
	print("[TEST] PASSED: Initial state correct")
	
	print("[TEST] ==========================================")
	print("[TEST] Step 2: Kill all enemies in ring 1")
	print("[TEST] ==========================================")
	
	# Kill all enemies in ring 1
	var ring1_enemies: Array = CombatManager.battlefield.get_enemies_in_ring(1).duplicate()
	print("[TEST] Killing ", ring1_enemies.size(), " enemies in ring 1")
	
	for enemy in ring1_enemies:
		print("[TEST]   Killing enemy instance_id=", enemy.instance_id)
		CombatManager.battlefield.remove_enemy(enemy)
		CombatManager.enemy_killed.emit(enemy)
	
	await get_tree().create_timer(0.5).timeout
	
	# Check stack count after kills
	var after_kill_stack_count: int = stack_system.stack_visuals.size()
	print("[TEST] Stack count after kills: ", after_kill_stack_count)
	print("[TEST] Stack keys after kills: ", stack_system.stack_visuals.keys())
	
	# Ring 1 stack should be removed (0 enemies)
	if after_kill_stack_count != 1:
		print("[TEST] WARNING: Expected 1 stack after killing ring 1, got ", after_kill_stack_count)
	
	print("[TEST] ==========================================")
	print("[TEST] Step 3: Move ring 2 enemies to ring 1")
	print("[TEST] ==========================================")
	
	# Get enemies in ring 2
	var ring2_enemies: Array = CombatManager.battlefield.get_enemies_in_ring(2).duplicate()
	print("[TEST] Moving ", ring2_enemies.size(), " enemies from ring 2 to ring 1")
	
	# Print enemy groups before move
	print("[TEST] Enemy groups before move:")
	for gid in battlefield_arena.enemy_groups.keys():
		var group: Dictionary = battlefield_arena.enemy_groups[gid]
		print("[TEST]   ", gid, ": ring=", group.ring, " enemy_id=", group.enemy_id, " count=", group.enemies.size())
	
	# Move each enemy
	for enemy in ring2_enemies:
		var from_ring: int = enemy.ring
		CombatManager.battlefield.move_enemy(enemy, 1)
		CombatManager.enemy_moved.emit(enemy, from_ring, 1)
	
	await get_tree().create_timer(0.5).timeout
	
	print("[TEST] ==========================================")
	print("[TEST] Step 4: Verify final state")
	print("[TEST] ==========================================")
	
	# Check final stack count
	var final_stack_count: int = stack_system.stack_visuals.size()
	print("[TEST] Final stack count: ", final_stack_count)
	print("[TEST] Final stack keys: ", stack_system.stack_visuals.keys())
	
	# Print enemy groups after move
	print("[TEST] Enemy groups after move:")
	for gid in battlefield_arena.enemy_groups.keys():
		var group: Dictionary = battlefield_arena.enemy_groups[gid]
		print("[TEST]   ", gid, ": ring=", group.ring, " enemy_id=", group.enemy_id, " count=", group.enemies.size())
	
	# Should have exactly 1 stack (the one that moved to ring 1)
	if final_stack_count != 1:
		print("[TEST] FAILED: Expected 1 stack after move, got ", final_stack_count)
		print("[TEST]   This indicates orphaned stack panels!")
		_end_test(false)
		return
	
	# Verify the remaining stack is in ring 1
	var remaining_stack_data: Dictionary = stack_system.stack_visuals.values()[0]
	if remaining_stack_data.ring != 1:
		print("[TEST] FAILED: Remaining stack is in ring ", remaining_stack_data.ring, ", expected ring 1")
		_end_test(false)
		return
	
	# Verify it has 3 enemies
	if remaining_stack_data.enemies.size() != 3:
		print("[TEST] FAILED: Stack has ", remaining_stack_data.enemies.size(), " enemies, expected 3")
		_end_test(false)
		return
	
	# Count actual visible children in stack_system
	var visible_panels: int = 0
	for child in stack_system.get_children():
		if child is Panel and child.visible:
			visible_panels += 1
	
	print("[TEST] Visible panel children in StackSystem: ", visible_panels)
	
	if visible_panels > 1:
		print("[TEST] FAILED: Found ", visible_panels, " visible panels, expected 1")
		print("[TEST]   This indicates orphaned visual panels!")
		_end_test(false)
		return
	
	print("[TEST] PASSED: All checks passed!")
	_end_test(true)


func _end_test(passed: bool) -> void:
	print("[TEST] ==========================================")
	if passed:
		print("[TEST] RESULT: PASSED ✓")
	else:
		print("[TEST] RESULT: FAILED ✗")
	print("[TEST] ==========================================")
	
	# Exit with appropriate code
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0 if passed else 1)

