extends Node
## CardDatabase - V2 Card Pool
## Contains ONLY V2 cards - all V1 cards have been removed per destructive change policy

signal cards_loaded()

var cards: Dictionary = {}  # card_id -> CardDefinition
var cards_by_tag: Dictionary = {}
var cards_by_type: Dictionary = {}
var unlocked_cards: Array = []

const CardDef = preload("res://scripts/resources/CardDefinition.gd")


func _ready() -> void:
	_create_v2_cards()
	print("[CardDatabase] Initialized with ", cards.size(), " V2 cards")


func _create_v2_cards() -> void:
	"""Create the complete V2 card pool - brainstorm.md cards only."""
	_create_brotato_starter_weapons()  # New Brotato-style starter weapons
	_create_v2_starter_cards()
	_create_v2_brainstorm_persistent_cards()
	_create_v2_brainstorm_instant_cards()
	cards_loaded.emit()


# =============================================================================
# BROTATO STARTER WEAPONS (Pick 1 at run start)
# =============================================================================

func _create_brotato_starter_weapons() -> void:
	"""7 starter weapons for Brotato-style economy. All cost 1, all persistent, all weak."""
	
	# Note: Rusty Pistol already exists in _create_v2_starter_cards()
	
	# Worn Hex Staff - hex, persistent - deals damage AND applies hex (INFINITE)
	var worn_hex_staff := CardDef.new()
	worn_hex_staff.card_id = "worn_hex_staff"
	worn_hex_staff.card_name = "Worn Hex Staff"
	worn_hex_staff.description = "Persistent: Deal {damage} damage and apply {hex_damage} Hex to a random enemy at end of turn."
	worn_hex_staff.persistent_description = "Deal {damage} + apply {hex_damage} Hex."
	worn_hex_staff.card_type = "hex"
	worn_hex_staff.effect_type = "weapon_persistent"
	worn_hex_staff.tags = ["hex", "persistent", "hex_ritual"]
	worn_hex_staff.base_cost = 1
	worn_hex_staff.base_damage = 1  # Low damage but triggers hex
	worn_hex_staff.hex_damage = 2   # Hex triggers on the hit
	worn_hex_staff.target_type = "random_enemy"
	worn_hex_staff.target_rings = [0, 1, 2, 3]
	worn_hex_staff.weapon_trigger = "turn_end"
	worn_hex_staff.rarity = 1
	worn_hex_staff.is_starter_weapon = true
	worn_hex_staff.duration_type = "infinite"  # V2: Permanent - core hex build weapon
	_register_card(worn_hex_staff)
	
	# Shock Prod - shock, persistent - targets closest enemy (TIMED: 5 turns)
	var shock_prod := CardDef.new()
	shock_prod.card_id = "shock_prod"
	shock_prod.card_name = "Shock Prod"
	shock_prod.description = "Persistent (5 turns): Deal {damage} shock damage to the closest enemy at end of turn."
	shock_prod.persistent_description = "Deal {damage} shock to closest enemy. (5 turns)"
	shock_prod.card_type = "weapon"
	shock_prod.effect_type = "weapon_persistent"
	shock_prod.tags = ["shock", "persistent", "single_target"]
	shock_prod.base_cost = 1
	shock_prod.base_damage = 3
	shock_prod.target_type = "closest_enemy"
	shock_prod.target_rings = [0, 1, 2, 3]
	shock_prod.weapon_trigger = "turn_end"
	shock_prod.rarity = 1
	shock_prod.is_starter_weapon = true
	shock_prod.duration_type = "turns"  # V2: Timed weapon
	shock_prod.duration_turns = 5
	shock_prod.on_expire = "discard"  # Returns to deck after expiring
	_register_card(shock_prod)
	
	# Leaky Siphon - gun, persistent, lifedrain (INFINITE)
	var leaky_siphon := CardDef.new()
	leaky_siphon.card_id = "leaky_siphon"
	leaky_siphon.card_name = "Leaky Siphon"
	leaky_siphon.description = "Persistent: Deal {damage} damage to random enemy, heal 1 HP at end of turn."
	leaky_siphon.persistent_description = "Deal {damage} damage, heal 1 HP."
	leaky_siphon.card_type = "weapon"
	leaky_siphon.effect_type = "weapon_persistent"
	leaky_siphon.tags = ["gun", "persistent", "lifedrain"]
	leaky_siphon.base_cost = 1
	leaky_siphon.base_damage = 2
	leaky_siphon.heal_amount = 1
	leaky_siphon.target_type = "random_enemy"
	leaky_siphon.target_rings = [0, 1, 2, 3]
	leaky_siphon.weapon_trigger = "turn_end"
	leaky_siphon.rarity = 1
	leaky_siphon.is_starter_weapon = true
	leaky_siphon.duration_type = "infinite"  # V2: Permanent - sustain build core
	_register_card(leaky_siphon)
	
	# Volatile Handgun - gun, persistent, volatile (KILL-BASED: 4 kills then banished)
	var volatile_handgun := CardDef.new()
	volatile_handgun.card_id = "volatile_handgun"
	volatile_handgun.card_name = "Volatile Handgun"
	volatile_handgun.description = "Persistent (4 kills): Deal {damage} damage to random enemy, lose 1 HP at end of turn. Banished after 4 kills."
	volatile_handgun.persistent_description = "Deal {damage} damage, lose 1 HP. (4 kills)"
	volatile_handgun.card_type = "weapon"
	volatile_handgun.effect_type = "weapon_persistent"
	volatile_handgun.tags = ["gun", "persistent", "volatile"]
	volatile_handgun.base_cost = 1
	volatile_handgun.base_damage = 4
	volatile_handgun.self_damage = 1
	volatile_handgun.target_type = "random_enemy"
	volatile_handgun.target_rings = [0, 1, 2, 3]
	volatile_handgun.weapon_trigger = "turn_end"
	volatile_handgun.rarity = 1
	volatile_handgun.is_starter_weapon = true
	volatile_handgun.duration_type = "kills"  # V2: Expires after kills
	volatile_handgun.duration_kills = 4
	volatile_handgun.on_expire = "banish"  # Gone for the wave when it burns out
	_register_card(volatile_handgun)
	
	# Mini Turret - gun, engine, persistent, aoe (INFINITE)
	var mini_turret := CardDef.new()
	mini_turret.card_id = "mini_turret"
	mini_turret.card_name = "Mini Turret"
	mini_turret.description = "Persistent: Deal {damage} damage to 2 random enemies at end of turn."
	mini_turret.persistent_description = "Deal {damage} damage to 2 random enemies."
	mini_turret.card_type = "weapon"
	mini_turret.effect_type = "weapon_persistent"
	mini_turret.tags = ["gun", "engine", "persistent", "aoe"]
	mini_turret.base_cost = 1
	mini_turret.base_damage = 2  # Buffed from 1 - needs to kill 3HP weaklings
	mini_turret.target_count = 2
	mini_turret.target_type = "random_enemy"
	mini_turret.target_rings = [0, 1, 2, 3]
	mini_turret.weapon_trigger = "turn_end"
	mini_turret.rarity = 1
	mini_turret.is_starter_weapon = true
	mini_turret.duration_type = "infinite"  # V2: Permanent - engine build core
	_register_card(mini_turret)
	
	# Spark Coil - AoE close range damage, persistent (BURN_OUT: 3 turns then banished)
	var spark_coil := CardDef.new()
	spark_coil.card_id = "spark_coil"
	spark_coil.card_name = "Spark Coil"
	spark_coil.description = "Persistent (3 turns): Deal {damage} damage to ALL enemies in Close ring at end of turn. Banished after 3 turns."
	spark_coil.persistent_description = "Deal {damage} to all Close enemies. (3 turns)"
	spark_coil.card_type = "weapon"
	spark_coil.effect_type = "weapon_persistent"
	spark_coil.tags = ["shock", "persistent", "aoe", "defensive"]
	spark_coil.base_cost = 1
	spark_coil.base_damage = 3  # Buffed from 2 since it's limited duration
	spark_coil.target_type = "all_in_ring"
	spark_coil.target_rings = [0]  # Close ring only (changed to Melee for more defensive)
	spark_coil.weapon_trigger = "turn_end"
	spark_coil.rarity = 1
	spark_coil.is_starter_weapon = true
	spark_coil.duration_type = "burn_out"  # V2: Strong but burns out
	spark_coil.duration_turns = 3
	spark_coil.on_expire = "banish"  # Gone for the wave
	_register_card(spark_coil)


