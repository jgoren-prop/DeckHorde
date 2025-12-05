extends Node
## CardDatabase - V5 Card Pool
## 54 Weapons + 24 Instants = 78 total cards
## All weapons use V5 damage formula with stat scaling

signal cards_loaded()

var cards: Dictionary = {}  # card_id -> CardDefinition
var cards_by_category: Dictionary = {}  # category -> Array[CardDefinition]
var cards_by_type: Dictionary = {}  # damage_type -> Array[CardDefinition]
var weapons: Array = []  # All weapon cards
var instants: Array = []  # All instant cards

const CardDef = preload("res://scripts/resources/CardDefinition.gd")
const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")


func _ready() -> void:
	_create_v5_cards()
	print("[CardDatabase] V5 Card Pool initialized with ", cards.size(), " cards (",
		weapons.size(), " weapons, ", instants.size(), " instants)")


func _create_v5_cards() -> void:
	"""Create the V5 card pool."""
	# Create weapons by category
	_create_kinetic_weapons()
	_create_thermal_weapons()
	_create_arcane_weapons()
	_create_fortress_weapons()
	_create_shadow_weapons()
	_create_utility_weapons()
	_create_control_weapons()
	_create_volatile_weapons()
	
	# Create instant cards
	_create_universal_instants()
	_create_category_instants()
	_create_dual_category_instants()
	
	cards_loaded.emit()


# =============================================================================
# V5 WEAPON CREATION HELPERS
# =============================================================================

func _create_weapon(id: String, card_name: String, cost: int, base: int, damage_type: String,
		categories: Array[String], scaling: Dictionary, crit_chance: float, crit_damage: float,
		effect: String = "", desc: String = "", hit_count: int = 1, rarity: int = 1) -> CardDef:
	"""Helper to create a V5 weapon card."""
	var card := CardDef.new()
	card.card_id = id
	card.card_name = card_name
	card.base_cost = cost
	card.base_damage = base
	card.damage_type = damage_type
	card.categories = categories
	card.tier = 1
	card.is_instant_card = false
	card.rarity = rarity
	card.card_type = "weapon"
	card.play_mode = "combat"
	card.hit_count = hit_count
	
	# Set scaling
	card.kinetic_scaling = scaling.get("kinetic", 0)
	card.thermal_scaling = scaling.get("thermal", 0)
	card.arcane_scaling = scaling.get("arcane", 0)
	card.armor_start_scaling = scaling.get("armor_start", 0)
	card.crit_damage_scaling = scaling.get("crit_damage", 0)
	card.missing_hp_scaling = scaling.get("missing_hp", 0)
	card.cards_played_scaling = scaling.get("cards_played", 0)
	card.barriers_scaling = scaling.get("barriers", 0)
	
	# Set crit
	card.crit_chance_bonus = crit_chance - 5.0  # Base is 5%, so subtract
	card.crit_damage_bonus = crit_damage - 150.0  # Base is 150%, so subtract
	
	# Set effect type
	if hit_count > 1:
		card.effect_type = "v5_multi_hit"
		card.target_type = "random_enemy"
		card.target_rings = [0, 1, 2, 3]
	elif effect.contains("ring") or effect.contains("Ring"):
		card.effect_type = "v5_ring_damage"
		card.target_type = "ring"
		card.requires_target = true
		card.target_rings = [0, 1, 2, 3]
	elif effect.contains("ALL"):
		card.effect_type = "v5_aoe"
		card.target_type = "all_enemies"
	else:
		card.effect_type = "v5_damage"
		card.target_type = "random_enemy"
		card.target_rings = [0, 1, 2, 3]
	
	# Build description
	if desc.is_empty():
		desc = _build_weapon_description(card, effect)
	card.description = desc
	
	# Store effect info in params
	if not effect.is_empty():
		card.effect_params["effect_text"] = effect
	
	# Legacy tags for backward compatibility
	card.tags = _categories_to_legacy_tags(categories)
	
	return card


func _build_weapon_description(card: CardDef, effect: String) -> String:
	"""Build a description string for a weapon."""
	var desc: String = ""
	
	# Base damage line
	if card.hit_count > 1:
		desc = "Deal {damage} damage %d times." % card.hit_count
	elif card.effect_type == "v5_ring_damage":
		desc = "Deal {damage} damage to a ring."
	elif card.effect_type == "v5_aoe":
		desc = "Deal {damage} damage to ALL enemies."
	else:
		desc = "Deal {damage} damage."
	
	# Add effect text
	if not effect.is_empty():
		desc += " " + effect
	
	return desc


