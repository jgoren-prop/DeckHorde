extends RefCounted
class_name CardData
## CardData - Modular card definitions for easy redesign
## V6 Horde Slaughter: ~35 Weapons + ~15 Instants = ~50 total cards
##
## SYNERGY PHILOSOPHY (Brotato-style):
## - Pure archetypes: 1 category (quintessential expression of that playstyle)
## - Thematic/mechanical hybrids: 2 categories (enables build crossover)
## - Single-category cards may have slightly better base stats


# =============================================================================
# KINETIC WEAPONS (10) - Raw damage, armor shred via multi-hit
# =============================================================================

const KINETIC_WEAPONS: Array[Dictionary] = [
	# Pistol - PURE ARCHETYPE: The basic gun, starter weapon
	{
		"id": "pistol", "name": "Pistol",
		"cost": 1, "base": 2, "hits": 2, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Kinetic"],  # Pure - starter, quintessential gun
		"scaling": {"kinetic": 80},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": ""
	},
	# SMG - Utility hybrid: volume fire = consistency tool
	{
		"id": "smg", "name": "SMG",
		"cost": 1, "base": 1, "hits": 4, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Kinetic", "Utility"],  # Hybrid - reliable spray
		"scaling": {"kinetic": 50},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "",
		"flags": ["can_repeat_target"]
	},
	# Assault Rifle - PURE ARCHETYPE: reliable standard kinetic
	{
		"id": "assault_rifle", "name": "Assault Rifle",
		"cost": 2, "base": 2, "hits": 3, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Kinetic"],  # Pure - quintessential assault weapon
		"scaling": {"kinetic": 70},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": ""
	},
	# Minigun - Utility hybrid: armor shredder = utility tool
	{
		"id": "minigun", "name": "Minigun",
		"cost": 3, "base": 1, "hits": 8, "rarity": 2,
		"damage_type": "kinetic",
		"categories": ["Kinetic", "Utility"],  # Hybrid - armor shredding tool
		"scaling": {"kinetic": 40},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Armor shredder",
		"flags": ["can_repeat_target"]
	},
	# Shotgun - Volatile hybrid: aggressive close-range burst
	{
		"id": "shotgun", "name": "Shotgun",
		"cost": 2, "base": 2, "hits": 3, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Kinetic", "Volatile"],  # Hybrid - high aggression
		"scaling": {"kinetic": 60},
		"crit_chance": 8.0, "crit_damage": 160.0,
		"effect": "+2 splash",
		"splash": 2
	},
	# Sniper - Utility hybrid: precision tool
	{
		"id": "sniper", "name": "Sniper Rifle",
		"cost": 2, "base": 6, "hits": 1, "rarity": 2,
		"damage_type": "kinetic",
		"categories": ["Kinetic", "Utility"],  # Hybrid - precision instrument
		"scaling": {"kinetic": 120},
		"crit_chance": 20.0, "crit_damage": 200.0,
		"effect": "High crit chance"
	},
	# Burst Fire - PURE ARCHETYPE: clean burst damage
	{
		"id": "burst_fire", "name": "Burst Fire",
		"cost": 1, "base": 2, "hits": 3, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Kinetic"],  # Pure - simple burst
		"scaling": {"kinetic": 60},
		"crit_chance": 8.0, "crit_damage": 160.0,
		"effect": ""
	},
	# Heavy Rifle - Volatile hybrid: high damage = aggressive
	{
		"id": "heavy_rifle", "name": "Heavy Rifle",
		"cost": 2, "base": 4, "hits": 2, "rarity": 2,
		"damage_type": "kinetic",
		"categories": ["Kinetic", "Volatile"],  # Hybrid - heavy hitting
		"scaling": {"kinetic": 100},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": ""
	},
	# Railgun - Arcane hybrid: armor-ignoring = quasi-magical penetration
	{
		"id": "railgun", "name": "Railgun",
		"cost": 3, "base": 10, "hits": 1, "rarity": 3,
		"damage_type": "kinetic",
		"categories": ["Kinetic", "Arcane"],  # Hybrid - penetrating magic-tech
		"scaling": {"kinetic": 150},
		"crit_chance": 10.0, "crit_damage": 175.0,
		"effect": "Ignores armor",
		"flags": ["ignore_armor"]
	},
	# Machine Pistol - Utility hybrid: budget multi-hit tool
	{
		"id": "machine_pistol", "name": "Machine Pistol",
		"cost": 1, "base": 1, "hits": 5, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Kinetic", "Utility"],  # Hybrid - budget utility
		"scaling": {"kinetic": 40},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "",
		"flags": ["can_repeat_target"]
	},
]


