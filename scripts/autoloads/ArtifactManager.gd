extends Node
## ArtifactManager - V5 Brotato-style Artifact System
## 50 artifacts: 16 Common, 16 Uncommon, 12 Rare, 6 Legendary

signal artifact_triggered(artifact, context: Dictionary)
signal artifact_acquired(artifact)
@warning_ignore("unused_signal")
signal stats_changed()  # Reserved for future UI binding

var artifacts: Dictionary = {}
var equipped_artifacts: Array = []

const ArtifactDef = preload("res://scripts/resources/ArtifactDefinition.gd")


func _ready() -> void:
	_create_v5_artifacts()
	print("[ArtifactManager] V5 Initialized with ", artifacts.size(), " artifacts")


func _create_v5_artifacts() -> void:
	_create_common_artifacts()
	_create_uncommon_artifacts()
	_create_rare_artifacts()
	_create_legendary_artifacts()


func _create_common_artifacts() -> void:
	_create_artifact({"id": "kinetic_rounds", "name": "Kinetic Rounds", "desc": "+3 Kinetic", "icon": "bullet", "rarity": 0, "cost": 25, "stackable": true, "stat_modifiers": {"kinetic": 3}})
	_create_artifact({"id": "thermal_core", "name": "Thermal Core", "desc": "+3 Thermal", "icon": "fire", "rarity": 0, "cost": 25, "stackable": true, "stat_modifiers": {"thermal": 3}})
	_create_artifact({"id": "arcane_focus", "name": "Arcane Focus", "desc": "+3 Arcane", "icon": "crystal", "rarity": 0, "cost": 25, "stackable": true, "stat_modifiers": {"arcane": 3}})
	_create_artifact({"id": "kinetic_amplifier", "name": "Kinetic Amplifier", "desc": "Kinetic damage +10%", "icon": "amplifier", "rarity": 0, "cost": 30, "stackable": true, "stat_modifiers": {"kinetic_percent": 10.0}})
	_create_artifact({"id": "thermal_amplifier", "name": "Thermal Amplifier", "desc": "Thermal damage +10%", "icon": "flame", "rarity": 0, "cost": 30, "stackable": true, "stat_modifiers": {"thermal_percent": 10.0}})
	_create_artifact({"id": "arcane_amplifier", "name": "Arcane Amplifier", "desc": "Arcane damage +10%", "icon": "magic", "rarity": 0, "cost": 30, "stackable": true, "stat_modifiers": {"arcane_percent": 10.0}})
	_create_artifact({"id": "sharp_edge", "name": "Sharp Edge", "desc": "ALL damage +5%", "icon": "sword", "rarity": 0, "cost": 35, "stackable": true, "stat_modifiers": {"damage_percent": 5.0}})
	_create_artifact({"id": "lucky_coin", "name": "Lucky Coin", "desc": "Crit chance +3%", "icon": "coin", "rarity": 0, "cost": 30, "stackable": true, "stat_modifiers": {"crit_chance": 3.0}})
	_create_artifact({"id": "heavy_hitter", "name": "Heavy Hitter", "desc": "Crit damage +15%", "icon": "skull", "rarity": 0, "cost": 30, "stackable": true, "stat_modifiers": {"crit_damage": 15.0}})
	_create_artifact({"id": "vampiric_fang", "name": "Vampiric Fang", "desc": "Lifesteal +3%", "icon": "fang", "rarity": 0, "cost": 35, "stackable": true, "stat_modifiers": {"lifesteal_percent": 3.0}})
	_create_artifact({"id": "blast_amplifier", "name": "Blast Amplifier", "desc": "AOE damage +10%", "icon": "bomb", "rarity": 0, "cost": 30, "stackable": true, "stat_modifiers": {"aoe_percent": 10.0}})
	_create_artifact({"id": "iron_skin", "name": "Iron Skin", "desc": "+5 Max HP", "icon": "heart", "rarity": 0, "cost": 20, "stackable": true, "stat_modifiers": {"max_hp": 5}})
	_create_artifact({"id": "steel_plate", "name": "Steel Plate", "desc": "+2 Armor at wave start", "icon": "shield", "rarity": 0, "cost": 25, "stackable": true, "stat_modifiers": {"armor_start": 2}})
	_create_artifact({"id": "scrap_collector", "name": "Scrap Collector", "desc": "Scrap gain +10%", "icon": "gear", "rarity": 0, "cost": 25, "stackable": true, "stat_modifiers": {"scrap_gain_percent": 10.0}})
	_create_artifact({"id": "card_sleeve", "name": "Card Sleeve", "desc": "+1 Hand Size", "icon": "cards", "rarity": 0, "cost": 30, "stackable": true, "stat_modifiers": {"hand_size": 1}})
	_create_artifact({"id": "hex_potency_gem", "name": "Hex Potency Gem", "desc": "Hex deals +15%", "icon": "gem", "rarity": 0, "cost": 30, "stackable": true, "stat_modifiers": {"hex_potency": 15.0}})


