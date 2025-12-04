extends Node
## CardDatabase - V3 Card Pool for Staging System
## All cards are one-shot (discard after use)
## Designed for "queue and execute" combat lane mechanics

signal cards_loaded()

var cards: Dictionary = {}  # card_id -> CardDefinition
var cards_by_tag: Dictionary = {}
var cards_by_type: Dictionary = {}

const CardDef = preload("res://scripts/resources/CardDefinition.gd")


func _ready() -> void:
	_create_v3_cards()
	print("[CardDatabase] V3 Staging System initialized with ", cards.size(), " cards")


func _create_v3_cards() -> void:
	"""Create the V3 card pool for staging system."""
	_create_v3_starter_deck()
	_create_v3_weapons()
	_create_v3_buffs()
	_create_v3_utility()
	_create_v3_defense()
	cards_loaded.emit()


# =============================================================================
# V3 STARTER DECK - 10 cards for Veteran Warden
# =============================================================================

func _create_v3_starter_deck() -> void:
	"""Create starter deck cards - basic versions of each mechanic."""
	
	# Pistol x2 - basic gun, random target
	var pistol := CardDef.new()
	pistol.card_id = "pistol"
	pistol.card_name = "Pistol"
	pistol.description = "Deal {damage} damage to a random enemy."
	pistol.card_type = "weapon"
	pistol.effect_type = "instant_damage"
	pistol.tags = ["gun", "single_target"]
	pistol.base_cost = 1
	pistol.base_damage = 4
	pistol.target_type = "random_enemy"
	pistol.target_rings = [0, 1, 2, 3]
	pistol.rarity = 1
	_register_card(pistol)
	
	# Shotgun - splash damage to group
	var shotgun := CardDef.new()
	shotgun.card_id = "shotgun"
	shotgun.card_name = "Shotgun"
	shotgun.description = "Deal {damage} damage to a target, {splash} splash to its group."
	shotgun.card_type = "weapon"
	shotgun.effect_type = "splash_damage"
	shotgun.tags = ["gun", "splash", "aoe"]
	shotgun.base_cost = 2
	shotgun.base_damage = 3
	shotgun.splash_damage = 2
	shotgun.target_type = "random_enemy"
	shotgun.target_rings = [0, 1, 2]
	shotgun.rarity = 1
	_register_card(shotgun)
	
	# Gun Amplifier - lane buff (INSTANT - buffs cards in lane immediately)
	var gun_amplifier := CardDef.new()
	gun_amplifier.card_id = "gun_amplifier"
	gun_amplifier.card_name = "Gun Amplifier"
	gun_amplifier.description = "All gun cards in lane gain +{lane_buff_value} damage."
	gun_amplifier.card_type = "buff"
	gun_amplifier.play_mode = "instant"
	gun_amplifier.effect_type = "lane_buff"
	gun_amplifier.tags = ["buff", "gun_support"]
	gun_amplifier.base_cost = 1
	gun_amplifier.lane_buff_type = "gun_damage"
	gun_amplifier.lane_buff_value = 2
	gun_amplifier.lane_buff_tag_filter = "gun"
	gun_amplifier.rarity = 1
	_register_card(gun_amplifier)
	
	# Iron Shell x2 - basic armor (INSTANT)
	var iron_shell := CardDef.new()
	iron_shell.card_id = "iron_shell"
	iron_shell.card_name = "Iron Shell"
	iron_shell.description = "Gain {armor} Armor."
	iron_shell.card_type = "defense"
	iron_shell.play_mode = "instant"
	iron_shell.effect_type = "gain_armor"
	iron_shell.tags = ["defense", "armor"]
	iron_shell.base_cost = 1
	iron_shell.armor_amount = 4
	iron_shell.target_type = "self"
	iron_shell.rarity = 1
	_register_card(iron_shell)
	
	# Hex Bolt - apply hex to single target
	var hex_bolt := CardDef.new()
	hex_bolt.card_id = "hex_bolt"
	hex_bolt.card_name = "Hex Bolt"
	hex_bolt.description = "Apply {hex_damage} Hex to a random enemy."
	hex_bolt.card_type = "hex"
	hex_bolt.effect_type = "apply_hex"
	hex_bolt.tags = ["hex", "single_target"]
	hex_bolt.base_cost = 1
	hex_bolt.hex_damage = 4
	hex_bolt.target_type = "random_enemy"
	hex_bolt.target_rings = [0, 1, 2, 3]
	hex_bolt.target_count = 1
	hex_bolt.rarity = 1
	_register_card(hex_bolt)
	
	# Quick Draw x2 - draw cards (INSTANT)
	var quick_draw := CardDef.new()
	quick_draw.card_id = "quick_draw"
	quick_draw.card_name = "Quick Draw"
	quick_draw.description = "Draw 2 cards."
	quick_draw.card_type = "skill"
	quick_draw.play_mode = "instant"
	quick_draw.effect_type = "draw_cards"
	quick_draw.tags = ["skill", "draw"]
	quick_draw.base_cost = 1
	quick_draw.cards_to_draw = 2
	quick_draw.target_type = "self"
	quick_draw.rarity = 1
	_register_card(quick_draw)
	
	# Shove - push enemy (INSTANT)
	var shove := CardDef.new()
	shove.card_id = "shove"
	shove.card_name = "Shove"
	shove.description = "Push an enemy in Melee/Close back 1 ring."
	shove.card_type = "skill"
	shove.play_mode = "instant"
	shove.effect_type = "push_enemies"
	shove.tags = ["skill", "utility", "ring_control"]
	shove.base_cost = 1
	shove.push_amount = 1
	shove.target_type = "random_enemy"
	shove.target_rings = [0, 1]
	shove.target_count = 1
	shove.rarity = 1
	_register_card(shove)


