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
	"""Create the complete V2 card pool."""
	_create_v2_starter_cards()
	_create_gun_board_cards()
	_create_hex_ritualist_cards()
	_create_barrier_fortress_cards()
	_create_lifedrain_cards()
	_create_overlap_cards()
	cards_loaded.emit()


# =============================================================================
# V2 STARTER CARDS (Veteran Warden deck)
# =============================================================================

func _create_v2_starter_cards() -> void:
	"""V2 Veteran Warden starter deck - weak, flexible cards for build pivots."""
	
	# Rusty Pistol - basic PERSISTENT gun (gives starter deck auto-fire ramp)
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
	rusty_pistol.rarity = 0
	_register_card(rusty_pistol)
	
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
	minor_hex.rarity = 0
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
	minor_barrier.rarity = 0
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
	guard_stance.rarity = 0
	_register_card(guard_stance)
	
	# Quick Draw - free card draw
	var quick_draw := CardDef.new()
	quick_draw.card_id = "quick_draw"
	quick_draw.card_name = "Quick Draw"
	quick_draw.description = "Draw 1 card."
	quick_draw.card_type = "skill"
	quick_draw.effect_type = "draw_cards"
	quick_draw.tags = ["skill", "instant", "engine_core"]
	quick_draw.base_cost = 0
	quick_draw.cards_to_draw = 1
	quick_draw.target_type = "self"
	quick_draw.rarity = 0
	_register_card(quick_draw)
	
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
	shove.rarity = 0
	_register_card(shove)


# =============================================================================
# GUN BOARD FAMILY (10 cards)
# =============================================================================

