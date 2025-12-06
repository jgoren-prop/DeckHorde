extends RefCounted
class_name ArtifactData
## ArtifactData - Modular artifact definitions for easy redesign
## V6 Horde Slaughter: 10 Common, 10 Uncommon, 6 Rare, 4 Legendary = 30 total
##
## ARTIFACT PHILOSOPHY:
## - Common: Simple stat bonuses, stackable foundation
## - Uncommon: Synergy enablers, build direction
## - Rare: Powerful effects, build amplifiers
## - Legendary: Run-defining, game-changing


# =============================================================================
# COMMON ARTIFACTS (10) - Stackable stat bonuses
# =============================================================================

const COMMON_ARTIFACTS: Array[Dictionary] = [
	# Damage Type Bonuses (3)
	{
		"id": "kinetic_rounds", "name": "Kinetic Rounds",
		"desc": "+3 Kinetic damage", "icon": "bullet",
		"rarity": 0, "cost": 25, "stackable": true,
		"stat_modifiers": {"kinetic": 3}
	},
	{
		"id": "thermal_core", "name": "Thermal Core",
		"desc": "+3 Thermal damage", "icon": "fire",
		"rarity": 0, "cost": 25, "stackable": true,
		"stat_modifiers": {"thermal": 3}
	},
	{
		"id": "arcane_focus", "name": "Arcane Focus",
		"desc": "+3 Arcane damage", "icon": "crystal",
		"rarity": 0, "cost": 25, "stackable": true,
		"stat_modifiers": {"arcane": 3}
	},
	
	# Crit Bonuses (2)
	{
		"id": "lucky_coin", "name": "Lucky Coin",
		"desc": "+5% Crit chance", "icon": "coin",
		"rarity": 0, "cost": 30, "stackable": true,
		"stat_modifiers": {"crit_chance": 5.0}
	},
	{
		"id": "heavy_hitter", "name": "Heavy Hitter",
		"desc": "+20% Crit damage", "icon": "skull",
		"rarity": 0, "cost": 30, "stackable": true,
		"stat_modifiers": {"crit_damage": 20.0}
	},
	
	# Multi-Hit Bonus (1) - Core horde mechanic
	{
		"id": "extra_rounds", "name": "Extra Rounds",
		"desc": "+1 hit to all weapons", "icon": "ammo",
		"rarity": 0, "cost": 35, "stackable": true,
		"stat_modifiers": {"bonus_hits": 1}
	},
	
	# Defensive (2)
	{
		"id": "iron_skin", "name": "Iron Skin",
		"desc": "+10 Max HP", "icon": "heart",
		"rarity": 0, "cost": 25, "stackable": true,
		"stat_modifiers": {"max_hp": 10}
	},
	{
		"id": "steel_plate", "name": "Steel Plate",
		"desc": "+3 Armor at wave start", "icon": "shield",
		"rarity": 0, "cost": 25, "stackable": true,
		"stat_modifiers": {"armor_start": 3}
	},
	
	# Utility (2)
	{
		"id": "vampiric_fang", "name": "Vampiric Fang",
		"desc": "+5% Lifesteal", "icon": "fang",
		"rarity": 0, "cost": 35, "stackable": true,
		"stat_modifiers": {"lifesteal_percent": 5.0}
	},
	{
		"id": "aoe_amplifier", "name": "AOE Amplifier",
		"desc": "+15% AOE damage", "icon": "bomb",
		"rarity": 0, "cost": 30, "stackable": true,
		"stat_modifiers": {"aoe_percent": 15.0}
	},
]


# =============================================================================
# UNCOMMON ARTIFACTS (10) - Synergy enablers
# =============================================================================

