extends Resource
class_name WaveDefinition
## WaveDefinition - V2 Wave Generation with Wave Bands
## Waves 1-3: Onboarding, Waves 4-6: Build Check, Waves 7-9: Stress, Waves 10-12: Boss

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")

@export var wave_number: int = 1
@export var wave_name: String = ""
@export_multiline var description: String = ""

# Wave parameters
@export var turn_limit: int = 5
@export var is_elite_wave: bool = false
@export var is_boss_wave: bool = false
@export var is_theme_wave: bool = false  # V2: Special theme waves
@export var theme_type: String = ""  # V2: "bomber_storm", "ranged_wall", "tank_corridor"

# Scaling multipliers
@export var hp_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0

# Initial enemy spawns at wave start
# Array of {enemy_id: String, count: int, ring: int}
@export var initial_spawns: Array[Dictionary] = []

# Per-phase spawns (happen each enemy phase)
# Array of {enemy_id: String, count: int, ring: int, start_turn: int, end_turn: int}
@export var phase_spawns: Array[Dictionary] = []

# Special events during the wave
# Array of {turn: int, event_type: String, params: Dictionary}
@export var wave_events: Array[Dictionary] = []

# Reward scaling
@export var scrap_bonus: int = 0
@export var card_rarity_bonus: int = 0


static func create_basic_wave(wave_num: int) -> WaveDefinition:
	"""Create a V2 wave definition based on wave bands."""
	var wave: WaveDefinition = WaveDefinition.new()
	wave.wave_number = wave_num
	wave.wave_name = "Wave " + str(wave_num)
	
	# Scale turn limit with wave
	@warning_ignore("integer_division")
	wave.turn_limit = 4 + wave_num / 4
	
	# Scale multipliers
	wave.hp_multiplier = 1.0 + (wave_num - 1) * 0.12  # V2: slightly reduced scaling
	wave.damage_multiplier = 1.0 + (wave_num - 1) * 0.08
	
	# Determine wave band and generate spawns
	if wave_num >= 10:
		# Band 4: Boss & Pre-Boss (waves 10-12)
		_generate_band4_wave(wave, wave_num)
	elif wave_num >= 7:
		# Band 3: Stress Mix (waves 7-9)
		_generate_band3_wave(wave, wave_num)
	elif wave_num >= 4:
		# Band 2: Build Check (waves 4-6)
		_generate_band2_wave(wave, wave_num)
	else:
		# Band 1: Onboarding (waves 1-3)
		_generate_band1_wave(wave, wave_num)
	
	return wave


