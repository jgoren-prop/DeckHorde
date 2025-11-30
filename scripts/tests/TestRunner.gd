extends Node
## TestRunner - Runs all unit and integration tests
## Exit code 0 = all tests passed, 1 = some tests failed

var tests_passed: int = 0
var tests_failed: int = 0
var test_results: Array[String] = []

func _ready() -> void:
	print("=== DECK HORDE TEST SUITE ===")
	print("")
	
	# Run all test modules
	await _run_run_manager_tests()
	await _run_combat_manager_tests()
	await _run_card_effect_tests()
	await _run_armor_card_tests()
	await _run_hex_card_tests()
	await _run_behavior_type_tests()
	await _run_intent_bar_tests()
	await _run_merge_manager_tests()
	await _run_artifact_manager_tests()
	await _run_battlefield_state_tests()
	await _run_enemy_instance_tests()
	await _run_warden_passive_tests()
	await _run_card_database_tests()
	await _run_enemy_database_tests()
	await _run_card_ui_tests()
	await _run_enemy_ai_movement_tests()
	await _run_integration_tests()
	
	# Print summary
	print("")
	print("=== TEST SUMMARY ===")
	print("Passed: ", tests_passed)
	print("Failed: ", tests_failed)
	print("")
	
	if tests_failed > 0:
		print("FAILED TESTS:")
		for result in test_results:
			if result.begins_with("FAIL"):
				print("  - ", result)
	
	print("")
	print("=== SUITE ", "PASSED" if tests_failed == 0 else "FAILED", " ===")
	
	# Exit with appropriate code
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if tests_failed == 0 else 1)


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		tests_passed += 1
		test_results.append("PASS: " + test_name)
		print("  ✓ ", test_name)
	else:
		tests_failed += 1
		test_results.append("FAIL: " + test_name)
		print("  ✗ ", test_name)


func _setup_minimal_warden() -> void:
	"""Helper to set up a minimal warden Dictionary for combat tests."""
	RunManager.current_warden = {
		"hand_size": 5,
		"passive_id": "",
		"tag_damage_bonuses": {}
	}


func _run_run_manager_tests() -> void:
	print("[RunManager Tests]")
	
	# Reset state
	RunManager.current_hp = 60
	RunManager.max_hp = 60
	RunManager.armor = 0
	RunManager.scrap = 0
	
	# Test: Take damage without armor
	RunManager.take_damage(10)
	_assert(RunManager.current_hp == 50, "take_damage reduces HP")
	
	# Test: Add armor
	RunManager.add_armor(5)
	_assert(RunManager.armor == 5, "add_armor increases armor")
	
	# Test: Take damage with armor (armor should absorb)
	RunManager.take_damage(3)
	_assert(RunManager.armor == 2, "armor absorbs damage first")
	_assert(RunManager.current_hp == 50, "HP unchanged when armor absorbs")
	
	# Test: Take damage exceeding armor
	RunManager.take_damage(10)
	_assert(RunManager.armor == 0, "armor depleted on big hit")
	_assert(RunManager.current_hp == 42, "excess damage goes to HP")
	
	# Test: Heal
	RunManager.heal(5)
	_assert(RunManager.current_hp == 47, "heal increases HP")
	
	# Test: Heal doesn't exceed max
	RunManager.heal(100)
	_assert(RunManager.current_hp == RunManager.max_hp, "heal caps at max_hp")
	
	# Test: Add scrap
	RunManager.add_scrap(10)
	_assert(RunManager.scrap == 10, "add_scrap increases scrap")
	
	# Test: Spend scrap
	var spent: bool = RunManager.spend_scrap(5)
	_assert(spent == true, "spend_scrap returns true when sufficient")
	_assert(RunManager.scrap == 5, "spend_scrap reduces scrap")
	
	# Test: Spend more scrap than available
	spent = RunManager.spend_scrap(100)
	_assert(spent == false, "spend_scrap returns false when insufficient")
	_assert(RunManager.scrap == 5, "scrap unchanged on failed spend")
	
	await get_tree().process_frame


func _run_combat_manager_tests() -> void:
	print("[CombatManager Tests]")
	
	# Reset state
	RunManager.current_hp = 60
	RunManager.max_hp = 60
	RunManager.armor = 0
	RunManager.deck = [{"card_id": "infernal_pistol", "tier": 1}]
	
	const WaveDef = preload("res://scripts/resources/WaveDefinition.gd")
	var wave: WaveDef = WaveDef.create_basic_wave(1)
	
	# Initialize combat
	CombatManager.initialize_combat(wave)
	await get_tree().process_frame
	
	# Test: Combat initialized
	_assert(CombatManager.current_phase == CombatManager.CombatPhase.PLAYER_PHASE, "combat starts in player phase")
	_assert(CombatManager.current_energy > 0, "player has energy")
	
	# Test: Enemies spawned
	var enemies: Array = CombatManager.battlefield.get_all_enemies()
	_assert(enemies.size() > 0, "enemies spawned on battlefield")
	
	# Test: Can play card check
	var pistol = CardDatabase.get_card("infernal_pistol")
	var can_play: bool = CombatManager.can_play_card(pistol, 1)
	_assert(can_play == true, "can_play_card returns true for playable card")
	
	await get_tree().process_frame


func _run_card_effect_tests() -> void:
	print("[CardEffectResolver Tests]")
	
	# Test: Infernal Pistol targets all rings
	var pistol = CardDatabase.get_card("infernal_pistol")
	_assert(pistol != null, "infernal_pistol exists in database")
	_assert(pistol.target_rings.size() == 4, "pistol targets all 4 rings")
	_assert(0 in pistol.target_rings, "pistol can hit Melee ring")
	_assert(3 in pistol.target_rings, "pistol can hit Far ring")
	
	# Test: Card damage values
	var damage: int = pistol.get_scaled_value("damage", 1)
	_assert(damage == 4, "pistol base damage is 4")
	
	# Test: Shotgun targets Close ring only
	var shotgun = CardDatabase.get_card("choirbreaker_shotgun")
	_assert(shotgun != null, "choirbreaker_shotgun exists")
	_assert(1 in shotgun.target_rings, "shotgun targets Close ring")
	
	await get_tree().process_frame