func _categories_to_legacy_tags(categories: Array[String]) -> Array:
	"""Convert V5 categories to legacy tags for backward compatibility."""
	var tags: Array = []
	for cat: String in categories:
		tags.append(TagConstantsClass.category_to_legacy_tag(cat))
	return tags


func _register_card(card: CardDef) -> void:
	"""Register a card in all indexes."""
	cards[card.card_id] = card
	
	# Index by category
	for category: String in card.categories:
		if not cards_by_category.has(category):
			cards_by_category[category] = []
		cards_by_category[category].append(card)
	
	# Index by damage type
	if not cards_by_type.has(card.damage_type):
		cards_by_type[card.damage_type] = []
	cards_by_type[card.damage_type].append(card)
	
	# Track weapons vs instants
	if card.is_instant_card:
		instants.append(card)
	else:
		weapons.append(card)


# =============================================================================
# KINETIC-PRIMARY WEAPONS (10 Cards)
# =============================================================================

func _create_kinetic_weapons() -> void:
	# Pistol - basic gun
	var pistol := _create_weapon("pistol", "Pistol", 1, 2, "kinetic",
		["Kinetic"], {"kinetic": 100}, 5.0, 150.0)
	_register_card(pistol)
	
	# Heavy Pistol - upgraded pistol
	var heavy_pistol := _create_weapon("heavy_pistol", "Heavy Pistol", 2, 3, "kinetic",
		["Kinetic"], {"kinetic": 120}, 5.0, 150.0)
	_register_card(heavy_pistol)
	
	# Shotgun - splash damage (Kinetic + Thermal)
	var shotgun := _create_weapon("shotgun", "Shotgun", 2, 2, "kinetic",
		["Kinetic", "Thermal"], {"kinetic": 80}, 5.0, 150.0, "+2 splash to group")
	shotgun.splash_damage = 2
	shotgun.effect_type = "splash_damage"
	_register_card(shotgun)
	
	# Assault Rifle - hits 3 random (Kinetic + Utility)
	var assault := _create_weapon("assault_rifle", "Assault Rifle", 2, 1, "kinetic",
		["Kinetic", "Utility"], {"kinetic": 60}, 5.0, 150.0, "", "", 3)
	_register_card(assault)
	
	# Sniper Rifle - Far/Mid only, high crit (Kinetic + Shadow)
	var sniper := _create_weapon("sniper_rifle", "Sniper Rifle", 2, 4, "kinetic",
		["Kinetic", "Shadow"], {"kinetic": 150}, 15.0, 200.0, "Far/Mid only")
	sniper.target_rings = [2, 3]  # Mid, Far only
	_register_card(sniper)
	
	# Burst Fire - hits 3x (Kinetic + Utility)
	var burst := _create_weapon("burst_fire", "Burst Fire", 2, 1, "kinetic",
		["Kinetic", "Utility"], {"kinetic": 50}, 5.0, 150.0, "", "", 3)
	_register_card(burst)
	
	# Chain Gun - hits 5x (Kinetic + Utility)
	var chain := _create_weapon("chain_gun", "Chain Gun", 2, 0, "kinetic",
		["Kinetic", "Utility"], {"kinetic": 40}, 5.0, 150.0, "", "", 5)
	chain.can_repeat_target = true
	_register_card(chain)
	
	# Double Tap - hits 2x (Kinetic + Shadow)
	var double := _create_weapon("double_tap", "Double Tap", 1, 1, "kinetic",
		["Kinetic", "Shadow"], {"kinetic": 70}, 12.0, 175.0, "", "", 2)
	_register_card(double)
	
	# Marksman - +50% vs Far (Kinetic + Shadow)
	var marksman := _create_weapon("marksman", "Marksman", 2, 2, "kinetic",
		["Kinetic", "Shadow"], {"kinetic": 100}, 18.0, 200.0, "+50% vs Far")
	marksman.effect_params["far_bonus"] = 0.5
	_register_card(marksman)
	
	# Railgun - ignores armor (Kinetic + Fortress)
	var railgun := _create_weapon("railgun", "Railgun", 3, 5, "kinetic",
		["Kinetic", "Fortress"], {"kinetic": 180}, 5.0, 150.0, "Ignores armor")
	railgun.effect_params["ignore_armor"] = true
	_register_card(railgun)


# =============================================================================
# THERMAL-PRIMARY WEAPONS (7 Cards)
# =============================================================================