# ============================================================
# BAND 1: ONBOARDING & EARLY COMMIT (Waves 1-3)
# Goals: Teach ring movement, allow shops to push into a family
# Enemies: Husks, Cultists, occasional Spitter/Bomber by wave 3
# ============================================================
static func _generate_band1_wave(wave: WaveDefinition, wave_num: int) -> void:
	wave.wave_name = "Wave " + str(wave_num) + " - Onboarding"
	wave.initial_spawns = []
	wave.phase_spawns = []
	
	match wave_num:
		1:
			# Wave 1: Pure husks, learn the basics
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
		2:
			# Wave 2: Husks + cultists (swarm)
			wave.initial_spawns.append({"enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "cultist", "count": 4, "ring": BattlefieldStateScript.Ring.MID})
		3:
			# Wave 3: First Spitter (ranged), possible Bomber
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "spitter", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			# 50% chance for an early Bomber
			if randf() < 0.5:
				wave.initial_spawns.append({"enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.MID})


# ============================================================
# BAND 2: BUILD CHECK 1 (Waves 4-6)
# Goals: Check that builds are coming online
# Enemies: Spinecrawlers (fast), more Spitters, first Torchbearer/Channeler
# ============================================================
static func _generate_band2_wave(wave: WaveDefinition, wave_num: int) -> void:
	wave.wave_name = "Wave " + str(wave_num) + " - Build Check"
	wave.initial_spawns = []
	wave.phase_spawns = []
	
	match wave_num:
		4:
			# Wave 4: First Spinecrawlers - tests Gun Board
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
		5:
			# Wave 5: First Torchbearer (buffer) - priority target
			wave.is_elite_wave = true
			wave.wave_name = "Wave 5 - First Elite"
			wave.initial_spawns.append({"enemy_id": "husk", "count": 5, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "spinecrawler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
		6:
			# Wave 6: First Channeler (spawner) - tests sustained damage
			wave.is_elite_wave = true
			wave.wave_name = "Wave 6 - Spawner Test"
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.MID})


# ============================================================
# BAND 3: STRESS MIX & COUNTER-WAVES (Waves 7-9)
# Goals: Each build has good and bad matchups, require tactical play
# Enemies: Tanks, Bombers, Buffers, Spawners, Ambushers, Armor Reavers
# Theme waves: Bomber storm, Ranged wall, Tank corridor
# ============================================================
static func _generate_band3_wave(wave: WaveDefinition, wave_num: int) -> void:
	wave.initial_spawns = []
	wave.phase_spawns = []
	
	match wave_num:
		7:
			# Wave 7: BOMBER STORM theme
			# Great for Barrier/Volatile, scary for Glass builds
			wave.is_theme_wave = true
			wave.theme_type = "bomber_storm"
			wave.wave_name = "Wave 7 - Bomber Storm"
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 3, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "cultist", "count": 4, "ring": BattlefieldStateScript.Ring.CLOSE})
			# Phase spawns: more bombers
			wave.phase_spawns.append({"enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.MID})
		8:
			# Wave 8: RANGED WALL theme
			# Counters pure barrier builds, rewards snipers
			wave.is_theme_wave = true
			wave.theme_type = "ranged_wall"
			wave.wave_name = "Wave 8 - Ranged Wall"
			wave.initial_spawns.append({"enemy_id": "spitter", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "stalker", "count": 1, "ring": BattlefieldStateScript.Ring.CLOSE})
			wave.initial_spawns.append({"enemy_id": "armor_reaver", "count": 1, "ring": BattlefieldStateScript.Ring.MID})
		9:
			# Wave 9: TANK CORRIDOR theme
			# Tests Hex and Barrier scaling, high HP sponges
			wave.is_theme_wave = true
			wave.theme_type = "tank_corridor"
			wave.wave_name = "Wave 9 - Tank Corridor"
			wave.initial_spawns.append({"enemy_id": "shell_titan", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})


# ============================================================
# BAND 4: BOSS & PRE-BOSS (Waves 10-12)
# Goals: Show off build patterns, climactic fights
# Enemies: Concentrated archetypes, final boss
# ============================================================
static func _generate_band4_wave(wave: WaveDefinition, wave_num: int) -> void:
	wave.initial_spawns = []
	wave.phase_spawns = []
	
	match wave_num:
		10:
			# Wave 10: Pre-boss - Ambush Assault
			wave.is_elite_wave = true
			wave.wave_name = "Wave 10 - Ambush Assault"
			wave.initial_spawns.append({"enemy_id": "stalker", "count": 2, "ring": BattlefieldStateScript.Ring.CLOSE})
			wave.initial_spawns.append({"enemy_id": "spinecrawler", "count": 3, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "armor_reaver", "count": 1, "ring": BattlefieldStateScript.Ring.MID})
		11:
			# Wave 11: Pre-boss - Last Stand (armor shredders + mixed)
			wave.is_elite_wave = true
			wave.wave_name = "Wave 11 - Last Stand"
			wave.initial_spawns.append({"enemy_id": "armor_reaver", "count": 2, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.MID})
		12:
			# Wave 12: EMBER SAINT BOSS
			wave.is_boss_wave = true
			wave.wave_name = "Final Wave - Ember Saint"
			wave.initial_spawns.append({"enemy_id": "ember_saint", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			# Boss phase spawns: alternating Bomber + Husk (per V2 spec)
			wave.phase_spawns.append({"enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.phase_spawns.append({"enemy_id": "husk", "count": 1, "ring": BattlefieldStateScript.Ring.MID})


# ============================================================
# HELPER: Get wave band for a wave number
# ============================================================
static func get_wave_band(wave_num: int) -> int:
	"""Returns 1-4 based on which band the wave is in."""
	if wave_num >= 10:
		return 4
	elif wave_num >= 7:
		return 3
	elif wave_num >= 4:
		return 2
	else:
		return 1


static func get_wave_band_name(wave_num: int) -> String:
	"""Returns descriptive name for the wave band."""
	match get_wave_band(wave_num):
		1:
			return "Onboarding"
		2:
			return "Build Check"
		3:
			return "Stress Test"
		4:
			return "Boss Phase"
		_:
			return "Unknown"
