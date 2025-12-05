extends Resource
class_name WaveDefinition
## WaveDefinition - V5 Wave System with Turn-Based Spawns
## 20 waves total with specific spawn timings per DESIGN_V5.md
## Spawn format: {turn: int, enemy_id: String, count: int, ring: int, lane: int (optional)}

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")

@export var wave_number: int = 1
@export var wave_name: String = ""
@export_multiline var description: String = ""

# Wave parameters
@export var turn_limit: int = 6
@export var is_elite_wave: bool = false
@export var is_boss_wave: bool = false
@export var is_horde_wave: bool = false  # V5: Special horde waves with many enemies

# Scaling multipliers
@export var hp_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0

# V5 Turn-based spawns: Array of {turn: int, enemy_id: String, count: int, ring: int, lane: int (optional)}
# Spawns are grouped by turn number
@export var turn_spawns: Array[Dictionary] = []

# Legacy support (converted to turn_spawns internally)
@export var initial_spawns: Array[Dictionary] = []
@export var phase_spawns: Array[Dictionary] = []

# Reward scaling
@export var scrap_bonus: int = 0


static func create_wave(wave_num: int) -> WaveDefinition:
	"""Create a V5 wave definition with turn-based spawns."""
	var wave: WaveDefinition = WaveDefinition.new()
	wave.wave_number = wave_num
	wave.wave_name = "Wave " + str(wave_num)
	wave.turn_limit = 6
	
	# Scale multipliers
	wave.hp_multiplier = 1.0 + (wave_num - 1) * 0.15
	wave.damage_multiplier = 1.0 + (wave_num - 1) * 0.10
	
	# Generate V5 wave composition
	match wave_num:
		1: _generate_wave_1(wave)
		2: _generate_wave_2(wave)
		3: _generate_wave_3(wave)
		4: _generate_wave_4(wave)
		5: _generate_wave_5(wave)
		6: _generate_wave_6(wave)
		7: _generate_wave_7(wave)
		8: _generate_wave_8(wave)
		9: _generate_wave_9(wave)
		10: _generate_wave_10(wave)
		11: _generate_wave_11(wave)
		12: _generate_wave_12(wave)
		13: _generate_wave_13(wave)
		14: _generate_wave_14(wave)
		15: _generate_wave_15(wave)
		16: _generate_wave_16(wave)
		17: _generate_wave_17(wave)
		18: _generate_wave_18(wave)
		19: _generate_wave_19(wave)
		20: _generate_wave_20(wave)
		_:
			# Fallback for waves beyond 20
			_generate_wave_20(wave)
			wave.wave_name = "Endless Wave " + str(wave_num)
	
	return wave


# Legacy function for backward compatibility
static func create_basic_wave(wave_num: int) -> WaveDefinition:
	return create_wave(wave_num)


func get_spawns_for_turn(turn: int) -> Array[Dictionary]:
	"""Get all spawns that should happen on a specific turn."""
	var result: Array[Dictionary] = []
	for spawn: Dictionary in turn_spawns:
		if spawn.get("turn", 1) == turn:
			result.append(spawn)
	return result


func get_total_enemy_count() -> int:
	"""Get total enemies that will spawn in this wave."""
	var total: int = 0
	for spawn: Dictionary in turn_spawns:
		total += spawn.get("count", 1)
	return total


# =============================================================================
# V5 WAVE DEFINITIONS - Per DESIGN_V5.md
# =============================================================================

