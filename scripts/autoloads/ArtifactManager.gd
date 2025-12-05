extends Node
## ArtifactManager - V6 Horde Slaughter Artifact System
## ~30 artifacts: 10 Common, 10 Uncommon, 6 Rare, 4 Legendary
## Focused on multi-hit, execute, ripple, and horde-killing synergies

signal artifact_triggered(artifact, context: Dictionary)
signal artifact_acquired(artifact)
@warning_ignore("unused_signal")
signal stats_changed()

var artifacts: Dictionary = {}
var equipped_artifacts: Array = []

const ArtifactDef = preload("res://scripts/resources/ArtifactDefinition.gd")


func _ready() -> void:
	_create_v6_artifacts()
	print("[ArtifactManager] V6 Initialized with ", artifacts.size(), " artifacts")


func _create_v6_artifacts() -> void:
	_create_common_artifacts()
	_create_uncommon_artifacts()
	_create_rare_artifacts()
	_create_legendary_artifacts()


# =============================================================================
# COMMON ARTIFACTS (10) - Simple stat bonuses, stackable
# =============================================================================

func _create_common_artifacts() -> void:
	# Flat damage bonuses
	_create_artifact({
		"id": "kinetic_rounds", "name": "Kinetic Rounds", 
		"desc": "+3 Kinetic damage", "icon": "bullet", 
		"rarity": 0, "cost": 25, "stackable": true, 
		"stat_modifiers": {"kinetic": 3}
	})
	
	_create_artifact({
		"id": "thermal_core", "name": "Thermal Core", 
		"desc": "+3 Thermal damage", "icon": "fire", 
		"rarity": 0, "cost": 25, "stackable": true, 
		"stat_modifiers": {"thermal": 3}
	})
	
	_create_artifact({
		"id": "arcane_focus", "name": "Arcane Focus", 
		"desc": "+3 Arcane damage", "icon": "crystal", 
		"rarity": 0, "cost": 25, "stackable": true, 
		"stat_modifiers": {"arcane": 3}
	})
	
	# Crit bonuses
	_create_artifact({
		"id": "lucky_coin", "name": "Lucky Coin", 
		"desc": "+5% Crit chance", "icon": "coin", 
		"rarity": 0, "cost": 30, "stackable": true, 
		"stat_modifiers": {"crit_chance": 5.0}
	})
	
	_create_artifact({
		"id": "heavy_hitter", "name": "Heavy Hitter", 
		"desc": "+20% Crit damage", "icon": "skull", 
		"rarity": 0, "cost": 30, "stackable": true, 
		"stat_modifiers": {"crit_damage": 20.0}
	})
	
	# V6 HORDE: Multi-hit bonus
	_create_artifact({
		"id": "extra_rounds", "name": "Extra Rounds", 
		"desc": "+1 hit to all weapons", "icon": "ammo", 
		"rarity": 0, "cost": 35, "stackable": true, 
		"stat_modifiers": {"bonus_hits": 1}
	})
	
	# Defensive
	_create_artifact({
		"id": "iron_skin", "name": "Iron Skin", 
		"desc": "+10 Max HP", "icon": "heart", 
		"rarity": 0, "cost": 25, "stackable": true, 
		"stat_modifiers": {"max_hp": 10}
	})
	
	_create_artifact({
		"id": "steel_plate", "name": "Steel Plate", 
		"desc": "+3 Armor at wave start", "icon": "shield", 
		"rarity": 0, "cost": 25, "stackable": true, 
		"stat_modifiers": {"armor_start": 3}
	})
	
	# Utility
	_create_artifact({
		"id": "vampiric_fang", "name": "Vampiric Fang", 
		"desc": "+5% Lifesteal", "icon": "fang", 
		"rarity": 0, "cost": 35, "stackable": true, 
		"stat_modifiers": {"lifesteal_percent": 5.0}
	})
	
	_create_artifact({
		"id": "aoe_amplifier", "name": "AOE Amplifier", 
		"desc": "+15% AOE damage", "icon": "bomb", 
		"rarity": 0, "cost": 30, "stackable": true, 
		"stat_modifiers": {"aoe_percent": 15.0}
	})


