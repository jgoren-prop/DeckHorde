extends Resource
class_name WaveDefinition
## WaveDefinition - Brotato Economy Wave Generation with Wave Bands
## 20 waves total:
## Waves 1-3: Onboarding (trivially easy start)
## Waves 4-6: Build Check, Waves 7-9: Stress Mix
## Waves 10-12: Late Game, Waves 13-16: Endgame, Waves 17-20: Boss Rush

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
	
	# Determine wave band and generate spawns (Brotato Economy: 20 waves)
	if wave_num >= 17:
		# Band 6: Boss Rush (waves 17-20)
		_generate_band6_wave(wave, wave_num)
	elif wave_num >= 13:
		# Band 5: Endgame (waves 13-16)
		_generate_band5_wave(wave, wave_num)
	elif wave_num >= 10:
		# Band 4: Late Game (waves 10-12)
		_generate_band4_wave(wave, wave_num)
	elif wave_num >= 7:
		# Band 3: Stress Mix (waves 7-9)
		_generate_band3_wave(wave, wave_num)
	elif wave_num >= 4:
		# Band 2: Build Check (waves 4-6)
		_generate_band2_wave(wave, wave_num)
	else:
		# Band 1: Onboarding (waves 1-3) - trivially easy
		_generate_band1_wave(wave, wave_num)
	
	return wave