func _create_uncommon_artifacts() -> void:
	_create_artifact({"id": "precision_scope", "name": "Precision Scope", "desc": "Kinetic weapons: +5% crit", "icon": "scope", "rarity": 1, "cost": 45, "stackable": true, "trigger_type": "on_kinetic_attack", "effect_type": "bonus_crit", "effect_value": 5.0})
	_create_artifact({"id": "pyromaniac", "name": "Pyromaniac", "desc": "Thermal kills: 2 Burn to adjacent", "icon": "flame", "rarity": 1, "cost": 50, "stackable": false, "trigger_type": "on_thermal_kill", "effect_type": "apply_burn_aoe", "effect_value": 2})
	_create_artifact({"id": "soul_leech", "name": "Soul Leech", "desc": "Arcane damage: heal 10% dealt", "icon": "ghost", "rarity": 1, "cost": 55, "stackable": true, "trigger_type": "on_arcane_damage", "effect_type": "heal_percent_damage", "effect_value": 10.0})
	_create_artifact({"id": "reactive_armor", "name": "Reactive Armor", "desc": "Fortress cards: +1 armor gained", "icon": "armor", "rarity": 1, "cost": 45, "stackable": true, "trigger_type": "on_fortress_play", "effect_type": "bonus_armor", "effect_value": 1})
	_create_artifact({"id": "assassins_mark", "name": "Assassin's Mark", "desc": "Shadow crits: +25% crit damage", "icon": "dagger", "rarity": 1, "cost": 50, "stackable": true, "trigger_type": "on_shadow_crit", "effect_type": "bonus_crit_damage", "effect_value": 25.0})
	_create_artifact({"id": "nimble_fingers", "name": "Nimble Fingers", "desc": "First Utility each turn costs 0", "icon": "hand", "rarity": 1, "cost": 55, "stackable": false, "trigger_type": "on_first_utility", "effect_type": "refund_energy", "effect_value": 0})
	_create_artifact({"id": "fortified_walls", "name": "Fortified Walls", "desc": "Control barriers: +1 use", "icon": "wall", "rarity": 1, "cost": 45, "stackable": true, "stat_modifiers": {"barrier_uses_bonus": 1}})
	_create_artifact({"id": "pain_conduit", "name": "Pain Conduit", "desc": "Volatile self-damage -1", "icon": "lightning", "rarity": 1, "cost": 40, "stackable": true, "stat_modifiers": {"self_damage_reduction": 1}})
	_create_artifact({"id": "hunters_instinct", "name": "Hunter's Instinct", "desc": "On kill: heal 1 HP", "icon": "bow", "rarity": 1, "cost": 45, "stackable": true, "trigger_type": "on_kill", "effect_type": "heal", "effect_value": 1})
	_create_artifact({"id": "bounty_hunter", "name": "Bounty Hunter", "desc": "On kill: +1 scrap", "icon": "bag", "rarity": 1, "cost": 40, "stackable": true, "trigger_type": "on_kill", "effect_type": "bonus_scrap", "effect_value": 1})
	_create_artifact({"id": "rapid_loader", "name": "Rapid Loader", "desc": "+1 draw per turn", "icon": "scroll", "rarity": 1, "cost": 60, "stackable": false, "stat_modifiers": {"draw_per_turn": 1}})
	_create_artifact({"id": "power_cell", "name": "Power Cell", "desc": "+1 energy per turn", "icon": "battery", "rarity": 1, "cost": 65, "stackable": false, "stat_modifiers": {"energy_per_turn": 1}})
	_create_artifact({"id": "far_sight", "name": "Far Sight", "desc": "Damage to Far/Mid +15%", "icon": "telescope", "rarity": 1, "cost": 45, "stackable": true, "trigger_type": "on_far_mid_attack", "effect_type": "bonus_damage_percent", "effect_value": 15.0})
	_create_artifact({"id": "close_quarters", "name": "Close Quarters", "desc": "Damage to Melee/Close +15%", "icon": "fist", "rarity": 1, "cost": 45, "stackable": true, "trigger_type": "on_melee_close_attack", "effect_type": "bonus_damage_percent", "effect_value": 15.0})
	_create_artifact({"id": "thick_skin", "name": "Thick Skin", "desc": "Damage reduction +1", "icon": "rhino", "rarity": 1, "cost": 50, "stackable": true, "stat_modifiers": {"self_damage_reduction": 1}})
	_create_artifact({"id": "combo_training", "name": "Combo Training", "desc": "+2 damage per card played", "icon": "mask", "rarity": 1, "cost": 55, "stackable": true, "trigger_type": "on_card_play", "effect_type": "cards_played_damage_bonus", "effect_value": 2})