func _create_gun_board_cards() -> void:
	"""Gun Board family - persistent guns that auto-clear the horde."""
	
	# Infernal Pistol - persistent sniper
	var infernal_pistol := CardDef.new()
	infernal_pistol.card_id = "infernal_pistol"
	infernal_pistol.card_name = "Infernal Pistol"
	infernal_pistol.description = "Persistent: Deal {damage} damage to a random enemy in Mid/Far at end of turn."
	infernal_pistol.persistent_description = "Deal {damage} to random enemy in Mid/Far."
	infernal_pistol.card_type = "weapon"
	infernal_pistol.effect_type = "weapon_persistent"
	infernal_pistol.tags = ["gun", "persistent", "single_target", "sniper"]
	infernal_pistol.base_cost = 1
	infernal_pistol.base_damage = 4
	infernal_pistol.target_type = "random_enemy"
	infernal_pistol.target_rings = [2, 3]
	infernal_pistol.weapon_trigger = "turn_end"
	infernal_pistol.rarity = 1
	_register_card(infernal_pistol)
	
	# Choirbreaker Shotgun - persistent swarm clear
	var choirbreaker := CardDef.new()
	choirbreaker.card_id = "choirbreaker_shotgun"
	choirbreaker.card_name = "Choirbreaker Shotgun"
	choirbreaker.description = "Persistent: Deal {damage} damage to up to 3 enemies in Melee/Close at end of turn."
	choirbreaker.persistent_description = "Deal {damage} to up to 3 enemies in Melee/Close."
	choirbreaker.card_type = "weapon"
	choirbreaker.effect_type = "weapon_persistent"
	choirbreaker.tags = ["gun", "persistent", "shotgun", "close_focus", "swarm_clear"]
	choirbreaker.base_cost = 1
	choirbreaker.base_damage = 2
	choirbreaker.target_type = "random_enemy"
	choirbreaker.target_rings = [0, 1]
	choirbreaker.target_count = 3
	choirbreaker.weapon_trigger = "turn_end"
	choirbreaker.rarity = 1
	_register_card(choirbreaker)
	
	# Riftshard Rifle - high damage sniper
	var riftshard := CardDef.new()
	riftshard.card_id = "riftshard_rifle"
	riftshard.card_name = "Riftshard Rifle"
	riftshard.description = "Deal {damage} damage to a random enemy in Far. If it dies, apply 2 hex to another enemy."
	riftshard.card_type = "weapon"
	riftshard.effect_type = "instant_damage"
	riftshard.tags = ["gun", "instant", "sniper", "single_target"]
	riftshard.base_cost = 2
	riftshard.base_damage = 8
	riftshard.hex_damage = 2
	riftshard.target_type = "random_enemy"
	riftshard.target_rings = [3]
	riftshard.rarity = 2
	_register_card(riftshard)
	
	# Scatter Volley - multi-target instant
	var scatter := CardDef.new()
	scatter.card_id = "scatter_volley"
	scatter.card_name = "Scatter Volley"
	scatter.description = "Deal {damage} damage to 4 random enemies."
	scatter.card_type = "weapon"
	scatter.effect_type = "scatter_damage"
	scatter.tags = ["gun", "instant", "shotgun", "swarm_clear"]
	scatter.base_cost = 1
	scatter.base_damage = 2
	scatter.target_count = 4
	scatter.target_type = "random_enemy"
	scatter.target_rings = [0, 1, 2, 3]
	scatter.rarity = 1
	_register_card(scatter)
	
	# Storm Carbine - persistent mid-range
	var storm := CardDef.new()
	storm.card_id = "storm_carbine"
	storm.card_name = "Storm Carbine"
	storm.description = "Persistent: Deal {damage} damage to 2 random enemies in Close/Mid at end of turn."
	storm.persistent_description = "Deal {damage} to 2 enemies in Close/Mid."
	storm.card_type = "weapon"
	storm.effect_type = "weapon_persistent"
	storm.tags = ["gun", "persistent", "single_target", "mid_focus"]
	storm.base_cost = 2
	storm.base_damage = 3
	storm.target_type = "random_enemy"
	storm.target_rings = [1, 2]
	storm.target_count = 2
	storm.weapon_trigger = "turn_end"
	storm.rarity = 2
	_register_card(storm)
	
	# Overcharged Revolver - volatile damage
	var overcharged := CardDef.new()
	overcharged.card_id = "overcharged_revolver"
	overcharged.card_name = "Overcharged Revolver"
	overcharged.description = "Deal {damage} damage to a random enemy. Lose 1 HP."
	overcharged.card_type = "weapon"
	overcharged.effect_type = "instant_damage"
	overcharged.tags = ["gun", "instant", "volatile", "single_target"]
	overcharged.base_cost = 1
	overcharged.base_damage = 6
	overcharged.self_damage = 1
	overcharged.target_type = "random_enemy"
	overcharged.target_rings = [0, 1, 2, 3]
	overcharged.rarity = 1
	_register_card(overcharged)
	
	# Suppressing Fire - ring control gun
	var suppressing := CardDef.new()
	suppressing.card_id = "suppressing_fire"
	suppressing.card_name = "Suppressing Fire"
	suppressing.description = "Deal {damage} damage to all enemies in Mid."
	suppressing.card_type = "weapon"
	suppressing.effect_type = "instant_damage"
	suppressing.tags = ["gun", "instant", "ring_control", "mid_focus"]
	suppressing.base_cost = 1
	suppressing.base_damage = 3
	suppressing.target_type = "ring"
	suppressing.target_rings = [2]
	suppressing.requires_target = false
	suppressing.rarity = 1
	_register_card(suppressing)
	
	# Twin Pistols - persistent close range
	var twin := CardDef.new()
	twin.card_id = "twin_pistols"
	twin.card_name = "Twin Pistols"
	twin.description = "Persistent: Deal {damage} damage to 2 random enemies in Melee/Close at end of turn."
	twin.persistent_description = "Deal {damage} to 2 enemies in Melee/Close."
	twin.card_type = "weapon"
	twin.effect_type = "weapon_persistent"
	twin.tags = ["gun", "persistent", "single_target", "close_focus"]
	twin.base_cost = 1
	twin.base_damage = 2
	twin.target_type = "random_enemy"
	twin.target_rings = [0, 1]
	twin.target_count = 2
	twin.weapon_trigger = "turn_end"
	twin.rarity = 1
	_register_card(twin)
	
	# Salvo Drone - persistent AoE
	var salvo := CardDef.new()
	salvo.card_id = "salvo_drone"
	salvo.card_name = "Salvo Drone"
	salvo.description = "Persistent: Deal {damage} damage to a random ring at end of turn."
	salvo.persistent_description = "Deal {damage} to all enemies in a random ring."
	salvo.card_type = "weapon"
	salvo.effect_type = "weapon_persistent"
	salvo.tags = ["gun", "engine", "persistent", "aoe"]
	salvo.base_cost = 2
	salvo.base_damage = 3
	salvo.target_type = "ring"
	salvo.target_rings = [0, 1, 2, 3]
	salvo.weapon_trigger = "turn_end"
	salvo.rarity = 2
	_register_card(salvo)
	
	# Ammo Cache - gun support skill
	var ammo := CardDef.new()
	ammo.card_id = "ammo_cache"
	ammo.card_name = "Ammo Cache"
	ammo.description = "Draw 2 cards. The next gun card you play this turn costs 1 less."
	ammo.card_type = "skill"
	ammo.effect_type = "draw_and_buff"
	ammo.tags = ["skill", "instant", "engine_core", "gun"]
	ammo.base_cost = 1
	ammo.cards_to_draw = 2
	ammo.buff_type = "cost_reduction"
	ammo.buff_value = 1
	ammo.rarity = 1
	_register_card(ammo)


