extends Node
## CardDatabase - V6 Horde Slaughter Card Pool
## ~35 Weapons + ~15 Instants = ~50 total cards
## Multi-hit is CORE - most weapons hit 2+ times
## Simplified to 5 categories: Kinetic, Thermal, Arcane, Volatile, Utility

signal cards_loaded()

var cards: Dictionary = {}  # card_id -> CardDefinition
var cards_by_category: Dictionary = {}  # category -> Array[CardDefinition]
var cards_by_type: Dictionary = {}  # damage_type -> Array[CardDefinition]
var weapons: Array = []  # All weapon cards
var instants: Array = []  # All instant cards

const CardDef = preload("res://scripts/resources/CardDefinition.gd")
const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")


func _ready() -> void:
	_create_v6_cards()
	print("[CardDatabase] V6 Card Pool initialized with ", cards.size(), " cards (",
		weapons.size(), " weapons, ", instants.size(), " instants)")


func _create_v6_cards() -> void:
	"""Create the V6 horde-focused card pool."""
	# Create weapons by category (5 categories, ~35 weapons)
	_create_kinetic_weapons()
	_create_thermal_weapons()
	_create_arcane_weapons()
	_create_volatile_weapons()
	_create_utility_weapons()
	
	# Create instant cards (~15 instants)
	_create_instant_cards()
	
	cards_loaded.emit()


# =============================================================================
# V6 WEAPON CREATION HELPERS
# =============================================================================

func _create_weapon(id: String, card_name: String, cost: int, base: int, damage_type: String,
		categories: Array[String], scaling: Dictionary, crit_chance: float, crit_damage: float,
		hit_count: int = 1, effect: String = "", rarity: int = 1) -> CardDef:
	"""Helper to create a V6 weapon card. Multi-hit is default."""
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
	card.crit_chance_bonus = crit_chance - 5.0  # Base is 5%
	card.crit_damage_bonus = crit_damage - 150.0  # Base is 150%
	
	# Set effect type based on hit count and effect string
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
	card.description = _build_weapon_description(card, effect)
	
	# Store effect info
	if not effect.is_empty():
		card.effect_params["effect_text"] = effect
	
	# Legacy tags
	card.tags = _categories_to_legacy_tags(categories)
	
	return card


func _build_weapon_description(card: CardDef, effect: String) -> String:
	"""Build description string for a weapon."""
	var desc: String = ""
	
	if card.hit_count > 1:
		desc = "Deal {damage} damage %d times." % card.hit_count
	elif card.effect_type == "v5_ring_damage":
		desc = "Deal {damage} damage to a ring."
	elif card.effect_type == "v5_aoe":
		desc = "Deal {damage} damage to ALL enemies."
	else:
		desc = "Deal {damage} damage."
	
	if not effect.is_empty():
		desc += " " + effect
	
	return desc


func _categories_to_legacy_tags(categories: Array[String]) -> Array:
	"""Convert categories to legacy tags."""
	var tags: Array = []
	for cat: String in categories:
		tags.append(TagConstantsClass.category_to_legacy_tag(cat))
	return tags


func _register_card(card: CardDef) -> void:
	"""Register a card in all indexes."""
	cards[card.card_id] = card
	
	for category: String in card.categories:
		if not cards_by_category.has(category):
			cards_by_category[category] = []
		cards_by_category[category].append(card)
	
	if not cards_by_type.has(card.damage_type):
		cards_by_type[card.damage_type] = []
	cards_by_type[card.damage_type].append(card)
	
	if card.is_instant_card:
		instants.append(card)
	else:
		weapons.append(card)


# =============================================================================
# KINETIC WEAPONS (10 Cards) - Raw damage, armor shred via multi-hit
# =============================================================================

