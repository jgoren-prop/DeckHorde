extends Node
## Unit tests for V5 Artifact System
## Tests 50 artifacts: 16 Common, 16 Uncommon, 12 Rare, 6 Legendary

var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("[TestV5Artifacts] Starting V5 artifact tests...")
	await get_tree().process_frame
	
	# Run all tests
	test_artifact_counts()
	test_common_artifacts()
	test_uncommon_artifacts()
	test_rare_artifacts()
	test_legendary_artifacts()
	test_artifact_equip_unequip()
	test_stackable_artifacts()
	test_stat_modifier_artifacts()
	test_artifact_triggers()
	
	# Summary
	print("\n[TestV5Artifacts] ========================================")
	print("[TestV5Artifacts] Tests passed: ", tests_passed)
	print("[TestV5Artifacts] Tests failed: ", tests_failed)
	print("[TestV5Artifacts] ========================================")
	
	if tests_failed == 0:
		print("[TestV5Artifacts] ✅ ALL TESTS PASSED!")
		get_tree().quit(0)
	else:
		print("[TestV5Artifacts] ❌ SOME TESTS FAILED")
		get_tree().quit(1)


func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("[PASS] ", test_name)
	else:
		tests_failed += 1
		print("[FAIL] ", test_name, " - Expected: ", expected, ", Got: ", actual)


func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		tests_passed += 1
		print("[PASS] ", test_name)
	else:
		tests_failed += 1
		print("[FAIL] ", test_name)


func assert_not_null(value, test_name: String) -> void:
	if value != null:
		tests_passed += 1
		print("[PASS] ", test_name)
	else:
		tests_failed += 1
		print("[FAIL] ", test_name, " - Value was null")


# =============================================================================
# ARTIFACT COUNT TESTS
# =============================================================================

func test_artifact_counts() -> void:
	print("\n[TestV5Artifacts] --- Testing Artifact Counts ---")
	
	var all: Array = ArtifactManager.get_all_artifacts()
	assert_eq(all.size(), 50, "Total artifact count is 50")
	
	var common: Array = ArtifactManager.get_artifacts_by_rarity(0)
	assert_eq(common.size(), 16, "Common artifacts count is 16")
	
	var uncommon: Array = ArtifactManager.get_artifacts_by_rarity(1)
	assert_eq(uncommon.size(), 16, "Uncommon artifacts count is 16")
	
	var rare: Array = ArtifactManager.get_artifacts_by_rarity(2)
	assert_eq(rare.size(), 12, "Rare artifacts count is 12")
	
	var legendary: Array = ArtifactManager.get_artifacts_by_rarity(3)
	assert_eq(legendary.size(), 6, "Legendary artifacts count is 6")


# =============================================================================
# COMMON ARTIFACT TESTS
# =============================================================================

func test_common_artifacts() -> void:
	print("\n[TestV5Artifacts] --- Testing Common Artifacts ---")
	
	# Flat damage boosters
	var kinetic_rounds = ArtifactManager.get_artifact("kinetic_rounds")
	assert_not_null(kinetic_rounds, "Kinetic Rounds exists")
	assert_eq(kinetic_rounds.stat_modifiers.get("kinetic", 0), 3, "Kinetic Rounds gives +3 Kinetic")
	assert_true(kinetic_rounds.stackable, "Kinetic Rounds is stackable")
	
	var thermal_core = ArtifactManager.get_artifact("thermal_core")
	assert_not_null(thermal_core, "Thermal Core exists")
	assert_eq(thermal_core.stat_modifiers.get("thermal", 0), 3, "Thermal Core gives +3 Thermal")
	
	var arcane_focus = ArtifactManager.get_artifact("arcane_focus")
	assert_not_null(arcane_focus, "Arcane Focus exists")
	assert_eq(arcane_focus.stat_modifiers.get("arcane", 0), 3, "Arcane Focus gives +3 Arcane")
	
	# Percentage boosters
	var sharp_edge = ArtifactManager.get_artifact("sharp_edge")
	assert_not_null(sharp_edge, "Sharp Edge exists")
	assert_eq(sharp_edge.stat_modifiers.get("damage_percent", 0.0), 5.0, "Sharp Edge gives +5% damage")
	
	# Other stats
	var lucky_coin = ArtifactManager.get_artifact("lucky_coin")
	assert_not_null(lucky_coin, "Lucky Coin exists")
	assert_eq(lucky_coin.stat_modifiers.get("crit_chance", 0.0), 3.0, "Lucky Coin gives +3% crit")
	
	var iron_skin = ArtifactManager.get_artifact("iron_skin")
	assert_not_null(iron_skin, "Iron Skin exists")
	assert_eq(iron_skin.stat_modifiers.get("max_hp", 0), 5, "Iron Skin gives +5 Max HP")
	
	var steel_plate = ArtifactManager.get_artifact("steel_plate")
	assert_not_null(steel_plate, "Steel Plate exists")
	assert_eq(steel_plate.stat_modifiers.get("armor_start", 0), 2, "Steel Plate gives +2 Armor/wave")