const UNCOMMON_ARTIFACTS: Array[Dictionary] = [
	# Kill Bonuses (2) - Core horde mechanics
	{
		"id": "hunters_instinct", "name": "Hunter's Instinct",
		"desc": "On kill: heal 2 HP", "icon": "bow",
		"rarity": 1, "cost": 45, "stackable": true,
		"trigger_type": "on_kill", "effect_type": "heal", "effect_value": 2
	},
	{
		"id": "bounty_hunter", "name": "Bounty Hunter",
		"desc": "On kill: +2 scrap", "icon": "bag",
		"rarity": 1, "cost": 45, "stackable": true,
		"trigger_type": "on_kill", "effect_type": "bonus_scrap", "effect_value": 2
	},
	
	# Multi-Hit Synergies (2)
	{
		"id": "rapid_fire_module", "name": "Rapid Fire Module",
		"desc": "Multi-hit weapons +20% damage", "icon": "gears",
		"rarity": 1, "cost": 50, "stackable": true,
		"stat_modifiers": {"multi_hit_damage_percent": 20.0}
	},
	{
		"id": "crit_chain", "name": "Crit Chain",
		"desc": "Crits grant +1 hit this turn", "icon": "chain",
		"rarity": 1, "cost": 55, "stackable": false,
		"trigger_type": "on_crit", "effect_type": "bonus_hit", "effect_value": 1
	},
	
	# Execute Synergy (1)
	{
		"id": "executioner_blade", "name": "Executioner's Blade",
		"desc": "Execute kills: +1 energy", "icon": "axe",
		"rarity": 1, "cost": 50, "stackable": false,
		"trigger_type": "on_execute_kill", "effect_type": "refund_energy", "effect_value": 1
	},
	
	# Status Effect Synergies (2)
	{
		"id": "burn_amplifier", "name": "Burn Amplifier",
		"desc": "Burn damage +50%", "icon": "flame",
		"rarity": 1, "cost": 45, "stackable": true,
		"stat_modifiers": {"burn_potency": 50.0}
	},
	{
		"id": "hex_amplifier", "name": "Hex Amplifier",
		"desc": "Hex damage +50%", "icon": "hex",
		"rarity": 1, "cost": 45, "stackable": true,
		"stat_modifiers": {"hex_potency": 50.0}
	},
	
	# Economy/Tempo (3)
	{
		"id": "rapid_loader", "name": "Rapid Loader",
		"desc": "+1 Draw per turn", "icon": "scroll",
		"rarity": 1, "cost": 60, "stackable": false,
		"stat_modifiers": {"draw_per_turn": 1}
	},
	{
		"id": "power_cell", "name": "Power Cell",
		"desc": "+1 Energy per turn", "icon": "battery",
		"rarity": 1, "cost": 65, "stackable": false,
		"stat_modifiers": {"energy_per_turn": 1}
	},
	{
		"id": "opening_salvo", "name": "Opening Salvo",
		"desc": "First card each turn: +2 hits", "icon": "target",
		"rarity": 1, "cost": 55, "stackable": false,
		"trigger_type": "on_first_card", "effect_type": "bonus_hits", "effect_value": 2
	},
]


# =============================================================================
# RARE ARTIFACTS (6) - Powerful effects
# =============================================================================

const RARE_ARTIFACTS: Array[Dictionary] = [
	# Overkill - Damage chains
	{
		"id": "overkill", "name": "Overkill",
		"desc": "Excess kill damage hits random enemy", "icon": "blast",
		"rarity": 2, "cost": 80, "stackable": false,
		"trigger_type": "on_kill", "effect_type": "overkill_damage", "effect_value": 0
	},
	
	# Death Echo - Mini ripple
	{
		"id": "death_echo", "name": "Death Echo",
		"desc": "Kills deal 2 damage to enemy's group", "icon": "wave",
		"rarity": 2, "cost": 85, "stackable": false,
		"trigger_type": "on_kill", "effect_type": "mini_ripple", "effect_value": 2
	},
	
	# Execute Threshold
	{
		"id": "mercy_killer", "name": "Mercy Killer",
		"desc": "Execute threshold +3 on all enemies", "icon": "reaper",
		"rarity": 2, "cost": 90, "stackable": true,
		"stat_modifiers": {"execute_threshold_bonus": 3}
	},
	
	# Crit + Burn
	{
		"id": "burning_strikes", "name": "Burning Strikes",
		"desc": "Crits apply 2 Burn", "icon": "fire_sword",
		"rarity": 2, "cost": 75, "stackable": false,
		"trigger_type": "on_crit", "effect_type": "apply_burn", "effect_value": 2
	},
	
	# Multi-hit repeat
	{
		"id": "focused_fire", "name": "Focused Fire",
		"desc": "All multi-hit weapons can repeat targets", "icon": "crosshair",
		"rarity": 2, "cost": 70, "stackable": false,
		"stat_modifiers": {"all_repeat_target": 1}
	},
	
	# Glass cannon
	{
		"id": "berserker_rage", "name": "Berserker's Rage",
		"desc": "All damage +25%. Take 1 damage per attack", "icon": "rage",
		"rarity": 2, "cost": 80, "stackable": false,
		"stat_modifiers": {"damage_percent": 25.0},
		"trigger_type": "on_attack", "effect_type": "self_damage", "effect_value": 1
	},
]