# =============================================================================
# UNCOMMON ARTIFACTS (10) - Synergy enablers
# =============================================================================

func _create_uncommon_artifacts() -> void:
	# Kill bonuses - core for horde slaughter
	_create_artifact({
		"id": "hunters_instinct", "name": "Hunter's Instinct", 
		"desc": "On kill: heal 2 HP", "icon": "bow", 
		"rarity": 1, "cost": 45, "stackable": true, 
		"trigger_type": "on_kill", "effect_type": "heal", "effect_value": 2
	})
	
	_create_artifact({
		"id": "bounty_hunter", "name": "Bounty Hunter", 
		"desc": "On kill: +2 scrap", "icon": "bag", 
		"rarity": 1, "cost": 45, "stackable": true, 
		"trigger_type": "on_kill", "effect_type": "bonus_scrap", "effect_value": 2
	})
	
	# Multi-hit synergies
	_create_artifact({
		"id": "rapid_fire_module", "name": "Rapid Fire Module", 
		"desc": "Multi-hit weapons +20% damage", "icon": "gears", 
		"rarity": 1, "cost": 50, "stackable": true, 
		"stat_modifiers": {"multi_hit_damage_percent": 20.0}
	})
	
	_create_artifact({
		"id": "crit_chain", "name": "Crit Chain", 
		"desc": "Crits grant +1 hit this turn", "icon": "chain", 
		"rarity": 1, "cost": 55, "stackable": false, 
		"trigger_type": "on_crit", "effect_type": "bonus_hit", "effect_value": 1
	})
	
	# Execute synergies
	_create_artifact({
		"id": "executioner_blade", "name": "Executioner's Blade", 
		"desc": "Execute kills: +1 energy", "icon": "axe", 
		"rarity": 1, "cost": 50, "stackable": false, 
		"trigger_type": "on_execute_kill", "effect_type": "refund_energy", "effect_value": 1
	})
	
	# Status effect synergies
	_create_artifact({
		"id": "burn_amplifier", "name": "Burn Amplifier", 
		"desc": "Burn damage +50%", "icon": "flame", 
		"rarity": 1, "cost": 45, "stackable": true, 
		"stat_modifiers": {"burn_potency": 50.0}
	})
	
	_create_artifact({
		"id": "hex_amplifier", "name": "Hex Amplifier", 
		"desc": "Hex damage +50%", "icon": "hex", 
		"rarity": 1, "cost": 45, "stackable": true, 
		"stat_modifiers": {"hex_potency": 50.0}
	})
	
	# Economy/Tempo
	_create_artifact({
		"id": "rapid_loader", "name": "Rapid Loader", 
		"desc": "+1 Draw per turn", "icon": "scroll", 
		"rarity": 1, "cost": 60, "stackable": false, 
		"stat_modifiers": {"draw_per_turn": 1}
	})
	
	_create_artifact({
		"id": "power_cell", "name": "Power Cell", 
		"desc": "+1 Energy per turn", "icon": "battery", 
		"rarity": 1, "cost": 65, "stackable": false, 
		"stat_modifiers": {"energy_per_turn": 1}
	})
	
	# First card bonus
	_create_artifact({
		"id": "opening_salvo", "name": "Opening Salvo", 
		"desc": "First card each turn: +2 hits", "icon": "target", 
		"rarity": 1, "cost": 55, "stackable": false, 
		"trigger_type": "on_first_card", "effect_type": "bonus_hits", "effect_value": 2
	})


# =============================================================================
# RARE ARTIFACTS (6) - Powerful effects
# =============================================================================

