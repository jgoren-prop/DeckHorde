extends Resource
class_name WaveDefinition
## WaveDefinition - Data resource for wave definitions

const BattlefieldStateScript = preload("res://scripts/combat/BattlefieldState.gd")

@export var wave_number: int = 1
@export var wave_name: String = ""
@export_multiline var description: String = ""

# Wave parameters
@export var turn_limit: int = 5
@export var is_elite_wave: bool = false
@export var is_boss_wave: bool = false

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
	"""Create a basic wave definition based on wave number."""
	var wave: WaveDefinition = WaveDefinition.new()
	wave.wave_number = wave_num
	wave.wave_name = "Wave " + str(wave_num)
	
	# Scale turn limit with wave (integer division is intentional)
	@warning_ignore("integer_division")
	wave.turn_limit = 4 + wave_num / 4
	
	# Determine wave type
	if wave_num == 12:
		wave.is_boss_wave = true
		wave.wave_name = "Final Wave"
	elif wave_num in [4, 8]:
		wave.is_elite_wave = true
		wave.wave_name = "Elite Wave " + str(wave_num)
	
	# Scale multipliers
	wave.hp_multiplier = 1.0 + (wave_num - 1) * 0.15
	wave.damage_multiplier = 1.0 + (wave_num - 1) * 0.1
	
	# Generate spawns based on wave number
	wave.initial_spawns = _generate_initial_spawns(wave_num, wave.is_elite_wave, wave.is_boss_wave)
	wave.phase_spawns = _generate_phase_spawns(wave_num, wave.is_elite_wave, wave.is_boss_wave)
	
	return wave


static func _generate_initial_spawns(wave_num: int, is_elite: bool, is_boss: bool) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	
	if is_boss:
		# Boss wave
		spawns.append({"enemy_id": "ember_saint", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
		spawns.append({"enemy_id": "husk", "count": 3, "ring": BattlefieldStateScript.Ring.FAR})
	elif is_elite:
		# Elite wave
		spawns.append({"enemy_id": "channeler", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
		@warning_ignore("integer_division")
		spawns.append({"enemy_id": "husk", "count": 3 + wave_num / 2, "ring": BattlefieldStateScript.Ring.FAR})
		spawns.append({"enemy_id": "spitter", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
	else:
		# Normal wave - scale enemy count with wave
		var husk_count: int = 3 + wave_num
		var spitter_count: int = max(0, wave_num - 2)
		
		spawns.append({"enemy_id": "husk", "count": husk_count, "ring": BattlefieldStateScript.Ring.FAR})
		
		if spitter_count > 0:
			spawns.append({"enemy_id": "spitter", "count": spitter_count, "ring": BattlefieldStateScript.Ring.FAR})
		
		# Add variety in later waves
		if wave_num >= 3:
			@warning_ignore("integer_division")
			spawns.append({"enemy_id": "spinecrawler", "count": wave_num / 3, "ring": BattlefieldStateScript.Ring.FAR})
		
		if wave_num >= 5:
			spawns.append({"enemy_id": "shell_titan", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
	
	return spawns


static func _generate_phase_spawns(wave_num: int, is_elite: bool, is_boss: bool) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	
	if is_boss:
		# Boss spawns pilgrims (bombers) each phase
		spawns.append({"enemy_id": "bomber", "count": 1, "ring": BattlefieldStateScript.Ring.FAR})
	elif is_elite:
		# Elite spawns husks
		spawns.append({"enemy_id": "husk", "count": 2, "ring": BattlefieldStateScript.Ring.FAR})
	else:
		# Normal waves get reinforcements in later waves
		if wave_num >= 4:
			@warning_ignore("integer_division")
			spawns.append({"enemy_id": "husk", "count": 1 + wave_num / 4, "ring": BattlefieldStateScript.Ring.FAR})
	
	return spawns
