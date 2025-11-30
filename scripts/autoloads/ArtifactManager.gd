extends Node
## ArtifactManager - Artifact management
## Contains all artifact definitions and handles artifact triggers

signal artifact_triggered(artifact, context: Dictionary)
signal artifact_acquired(artifact)

var artifacts: Dictionary = {}  # artifact_id -> ArtifactDefinition
var equipped_artifacts: Array = []  # Array of equipped artifact_ids

const ArtifactDef = preload("res://scripts/resources/ArtifactDefinition.gd")


func _ready() -> void:
	_create_default_artifacts()
	print("[ArtifactManager] Initialized with ", artifacts.size(), " artifacts")


func _create_default_artifacts() -> void:
	# === PASSIVE ARTIFACTS (always active) ===
	
	# Quick Draw - draw extra card each turn
	var quick_draw := ArtifactDef.new()
	quick_draw.artifact_id = "quick_draw"
	quick_draw.artifact_name = "Quick Draw"
	quick_draw.description = "Draw {value} extra card each turn."
	quick_draw.rarity = 2
	quick_draw.base_cost = 75
	quick_draw.trigger_type = "on_turn_start"
	quick_draw.effect_type = "draw_cards"
	quick_draw.effect_value = 1
	quick_draw.icon = "🎴"
	quick_draw.icon_color = Color(0.2, 0.6, 0.9)
	_register_artifact(quick_draw)
	
	# Iron Shell - start each wave with armor
	var iron_shell := ArtifactDef.new()
	iron_shell.artifact_id = "iron_shell"
	iron_shell.artifact_name = "Iron Shell"
	iron_shell.description = "Start each wave with {value} Armor."
	iron_shell.rarity = 1
	iron_shell.base_cost = 50
	iron_shell.trigger_type = "on_wave_start"
	iron_shell.effect_type = "gain_armor"
	iron_shell.effect_value = 3
	iron_shell.icon = "🛡️"
	iron_shell.icon_color = Color(0.5, 0.5, 0.6)
	_register_artifact(iron_shell)
	
	# Ember Charm - gun cards deal bonus damage
	var ember_charm := ArtifactDef.new()
	ember_charm.artifact_id = "ember_charm"
	ember_charm.artifact_name = "Ember Charm"
	ember_charm.description = "Gun cards deal +{value} damage."
	ember_charm.rarity = 2
	ember_charm.base_cost = 80
	ember_charm.trigger_type = "on_card_play"
	ember_charm.trigger_tag = "gun"
	ember_charm.effect_type = "bonus_damage"
	ember_charm.effect_value = 2
	ember_charm.icon = "🔥"
	ember_charm.icon_color = Color(0.9, 0.4, 0.1)
	_register_artifact(ember_charm)
	
	# Void Heart - hex damage increased
	var void_heart := ArtifactDef.new()
	void_heart.artifact_id = "void_heart"
	void_heart.artifact_name = "Void Heart"
	void_heart.description = "Hex damage increased by {value}%."
	void_heart.rarity = 2
	void_heart.base_cost = 75
	void_heart.trigger_type = "passive"
	void_heart.effect_type = "hex_multiplier"
	void_heart.effect_value = 50
	void_heart.icon = "💜"
	void_heart.icon_color = Color(0.5, 0.2, 0.7)
	_register_artifact(void_heart)
	
	# Refracting Core - bonus armor when gaining armor
	var refracting := ArtifactDef.new()
	refracting.artifact_id = "refracting_core"
	refracting.artifact_name = "Refracting Core"
	refracting.description = "When you gain Armor, gain {value} extra."
	refracting.rarity = 2
	refracting.base_cost = 70
	refracting.trigger_type = "on_card_play"
	refracting.trigger_tag = "armor"
	refracting.effect_type = "bonus_armor"
	refracting.effect_value = 1
	refracting.icon = "💎"
	refracting.icon_color = Color(0.3, 0.8, 0.9)
	_register_artifact(refracting)
	
	# === ON-KILL ARTIFACTS ===
	
	# Blood Sigil - heal on kill
	var blood_sigil := ArtifactDef.new()
	blood_sigil.artifact_id = "blood_sigil"
	blood_sigil.artifact_name = "Blood Sigil"
	blood_sigil.description = "Heal {value} HP when you kill an enemy."
	blood_sigil.rarity = 2
	blood_sigil.base_cost = 80
	blood_sigil.trigger_type = "on_kill"
	blood_sigil.effect_type = "heal"
	blood_sigil.effect_value = 1
	blood_sigil.icon = "🩸"
	blood_sigil.icon_color = Color(0.8, 0.1, 0.2)
	_register_artifact(blood_sigil)
	
	# Scavenger's Eye - bonus scrap from kills
	var scavenger := ArtifactDef.new()
	scavenger.artifact_id = "scavengers_eye"
	scavenger.artifact_name = "Scavenger's Eye"
	scavenger.description = "Gain +{value} Scrap from enemy kills."
	scavenger.rarity = 1
	scavenger.base_cost = 60
	scavenger.trigger_type = "on_kill"
	scavenger.effect_type = "bonus_scrap"
	scavenger.effect_value = 1
	scavenger.icon = "👁️"
	scavenger.icon_color = Color(0.7, 0.6, 0.2)
	_register_artifact(scavenger)
	
	# Leech Tooth - heal at end of turn if you killed something
	var leech_tooth := ArtifactDef.new()
	leech_tooth.artifact_id = "leech_tooth"
	leech_tooth.artifact_name = "Leech Tooth"
	leech_tooth.description = "Heal {value} HP at end of turn if you killed an enemy this turn."
	leech_tooth.rarity = 2
	leech_tooth.base_cost = 75
	leech_tooth.trigger_type = "on_turn_end"
	leech_tooth.trigger_condition = "killed_this_turn"
	leech_tooth.effect_type = "heal"
	leech_tooth.effect_value = 2
	leech_tooth.icon = "🦷"
	leech_tooth.icon_color = Color(0.9, 0.9, 0.7)
	_register_artifact(leech_tooth)
	
	# === ON-DAMAGE ARTIFACTS ===
	
	# Hex Amplifier - hexed enemies take damage at turn start
	var hex_amp := ArtifactDef.new()
	hex_amp.artifact_id = "hex_amplifier"
	hex_amp.artifact_name = "Hex Amplifier"
	hex_amp.description = "Enemies with Hex take {value} damage at turn start."
	hex_amp.rarity = 3
	hex_amp.base_cost = 100
	hex_amp.trigger_type = "on_turn_start"
	hex_amp.effect_type = "hex_tick_damage"
	hex_amp.effect_value = 1
	hex_amp.icon = "⚡"
	hex_amp.icon_color = Color(0.6, 0.3, 0.8)
	_register_artifact(hex_amp)
	
	# Gun Harness - first gun card costs less
	var gun_harness := ArtifactDef.new()
	gun_harness.artifact_id = "gun_harness"
	gun_harness.artifact_name = "Gun Harness"
	gun_harness.description = "First Gun card each turn costs {value} less Energy."
	gun_harness.rarity = 2
	gun_harness.base_cost = 70
	gun_harness.trigger_type = "passive"
	gun_harness.trigger_tag = "gun"
	gun_harness.effect_type = "cost_reduction"
	gun_harness.effect_value = 1
	gun_harness.icon = "🔧"
	gun_harness.icon_color = Color(0.4, 0.4, 0.5)
	_register_artifact(gun_harness)