func _create_rare_artifacts() -> void:
	# Overkill - damage chains to next enemy
	_create_artifact({
		"id": "overkill", "name": "Overkill", 
		"desc": "Excess kill damage hits random enemy", "icon": "blast", 
		"rarity": 2, "cost": 80, "stackable": false, 
		"trigger_type": "on_kill", "effect_type": "overkill_damage", "effect_value": 0
	})
	
	# Mini ripple on all kills
	_create_artifact({
		"id": "death_echo", "name": "Death Echo", 
		"desc": "Kills deal 2 damage to enemy's group", "icon": "wave", 
		"rarity": 2, "cost": 85, "stackable": false, 
		"trigger_type": "on_kill", "effect_type": "mini_ripple", "effect_value": 2
	})
	
	# Execute threshold boost
	_create_artifact({
		"id": "mercy_killer", "name": "Mercy Killer", 
		"desc": "Execute threshold +3 on all enemies", "icon": "reaper", 
		"rarity": 2, "cost": 90, "stackable": true, 
		"stat_modifiers": {"execute_threshold_bonus": 3}
	})
	
	# Crits apply burn
	_create_artifact({
		"id": "burning_strikes", "name": "Burning Strikes", 
		"desc": "Crits apply 2 Burn", "icon": "fire_sword", 
		"rarity": 2, "cost": 75, "stackable": false, 
		"trigger_type": "on_crit", "effect_type": "apply_burn", "effect_value": 2
	})
	
	# Multi-hit can repeat
	_create_artifact({
		"id": "focused_fire", "name": "Focused Fire", 
		"desc": "All multi-hit weapons can repeat targets", "icon": "crosshair", 
		"rarity": 2, "cost": 70, "stackable": false, 
		"stat_modifiers": {"all_repeat_target": 1}
	})
	
	# Glass cannon variant
	_create_artifact({
		"id": "berserker_rage", "name": "Berserker's Rage", 
		"desc": "All damage +25%. Take 1 damage per attack", "icon": "rage", 
		"rarity": 2, "cost": 80, "stackable": false, 
		"stat_modifiers": {"damage_percent": 25.0},
		"trigger_type": "on_attack", "effect_type": "self_damage", "effect_value": 1
	})


# =============================================================================
# LEGENDARY ARTIFACTS (4) - Build definers
# =============================================================================

func _create_legendary_artifacts() -> void:
	# Infinity Engine - kills refund energy
	_create_artifact({
		"id": "infinity_engine", "name": "Infinity Engine", 
		"desc": "Kills refund 1 energy", "icon": "infinity", 
		"rarity": 3, "cost": 120, "stackable": false, 
		"trigger_type": "on_kill", "effect_type": "refund_energy", "effect_value": 1
	})
	
	# Bullet Storm - +3 hits to all weapons
	_create_artifact({
		"id": "bullet_storm", "name": "Bullet Storm", 
		"desc": "All weapons +3 hits", "icon": "storm", 
		"rarity": 3, "cost": 130, "stackable": false, 
		"stat_modifiers": {"bonus_hits": 3}
	})
	
	# Blood Pact - heavy lifesteal, reduced HP
	_create_artifact({
		"id": "blood_pact", "name": "Blood Pact", 
		"desc": "Lifesteal 20%. Max HP -30", "icon": "blood", 
		"rarity": 3, "cost": 100, "stackable": false, 
		"stat_modifiers": {"lifesteal_percent": 20.0, "max_hp": -30}
	})
	
	# Chain Reaction - full ripple on every kill
	_create_artifact({
		"id": "chain_reaction", "name": "Chain Reaction", 
		"desc": "Every kill triggers ripple chain", "icon": "explosion", 
		"rarity": 3, "cost": 140, "stackable": false, 
		"trigger_type": "on_kill", "effect_type": "full_ripple", "effect_value": 0
	})


# =============================================================================
# ARTIFACT MANAGEMENT
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


func reset_artifacts() -> void:
	equipped_artifacts.clear()


func get_hex_multiplier() -> float:
	return 1.0


func get_artifacts_by_rarity(rarity: int) -> Array:
	var result: Array = []
	for artifact in artifacts.values():
		if artifact.rarity == rarity:
			result.append(artifact)
	return result