# =============================================================================
# V2 STARTER CARDS (Veteran Warden deck)
# =============================================================================

func _create_v2_starter_cards() -> void:
	"""V2 Veteran Warden starter deck - weak, flexible cards for build pivots."""
	
	# Rusty Pistol - basic PERSISTENT gun (INFINITE - reliable starter)
	var rusty_pistol := CardDef.new()
	rusty_pistol.card_id = "rusty_pistol"
	rusty_pistol.card_name = "Rusty Pistol"
	rusty_pistol.description = "Persistent: Deal {damage} damage to a random enemy at end of turn."
	rusty_pistol.persistent_description = "Deal {damage} to a random enemy."
	rusty_pistol.card_type = "weapon"
	rusty_pistol.effect_type = "weapon_persistent"
	rusty_pistol.tags = ["gun", "persistent", "single_target"]
	rusty_pistol.base_cost = 1
	rusty_pistol.base_damage = 3  # Slightly weaker than Infernal Pistol (4) - upgrade path!
	rusty_pistol.target_type = "random_enemy"
	rusty_pistol.target_rings = [0, 1, 2, 3]  # ALL rings
	rusty_pistol.weapon_trigger = "turn_end"
	rusty_pistol.rarity = 1
	rusty_pistol.is_starter_weapon = true
	rusty_pistol.duration_type = "infinite"  # V2: Permanent - reliable baseline
	_register_card(rusty_pistol)
	
	# Storm Carbine [Starter] - persistent gun for Close/Mid
	var storm_carbine := CardDef.new()
	storm_carbine.card_id = "storm_carbine"
	storm_carbine.card_name = "Storm Carbine"
	storm_carbine.description = "Persistent: Deal {damage} damage to 2 random enemies in Close/Mid at end of turn."
	storm_carbine.persistent_description = "Deal {damage} to 2 enemies in Close/Mid."
	storm_carbine.card_type = "weapon"
	storm_carbine.effect_type = "weapon_persistent"
	storm_carbine.tags = ["gun", "persistent", "close_focus"]
	storm_carbine.base_cost = 2
	storm_carbine.base_damage = 3
	storm_carbine.target_type = "random_enemy"
	storm_carbine.target_rings = [1, 2]  # Close/Mid
	storm_carbine.target_count = 2
	storm_carbine.weapon_trigger = "turn_end"
	storm_carbine.rarity = 1
	_register_card(storm_carbine)
	
	# Ammo Cache [Starter] - draw + gun cost reduction
	var ammo_cache := CardDef.new()
	ammo_cache.card_id = "ammo_cache"
	ammo_cache.card_name = "Ammo Cache"
	ammo_cache.description = "Draw 2 cards. The next gun card you play this turn costs 1 less."
	ammo_cache.card_type = "skill"
	ammo_cache.effect_type = "draw_and_buff"
	ammo_cache.tags = ["skill", "instant", "engine_core", "gun"]
	ammo_cache.base_cost = 1
	ammo_cache.cards_to_draw = 2
	ammo_cache.buff_type = "cost_reduction"
	ammo_cache.buff_value = 1
	ammo_cache.target_type = "self"
	ammo_cache.rarity = 1
	_register_card(ammo_cache)
	
	# Minor Hex - basic hex to single enemy
	var minor_hex := CardDef.new()
	minor_hex.card_id = "minor_hex"
	minor_hex.card_name = "Minor Hex"
	minor_hex.description = "Apply {hex_damage} Hex to a random enemy."
	minor_hex.card_type = "hex"
	minor_hex.effect_type = "apply_hex"
	minor_hex.tags = ["hex", "instant", "single_target", "hex_ritual"]
	minor_hex.base_cost = 1
	minor_hex.hex_damage = 3
	minor_hex.target_type = "random_enemy"
	minor_hex.target_rings = [0, 1, 2, 3]
	minor_hex.target_count = 1
	minor_hex.rarity = 1
	_register_card(minor_hex)
	
	# Minor Barrier - weak barrier trap
	var minor_barrier := CardDef.new()
	minor_barrier.card_id = "minor_barrier"
	minor_barrier.card_name = "Minor Barrier"
	minor_barrier.description = "Place a barrier in target ring. Deals {damage} damage when crossed (1 use)."
	minor_barrier.card_type = "defense"
	minor_barrier.effect_type = "ring_barrier"
	minor_barrier.tags = ["barrier", "instant", "ring_control", "barrier_trap"]
	minor_barrier.base_cost = 1
	minor_barrier.base_damage = 3
	minor_barrier.duration = 1
	minor_barrier.target_type = "ring"
	minor_barrier.target_rings = [1, 2, 3]
	minor_barrier.requires_target = true
	minor_barrier.rarity = 1
	_register_card(minor_barrier)
	
	# Guard Stance - basic armor
	var guard_stance := CardDef.new()
	guard_stance.card_id = "guard_stance"
	guard_stance.card_name = "Guard Stance"
	guard_stance.description = "Gain {armor} Armor."
	guard_stance.card_type = "defense"
	guard_stance.effect_type = "gain_armor"
	guard_stance.tags = ["defense", "instant", "fortress"]
	guard_stance.base_cost = 1
	guard_stance.armor_amount = 4
	guard_stance.target_type = "self"
	guard_stance.rarity = 1
	_register_card(guard_stance)
	
	# Precision Strike - AoE damage to all enemies in a group/stack
	var precision_strike := CardDef.new()
	precision_strike.card_id = "precision_strike"
	precision_strike.card_name = "Precision Strike"
	precision_strike.description = "Deal {damage} damage to all enemies in a group."
	precision_strike.card_type = "weapon"
	precision_strike.effect_type = "targeted_group_damage"
	precision_strike.tags = ["gun", "instant", "aoe"]
	precision_strike.base_cost = 1
	precision_strike.base_damage = 2
	precision_strike.target_type = "random_enemy"
	precision_strike.target_rings = [0, 1, 2, 3]  # ALL rings
	precision_strike.requires_target = false  # Picks random then hits group
	precision_strike.rarity = 1
	_register_card(precision_strike)
	
	# Shove - push enemy back
	var shove := CardDef.new()
	shove.card_id = "shove"
	shove.card_name = "Shove"
	shove.description = "Push 1 enemy in Melee/Close back 1 ring. If they hit a barrier, deal 2 damage."
	shove.card_type = "skill"
	shove.effect_type = "push_enemies"
	shove.tags = ["skill", "instant", "ring_control", "volatile"]
	shove.base_cost = 1
	shove.push_amount = 1
	shove.base_damage = 2
	shove.target_type = "random_enemy"
	shove.target_rings = [0, 1]
	shove.target_count = 1
	shove.rarity = 1
	_register_card(shove)
	
	# Overclock [Starter] - all guns fire at 75% damage
	var overclock := CardDef.new()
	overclock.card_id = "overclock"
	overclock.card_name = "Overclock"
	overclock.description = "All deployed guns fire immediately for 75% damage. Draw 1 card."
	overclock.card_type = "skill"
	overclock.effect_type = "fire_all_guns"
	overclock.tags = ["skill", "instant", "engine_core"]
	overclock.base_cost = 1
	overclock.effect_params = {"damage_percent": 75.0}
	overclock.cards_to_draw = 1
	overclock.target_type = "self"
	overclock.rarity = 1
	_register_card(overclock)
	
	# Tag Infusion: Piercing [Starter] - add piercing tag to a gun
	var tag_infusion_piercing := CardDef.new()
	tag_infusion_piercing.card_id = "tag_infusion_piercing"
	tag_infusion_piercing.card_name = "Tag Infusion: Piercing"
	tag_infusion_piercing.description = "Add 'piercing' to a deployed gun. Its shots continue through stacks to hit a second enemy (50% overflow)."
	tag_infusion_piercing.card_type = "skill"
	tag_infusion_piercing.effect_type = "tag_infusion"
	tag_infusion_piercing.tags = ["skill", "instant"]
	tag_infusion_piercing.base_cost = 1
	tag_infusion_piercing.effect_params = {"tag": "piercing", "bonus_damage": 0}
	tag_infusion_piercing.target_type = "self"
	tag_infusion_piercing.rarity = 1
	_register_card(tag_infusion_piercing)