# ============================================================
# BAND 1: ONBOARDING (Waves 1-3)
# Brotato Economy: Wave 1 is TRIVIALLY EASY - just survive and collect
# Goals: Learn your starter weapon, collect scrap for first shop visit
# ============================================================
static func _generate_band1_wave(wave: WaveDefinition, wave_num: int) -> void:
	wave.wave_name = "Wave " + str(wave_num) + " - Onboarding"
	wave.initial_spawns = []
	wave.phase_spawns = []
	
	match wave_num:
		1:
			# Wave 1: Brotato Economy - TRIVIALLY EASY
			# Just 2-3 Weaklings - any starter weapon can clear them
			wave.wave_name = "Wave 1 - Tutorial"
			wave.initial_spawns.append({"enemy_id": "weakling", "count": 3, "ring": BattlefieldStateScript.Ring.FAR})
		2:
			# Wave 2: Still easy - Weaklings + a few Cultists
			wave.initial_spawns.append({"enemy_id": "weakling", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.MID})
		3:
			# Wave 3: Transition - First real enemies
			wave.initial_spawns.append({"enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "cultist", "count": 3, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "weakling", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})


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
# BAND 4: LATE GAME (Waves 10-12)
# Goals: Build should be strong now, test synergies
# Enemies: Mixed elites, heavier pressure
# ============================================================
static func _generate_band4_wave(wave: WaveDefinition, wave_num: int) -> void:
	wave.initial_spawns = []
	wave.phase_spawns = []
	
	match wave_num:
		10:
			# Wave 10: Ambush Assault
			wave.is_elite_wave = true
			wave.wave_name = "Wave 10 - Ambush Assault"
			wave.initial_spawns.append({"enemy_id": "stalker", "count": 2, "ring": BattlefieldStateScript.Ring.CLOSE})
			wave.initial_spawns.append({"enemy_id": "spinecrawler", "count": 3, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "armor_reaver", "count": 1, "ring": BattlefieldStateScript.Ring.MID})
		11:
			# Wave 11: Mixed Elite
			wave.is_elite_wave = true
			wave.wave_name = "Wave 11 - Elite Mix"
			wave.initial_spawns.append({"enemy_id": "armor_reaver", "count": 2, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.MID})
		12:
			# Wave 12: Heavy Horde
			wave.is_elite_wave = true
			wave.wave_name = "Wave 12 - Heavy Horde"
			wave.initial_spawns.append({"enemy_id": "shell_titan", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 5, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})


# ============================================================
# BAND 5: ENDGAME (Waves 13-16)
# Goals: Build is complete, survive the onslaught
# Enemies: Heavy elites, themed waves, intense pressure
# ============================================================
static func _generate_band5_wave(wave: WaveDefinition, wave_num: int) -> void:
	wave.initial_spawns = []
	wave.phase_spawns = []
	
	match wave_num:
		13:
			# Wave 13: Shredder Rush
			wave.is_elite_wave = true
			wave.wave_name = "Wave 13 - Shredder Rush"
			wave.initial_spawns.append({"enemy_id": "armor_reaver", "count": 3, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "spinecrawler", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "stalker", "count": 2, "ring": BattlefieldStateScript.Ring.CLOSE})
		14:
			# Wave 14: Double Buffer
			wave.is_elite_wave = true
			wave.wave_name = "Wave 14 - Double Buffer"
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 6, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.MID})
		15:
			# Wave 15: Tank Line
			wave.is_elite_wave = true
			wave.wave_name = "Wave 15 - Tank Line"
			wave.initial_spawns.append({"enemy_id": "shell_titan", "count": 3, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.MID})
		16:
			# Wave 16: All-Out Assault
			wave.is_elite_wave = true
			wave.wave_name = "Wave 16 - All-Out"
			wave.initial_spawns.append({"enemy_id": "stalker", "count": 3, "ring": BattlefieldStateScript.Ring.CLOSE})
			wave.initial_spawns.append({"enemy_id": "shell_titan", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 3, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "channeler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})


# ============================================================
# BAND 6: BOSS RUSH (Waves 17-20)
# Goals: Final stretch, culminating in boss
# Enemies: Everything thrown at you, boss wave at 20
# ============================================================
static func _generate_band6_wave(wave: WaveDefinition, wave_num: int) -> void:
	wave.initial_spawns = []
	wave.phase_spawns = []
	
	match wave_num:
		17:
			# Wave 17: Pre-Boss 1
			wave.is_elite_wave = true
			wave.wave_name = "Wave 17 - Gauntlet I"
			wave.initial_spawns.append({"enemy_id": "armor_reaver", "count": 2, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "shell_titan", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "spinecrawler", "count": 4, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.MID})
		18:
			# Wave 18: Pre-Boss 2
			wave.is_elite_wave = true
			wave.wave_name = "Wave 18 - Gauntlet II"
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "channeler", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "stalker", "count": 3, "ring": BattlefieldStateScript.Ring.CLOSE})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 5, "ring": BattlefieldStateScript.Ring.FAR})
		19:
			# Wave 19: Pre-Boss 3 - Last Stand
			wave.is_elite_wave = true
			wave.wave_name = "Wave 19 - Last Stand"
			wave.initial_spawns.append({"enemy_id": "shell_titan", "count": 3, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "armor_reaver", "count": 3, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 4, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
		20:
			# Wave 20: EMBER SAINT BOSS
			wave.is_boss_wave = true
			wave.wave_name = "Final Wave - Ember Saint"
			wave.initial_spawns.append({"enemy_id": "ember_saint", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "husk", "count": 4, "ring": BattlefieldStateScript.Ring.MID})
			wave.initial_spawns.append({"enemy_id": "bomber", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
			wave.initial_spawns.append({"enemy_id": "torchbearer", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			# Boss phase spawns: alternating Bomber + Husk
			wave.phase_spawns.append({"enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
			wave.phase_spawns.append({"enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.MID})


# ============================================================
# HELPER: Get wave band for a wave number (Brotato Economy: 6 bands)
# ============================================================
static func get_wave_band(wave_num: int) -> int:
	"""Returns 1-6 based on which band the wave is in."""
	if wave_num >= 17:
		return 6
	elif wave_num >= 13:
		return 5
	elif wave_num >= 10:
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
			return "Late Game"
		5:
			return "Endgame"
		6:
			return "Boss Rush"
		_:
			return "Unknown"
