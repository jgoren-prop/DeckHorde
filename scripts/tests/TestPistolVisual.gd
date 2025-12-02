extends Control
## TestPistolVisual - Automated test for the 2.5D pistol visual on gun cards
## This test:
## 1. Creates a CombatLane
## 2. Gets the "Rusty Pistol" card from CardDatabase
## 3. Deploys it to the lane
## 4. Verifies the pistol visual appears and is visible
## 5. Reports success/failure

const CombatLaneScript: GDScript = preload("res://scripts/ui/CombatLane.gd")

var combat_lane: Control = null
var test_passed: bool = false
var test_complete: bool = false

func _ready() -> void:
	print("[TEST] ========================================")
	print("[TEST] Starting PistolVisual Test")
	print("[TEST] ========================================")
	
	# Wait a frame for everything to initialize
	await get_tree().process_frame
	
	# Run the test
	await _run_test()
	
	# Wait for animations to complete
	await get_tree().create_timer(1.0).timeout
	
	# Verify results
	_verify_results()
	
	# Report and exit
	_report_and_exit()


func _run_test() -> void:
	print("[TEST] Step 1: Creating CombatLane...")
	
	# Create the combat lane - it's a Control with a script, not a separate scene
	combat_lane = Control.new()
	combat_lane.set_script(CombatLaneScript)
	combat_lane.position = Vector2(100, 300)
	combat_lane.size = Vector2(800, 150)
	add_child(combat_lane)
	
	print("[TEST] CombatLane created at position: ", combat_lane.position)
	
	# Wait a frame for it to initialize
	await get_tree().process_frame
	
	print("[TEST] Step 2: Getting Rusty Pistol card from database...")
	
	# Get the Rusty Pistol card
	var rusty_pistol = CardDatabase.get_card("rusty_pistol")
	if not rusty_pistol:
		print("[TEST] ERROR: Could not find 'rusty_pistol' card in database!")
		print("[TEST] Available cards: ", CardDatabase.get_all_card_ids())
		return
	
	print("[TEST] Found Rusty Pistol: ", rusty_pistol.card_name)
	print("[TEST] Card tags: ", rusty_pistol.tags)
	print("[TEST] Core type: ", rusty_pistol.get_core_type())
	
	# Check if it's detected as a gun card
	var is_gun: bool = "gun" in rusty_pistol.tags if rusty_pistol.tags else false
	print("[TEST] Is gun card (has 'gun' tag): ", is_gun)
	
	print("[TEST] Step 3: Deploying weapon to lane...")
	
	# Deploy with a drop position (simulating a card drop)
	var drop_pos: Vector2 = Vector2(400, 400)
	combat_lane.deploy_weapon(rusty_pistol, 1, -1, drop_pos)
	
	print("[TEST] Weapon deployed. Waiting for animation...")


func _verify_results() -> void:
	print("[TEST] ========================================")
	print("[TEST] Step 4: Verifying results...")
	print("[TEST] ========================================")
	
	# Check if weapon was deployed
	var deployed_count: int = combat_lane.get_deployed_count()
	print("[TEST] Deployed weapons count: ", deployed_count)
	
	if deployed_count == 0:
		print("[TEST] FAIL: No weapons deployed!")
		return
	
	# Get the deployed weapon data
	var weapons: Array = combat_lane.deployed_weapons
	var weapon: Dictionary = weapons[0]
	
	print("[TEST] Weapon card_def: ", weapon.card_def.card_name)
	print("[TEST] Weapon card_ui valid: ", is_instance_valid(weapon.card_ui))
	print("[TEST] Weapon pistol_visual: ", weapon.get("pistol_visual", "NOT SET"))
	
	var pistol_visual: Control = weapon.get("pistol_visual", null)
	
	if not pistol_visual:
		print("[TEST] FAIL: No pistol_visual in weapon data!")
		return
	
	if not is_instance_valid(pistol_visual):
		print("[TEST] FAIL: pistol_visual is invalid!")
		return
	
	print("[TEST] Pistol visual exists and is valid")
	
	# Check visibility
	print("[TEST] Pistol visible: ", pistol_visual.visible)
	print("[TEST] Pistol modulate.a: ", pistol_visual.modulate.a)
	print("[TEST] Pistol position: ", pistol_visual.position)
	print("[TEST] Pistol scale: ", pistol_visual.scale)
	print("[TEST] Pistol size: ", pistol_visual.size)
	print("[TEST] Pistol global_position: ", pistol_visual.global_position)
	
	# Check the pistol_container inside
	var pistol_container: Control = pistol_visual.pistol_container if "pistol_container" in pistol_visual else null
	if pistol_container:
		print("[TEST] Pistol container found")
		print("[TEST] Pistol container position: ", pistol_container.position)
		print("[TEST] Pistol container size: ", pistol_container.size)
		print("[TEST] Pistol container modulate.a: ", pistol_container.modulate.a)
		print("[TEST] Pistol container children count: ", pistol_container.get_child_count())
	else:
		print("[TEST] WARNING: No pistol_container found in pistol_visual")
	
	# Check parent card_ui
	var card_ui: Control = weapon.card_ui
	if card_ui:
		print("[TEST] Card UI position: ", card_ui.position)
		print("[TEST] Card UI global_position: ", card_ui.global_position)
		print("[TEST] Card UI scale: ", card_ui.scale)
		print("[TEST] Card UI modulate.a: ", card_ui.modulate.a)
		print("[TEST] Card UI size: ", card_ui.size)
		print("[TEST] Card UI children: ", card_ui.get_child_count())
		
		# Check if pistol is a child of card_ui
		var pistol_is_child: bool = pistol_visual.get_parent() == card_ui
		print("[TEST] Pistol is child of card_ui: ", pistol_is_child)
	
	# Determine pass/fail
	var alpha_ok: bool = pistol_visual.modulate.a > 0.5  # Should be 1.0 after animation
	var scale_ok: bool = pistol_visual.scale.x > 0.5 and pistol_visual.scale.y > 0.5  # Should be 1.0 after animation
	var visible_ok: bool = pistol_visual.visible
	
	print("[TEST] ----------------------------------------")
	print("[TEST] Visibility check: ", visible_ok)
	print("[TEST] Alpha check (> 0.5): ", alpha_ok, " (actual: ", pistol_visual.modulate.a, ")")
	print("[TEST] Scale check (> 0.5): ", scale_ok, " (actual: ", pistol_visual.scale, ")")
	
	test_passed = alpha_ok and scale_ok and visible_ok
	test_complete = true


func _report_and_exit() -> void:
	print("[TEST] ========================================")
	if test_passed:
		print("[TEST] RESULT: PASSED ✓")
	else:
		print("[TEST] RESULT: FAILED ✗")
	print("[TEST] ========================================")
	
	# Wait a moment before quitting so output can be captured
	await get_tree().create_timer(0.5).timeout
	
	# Quit with appropriate exit code
	if test_passed:
		get_tree().quit(0)
	else:
		get_tree().quit(1)

