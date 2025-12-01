extends Node
## ArtifactManager - V2 Brotato-style Artifact System
## Artifacts use stat_modifiers for PlayerStats integration
## Supports stackable artifacts for build diversity

signal artifact_triggered(artifact, context: Dictionary)
signal artifact_acquired(artifact)
signal stats_changed()  # V2: Emitted when artifact modifiers change

var artifacts: Dictionary = {}  # artifact_id -> ArtifactDefinition
var equipped_artifacts: Array = []  # Array of artifact_ids (can have duplicates for stackable)

const ArtifactDef = preload("res://scripts/resources/ArtifactDefinition.gd")


func _ready() -> void:
	_create_v2_artifacts()
	print("[ArtifactManager] Initialized with ", artifacts.size(), " V2 artifacts")


func _create_v2_artifacts() -> void:
	"""Create the V2 artifact pool - Brotato-style stackable stat items."""
	_create_core_stat_artifacts()
	_create_lifedrain_artifacts()
	_create_hex_ritual_artifacts()
	_create_barrier_fortress_artifacts()
	_create_volatile_artifacts()


# =============================================================================
# CORE STAT ARTIFACTS (Tag-Agnostic)
# =============================================================================

func _create_core_stat_artifacts() -> void:
	"""Pure stat boosts with mild or no downsides."""
	
	# Sharpened Rounds - gun damage boost
	var sharpened := ArtifactDef.new()
	sharpened.artifact_id = "sharpened_rounds"
	sharpened.artifact_name = "Sharpened Rounds"
	sharpened.description = "Gun damage +10%."
	sharpened.rarity = 1
	sharpened.base_cost = 40
	sharpened.stackable = true
	sharpened.stat_modifiers = {"gun_damage_percent": 10.0}
	sharpened.trigger_type = "passive"
	sharpened.icon = "🔫"
	sharpened.icon_color = Color(0.9, 0.5, 0.2)
	_register_artifact(sharpened)
	
	# Hex Lens - hex damage boost
	var hex_lens := ArtifactDef.new()
	hex_lens.artifact_id = "hex_lens"
	hex_lens.artifact_name = "Hex Lens"
	hex_lens.description = "Hex damage +10%."
	hex_lens.rarity = 1
	hex_lens.base_cost = 40
	hex_lens.stackable = true
	hex_lens.stat_modifiers = {"hex_damage_percent": 10.0}
	hex_lens.trigger_type = "passive"
	hex_lens.icon = "🔮"
	hex_lens.icon_color = Color(0.6, 0.2, 0.8)
	_register_artifact(hex_lens)
	
	# Reinforced Plating - armor gain boost
	var reinforced := ArtifactDef.new()
	reinforced.artifact_id = "reinforced_plating"
	reinforced.artifact_name = "Reinforced Plating"
	reinforced.description = "Armor gained +15%."
	reinforced.rarity = 1
	reinforced.base_cost = 45
	reinforced.stackable = true
	reinforced.stat_modifiers = {"armor_gain_percent": 15.0}
	reinforced.trigger_type = "passive"
	reinforced.icon = "🛡️"
	reinforced.icon_color = Color(0.5, 0.5, 0.6)
	_register_artifact(reinforced)
	
	# Barrier Alloy - barrier strength boost
	var barrier_alloy := ArtifactDef.new()
	barrier_alloy.artifact_id = "barrier_alloy"
	barrier_alloy.artifact_name = "Barrier Alloy"
	barrier_alloy.description = "Barriers have +20% HP/duration."
	barrier_alloy.rarity = 1
	barrier_alloy.base_cost = 45
	barrier_alloy.stackable = true
	barrier_alloy.stat_modifiers = {"barrier_strength_percent": 20.0}
	barrier_alloy.trigger_type = "passive"
	barrier_alloy.icon = "🧱"
	barrier_alloy.icon_color = Color(0.4, 0.6, 0.8)
	_register_artifact(barrier_alloy)
	
	# Tactical Pack - draw boost (non-stackable)
	var tactical := ArtifactDef.new()
	tactical.artifact_id = "tactical_pack"
	tactical.artifact_name = "Tactical Pack"
	tactical.description = "Draw +1 card per turn."
	tactical.rarity = 2
	tactical.base_cost = 75
	tactical.stackable = false
	tactical.stat_modifiers = {"draw_per_turn": 1}
	tactical.trigger_type = "passive"
	tactical.icon = "🎒"
	tactical.icon_color = Color(0.3, 0.5, 0.2)
	_register_artifact(tactical)
	
	# Surge Capacitor - energy boost (non-stackable)
	var surge := ArtifactDef.new()
	surge.artifact_id = "surge_capacitor"
	surge.artifact_name = "Surge Capacitor"
	surge.description = "Energy per turn +1."
	surge.rarity = 2
	surge.base_cost = 80
	surge.stackable = false
	surge.stat_modifiers = {"energy_per_turn": 1}
	surge.trigger_type = "passive"
	surge.icon = "⚡"
	surge.icon_color = Color(1.0, 0.9, 0.2)
	_register_artifact(surge)
	
	# Glass Core - gun boost with HP penalty
	var glass_core := ArtifactDef.new()
	glass_core.artifact_id = "glass_core"
	glass_core.artifact_name = "Glass Core"
	glass_core.description = "Gun damage +20%. Max HP -5."
	glass_core.rarity = 2
	glass_core.base_cost = 60
	glass_core.stackable = true
	glass_core.stat_modifiers = {"gun_damage_percent": 20.0, "max_hp": -5}
	glass_core.trigger_type = "passive"
	glass_core.icon = "💠"
	glass_core.icon_color = Color(0.7, 0.9, 1.0)
	_register_artifact(glass_core)
	
	# Runic Plating - armor boost with heal penalty
	var runic := ArtifactDef.new()
	runic.artifact_id = "runic_plating"
	runic.artifact_name = "Runic Plating"
	runic.description = "Armor gained +25%. Heal power -10%."
	runic.rarity = 2
	runic.base_cost = 55
	runic.stackable = true
	runic.stat_modifiers = {"armor_gain_percent": 25.0, "heal_power_percent": -10.0}
	runic.trigger_type = "passive"
	runic.icon = "🔷"
	runic.icon_color = Color(0.3, 0.4, 0.9)
	_register_artifact(runic)
	
	# Forward Bastion - close range focus
	var forward := ArtifactDef.new()
	forward.artifact_id = "forward_bastion"
	forward.artifact_name = "Forward Bastion"
	forward.description = "Damage vs Melee/Close +15%. Damage vs Mid/Far -10%."
	forward.rarity = 2
	forward.base_cost = 50
	forward.stackable = true
	forward.stat_modifiers = {
		"damage_vs_melee_percent": 15.0,
		"damage_vs_close_percent": 15.0,
		"damage_vs_mid_percent": -10.0,
		"damage_vs_far_percent": -10.0
	}
	forward.trigger_type = "passive"
	forward.icon = "🏰"
	forward.icon_color = Color(0.6, 0.4, 0.2)
	_register_artifact(forward)
	
	# Scrap Magnet - economy boost
	var scrap_magnet := ArtifactDef.new()
	scrap_magnet.artifact_id = "scrap_magnet"
	scrap_magnet.artifact_name = "Scrap Magnet"
	scrap_magnet.description = "Scrap gained +15%."
	scrap_magnet.rarity = 1
	scrap_magnet.base_cost = 50
	scrap_magnet.stackable = true
	scrap_magnet.stat_modifiers = {"scrap_gain_percent": 15.0}
	scrap_magnet.trigger_type = "passive"
	scrap_magnet.icon = "🧲"
	scrap_magnet.icon_color = Color(0.8, 0.6, 0.3)
	_register_artifact(scrap_magnet)