# =============================================================================
# HEX RITUALIST FAMILY (10 cards)
# =============================================================================

func _create_hex_ritualist_cards() -> void:
	"""Hex Ritualist family - stack hex for massive delayed damage."""
	
	# Plague Cloud - AoE hex
	var plague := CardDef.new()
	plague.card_id = "plague_cloud"
	plague.card_name = "Plague Cloud"
	plague.description = "Apply {hex_damage} Hex to all enemies."
	plague.card_type = "hex"
	plague.effect_type = "apply_hex"
	plague.tags = ["hex", "instant", "aoe", "swarm_clear", "hex_ritual"]
	plague.base_cost = 2
	plague.hex_damage = 2
	plague.target_type = "all_enemies"
	plague.rarity = 1
	_register_card(plague)
	
	# Withering Mark - single target high hex
	var withering := CardDef.new()
	withering.card_id = "withering_mark"
	withering.card_name = "Withering Mark"
	withering.description = "Apply {hex_damage} Hex to a single enemy."
	withering.card_type = "hex"
	withering.effect_type = "apply_hex"
	withering.tags = ["hex", "instant", "single_target", "sniper", "hex_ritual"]
	withering.base_cost = 1
	withering.hex_damage = 5
	withering.target_type = "random_enemy"
	withering.target_rings = [0, 1, 2, 3]
	withering.target_count = 1
	withering.rarity = 1
	_register_card(withering)
	
	# Plague Turret - persistent hex engine
	var plague_turret := CardDef.new()
	plague_turret.card_id = "plague_turret"
	plague_turret.card_name = "Plague Turret"
	plague_turret.description = "Persistent: Apply {hex_damage} Hex to all enemies in a random ring at end of turn."
	plague_turret.persistent_description = "Apply {hex_damage} Hex to a random ring."
	plague_turret.card_type = "hex"
	plague_turret.effect_type = "weapon_persistent"
	plague_turret.tags = ["hex", "engine", "persistent", "aoe", "hex_ritual"]
	plague_turret.base_cost = 2
	plague_turret.hex_damage = 2
	plague_turret.target_type = "ring"
	plague_turret.target_rings = [0, 1, 2, 3]
	plague_turret.weapon_trigger = "turn_end"
	plague_turret.rarity = 2
	_register_card(plague_turret)
	
	# Soul Brand - hex with armor on kill
	var soul_brand := CardDef.new()
	soul_brand.card_id = "soul_brand"
	soul_brand.card_name = "Soul Brand"
	soul_brand.description = "Apply {hex_damage} Hex. If the target dies this turn, gain 2 armor."
	soul_brand.card_type = "hex"
	soul_brand.effect_type = "apply_hex"
	soul_brand.tags = ["hex", "instant", "single_target", "hex_ritual"]
	soul_brand.base_cost = 1
	soul_brand.hex_damage = 3
	soul_brand.armor_amount = 2
	soul_brand.target_type = "random_enemy"
	soul_brand.target_rings = [0, 1, 2, 3]
	soul_brand.target_count = 1
	soul_brand.rarity = 1
	_register_card(soul_brand)
	
	# Rotting Gale - hex + push
	var rotting := CardDef.new()
	rotting.card_id = "rotting_gale"
	rotting.card_name = "Rotting Gale"
	rotting.description = "Apply {hex_damage} Hex to all enemies in Close/Mid. Push Far enemies into Mid."
	rotting.card_type = "hex"
	rotting.effect_type = "apply_hex"
	rotting.tags = ["hex", "instant", "aoe", "ring_control", "hex_ritual"]
	rotting.base_cost = 2
	rotting.hex_damage = 2
	rotting.push_amount = -1  # Pull toward center
	rotting.target_type = "ring"
	rotting.target_rings = [1, 2]
	rotting.requires_target = false
	rotting.rarity = 2
	_register_card(rotting)
	
	# Ritual Focus - HP cost for hex boost
	var ritual := CardDef.new()
	ritual.card_id = "ritual_focus"
	ritual.card_name = "Ritual Focus"
	ritual.description = "Lose 2 HP. The next hex card you play this turn has +100% hex value."
	ritual.card_type = "skill"
	ritual.effect_type = "buff"
	ritual.tags = ["skill", "instant", "hex_ritual", "engine_core"]
	ritual.base_cost = 0
	ritual.self_damage = 2
	ritual.buff_type = "hex_damage"
	ritual.buff_value = 100
	ritual.rarity = 2
	_register_card(ritual)
	
	# Blood Sigil Bolt - hex + heal
	var blood_sigil := CardDef.new()
	blood_sigil.card_id = "blood_sigil_bolt"
	blood_sigil.card_name = "Blood Sigil Bolt"
	blood_sigil.description = "Apply {hex_damage} Hex to a random enemy. Heal 1 HP."
	blood_sigil.card_type = "hex"
	blood_sigil.effect_type = "apply_hex"
	blood_sigil.tags = ["hex", "instant", "lifedrain", "hex_ritual"]
	blood_sigil.base_cost = 1
	blood_sigil.hex_damage = 3
	blood_sigil.heal_amount = 1
	blood_sigil.target_type = "random_enemy"
	blood_sigil.target_rings = [0, 1, 2, 3]
	blood_sigil.target_count = 1
	blood_sigil.rarity = 1
	_register_card(blood_sigil)
	
	# Cursed Miasma - hex + draw
	var miasma := CardDef.new()
	miasma.card_id = "cursed_miasma"
	miasma.card_name = "Cursed Miasma"
	miasma.description = "Apply 1 Hex to all enemies. Draw 1 card for every 3 hex applied."
	miasma.card_type = "hex"
	miasma.effect_type = "apply_hex"
	miasma.tags = ["hex", "instant", "aoe", "swarm_clear"]
	miasma.base_cost = 2
	miasma.hex_damage = 1
	miasma.target_type = "all_enemies"
	miasma.rarity = 2
	_register_card(miasma)
	
	# Doom Clock - persistent hex amplifier
	var doom := CardDef.new()
	doom.card_id = "doom_clock"
	doom.card_name = "Doom Clock"
	doom.description = "Persistent: At end of your turn, increase hex on all hexed enemies by 1."
	doom.persistent_description = "Increase hex on all hexed enemies by 1."
	doom.card_type = "hex"
	doom.effect_type = "weapon_persistent"
	doom.tags = ["hex", "engine", "persistent", "hex_ritual"]
	doom.base_cost = 2
	doom.hex_damage = 1
	doom.weapon_trigger = "turn_end"
	doom.rarity = 2
	_register_card(doom)
	
	# Last Rite - consume hex for AoE
	var last_rite := CardDef.new()
	last_rite.card_id = "last_rite"
	last_rite.card_name = "Last Rite"
	last_rite.description = "Choose a hexed enemy. Consume its hex and deal that much damage to all other enemies."
	last_rite.card_type = "hex"
	last_rite.effect_type = "consume_hex_aoe"
	last_rite.tags = ["hex", "instant", "single_target", "volatile", "hex_ritual"]
	last_rite.base_cost = 2
	last_rite.target_type = "random_enemy"
	last_rite.target_rings = [0, 1, 2, 3]
	last_rite.rarity = 2
	_register_card(last_rite)