func _register_artifact(artifact) -> void:
	artifacts[artifact.artifact_id] = artifact


func get_artifact(artifact_id: String):
	return artifacts.get(artifact_id, null)


func equip_artifact(artifact_id: String) -> void:
	if artifact_id not in equipped_artifacts:
		equipped_artifacts.append(artifact_id)
		var artifact = get_artifact(artifact_id)
		if artifact:
			artifact_acquired.emit(artifact)
			print("[ArtifactManager] Equipped artifact: ", artifact.artifact_name)


func has_artifact(artifact_id: String) -> bool:
	return artifact_id in equipped_artifacts


func clear_artifacts() -> void:
	equipped_artifacts.clear()


func get_equipped_artifacts() -> Array:
	"""Get list of all equipped artifact definitions."""
	var result: Array = []
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if artifact:
			result.append(artifact)
	return result


func trigger_artifacts(trigger_type: String, context: Dictionary = {}) -> Dictionary:
	"""Trigger all artifacts of a specific trigger type and return combined effects."""
	var effects: Dictionary = {
		"bonus_damage": 0,
		"bonus_armor": 0,
		"heal": 0,
		"draw_cards": 0,
		"bonus_scrap": 0,
		"cost_reduction": 0
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
		
		# Apply effect
		match artifact.effect_type:
			"bonus_damage":
				effects.bonus_damage += artifact.effect_value
			"bonus_armor":
				effects.bonus_armor += artifact.effect_value
			"gain_armor":
				RunManager.add_armor(artifact.effect_value)
			"heal":
				RunManager.heal(artifact.effect_value)
			"draw_cards":
				effects.draw_cards += artifact.effect_value
			"bonus_scrap":
				effects.bonus_scrap += artifact.effect_value
			"cost_reduction":
				effects.cost_reduction += artifact.effect_value
			"hex_tick_damage":
				# Handle hex tick damage in CombatManager
				effects["hex_tick_damage"] = artifact.effect_value
		
		artifact_triggered.emit(artifact, context)
	
	return effects


func get_gun_cost_reduction() -> int:
	"""Get total cost reduction for gun cards from passive artifacts."""
	var reduction: int = 0
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if artifact and artifact.trigger_type == "passive" and artifact.trigger_tag == "gun":
			if artifact.effect_type == "cost_reduction":
				reduction += artifact.effect_value
	return reduction


func get_hex_multiplier() -> float:
	"""Get hex damage multiplier from passive artifacts."""
	var multiplier: float = 1.0
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if artifact and artifact.trigger_type == "passive":
			if artifact.effect_type == "hex_multiplier":
				multiplier += artifact.effect_value / 100.0
	return multiplier


func get_random_artifact(exclude_ids: Array = []):
	"""Get a random artifact that's not in exclude list."""
	var available: Array = []
	for artifact_id: String in artifacts.keys():
		if artifact_id not in exclude_ids and artifact_id not in equipped_artifacts:
			available.append(artifact_id)
	
	if available.size() > 0:
		return artifacts[available[randi() % available.size()]]
	return null


func get_available_artifacts() -> Array:
	"""Get all artifacts that are not equipped yet (for shop)."""
	var result: Array = []
	for artifact_id: String in artifacts.keys():
		if artifact_id not in equipped_artifacts:
			var artifact = artifacts[artifact_id]
			# Convert to dictionary for easier use in Shop UI
			result.append({
				"artifact_id": artifact.artifact_id,
				"artifact_name": artifact.artifact_name,
				"description": artifact.get_description_with_values(),
				"rarity": artifact.rarity,
				"cost": artifact.base_cost,
				"icon": artifact.icon,
				"icon_color": artifact.icon_color
			})
	return result


func acquire_artifact(artifact_id: String) -> bool:
	"""Acquire an artifact (purchase from shop)."""
	if artifact_id in equipped_artifacts:
		return false
	if not artifacts.has(artifact_id):
		return false
	
	equip_artifact(artifact_id)
	return true