# =============================================================================
# LIFEDRAIN FAMILY ARTIFACTS
# =============================================================================

func _create_lifedrain_artifacts() -> void:
	"""Artifacts for lifedrain/sustain builds."""
	
	# Leech Core - lifedrain heals more
	var leech := ArtifactDef.new()
	leech.artifact_id = "leech_core"
	leech.artifact_name = "Leech Core"
	leech.description = "Lifedrain cards heal +1 HP."
	leech.rarity = 1
	leech.base_cost = 45
	leech.stackable = true
	leech.required_tags = ["lifedrain"]
	leech.trigger_type = "on_card_play"
	leech.trigger_tag = "lifedrain"
	leech.effect_type = "bonus_heal"
	leech.effect_value = 1
	leech.icon = "🩸"
	leech.icon_color = Color(0.8, 0.1, 0.2)
	_register_artifact(leech)
	
	# Sanguine Reservoir - HP boost with heal penalty
	var sanguine := ArtifactDef.new()
	sanguine.artifact_id = "sanguine_reservoir"
	sanguine.artifact_name = "Sanguine Reservoir"
	sanguine.description = "Max HP +10. Heal power -10%."
	sanguine.rarity = 2
	sanguine.base_cost = 55
	sanguine.stackable = false
	sanguine.stat_modifiers = {"max_hp": 10, "heal_power_percent": -10.0}
	sanguine.trigger_type = "passive"
	sanguine.icon = "🫀"
	sanguine.icon_color = Color(0.7, 0.2, 0.3)
	_register_artifact(sanguine)
	
	# Hemorrhage Engine - heal converts to damage (rare)
	var hemorrhage := ArtifactDef.new()
	hemorrhage.artifact_id = "hemorrhage_engine"
	hemorrhage.artifact_name = "Hemorrhage Engine"
	hemorrhage.description = "Whenever you heal, deal that much damage split among enemies in Melee/Close."
	hemorrhage.rarity = 3
	hemorrhage.base_cost = 100
	hemorrhage.stackable = false
	hemorrhage.trigger_type = "on_heal"
	hemorrhage.effect_type = "heal_to_damage"
	hemorrhage.icon = "💉"
	hemorrhage.icon_color = Color(0.9, 0.2, 0.3)
	_register_artifact(hemorrhage)
	
	# Red Aegis - overheal to armor
	var red_aegis := ArtifactDef.new()
	red_aegis.artifact_id = "red_aegis"
	red_aegis.artifact_name = "Red Aegis"
	red_aegis.description = "When you heal at full HP, gain 2 armor instead."
	red_aegis.rarity = 2
	red_aegis.base_cost = 60
	red_aegis.stackable = false
	red_aegis.trigger_type = "on_heal"
	red_aegis.effect_type = "overheal_to_armor"
	red_aegis.effect_value = 2
	red_aegis.icon = "❤️‍🔥"
	red_aegis.icon_color = Color(0.9, 0.3, 0.4)
	_register_artifact(red_aegis)