func _create_thermal_weapons() -> void:
	# Frag Grenade - ring damage (Thermal + Volatile)
	var frag := _create_weapon("frag_grenade", "Frag Grenade", 2, 2, "thermal",
		["Thermal", "Volatile"], {"thermal": 100}, 5.0, 150.0, "Hits entire ring")
	frag.effect_type = "v5_ring_damage"
	frag.target_type = "ring"
	frag.requires_target = true
	_register_card(frag)
	
	# Rocket - splash to group
	var rocket := _create_weapon("rocket", "Rocket", 3, 3, "thermal",
		["Thermal"], {"thermal": 120}, 5.0, 150.0, "+3 splash to group")
	rocket.splash_damage = 3
	rocket.effect_type = "splash_damage"
	_register_card(rocket)
	
	# Incendiary - apply burn (Thermal + Arcane)
	var incendiary := _create_weapon("incendiary", "Incendiary", 2, 1, "thermal",
		["Thermal", "Arcane"], {"thermal": 80}, 5.0, 150.0, "Apply 3 Burn")
	incendiary.burn_damage = 3
	_register_card(incendiary)
	
	# Firebomb - ring + burn (Thermal + Control)
	var firebomb := _create_weapon("firebomb", "Firebomb", 2, 1, "thermal",
		["Thermal", "Control"], {"thermal": 70}, 5.0, 150.0, "Ring, apply 2 Burn each")
	firebomb.effect_type = "v5_ring_damage"
	firebomb.burn_damage = 2
	firebomb.target_type = "ring"
	firebomb.requires_target = true
	_register_card(firebomb)
	
	# Cluster Bomb - hits 4 random (Thermal + Utility)
	var cluster := _create_weapon("cluster_bomb", "Cluster Bomb", 2, 1, "thermal",
		["Thermal", "Utility"], {"thermal": 60}, 5.0, 150.0, "", "", 4)
	_register_card(cluster)
	
	# Inferno - ring + heavy burn
	var inferno := _create_weapon("inferno", "Inferno", 3, 2, "thermal",
		["Thermal"], {"thermal": 100}, 5.0, 150.0, "Ring, apply 3 Burn each")
	inferno.effect_type = "v5_ring_damage"
	inferno.burn_damage = 3
	inferno.target_type = "ring"
	inferno.requires_target = true
	_register_card(inferno)
	
	# Napalm Strike - ALL enemies + burn (Thermal + Volatile)
	var napalm := _create_weapon("napalm_strike", "Napalm Strike", 3, 2, "thermal",
		["Thermal", "Volatile"], {"thermal": 90}, 5.0, 150.0, "ALL enemies, apply 2 Burn")
	napalm.effect_type = "v5_aoe"
	napalm.target_type = "all_enemies"
	napalm.burn_damage = 2
	_register_card(napalm)


# =============================================================================
# ARCANE-PRIMARY WEAPONS (7 Cards)
# =============================================================================

func _create_arcane_weapons() -> void:
	# Hex Bolt - apply hex
	var hex_bolt := _create_weapon("hex_bolt", "Hex Bolt", 1, 1, "arcane",
		["Arcane"], {"arcane": 80}, 5.0, 150.0, "Apply 3 Hex")
	hex_bolt.hex_damage = 3
	_register_card(hex_bolt)
	
	# Curse Wave - ring + hex (Arcane + Control)
	var curse_wave := _create_weapon("curse_wave", "Curse Wave", 2, 1, "arcane",
		["Arcane", "Control"], {"arcane": 60}, 5.0, 150.0, "Ring, apply 2 Hex each")
	curse_wave.effect_type = "v5_ring_damage"
	curse_wave.hex_damage = 2
	curse_wave.target_type = "ring"
	curse_wave.requires_target = true
	_register_card(curse_wave)
	
	# Soul Drain - heal (Arcane + Volatile)
	var soul_drain := _create_weapon("soul_drain", "Soul Drain", 2, 2, "arcane",
		["Arcane", "Volatile"], {"arcane": 100}, 5.0, 150.0, "Heal 3")
	soul_drain.heal_amount = 3
	_register_card(soul_drain)
	
	# Hex Detonation - consumes hex (Arcane + Shadow)
	var hex_det := _create_weapon("hex_detonation", "Hex Detonation", 2, 1, "arcane",
		["Arcane", "Shadow"], {"arcane": 70}, 20.0, 200.0, "Consumes Hex: +1 dmg per stack")
	hex_det.effect_params["consume_hex"] = true
	_register_card(hex_det)
	
	# Life Siphon - heal
	var life_siphon := _create_weapon("life_siphon", "Life Siphon", 1, 1, "arcane",
		["Arcane"], {"arcane": 60}, 5.0, 150.0, "Heal 2")
	life_siphon.heal_amount = 2
	_register_card(life_siphon)
	
	# Dark Ritual - ring + hex + self damage (Arcane + Volatile)
	var dark_ritual := _create_weapon("dark_ritual", "Dark Ritual", 2, 1, "arcane",
		["Arcane", "Volatile"], {"arcane": 50}, 5.0, 150.0, "Ring, apply 3 Hex. Take 2 damage")
	dark_ritual.effect_type = "v5_ring_damage"
	dark_ritual.hex_damage = 3
	dark_ritual.self_damage = 2
	dark_ritual.target_type = "ring"
	dark_ritual.requires_target = true
	_register_card(dark_ritual)
	
	# Spreading Plague - hex spread on kill (Arcane + Control)
	var plague := _create_weapon("spreading_plague", "Spreading Plague", 2, 2, "arcane",
		["Arcane", "Control"], {"arcane": 90}, 5.0, 150.0, "Apply 4 Hex. On kill, spread 2 to ring")
	plague.hex_damage = 4
	plague.effect_params["spread_hex_on_kill"] = 2
	_register_card(plague)