# =============================================================================
# THERMAL WEAPONS (7) - Burn, AOE, ring damage
# =============================================================================

const THERMAL_WEAPONS: Array[Dictionary] = [
	# Flamethrower - Kinetic hybrid: continuous spray like guns
	{
		"id": "flamethrower", "name": "Flamethrower",
		"cost": 2, "base": 2, "hits": 3, "rarity": 1,
		"damage_type": "thermal",
		"categories": ["Thermal", "Kinetic"],  # Hybrid - spray weapon
		"scaling": {"thermal": 70},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Apply 2 Burn",
		"burn": 2,
		"flags": ["can_repeat_target"]
	},
	# Firebomb - PURE ARCHETYPE: quintessential fire AOE
	{
		"id": "firebomb", "name": "Firebomb",
		"cost": 2, "base": 3, "hits": 1, "rarity": 1,
		"damage_type": "thermal",
		"categories": ["Thermal"],  # Pure - basic fire AOE
		"scaling": {"thermal": 80},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Lane. Apply 3 Burn each",
		"burn": 3,
		"target_mode": "ring"
	},
	# Rocket - Volatile hybrid: explosive = high risk/reward
	{
		"id": "rocket", "name": "Rocket Launcher",
		"cost": 3, "base": 5, "hits": 1, "rarity": 2,
		"damage_type": "thermal",
		"categories": ["Thermal", "Volatile"],  # Hybrid - explosive danger
		"scaling": {"thermal": 100},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "+4 splash to group",
		"splash": 4,
		"effect_type": "splash_damage"
	},
	# Napalm - Arcane hybrid: mass destruction = dark power
	{
		"id": "napalm", "name": "Napalm Strike",
		"cost": 3, "base": 2, "hits": 1, "rarity": 2,
		"damage_type": "thermal",
		"categories": ["Thermal", "Arcane"],  # Hybrid - mass destruction
		"scaling": {"thermal": 60},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "ALL enemies. Apply 2 Burn",
		"burn": 2,
		"target_mode": "all"
	},
	# Incendiary - Kinetic hybrid: fire ammo for guns
	{
		"id": "incendiary", "name": "Incendiary Rounds",
		"cost": 2, "base": 2, "hits": 2, "rarity": 1,
		"damage_type": "thermal",
		"categories": ["Thermal", "Kinetic"],  # Hybrid - fire bullets
		"scaling": {"thermal": 70},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Apply 4 Burn",
		"burn": 4
	},
	# Molotov - PURE ARCHETYPE: cheap simple fire
	{
		"id": "molotov", "name": "Molotov",
		"cost": 1, "base": 2, "hits": 1, "rarity": 1,
		"damage_type": "thermal",
		"categories": ["Thermal"],  # Pure - simple fire
		"scaling": {"thermal": 50},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Lane. Apply 2 Burn each",
		"burn": 2,
		"target_mode": "ring"
	},
	# Inferno - Arcane hybrid: overwhelming destruction
	{
		"id": "inferno", "name": "Inferno",
		"cost": 3, "base": 4, "hits": 1, "rarity": 2,
		"damage_type": "thermal",
		"categories": ["Thermal", "Arcane"],  # Hybrid - cataclysmic
		"scaling": {"thermal": 90},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "ALL enemies",
		"target_mode": "all"
	},
]


# =============================================================================
# ARCANE WEAPONS (8) - Hex, execute, lifesteal
# =============================================================================