# =============================================================================
# V3 WEAPONS - Damage dealing cards
# =============================================================================

func _create_v3_weapons() -> void:
	"""Create weapon cards for the V3 system."""
	
	# Heavy Pistol - stronger basic gun
	var heavy_pistol := CardDef.new()
	heavy_pistol.card_id = "heavy_pistol"
	heavy_pistol.card_name = "Heavy Pistol"
	heavy_pistol.description = "Deal {damage} damage to a random enemy."
	heavy_pistol.card_type = "weapon"
	heavy_pistol.effect_type = "instant_damage"
	heavy_pistol.tags = ["gun", "single_target"]
	heavy_pistol.base_cost = 2
	heavy_pistol.base_damage = 7
	heavy_pistol.target_type = "random_enemy"
	heavy_pistol.target_rings = [0, 1, 2, 3]
	heavy_pistol.rarity = 2
	_register_card(heavy_pistol)
	
	# Assault Rifle - hits multiple targets
	var assault_rifle := CardDef.new()
	assault_rifle.card_id = "assault_rifle"
	assault_rifle.card_name = "Assault Rifle"
	assault_rifle.description = "Deal {damage} damage to 3 random enemies."
	assault_rifle.card_type = "weapon"
	assault_rifle.effect_type = "scatter_damage"
	assault_rifle.tags = ["gun", "multi_target", "aoe"]
	assault_rifle.base_cost = 2
	assault_rifle.base_damage = 2
	assault_rifle.target_count = 3
	assault_rifle.target_type = "random_enemy"
	assault_rifle.target_rings = [0, 1, 2, 3]
	assault_rifle.rarity = 2
	_register_card(assault_rifle)
	
	# Sniper Rifle - high damage, Far ring focus
	var sniper_rifle := CardDef.new()
	sniper_rifle.card_id = "sniper_rifle"
	sniper_rifle.card_name = "Sniper Rifle"
	sniper_rifle.description = "Deal {damage} damage to a random enemy in Mid/Far."
	sniper_rifle.card_type = "weapon"
	sniper_rifle.effect_type = "instant_damage"
	sniper_rifle.tags = ["gun", "sniper", "single_target"]
	sniper_rifle.base_cost = 2
	sniper_rifle.base_damage = 10
	sniper_rifle.target_type = "random_enemy"
	sniper_rifle.target_rings = [2, 3]
	sniper_rifle.rarity = 2
	_register_card(sniper_rifle)
	
	# Armored Tank - scaling card, hits last damaged, gains armor
	var armored_tank := CardDef.new()
	armored_tank.card_id = "armored_tank"
	armored_tank.card_name = "Armored Tank"
	armored_tank.description = "Deal {damage} damage to last damaged enemy. +{scaling} per gun fired before this. Gain 2 armor."
	armored_tank.card_type = "weapon"
	armored_tank.effect_type = "scaling_damage"
	armored_tank.tags = ["gun", "defense", "scaling"]
	armored_tank.base_cost = 2
	armored_tank.base_damage = 2
	armored_tank.armor_amount = 2
	armored_tank.scales_with_lane = true
	armored_tank.scaling_type = "guns_fired"
	armored_tank.scaling_value = 2
	armored_tank.target_type = "last_damaged"
	armored_tank.target_rings = [0, 1, 2, 3]
	armored_tank.rarity = 3
	_register_card(armored_tank)
	
	# Chain Gun - fires many weak shots
	var chain_gun := CardDef.new()
	chain_gun.card_id = "chain_gun"
	chain_gun.card_name = "Chain Gun"
	chain_gun.description = "Deal {damage} damage to 5 random enemies (can hit same enemy multiple times)."
	chain_gun.card_type = "weapon"
	chain_gun.effect_type = "scatter_damage"
	chain_gun.tags = ["gun", "multi_target", "rapid_fire"]
	chain_gun.base_cost = 2
	chain_gun.base_damage = 1
	chain_gun.target_count = 5
	chain_gun.target_type = "random_enemy"
	chain_gun.target_rings = [0, 1, 2, 3]
	chain_gun.rarity = 2
	_register_card(chain_gun)
	
	# Rocket Launcher - AoE explosive
	var rocket_launcher := CardDef.new()
	rocket_launcher.card_id = "rocket_launcher"
	rocket_launcher.card_name = "Rocket Launcher"
	rocket_launcher.description = "Deal {damage} damage to all enemies in Close ring."
	rocket_launcher.card_type = "weapon"
	rocket_launcher.effect_type = "instant_damage"
	rocket_launcher.tags = ["gun", "explosive", "aoe"]
	rocket_launcher.base_cost = 3
	rocket_launcher.base_damage = 4
	rocket_launcher.target_type = "ring"
	rocket_launcher.target_rings = [1]
	rocket_launcher.rarity = 3
	_register_card(rocket_launcher)
	
	# Beam Cannon - chains through hexed enemies
	var beam_cannon := CardDef.new()
	beam_cannon.card_id = "beam_cannon"
	beam_cannon.card_name = "Beam Cannon"
	beam_cannon.description = "Deal {damage} damage chaining to up to 3 enemies (prefers hexed)."
	beam_cannon.card_type = "weapon"
	beam_cannon.effect_type = "beam_damage"
	beam_cannon.tags = ["gun", "beam", "hex_synergy"]
	beam_cannon.base_cost = 2
	beam_cannon.base_damage = 3
	beam_cannon.chain_count = 3
	beam_cannon.target_type = "random_enemy"
	beam_cannon.target_rings = [0, 1, 2, 3]
	beam_cannon.rarity = 3
	_register_card(beam_cannon)
	
	# Piercing Shot - overkill flows to next target
	var piercing_shot := CardDef.new()
	piercing_shot.card_id = "piercing_shot"
	piercing_shot.card_name = "Piercing Shot"
	piercing_shot.description = "Deal {damage} damage. Overkill flows to next enemy (50% overflow)."
	piercing_shot.card_type = "weapon"
	piercing_shot.effect_type = "piercing_damage"
	piercing_shot.tags = ["gun", "piercing", "single_target"]
	piercing_shot.base_cost = 2
	piercing_shot.base_damage = 8
	piercing_shot.effect_params = {"overflow_percent": 50}
	piercing_shot.target_type = "random_enemy"
	piercing_shot.target_rings = [0, 1, 2, 3]
	piercing_shot.rarity = 2
	_register_card(piercing_shot)
	
	# Finisher - scales with cards already played
	var finisher := CardDef.new()
	finisher.card_id = "finisher"
	finisher.card_name = "Finisher"
	finisher.description = "Deal {damage} damage. +{scaling} per card played before this."
	finisher.card_type = "weapon"
	finisher.effect_type = "scaling_damage"
	finisher.tags = ["gun", "scaling", "single_target"]
	finisher.base_cost = 1
	finisher.base_damage = 1
	finisher.scales_with_lane = true
	finisher.scaling_type = "cards_played"
	finisher.scaling_value = 2
	finisher.target_type = "random_enemy"
	finisher.target_rings = [0, 1, 2, 3]
	finisher.rarity = 2
	_register_card(finisher)
	
	# Hex Strike - damage + apply hex
	var hex_strike := CardDef.new()
	hex_strike.card_id = "hex_strike"
	hex_strike.card_name = "Hex Strike"
	hex_strike.description = "Deal {damage} damage and apply {hex_damage} Hex to target."
	hex_strike.card_type = "weapon"
	hex_strike.effect_type = "damage_and_hex"
	hex_strike.tags = ["gun", "hex", "single_target"]
	hex_strike.base_cost = 2
	hex_strike.base_damage = 3
	hex_strike.hex_damage = 3
	hex_strike.target_type = "random_enemy"
	hex_strike.target_rings = [0, 1, 2, 3]
	hex_strike.rarity = 2
	_register_card(hex_strike)