# =============================================================================
# FORTRESS-PRIMARY WEAPONS (6 Cards)
# =============================================================================

func _create_fortress_weapons() -> void:
	# Shield Bash - gain armor (Fortress + Control)
	var shield_bash := _create_weapon("shield_bash", "Shield Bash", 1, 2, "kinetic",
		["Fortress", "Control"], {"kinetic": 50, "armor_start": 20}, 5.0, 150.0, "Gain 2 armor")
	shield_bash.armor_amount = 2
	_register_card(shield_bash)
	
	# Iron Volley - gain armor
	var iron_volley := _create_weapon("iron_volley", "Iron Volley", 2, 2, "kinetic",
		["Fortress"], {"kinetic": 60, "armor_start": 25}, 5.0, 150.0, "Gain 3 armor")
	iron_volley.armor_amount = 3
	_register_card(iron_volley)
	
	# Bulwark Shot - bonus armor per melee enemy (Fortress + Control)
	var bulwark := _create_weapon("bulwark_shot", "Bulwark Shot", 2, 1, "kinetic",
		["Fortress", "Control"], {"kinetic": 40, "armor_start": 35}, 5.0, 150.0, "+1 armor per Melee enemy")
	bulwark.effect_params["armor_per_melee"] = 1
	_register_card(bulwark)
	
	# Fortified Barrage - ring + armor
	var fortified := _create_weapon("fortified_barrage", "Fortified Barrage", 3, 2, "kinetic",
		["Fortress"], {"kinetic": 50, "armor_start": 40}, 5.0, 150.0, "Ring. Gain 4 armor")
	fortified.effect_type = "v5_ring_damage"
	fortified.armor_amount = 4
	fortified.target_type = "ring"
	fortified.requires_target = true
	_register_card(fortified)
	
	# Reactive Shell - (Fortress + Shadow)
	var reactive := _create_weapon("reactive_shell", "Reactive Shell", 2, 2, "kinetic",
		["Fortress", "Shadow"], {"kinetic": 70, "armor_start": 30}, 15.0, 175.0)
	_register_card(reactive)
	
	# Siege Cannon - costs armor (Fortress + Volatile)
	var siege := _create_weapon("siege_cannon", "Siege Cannon", 3, 3, "kinetic",
		["Fortress", "Volatile"], {"kinetic": 80, "armor_start": 50}, 5.0, 150.0, "Costs 2 armor to play")
	siege.effect_params["armor_cost"] = 2
	_register_card(siege)


# =============================================================================
# SHADOW-PRIMARY WEAPONS (6 Cards)
# =============================================================================

func _create_shadow_weapons() -> void:
	# Assassin's Strike - (Shadow + Utility)
	var assassin := _create_weapon("assassins_strike", "Assassin's Strike", 1, 1, "kinetic",
		["Shadow", "Utility"], {"kinetic": 60, "crit_damage": 15}, 20.0, 200.0)
	_register_card(assassin)
	
	# Shadow Bolt
	var shadow_bolt := _create_weapon("shadow_bolt", "Shadow Bolt", 1, 2, "kinetic",
		["Shadow"], {"kinetic": 70, "crit_damage": 10}, 15.0, 175.0)
	_register_card(shadow_bolt)
	
	# Precision Shot - Mid/Far only (Shadow + Kinetic)
	var precision := _create_weapon("precision_shot", "Precision Shot", 2, 2, "kinetic",
		["Shadow", "Kinetic"], {"kinetic": 80, "crit_damage": 20}, 25.0, 200.0, "Mid/Far only")
	precision.target_rings = [2, 3]
	_register_card(precision)
	
	# Backstab - Far only (Shadow + Control)
	var backstab := _create_weapon("backstab", "Backstab", 2, 2, "kinetic",
		["Shadow", "Control"], {"kinetic": 90, "crit_damage": 25}, 30.0, 175.0, "Far only, +2 vs Far")
	backstab.target_rings = [3]
	backstab.effect_params["far_bonus_flat"] = 2
	_register_card(backstab)
	
	# Killing Blow - high crit
	var killing := _create_weapon("killing_blow", "Killing Blow", 3, 2, "kinetic",
		["Shadow"], {"kinetic": 100, "crit_damage": 35}, 35.0, 250.0)
	_register_card(killing)
	
	# Shadow Barrage - hits 3x, each crits separately (Shadow + Utility)
	var barrage := _create_weapon("shadow_barrage", "Shadow Barrage", 2, 1, "kinetic",
		["Shadow", "Utility"], {"kinetic": 50, "crit_damage": 15}, 20.0, 175.0, "", "", 3)
	_register_card(barrage)