# =============================================================================
# V2 BRAINSTORM PERSISTENT CARDS (from brainstorm.md #11-50, persistent only)
# =============================================================================

func _create_v2_brainstorm_persistent_cards() -> void:
	"""V2 Brainstorm persistent guns and engines."""
	
	# #11 Mortar Team - explosive sniper with ammo
	var mortar_team := CardDef.new()
	mortar_team.card_id = "mortar_team"
	mortar_team.card_name = "Mortar Team"
	mortar_team.description = "Persistent: Deal 5 damage to Far, splash 2 to Mid. 3 ammo. Reload 2 scrap: restore 2 ammo."
	mortar_team.persistent_description = "5 damage to Far, splash 2 to Mid."
	mortar_team.card_type = "weapon"
	mortar_team.effect_type = "weapon_persistent"
	mortar_team.tags = ["gun", "persistent", "sniper", "explosive", "ammo"]
	mortar_team.base_cost = 2
	mortar_team.base_damage = 5
	mortar_team.splash_damage = 2
	mortar_team.effect_params = {"ammo": 3, "reload_cost": 2, "reload_amount": 2}
	mortar_team.target_type = "ring"
	mortar_team.target_rings = [3]
	mortar_team.weapon_trigger = "turn_end"
	mortar_team.rarity = 3
	_register_card(mortar_team)
	
	# #12 Arc Conductor - beam engine with charge mechanic
	var arc_conductor := CardDef.new()
	arc_conductor.card_id = "arc_conductor"
	arc_conductor.card_name = "Arc Conductor"
	arc_conductor.description = "Persistent: Gain 1 charge when you play a hex card. End of turn: deal 3 chaining damage to that many enemies (prefers hexed)."
	arc_conductor.persistent_description = "Charges from hex cards, chains damage to enemies."
	arc_conductor.card_type = "weapon"
	arc_conductor.effect_type = "weapon_persistent"
	arc_conductor.tags = ["engine", "persistent", "beam"]
	arc_conductor.base_cost = 2
	arc_conductor.base_damage = 3
	arc_conductor.chain_count = 1
	arc_conductor.effect_params = {"charge_trigger": "hex_play", "damage_per_charge": 3}
	arc_conductor.target_type = "random_enemy"
	arc_conductor.target_rings = [0, 1, 2, 3]
	arc_conductor.weapon_trigger = "turn_end"
	arc_conductor.rarity = 3
	_register_card(arc_conductor)
	
	# #13 Bulwark Drone - fortress engine
	var bulwark_drone := CardDef.new()
	bulwark_drone.card_id = "bulwark_drone"
	bulwark_drone.card_name = "Bulwark Drone"
	bulwark_drone.description = "Persistent: End of turn: grant 2 armor. If you control 3+ barriers, also place a 2-damage, 1-use barrier in Close."
	bulwark_drone.persistent_description = "Grant 2 armor. 3+ barriers: +barrier in Close."
	bulwark_drone.card_type = "defense"
	bulwark_drone.effect_type = "weapon_persistent"
	bulwark_drone.tags = ["engine", "persistent", "fortress"]
	bulwark_drone.base_cost = 2
	bulwark_drone.armor_amount = 2
	bulwark_drone.base_damage = 2
	bulwark_drone.duration = 1
	bulwark_drone.effect_params = {"barrier_threshold": 3, "barrier_ring": 1}
	bulwark_drone.target_type = "self"
	bulwark_drone.weapon_trigger = "turn_end"
	bulwark_drone.rarity = 3
	_register_card(bulwark_drone)
	
	# #14 Pulse Array - shock AoE gun
	var pulse_array := CardDef.new()
	pulse_array.card_id = "pulse_array"
	pulse_array.card_name = "Pulse Array"
	pulse_array.description = "Persistent: Before enemy phase: deal 1 damage to all enemies in a chosen ring. If they moved this turn, apply Slow."
	pulse_array.persistent_description = "1 damage to ring, slow movers."
	pulse_array.card_type = "weapon"
	pulse_array.effect_type = "weapon_persistent"
	pulse_array.tags = ["gun", "persistent", "aoe", "shock"]
	pulse_array.base_cost = 2
	pulse_array.base_damage = 1
	pulse_array.effect_params = {"slow_movers": true}
	pulse_array.target_type = "ring"
	pulse_array.target_rings = [0, 1, 2, 3]
	pulse_array.requires_target = true
	pulse_array.weapon_trigger = "before_enemy_phase"
	pulse_array.rarity = 3
	_register_card(pulse_array)
	
	# #15 Ammo Foundry - volatile gun buff engine
	var ammo_foundry := CardDef.new()
	ammo_foundry.card_id = "ammo_foundry"
	ammo_foundry.card_name = "Ammo Foundry"
	ammo_foundry.description = "Persistent: Every 2 kills: +1 damage to all deployed guns next turn. Then lose 1 HP."
	ammo_foundry.persistent_description = "2 kills: +1 gun damage, -1 HP."
	ammo_foundry.card_type = "skill"
	ammo_foundry.effect_type = "weapon_persistent"
	ammo_foundry.tags = ["engine", "persistent", "volatile"]
	ammo_foundry.base_cost = 1
	ammo_foundry.self_damage = 1
	ammo_foundry.effect_params = {"kills_needed": 2, "damage_buff": 1}
	ammo_foundry.target_type = "self"
	ammo_foundry.weapon_trigger = "on_kill"
	ammo_foundry.rarity = 2
	_register_card(ammo_foundry)
	
	# #16 Scrap Forge - on-kill card generation
	var scrap_forge := CardDef.new()
	scrap_forge.card_id = "scrap_forge"
	scrap_forge.card_name = "Scrap Forge"
	scrap_forge.description = "Persistent: On kill: 20% chance to create a 1-cost 'Shard Shot' (4 damage instant) in next hand."
	scrap_forge.persistent_description = "On kill: 20% chance for Shard Shot."
	scrap_forge.card_type = "skill"
	scrap_forge.effect_type = "weapon_persistent"
	scrap_forge.tags = ["engine", "persistent"]
	scrap_forge.base_cost = 1
	scrap_forge.effect_params = {"spawn_chance": 20, "spawn_card": "shard_shot"}
	scrap_forge.target_type = "self"
	scrap_forge.weapon_trigger = "on_kill"
	scrap_forge.rarity = 2
	_register_card(scrap_forge)
	
	# Shard Shot - generated card from Scrap Forge
	var shard_shot := CardDef.new()
	shard_shot.card_id = "shard_shot"
	shard_shot.card_name = "Shard Shot"
	shard_shot.description = "Deal 4 damage to a random enemy. (Generated by Scrap Forge)"
	shard_shot.card_type = "weapon"
	shard_shot.effect_type = "instant_damage"
	shard_shot.tags = ["gun", "instant"]
	shard_shot.base_cost = 1
	shard_shot.base_damage = 4
	shard_shot.target_type = "random_enemy"
	shard_shot.target_rings = [0, 1, 2, 3]
	shard_shot.rarity = 1
	_register_card(shard_shot)
	
	# #24 Shock Lattice - shock engine
	var shock_lattice := CardDef.new()
	shock_lattice.card_id = "shock_lattice"
	shock_lattice.card_name = "Shock Lattice"
	shock_lattice.description = "Persistent: When you play a ring_control card, deal 1 shock damage to all enemies in that ring; 20% chance to Slow."
	shock_lattice.persistent_description = "Ring control cards shock that ring."
	shock_lattice.card_type = "weapon"
	shock_lattice.effect_type = "weapon_persistent"
	shock_lattice.tags = ["engine", "persistent", "shock"]
	shock_lattice.base_cost = 1
	shock_lattice.base_damage = 1
	shock_lattice.effect_params = {"trigger_tag": "ring_control", "slow_chance": 20}
	shock_lattice.target_type = "ring"
	shock_lattice.target_rings = [0, 1, 2, 3]
	shock_lattice.weapon_trigger = "on_tag_play"
	shock_lattice.rarity = 2
	_register_card(shock_lattice)
	
	# #26 Scatter Mines - explosive barrier engine
	var scatter_mines := CardDef.new()
	scatter_mines.card_id = "scatter_mines"
	scatter_mines.card_name = "Scatter Mines"
	scatter_mines.description = "Place 3 mines across random rings: 3 damage, 2 uses, splash 1 to adjacent ring on trigger."
	scatter_mines.card_type = "defense"
	scatter_mines.effect_type = "ring_barrier"
	scatter_mines.tags = ["barrier", "engine", "persistent", "barrier_trap", "explosive"]
	scatter_mines.base_cost = 2
	scatter_mines.base_damage = 3
	scatter_mines.splash_damage = 1
	scatter_mines.duration = 2
	scatter_mines.effect_params = {"mine_count": 3, "random_rings": true}
	scatter_mines.target_type = "all_rings"
	scatter_mines.rarity = 3
	_register_card(scatter_mines)
	
	# #28 Twin Lances - beam persistent gun
	var twin_lances := CardDef.new()
	twin_lances.card_id = "twin_lances"
	twin_lances.card_name = "Twin Lances"
	twin_lances.description = "Persistent: End of turn: deal 2 damage to 2 enemies. If both in same stack, spread 1 hex."
	twin_lances.persistent_description = "2 damage to 2 enemies, hex if stacked."
	twin_lances.card_type = "weapon"
	twin_lances.effect_type = "weapon_persistent"
	twin_lances.tags = ["gun", "persistent", "beam", "single_target"]
	twin_lances.base_cost = 2
	twin_lances.base_damage = 2
	twin_lances.hex_damage = 1
	twin_lances.target_count = 2
	twin_lances.target_type = "random_enemy"
	twin_lances.target_rings = [0, 1, 2, 3]
	twin_lances.weapon_trigger = "turn_end"
	twin_lances.rarity = 3
	_register_card(twin_lances)
	
	# #29 Volley Rig - shotgun with ammo refund
	var volley_rig := CardDef.new()
	volley_rig.card_id = "volley_rig"
	volley_rig.card_name = "Volley Rig"
	volley_rig.description = "Persistent: End of turn: 1 damage 5 times in Melee/Close. Each kill refunds 1 ammo (max 3, +1 dmg per charge)."
	volley_rig.persistent_description = "5x 1 damage, kills refund ammo."
	volley_rig.card_type = "weapon"
	volley_rig.effect_type = "weapon_persistent"
	volley_rig.tags = ["gun", "persistent", "shotgun", "swarm_clear", "ammo"]
	volley_rig.base_cost = 2
	volley_rig.base_damage = 1
	volley_rig.target_count = 5
	volley_rig.effect_params = {"max_charges": 3, "damage_per_charge": 1, "refund_on_kill": true}
	volley_rig.target_type = "random_enemy"
	volley_rig.target_rings = [0, 1]
	volley_rig.weapon_trigger = "turn_end"
	volley_rig.rarity = 3
	_register_card(volley_rig)
	
	# #32 Hex Lance Turret - hex beam engine
	var hex_lance_turret := CardDef.new()
	hex_lance_turret.card_id = "hex_lance_turret"
	hex_lance_turret.card_name = "Hex Lance Turret"
	hex_lance_turret.description = "Persistent: End of turn: deal 2 damage to a hexed enemy. If it survives, increase its hex by 1."
	hex_lance_turret.persistent_description = "2 damage to hexed, +1 hex if alive."
	hex_lance_turret.card_type = "weapon"
	hex_lance_turret.effect_type = "weapon_persistent"
	hex_lance_turret.tags = ["engine", "persistent", "hex", "beam"]
	hex_lance_turret.base_cost = 2
	hex_lance_turret.base_damage = 2
	hex_lance_turret.hex_damage = 1
	hex_lance_turret.effect_params = {"prefer_hexed": true, "add_hex_on_survive": true}
	hex_lance_turret.target_type = "random_enemy"
	hex_lance_turret.target_rings = [0, 1, 2, 3]
	hex_lance_turret.weapon_trigger = "turn_end"
	hex_lance_turret.rarity = 3
	_register_card(hex_lance_turret)
	
	# #35 Pulse Repeater - engine core
	var pulse_repeater := CardDef.new()
	pulse_repeater.card_id = "pulse_repeater"
	pulse_repeater.card_name = "Pulse Repeater"
	pulse_repeater.description = "Persistent: At turn start, choose: draw 1, or next Overclock costs 0."
	pulse_repeater.persistent_description = "Turn start: draw 1 or free Overclock."
	pulse_repeater.card_type = "skill"
	pulse_repeater.effect_type = "weapon_persistent"
	pulse_repeater.tags = ["engine", "persistent", "engine_core"]
	pulse_repeater.base_cost = 1
	pulse_repeater.cards_to_draw = 1
	pulse_repeater.effect_params = {"choice_mode": true, "free_card": "overclock"}
	pulse_repeater.target_type = "self"
	pulse_repeater.weapon_trigger = "turn_start"
	pulse_repeater.rarity = 2
	_register_card(pulse_repeater)
	
	# #38 Hex Capacitor - hex ritual engine
	var hex_capacitor := CardDef.new()
	hex_capacitor.card_id = "hex_capacitor"
	hex_capacitor.card_name = "Hex Capacitor"
	hex_capacitor.description = "Persistent: When hex is consumed, gain 1 charge (max 3). Spend charge: next gun applies 2 hex."
	hex_capacitor.persistent_description = "Hex consume = charge. Charge = gun hex."
	hex_capacitor.card_type = "skill"
	hex_capacitor.effect_type = "weapon_persistent"
	hex_capacitor.tags = ["engine", "persistent", "hex_ritual"]
	hex_capacitor.base_cost = 1
	hex_capacitor.hex_damage = 2
	hex_capacitor.effect_params = {"max_charges": 3, "charge_on_hex_consume": true}
	hex_capacitor.target_type = "self"
	hex_capacitor.weapon_trigger = "on_hex_consumed"
	hex_capacitor.rarity = 2
	_register_card(hex_capacitor)
	
	# #39 Sentinel Barrier - fortress barrier engine
	var sentinel_barrier := CardDef.new()
	sentinel_barrier.card_id = "sentinel_barrier"
	sentinel_barrier.card_name = "Sentinel Barrier"
	sentinel_barrier.description = "Place barrier with 3 HP, 2 damage. When triggered, your weakest gun gains +1 damage this turn."
	sentinel_barrier.card_type = "defense"
	sentinel_barrier.effect_type = "ring_barrier"
	sentinel_barrier.tags = ["barrier", "engine", "persistent", "fortress"]
	sentinel_barrier.base_cost = 2
	sentinel_barrier.base_damage = 2
	sentinel_barrier.duration = 3
	sentinel_barrier.effect_params = {"buff_weakest_gun": 1}
	sentinel_barrier.target_type = "ring"
	sentinel_barrier.target_rings = [1, 2, 3]
	sentinel_barrier.requires_target = true
	sentinel_barrier.rarity = 3
	_register_card(sentinel_barrier)
	
	# #40 Overwatch Drone - sniper engine
	var overwatch_drone := CardDef.new()
	overwatch_drone.card_id = "overwatch_drone"
	overwatch_drone.card_name = "Overwatch Drone"
	overwatch_drone.description = "Persistent: When you play a skill, deal 2 damage to a Far/Mid enemy. If none, random."
	overwatch_drone.persistent_description = "Skills trigger 2 damage to Far/Mid."
	overwatch_drone.card_type = "weapon"
	overwatch_drone.effect_type = "weapon_persistent"
	overwatch_drone.tags = ["engine", "persistent", "sniper"]
	overwatch_drone.base_cost = 1
	overwatch_drone.base_damage = 2
	overwatch_drone.effect_params = {"trigger_on": "skill_play", "prefer_rings": [2, 3]}
	overwatch_drone.target_type = "random_enemy"
	overwatch_drone.target_rings = [2, 3]
	overwatch_drone.weapon_trigger = "on_skill_play"
	overwatch_drone.rarity = 2
	_register_card(overwatch_drone)
	
	# #47 Inferno Stack - explosive sniper
	var inferno_stack := CardDef.new()
	inferno_stack.card_id = "inferno_stack"
	inferno_stack.card_name = "Inferno Stack"
	inferno_stack.description = "Persistent: End of turn: deal 4 to Far/Mid, splash 2 to adjacent. Each kill adds +1 splash (resets if no kill)."
	inferno_stack.persistent_description = "4 damage Far/Mid, splash grows on kills."
	inferno_stack.card_type = "weapon"
	inferno_stack.effect_type = "weapon_persistent"
	inferno_stack.tags = ["gun", "persistent", "explosive", "sniper"]
	inferno_stack.base_cost = 2
	inferno_stack.base_damage = 4
	inferno_stack.splash_damage = 2
	inferno_stack.effect_params = {"splash_on_kill_bonus": 1, "reset_on_no_kill": true}
	inferno_stack.target_type = "random_enemy"
	inferno_stack.target_rings = [2, 3]
	inferno_stack.weapon_trigger = "turn_end"
	inferno_stack.rarity = 3
	_register_card(inferno_stack)
	
	# #48 Chain Reactor - beam + explosive engine
	var chain_reactor := CardDef.new()
	chain_reactor.card_id = "chain_reactor"
	chain_reactor.card_name = "Chain Reactor"
	chain_reactor.description = "Persistent: First gun each turn: deal 2 beam damage to 2 enemies. If either dies, 2 explosive splash to ring."
	chain_reactor.persistent_description = "First gun: 2 beam to 2. Death = splash."
	chain_reactor.card_type = "weapon"
	chain_reactor.effect_type = "weapon_persistent"
	chain_reactor.tags = ["engine", "persistent", "beam", "explosive"]
	chain_reactor.base_cost = 2
	chain_reactor.base_damage = 2
	chain_reactor.splash_damage = 2
	chain_reactor.chain_count = 2
	chain_reactor.effect_params = {"trigger_on": "first_gun_play", "splash_on_kill": true}
	chain_reactor.target_type = "random_enemy"
	chain_reactor.target_rings = [0, 1, 2, 3]
	chain_reactor.weapon_trigger = "on_gun_play"
	chain_reactor.rarity = 3
	_register_card(chain_reactor)