# =============================================================================
# V3 BUFFS - Lane buff and support cards
# =============================================================================

func _create_v3_buffs() -> void:
	"""Create lane buff and support cards."""
	
	# Power Surge - all cards get damage (INSTANT)
	var power_surge := CardDef.new()
	power_surge.card_id = "power_surge"
	power_surge.card_name = "Power Surge"
	power_surge.description = "All damage-dealing cards in lane gain +{lane_buff_value} damage."
	power_surge.card_type = "buff"
	power_surge.play_mode = "instant"
	power_surge.effect_type = "lane_buff"
	power_surge.tags = ["buff", "damage_boost"]
	power_surge.base_cost = 2
	power_surge.lane_buff_type = "all_damage"
	power_surge.lane_buff_value = 3
	power_surge.lane_buff_tag_filter = ""
	power_surge.rarity = 2
	_register_card(power_surge)
	
	# Rapid Fire Protocol - doubles next gun's effect (INSTANT)
	var rapid_fire := CardDef.new()
	rapid_fire.card_id = "rapid_fire"
	rapid_fire.card_name = "Rapid Fire Protocol"
	rapid_fire.description = "Next gun card in lane fires twice."
	rapid_fire.card_type = "buff"
	rapid_fire.play_mode = "instant"
	rapid_fire.effect_type = "lane_buff"
	rapid_fire.tags = ["buff", "gun_support"]
	rapid_fire.base_cost = 1
	rapid_fire.lane_buff_type = "double_fire"
	rapid_fire.lane_buff_value = 1
	rapid_fire.lane_buff_tag_filter = "gun"
	rapid_fire.rarity = 3
	_register_card(rapid_fire)
	
	# Hex Infusion - apply hex to all gun targets (INSTANT)
	var hex_infusion := CardDef.new()
	hex_infusion.card_id = "hex_infusion"
	hex_infusion.card_name = "Hex Infusion"
	hex_infusion.description = "All gun cards in lane also apply 2 Hex to their targets."
	hex_infusion.card_type = "buff"
	hex_infusion.play_mode = "instant"
	hex_infusion.effect_type = "lane_buff"
	hex_infusion.tags = ["buff", "hex", "gun_support"]
	hex_infusion.base_cost = 1
	hex_infusion.lane_buff_type = "gun_damage"  # Uses damage buff type but adds hex effect
	hex_infusion.lane_buff_value = 0  # No damage bonus
	hex_infusion.effect_params = {"add_hex": 2}
	hex_infusion.lane_buff_tag_filter = "gun"
	hex_infusion.rarity = 2
	_register_card(hex_infusion)
	
	# Armor Plating - cards gain armor effect (INSTANT)
	var armor_plating := CardDef.new()
	armor_plating.card_id = "armor_plating"
	armor_plating.card_name = "Armor Plating"
	armor_plating.description = "All gun cards in lane grant 1 Armor when they execute."
	armor_plating.card_type = "buff"
	armor_plating.play_mode = "instant"
	armor_plating.effect_type = "lane_buff"
	armor_plating.tags = ["buff", "defense", "gun_support"]
	armor_plating.base_cost = 1
	armor_plating.lane_buff_type = "armor_gain"
	armor_plating.lane_buff_value = 1
	armor_plating.lane_buff_tag_filter = "gun"
	armor_plating.rarity = 2
	_register_card(armor_plating)


