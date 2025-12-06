extends Node
## ArtifactManager - V6 Horde Slaughter Artifact System
## Uses modular ArtifactData.gd for artifact definitions
## ~30 artifacts: 10 Common, 10 Uncommon, 6 Rare, 4 Legendary
## Focused on multi-hit, execute, ripple, and horde-killing synergies

signal artifact_triggered(artifact, context: Dictionary)
signal artifact_acquired(artifact)
@warning_ignore("unused_signal")
signal stats_changed()

var artifacts: Dictionary = {}
var equipped_artifacts: Array = []

const ArtifactDef = preload("res://scripts/resources/ArtifactDefinition.gd")
const ArtifactDataClass = preload("res://scripts/data/ArtifactData.gd")


func _ready() -> void:
	_load_artifacts_from_data()
	var counts: Dictionary = ArtifactDataClass.get_artifact_count()
	print("[ArtifactManager] V6 Initialized with ", counts.total, " artifacts ",
		"(", counts.common, " common, ", counts.uncommon, " uncommon, ",
		counts.rare, " rare, ", counts.legendary, " legendary)")


func _load_artifacts_from_data() -> void:
	"""Load all artifacts from the modular ArtifactData file."""
	for artifact_data: Dictionary in ArtifactDataClass.get_all_artifacts():
		_create_artifact(artifact_data)


# =============================================================================
# ARTIFACT CREATION
# =============================================================================

func _create_artifact(data: Dictionary) -> void:
	var artifact := ArtifactDef.new()
	artifact.artifact_id = data.get("id", "")
	artifact.artifact_name = data.get("name", "")
	artifact.description = data.get("desc", "")
	artifact.icon = data.get("icon", "unknown")
	artifact.rarity = data.get("rarity", 0)
	artifact.base_cost = data.get("cost", 25)
	artifact.stackable = data.get("stackable", false)
	artifact.trigger_type = data.get("trigger_type", "passive")
	artifact.effect_type = data.get("effect_type", "")
	artifact.effect_value = data.get("effect_value", 0)
	if data.has("stat_modifiers"):
		artifact.stat_modifiers = data.get("stat_modifiers")
	if data.has("on_acquire"):
		artifact.on_acquire = data.get("on_acquire")
	_register_artifact(artifact)


func _register_artifact(artifact) -> void:
	artifacts[artifact.artifact_id] = artifact


# =============================================================================
# QUERY FUNCTIONS
# =============================================================================

func get_artifact(artifact_id: String):
	return artifacts.get(artifact_id, null)


func get_all_artifacts() -> Array:
	return artifacts.values()


func get_available_artifacts() -> Array:
	var available: Array = []
	for artifact in artifacts.values():
		var equip_count: int = equipped_artifacts.count(artifact.artifact_id)
		if artifact.stackable or equip_count == 0:
			available.append({
				"artifact_id": artifact.artifact_id,
				"name": artifact.artifact_name,
				"description": artifact.description,
				"rarity": artifact.rarity,
				"cost": artifact.base_cost,
				"icon": artifact.icon,
				"stackable": artifact.stackable,
				"owned_count": equip_count
			})
	return available


func get_artifacts_by_rarity(rarity: int) -> Array:
	var result: Array = []
	for artifact in artifacts.values():
		if artifact.rarity == rarity:
			result.append(artifact)
	return result


# =============================================================================
# ARTIFACT MANAGEMENT
# =============================================================================

func equip_artifact(artifact_id: String) -> bool:
	var artifact = get_artifact(artifact_id)
	if not artifact:
		return false
	if not artifact.stackable and artifact_id in equipped_artifacts:
		return false
	equipped_artifacts.append(artifact_id)
	if artifact.stat_modifiers.size() > 0:
		RunManager.player_stats.apply_modifiers(artifact.stat_modifiers)
		RunManager.stats_changed.emit()
	if artifact.on_acquire == "set_max_hp_25":
		RunManager.player_stats.max_hp = 25
		if RunManager.current_hp > 25:
			RunManager.current_hp = 25
		RunManager.stats_changed.emit()
	artifact_acquired.emit(artifact)
	return true


func unequip_artifact(artifact_id: String) -> bool:
	if artifact_id not in equipped_artifacts:
		return false
	equipped_artifacts.erase(artifact_id)
	var artifact = get_artifact(artifact_id)
	if artifact and artifact.stat_modifiers.size() > 0:
		var reversed: Dictionary = {}
		for stat: String in artifact.stat_modifiers:
			reversed[stat] = -artifact.stat_modifiers[stat]
		RunManager.player_stats.apply_modifiers(reversed)
		RunManager.stats_changed.emit()
	return true


func get_equipped_artifacts() -> Array:
	return equipped_artifacts.duplicate()


func has_artifact(artifact_id: String) -> bool:
	return artifact_id in equipped_artifacts


func get_artifact_count(artifact_id: String) -> int:
	return equipped_artifacts.count(artifact_id)


func get_unique_equipped_artifacts() -> Array:
	"""Get unique equipped artifacts with counts for UI."""
	var unique: Dictionary = {}
	for artifact_id: String in equipped_artifacts:
		if not unique.has(artifact_id):
			unique[artifact_id] = {"artifact": get_artifact(artifact_id), "count": 0}
		unique[artifact_id].count += 1
	return unique.values()


# =============================================================================
# ARTIFACT TRIGGERS
# =============================================================================

func trigger_artifacts(trigger: String, context: Dictionary = {}) -> Dictionary:
	var effects: Dictionary = {
		"bonus_damage": 0,
		"bonus_crit": 0.0,
		"bonus_armor": 0,
		"heal": 0,
		"bonus_scrap": 0,
		"energy_refund": 0,
		"bonus_hits": 0,
	}
	for artifact_id: String in equipped_artifacts:
		var artifact = get_artifact(artifact_id)
		if artifact and artifact.trigger_type == trigger:
			var result: Dictionary = _apply_artifact_effect(artifact, context)
			for key: String in result:
				if effects.has(key):
					effects[key] += result[key]
			artifact_triggered.emit(artifact, context)
	return effects


func _apply_artifact_effect(artifact, _context: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var value = artifact.effect_value
	match artifact.effect_type:
		"bonus_damage":
			result["bonus_damage"] = value
		"bonus_crit":
			result["bonus_crit"] = value
		"bonus_armor":
			result["bonus_armor"] = value
		"heal":
			result["heal"] = value
			RunManager.heal(int(value))
		"bonus_scrap":
			result["bonus_scrap"] = value
			RunManager.add_scrap(int(value))
		"refund_energy":
			result["energy_refund"] = value
		"deal_damage_random":
			result["damage_to_random"] = value
		"bonus_hit", "bonus_hits":
			result["bonus_hits"] = value
		"apply_burn":
			result["apply_burn"] = value
		"mini_ripple":
			result["mini_ripple"] = value
		"full_ripple":
			result["full_ripple"] = true
		"overkill_damage":
			result["overkill"] = true
		"self_damage":
			RunManager.take_damage(int(value))
	return result


# =============================================================================
# STATE MANAGEMENT
# =============================================================================

func reset_artifacts() -> void:
	equipped_artifacts.clear()


func get_hex_multiplier() -> float:
	return 1.0