func _create_rare_artifacts() -> void:
	_create_artifact({"id": "burning_hex", "name": "Burning Hex", "desc": "Hex consumed: apply 2 Burn", "icon": "hex_fire", "rarity": 2, "cost": 80, "stackable": false, "trigger_type": "on_hex_consume", "effect_type": "apply_burn", "effect_value": 2})
	_create_artifact({"id": "crit_shockwave", "name": "Crit Shockwave", "desc": "Crits push target 1 ring", "icon": "wave", "rarity": 2, "cost": 75, "stackable": false, "trigger_type": "on_crit", "effect_type": "push_enemy", "effect_value": 1})
	_create_artifact({"id": "armor_to_arms", "name": "Armor to Arms", "desc": "Gain armor: deal 1 to random enemy", "icon": "sword_shield", "rarity": 2, "cost": 70, "stackable": true, "trigger_type": "on_armor_gain", "effect_type": "deal_damage_random", "effect_value": 1})
	_create_artifact({"id": "pain_reflection", "name": "Pain Reflection", "desc": "Take damage: deal 2 to random enemy", "icon": "mirror", "rarity": 2, "cost": 85, "stackable": true, "trigger_type": "on_player_damage", "effect_type": "deal_damage_random", "effect_value": 2})
	_create_artifact({"id": "draw_power", "name": "Draw Power", "desc": "Draw card: +1 damage this turn (max +5)", "icon": "book", "rarity": 2, "cost": 75, "stackable": false, "trigger_type": "on_draw", "effect_type": "temp_damage_bonus", "effect_value": 1})
	_create_artifact({"id": "hex_detonator", "name": "Hex Detonator", "desc": "Enemy 5+ Hex dies: Hex dmg to ring", "icon": "explosion", "rarity": 2, "cost": 90, "stackable": false, "trigger_type": "on_hex_kill", "effect_type": "hex_explosion", "effect_value": 5})
	_create_artifact({"id": "executioner", "name": "Executioner", "desc": "+50% damage to enemies below 25% HP", "icon": "axe", "rarity": 2, "cost": 80, "stackable": false, "trigger_type": "on_attack_low_hp", "effect_type": "execute_bonus", "effect_value": 50.0})
	_create_artifact({"id": "overkill", "name": "Overkill", "desc": "Excess kill damage hits random enemy", "icon": "blast", "rarity": 2, "cost": 85, "stackable": false, "trigger_type": "on_kill", "effect_type": "overkill_damage", "effect_value": 0})
	_create_artifact({"id": "combo_finisher", "name": "Combo Finisher", "desc": "5th+ card each turn: +3 damage", "icon": "target", "rarity": 2, "cost": 70, "stackable": true, "trigger_type": "on_5th_card", "effect_type": "bonus_damage", "effect_value": 3})
	_create_artifact({"id": "barrier_master", "name": "Barrier Master", "desc": "Barriers deal double damage", "icon": "barrier", "rarity": 2, "cost": 90, "stackable": false, "stat_modifiers": {"barrier_damage_bonus": 100}})
	_create_artifact({"id": "critical_mass", "name": "Critical Mass", "desc": "After 3 crits/turn: next crit +100%", "icon": "radiation", "rarity": 2, "cost": 85, "stackable": false, "trigger_type": "on_3rd_crit", "effect_type": "mega_crit", "effect_value": 100.0})
	_create_artifact({"id": "survivor", "name": "Survivor", "desc": "Below 25% HP: +30% all damage", "icon": "muscle", "rarity": 2, "cost": 75, "stackable": false, "trigger_type": "on_low_hp", "effect_type": "low_hp_damage_bonus", "effect_value": 30.0})


func _create_legendary_artifacts() -> void:
	_create_artifact({"id": "infinity_engine", "name": "Infinity Engine", "desc": "Cards that kill refund 1 energy", "icon": "infinity", "rarity": 3, "cost": 120, "stackable": false, "trigger_type": "on_kill", "effect_type": "refund_energy", "effect_value": 1})
	_create_artifact({"id": "blood_pact", "name": "Blood Pact", "desc": "All damage heals 15%. Max HP -20", "icon": "blood", "rarity": 3, "cost": 100, "stackable": false, "stat_modifiers": {"lifesteal_percent": 15.0, "max_hp": -20}})
	_create_artifact({"id": "glass_cannon", "name": "Glass Cannon", "desc": "All damage +50%. Max HP = 25", "icon": "cannon", "rarity": 3, "cost": 90, "stackable": false, "stat_modifiers": {"damage_percent": 50.0}, "on_acquire": "set_max_hp_25"})
	_create_artifact({"id": "bullet_time", "name": "Bullet Time", "desc": "First card each turn hits twice", "icon": "clock", "rarity": 3, "cost": 130, "stackable": false, "trigger_type": "on_first_card", "effect_type": "double_hit", "effect_value": 2})
	_create_artifact({"id": "chaos_core", "name": "Chaos Core", "desc": "All cards +10% crit. Crits deal 1 to you", "icon": "spiral", "rarity": 3, "cost": 110, "stackable": false, "stat_modifiers": {"crit_chance": 10.0}, "trigger_type": "on_crit", "effect_type": "self_damage", "effect_value": 1})
	_create_artifact({"id": "immortal_shell", "name": "Immortal Shell", "desc": "Once/wave: survive lethal at 1 HP, +10 armor", "icon": "shell", "rarity": 3, "cost": 140, "stackable": false, "trigger_type": "on_lethal", "effect_type": "cheat_death", "effect_value": 10})


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
	"""Get unique equipped artifacts with their counts (for UI display)."""
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