# =============================================================================
# V3 UTILITY - Draw, energy, etc.
# =============================================================================

func _create_v3_utility() -> void:
	"""Create utility and skill cards."""
	
	# Double Time - draw more (INSTANT)
	var double_time := CardDef.new()
	double_time.card_id = "double_time"
	double_time.card_name = "Double Time"
	double_time.description = "Draw 3 cards."
	double_time.card_type = "skill"
	double_time.play_mode = "instant"
	double_time.effect_type = "draw_cards"
	double_time.tags = ["skill", "draw"]
	double_time.base_cost = 2
	double_time.cards_to_draw = 3
	double_time.target_type = "self"
	double_time.rarity = 2
	_register_card(double_time)
	
	# Push Back - push multiple enemies (INSTANT)
	var push_back := CardDef.new()
	push_back.card_id = "push_back"
	push_back.card_name = "Push Back"
	push_back.description = "Push all enemies in Melee back 1 ring."
	push_back.card_type = "skill"
	push_back.play_mode = "instant"
	push_back.effect_type = "push_enemies"
	push_back.tags = ["skill", "utility", "ring_control"]
	push_back.base_cost = 2
	push_back.push_amount = 1
	push_back.target_type = "ring"
	push_back.target_rings = [0]
	push_back.rarity = 2
	_register_card(push_back)
	
	# Hex Cloud - apply hex to all enemies
	var hex_cloud := CardDef.new()
	hex_cloud.card_id = "hex_cloud"
	hex_cloud.card_name = "Hex Cloud"
	hex_cloud.description = "Apply {hex_damage} Hex to all enemies."
	hex_cloud.card_type = "hex"
	hex_cloud.effect_type = "apply_hex"
	hex_cloud.tags = ["hex", "aoe"]
	hex_cloud.base_cost = 2
	hex_cloud.hex_damage = 2
	hex_cloud.target_type = "all_enemies"
	hex_cloud.rarity = 3
	_register_card(hex_cloud)
	
	# Concentrated Hex - big hex on single target
	var concentrated_hex := CardDef.new()
	concentrated_hex.card_id = "concentrated_hex"
	concentrated_hex.card_name = "Concentrated Hex"
	concentrated_hex.description = "Apply {hex_damage} Hex to a random enemy."
	concentrated_hex.card_type = "hex"
	concentrated_hex.effect_type = "apply_hex"
	concentrated_hex.tags = ["hex", "single_target"]
	concentrated_hex.base_cost = 2
	concentrated_hex.hex_damage = 8
	concentrated_hex.target_type = "random_enemy"
	concentrated_hex.target_rings = [0, 1, 2, 3]
	concentrated_hex.target_count = 1
	concentrated_hex.rarity = 2
	_register_card(concentrated_hex)