# =============================================================================
# UNCOMMON ARTIFACT TESTS
# =============================================================================

func test_uncommon_artifacts() -> void:
	print("\n[TestV5Artifacts] --- Testing Uncommon Artifacts ---")
	
	var precision_scope = ArtifactManager.get_artifact("precision_scope")
	assert_not_null(precision_scope, "Precision Scope exists")
	assert_eq(precision_scope.trigger_type, "on_kinetic_attack", "Precision Scope triggers on kinetic attack")
	assert_eq(precision_scope.effect_value, 5.0, "Precision Scope gives +5% crit")
	
	var pyromaniac = ArtifactManager.get_artifact("pyromaniac")
	assert_not_null(pyromaniac, "Pyromaniac exists")
	assert_eq(pyromaniac.trigger_type, "on_thermal_kill", "Pyromaniac triggers on thermal kill")
	assert_true(!pyromaniac.stackable, "Pyromaniac is NOT stackable")
	
	var soul_leech = ArtifactManager.get_artifact("soul_leech")
	assert_not_null(soul_leech, "Soul Leech exists")
	assert_eq(soul_leech.effect_type, "heal_percent_damage", "Soul Leech heals percent of damage")
	
	var hunters_instinct = ArtifactManager.get_artifact("hunters_instinct")
	assert_not_null(hunters_instinct, "Hunter's Instinct exists")
	assert_eq(hunters_instinct.trigger_type, "on_kill", "Hunter's Instinct triggers on kill")
	assert_eq(hunters_instinct.effect_type, "heal", "Hunter's Instinct heals")
	assert_eq(hunters_instinct.effect_value, 1.0, "Hunter's Instinct heals 1 HP")
	
	var rapid_loader = ArtifactManager.get_artifact("rapid_loader")
	assert_not_null(rapid_loader, "Rapid Loader exists")
	assert_eq(rapid_loader.stat_modifiers.get("draw_per_turn", 0), 1, "Rapid Loader gives +1 draw/turn")
	
	var power_cell = ArtifactManager.get_artifact("power_cell")
	assert_not_null(power_cell, "Power Cell exists")
	assert_eq(power_cell.stat_modifiers.get("energy_per_turn", 0), 1, "Power Cell gives +1 energy/turn")


# =============================================================================
# RARE ARTIFACT TESTS
# =============================================================================