static func _generate_wave_1(wave: WaveDefinition) -> void:
	"""Wave 1 - Tutorial: 3× Weakling"""
	wave.wave_name = "Wave 1 - Tutorial"
	wave.description = "Your first battle. Learn the basics!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "weakling", "count": 3, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_2(wave: WaveDefinition) -> void:
	"""Wave 2 - Introduction: Weaklings + Cultists"""
	wave.wave_name = "Wave 2 - Introduction"
	wave.description = "Enemies attack from multiple angles."
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "weakling", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "weakling", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "cultist", "count": 2, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_3(wave: WaveDefinition) -> void:
	"""Wave 3 - First Real Wave: Husks arrive"""
	wave.wave_name = "Wave 3 - First Real Wave"
	wave.description = "Husks are tougher. Stay focused!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_4(wave: WaveDefinition) -> void:
	"""Wave 4 - Speed Pressure: Spinecrawlers introduced"""
	wave.wave_name = "Wave 4 - Speed Pressure"
	wave.description = "Spinecrawlers move fast! Kill them quick!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "spinecrawler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "spinecrawler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_5(wave: WaveDefinition) -> void:
	"""Wave 5 - Ranged Introduction: Spitters stay at distance"""
	wave.wave_name = "Wave 5 - Ranged Introduction"
	wave.description = "Spitters attack from Mid ring. Close the gap!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_6(wave: WaveDefinition) -> void:
	"""Wave 6 - Pincer: Enemies from all sides"""
	wave.wave_name = "Wave 6 - Pincer"
	wave.description = "Surrounded! Manage multiple threats."
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "spitter", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "spitter", "count": 1, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_7(wave: WaveDefinition) -> void:
	"""Wave 7 - Bomber Introduction: Explode on death!"""
	wave.wave_name = "Wave 7 - Bomber Introduction"
	wave.description = "Bombers explode! Kill them at range."
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_8(wave: WaveDefinition) -> void:
	"""Wave 8 - Buffer Introduction: Torchbearer buffs allies"""
	wave.wave_name = "Wave 8 - Buffer Introduction"
	wave.is_elite_wave = true
	wave.description = "Torchbearer gives +2 damage to nearby enemies!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "spinecrawler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "spinecrawler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_9(wave: WaveDefinition) -> void:
	"""Wave 9 - Stress Test: Multiple threats at once"""
	wave.wave_name = "Wave 9 - Stress Test"
	wave.is_elite_wave = true
	wave.description = "Everything at once. Prioritize targets!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_10(wave: WaveDefinition) -> void:
	"""Wave 10 - Spawner Introduction (HORDE): Channeler spawns Cultists"""
	wave.wave_name = "Wave 10 - Spawner Introduction"
	wave.is_elite_wave = true
	wave.is_horde_wave = true
	wave.description = "HORDE! Channeler spawns Cultists each turn!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_11(wave: WaveDefinition) -> void:
	"""Wave 11 - Tank Introduction: Shell Titan has armor"""
	wave.wave_name = "Wave 11 - Tank Introduction"
	wave.is_elite_wave = true
	wave.description = "Shell Titan has 5 ARMOR. Multi-hit weapons strip it!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "spitter", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "spitter", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_12(wave: WaveDefinition) -> void:
	"""Wave 12 - Ambush Wave: Stalkers spawn in Close!"""
	wave.wave_name = "Wave 12 - Ambush Wave"
	wave.is_elite_wave = true
	wave.description = "Stalkers spawn in CLOSE ring! Immediate threat!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "stalker", "count": 1, "ring": BattlefieldStateScript.Ring.CLOSE},
		{"turn": 2, "enemy_id": "stalker", "count": 1, "ring": BattlefieldStateScript.Ring.CLOSE},
		{"turn": 4, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_13(wave: WaveDefinition) -> void:
	"""Wave 13 - Elite Mix: Multiple elite types"""
	wave.wave_name = "Wave 13 - Elite Mix"
	wave.is_elite_wave = true
	wave.description = "Multiple elites. Kill support enemies first!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_14(wave: WaveDefinition) -> void:
	"""Wave 14 - Fortress Breaker: Armor Reavers shred your armor"""
	wave.wave_name = "Wave 14 - Fortress Breaker"
	wave.is_elite_wave = true
	wave.description = "Armor Reavers shred YOUR armor! Heal or kill fast!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "armor_reaver", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_15(wave: WaveDefinition) -> void:
	"""Wave 15 - Heavy Assault: Double Shell Titans"""
	wave.wave_name = "Wave 15 - Heavy Assault"
	wave.is_elite_wave = true
	wave.description = "Two Shell Titans! Need sustained damage."
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_16(wave: WaveDefinition) -> void:
	"""Wave 16 - Cultist Horde (HORDE): Mass of weak enemies"""
	wave.wave_name = "Wave 16 - Cultist Horde"
	wave.is_horde_wave = true
	wave.description = "HORDE! Overwhelming numbers! AOE shines here."
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "cultist", "count": 4, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "cultist", "count": 4, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "cultist", "count": 4, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_17(wave: WaveDefinition) -> void:
	"""Wave 17 - Double Tank: Two buffed Shell Titans"""
	wave.wave_name = "Wave 17 - Double Tank"
	wave.is_elite_wave = true
	wave.description = "Titans with support. Disable the Torchbearer!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "armor_reaver", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "stalker", "count": 2, "ring": BattlefieldStateScript.Ring.CLOSE}
	]


static func _generate_wave_18(wave: WaveDefinition) -> void:
	"""Wave 18 - Gauntlet (HORDE): Everything thrown at you"""
	wave.wave_name = "Wave 18 - Gauntlet"
	wave.is_elite_wave = true
	wave.is_horde_wave = true
	wave.description = "GAUNTLET! Survive the onslaught!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 4, "enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "stalker", "count": 2, "ring": BattlefieldStateScript.Ring.CLOSE}
	]


static func _generate_wave_19(wave: WaveDefinition) -> void:
	"""Wave 19 - Pre-Boss: Final test before the boss"""
	wave.wave_name = "Wave 19 - Pre-Boss"
	wave.is_elite_wave = true
	wave.description = "The calm before the storm. Final preparations!"
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 2, "enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "armor_reaver", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "armor_reaver", "count": 1, "ring": BattlefieldStateScript.Ring.FAR}
	]


static func _generate_wave_20(wave: WaveDefinition) -> void:
	"""Wave 20 - BOSS: Ember Saint - Final battle!"""
	wave.wave_name = "Wave 20 - BOSS: Ember Saint"
	wave.is_boss_wave = true
	wave.description = "FINAL BOSS! Ember Saint spawns Bombers. Survive!"
	wave.turn_limit = 8  # Longer boss fight
	wave.turn_spawns = [
		{"turn": 1, "enemy_id": "ember_saint", "count": 1, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 1, "enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 3, "enemy_id": "cultist", "count": 4, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR},
		{"turn": 5, "enemy_id": "stalker", "count": 1, "ring": BattlefieldStateScript.Ring.CLOSE}
	]


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_wave_band(wave_num: int) -> int:
	"""Returns 1-6 based on which band the wave is in."""
	if wave_num >= 17:
		return 6  # Boss Rush
	elif wave_num >= 13:
		return 5  # Endgame
	elif wave_num >= 10:
		return 4  # Late Game
	elif wave_num >= 7:
		return 3  # Stress Test
	elif wave_num >= 4:
		return 2  # Build Check
	else:
		return 1  # Onboarding


static func get_wave_band_name(wave_num: int) -> String:
	"""Returns descriptive name for the wave band."""
	match get_wave_band(wave_num):
		1: return "Onboarding"
		2: return "Build Check"
		3: return "Stress Test"
		4: return "Late Game"
		5: return "Endgame"
		6: return "Boss Rush"
		_: return "Unknown"