# =============================================================================
# UTILITY-PRIMARY WEAPONS (6 Cards)
# =============================================================================

func _create_utility_weapons() -> void:
	# Quick Shot - 0 cost, draw 1 (Utility + Kinetic)
	var quick := _create_weapon("quick_shot", "Quick Shot", 0, 1, "kinetic",
		["Utility", "Kinetic"], {"kinetic": 50, "cards_played": 1}, 5.0, 150.0, "Draw 1")
	quick.cards_to_draw = 1
	_register_card(quick)
	
	# Flurry
	var flurry := _create_weapon("flurry", "Flurry", 1, 1, "kinetic",
		["Utility"], {"kinetic": 40, "cards_played": 2}, 5.0, 150.0)
	_register_card(flurry)
	
	# Chain Strike - next card -1 cost (Utility + Shadow)
	var chain_strike := _create_weapon("chain_strike", "Chain Strike", 1, 2, "kinetic",
		["Utility", "Shadow"], {"kinetic": 60, "cards_played": 1}, 12.0, 175.0, "Next card -1 cost")
	chain_strike.effect_params["next_card_discount"] = 1
	_register_card(chain_strike)
	
	# Momentum - no base, high scaling
	var momentum := _create_weapon("momentum", "Momentum", 1, 0, "kinetic",
		["Utility"], {"kinetic": 30, "cards_played": 3}, 5.0, 150.0)
	_register_card(momentum)
	
	# Rapid Fire - hits 4x (Utility + Kinetic)
	var rapid := _create_weapon("rapid_fire", "Rapid Fire", 2, 0, "kinetic",
		["Utility", "Kinetic"], {"kinetic": 40, "cards_played": 1}, 5.0, 150.0, "", "", 4)
	_register_card(rapid)
	
	# Overdrive - draw 2, discard 1, self damage (Utility + Volatile)
	var overdrive := _create_weapon("overdrive", "Overdrive", 2, 2, "kinetic",
		["Utility", "Volatile"], {"kinetic": 70, "cards_played": 2}, 5.0, 150.0, "Draw 2, discard 1. Take 1 damage")
	overdrive.cards_to_draw = 2
	overdrive.self_damage = 1
	overdrive.effect_params["discard_count"] = 1
	_register_card(overdrive)


# =============================================================================
# CONTROL-PRIMARY WEAPONS (6 Cards)
# =============================================================================

func _create_control_weapons() -> void:
	# Repulsor - push (Control + Kinetic)
	var repulsor := _create_weapon("repulsor", "Repulsor", 1, 2, "kinetic",
		["Control", "Kinetic"], {"kinetic": 60, "barriers": 2}, 5.0, 150.0, "Push target 1 ring")
	repulsor.push_amount = 1
	_register_card(repulsor)
	
	# Barrier Shot - place barrier
	var barrier_shot := _create_weapon("barrier_shot", "Barrier Shot", 2, 2, "kinetic",
		["Control"], {"kinetic": 50, "barriers": 3}, 5.0, 150.0, "Place barrier (2dmg, 2 uses)")
	barrier_shot.effect_params["place_barrier"] = true
	barrier_shot.effect_params["barrier_damage"] = 2
	barrier_shot.effect_params["barrier_uses"] = 2
	_register_card(barrier_shot)
	
	# Lockdown - ring, enemies can't advance (Control + Fortress)
	var lockdown := _create_weapon("lockdown", "Lockdown", 2, 1, "kinetic",
		["Control", "Fortress"], {"kinetic": 40, "barriers": 2}, 5.0, 150.0, "Ring, enemies can't advance")
	lockdown.effect_type = "v5_ring_damage"
	lockdown.effect_params["prevent_advance"] = true
	lockdown.target_type = "ring"
	lockdown.requires_target = true
	_register_card(lockdown)
	
	# Far Strike - bonus vs Far (Control + Shadow)
	var far_strike := _create_weapon("far_strike", "Far Strike", 1, 2, "kinetic",
		["Control", "Shadow"], {"kinetic": 80}, 15.0, 175.0, "+3 vs Far, +2 if no Melee enemies")
	far_strike.effect_params["far_bonus_flat"] = 3
	far_strike.effect_params["no_melee_bonus"] = 2
	_register_card(far_strike)
	
	# Killzone - hits all that moved this turn
	var killzone := _create_weapon("killzone", "Killzone", 3, 2, "kinetic",
		["Control"], {"kinetic": 70, "barriers": 4}, 5.0, 150.0, "Hits all that moved this turn")
	killzone.effect_params["hit_moved_only"] = true
	_register_card(killzone)
	
	# Perimeter (Control + Fortress)
	var perimeter := _create_weapon("perimeter", "Perimeter", 2, 1, "kinetic",
		["Control", "Fortress"], {"kinetic": 40, "barriers": 5}, 5.0, 150.0)
	_register_card(perimeter)