# =============================================================================
# HEX RITUAL FAMILY ARTIFACTS
# =============================================================================

func _create_hex_ritual_artifacts() -> void:
	"""Artifacts for hex/ritual builds."""
	
	# Occult Focus - hex_ritual applies more hex
	var occult := ArtifactDef.new()
	occult.artifact_id = "occult_focus"
	occult.artifact_name = "Occult Focus"
	occult.description = "Hex_ritual cards apply +1 additional hex."
	occult.rarity = 1
	occult.base_cost = 45
	occult.stackable = true
	occult.required_tags = ["hex_ritual"]
	occult.trigger_type = "on_card_play"
	occult.trigger_tag = "hex_ritual"
	occult.effect_type = "bonus_hex"
	occult.effect_value = 1
	occult.icon = "🌀"
	occult.icon_color = Color(0.5, 0.2, 0.7)
	_register_artifact(occult)
	
	# Blood Pact - scaling hex damage
	var blood_pact := ArtifactDef.new()
	blood_pact.artifact_id = "blood_pact"
	blood_pact.artifact_name = "Blood Pact"
	blood_pact.description = "Start each wave: lose 3 HP, gain +2% hex damage permanently."
	blood_pact.rarity = 2
	blood_pact.base_cost = 65
	blood_pact.stackable = false
	blood_pact.trigger_type = "on_wave_start"
	blood_pact.effect_type = "blood_pact"
	blood_pact.effect_value = 3  # HP lost
	blood_pact.icon = "📜"
	blood_pact.icon_color = Color(0.6, 0.1, 0.3)
	_register_artifact(blood_pact)
	
	# Creeping Doom - hex spreads on consume (rare)
	var creeping := ArtifactDef.new()
	creeping.artifact_id = "creeping_doom"
	creeping.artifact_name = "Creeping Doom"
	creeping.description = "When hex is consumed, apply 1 hex to all other enemies in that ring."
	creeping.rarity = 3
	creeping.base_cost = 95
	creeping.stackable = false
	creeping.trigger_type = "on_hex_consumed"
	creeping.effect_type = "hex_spread"
	creeping.effect_value = 1
	creeping.icon = "☠️"
	creeping.icon_color = Color(0.3, 0.5, 0.2)
	_register_artifact(creeping)
	
	# Ritual Anchor - armor on hex_ritual play
	var anchor := ArtifactDef.new()
	anchor.artifact_id = "ritual_anchor"
	anchor.artifact_name = "Ritual Anchor"
	anchor.description = "When you play a hex_ritual card, gain 1 armor."
	anchor.rarity = 2
	anchor.base_cost = 50
	anchor.stackable = true
	anchor.required_tags = ["hex_ritual"]
	anchor.trigger_type = "on_card_play"
	anchor.trigger_tag = "hex_ritual"
	anchor.effect_type = "gain_armor"
	anchor.effect_value = 1
	anchor.icon = "⚓"
	anchor.icon_color = Color(0.4, 0.3, 0.6)
	_register_artifact(anchor)