func _create_kinetic_weapons() -> void:
	# Pistol - starter weapon, 2 hits
	var pistol := _create_weapon("pistol", "Pistol", 1, 2, "kinetic",
		["Kinetic"], {"kinetic": 80}, 5.0, 150.0, 2)
	_register_card(pistol)
	
	# SMG - rapid fire, 4 hits
	var smg := _create_weapon("smg", "SMG", 1, 1, "kinetic",
		["Kinetic"], {"kinetic": 50}, 5.0, 150.0, 4)
	smg.can_repeat_target = true
	_register_card(smg)
	
	# Assault Rifle - reliable 3 hits
	var assault := _create_weapon("assault_rifle", "Assault Rifle", 2, 2, "kinetic",
		["Kinetic"], {"kinetic": 70}, 5.0, 150.0, 3)
	_register_card(assault)
	
	# Minigun - bullet hose, 8 hits (armor shredder)
	var minigun := _create_weapon("minigun", "Minigun", 3, 1, "kinetic",
		["Kinetic"], {"kinetic": 40}, 5.0, 150.0, 8)
	minigun.can_repeat_target = true
	_register_card(minigun)
	
	# Shotgun - 3 hits with splash
	var shotgun := _create_weapon("shotgun", "Shotgun", 2, 2, "kinetic",
		["Kinetic"], {"kinetic": 60}, 5.0, 150.0, 3, "+2 splash")
	shotgun.splash_damage = 2
	_register_card(shotgun)
	
	# Sniper - single hit, high crit
	var sniper := _create_weapon("sniper", "Sniper Rifle", 2, 6, "kinetic",
		["Kinetic"], {"kinetic": 120}, 20.0, 200.0, 1, "High crit chance")
	_register_card(sniper)
	
	# Burst Fire - 3 fast hits, cheap
	var burst := _create_weapon("burst_fire", "Burst Fire", 1, 2, "kinetic",
		["Kinetic"], {"kinetic": 60}, 8.0, 160.0, 3)
	_register_card(burst)
	
	# Heavy Rifle - 2 hits, high damage
	var heavy := _create_weapon("heavy_rifle", "Heavy Rifle", 2, 4, "kinetic",
		["Kinetic"], {"kinetic": 100}, 5.0, 150.0, 2)
	_register_card(heavy)
	
	# Railgun - 1 hit, ignores armor
	var railgun := _create_weapon("railgun", "Railgun", 3, 10, "kinetic",
		["Kinetic"], {"kinetic": 150}, 10.0, 175.0, 1, "Ignores armor")
	railgun.effect_params["ignore_armor"] = true
	_register_card(railgun)
	
	# Machine Pistol - 5 hits, budget option
	var machine := _create_weapon("machine_pistol", "Machine Pistol", 1, 1, "kinetic",
		["Kinetic"], {"kinetic": 40}, 5.0, 150.0, 5)
	machine.can_repeat_target = true
	_register_card(machine)


# =============================================================================
# THERMAL WEAPONS (7 Cards) - Burn, AOE, ring damage
# =============================================================================

func _create_thermal_weapons() -> void:
	# Flamethrower - 3 hits + burn
	var flame := _create_weapon("flamethrower", "Flamethrower", 2, 2, "thermal",
		["Thermal"], {"thermal": 70}, 5.0, 150.0, 3, "Apply 2 Burn")
	flame.burn_damage = 2
	flame.can_repeat_target = true
	_register_card(flame)
	
	# Firebomb - ring damage + burn
	var firebomb := _create_weapon("firebomb", "Firebomb", 2, 3, "thermal",
		["Thermal"], {"thermal": 80}, 5.0, 150.0, 1, "Ring. Apply 3 Burn each")
	firebomb.effect_type = "v5_ring_damage"
	firebomb.burn_damage = 3
	firebomb.target_type = "ring"
	firebomb.requires_target = true
	_register_card(firebomb)
	
	# Rocket Launcher - splash damage
	var rocket := _create_weapon("rocket", "Rocket Launcher", 3, 5, "thermal",
		["Thermal"], {"thermal": 100}, 5.0, 150.0, 1, "+4 splash to group")
	rocket.splash_damage = 4
	rocket.effect_type = "splash_damage"
	_register_card(rocket)
	
	# Napalm - ALL enemies + burn
	var napalm := _create_weapon("napalm", "Napalm Strike", 3, 2, "thermal",
		["Thermal"], {"thermal": 60}, 5.0, 150.0, 1, "ALL enemies. Apply 2 Burn")
	napalm.effect_type = "v5_aoe"
	napalm.target_type = "all_enemies"
	napalm.burn_damage = 2
	_register_card(napalm)
	
	# Incendiary - 2 hits + heavy burn
	var incendiary := _create_weapon("incendiary", "Incendiary Rounds", 2, 2, "thermal",
		["Thermal"], {"thermal": 70}, 5.0, 150.0, 2, "Apply 4 Burn")
	incendiary.burn_damage = 4
	_register_card(incendiary)
	
	# Molotov - cheap ring burn
	var molotov := _create_weapon("molotov", "Molotov", 1, 2, "thermal",
		["Thermal"], {"thermal": 50}, 5.0, 150.0, 1, "Ring. Apply 2 Burn each")
	molotov.effect_type = "v5_ring_damage"
	molotov.burn_damage = 2
	molotov.target_type = "ring"
	molotov.requires_target = true
	_register_card(molotov)
	
	# Inferno - heavy AOE
	var inferno := _create_weapon("inferno", "Inferno", 3, 4, "thermal",
		["Thermal"], {"thermal": 90}, 5.0, 150.0, 1, "ALL enemies")
	inferno.effect_type = "v5_aoe"
	inferno.target_type = "all_enemies"
	_register_card(inferno)