# =============================================================================
# V2 BRAINSTORM INSTANT CARDS (from brainstorm.md #17-50, instant only)
# =============================================================================

func _create_v2_brainstorm_instant_cards() -> void:
	"""V2 Brainstorm instant spells and skills."""
	
	# #17 Target Sync - ring priority buff
	var target_sync := CardDef.new()
	target_sync.card_id = "target_sync"
	target_sync.card_name = "Target Sync"
	target_sync.description = "Choose a ring. Deployed guns prioritize it this turn and gain +2 damage against it."
	target_sync.card_type = "skill"
	target_sync.effect_type = "target_sync"
	target_sync.tags = ["skill", "instant"]
	target_sync.base_cost = 1
	target_sync.base_damage = 2
	target_sync.target_type = "ring"
	target_sync.target_rings = [0, 1, 2, 3]
	target_sync.requires_target = true
	target_sync.rarity = 2
	_register_card(target_sync)
	
	# #18 Explosive Primer - explosive buff
	var explosive_primer := CardDef.new()
	explosive_primer.card_id = "explosive_primer"
	explosive_primer.card_name = "Explosive Primer"
	explosive_primer.description = "This turn: explosive attacks double splash. Explosive hits restore 1 use to barriers they damage."
	explosive_primer.card_type = "skill"
	explosive_primer.effect_type = "buff"
	explosive_primer.tags = ["skill", "instant", "explosive"]
	explosive_primer.base_cost = 1
	explosive_primer.buff_type = "explosive_buff"
	explosive_primer.buff_value = 2
	explosive_primer.effect_params = {"double_splash": true, "barrier_restore": 1}
	explosive_primer.target_type = "self"
	explosive_primer.rarity = 2
	_register_card(explosive_primer)
	
	# #19 Hex Transfer - move hex between enemies
	var hex_transfer := CardDef.new()
	hex_transfer.card_id = "hex_transfer"
	hex_transfer.card_name = "Hex Transfer"
	hex_transfer.description = "Move all hex from one enemy to another. Your next persistent gun applies 2 hex on hit this turn."
	hex_transfer.card_type = "skill"
	hex_transfer.effect_type = "hex_transfer"
	hex_transfer.tags = ["skill", "instant", "hex_ritual"]
	hex_transfer.base_cost = 1
	hex_transfer.hex_damage = 2
	hex_transfer.effect_params = {"gun_hex_buff": 2}
	hex_transfer.target_type = "random_enemy"
	hex_transfer.target_rings = [0, 1, 2, 3]
	hex_transfer.rarity = 2
	_register_card(hex_transfer)
	
	# #20 Barrier Channel - trigger all barriers
	var barrier_channel := CardDef.new()
	barrier_channel.card_id = "barrier_channel"
	barrier_channel.card_name = "Barrier Channel"
	barrier_channel.description = "Trigger all barriers once without consuming uses. Gain 1 armor per trigger."
	barrier_channel.card_type = "skill"
	barrier_channel.effect_type = "barrier_trigger"
	barrier_channel.tags = ["skill", "instant", "fortress"]
	barrier_channel.base_cost = 1
	barrier_channel.armor_amount = 1
	barrier_channel.effect_params = {"armor_per_trigger": 1}
	barrier_channel.target_type = "self"
	barrier_channel.rarity = 2
	_register_card(barrier_channel)
	
	# #21 Emergency Deploy - play gun from deck
	var emergency_deploy := CardDef.new()
	emergency_deploy.card_id = "emergency_deploy"
	emergency_deploy.card_name = "Emergency Deploy"
	emergency_deploy.description = "Play the top persistent gun from your draw pile at -1 cost. It fires once at 75% damage."
	emergency_deploy.card_type = "skill"
	emergency_deploy.effect_type = "emergency_deploy"
	emergency_deploy.tags = ["skill", "instant", "swarm_clear"]
	emergency_deploy.base_cost = 1
	emergency_deploy.effect_params = {"cost_reduction": 1, "fire_percent": 75}
	emergency_deploy.target_type = "self"
	emergency_deploy.rarity = 2
	_register_card(emergency_deploy)
	
	# #22 Piercing Ammo - this turn buff
	var piercing_ammo := CardDef.new()
	piercing_ammo.card_id = "piercing_ammo"
	piercing_ammo.card_name = "Piercing Ammo"
	piercing_ammo.description = "This turn, guns gain piercing: overkill flows to next enemy (50% overflow)."
	piercing_ammo.card_type = "skill"
	piercing_ammo.effect_type = "buff"
	piercing_ammo.tags = ["skill", "instant", "piercing"]
	piercing_ammo.base_cost = 1
	piercing_ammo.buff_type = "piercing_buff"
	piercing_ammo.effect_params = {"overflow_percent": 50}
	piercing_ammo.target_type = "self"
	piercing_ammo.rarity = 2
	_register_card(piercing_ammo)
	
	# #23 Beam Splitter - beam instant
	var beam_splitter := CardDef.new()
	beam_splitter.card_id = "beam_splitter"
	beam_splitter.card_name = "Beam Splitter"
	beam_splitter.description = "Deal 4 damage chaining to up to 3 enemies in the same ring. Each hit spreads 1 hex if present."
	beam_splitter.card_type = "weapon"
	beam_splitter.effect_type = "beam_damage"
	beam_splitter.tags = ["gun", "instant", "beam", "aoe"]
	beam_splitter.base_cost = 2
	beam_splitter.base_damage = 4
	beam_splitter.chain_count = 3
	beam_splitter.hex_damage = 1
	beam_splitter.effect_params = {"spread_hex": true}
	beam_splitter.target_type = "ring"
	beam_splitter.target_rings = [0, 1, 2, 3]
	beam_splitter.requires_target = true
	beam_splitter.rarity = 3
	_register_card(beam_splitter)
	
	# #25 Corrosive Rounds - corrosive buff
	var corrosive_rounds := CardDef.new()
	corrosive_rounds.card_id = "corrosive_rounds"
	corrosive_rounds.card_name = "Corrosive Rounds"
	corrosive_rounds.description = "This turn, guns apply -2 armor shred on hit. If target has hex, shred doubles."
	corrosive_rounds.card_type = "skill"
	corrosive_rounds.effect_type = "buff"
	corrosive_rounds.tags = ["skill", "instant", "corrosive"]
	corrosive_rounds.base_cost = 1
	corrosive_rounds.armor_shred = 2
	corrosive_rounds.buff_type = "corrosive_buff"
	corrosive_rounds.effect_params = {"double_on_hex": true}
	corrosive_rounds.target_type = "self"
	corrosive_rounds.rarity = 2
	_register_card(corrosive_rounds)
	
	# #27 Kinetic Pulse - shock ring control
	var kinetic_pulse := CardDef.new()
	kinetic_pulse.card_id = "kinetic_pulse"
	kinetic_pulse.card_name = "Kinetic Pulse"
	kinetic_pulse.description = "Push all Melee enemies to Close. Deal 2 damage and apply Slow to pushed enemies."
	kinetic_pulse.card_type = "skill"
	kinetic_pulse.effect_type = "shock_damage"
	kinetic_pulse.tags = ["skill", "instant", "ring_control", "shock"]
	kinetic_pulse.base_cost = 1
	kinetic_pulse.base_damage = 2
	kinetic_pulse.push_amount = 1
	kinetic_pulse.effect_params = {"slow_chance": 100, "push_first": true}
	kinetic_pulse.target_type = "ring"
	kinetic_pulse.target_rings = [0]
	kinetic_pulse.rarity = 2
	_register_card(kinetic_pulse)
	
	# #30 Rail Piercer - piercing sniper
	var rail_piercer := CardDef.new()
	rail_piercer.card_id = "rail_piercer"
	rail_piercer.card_name = "Rail Piercer"
	rail_piercer.description = "Deal 9 damage. Overflow 50% continues to the next enemy in line or stack."
	rail_piercer.card_type = "weapon"
	rail_piercer.effect_type = "piercing_damage"
	rail_piercer.tags = ["gun", "instant", "piercing", "sniper"]
	rail_piercer.base_cost = 2
	rail_piercer.base_damage = 9
	rail_piercer.effect_params = {"overflow_percent": 50}
	rail_piercer.target_type = "random_enemy"
	rail_piercer.target_rings = [0, 1, 2, 3]
	rail_piercer.rarity = 3
	_register_card(rail_piercer)
	
	# #31 Flame Coil - explosive instant
	var flame_coil := CardDef.new()
	flame_coil.card_id = "flame_coil"
	flame_coil.card_name = "Flame Coil"
	flame_coil.description = "Deal 3 damage to a ring. Splash 1 to adjacent rings. Explosive hits add 1 hex."
	flame_coil.card_type = "weapon"
	flame_coil.effect_type = "explosive_damage"
	flame_coil.tags = ["gun", "instant", "explosive", "aoe"]
	flame_coil.base_cost = 1
	flame_coil.base_damage = 3
	flame_coil.splash_damage = 1
	flame_coil.hex_damage = 1
	flame_coil.effect_params = {"add_hex": true}
	flame_coil.target_type = "ring"
	flame_coil.target_rings = [0, 1, 2, 3]
	flame_coil.requires_target = true
	flame_coil.rarity = 2
	_register_card(flame_coil)
	
	# #33 Barrier Siphon - lifedrain fortress
	var barrier_siphon := CardDef.new()
	barrier_siphon.card_id = "barrier_siphon"
	barrier_siphon.card_name = "Barrier Siphon"
	barrier_siphon.description = "Drain 2 HP from each barrier you control. Heal equal to total drained. Barriers keep uses."
	barrier_siphon.card_type = "skill"
	barrier_siphon.effect_type = "barrier_siphon"
	barrier_siphon.tags = ["skill", "instant", "lifedrain", "fortress"]
	barrier_siphon.base_cost = 1
	barrier_siphon.effect_params = {"drain_per_barrier": 2}
	barrier_siphon.target_type = "self"
	barrier_siphon.rarity = 2
	_register_card(barrier_siphon)
	
	# #34 Shock Net - shock barrier
	var shock_net := CardDef.new()
	shock_net.card_id = "shock_net"
	shock_net.card_name = "Shock Net"
	shock_net.description = "Place barrier: 0 damage, 2 uses. Enemies crossing are Slowed and take +1 damage from shock this turn."
	shock_net.card_type = "defense"
	shock_net.effect_type = "ring_barrier"
	shock_net.tags = ["barrier", "instant", "shock", "ring_control"]
	shock_net.base_cost = 1
	shock_net.base_damage = 0
	shock_net.duration = 2
	shock_net.effect_params = {"apply_slow": true, "shock_vuln": 1}
	shock_net.target_type = "ring"
	shock_net.target_rings = [1, 2, 3]
	shock_net.requires_target = true
	shock_net.rarity = 2
	_register_card(shock_net)
	
	# #36 Focused Salvo - synergy instant
	var focused_salvo := CardDef.new()
	focused_salvo.card_id = "focused_salvo"
	focused_salvo.card_name = "Focused Salvo"
	focused_salvo.description = "Deal 5 damage. If a deployed gun shares a tag, it fires at same target for +2 damage."
	focused_salvo.card_type = "weapon"
	focused_salvo.effect_type = "instant_damage"
	focused_salvo.tags = ["gun", "instant", "single_target", "engine_core"]
	focused_salvo.base_cost = 1
	focused_salvo.base_damage = 5
	focused_salvo.effect_params = {"synergy_fire": true, "synergy_bonus": 2}
	focused_salvo.target_type = "random_enemy"
	focused_salvo.target_rings = [0, 1, 2, 3]
	focused_salvo.rarity = 2
	_register_card(focused_salvo)
	
	# #37 Fracture Rounds - piercing swarm clear
	var fracture_rounds := CardDef.new()
	fracture_rounds.card_id = "fracture_rounds"
	fracture_rounds.card_name = "Fracture Rounds"
	fracture_rounds.description = "Next shotgun/piercing attack this turn repeats on a second random target for 50% damage."
	fracture_rounds.card_type = "skill"
	fracture_rounds.effect_type = "buff"
	fracture_rounds.tags = ["skill", "instant", "piercing", "swarm_clear"]
	fracture_rounds.base_cost = 1
	fracture_rounds.buff_type = "fracture_buff"
	fracture_rounds.effect_params = {"repeat_percent": 50, "trigger_tags": ["shotgun", "piercing"]}
	fracture_rounds.target_type = "self"
	fracture_rounds.rarity = 2
	_register_card(fracture_rounds)
	
	# #41 Ricochet Disk - piercing shotgun
	var ricochet_disk := CardDef.new()
	ricochet_disk.card_id = "ricochet_disk"
	ricochet_disk.card_name = "Ricochet Disk"
	ricochet_disk.description = "Deal 2 damage bouncing up to 4 times in Close/Mid. Cannot hit same enemy twice."
	ricochet_disk.card_type = "weapon"
	ricochet_disk.effect_type = "beam_damage"
	ricochet_disk.tags = ["gun", "instant", "piercing", "shotgun"]
	ricochet_disk.base_cost = 1
	ricochet_disk.base_damage = 2
	ricochet_disk.chain_count = 4
	ricochet_disk.effect_params = {"no_repeat_targets": true}
	ricochet_disk.target_type = "random_enemy"
	ricochet_disk.target_rings = [1, 2]
	ricochet_disk.rarity = 2
	_register_card(ricochet_disk)
	
	# #42 Hex Bloom - hex AoE
	var hex_bloom := CardDef.new()
	hex_bloom.card_id = "hex_bloom"
	hex_bloom.card_name = "Hex Bloom"
	hex_bloom.description = "Apply 1 hex to all enemies. If already hexed, apply +2 more."
	hex_bloom.card_type = "hex"
	hex_bloom.effect_type = "apply_hex"
	hex_bloom.tags = ["hex", "instant", "aoe"]
	hex_bloom.base_cost = 2
	hex_bloom.hex_damage = 1
	hex_bloom.effect_params = {"bonus_if_hexed": 2}
	hex_bloom.target_type = "all_enemies"
	hex_bloom.rarity = 3
	_register_card(hex_bloom)
	
	# #43 Runic Overload - fortress volatile
	var runic_overload := CardDef.new()
	runic_overload.card_id = "runic_overload"
	runic_overload.card_name = "Runic Overload"
	runic_overload.description = "Gain 4 armor. If you have 3+ barriers, Overclock costs 0 this turn."
	runic_overload.card_type = "defense"
	runic_overload.effect_type = "gain_armor"
	runic_overload.tags = ["skill", "instant", "fortress", "volatile"]
	runic_overload.base_cost = 1
	runic_overload.armor_amount = 4
	runic_overload.effect_params = {"barrier_threshold": 3, "free_card": "overclock"}
	runic_overload.target_type = "self"
	runic_overload.rarity = 2
	_register_card(runic_overload)
	
	# #44 Barrier Bloom - duplicate barriers
	var barrier_bloom := CardDef.new()
	barrier_bloom.card_id = "barrier_bloom"
	barrier_bloom.card_name = "Barrier Bloom"
	barrier_bloom.description = "Choose a ring. Duplicate each barrier there with 1 use and 1 damage."
	barrier_bloom.card_type = "skill"
	barrier_bloom.effect_type = "barrier_bloom"
	barrier_bloom.tags = ["skill", "instant", "barrier_trap"]
	barrier_bloom.base_cost = 1
	barrier_bloom.base_damage = 1
	barrier_bloom.duration = 1
	barrier_bloom.target_type = "ring"
	barrier_bloom.target_rings = [0, 1, 2, 3]
	barrier_bloom.requires_target = true
	barrier_bloom.rarity = 2
	_register_card(barrier_bloom)
	
	# #45 Scrap Vents - volatile buff
	var scrap_vents := CardDef.new()
	scrap_vents.card_id = "scrap_vents"
	scrap_vents.card_name = "Scrap Vents"
	scrap_vents.description = "Lose 2 HP. Your next explosive or piercing card this turn gains +3 damage."
	scrap_vents.card_type = "skill"
	scrap_vents.effect_type = "buff"
	scrap_vents.tags = ["skill", "instant", "volatile"]
	scrap_vents.base_cost = 0
	scrap_vents.self_damage = 2
	scrap_vents.buff_type = "damage_buff"
	scrap_vents.buff_value = 3
	scrap_vents.effect_params = {"buff_tags": ["explosive", "piercing"]}
	scrap_vents.target_type = "self"
	scrap_vents.rarity = 1
	_register_card(scrap_vents)
	
	# #46 Shockwave Gauntlet - shock ring control
	var shockwave_gauntlet := CardDef.new()
	shockwave_gauntlet.card_id = "shockwave_gauntlet"
	shockwave_gauntlet.card_name = "Shockwave Gauntlet"
	shockwave_gauntlet.description = "Deal 3 damage and push target 1 ring. If it hits a barrier, stun it for 1 turn."
	shockwave_gauntlet.card_type = "weapon"
	shockwave_gauntlet.effect_type = "shock_damage"
	shockwave_gauntlet.tags = ["gun", "instant", "shock", "ring_control"]
	shockwave_gauntlet.base_cost = 1
	shockwave_gauntlet.base_damage = 3
	shockwave_gauntlet.push_amount = 1
	shockwave_gauntlet.effect_params = {"stun_on_barrier": true}
	shockwave_gauntlet.target_type = "random_enemy"
	shockwave_gauntlet.target_rings = [0, 1, 2]
	shockwave_gauntlet.rarity = 2
	_register_card(shockwave_gauntlet)
	
	# #49 Glass Shards - volatile piercing
	var glass_shards := CardDef.new()
	glass_shards.card_id = "glass_shards"
	glass_shards.card_name = "Glass Shards"
	glass_shards.description = "Deal 6 damage. Lose 2 armor. If target dies, gain 1 energy next turn."
	glass_shards.card_type = "weapon"
	glass_shards.effect_type = "piercing_damage"
	glass_shards.tags = ["gun", "instant", "piercing", "volatile"]
	glass_shards.base_cost = 1
	glass_shards.base_damage = 6
	glass_shards.effect_params = {"armor_cost": 2, "energy_on_kill": 1}
	glass_shards.target_type = "random_enemy"
	glass_shards.target_rings = [0, 1, 2, 3]
	glass_shards.rarity = 2
	_register_card(glass_shards)
	
	# #50 Null Field - fortress defense
	var null_field := CardDef.new()
	null_field.card_id = "null_field"
	null_field.card_name = "Null Field"
	null_field.description = "Gain 5 armor. This turn, enemies in Melee deal -2 damage. If barrier, slow Melee enemies."
	null_field.card_type = "defense"
	null_field.effect_type = "gain_armor"
	null_field.tags = ["defense", "instant", "fortress"]
	null_field.base_cost = 1
	null_field.armor_amount = 5
	null_field.effect_params = {"melee_damage_reduction": 2, "slow_if_barrier": true}
	null_field.target_type = "self"
	null_field.rarity = 2
	_register_card(null_field)


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func _register_card(card) -> void:
	cards[card.card_id] = card
	
	if not cards_by_type.has(card.card_type):
		cards_by_type[card.card_type] = []
	cards_by_type[card.card_type].append(card.card_id)
	
	for tag in card.tags:
		if not cards_by_tag.has(tag):
			cards_by_tag[tag] = []
		cards_by_tag[tag].append(card.card_id)


func get_card(card_id: String):
	return cards.get(card_id, null)


func get_random_card(exclude_ids: Array = []):
	var available: Array = []
	for card_id in cards.keys():
		if card_id not in exclude_ids:
			available.append(card_id)
	if available.size() > 0:
		return cards[available[randi() % available.size()]]
	return null


func get_shop_cards(count: int, _wave: int) -> Array[CardDefinition]:
	"""Get random V2 cards for shop/rewards."""
	var result: Array[CardDefinition] = []
	var used_ids: Array = []
	
	for i: int in range(count):
		var card = get_random_card(used_ids)
		if card:
			result.append(card)
			used_ids.append(card.card_id)
	
	return result


func get_cards_by_tag(tag: String) -> Array:
	"""Get all card IDs with a specific tag."""
	return cards_by_tag.get(tag, [])


func get_cards_by_type(card_type: String) -> Array:
	"""Get all card IDs of a specific type."""
	return cards_by_type.get(card_type, [])


func get_starter_weapons() -> Array:
	"""Get all starter weapon cards for Brotato economy mode."""
	var result: Array = []
	for card_id: String in cards.keys():
		var card = cards[card_id]
		if card.is_starter_weapon:
			result.append(card)
	return result