# =============================================================================
# BARRIER/FORTRESS FAMILY ARTIFACTS
# =============================================================================

func _create_barrier_fortress_artifacts() -> void:
	"""Artifacts for barrier/fortress builds."""
	
	# Trap Engineer - barrier_trap damage boost
	var trap_eng := ArtifactDef.new()
	trap_eng.artifact_id = "trap_engineer"
	trap_eng.artifact_name = "Trap Engineer"
	trap_eng.description = "Barriers with barrier_trap deal +2 damage."
	trap_eng.rarity = 1
	trap_eng.base_cost = 45
	trap_eng.stackable = true
	trap_eng.required_tags = ["barrier_trap"]
	trap_eng.trigger_type = "on_barrier_trigger"
	trap_eng.trigger_tag = "barrier_trap"
	trap_eng.effect_type = "bonus_damage"
	trap_eng.effect_value = 2
	trap_eng.icon = "⚙️"
	trap_eng.icon_color = Color(0.5, 0.5, 0.5)
	_register_artifact(trap_eng)
	
	# Runic Bastion - fortress barriers grant armor
	var runic_bast := ArtifactDef.new()
	runic_bast.artifact_id = "runic_bastion"
	runic_bast.artifact_name = "Runic Bastion"
	runic_bast.description = "Fortress barriers grant 1 armor when triggered."
	runic_bast.rarity = 2
	runic_bast.base_cost = 55
	runic_bast.stackable = true
	runic_bast.required_tags = ["fortress"]
	runic_bast.trigger_type = "on_barrier_trigger"
	runic_bast.trigger_tag = "fortress"
	runic_bast.effect_type = "gain_armor"
	runic_bast.effect_value = 1
	runic_bast.icon = "🏯"
	runic_bast.icon_color = Color(0.3, 0.4, 0.7)
	_register_artifact(runic_bast)
	
	# Punishing Walls - barrier damage applies hex (rare)
	var punishing := ArtifactDef.new()
	punishing.artifact_id = "punishing_walls"
	punishing.artifact_name = "Punishing Walls"
	punishing.description = "Whenever a barrier deals damage, apply 1 hex to that enemy."
	punishing.rarity = 3
	punishing.base_cost = 90
	punishing.stackable = false
	punishing.trigger_type = "on_barrier_trigger"
	punishing.effect_type = "barrier_hex"
	punishing.effect_value = 1
	punishing.icon = "🧱"
	punishing.icon_color = Color(0.6, 0.3, 0.5)
	_register_artifact(punishing)
	
	# Nested Circles - start with barrier
	var nested := ArtifactDef.new()
	nested.artifact_id = "nested_circles"
	nested.artifact_name = "Nested Circles"
	nested.description = "Start each wave with a Minor Barrier in Close."
	nested.rarity = 2
	nested.base_cost = 60
	nested.stackable = false
	nested.trigger_type = "on_wave_start"
	nested.effect_type = "spawn_barrier"
	nested.effect_value = 1  # Close ring
	nested.icon = "⭕"
	nested.icon_color = Color(0.4, 0.6, 0.7)
	_register_artifact(nested)