# =============================================================================
# BARRIER FORTRESS FAMILY (10 cards)
# =============================================================================

func _create_barrier_fortress_cards() -> void:
	"""Barrier Fortress family - turn rings into minefields."""
	
	# Ring Ward - persistent barrier
	var ring_ward := CardDef.new()
	ring_ward.card_id = "ring_ward"
	ring_ward.card_name = "Ring Ward"
	ring_ward.description = "Place a barrier in a chosen ring. Deals {damage} damage when crossed (3 uses)."
	ring_ward.card_type = "defense"
	ring_ward.effect_type = "ring_barrier"
	ring_ward.tags = ["barrier", "engine", "persistent", "ring_control", "barrier_trap", "fortress"]
	ring_ward.base_cost = 2
	ring_ward.base_damage = 3
	ring_ward.duration = 3
	ring_ward.target_type = "ring"
	ring_ward.target_rings = [1, 2, 3]
	ring_ward.requires_target = true
	ring_ward.rarity = 2
	_register_card(ring_ward)
	
	# Barrier Sigil - barrier + slow
	var barrier_sigil := CardDef.new()
	barrier_sigil.card_id = "barrier_sigil"
	barrier_sigil.card_name = "Barrier Sigil"
	barrier_sigil.description = "Place a barrier that deals {damage} damage. Enemies that cross don't move this turn."
	barrier_sigil.card_type = "defense"
	barrier_sigil.effect_type = "ring_barrier"
	barrier_sigil.tags = ["barrier", "instant", "ring_control", "barrier_trap"]
	barrier_sigil.base_cost = 1
	barrier_sigil.base_damage = 4
	barrier_sigil.duration = 2
	barrier_sigil.target_type = "ring"
	barrier_sigil.target_rings = [1, 2, 3]
	barrier_sigil.requires_target = true
	barrier_sigil.rarity = 1
	_register_card(barrier_sigil)
	
	# Glass Ward - pure armor
	var glass_ward := CardDef.new()
	glass_ward.card_id = "glass_ward"
	glass_ward.card_name = "Glass Ward"
	glass_ward.description = "Gain {armor} Armor."
	glass_ward.card_type = "defense"
	glass_ward.effect_type = "gain_armor"
	glass_ward.tags = ["defense", "instant", "fortress"]
	glass_ward.base_cost = 1
	glass_ward.armor_amount = 5
	glass_ward.target_type = "self"
	glass_ward.rarity = 1
	_register_card(glass_ward)
	
	# Runic Rampart - double barrier
	var rampart := CardDef.new()
	rampart.card_id = "runic_rampart"
	rampart.card_name = "Runic Rampart"
	rampart.description = "Place a barrier in Melee and Close. Each has 3 HP and deals 2 damage when crossed."
	rampart.card_type = "defense"
	rampart.effect_type = "ring_barrier"
	rampart.tags = ["barrier", "instant", "fortress"]
	rampart.base_cost = 2
	rampart.base_damage = 2
	rampart.duration = 3
	rampart.target_type = "ring"
	rampart.target_rings = [0, 1]
	rampart.requires_target = false
	rampart.rarity = 2
	_register_card(rampart)
	
	# Reinforced Circle - barrier buff
	var reinforced := CardDef.new()
	reinforced.card_id = "reinforced_circle"
	reinforced.card_name = "Reinforced Circle"
	reinforced.description = "Choose a ring. Existing barriers in that ring gain +2 HP/duration."
	reinforced.card_type = "skill"
	reinforced.effect_type = "buff_barriers"
	reinforced.tags = ["barrier", "instant", "fortress"]
	reinforced.base_cost = 1
	reinforced.buff_value = 2
	reinforced.target_type = "ring"
	reinforced.target_rings = [0, 1, 2, 3]
	reinforced.requires_target = true
	reinforced.rarity = 1
	_register_card(reinforced)
	
	# Ward Shock - barrier synergy damage
	var ward_shock := CardDef.new()
	ward_shock.card_id = "ward_shock"
	ward_shock.card_name = "Ward Shock"
	ward_shock.description = "All enemies that crossed a barrier this turn take {damage} damage."
	ward_shock.card_type = "skill"
	ward_shock.effect_type = "barrier_synergy_damage"
	ward_shock.tags = ["skill", "instant", "barrier_trap", "ring_control"]
	ward_shock.base_cost = 1
	ward_shock.base_damage = 2
	ward_shock.rarity = 1
	_register_card(ward_shock)
	
	# Lockdown Field - prevent movement
	var lockdown := CardDef.new()
	lockdown.card_id = "lockdown_field"
	lockdown.card_name = "Lockdown Field"
	lockdown.description = "This turn, enemies cannot move from Close into Melee. Place a barrier in Close."
	lockdown.card_type = "defense"
	lockdown.effect_type = "ring_barrier"
	lockdown.tags = ["barrier", "instant", "ring_control", "fortress"]
	lockdown.base_cost = 2
	lockdown.base_damage = 3
	lockdown.duration = 1
	lockdown.target_type = "ring"
	lockdown.target_rings = [1]
	lockdown.requires_target = false
	lockdown.rarity = 2
	_register_card(lockdown)
	
	# Guardian Circle - armor + barrier synergy
	var guardian := CardDef.new()
	guardian.card_id = "guardian_circle"
	guardian.card_name = "Guardian Circle"
	guardian.description = "Gain 3 armor. If you control 3+ barriers, gain 2 additional armor."
	guardian.card_type = "defense"
	guardian.effect_type = "gain_armor"
	guardian.tags = ["defense", "instant", "fortress"]
	guardian.base_cost = 1
	guardian.armor_amount = 3
	guardian.target_type = "self"
	guardian.rarity = 1
	_register_card(guardian)
	
	# Repulsion Wave - push + barrier damage
	var repulsion := CardDef.new()
	repulsion.card_id = "repulsion_wave"
	repulsion.card_name = "Repulsion Wave"
	repulsion.description = "Push all enemies in Melee/Close back 1 ring. Enemies that cross a barrier take 2 damage."
	repulsion.card_type = "skill"
	repulsion.effect_type = "push_enemies"
	repulsion.tags = ["skill", "instant", "ring_control", "swarm_clear", "volatile"]
	repulsion.base_cost = 1
	repulsion.push_amount = 1
	repulsion.base_damage = 2
	repulsion.target_type = "ring"
	repulsion.target_rings = [0, 1]
	repulsion.requires_target = false
	repulsion.rarity = 1
	_register_card(repulsion)
	
	# Iron Bastion - strong armor
	var bastion := CardDef.new()
	bastion.card_id = "iron_bastion"
	bastion.card_name = "Iron Bastion"
	bastion.description = "Gain {armor} Armor."
	bastion.card_type = "defense"
	bastion.effect_type = "gain_armor"
	bastion.tags = ["defense", "instant", "fortress"]
	bastion.base_cost = 2
	bastion.armor_amount = 8
	bastion.target_type = "self"
	bastion.rarity = 2
	_register_card(bastion)
	

