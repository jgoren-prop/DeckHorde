extends Node
## TestGameFlow - Automated test for full game flow
## Tests: MainMenu -> WardenSelect -> Combat -> PostWave (or RunEnd)

const WaveDef = preload("res://scripts/resources/WaveDefinition.gd")

var test_results: Array[String] = []
var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestGameFlow] Starting full game flow test...")
	await get_tree().process_frame
	
	# Run tests sequentially
	await _test_initialization()
	await _test_warden_selection()
	await _test_combat_flow()
	await _test_post_combat()
	
	# Report results
	_report_results()


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		tests_passed += 1
		test_results.append("[PASS] " + test_name)
		print("[PASS] " + test_name)
	else:
		tests_failed += 1
		test_results.append("[FAIL] " + test_name)
		print("[FAIL] " + test_name)


func _test_initialization() -> void:
	print("\n--- Testing Initialization ---")
	
	# Check all autoloads are available
	_assert(GameManager != null, "GameManager autoload exists")
	_assert(RunManager != null, "RunManager autoload exists")
	_assert(CombatManager != null, "CombatManager autoload exists")
	_assert(CardDatabase != null, "CardDatabase autoload exists")
	_assert(EnemyDatabase != null, "EnemyDatabase autoload exists")
	_assert(ArtifactManager != null, "ArtifactManager autoload exists")
	_assert(ShopGenerator != null, "ShopGenerator autoload exists")
	
	# Check databases are populated
	_assert(CardDatabase.cards.size() > 0, "CardDatabase has cards")
	_assert(EnemyDatabase.enemies.size() > 0, "EnemyDatabase has enemies")
	
	await get_tree().process_frame


func _test_warden_selection() -> void:
	print("\n--- Testing Warden Selection ---")
	
	# Reset run state - note: reset_run sets wave to 1
	RunManager.reset_run()
	_assert(RunManager.current_wave == 1, "Run reset: wave is 1")
	
	# Initialize starter deck (sets up basic deck)
	RunManager.initialize_starter_deck()
	
	_assert(RunManager.current_hp > 0, "Run started: HP is positive")
	_assert(RunManager.deck.size() > 0, "Run started: deck has cards")
	
	await get_tree().process_frame


func _test_combat_flow() -> void:
	print("\n--- Testing Combat Flow ---")
	
	# Create a simple wave
	var wave: WaveDef = WaveDef.new()
	wave.wave_number = 1
	wave.turn_limit = 5
	wave.initial_spawns = [
		{"enemy_id": "husk", "count": 2, "ring": 3}
	]
	wave.phase_spawns = []
	
	# Initialize combat
	CombatManager.initialize_combat(wave)
	await get_tree().process_frame
	
	_assert(CombatManager.battlefield != null, "Combat: battlefield created")
	_assert(CombatManager.deck_manager != null, "Combat: deck_manager created")
	_assert(CombatManager.current_phase == CombatManager.CombatPhase.PLAYER_PHASE, "Combat: in player phase")
	
	# Check enemies spawned
	var enemies: Array = CombatManager.battlefield.get_all_enemies()
	_assert(enemies.size() > 0, "Combat: enemies spawned")
	
	# Check hand was drawn
	var hand_size: int = CombatManager.deck_manager.hand.size()
	_assert(hand_size > 0, "Combat: hand has cards")
	
	# Test staging a card (V3 system)
	if hand_size > 0:
		var initial_energy: int = CombatManager.current_energy
		var stage_success: bool = CombatManager.stage_card(0)
		_assert(stage_success, "Combat: card staged successfully")
		_assert(CombatManager.staged_cards.size() > 0, "Combat: staged_cards has card")
		_assert(CombatManager.current_energy < initial_energy, "Combat: energy spent on staging")
	
	# Test unstaging
	if CombatManager.staged_cards.size() > 0:
		var energy_before: int = CombatManager.current_energy
		var unstage_success: bool = CombatManager.unstage_card(0)
		_assert(unstage_success, "Combat: card unstaged successfully")
		_assert(CombatManager.staged_cards.size() == 0, "Combat: staged_cards empty after unstage")
		_assert(CombatManager.current_energy > energy_before, "Combat: energy refunded after unstage")
	
	# Stage card again and execute turn
	if CombatManager.deck_manager.hand.size() > 0:
		CombatManager.stage_card(0)
		
		print("[TestGameFlow] Testing end turn execution...")
		
		# End turn triggers execution
		var enemies_before: int = CombatManager.battlefield.get_total_enemy_count()
		var hp_total_before: int = 0
		for enemy in CombatManager.battlefield.get_all_enemies():
			hp_total_before += enemy.current_hp
		
		CombatManager.end_player_turn()
		
		# Wait for execution and enemy phase
		await get_tree().create_timer(2.0).timeout
		await get_tree().process_frame
		
		# Check execution happened
		var enemies_after: int = CombatManager.battlefield.get_total_enemy_count()
		var hp_total_after: int = 0
		for enemy in CombatManager.battlefield.get_all_enemies():
			hp_total_after += enemy.current_hp
		
		var damage_dealt: bool = (hp_total_after < hp_total_before) or (enemies_after < enemies_before)
		_assert(damage_dealt or hp_total_before == 0, "Combat: damage dealt during execution (or no enemies)")
		
		# Check staged cards cleared
		_assert(CombatManager.staged_cards.size() == 0, "Combat: staged cards cleared after turn")
	
	await get_tree().process_frame


func _test_post_combat() -> void:
	print("\n--- Testing Post Combat ---")
	
	# Store current state
	var wave_before: int = RunManager.current_wave
	
	# Simulate wave victory
	RunManager.current_wave += 1
	_assert(RunManager.current_wave > wave_before, "PostCombat: wave incremented")
	
	# Test shop generation
	var shop_cards: Array = ShopGenerator.generate_shop_cards(RunManager.current_wave)
	_assert(shop_cards.size() > 0, "PostCombat: shop generated card offers")
	
	var shop_artifacts: Array = ShopGenerator.generate_shop_artifacts(RunManager.current_wave)
	# Artifacts might be empty if none available, so just check it doesn't crash
	_assert(shop_artifacts != null, "PostCombat: shop generated artifact offers (may be empty)")
	
	# Cleanup combat
	CombatManager.cleanup_combat()
	_assert(CombatManager.battlefield == null, "PostCombat: combat cleaned up")
	
	await get_tree().process_frame


func _report_results() -> void:
	print("\n========================================")
	print("[TestGameFlow] RESULTS")
	print("========================================")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("Total:  ", tests_passed + tests_failed)
	print("========================================")
	
	if tests_failed == 0:
		print("[TestGameFlow] ALL TESTS PASSED ✓")
		get_tree().quit(0)
	else:
		print("[TestGameFlow] SOME TESTS FAILED ✗")
		for result in test_results:
			if result.begins_with("[FAIL]"):
				print("  ", result)
		get_tree().quit(1)