func test_rare_artifacts() -> void:
	print("\n[TestV5Artifacts] --- Testing Rare Artifacts ---")
	
	var burning_hex = ArtifactManager.get_artifact("burning_hex")
	assert_not_null(burning_hex, "Burning Hex exists")
	assert_eq(burning_hex.trigger_type, "on_hex_consume", "Burning Hex triggers on hex consume")
	assert_eq(burning_hex.effect_type, "apply_burn", "Burning Hex applies burn")
	assert_eq(burning_hex.effect_value, 2.0, "Burning Hex applies 2 burn")
	
	var crit_shockwave = ArtifactManager.get_artifact("crit_shockwave")
	assert_not_null(crit_shockwave, "Crit Shockwave exists")
	assert_eq(crit_shockwave.trigger_type, "on_crit", "Crit Shockwave triggers on crit")
	assert_eq(crit_shockwave.effect_type, "push_enemy", "Crit Shockwave pushes enemy")
	
	var executioner = ArtifactManager.get_artifact("executioner")
	assert_not_null(executioner, "Executioner exists")
	assert_eq(executioner.trigger_type, "on_attack_low_hp", "Executioner triggers on low HP attack")
	assert_eq(executioner.effect_value, 50.0, "Executioner gives +50% damage")
	
	var barrier_master = ArtifactManager.get_artifact("barrier_master")
	assert_not_null(barrier_master, "Barrier Master exists")
	assert_eq(barrier_master.stat_modifiers.get("barrier_damage_bonus", 0), 100, "Barrier Master doubles barrier damage")


# =============================================================================
# LEGENDARY ARTIFACT TESTS
# =============================================================================

func test_legendary_artifacts() -> void:
	print("\n[TestV5Artifacts] --- Testing Legendary Artifacts ---")
	
	var infinity_engine = ArtifactManager.get_artifact("infinity_engine")
	assert_not_null(infinity_engine, "Infinity Engine exists")
	assert_eq(infinity_engine.trigger_type, "on_kill", "Infinity Engine triggers on kill")
	assert_eq(infinity_engine.effect_type, "refund_energy", "Infinity Engine refunds energy")
	
	var blood_pact = ArtifactManager.get_artifact("blood_pact")
	assert_not_null(blood_pact, "Blood Pact exists")
	assert_eq(blood_pact.stat_modifiers.get("lifesteal_percent", 0.0), 15.0, "Blood Pact gives +15% lifesteal")
	assert_eq(blood_pact.stat_modifiers.get("max_hp", 0), -20, "Blood Pact reduces max HP by 20")
	
	var glass_cannon = ArtifactManager.get_artifact("glass_cannon")
	assert_not_null(glass_cannon, "Glass Cannon exists")
	assert_eq(glass_cannon.stat_modifiers.get("damage_percent", 0.0), 50.0, "Glass Cannon gives +50% damage")
	assert_eq(glass_cannon.on_acquire, "set_max_hp_25", "Glass Cannon sets max HP to 25")
	
	var bullet_time = ArtifactManager.get_artifact("bullet_time")
	assert_not_null(bullet_time, "Bullet Time exists")
	assert_eq(bullet_time.trigger_type, "on_first_card", "Bullet Time triggers on first card")
	assert_eq(bullet_time.effect_type, "double_hit", "Bullet Time causes double hit")
	
	var chaos_core = ArtifactManager.get_artifact("chaos_core")
	assert_not_null(chaos_core, "Chaos Core exists")
	assert_eq(chaos_core.stat_modifiers.get("crit_chance", 0.0), 10.0, "Chaos Core gives +10% crit")
	assert_eq(chaos_core.trigger_type, "on_crit", "Chaos Core triggers on crit")
	
	var immortal_shell = ArtifactManager.get_artifact("immortal_shell")
	assert_not_null(immortal_shell, "Immortal Shell exists")
	assert_eq(immortal_shell.trigger_type, "on_lethal", "Immortal Shell triggers on lethal")
	assert_eq(immortal_shell.effect_type, "cheat_death", "Immortal Shell cheats death")


# =============================================================================
# EQUIP/UNEQUIP TESTS
# =============================================================================