# =============================================================================
# VOLATILE/PUSH FAMILY ARTIFACTS
# =============================================================================

func _create_volatile_artifacts() -> void:
	"""Artifacts for volatile/push builds."""
	
	# Kinetic Harness - push deals damage
	var kinetic := ArtifactDef.new()
	kinetic.artifact_id = "kinetic_harness"
	kinetic.artifact_name = "Kinetic Harness"
	kinetic.description = "When you push an enemy, deal 1 damage to it."
	kinetic.rarity = 1
	kinetic.base_cost = 40
	kinetic.stackable = true
	kinetic.trigger_type = "on_card_play"
	kinetic.trigger_tag = "ring_control"
	kinetic.effect_type = "push_damage"
	kinetic.effect_value = 1
	kinetic.icon = "💨"
	kinetic.icon_color = Color(0.5, 0.7, 0.9)
	_register_artifact(kinetic)
	
	# Shock Collars - movement damage
	var shock := ArtifactDef.new()
	shock.artifact_id = "shock_collars"
	shock.artifact_name = "Shock Collars"
	shock.description = "Enemies that move from Mid to Close take 1 damage."
	shock.rarity = 2
	shock.base_cost = 55
	shock.stackable = true
	shock.trigger_type = "passive"  # Handled by combat system
	shock.effect_type = "movement_damage"
	shock.effect_value = 1
	shock.icon = "⚡"
	shock.icon_color = Color(1.0, 0.8, 0.2)
	_register_artifact(shock)
	
	# Last Stand Protocol - defensive boost (rare)
	var last_stand := ArtifactDef.new()
	last_stand.artifact_id = "last_stand_protocol"
	last_stand.artifact_name = "Last Stand Protocol"
	last_stand.description = "At turn start, if 3+ enemies in Melee: gain +1 energy and 3 armor."
	last_stand.rarity = 3
	last_stand.base_cost = 85
	last_stand.stackable = false
	last_stand.trigger_type = "on_turn_start"
	last_stand.effect_type = "last_stand"
	last_stand.effect_value = 3  # Armor gained
	last_stand.icon = "🛑"
	last_stand.icon_color = Color(0.9, 0.3, 0.2)
	_register_artifact(last_stand)
	
	# Overloader - volatile boost with HP cost
	var overloader := ArtifactDef.new()
	overloader.artifact_id = "overloader"
	overloader.artifact_name = "Overloader"
	overloader.description = "Volatile cards deal +2 damage. At end of each wave, lose 3 HP."
	overloader.rarity = 2
	overloader.base_cost = 50
	overloader.stackable = false
	overloader.required_tags = ["volatile"]
	overloader.trigger_type = "on_card_play"
	overloader.trigger_tag = "volatile"
	overloader.effect_type = "bonus_damage"
	overloader.effect_value = 2
	overloader.icon = "💥"
	overloader.icon_color = Color(1.0, 0.5, 0.2)
	_register_artifact(overloader)


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func _register_artifact(artifact) -> void:
	artifacts[artifact.artifact_id] = artifact