# =============================================================================
# V3 DEFENSE - Armor and barriers
# =============================================================================

func _create_v3_defense() -> void:
	"""Create defense cards."""
	
	# Heavy Armor - more armor (INSTANT)
	var heavy_armor := CardDef.new()
	heavy_armor.card_id = "heavy_armor"
	heavy_armor.card_name = "Heavy Armor"
	heavy_armor.description = "Gain {armor} Armor."
	heavy_armor.card_type = "defense"
	heavy_armor.play_mode = "instant"
	heavy_armor.effect_type = "gain_armor"
	heavy_armor.tags = ["defense", "armor"]
	heavy_armor.base_cost = 2
	heavy_armor.armor_amount = 8
	heavy_armor.target_type = "self"
	heavy_armor.rarity = 2
	_register_card(heavy_armor)
	
	# Reactive Armor - armor + heal (INSTANT)
	var reactive_armor := CardDef.new()
	reactive_armor.card_id = "reactive_armor"
	reactive_armor.card_name = "Reactive Armor"
	reactive_armor.description = "Gain {armor} Armor and heal {heal_amount} HP."
	reactive_armor.card_type = "defense"
	reactive_armor.play_mode = "instant"
	reactive_armor.effect_type = "armor_and_heal"
	reactive_armor.tags = ["defense", "armor", "heal"]
	reactive_armor.base_cost = 2
	reactive_armor.armor_amount = 4
	reactive_armor.heal_amount = 3
	reactive_armor.target_type = "self"
	reactive_armor.rarity = 2
	_register_card(reactive_armor)
	
	# Shield Barrier - barrier trap (INSTANT - placed immediately)
	var shield_barrier := CardDef.new()
	shield_barrier.card_id = "shield_barrier"
	shield_barrier.card_name = "Shield Barrier"
	shield_barrier.description = "Place a barrier in target ring. Deals {damage} damage when crossed (2 uses)."
	shield_barrier.card_type = "defense"
	shield_barrier.play_mode = "instant"
	shield_barrier.effect_type = "ring_barrier"
	shield_barrier.tags = ["barrier", "defense", "ring_control"]
	shield_barrier.base_cost = 1
	shield_barrier.base_damage = 3
	shield_barrier.effect_params = {"duration": 2}
	shield_barrier.target_type = "ring"
	shield_barrier.target_rings = [1, 2, 3]
	shield_barrier.requires_target = true
	shield_barrier.rarity = 2
	_register_card(shield_barrier)
	
	# Healing Surge - direct heal (INSTANT)
	var healing_surge := CardDef.new()
	healing_surge.card_id = "healing_surge"
	healing_surge.card_name = "Healing Surge"
	healing_surge.description = "Heal {heal_amount} HP."
	healing_surge.card_type = "skill"
	healing_surge.play_mode = "instant"
	healing_surge.effect_type = "heal"
	healing_surge.tags = ["skill", "heal"]
	healing_surge.base_cost = 1
	healing_surge.heal_amount = 5
	healing_surge.target_type = "self"
	healing_surge.rarity = 2
	_register_card(healing_surge)


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
	"""Get random cards for shop/rewards."""
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


func get_veteran_starter_deck() -> Array[Dictionary]:
	"""Get the Veteran Warden's starter deck (10 cards)."""
	return [
		{"card_id": "pistol", "tier": 1},
		{"card_id": "pistol", "tier": 1},
		{"card_id": "shotgun", "tier": 1},
		{"card_id": "gun_amplifier", "tier": 1},
		{"card_id": "iron_shell", "tier": 1},
		{"card_id": "iron_shell", "tier": 1},
		{"card_id": "hex_bolt", "tier": 1},
		{"card_id": "quick_draw", "tier": 1},
		{"card_id": "quick_draw", "tier": 1},
		{"card_id": "shove", "tier": 1},
	]