# =============================================================================
# VOLATILE-PRIMARY WEAPONS (6 Cards)
# =============================================================================

func _create_volatile_weapons() -> void:
	# Overcharge - self damage (Volatile + Thermal)
	var overcharge := _create_weapon("overcharge", "Overcharge", 1, 2, "thermal",
		["Volatile", "Thermal"], {"thermal": 80, "missing_hp": 15}, 5.0, 150.0, "Take 2 damage")
	overcharge.self_damage = 2
	_register_card(overcharge)
	
	# Reckless Blast - splash + self damage (Volatile + Thermal)
	var reckless := _create_weapon("reckless_blast", "Reckless Blast", 2, 3, "thermal",
		["Volatile", "Thermal"], {"thermal": 100, "missing_hp": 20}, 5.0, 150.0, "+3 splash. Take 3 damage")
	reckless.splash_damage = 3
	reckless.self_damage = 3
	reckless.effect_type = "splash_damage"
	_register_card(reckless)
	
	# Blood Rocket - ring, self damage, heal on kill (Volatile + Arcane)
	var blood_rocket := _create_weapon("blood_rocket", "Blood Rocket", 2, 2, "thermal",
		["Volatile", "Arcane"], {"thermal": 70, "missing_hp": 25}, 5.0, 150.0, "Ring. Take 2 damage. Heal 1 per kill")
	blood_rocket.effect_type = "v5_ring_damage"
	blood_rocket.self_damage = 2
	blood_rocket.effect_params["heal_per_kill"] = 1
	blood_rocket.target_type = "ring"
	blood_rocket.requires_target = true
	_register_card(blood_rocket)
	
	# Unstable Core - high self damage, no damage if kill
	var unstable := _create_weapon("unstable_core", "Unstable Core", 2, 4, "thermal",
		["Volatile"], {"thermal": 120, "missing_hp": 15}, 5.0, 150.0, "Take 4 damage. Kill = no self-damage")
	unstable.self_damage = 4
	unstable.effect_params["no_self_damage_on_kill"] = true
	_register_card(unstable)
	
	# Kamikaze Swarm - ALL enemies, heavy self damage (Volatile + Thermal)
	var kamikaze := _create_weapon("kamikaze_swarm", "Kamikaze Swarm", 3, 2, "thermal",
		["Volatile", "Thermal"], {"thermal": 80, "missing_hp": 30}, 5.0, 150.0, "ALL enemies. Take 5 damage")
	kamikaze.effect_type = "v5_aoe"
	kamikaze.target_type = "all_enemies"
	kamikaze.self_damage = 5
	_register_card(kamikaze)
	
	# Desperation - (Volatile + Shadow)
	var desperation := _create_weapon("desperation", "Desperation", 1, 1, "thermal",
		["Volatile", "Shadow"], {"thermal": 60, "missing_hp": 40}, 25.0, 200.0)
	_register_card(desperation)


# =============================================================================
# INSTANT CARDS (24 Cards)
# =============================================================================

func _create_instant(id: String, card_name: String, cost: int, rarity: int,
		categories: Array[String], effect_type: String, desc: String) -> CardDef:
	"""Helper to create an instant card."""
	var card := CardDef.new()
	card.card_id = id
	card.card_name = card_name
	card.description = desc
	card.base_cost = cost
	card.rarity = rarity
	card.categories = categories
	card.is_instant_card = true
	card.card_type = "skill"
	card.play_mode = "instant"
	card.effect_type = effect_type
	card.damage_type = "none"
	card.tier = 1  # Instants don't have tiers but need a default
	card.tags = ["skill"]
	return card