# =============================================================================
# LEGENDARY ARTIFACTS (4) - Build definers
# =============================================================================

const LEGENDARY_ARTIFACTS: Array[Dictionary] = [
	# Infinity Engine - Kills refund energy
	{
		"id": "infinity_engine", "name": "Infinity Engine",
		"desc": "Kills refund 1 energy", "icon": "infinity",
		"rarity": 3, "cost": 120, "stackable": false,
		"trigger_type": "on_kill", "effect_type": "refund_energy", "effect_value": 1
	},
	
	# Bullet Storm - +3 hits to all weapons
	{
		"id": "bullet_storm", "name": "Bullet Storm",
		"desc": "All weapons +3 hits", "icon": "storm",
		"rarity": 3, "cost": 130, "stackable": false,
		"stat_modifiers": {"bonus_hits": 3}
	},
	
	# Blood Pact - Heavy lifesteal, reduced HP
	{
		"id": "blood_pact", "name": "Blood Pact",
		"desc": "Lifesteal 20%. Max HP -30", "icon": "blood",
		"rarity": 3, "cost": 100, "stackable": false,
		"stat_modifiers": {"lifesteal_percent": 20.0, "max_hp": -30}
	},
	
	# Chain Reaction - Full ripple on every kill
	{
		"id": "chain_reaction", "name": "Chain Reaction",
		"desc": "Every kill triggers ripple chain", "icon": "explosion",
		"rarity": 3, "cost": 140, "stackable": false,
		"trigger_type": "on_kill", "effect_type": "full_ripple", "effect_value": 0
	},
]


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_all_artifacts() -> Array[Dictionary]:
	"""Get all artifact data combined."""
	var all: Array[Dictionary] = []
	all.append_array(COMMON_ARTIFACTS)
	all.append_array(UNCOMMON_ARTIFACTS)
	all.append_array(RARE_ARTIFACTS)
	all.append_array(LEGENDARY_ARTIFACTS)
	return all


static func get_artifacts_by_rarity(rarity: int) -> Array[Dictionary]:
	"""Get artifacts of a specific rarity (0=Common, 1=Uncommon, 2=Rare, 3=Legendary)."""
	match rarity:
		0: return COMMON_ARTIFACTS.duplicate()
		1: return UNCOMMON_ARTIFACTS.duplicate()
		2: return RARE_ARTIFACTS.duplicate()
		3: return LEGENDARY_ARTIFACTS.duplicate()
		_: return []


static func get_artifact_count() -> Dictionary:
	"""Get count of artifacts by rarity."""
	return {
		"common": COMMON_ARTIFACTS.size(),
		"uncommon": UNCOMMON_ARTIFACTS.size(),
		"rare": RARE_ARTIFACTS.size(),
		"legendary": LEGENDARY_ARTIFACTS.size(),
		"total": COMMON_ARTIFACTS.size() + UNCOMMON_ARTIFACTS.size() + RARE_ARTIFACTS.size() + LEGENDARY_ARTIFACTS.size()
	}