func get_artifact(artifact_id: String):
	return artifacts.get(artifact_id, null)


func equip_artifact(artifact_id: String) -> bool:
	"""Equip an artifact. Returns false if non-stackable and already owned."""
	var artifact = get_artifact(artifact_id)
	if not artifact:
		return false
	
	# Check stackability
	if not artifact.stackable and artifact_id in equipped_artifacts:
		print("[ArtifactManager] Cannot stack non-stackable artifact: ", artifact.artifact_name)
		return false
	
	equipped_artifacts.append(artifact_id)
	artifact_acquired.emit(artifact)
	
	# Apply stat modifiers to PlayerStats
	if artifact.stat_modifiers.size() > 0 and RunManager:
		RunManager.player_stats.apply_modifiers(artifact.stat_modifiers)
		RunManager.stats_changed.emit()
	
	print("[ArtifactManager] Equipped artifact: ", artifact.artifact_name, " (x", get_artifact_count(artifact_id), ")")
	stats_changed.emit()
	return true


func get_artifact_count(artifact_id: String) -> int:
	"""Get how many copies of an artifact are equipped."""
	var count: int = 0
	for id: String in equipped_artifacts:
		if id == artifact_id:
			count += 1
	return count


func has_artifact(artifact_id: String) -> bool:
	return artifact_id in equipped_artifacts


func clear_artifacts() -> void:
	equipped_artifacts.clear()
	stats_changed.emit()


func get_equipped_artifacts() -> Array:
	"""Get list of all equipped artifact definitions."""
	var result: Array = []
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if artifact:
			result.append(artifact)
	return result


func get_unique_equipped_artifacts() -> Array:
	"""Get list of unique equipped artifacts with counts."""
	var unique_ids: Array = []
	var result: Array = []
	
	for artifact_id: String in equipped_artifacts:
		if artifact_id not in unique_ids:
			unique_ids.append(artifact_id)
			var artifact = get_artifact(artifact_id)
			if artifact:
				result.append({
					"artifact": artifact,
					"count": get_artifact_count(artifact_id)
				})
	return result


func trigger_artifacts(trigger_type: String, context: Dictionary = {}) -> Dictionary:
	"""Trigger all artifacts of a specific trigger type and return combined effects."""
	var effects: Dictionary = {
		"bonus_damage": 0,
		"bonus_armor": 0,
		"bonus_heal": 0,
		"bonus_hex": 0,
		"heal": 0,
		"draw_cards": 0,
		"bonus_scrap": 0,
		"cost_reduction": 0,
		"gain_armor": 0
	}
	
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if not artifact:
			continue
		
		if artifact.trigger_type != trigger_type:
			continue
		
		# Check tag filter
		if artifact.trigger_tag != "" and context.has("card_tags"):
			if artifact.trigger_tag not in context.card_tags:
				continue
		
		# Check condition
		if artifact.trigger_condition != "" and context.has("condition"):
			if artifact.trigger_condition != context.condition:
				continue
		
		# Apply effect based on type
		match artifact.effect_type:
			"bonus_damage":
				effects.bonus_damage += artifact.effect_value
			"bonus_armor", "gain_armor":
				effects.gain_armor += artifact.effect_value
			"bonus_heal":
				effects.bonus_heal += artifact.effect_value
			"bonus_hex":
				effects.bonus_hex += artifact.effect_value
			"heal":
				if RunManager:
					RunManager.heal(artifact.effect_value)
			"draw_cards":
				effects.draw_cards += artifact.effect_value
			"bonus_scrap":
				effects.bonus_scrap += artifact.effect_value
			"cost_reduction":
				effects.cost_reduction += artifact.effect_value
			"push_damage":
				effects.bonus_damage += artifact.effect_value
			"blood_pact":
				# Lose HP, gain permanent hex damage
				if RunManager:
					RunManager.take_damage(artifact.effect_value)
					RunManager.player_stats.apply_modifier("hex_damage_percent", 2.0)
			"last_stand":
				# Check if 3+ enemies in Melee
				if context.has("melee_enemy_count") and context.melee_enemy_count >= 3:
					effects.gain_armor += artifact.effect_value
					if RunManager:
						RunManager.add_energy(1)
		
		artifact_triggered.emit(artifact, context)
	
	# Apply armor gain
	if effects.gain_armor > 0 and RunManager:
		RunManager.add_armor(effects.gain_armor)
	
	return effects