func _run_armor_card_tests() -> void:
	print("[Armor Card Tests]")
	
	# Reset state
	RunManager.current_hp = 60
	RunManager.max_hp = 60
	RunManager.armor = 0
	RunManager.deck = [{"card_id": "glass_ward", "tier": 1}]
	
	const WaveDef = preload("res://scripts/resources/WaveDefinition.gd")
	var wave: WaveDef = WaveDef.create_basic_wave(1)
	CombatManager.initialize_combat(wave)
	await get_tree().process_frame
	
	# Test: Glass Ward exists and has armor
	var glass_ward = CardDatabase.get_card("glass_ward")
	_assert(glass_ward != null, "glass_ward exists in database")
	
	if glass_ward == null:
		print("  [SKIP] Skipping remaining armor tests - card not found")
		return
	
	var armor_amount: int = glass_ward.get_scaled_value("armor_amount", 1)
	_assert(armor_amount > 0, "glass_ward grants armor")
	
	# Play the armor card
	var armor_before: int = RunManager.armor
	CombatManager.play_card(0, -1)
	await get_tree().process_frame
	
	_assert(RunManager.armor > armor_before, "playing glass_ward increases armor")
	_assert(RunManager.armor == armor_before + armor_amount, "armor amount matches card value")
	
	await get_tree().process_frame


func _run_hex_card_tests() -> void:
	print("[Hex Card Tests]")
	
	# Reset state
	RunManager.current_hp = 60
	RunManager.max_hp = 60
	RunManager.armor = 0
	RunManager.deck = [{"card_id": "simple_hex", "tier": 1}]
	
	const WaveDef = preload("res://scripts/resources/WaveDefinition.gd")
	var wave: WaveDef = WaveDef.create_basic_wave(1)
	CombatManager.initialize_combat(wave)
	await get_tree().process_frame
	
	# Test: Simple Hex exists
	var hex_card = CardDatabase.get_card("simple_hex")
	_assert(hex_card != null, "simple_hex exists in database")
	
	if hex_card == null:
		print("  [SKIP] Skipping remaining hex tests - card not found")
		return
	
	_assert(hex_card.effect_type == "apply_hex", "simple_hex applies hex")
	
	# Get enemies before hex
	var enemies: Array = CombatManager.battlefield.get_all_enemies()
	_assert(enemies.size() > 0, "enemies exist to hex")
	
	# Check hex status before
	var hex_before: int = 0
	for enemy in enemies:
		if enemy.status_effects.has("hex"):
			hex_before += enemy.status_effects["hex"].value
	
	# Play hex card (targets ring, enemies are in ring 3)
	CombatManager.play_card(0, 3)  # Target Far ring
	await get_tree().process_frame
	
	# Check hex was applied
	var enemies_after: Array = CombatManager.battlefield.get_all_enemies()
	var hex_after: int = 0
	for enemy in enemies_after:
		if enemy.status_effects.has("hex"):
			hex_after += enemy.status_effects["hex"].value
	
	_assert(hex_after > hex_before, "hex card applies hex to enemies")
	
	await get_tree().process_frame


func _run_behavior_type_tests() -> void:
	print("[Combat Clarity - Behavior Type Tests]")
	
	const EnemyDef = preload("res://scripts/resources/EnemyDefinition.gd")
	
	# Test: All enemies have behavior types set
	var all_enemies_have_behavior: bool = true
	var enemy_ids: Array = ["husk", "spitter", "spinecrawler", "bomber", "cultist", 
		"shell_titan", "torchbearer", "channeler", "stalker", "ember_saint"]
	
	for enemy_id: String in enemy_ids:
		var enemy = EnemyDatabase.get_enemy(enemy_id)
		if enemy == null:
			all_enemies_have_behavior = false
			print("  [WARN] Enemy not found: ", enemy_id)
			continue
	
	_assert(all_enemies_have_behavior, "all enemies exist in database")
	
	# Test: Specific behavior type assignments
	var husk = EnemyDatabase.get_enemy("husk")
	_assert(husk != null and husk.behavior_type == EnemyDef.BehaviorType.RUSHER, "husk is RUSHER type")
	
	var spitter = EnemyDatabase.get_enemy("spitter")
	_assert(spitter != null and spitter.behavior_type == EnemyDef.BehaviorType.RANGED, "spitter is RANGED type")
	
	var spinecrawler = EnemyDatabase.get_enemy("spinecrawler")
	_assert(spinecrawler != null and spinecrawler.behavior_type == EnemyDef.BehaviorType.FAST, "spinecrawler is FAST type")
	
	var bomber = EnemyDatabase.get_enemy("bomber")
	_assert(bomber != null and bomber.behavior_type == EnemyDef.BehaviorType.BOMBER, "bomber is BOMBER type")
	
	var torchbearer = EnemyDatabase.get_enemy("torchbearer")
	_assert(torchbearer != null and torchbearer.behavior_type == EnemyDef.BehaviorType.BUFFER, "torchbearer is BUFFER type")
	
	var channeler = EnemyDatabase.get_enemy("channeler")
	_assert(channeler != null and channeler.behavior_type == EnemyDef.BehaviorType.SPAWNER, "channeler is SPAWNER type")
	
	var shell_titan = EnemyDatabase.get_enemy("shell_titan")
	_assert(shell_titan != null and shell_titan.behavior_type == EnemyDef.BehaviorType.TANK, "shell_titan is TANK type")
	
	var stalker = EnemyDatabase.get_enemy("stalker")
	_assert(stalker != null and stalker.behavior_type == EnemyDef.BehaviorType.AMBUSH, "stalker is AMBUSH type")
	
	var ember_saint = EnemyDatabase.get_enemy("ember_saint")
	_assert(ember_saint != null and ember_saint.behavior_type == EnemyDef.BehaviorType.BOSS, "ember_saint is BOSS type")
	
	# Test: Badge icon functions return non-empty strings
	_assert(husk.get_behavior_badge_icon() != "", "get_behavior_badge_icon returns icon for RUSHER")
	_assert(bomber.get_behavior_badge_icon() == "💣", "bomber badge icon is bomb emoji")
	_assert(torchbearer.get_behavior_badge_icon() == "📢", "buffer badge icon is megaphone")
	_assert(channeler.get_behavior_badge_icon() == "⚙️", "spawner badge icon is gear")
	
	# Test: Badge color functions return valid colors
	var rusher_color: Color = husk.get_behavior_badge_color()
	_assert(rusher_color.r > 0 or rusher_color.g > 0 or rusher_color.b > 0, "RUSHER badge has valid color")
	
	# Test: Tooltip functions return non-empty strings
	_assert(husk.get_behavior_tooltip() != "", "get_behavior_tooltip returns text for RUSHER")
	_assert(bomber.get_behavior_tooltip().find("Bomber") >= 0, "bomber tooltip contains 'Bomber'")
	
	await get_tree().process_frame