# =============================================================================
# ARCANE WEAPONS (8 Cards) - Hex, execute, lifesteal
# =============================================================================

func _create_arcane_weapons() -> void:
	# Hex Bolt - 2 hits + hex
	var hex_bolt := _create_weapon("hex_bolt", "Hex Bolt", 1, 2, "arcane",
		["Arcane"], {"arcane": 70}, 5.0, 150.0, 2, "Apply 3 Hex")
	hex_bolt.hex_damage = 3
	_register_card(hex_bolt)
	
	# Curse - 3 hits + hex
	var curse := _create_weapon("curse", "Curse", 2, 2, "arcane",
		["Arcane"], {"arcane": 80}, 5.0, 150.0, 3, "Apply 4 Hex")
	curse.hex_damage = 4
	_register_card(curse)
	
	# Soul Drain - 2 hits + heal
	var soul := _create_weapon("soul_drain", "Soul Drain", 2, 3, "arcane",
		["Arcane"], {"arcane": 90}, 5.0, 150.0, 2, "Heal 3")
	soul.heal_amount = 3
	_register_card(soul)
	
	# Void Strike - execute effect
	var void_strike := _create_weapon("void_strike", "Void Strike", 2, 4, "arcane",
		["Arcane"], {"arcane": 100}, 5.0, 150.0, 1, "Apply Execute 4 HP")
	void_strike.effect_type = "apply_execute"
	void_strike.effect_params["execute_threshold"] = 4
	_register_card(void_strike)
	
	# Mind Shatter - 4 hits
	var shatter := _create_weapon("mind_shatter", "Mind Shatter", 2, 2, "arcane",
		["Arcane"], {"arcane": 60}, 5.0, 150.0, 4)
	_register_card(shatter)
	
	# Arcane Barrage - 5 hits
	var barrage := _create_weapon("arcane_barrage", "Arcane Barrage", 3, 2, "arcane",
		["Arcane"], {"arcane": 50}, 5.0, 150.0, 5)
	_register_card(barrage)
	
	# Death Mark - apply execute to multiple
	var death_mark := _create_weapon("death_mark", "Death Mark", 2, 2, "arcane",
		["Arcane"], {"arcane": 70}, 5.0, 150.0, 3, "Apply Execute 3 HP each")
	death_mark.effect_type = "apply_execute"
	death_mark.effect_params["execute_threshold"] = 3
	_register_card(death_mark)
	
	# Life Siphon - cheap heal
	var siphon := _create_weapon("life_siphon", "Life Siphon", 1, 2, "arcane",
		["Arcane"], {"arcane": 60}, 5.0, 150.0, 2, "Heal 2")
	siphon.heal_amount = 2
	_register_card(siphon)


# =============================================================================
# VOLATILE WEAPONS (5 Cards) - High risk/reward, self-damage
# =============================================================================