# =============================================================================
# LIFEDRAIN BRUISER FAMILY (7 cards)
# =============================================================================

func _create_lifedrain_cards() -> void:
	"""Lifedrain Bruiser family - trade damage for sustain."""
	
	# Blood Shield - armor + kill heal
	var blood_shield := CardDef.new()
	blood_shield.card_id = "blood_shield"
	blood_shield.card_name = "Blood Shield"
	blood_shield.description = "Gain 3 armor. This turn, heal 1 HP whenever you kill an enemy."
	blood_shield.card_type = "defense"
	blood_shield.effect_type = "gain_armor"
	blood_shield.tags = ["defense", "instant", "lifedrain", "fortress"]
	blood_shield.base_cost = 1
	blood_shield.armor_amount = 3
	blood_shield.lifesteal_on_kill = 1
	blood_shield.target_type = "self"
	blood_shield.rarity = 1
	_register_card(blood_shield)
	
	# Blood Bolt - damage + heal
	var blood_bolt := CardDef.new()
	blood_bolt.card_id = "blood_bolt"
	blood_bolt.card_name = "Blood Bolt"
	blood_bolt.description = "Deal {damage} damage to a random enemy. Heal 2 HP."
	blood_bolt.card_type = "weapon"
	blood_bolt.effect_type = "damage_and_heal"
	blood_bolt.tags = ["gun", "instant", "lifedrain", "single_target"]
	blood_bolt.base_cost = 1
	blood_bolt.base_damage = 5
	blood_bolt.heal_amount = 2
	blood_bolt.target_type = "random_enemy"
	blood_bolt.target_rings = [0, 1, 2, 3]
	blood_bolt.rarity = 1
	_register_card(blood_bolt)
	
	# Leeching Slash - close range lifesteal
	var leeching := CardDef.new()
	leeching.card_id = "leeching_slash"
	leeching.card_name = "Leeching Slash"
	leeching.description = "Deal {damage} damage to an enemy in Melee/Close. Heal 2 HP."
	leeching.card_type = "weapon"
	leeching.effect_type = "damage_and_heal"
	leeching.tags = ["gun", "instant", "lifedrain", "close_focus"]
	leeching.base_cost = 1
	leeching.base_damage = 4
	leeching.heal_amount = 2
	leeching.target_type = "random_enemy"
	leeching.target_rings = [0, 1]
	leeching.rarity = 1
	_register_card(leeching)
	
	# Crimson Guard - armor + heal
	var crimson := CardDef.new()
	crimson.card_id = "crimson_guard"
	crimson.card_name = "Crimson Guard"
	crimson.description = "Gain 4 armor. Heal 1 HP."
	crimson.card_type = "defense"
	crimson.effect_type = "armor_and_heal"
	crimson.tags = ["defense", "instant", "lifedrain"]
	crimson.base_cost = 1
	crimson.armor_amount = 4
	crimson.heal_amount = 1
	crimson.target_type = "self"
	crimson.rarity = 1
	_register_card(crimson)
	
	# Sanguine Aura - persistent heal engine
	var sanguine := CardDef.new()
	sanguine.card_id = "sanguine_aura"
	sanguine.card_name = "Sanguine Aura"
	sanguine.description = "Persistent: At end of your turn, heal 1 HP for each enemy killed this turn."
	sanguine.persistent_description = "Heal 1 HP for each enemy killed this turn."
	sanguine.card_type = "skill"
	sanguine.effect_type = "weapon_persistent"
	sanguine.tags = ["engine", "persistent", "lifedrain"]
	sanguine.base_cost = 2
	sanguine.heal_amount = 1
	sanguine.weapon_trigger = "turn_end"
	sanguine.rarity = 2
	_register_card(sanguine)
	
	# Martyr's Vow - HP risk for big heal
	var martyr := CardDef.new()
	martyr.card_id = "martyrs_vow"
	martyr.card_name = "Martyr's Vow"
	martyr.description = "Lose 3 HP. This turn, whenever you kill an enemy, heal 3 HP."
	martyr.card_type = "skill"
	martyr.effect_type = "buff"
	martyr.tags = ["skill", "instant", "lifedrain", "volatile"]
	martyr.base_cost = 0
	martyr.self_damage = 3
	martyr.buff_type = "kill_heal"
	martyr.buff_value = 3
	martyr.rarity = 2
	_register_card(martyr)
	
	# Vampiric Volley - multi-target lifesteal
	var vampiric := CardDef.new()
	vampiric.card_id = "vampiric_volley"
	vampiric.card_name = "Vampiric Volley"
	vampiric.description = "Deal {damage} damage to up to 3 random enemies. Heal 1 HP for each enemy hit."
	vampiric.card_type = "weapon"
	vampiric.effect_type = "scatter_damage"
	vampiric.tags = ["gun", "instant", "lifedrain", "swarm_clear"]
	vampiric.base_cost = 2
	vampiric.base_damage = 3
	vampiric.target_count = 3
	vampiric.heal_amount = 1
	vampiric.target_type = "random_enemy"
	vampiric.target_rings = [0, 1, 2, 3]
	vampiric.rarity = 2
	_register_card(vampiric)