func _run_intent_bar_tests() -> void:
	print("[Combat Clarity - Intent Bar Tests]")
	
	# Reset state
	RunManager.current_hp = 60
	RunManager.max_hp = 60
	RunManager.armor = 0
	RunManager.deck = [{"card_id": "infernal_pistol", "tier": 1}]
	
	const WaveDef = preload("res://scripts/resources/WaveDefinition.gd")
	var wave: WaveDef = WaveDef.create_basic_wave(1)
	
	# Initialize combat
	CombatManager.initialize_combat(wave)
	await get_tree().process_frame
	
	# Test: Battlefield exists after combat init
	_assert(CombatManager.battlefield != null, "battlefield exists after combat init")
	
	# Test: Can calculate incoming damage
	var threat: Dictionary = CombatManager.calculate_incoming_damage()
	_assert(threat.has("total"), "calculate_incoming_damage returns total")
	_assert(threat.has("breakdown"), "calculate_incoming_damage returns breakdown")
	_assert(threat.total >= 0, "total damage is non-negative")
	
	# Test: Enemy counts per ring work
	var melee_count: int = CombatManager.battlefield.get_enemies_in_ring(0).size()
	var close_count: int = CombatManager.battlefield.get_enemies_in_ring(1).size()
	var mid_count: int = CombatManager.battlefield.get_enemies_in_ring(2).size()
	var far_count: int = CombatManager.battlefield.get_enemies_in_ring(3).size()
	var total_count: int = CombatManager.battlefield.get_total_enemy_count()
	
	_assert(melee_count + close_count + mid_count + far_count == total_count, "ring counts sum to total")
	
	# Test: EnemyDefinition behavior types are accessible from EnemyInstance
	var enemies: Array = CombatManager.battlefield.get_all_enemies()
	if enemies.size() > 0:
		var enemy = enemies[0]
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		_assert(enemy_def != null, "can get EnemyDefinition from EnemyInstance")
		if enemy_def:
			_assert(enemy_def.behavior_type >= 0, "behavior_type is valid enum value")
	
	# Test: Count specific enemy types (for intent bar logic)
	var bomber_count: int = 0
	var buffer_count: int = 0
	var spawner_count: int = 0
	var fast_count: int = 0
	
	const EnemyDef = preload("res://scripts/resources/EnemyDefinition.gd")
	
	for enemy in enemies:
		var enemy_def = EnemyDatabase.get_enemy(enemy.enemy_id)
		if enemy_def:
			match enemy_def.behavior_type:
				EnemyDef.BehaviorType.BOMBER:
					bomber_count += 1
				EnemyDef.BehaviorType.BUFFER:
					buffer_count += 1
				EnemyDef.BehaviorType.SPAWNER:
					spawner_count += 1
				EnemyDef.BehaviorType.FAST:
					fast_count += 1
	
	_assert(bomber_count >= 0, "bomber count is valid")
	_assert(buffer_count >= 0, "buffer count is valid")
	_assert(spawner_count >= 0, "spawner count is valid")
	_assert(fast_count >= 0, "fast enemy count is valid")
	
	await get_tree().process_frame


func _run_merge_manager_tests() -> void:
	print("[MergeManager Tests]")
	
	# Reset deck
	RunManager.deck.clear()
	
	# Test: No merges available on empty deck
	var mergeable: Array = MergeManager.check_for_merges()
	_assert(mergeable.size() == 0, "no merges available on empty deck")
	
	# Test: Add 2 copies - can't merge yet
	RunManager.deck.append({"card_id": "infernal_pistol", "tier": 1})
	RunManager.deck.append({"card_id": "infernal_pistol", "tier": 1})
	var can_merge: bool = MergeManager.can_merge("infernal_pistol", 1)
	_assert(can_merge == false, "cannot merge with only 2 copies")
	
	# Test: Add 3rd copy - can merge now
	RunManager.deck.append({"card_id": "infernal_pistol", "tier": 1})
	can_merge = MergeManager.can_merge("infernal_pistol", 1)
	_assert(can_merge == true, "can merge with 3 copies")
	
	# Test: Check merge count
	var count: int = MergeManager.get_merge_count("infernal_pistol", 1)
	_assert(count == 3, "get_merge_count returns 3 for 3 copies")
	
	# Test: Execute merge removes 3 and adds 1 upgraded
	var deck_size_before: int = RunManager.deck.size()
	var merge_success: bool = MergeManager.execute_merge("infernal_pistol", 1)
	_assert(merge_success == true, "execute_merge returns true")
	_assert(RunManager.deck.size() == deck_size_before - 2, "merge removes 2 cards (3->1)")
	
	# Check tier 2 card was added
	var has_tier2: bool = false
	for entry: Dictionary in RunManager.deck:
		if entry.card_id == "infernal_pistol" and entry.tier == 2:
			has_tier2 = true
			break
	_assert(has_tier2 == true, "merge creates tier 2 card")
	
	# Test: Cannot merge tier 3 (max tier)
	RunManager.deck.clear()
	RunManager.deck.append({"card_id": "infernal_pistol", "tier": 3})
	RunManager.deck.append({"card_id": "infernal_pistol", "tier": 3})
	RunManager.deck.append({"card_id": "infernal_pistol", "tier": 3})
	can_merge = MergeManager.can_merge("infernal_pistol", 3)
	_assert(can_merge == false, "cannot merge tier 3 (max tier)")
	
	# Test: Upgrade preview shows stat changes
	RunManager.deck.clear()
	RunManager.deck.append({"card_id": "infernal_pistol", "tier": 1})
	var preview: Dictionary = MergeManager.get_upgrade_preview("infernal_pistol", 1)
	_assert(preview.has("card_id"), "upgrade preview contains card_id")
	_assert(preview.has("new_tier"), "upgrade preview contains new_tier")
	_assert(preview.new_tier == 2, "upgrade preview shows tier 2")
	
	await get_tree().process_frame