func _create_volatile_weapons() -> void:
	# Blood Cannon - 4 hits + self damage
	var blood := _create_weapon("blood_cannon", "Blood Cannon", 2, 3, "thermal",
		["Volatile"], {"thermal": 80, "missing_hp": 20}, 5.0, 150.0, 4, "Take 3 damage")
	blood.self_damage = 3
	blood.can_repeat_target = true
	_register_card(blood)
	
	# Pain Spike - 3 hits with high damage
	var pain := _create_weapon("pain_spike", "Pain Spike", 2, 4, "thermal",
		["Volatile"], {"thermal": 90, "missing_hp": 25}, 5.0, 150.0, 3)
	_register_card(pain)
	
	# Chaos Bolt - 6 random hits
	var chaos := _create_weapon("chaos_bolt", "Chaos Bolt", 2, 2, "thermal",
		["Volatile"], {"thermal": 60, "missing_hp": 15}, 10.0, 175.0, 6, "Random targets")
	_register_card(chaos)
	
	# Berserker Strike - scales with missing HP
	var berserker := _create_weapon("berserker", "Berserker Strike", 2, 3, "thermal",
		["Volatile"], {"thermal": 50, "missing_hp": 50}, 15.0, 175.0, 3, "+1 dmg per 5 missing HP")
	_register_card(berserker)
	
	# Overcharge - 5 hits, costs HP
	var overcharge := _create_weapon("overcharge", "Overcharge", 1, 2, "thermal",
		["Volatile"], {"thermal": 70, "missing_hp": 20}, 5.0, 150.0, 5, "Take 4 damage")
	overcharge.self_damage = 4
	overcharge.can_repeat_target = true
	_register_card(overcharge)


# =============================================================================
# UTILITY WEAPONS (5 Cards) - Draw, energy, support
# =============================================================================

func _create_utility_weapons() -> void:
	# Quick Shot - 2 hits, draw 1
	var quick := _create_weapon("quick_shot", "Quick Shot", 0, 1, "kinetic",
		["Utility"], {"kinetic": 40, "cards_played": 1}, 5.0, 150.0, 2, "Draw 1")
	quick.cards_to_draw = 1
	_register_card(quick)
	
	# Scanner - 2 hits, next card +2 damage
	var scanner := _create_weapon("scanner", "Scanner", 1, 2, "kinetic",
		["Utility"], {"kinetic": 50}, 5.0, 150.0, 2, "Next weapon +2 damage")
	scanner.effect_params["next_weapon_bonus"] = 2
	_register_card(scanner)
	
	# Rapid Fire - 4 hits, cheap
	var rapid := _create_weapon("rapid_fire", "Rapid Fire", 1, 1, "kinetic",
		["Utility"], {"kinetic": 40}, 5.0, 150.0, 4)
	rapid.can_repeat_target = true
	_register_card(rapid)
	
	# Precision Strike - 1 hit, guaranteed crit
	var precision := _create_weapon("precision", "Precision Strike", 2, 4, "kinetic",
		["Utility"], {"kinetic": 80}, 100.0, 200.0, 1, "Always crits")
	_register_card(precision)
	
	# Energy Siphon - 2 hits, +1 energy
	var siphon := _create_weapon("energy_siphon", "Energy Siphon", 1, 2, "kinetic",
		["Utility"], {"kinetic": 50}, 5.0, 150.0, 2, "+1 Energy")
	siphon.effect_params["grant_energy"] = 1
	_register_card(siphon)


# =============================================================================
# INSTANT CARDS (15 Cards) - Support, buffs, status
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
	card.tier = 1
	card.tags = ["skill"]
	return card