const ARCANE_WEAPONS: Array[Dictionary] = [
	# Hex Bolt - PURE ARCHETYPE: quintessential hex applicator
	{
		"id": "hex_bolt", "name": "Hex Bolt",
		"cost": 1, "base": 2, "hits": 2, "rarity": 1,
		"damage_type": "arcane",
		"categories": ["Arcane"],  # Pure - basic hex
		"scaling": {"arcane": 70},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Apply 3 Hex",
		"hex": 3
	},
	# Curse - Volatile hybrid: dark curse = dangerous magic
	{
		"id": "curse", "name": "Curse",
		"cost": 2, "base": 2, "hits": 3, "rarity": 2,
		"damage_type": "arcane",
		"categories": ["Arcane", "Volatile"],  # Hybrid - risky dark magic
		"scaling": {"arcane": 80},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Apply 4 Hex",
		"hex": 4
	},
	# Soul Drain - Volatile hybrid: life-stealing dark magic
	{
		"id": "soul_drain", "name": "Soul Drain",
		"cost": 2, "base": 3, "hits": 2, "rarity": 2,
		"damage_type": "arcane",
		"categories": ["Arcane", "Volatile"],  # Hybrid - risky lifesteal
		"scaling": {"arcane": 90},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Heal 3",
		"heal": 3
	},
	# Void Strike - PURE ARCHETYPE: quintessential execute
	{
		"id": "void_strike", "name": "Void Strike",
		"cost": 2, "base": 4, "hits": 1, "rarity": 2,
		"damage_type": "arcane",
		"categories": ["Arcane"],  # Pure - clean execute
		"scaling": {"arcane": 100},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Apply Execute 4 HP",
		"execute_threshold": 4
	},
	# Mind Shatter - Kinetic hybrid: mental assault with physical impact
	{
		"id": "mind_shatter", "name": "Mind Shatter",
		"cost": 2, "base": 2, "hits": 4, "rarity": 2,
		"damage_type": "arcane",
		"categories": ["Arcane", "Kinetic"],  # Hybrid - psychic bullets
		"scaling": {"arcane": 60},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": ""
	},
	# Arcane Barrage - Kinetic hybrid: magic multi-hit bullets
	{
		"id": "arcane_barrage", "name": "Arcane Barrage",
		"cost": 3, "base": 2, "hits": 5, "rarity": 2,
		"damage_type": "arcane",
		"categories": ["Arcane", "Kinetic"],  # Hybrid - magic spray
		"scaling": {"arcane": 50},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": ""
	},
	# Death Mark - Volatile hybrid: mass execute = dangerous
	{
		"id": "death_mark", "name": "Death Mark",
		"cost": 2, "base": 2, "hits": 3, "rarity": 2,
		"damage_type": "arcane",
		"categories": ["Arcane", "Volatile"],  # Hybrid - risky mass execute
		"scaling": {"arcane": 70},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Apply Execute 3 HP each",
		"execute_threshold": 3
	},
	# Life Siphon - PURE ARCHETYPE: simple healing magic
	{
		"id": "life_siphon", "name": "Life Siphon",
		"cost": 1, "base": 2, "hits": 2, "rarity": 1,
		"damage_type": "arcane",
		"categories": ["Arcane"],  # Pure - basic lifesteal
		"scaling": {"arcane": 60},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Heal 2",
		"heal": 2
	},
]


# =============================================================================
# VOLATILE WEAPONS (5) - High risk/reward, self-damage
# =============================================================================

const VOLATILE_WEAPONS: Array[Dictionary] = [
	# Blood Cannon - Thermal hybrid: self-damage fire
	{
		"id": "blood_cannon", "name": "Blood Cannon",
		"cost": 2, "base": 3, "hits": 4, "rarity": 2,
		"damage_type": "thermal",
		"categories": ["Volatile", "Thermal"],  # Hybrid - fire + risk
		"scaling": {"thermal": 80, "missing_hp": 20},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Take 3 damage",
		"self_damage": 3,
		"flags": ["can_repeat_target"]
	},
	# Pain Spike - Kinetic hybrid: aggressive physical
	{
		"id": "pain_spike", "name": "Pain Spike",
		"cost": 2, "base": 4, "hits": 3, "rarity": 2,
		"damage_type": "kinetic",
		"categories": ["Volatile", "Kinetic"],  # Hybrid - aggressive kinetic
		"scaling": {"kinetic": 90, "missing_hp": 25},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": ""
	},
	# Chaos Bolt - Arcane hybrid: chaotic magic
	{
		"id": "chaos_bolt", "name": "Chaos Bolt",
		"cost": 2, "base": 2, "hits": 6, "rarity": 2,
		"damage_type": "arcane",
		"categories": ["Volatile", "Arcane"],  # Hybrid - chaotic magic
		"scaling": {"arcane": 60, "missing_hp": 15},
		"crit_chance": 10.0, "crit_damage": 175.0,
		"effect": "Random targets"
	},
	# Berserker Strike - PURE ARCHETYPE: quintessential rage
	{
		"id": "berserker", "name": "Berserker Strike",
		"cost": 2, "base": 3, "hits": 3, "rarity": 2,
		"damage_type": "kinetic",
		"categories": ["Volatile"],  # Pure - pure rage archetype
		"scaling": {"kinetic": 50, "missing_hp": 50},
		"crit_chance": 15.0, "crit_damage": 175.0,
		"effect": "+1 dmg per 5 missing HP"
	},
	# Overcharge - Thermal hybrid: overclocked fire
	{
		"id": "overcharge", "name": "Overcharge",
		"cost": 1, "base": 2, "hits": 5, "rarity": 2,
		"damage_type": "thermal",
		"categories": ["Volatile", "Thermal"],  # Hybrid - fire + risk
		"scaling": {"thermal": 70, "missing_hp": 20},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Take 4 damage",
		"self_damage": 4,
		"flags": ["can_repeat_target"]
	},
]