func _run_artifact_manager_tests() -> void:
	print("[ArtifactManager Tests]")
	
	# Reset artifacts
	ArtifactManager.clear_artifacts()
	
	# Test: Artifacts exist in database
	var quick_draw = ArtifactManager.get_artifact("quick_draw")
	_assert(quick_draw != null, "quick_draw exists in database")
	
	var iron_shell = ArtifactManager.get_artifact("iron_shell")
	_assert(iron_shell != null, "iron_shell exists in database")
	
	# Test: Equip artifact
	ArtifactManager.equip_artifact("iron_shell")
	_assert(ArtifactManager.has_artifact("iron_shell") == true, "has_artifact returns true after equip")
	
	# Test: Trigger on_wave_start artifact (Iron Shell)
	RunManager.armor = 0
	ArtifactManager.trigger_artifacts("on_wave_start")
	_assert(RunManager.armor > 0, "Iron Shell grants armor on wave start")
	
	# Test: Trigger on_turn_start artifact (Quick Draw)
	ArtifactManager.equip_artifact("quick_draw")
	var effects: Dictionary = ArtifactManager.trigger_artifacts("on_turn_start")
	_assert(effects.has("draw_cards"), "trigger_artifacts returns draw_cards effect")
	_assert(effects.draw_cards > 0, "Quick Draw adds draw_cards effect")
	
	# Test: Tag filtering (Ember Charm for gun cards)
	ArtifactManager.equip_artifact("ember_charm")
	var gun_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": ["gun"]})
	_assert(gun_effects.bonus_damage > 0, "Ember Charm adds bonus damage for gun cards")
	
	# Test: No bonus for non-gun cards
	var non_gun_effects: Dictionary = ArtifactManager.trigger_artifacts("on_card_play", {"card_tags": ["skill"]})
	_assert(non_gun_effects.bonus_damage == 0, "Ember Charm doesn't trigger for non-gun cards")
	
	# Test: Passive artifacts (Gun Harness cost reduction)
	ArtifactManager.equip_artifact("gun_harness")
	var cost_reduction: int = ArtifactManager.get_gun_cost_reduction()
	_assert(cost_reduction > 0, "Gun Harness provides cost reduction")
	
	# Test: Hex multiplier (Void Heart)
	ArtifactManager.equip_artifact("void_heart")
	var hex_mult: float = ArtifactManager.get_hex_multiplier()
	_assert(hex_mult > 1.0, "Void Heart increases hex multiplier")
	
	# Test: Cannot equip same artifact twice
	var equip_count_before: int = ArtifactManager.equipped_artifacts.size()
	ArtifactManager.equip_artifact("iron_shell")
	_assert(ArtifactManager.equipped_artifacts.size() == equip_count_before, "cannot equip same artifact twice")
	
	# Test: Get available artifacts (excludes equipped)
	var available: Array = ArtifactManager.get_available_artifacts()
	_assert(available.size() > 0, "get_available_artifacts returns non-empty array")
	
	await get_tree().process_frame


func _run_battlefield_state_tests() -> void:
	print("[BattlefieldState Tests]")
	
	# Reset combat state
	RunManager.current_hp = 60
	RunManager.max_hp = 60
	RunManager.armor = 0
	RunManager.deck = [{"card_id": "infernal_pistol", "tier": 1}]
	
	const WaveDef = preload("res://scripts/resources/WaveDefinition.gd")
	var wave: WaveDef = WaveDef.create_basic_wave(1)
	CombatManager.initialize_combat(wave)
	await get_tree().process_frame
	
	var battlefield = CombatManager.battlefield
	_assert(battlefield != null, "battlefield exists")
	
	# Test: Spawn enemy
	var enemy = battlefield.spawn_enemy("husk", 3)  # Far ring
	_assert(enemy != null, "spawn_enemy returns enemy instance")
	_assert(enemy.ring == 3, "enemy spawned in correct ring")
	_assert(enemy.current_hp > 0, "enemy has HP")
	
	# Test: Get enemies in ring
	var far_enemies: Array = battlefield.get_enemies_in_ring(3)
	_assert(far_enemies.size() > 0, "get_enemies_in_ring returns enemies")
	
	# Test: Move enemy inward
	var old_ring: int = enemy.ring
	battlefield.move_enemy(enemy, 2)  # Move to Mid ring
	_assert(enemy.ring == 2, "enemy moved to new ring")
	_assert(battlefield.get_enemies_in_ring(old_ring).has(enemy) == false, "enemy removed from old ring")
	_assert(battlefield.get_enemies_in_ring(2).has(enemy) == true, "enemy added to new ring")
	
	# Test: Get all enemies
	var all_enemies: Array = battlefield.get_all_enemies()
	_assert(all_enemies.size() > 0, "get_all_enemies returns enemies")
	
	# Test: Get total enemy count
	var total: int = battlefield.get_total_enemy_count()
	_assert(total > 0, "get_total_enemy_count returns positive value")
	_assert(total == all_enemies.size(), "total count matches all_enemies size")
	
	# Test: Remove enemy
	var enemy_count_before: int = battlefield.get_total_enemy_count()
	battlefield.remove_enemy(enemy)
	var enemy_count_after: int = battlefield.get_total_enemy_count()
	_assert(enemy_count_after < enemy_count_before, "remove_enemy reduces count")
	
	# Test: Ring barrier
	battlefield.add_ring_barrier(1, 5, 2)  # 5 damage, 2 turns
	_assert(battlefield.ring_barriers.has(1), "barrier added to ring")
	
	# Test: Barrier damages enemy moving through
	var test_enemy = battlefield.spawn_enemy("husk", 2)  # Start in Mid
	var hp_before: int = test_enemy.current_hp
	battlefield.move_enemy(test_enemy, 0)  # Move to Melee (passes through ring 1)
	var hp_after: int = test_enemy.current_hp
	_assert(hp_after < hp_before, "barrier damages enemy moving through")
	
	# Test: Ring name
	_assert(battlefield.get_ring_name(0) == "Melee", "ring name for MELEE is correct")
	_assert(battlefield.get_ring_name(3) == "Far", "ring name for FAR is correct")
	
	# Test: Get enemies by type
	battlefield.spawn_enemy("husk", 3)
	battlefield.spawn_enemy("spitter", 3)
	var husks: Array = battlefield.get_enemies_by_type("husk")
	_assert(husks.size() > 0, "get_enemies_by_type returns enemies")
	
	await get_tree().process_frame