# =============================================================================
# OVERLAP / ENGINE CARDS (5 cards)
# =============================================================================

func _create_overlap_cards() -> void:
	"""Overlap cards - bridge multiple families for hybrid builds."""
	
	# Hex-Tipped Rounds - gun + hex
	var hex_rounds := CardDef.new()
	hex_rounds.card_id = "hex_tipped_rounds"
	hex_rounds.card_name = "Hex-Tipped Rounds"
	hex_rounds.description = "Deal {damage} damage to a random enemy. Apply 2 hex to it."
	hex_rounds.card_type = "weapon"
	hex_rounds.effect_type = "damage_and_hex"
	hex_rounds.tags = ["gun", "instant", "hex_ritual", "sniper"]
	hex_rounds.base_cost = 1
	hex_rounds.base_damage = 3
	hex_rounds.hex_damage = 2
	hex_rounds.target_type = "random_enemy"
	hex_rounds.target_rings = [0, 1, 2, 3]
	hex_rounds.rarity = 1
	_register_card(hex_rounds)
	
	# Barrier Leech - barrier + lifedrain
	var barrier_leech := CardDef.new()
	barrier_leech.card_id = "barrier_leech"
	barrier_leech.card_name = "Barrier Leech"
	barrier_leech.description = "Place a barrier that deals 2 damage when crossed. Heal 1 HP when it triggers."
	barrier_leech.card_type = "defense"
	barrier_leech.effect_type = "ring_barrier"
	barrier_leech.tags = ["barrier", "instant", "lifedrain", "barrier_trap"]
	barrier_leech.base_cost = 1
	barrier_leech.base_damage = 2
	barrier_leech.duration = 2
	barrier_leech.heal_amount = 1
	barrier_leech.target_type = "ring"
	barrier_leech.target_rings = [1, 2, 3]
	barrier_leech.requires_target = true
	barrier_leech.rarity = 1
	_register_card(barrier_leech)
	
	# Ritual Cartridge - gun + hex cost reduction
	var ritual_cart := CardDef.new()
	ritual_cart.card_id = "ritual_cartridge"
	ritual_cart.card_name = "Ritual Cartridge"
	ritual_cart.description = "The next gun and the next hex card you play this turn each cost 1 less."
	ritual_cart.card_type = "skill"
	ritual_cart.effect_type = "buff"
	ritual_cart.tags = ["skill", "instant", "engine_core", "gun", "hex_ritual"]
	ritual_cart.base_cost = 1
	ritual_cart.buff_type = "cost_reduction"
	ritual_cart.buff_value = 1
	ritual_cart.rarity = 1
	_register_card(ritual_cart)
	
	# Cursed Bulwark - armor + hex
	var cursed_bulwark := CardDef.new()
	cursed_bulwark.card_id = "cursed_bulwark"
	cursed_bulwark.card_name = "Cursed Bulwark"
	cursed_bulwark.description = "Gain 6 armor. Apply 1 hex to all enemies in Melee."
	cursed_bulwark.card_type = "defense"
	cursed_bulwark.effect_type = "armor_and_hex"
	cursed_bulwark.tags = ["defense", "instant", "fortress", "hex_ritual"]
	cursed_bulwark.base_cost = 2
	cursed_bulwark.armor_amount = 6
	cursed_bulwark.hex_damage = 1
	cursed_bulwark.target_type = "ring"
	cursed_bulwark.target_rings = [0]
	cursed_bulwark.rarity = 2
	_register_card(cursed_bulwark)
	
	# Blood Ward Turret - lifedrain engine
	var blood_turret := CardDef.new()
	blood_turret.card_id = "blood_ward_turret"
	blood_turret.card_name = "Blood Ward Turret"
	blood_turret.description = "Persistent: Deal 2 damage to a random enemy in Melee/Close and heal 1 HP at end of turn."
	blood_turret.persistent_description = "Deal 2 damage to enemy in Melee/Close. Heal 1 HP."
	blood_turret.card_type = "weapon"
	blood_turret.effect_type = "weapon_persistent"
	blood_turret.tags = ["engine", "persistent", "lifedrain", "barrier_trap"]
	blood_turret.base_cost = 2
	blood_turret.base_damage = 2
	blood_turret.heal_amount = 1
	blood_turret.target_type = "random_enemy"
	blood_turret.target_rings = [0, 1]
	blood_turret.weapon_trigger = "turn_end"
	blood_turret.rarity = 2
	_register_card(blood_turret)


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