func _create_universal_instants() -> void:
	# Bandage - heal 5
	var bandage := _create_instant("bandage", "Bandage", 1, 1, [], "heal", "Heal 5")
	bandage.heal_amount = 5
	_register_card(bandage)
	
	# Med Kit - heal 10
	var medkit := _create_instant("med_kit", "Med Kit", 2, 1, [], "heal", "Heal 10")
	medkit.heal_amount = 10
	_register_card(medkit)
	
	# Stim Pack - +2 energy
	var stim := _create_instant("stim_pack", "Stim Pack", 1, 1, [], "buff", "+2 Energy this turn")
	stim.buff_type = "energy"
	stim.buff_value = 2
	_register_card(stim)
	
	# Tactical Draw - draw 2
	var tactical := _create_instant("tactical_draw", "Tactical Draw", 1, 1, [], "draw_cards", "Draw 2")
	tactical.cards_to_draw = 2
	_register_card(tactical)


func _create_category_instants() -> void:
	# KINETIC
	var focus_fire := _create_instant("focus_fire", "Focus Fire", 1, 1,
		["Kinetic"], "lane_buff", "Next weapon +3 damage")
	focus_fire.lane_buff_type = "next_weapon_effect"
	focus_fire.lane_buff_value = 3
	_register_card(focus_fire)
	
	var reload := _create_instant("reload", "Reload", 1, 2,
		["Kinetic"], "draw_cards", "If hand < 3 cards, draw to 3")
	reload.cards_to_draw = 3
	reload.effect_params["conditional_draw"] = true
	_register_card(reload)
	
	# THERMAL
	var ignite := _create_instant("ignite", "Ignite", 1, 1,
		["Thermal"], "apply_burn", "Apply 4 Burn to target")
	ignite.burn_damage = 4
	ignite.target_type = "random_enemy"
	_register_card(ignite)
	
	var heat_wave := _create_instant("heat_wave", "Heat Wave", 2, 2,
		["Thermal"], "apply_burn_multi", "Apply 2 Burn to ALL enemies")
	heat_wave.burn_damage = 2
	heat_wave.target_type = "all_enemies"
	_register_card(heat_wave)
	
	# ARCANE
	var curse := _create_instant("curse", "Curse", 1, 1,
		["Arcane"], "apply_hex", "Apply 4 Hex to target")
	curse.hex_damage = 4
	curse.target_type = "random_enemy"
	_register_card(curse)
	
	var mass_hex := _create_instant("mass_hex", "Mass Hex", 2, 2,
		["Arcane"], "apply_hex_multi", "Apply 2 Hex to ALL enemies")
	mass_hex.hex_damage = 2
	mass_hex.target_type = "all_enemies"
	_register_card(mass_hex)
	
	# FORTRESS
	var reinforce := _create_instant("reinforce", "Reinforce", 1, 1,
		["Fortress"], "gain_armor", "Gain 5 armor")
	reinforce.armor_amount = 5
	_register_card(reinforce)
	
	var fortify := _create_instant("fortify", "Fortify", 2, 2,
		["Fortress"], "gain_armor", "Gain armor = your ArmorStart stat")
	fortify.effect_params["armor_equals_stat"] = "armor_start"
	_register_card(fortify)
	
	# SHADOW
	var mark_target := _create_instant("mark_target", "Mark Target", 1, 2,
		["Shadow"], "buff", "Next weapon guaranteed crit")
	mark_target.buff_type = "guaranteed_crit"
	_register_card(mark_target)
	
	var setup_kill := _create_instant("setup_kill", "Setup Kill", 2, 2,
		["Shadow"], "buff", "Next weapon +50% crit damage")
	setup_kill.buff_type = "crit_damage_bonus"
	setup_kill.buff_value = 50
	_register_card(setup_kill)
	
	# UTILITY
	var quick_hands := _create_instant("quick_hands", "Quick Hands", 0, 1,
		["Utility"], "draw_cards", "Draw 1")
	quick_hands.cards_to_draw = 1
	_register_card(quick_hands)
	
	var tempo := _create_instant("tempo", "Tempo", 1, 2,
		["Utility"], "draw_cards", "Draw 2. Next card costs 1 less")
	tempo.cards_to_draw = 2
	tempo.effect_params["next_card_discount"] = 1
	_register_card(tempo)
	
	# CONTROL
	var deploy_barrier := _create_instant("deploy_barrier", "Deploy Barrier", 2, 1,
		["Control"], "ring_barrier", "Place barrier (2 dmg, 3 uses) on any ring")
	deploy_barrier.base_damage = 2
	deploy_barrier.effect_params["barrier_uses"] = 3
	deploy_barrier.target_type = "ring"
	deploy_barrier.requires_target = true
	deploy_barrier.target_rings = [0, 1, 2, 3]  # Can target any ring
	_register_card(deploy_barrier)
	
	var hold_line := _create_instant("hold_the_line", "Hold the Line", 2, 2,
		["Control"], "buff", "Enemies can't advance this turn")
	hold_line.buff_type = "prevent_advance"
	_register_card(hold_line)
	
	# VOLATILE
	var adrenaline := _create_instant("adrenaline", "Adrenaline", 1, 1,
		["Volatile"], "buff", "Take 3 damage. +3 Energy this turn")
	adrenaline.self_damage = 3
	adrenaline.buff_type = "energy"
	adrenaline.buff_value = 3
	_register_card(adrenaline)
	
	var pain_threshold := _create_instant("pain_threshold", "Pain Threshold", 1, 1,
		["Volatile"], "draw_cards", "Take 2 damage. Draw 2")
	pain_threshold.self_damage = 2
	pain_threshold.cards_to_draw = 2
	_register_card(pain_threshold)