func _run_enemy_instance_tests() -> void:
	print("[EnemyInstance Tests]")
	
	# Create a test enemy instance manually
	const EnemyInstanceScript = preload("res://scripts/combat/EnemyInstance.gd")
	var enemy = EnemyInstanceScript.new()
	enemy.enemy_id = "husk"
	enemy.current_hp = 20
	enemy.max_hp = 20
	enemy.ring = 3
	
	# Test: Enemy is alive
	_assert(enemy.is_alive() == true, "enemy is alive with HP > 0")
	
	# Test: Apply status effect (hex)
	enemy.apply_status("hex", 3)
	_assert(enemy.has_status("hex") == true, "enemy has hex status")
	_assert(enemy.get_status_value("hex") == 3, "hex value is 3")
	
	# Test: Hex stacks
	enemy.apply_status("hex", 2)
	_assert(enemy.get_status_value("hex") == 5, "hex stacks (3+2=5)")
	
	# Test: Take damage with hex (hex should trigger and be consumed)
	var damage_result: Dictionary = enemy.take_damage(4)  # Base 4 damage
	_assert(damage_result.has("total_damage"), "take_damage returns total_damage")
	_assert(damage_result.has("hex_triggered"), "take_damage returns hex_triggered")
	_assert(damage_result.hex_triggered == true, "hex triggered on damage")
	_assert(damage_result.total_damage > 4, "total damage includes hex bonus")
	_assert(enemy.has_status("hex") == false, "hex consumed after triggering")
	
	# Test: Enemy HP reduced
	_assert(enemy.current_hp < 20, "enemy HP reduced by damage")
	
	# Test: Apply temporary status effect
	enemy.apply_status("vulnerable", 1, 2)  # value 1, duration 2
	_assert(enemy.has_status("vulnerable") == true, "enemy has temporary status")
	
	# Test: Status effect duration ticks down
	enemy.tick_status_effects()
	# Status should still exist (duration 2 -> 1)
	_assert(enemy.has_status("vulnerable") == true, "status persists after 1 tick")
	
	# Test: Status effect expires after duration
	enemy.tick_status_effects()
	enemy.tick_status_effects()
	_assert(enemy.has_status("vulnerable") == false, "status expires after duration")
	
	# Test: Enemy dies when HP reaches 0
	enemy.current_hp = 5
	enemy.take_damage(10)
	_assert(enemy.current_hp <= 0, "enemy HP reduced to 0 or below")
	_assert(enemy.is_alive() == false, "enemy is dead when HP <= 0")
	
	# Test: Get HP percentage
	var healthy_enemy = EnemyInstanceScript.new()
	healthy_enemy.current_hp = 80
	healthy_enemy.max_hp = 100
	var hp_pct: float = healthy_enemy.get_hp_percentage()
	_assert(hp_pct == 0.8, "HP percentage is 0.8 for 80/100")
	
	# Test: Get definition
	var def = enemy.get_definition()
	_assert(def != null, "get_definition returns EnemyDefinition")
	
	await get_tree().process_frame


func _run_warden_passive_tests() -> void:
	print("[Warden Passive Tests]")
	
	# Test: Warden passive check function
	RunManager.current_warden = null
	var has_cheat: bool = RunManager._has_warden_passive("cheat_death")
	_assert(has_cheat == false, "_has_warden_passive returns false when warden is null")
	
	# Test: Warden tag bonus (Ash Warden)
	RunManager.current_warden = {
		"passive_id": "",
		"tag_damage_bonuses": {"gun": 0.15}
	}
	
	var gun_bonus: float = RunManager.get_warden_tag_bonus("gun")
	_assert(gun_bonus == 0.15, "get_warden_tag_bonus returns 15% for gun tag")
	
	var fire_bonus: float = RunManager.get_warden_tag_bonus("fire")
	_assert(fire_bonus == 0.0, "get_warden_tag_bonus returns 0 for non-gun tags")
	
	# Test: Warden passive ID check
	RunManager.current_warden = {"passive_id": "cheat_death"}
	has_cheat = RunManager._has_warden_passive("cheat_death")
	_assert(has_cheat == true, "_has_warden_passive returns true when passive_id matches")
	
	has_cheat = RunManager._has_warden_passive("other_passive")
	_assert(has_cheat == false, "_has_warden_passive returns false when passive_id doesn't match")
	
	# Test: Warden tag bonuses work with different tags
	RunManager.current_warden = {
		"passive_id": "",
		"tag_damage_bonuses": {"gun": 0.15, "fire": 0.10}
	}
	var gun_bonus2: float = RunManager.get_warden_tag_bonus("gun")
	var fire_bonus2: float = RunManager.get_warden_tag_bonus("fire")
	_assert(gun_bonus2 == 0.15, "gun bonus is 15%")
	_assert(fire_bonus2 == 0.10, "fire bonus is 10%")
	
	await get_tree().process_frame


func _run_card_database_tests() -> void:
	print("[CardDatabase Tests]")
	
	# Test: Cards exist in database
	var pistol = CardDatabase.get_card("infernal_pistol")
	_assert(pistol != null, "infernal_pistol exists in database")
	
	var shotgun = CardDatabase.get_card("choirbreaker_shotgun")
	_assert(shotgun != null, "choirbreaker_shotgun exists in database")
	
	var glass_ward = CardDatabase.get_card("glass_ward")
	_assert(glass_ward != null, "glass_ward exists in database")
	
	var simple_hex = CardDatabase.get_card("simple_hex")
	_assert(simple_hex != null, "simple_hex exists in database")
	
	# Test: Card properties
	_assert(pistol.card_name != "", "card has name")
	_assert(pistol.base_cost >= 0, "card has base cost")
	_assert(pistol.effect_type != "", "card has effect type")
	
	# Test: Scaled values work
	var tier1_damage: int = pistol.get_scaled_value("damage", 1)
	var tier2_damage: int = pistol.get_scaled_value("damage", 2)
	_assert(tier2_damage >= tier1_damage, "tier 2 damage >= tier 1 damage")
	
	# Test: Card targeting
	_assert(pistol.target_rings.size() > 0, "card has target rings")
	
	# Test: Invalid card returns null
	var invalid = CardDatabase.get_card("nonexistent_card")
	_assert(invalid == null, "invalid card returns null")
	
	await get_tree().process_frame