# =============================================================================
# UTILITY WEAPONS (5) - Draw, energy, support, precision
# =============================================================================

const UTILITY_WEAPONS: Array[Dictionary] = [
	# Quick Shot - PURE ARCHETYPE: quintessential cantrip
	{
		"id": "quick_shot", "name": "Quick Shot",
		"cost": 0, "base": 1, "hits": 2, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Utility"],  # Pure - simple cantrip
		"scaling": {"kinetic": 40, "cards_played": 1},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Draw 1",
		"draw": 1
	},
	# Scanner - Arcane hybrid: tech/magic targeting
	{
		"id": "scanner", "name": "Scanner",
		"cost": 1, "base": 2, "hits": 2, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Utility", "Arcane"],  # Hybrid - scanning = magic-tech
		"scaling": {"kinetic": 50},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "Next weapon +2 damage",
		"next_weapon_bonus": 2
	},
	# Rapid Fire - Kinetic hybrid: multi-hit tool
	{
		"id": "rapid_fire", "name": "Rapid Fire",
		"cost": 1, "base": 1, "hits": 4, "rarity": 1,
		"damage_type": "kinetic",
		"categories": ["Utility", "Kinetic"],  # Hybrid - consistent kinetic
		"scaling": {"kinetic": 40},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "",
		"flags": ["can_repeat_target"]
	},
	# Precision Strike - PURE ARCHETYPE: quintessential precision
	{
		"id": "precision", "name": "Precision Strike",
		"cost": 2, "base": 4, "hits": 1, "rarity": 2,
		"damage_type": "kinetic",
		"categories": ["Utility"],  # Pure - pure precision
		"scaling": {"kinetic": 80},
		"crit_chance": 100.0, "crit_damage": 200.0,
		"effect": "Always crits"
	},
	# Energy Siphon - Arcane hybrid: energy drain = magic
	{
		"id": "energy_siphon", "name": "Energy Siphon",
		"cost": 1, "base": 2, "hits": 2, "rarity": 2,
		"damage_type": "arcane",
		"categories": ["Utility", "Arcane"],  # Hybrid - energy magic
		"scaling": {"arcane": 50},
		"crit_chance": 5.0, "crit_damage": 150.0,
		"effect": "+1 Energy",
		"grant_energy": 1
	},
]


# =============================================================================
# INSTANT CARDS (15) - Support, buffs, status effects
# =============================================================================