func _create_dual_category_instants() -> void:
	# Incendiary Rounds (Kinetic + Thermal)
	var incendiary_rounds := _create_instant("incendiary_rounds", "Incendiary Rounds", 1, 2,
		["Kinetic", "Thermal"], "buff", "Next weapon applies 2 Burn")
	incendiary_rounds.buff_type = "weapon_apply_burn"
	incendiary_rounds.burn_damage = 2
	_register_card(incendiary_rounds)
	
	# Cursed Ammo (Kinetic + Arcane)
	var cursed_ammo := _create_instant("cursed_ammo", "Cursed Ammo", 1, 2,
		["Kinetic", "Arcane"], "buff", "Next weapon applies 2 Hex")
	cursed_ammo.buff_type = "weapon_apply_hex"
	cursed_ammo.hex_damage = 2
	_register_card(cursed_ammo)
	
	# Burning Barrier (Control + Thermal)
	var burning_barrier := _create_instant("burning_barrier", "Burning Barrier", 2, 3,
		["Control", "Thermal"], "ring_barrier", "Place barrier (2 dmg, 2 uses) that applies 3 Burn when hit")
	burning_barrier.base_damage = 2
	burning_barrier.burn_damage = 3
	burning_barrier.effect_params["barrier_uses"] = 2
	burning_barrier.target_type = "ring"
	burning_barrier.requires_target = true
	burning_barrier.target_rings = [0, 1, 2, 3]  # Can target any ring
	_register_card(burning_barrier)
	
	# Desperate Strike (Volatile + Shadow)
	var desperate_strike := _create_instant("desperate_strike", "Desperate Strike", 1, 3,
		["Volatile", "Shadow"], "buff", "Next weapon +1 damage per 5 missing HP")
	desperate_strike.buff_type = "missing_hp_damage"
	desperate_strike.effect_params["damage_per_missing_hp"] = 5
	_register_card(desperate_strike)


# =============================================================================
# QUERY FUNCTIONS
# =============================================================================

func get_card(card_id: String) -> CardDef:
	"""Get a card by ID."""
	return cards.get(card_id, null)


func get_all_cards() -> Array:
	"""Get all cards as an array."""
	return cards.values()


func get_weapons() -> Array:
	"""Get all weapon cards."""
	return weapons.duplicate()


func get_instants() -> Array:
	"""Get all instant cards."""
	return instants.duplicate()


func get_cards_by_category(category: String) -> Array:
	"""Get all cards with a specific category."""
	return cards_by_category.get(category, []).duplicate()


func get_cards_by_damage_type(dtype: String) -> Array:
	"""Get all cards with a specific damage type."""
	return cards_by_type.get(dtype, []).duplicate()


func get_cards_by_rarity(rarity: int) -> Array:
	"""Get all cards with a specific rarity."""
	var result: Array = []
	for card: CardDef in cards.values():
		if card.rarity == rarity:
			result.append(card)
	return result


func get_veteran_starter_deck() -> Array:
	"""Get the V5 starter deck entries for Veteran warden."""
	return [
		{"card_id": "pistol", "count": 3, "tier": 1},
		{"card_id": "shotgun", "count": 1, "tier": 1},
		{"card_id": "hex_bolt", "count": 2, "tier": 1},
		{"card_id": "shield_bash", "count": 2, "tier": 1},
		{"card_id": "quick_shot", "count": 2, "tier": 1},
	]