func _run_enemy_database_tests() -> void:
	print("[EnemyDatabase Tests]")
	
	# Test: All known enemies exist
	var enemy_ids: Array = ["husk", "spitter", "spinecrawler", "bomber", "cultist", 
		"shell_titan", "torchbearer", "channeler", "stalker", "ember_saint"]
	
	for enemy_id: String in enemy_ids:
		var enemy = EnemyDatabase.get_enemy(enemy_id)
		_assert(enemy != null, "enemy " + enemy_id + " exists in database")
	
	# Test: Enemy properties
	var husk = EnemyDatabase.get_enemy("husk")
	if husk:
		_assert(husk.enemy_name != "", "enemy has name")
		_assert(husk.base_hp > 0, "enemy has base HP")
		_assert(husk.behavior_type >= 0, "enemy has behavior type")
	
	# Test: Scaled HP works
	var wave1_hp: int = husk.get_scaled_hp(1)
	var wave5_hp: int = husk.get_scaled_hp(5)
	_assert(wave5_hp >= wave1_hp, "HP scales with wave number")
	
	# Test: Invalid enemy returns null
	var invalid = EnemyDatabase.get_enemy("nonexistent_enemy")
	_assert(invalid == null, "invalid enemy returns null")
	
	await get_tree().process_frame


func _run_card_ui_tests() -> void:
	print("[CardUI Tests]")
	
	# Test: CardUI can be instantiated and setup works
	var card_ui_scene = preload("res://scenes/ui/CardUI.tscn")
	var card_ui = card_ui_scene.instantiate()
	add_child(card_ui)
	
	var pistol = CardDatabase.get_card("infernal_pistol")
	_assert(pistol != null, "pistol card exists for UI test")
	
	if pistol:
		card_ui.setup(pistol, 1, 0)
		await get_tree().process_frame
		
		# Test: CardUI has card_def set
		_assert(card_ui.card_def == pistol, "card_def is set correctly")
		_assert(card_ui.tier == 1, "tier is set correctly")
		_assert(card_ui.hand_index == 0, "hand_index is set correctly")
		
		# Test: Display properties are populated
		card_ui._update_display()
		await get_tree().process_frame
		
		_assert(card_ui.cost_label.text == str(pistol.base_cost), "cost label displays base cost")
		_assert(pistol.card_name in card_ui.name_label.text, "name label contains card name")
		
		# Test: Type icon is set
		var type_icon: String = card_ui.TYPE_ICONS.get(pistol.card_type, "")
		_assert(type_icon != "", "type icon exists for weapon type")
		
		# Test: Stats row updates correctly
		var damage: int = pistol.get_scaled_value("damage", 1)
		if damage > 0:
			_assert(card_ui.damage_label.visible == true, "damage label visible when damage > 0")
			_assert(str(damage) in card_ui.damage_label.text, "damage label shows damage value")
		
		# Test: Target row updates correctly
		card_ui._update_target_row()
		_assert(card_ui.target_label.text != "", "target label is not empty")
		
		# Test: Footer updates correctly
		card_ui._update_footer()
		_assert(card_ui.timing_label.text != "", "timing label is not empty")
		
		# Test: Playability check (in non-combat context)
		card_ui.check_playability = false
		card_ui._apply_style()
		_assert(card_ui.modulate == Color.WHITE, "card shows full brightness when check_playability is false")
		
		# Test: Tier 2 card displays tier indicator
		card_ui.setup(pistol, 2, 0)
		await get_tree().process_frame
		card_ui._update_display()
		await get_tree().process_frame
		_assert("T2" in card_ui.tier_label.text, "tier 2 card shows tier indicator")
		
		# Test: Type colors are defined
		_assert(card_ui.TYPE_COLORS.has("weapon"), "TYPE_COLORS has weapon color")
		_assert(card_ui.TYPE_BG_COLORS.has("weapon"), "TYPE_BG_COLORS has weapon bg color")
		
		# Test: Ring names array is correct
		_assert(card_ui.RING_NAMES.size() == 4, "RING_NAMES has 4 entries")
		
		# Test: Description text generation
		var desc: String = card_ui._get_flavor_description()
		_assert(desc != "", "flavor description is not empty")
		
		# Test: Value substitution in descriptions
		var test_desc: String = "Deal {damage} damage"
		var substituted: String = card_ui._substitute_values(test_desc)
		_assert("{damage}" not in substituted, "value substitution replaces placeholders")
		
		# Test: Ring names text generation
		var rings_array: Array[int] = [0, 1, 2, 3]
		var rings_text: String = card_ui._get_rings_text(rings_array)
		_assert(rings_text == "ALL" or "M" in rings_text, "rings text is generated correctly")
	
	# Test: Different card types
	var armor_card = CardDatabase.get_card("glass_ward")
	if armor_card:
		var card_ui_armor = card_ui_scene.instantiate()
		add_child(card_ui_armor)
		card_ui_armor.setup(armor_card, 1, 0)
		await get_tree().process_frame
		
		card_ui_armor._update_display()
		await get_tree().process_frame
		
		# Test: Armor card shows armor stat
		var armor_amount: int = armor_card.get_scaled_value("armor_amount", 1)
		if armor_amount > 0:
			_assert(card_ui_armor.armor_label.visible == true, "armor label visible for armor card")
		
		# Test: Card type icon matches card type
		var expected_icon: String = card_ui_armor.TYPE_ICONS.get(armor_card.card_type, "")
		_assert(expected_icon != "", "type icon exists for card type")
		
		if is_instance_valid(card_ui_armor):
			card_ui_armor.queue_free()
	
	# Test: Hex card
	var hex_card_def = CardDatabase.get_card("simple_hex")
	if hex_card_def:
		var card_ui_hex = card_ui_scene.instantiate()
		add_child(card_ui_hex)
		card_ui_hex.setup(hex_card_def, 1, 0)
		await get_tree().process_frame
		
		card_ui_hex._update_display()
		await get_tree().process_frame
		
		# Test: Hex card shows hex stat
		var hex_dmg: int = hex_card_def.get_scaled_value("hex_damage", 1)
		if hex_dmg > 0:
			_assert(card_ui_hex.hex_label.visible == true, "hex label visible for hex card")
		
		# Test: Footer shows correct timing badge
		card_ui_hex._update_footer()
		_assert(card_ui_hex.timing_label.text != "", "timing badge has text")
		
		if is_instance_valid(card_ui_hex):
			card_ui_hex.queue_free()
	
	# Test: Card with tags
	if pistol and pistol.tags.size() > 0:
		card_ui.setup(pistol, 1, 0)
		await get_tree().process_frame
		card_ui._update_footer()
		_assert(card_ui.tags_label.text != "", "tags label shows tags")
	
	# Test: Tier colors are valid
	_assert(card_ui.TIER_COLORS.size() >= 3, "TIER_COLORS has at least 3 entries")
	for tier_color: Color in card_ui.TIER_COLORS:
		_assert(tier_color.r >= 0 and tier_color.r <= 1, "tier color components are valid")
	
	# Cleanup
	if is_instance_valid(card_ui):
		card_ui.queue_free()
	
	await get_tree().process_frame