func get_total_stat_modifiers() -> Dictionary:
	"""Get combined stat modifiers from all equipped artifacts."""
	var total: Dictionary = {}
	
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if artifact and artifact.stat_modifiers.size() > 0:
			for stat_name: String in artifact.stat_modifiers:
				if not total.has(stat_name):
					total[stat_name] = 0
				total[stat_name] += artifact.stat_modifiers[stat_name]
	
	return total


func get_hex_multiplier() -> float:
	"""Get hex damage multiplier from equipped artifacts (V2 compatibility)."""
	var mods: Dictionary = get_total_stat_modifiers()
	var bonus: float = mods.get("hex_damage_percent", 0.0)
	return 1.0 + (bonus / 100.0)


func get_gun_multiplier() -> float:
	"""Get gun damage multiplier from equipped artifacts."""
	var mods: Dictionary = get_total_stat_modifiers()
	var bonus: float = mods.get("gun_damage_percent", 0.0)
	return 1.0 + (bonus / 100.0)


func get_barrier_multiplier() -> float:
	"""Get barrier damage multiplier from equipped artifacts."""
	var mods: Dictionary = get_total_stat_modifiers()
	var bonus: float = mods.get("barrier_damage_percent", 0.0)
	return 1.0 + (bonus / 100.0)


func get_random_artifact(exclude_ids: Array = []):
	"""Get a random artifact. Excludes non-stackable artifacts already owned."""
	var available: Array = []
	for artifact_id: String in artifacts.keys():
		if artifact_id in exclude_ids:
			continue
		var artifact = artifacts[artifact_id]
		# Skip non-stackable artifacts already owned
		if not artifact.stackable and artifact_id in equipped_artifacts:
			continue
		available.append(artifact_id)
	
	if available.size() > 0:
		return artifacts[available[randi() % available.size()]]
	return null


func get_available_artifacts() -> Array:
	"""Get all artifacts available for shop (respects stackability)."""
	var result: Array = []
	for artifact_id: String in artifacts.keys():
		var artifact = artifacts[artifact_id]
		# Skip non-stackable artifacts already owned
		if not artifact.stackable and artifact_id in equipped_artifacts:
			continue
		
		result.append({
			"artifact_id": artifact.artifact_id,
			"artifact_name": artifact.artifact_name,
			"description": artifact.get_description_with_values(),
			"rarity": artifact.rarity,
			"cost": artifact.base_cost,
			"icon": artifact.icon,
			"icon_color": artifact.icon_color,
			"stackable": artifact.stackable,
			"owned_count": get_artifact_count(artifact_id)
		})
	return result


func acquire_artifact(artifact_id: String) -> bool:
	"""Acquire an artifact (purchase from shop)."""
	return equip_artifact(artifact_id)