func test_artifact_equip_unequip() -> void:
	print("\n[TestV5Artifacts] --- Testing Equip/Unequip ---")
	
	# Reset equipped artifacts
	ArtifactManager.reset_artifacts()
	assert_eq(ArtifactManager.get_equipped_artifacts().size(), 0, "No artifacts equipped after reset")
	
	# Equip an artifact
	var success: bool = ArtifactManager.equip_artifact("kinetic_rounds")
	assert_true(success, "Can equip Kinetic Rounds")
	assert_true(ArtifactManager.has_artifact("kinetic_rounds"), "Kinetic Rounds is equipped")
	
	# Unequip the artifact
	success = ArtifactManager.unequip_artifact("kinetic_rounds")
	assert_true(success, "Can unequip Kinetic Rounds")
	assert_true(!ArtifactManager.has_artifact("kinetic_rounds"), "Kinetic Rounds is no longer equipped")
	
	# Reset for other tests
	ArtifactManager.reset_artifacts()


# =============================================================================
# STACKABLE ARTIFACT TESTS
# =============================================================================

func test_stackable_artifacts() -> void:
	print("\n[TestV5Artifacts] --- Testing Stackable Artifacts ---")
	
	ArtifactManager.reset_artifacts()
	
	# Stackable artifact can be equipped multiple times
	ArtifactManager.equip_artifact("kinetic_rounds")
	ArtifactManager.equip_artifact("kinetic_rounds")
	assert_eq(ArtifactManager.get_artifact_count("kinetic_rounds"), 2, "Can stack Kinetic Rounds")
	
	# Non-stackable artifact cannot be equipped multiple times
	ArtifactManager.equip_artifact("pyromaniac")
	var second_equip: bool = ArtifactManager.equip_artifact("pyromaniac")
	assert_true(!second_equip, "Cannot equip second Pyromaniac")
	assert_eq(ArtifactManager.get_artifact_count("pyromaniac"), 1, "Only one Pyromaniac equipped")
	
	ArtifactManager.reset_artifacts()


# =============================================================================
# STAT MODIFIER TESTS
# =============================================================================

func test_stat_modifier_artifacts() -> void:
	print("\n[TestV5Artifacts] --- Testing Stat Modifier Artifacts ---")
	
	ArtifactManager.reset_artifacts()
	RunManager.player_stats.reset_to_defaults()
	
	# Get initial values
	var initial_kinetic: int = RunManager.player_stats.kinetic
	var initial_damage_percent: float = RunManager.player_stats.damage_percent
	
	# Equip artifacts with stat modifiers
	ArtifactManager.equip_artifact("kinetic_rounds")
	assert_eq(RunManager.player_stats.kinetic, initial_kinetic + 3, "Kinetic increased by 3 after equip")
	
	ArtifactManager.equip_artifact("sharp_edge")
	assert_eq(RunManager.player_stats.damage_percent, initial_damage_percent + 5.0, "Damage percent increased after equip")
	
	# Stack kinetic rounds
	ArtifactManager.equip_artifact("kinetic_rounds")
	assert_eq(RunManager.player_stats.kinetic, initial_kinetic + 6, "Kinetic increased by 6 total with 2 stacks")
	
	# Unequip and verify stats decrease
	ArtifactManager.unequip_artifact("kinetic_rounds")
	assert_eq(RunManager.player_stats.kinetic, initial_kinetic + 3, "Kinetic decreased after unequip one stack")
	
	ArtifactManager.reset_artifacts()
	RunManager.player_stats.reset_to_defaults()


# =============================================================================
# ARTIFACT TRIGGER TESTS
# =============================================================================

func test_artifact_triggers() -> void:
	print("\n[TestV5Artifacts] --- Testing Artifact Triggers ---")
	
	ArtifactManager.reset_artifacts()
	
	# Equip on_kill artifacts
	ArtifactManager.equip_artifact("hunters_instinct")
	ArtifactManager.equip_artifact("bounty_hunter")
	
	# Trigger on_kill
	var effects: Dictionary = ArtifactManager.trigger_artifacts("on_kill", {})
	assert_eq(effects.get("heal", 0), 1, "Hunter's Instinct heal triggered")
	assert_eq(effects.get("bonus_scrap", 0), 1, "Bounty Hunter scrap triggered")
	
	ArtifactManager.reset_artifacts()