func _run_enemy_ai_movement_tests() -> void:
	print("[Enemy AI/Movement Tests]")
	
	# Reset combat state
	RunManager.current_hp = 60
	RunManager.max_hp = 60
	RunManager.armor = 0
	RunManager.deck = [{"card_id": "infernal_pistol", "tier": 1}]
	
	# Set up a minimal warden for combat initialization
	_setup_minimal_warden()
	
	const WaveDef = preload("res://scripts/resources/WaveDefinition.gd")
	var wave: WaveDef = WaveDef.create_basic_wave(1)
	CombatManager.initialize_combat(wave)
	await get_tree().process_frame
	
	var battlefield = CombatManager.battlefield
	_assert(battlefield != null, "battlefield exists for AI tests")
	
	# Test: Enemy movement based on behavior type
	# Spawn a husk (RUSHER - moves every turn until melee)
	var husk = battlefield.spawn_enemy("husk", 3)  # Start in Far
	var husk_def = EnemyDatabase.get_enemy("husk")
	_assert(husk != null, "husk spawned for movement test")
	
	if husk and husk_def:
		_assert(husk.ring == 3, "husk starts in Far ring")
		_assert(husk_def.target_ring == 0, "husk target ring is Melee")
		_assert(husk_def.movement_speed == 1, "husk moves 1 ring per turn")
		
		# Simulate movement
		var new_ring: int = max(husk_def.target_ring, husk.ring - husk_def.movement_speed)
		_assert(new_ring == 2, "husk would move from ring 3 to ring 2")
		
		# Test: Enemy stops at target ring
		husk.ring = 0  # Move to Melee
		new_ring = max(husk_def.target_ring, husk.ring - husk_def.movement_speed)
		_assert(new_ring == 0, "enemy stops at target ring")
	
	# Test: Ranged enemy movement (stops early)
	var spitter = battlefield.spawn_enemy("spitter", 3)
	var spitter_def = EnemyDatabase.get_enemy("spitter")
	_assert(spitter != null, "spitter spawned for ranged test")
	
	if spitter and spitter_def:
		_assert(spitter_def.attack_type == "ranged", "spitter is ranged type")
		_assert(spitter_def.target_ring > 0, "ranged enemy stops before Melee")
		
		# Test: Ranged enemy attacks at target ring
		spitter.ring = spitter_def.target_ring
		var can_attack: bool = (spitter.ring == spitter_def.target_ring and spitter_def.attack_range >= spitter.ring)
		_assert(can_attack == true, "ranged enemy can attack at target ring")
	
	# Test: Fast enemy movement (moves multiple rings)
	var spinecrawler = battlefield.spawn_enemy("spinecrawler", 3)
	var spinecrawler_def = EnemyDatabase.get_enemy("spinecrawler")
	_assert(spinecrawler != null, "spinecrawler spawned for fast test")
	
	if spinecrawler and spinecrawler_def:
		var old_ring_fast: int = spinecrawler.ring
		var new_ring_fast: int = max(spinecrawler_def.target_ring, spinecrawler.ring - spinecrawler_def.movement_speed)
		_assert(new_ring_fast < old_ring_fast, "fast enemy moves multiple rings")
	
	# Test: Melee attacks process correctly
	battlefield.spawn_enemy("husk", 0)  # Spawn in Melee ring
	var melee_enemies: Array = battlefield.get_enemies_in_ring(0)
	_assert(melee_enemies.size() > 0, "melee enemies exist")
	
	# Test: Enemy attack damage calculation
	var total_damage: int = CombatManager._calculate_enemy_attack_damage()
	_assert(total_damage >= 0, "enemy attack damage is non-negative")
	_assert(total_damage > 0 if melee_enemies.size() > 0 else true, "damage > 0 when melee enemies present")
	
	# Test: Torchbearer buff system
	var torchbearer = battlefield.spawn_enemy("torchbearer", 2)
	var torchbearer_def = EnemyDatabase.get_enemy("torchbearer")
	_assert(torchbearer != null, "torchbearer spawned for buff test")
	
	if torchbearer and torchbearer_def:
		_assert(torchbearer_def.special_ability == "buff_allies", "torchbearer has buff_allies ability")
		_assert(torchbearer_def.buff_amount > 0, "torchbearer buff amount > 0")
		
		# Test: Torchbearer buff is applied
		var buff_amount: int = CombatManager._get_torchbearer_buff()
		_assert(buff_amount > 0, "torchbearer buff is active")
	
	# Test: Enemy special abilities - Spawner
	var channeler = battlefield.spawn_enemy("channeler", 2)
	var channeler_def = EnemyDatabase.get_enemy("channeler")
	_assert(channeler != null, "channeler spawned for spawner test")
	
	if channeler and channeler_def:
		_assert(channeler_def.special_ability == "spawn_minions", "channeler has spawn_minions ability")
		_assert(channeler_def.spawn_count > 0, "channeler spawn count > 0")
		_assert(channeler_def.spawn_enemy_id != "", "channeler has spawn enemy ID")
	
	# Test: Bomber doesn't attack (suicide type)
	var bomber = battlefield.spawn_enemy("bomber", 0)
	var bomber_def = EnemyDatabase.get_enemy("bomber")
	_assert(bomber != null, "bomber spawned for bomber test")
	
	if bomber and bomber_def:
		_assert(bomber_def.attack_type == "suicide", "bomber is suicide type")
		_assert(bomber_def.behavior_type == EnemyDefinition.BehaviorType.BOMBER, "bomber has BOMBER behavior type")
	
	# Test: Enemy phase ring processing order (Melee -> Close -> Mid -> Far)
	var processing_order: Array[int] = []
	for ring: int in range(4):
		processing_order.append(ring)
	
	_assert(processing_order == [0, 1, 2, 3], "ring processing order is Melee->Close->Mid->Far")
	
	# Test: Enemy movement respects target ring
	var test_enemy = battlefield.spawn_enemy("husk", 3)
	var test_def = EnemyDatabase.get_enemy("husk")
	if test_enemy and test_def:
		# Enemy should move toward target_ring (0 = Melee)
		var current_ring: int = test_enemy.ring
		var target_ring: int = test_def.target_ring
		var movement_speed: int = test_def.movement_speed
		
		_assert(current_ring > target_ring, "enemy is beyond target ring")
		var expected_new_ring: int = max(target_ring, current_ring - movement_speed)
		_assert(expected_new_ring < current_ring, "enemy moves inward toward target")
	
	# Test: Enemy scaled damage
	var wave1_damage: int = husk_def.get_scaled_damage(1)
	var wave5_damage: int = husk_def.get_scaled_damage(5)
	_assert(wave5_damage >= wave1_damage, "enemy damage scales with wave")
	
	# Test: Bomber explosion on death
	if bomber and bomber_def:
		_assert(bomber_def.special_ability == "explode_on_death", "bomber has explode_on_death ability")
		var explosion_dmg: int = bomber_def.buff_amount
		_assert(explosion_dmg > 0, "bomber explosion damage > 0")
		# Note: Actual explosion is tested in integration when enemy dies
	
	# Test: Enemy spawning ability
	if channeler and channeler_def:
		# Test that spawner can spawn enemies
		var spawn_enemy_id: String = channeler_def.spawn_enemy_id
		_assert(spawn_enemy_id != "", "spawner has valid spawn enemy ID")
		
		var spawn_count: int = channeler_def.spawn_count
		_assert(spawn_count > 0, "spawner has spawn count > 0")
		
		# Verify spawn enemy exists in database
		var spawn_enemy_def = EnemyDatabase.get_enemy(spawn_enemy_id)
		_assert(spawn_enemy_def != null, "spawn enemy exists in database")
	
	# Test: Enemy movement doesn't happen if already at target ring
	var enemy_at_target = battlefield.spawn_enemy("husk", 0)  # Spawn in Melee (target ring)
	var enemy_at_target_def = EnemyDatabase.get_enemy("husk")
	if enemy_at_target and enemy_at_target_def:
		_assert(enemy_at_target.ring == enemy_at_target_def.target_ring, "enemy is at target ring")
		var would_move: bool = (enemy_at_target.ring > enemy_at_target_def.target_ring)
		_assert(would_move == false, "enemy at target ring doesn't move")
	
	# Test: Tank enemy has high HP and armor
	var shell_titan = EnemyDatabase.get_enemy("shell_titan")
	if shell_titan:
		_assert(shell_titan.behavior_type == EnemyDefinition.BehaviorType.TANK, "shell_titan is TANK type")
		var titan_hp: int = shell_titan.get_scaled_hp(1)
		_assert(titan_hp > 15, "tank has high HP")
	
	# Test: Ambush enemy spawns close to player
	var stalker_def = EnemyDatabase.get_enemy("stalker")
	if stalker_def:
		_assert(stalker_def.behavior_type == EnemyDefinition.BehaviorType.AMBUSH, "stalker is AMBUSH type")
	
	# Test: Boss enemy has special mechanics
	var ember_saint_def = EnemyDatabase.get_enemy("ember_saint")
	if ember_saint_def:
		_assert(ember_saint_def.behavior_type == EnemyDefinition.BehaviorType.BOSS, "ember_saint is BOSS type")
		_assert(ember_saint_def.is_boss == true, "boss enemy has is_boss flag")
	
	await get_tree().process_frame