func _create_instant_cards() -> void:
	# === DAMAGE SUPPORT (5) ===
	
	# Amplify - +3 damage to all weapons this turn
	var amplify := _create_instant("amplify", "Amplify", 1, 1, [], "lane_buff", "+3 damage to all weapons this turn")
	amplify.lane_buff_type = "all_weapons_bonus"
	amplify.lane_buff_value = 3
	_register_card(amplify)
	
	# Focus Fire - next weapon +3 hits
	var focus := _create_instant("focus_fire", "Focus Fire", 1, 2, [], "buff", "Next weapon +3 hits")
	focus.buff_type = "extra_hits"
	focus.buff_value = 3
	_register_card(focus)
	
	# Execute Order - apply Execute 5 to 3 enemies
	var execute := _create_instant("execute_order", "Execute Order", 2, 2, ["Arcane"], "apply_execute", "Apply Execute 5 HP to 3 enemies")
	execute.effect_params["execute_threshold"] = 5
	execute.target_count = 3
	execute.target_type = "random_enemy"
	_register_card(execute)
	
	# Ripple Charge - next kill triggers ripple
	var ripple := _create_instant("ripple_charge", "Ripple Charge", 1, 2, [], "buff", "Next kill: 3 damage to group")
	ripple.buff_type = "ripple_on_kill"
	ripple.buff_value = 3
	_register_card(ripple)
	
	# Shred Armor - strip 3 armor from all enemies
	var shred := _create_instant("shred_armor", "Shred Armor", 1, 1, ["Kinetic"], "buff", "All enemies -3 armor")
	shred.buff_type = "shred_armor"
	shred.buff_value = 3
	_register_card(shred)
	
	# === DEFENSE (4) ===
	
	# Barrier - place barrier on ring
	var barrier := _create_instant("barrier", "Barrier", 2, 1, [], "ring_barrier", "Place barrier (3 dmg, 2 uses)")
	barrier.base_damage = 3
	barrier.effect_params["barrier_uses"] = 2
	barrier.target_type = "ring"
	barrier.requires_target = true
	barrier.target_rings = [0, 1, 2, 3]
	_register_card(barrier)
	
	# Armor Up - gain 5 armor
	var armor := _create_instant("armor_up", "Armor Up", 1, 1, [], "gain_armor", "Gain 5 armor")
	armor.armor_amount = 5
	_register_card(armor)
	
	# Heal - restore 8 HP
	var heal := _create_instant("heal", "Heal", 1, 1, [], "heal", "Restore 8 HP")
	heal.heal_amount = 8
	_register_card(heal)
	
	# Shield Wall - +3 armor, draw 1
	var wall := _create_instant("shield_wall", "Shield Wall", 2, 2, [], "gain_armor", "Gain 3 armor. Draw 1")
	wall.armor_amount = 3
	wall.cards_to_draw = 1
	_register_card(wall)
	
	# === ECONOMY/TEMPO (3) ===
	
	# Reload - draw 3 cards
	var reload := _create_instant("reload", "Reload", 1, 1, [], "draw_cards", "Draw 3")
	reload.cards_to_draw = 3
	_register_card(reload)
	
	# Surge - +2 energy this turn
	var surge := _create_instant("surge", "Surge", 0, 1, [], "buff", "+2 Energy this turn")
	surge.buff_type = "energy"
	surge.buff_value = 2
	_register_card(surge)
	
	# Scavenge - +8 scrap
	var scavenge := _create_instant("scavenge", "Scavenge", 1, 2, [], "buff", "Gain 8 scrap")
	scavenge.buff_type = "scrap"
	scavenge.buff_value = 8
	_register_card(scavenge)
	
	# === STATUS (3) ===
	
	# Mass Hex - apply 3 hex to all enemies
	var mass_hex := _create_instant("mass_hex", "Mass Hex", 2, 2, ["Arcane"], "apply_hex_multi", "Apply 3 Hex to ALL enemies")
	mass_hex.hex_damage = 3
	mass_hex.target_type = "all_enemies"
	_register_card(mass_hex)
	
	# Ignite - apply 4 burn to ring
	var ignite := _create_instant("ignite", "Ignite", 1, 1, ["Thermal"], "apply_burn", "Apply 4 Burn to ring")
	ignite.burn_damage = 4
	ignite.target_type = "ring"
	ignite.requires_target = true
	ignite.target_rings = [0, 1, 2, 3]
	_register_card(ignite)
	
	# Weaken - enemies in ring take +2 damage
	var weaken := _create_instant("weaken", "Weaken", 1, 1, ["Arcane"], "buff", "Enemies in ring take +2 damage")
	weaken.buff_type = "ring_vulnerability"
	weaken.buff_value = 2
	weaken.target_type = "ring"
	weaken.requires_target = true
	weaken.target_rings = [0, 1, 2, 3]
	_register_card(weaken)


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
	"""Get the V6 starter deck - start with pistol."""
	return [
		{"card_id": "pistol", "count": 1, "tier": 1},
	]