const INSTANT_CARDS: Array[Dictionary] = [
	# === DAMAGE SUPPORT (5) ===
	{
		"id": "amplify", "name": "Amplify",
		"cost": 1, "rarity": 1,
		"categories": ["Kinetic", "Utility"],  # Hybrid - damage + support
		"effect_type": "lane_buff",
		"desc": "+3 damage to all weapons this turn",
		"buff_type": "all_weapons_bonus", "buff_value": 3
	},
	{
		"id": "focus_fire", "name": "Focus Fire",
		"cost": 1, "rarity": 2,
		"categories": ["Kinetic"],  # Pure kinetic focus
		"effect_type": "buff",
		"desc": "Next weapon +3 hits",
		"buff_type": "extra_hits", "buff_value": 3
	},
	{
		"id": "execute_order", "name": "Execute Order",
		"cost": 2, "rarity": 2,
		"categories": ["Arcane", "Volatile"],  # Hybrid - execute + danger
		"effect_type": "apply_execute",
		"desc": "Apply Execute 5 HP to 3 enemies",
		"execute_threshold": 5, "target_count": 3
	},
	{
		"id": "ripple_charge", "name": "Ripple Charge",
		"cost": 1, "rarity": 2,
		"categories": ["Volatile", "Thermal"],  # Hybrid - explosive chain
		"effect_type": "buff",
		"desc": "Next kill: 3 damage to group",
		"buff_type": "ripple_on_kill", "buff_value": 3
	},
	{
		"id": "shred_armor", "name": "Shred Armor",
		"cost": 1, "rarity": 1,
		"categories": ["Kinetic"],  # Pure kinetic utility
		"effect_type": "buff",
		"desc": "All enemies -3 armor",
		"buff_type": "shred_armor", "buff_value": 3
	},
	
	# === DEFENSE (4) ===
	{
		"id": "barrier", "name": "Barrier",
		"cost": 2, "rarity": 1,
		"categories": ["Utility"],  # Pure defensive utility
		"effect_type": "ring_barrier",
		"desc": "Place barrier (3 dmg, 2 uses)",
		"barrier_damage": 3, "barrier_uses": 2,
		"requires_target": true
	},
	{
		"id": "armor_up", "name": "Armor Up",
		"cost": 1, "rarity": 1,
		"categories": ["Utility"],  # Pure utility
		"effect_type": "gain_armor",
		"desc": "Gain 5 armor",
		"armor": 5
	},
	{
		"id": "heal", "name": "Heal",
		"cost": 1, "rarity": 1,
		"categories": ["Arcane", "Utility"],  # Hybrid - magic healing
		"effect_type": "heal",
		"desc": "Restore 8 HP",
		"heal": 8
	},
	{
		"id": "shield_wall", "name": "Shield Wall",
		"cost": 2, "rarity": 2,
		"categories": ["Utility", "Kinetic"],  # Hybrid - defense + draw
		"effect_type": "gain_armor",
		"desc": "Gain 3 armor. Draw 1",
		"armor": 3, "draw": 1
	},
	
	# === ECONOMY/TEMPO (3) ===
	{
		"id": "reload", "name": "Reload",
		"cost": 1, "rarity": 1,
		"categories": ["Utility"],  # Pure utility
		"effect_type": "draw_cards",
		"desc": "Draw 3",
		"draw": 3
	},
	{
		"id": "surge", "name": "Surge",
		"cost": 0, "rarity": 1,
		"categories": ["Utility", "Volatile"],  # Hybrid - tempo burst
		"effect_type": "buff",
		"desc": "+2 Energy this turn",
		"buff_type": "energy", "buff_value": 2
	},
	{
		"id": "scavenge", "name": "Scavenge",
		"cost": 1, "rarity": 2,
		"categories": ["Utility"],  # Pure utility
		"effect_type": "buff",
		"desc": "Gain 8 scrap",
		"buff_type": "scrap", "buff_value": 8
	},
	
	# === STATUS (3) ===
	{
		"id": "mass_hex", "name": "Mass Hex",
		"cost": 2, "rarity": 2,
		"categories": ["Arcane"],  # Pure arcane
		"effect_type": "apply_hex_multi",
		"desc": "Apply 3 Hex to ALL enemies",
		"hex": 3, "target_mode": "all"
	},
	{
		"id": "ignite", "name": "Ignite",
		"cost": 1, "rarity": 1,
		"categories": ["Thermal"],  # Pure thermal
		"effect_type": "apply_burn",
		"desc": "Apply 4 Burn to a lane",
		"burn": 4, "requires_target": true
	},
	{
		"id": "weaken", "name": "Weaken",
		"cost": 1, "rarity": 1,
		"categories": ["Arcane", "Volatile"],  # Hybrid - curse + danger
		"effect_type": "buff",
		"desc": "Enemies in lane take +2 damage",
		"buff_type": "ring_vulnerability", "buff_value": 2,
		"requires_target": true
	},
]


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_all_weapons() -> Array[Dictionary]:
	"""Get all weapon data arrays combined."""
	var all: Array[Dictionary] = []
	all.append_array(KINETIC_WEAPONS)
	all.append_array(THERMAL_WEAPONS)
	all.append_array(ARCANE_WEAPONS)
	all.append_array(VOLATILE_WEAPONS)
	all.append_array(UTILITY_WEAPONS)
	return all


static func get_all_instants() -> Array[Dictionary]:
	"""Get all instant card data."""
	var result: Array[Dictionary] = []
	result.append_array(INSTANT_CARDS)
	return result


static func get_all_cards() -> Array[Dictionary]:
	"""Get all card data combined."""
	var all: Array[Dictionary] = []
	all.append_array(get_all_weapons())
	all.append_array(get_all_instants())
	return all


static func get_category_summary() -> Dictionary:
	"""Get a summary of how many cards are in each category."""
	var summary: Dictionary = {}
	for card: Dictionary in get_all_cards():
		var categories: Array = card.get("categories", [])
		for cat: String in categories:
			if not summary.has(cat):
				summary[cat] = {"total": 0, "pure": 0, "hybrid": 0}
			summary[cat].total += 1
			if categories.size() == 1:
				summary[cat].pure += 1
			else:
				summary[cat].hybrid += 1
	return summary