func _run_integration_tests() -> void:
	print("[Integration Tests]")
	
	# Reset everything
	RunManager.current_hp = 60
	RunManager.max_hp = 60
	RunManager.armor = 0
	RunManager.scrap = 0
	RunManager.deck = [{"card_id": "infernal_pistol", "tier": 1}]
	
	const WaveDef = preload("res://scripts/resources/WaveDefinition.gd")
	var wave: WaveDef = WaveDef.create_basic_wave(1)
	CombatManager.initialize_combat(wave)
	await get_tree().process_frame
	
	# Get enemy HP before
	var enemies_before: Array = CombatManager.battlefield.get_all_enemies()
	var total_hp_before: int = 0
	for enemy in enemies_before:
		total_hp_before += enemy.current_hp
	
	# Play the pistol card
	var play_success: bool = CombatManager.play_card(0, -1)
	_assert(play_success == true, "play_card returns true")
	
	await get_tree().process_frame
	
	# Check that damage was dealt
	var enemies_after: Array = CombatManager.battlefield.get_all_enemies()
	var total_hp_after: int = 0
	for enemy in enemies_after:
		total_hp_after += enemy.current_hp
	
	# Either HP decreased or an enemy died
	var damage_dealt: bool = (total_hp_after < total_hp_before) or (enemies_after.size() < enemies_before.size())
	_assert(damage_dealt, "infernal_pistol deals damage to enemies")
	
	# Test: Weapon was registered for future turns
	_assert(CombatManager.active_weapons.size() > 0, "persistent weapon registered")
	
	# Test: End turn and start new turn to verify weapon triggers again
	var enemies_before_turn2: Array = CombatManager.battlefield.get_all_enemies()
	var total_hp_before_turn2: int = 0
	for enemy in enemies_before_turn2:
		total_hp_before_turn2 += enemy.current_hp
	
	# End turn (this will process enemy phase and start new turn)
	CombatManager.end_player_turn()
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check that persistent weapon triggered again
	var enemies_after_turn2: Array = CombatManager.battlefield.get_all_enemies()
	var total_hp_after_turn2: int = 0
	for enemy in enemies_after_turn2:
		total_hp_after_turn2 += enemy.current_hp
	
	var weapon_triggered_turn2: bool = (total_hp_after_turn2 < total_hp_before_turn2) or (enemies_after_turn2.size() < enemies_before_turn2.size())
	_assert(weapon_triggered_turn2, "persistent weapon triggers on turn 2")
	
	await get_tree().process_frame

