extends Node
## CardDatabase - Card definitions lookup
## Contains all card definitions for the game

signal cards_loaded()

var cards: Dictionary = {}  # card_id -> CardDefinition
var cards_by_tag: Dictionary = {}
var cards_by_type: Dictionary = {}
var unlocked_cards: Array = []

const CardDef = preload("res://scripts/resources/CardDefinition.gd")


func _ready() -> void:
	_create_default_cards()
	print("[CardDatabase] Initialized with ", cards.size(), " cards")


func _create_default_cards() -> void:
	_create_weapon_cards()
	_create_skill_cards()
	_create_hex_cards()
	_create_defense_cards()
	cards_loaded.emit()


func _create_weapon_cards() -> void:
	# === WEAPON CARDS ===
	
	# Infernal Pistol - persistent weapon, hits random enemy each turn
	var pistol := CardDef.new()
	pistol.card_id = "infernal_pistol"
	pistol.card_name = "Infernal Pistol"
	pistol.description = "Persistent: Deal {damage} damage to random enemy in Mid/Close each turn."
	pistol.card_type = "weapon"
	pistol.effect_type = "weapon_persistent"
	pistol.tags = ["gun", "persistent"]
	pistol.base_cost = 1
	pistol.base_damage = 4
	pistol.target_type = "random_enemy"
	pistol.target_rings = [1, 2]  # Close, Mid
	pistol.weapon_trigger = "turn_start"
	_register_card(pistol)
	
	# Choirbreaker Shotgun - AoE damage to Close ring
	var shotgun := CardDef.new()
	shotgun.card_id = "choirbreaker_shotgun"
	shotgun.card_name = "Choirbreaker Shotgun"
	shotgun.description = "Deal {damage} damage to ALL enemies in Close ring."
	shotgun.card_type = "weapon"
	shotgun.effect_type = "instant_damage"
	shotgun.tags = ["gun"]
	shotgun.base_cost = 1
	shotgun.base_damage = 6
	shotgun.target_type = "ring"
	shotgun.target_rings = [1]  # Close only
	shotgun.requires_target = false
	_register_card(shotgun)
	
	# Riftshard Rifle - high single target damage at Far range
	var rifle := CardDef.new()
	rifle.card_id = "riftshard_rifle"
	rifle.card_name = "Riftshard Rifle"
	rifle.description = "Deal {damage} damage to single enemy in Far ring."
	rifle.card_type = "weapon"
	rifle.effect_type = "instant_damage"
	rifle.tags = ["gun"]
	rifle.base_cost = 2
	rifle.base_damage = 8
	rifle.target_type = "random_enemy"
	rifle.target_rings = [3]  # Far only
	rifle.rarity = 2
	_register_card(rifle)
	
	# Ember Grenade - AoE damage to any ring (player chooses)
	var grenade := CardDef.new()
	grenade.card_id = "ember_grenade"
	grenade.card_name = "Ember Grenade"
	grenade.description = "Deal {damage} damage to ALL enemies in target ring."
	grenade.card_type = "weapon"
	grenade.effect_type = "instant_damage"
	grenade.tags = ["explosive"]
	grenade.base_cost = 2
	grenade.base_damage = 4
	grenade.target_type = "ring"
	grenade.target_rings = [0, 1, 2, 3]  # All rings valid
	grenade.requires_target = true
	_register_card(grenade)
	
	# Void Revolver - damage + card draw
	var revolver := CardDef.new()
	revolver.card_id = "void_revolver"
	revolver.card_name = "Void Revolver"
	revolver.description = "Deal {damage} damage to random enemy, draw 1 card."
	revolver.card_type = "weapon"
	revolver.effect_type = "damage_and_draw"
	revolver.tags = ["gun"]
	revolver.base_cost = 1
	revolver.base_damage = 3
	revolver.cards_to_draw = 1
	revolver.target_type = "random_enemy"
	revolver.target_rings = [0, 1, 2, 3]
	_register_card(revolver)
	
	# Scatter Shot - multi-target random damage
	var scatter := CardDef.new()
	scatter.card_id = "scatter_shot"
	scatter.card_name = "Scatter Shot"
	scatter.description = "Deal {damage} damage to 3 random enemies."
	scatter.card_type = "weapon"
	scatter.effect_type = "scatter_damage"
	scatter.tags = ["gun"]
	scatter.base_cost = 1
	scatter.base_damage = 2
	scatter.target_count = 3
	scatter.target_type = "random_enemy"
	scatter.target_rings = [0, 1, 2, 3]
	_register_card(scatter)
	
	# Blood Bolt - damage + self heal
	var bloodbolt := CardDef.new()
	bloodbolt.card_id = "blood_bolt"
	bloodbolt.card_name = "Blood Bolt"
	bloodbolt.description = "Deal {damage} damage to random enemy. Heal {heal_amount} HP."
	bloodbolt.card_type = "weapon"
	bloodbolt.effect_type = "damage_and_heal"
	bloodbolt.tags = ["gun", "lifesteal"]
	bloodbolt.base_cost = 1
	bloodbolt.base_damage = 5
	bloodbolt.heal_amount = 2
	bloodbolt.target_type = "random_enemy"
	bloodbolt.target_rings = [0, 1, 2, 3]
	_register_card(bloodbolt)
	
	# Flamethrower - hits Melee and Close
	var flamethrower := CardDef.new()
	flamethrower.card_id = "flamethrower"
	flamethrower.card_name = "Flamethrower"
	flamethrower.description = "Deal {damage} damage to ALL enemies in Melee and Close."
	flamethrower.card_type = "weapon"
	flamethrower.effect_type = "instant_damage"
	flamethrower.tags = ["fire"]
	flamethrower.base_cost = 2
	flamethrower.base_damage = 3
	flamethrower.target_type = "ring"
	flamethrower.target_rings = [0, 1]  # Melee and Close
	flamethrower.requires_target = false
	flamethrower.rarity = 2
	_register_card(flamethrower)


func _create_skill_cards() -> void:
	# === SKILL CARDS ===
	
	# Emergency Medkit - basic heal
	var medkit := CardDef.new()
	medkit.card_id = "emergency_medkit"
	medkit.card_name = "Emergency Medkit"
	medkit.description = "Heal {heal_amount} HP."
	medkit.card_type = "skill"
	medkit.effect_type = "heal"
	medkit.tags = ["heal"]
	medkit.base_cost = 1
	medkit.heal_amount = 5
	_register_card(medkit)
	
	# Adrenaline - gain energy + draw
	var adrenaline := CardDef.new()
	adrenaline.card_id = "adrenaline"
	adrenaline.card_name = "Adrenaline"
	adrenaline.description = "Gain 1 Energy this turn. Draw 1 card."
	adrenaline.card_type = "skill"
	adrenaline.effect_type = "energy_and_draw"
	adrenaline.tags = ["utility"]
	adrenaline.base_cost = 1
	adrenaline.buff_value = 1  # Energy gain
	adrenaline.cards_to_draw = 1
	_register_card(adrenaline)
	
	# Second Wind - big heal
	var second_wind := CardDef.new()
	second_wind.card_id = "second_wind"
	second_wind.card_name = "Second Wind"
	second_wind.description = "Heal {heal_amount} HP."
	second_wind.card_type = "skill"
	second_wind.effect_type = "heal"
	second_wind.tags = ["heal"]
	second_wind.base_cost = 2
	second_wind.heal_amount = 8
	second_wind.rarity = 2
	_register_card(second_wind)
	
	# Ritual Focus - buff next hex
	var ritual := CardDef.new()
	ritual.card_id = "ritual_focus"
	ritual.card_name = "Ritual Focus"
	ritual.description = "Your next Hex card this turn deals double Hex."
	ritual.card_type = "skill"
	ritual.effect_type = "buff"
	ritual.tags = ["hex", "utility"]
	ritual.base_cost = 0
	ritual.buff_type = "hex_damage"
	ritual.buff_value = 100  # 100% increase
	ritual.rarity = 2
	_register_card(ritual)
	
	# Gambit - discard and draw
	var gambit := CardDef.new()
	gambit.card_id = "gambit"
	gambit.card_name = "Gambit"
	gambit.description = "Discard your hand. Draw 5 cards."
	gambit.card_type = "skill"
	gambit.effect_type = "gambit"
	gambit.tags = ["utility"]
	gambit.base_cost = 1
	gambit.cards_to_draw = 5
	gambit.rarity = 2
	_register_card(gambit)
	
	# Quick Strike - free damage
	var quick_strike := CardDef.new()
	quick_strike.card_id = "quick_strike"
	quick_strike.card_name = "Quick Strike"
	quick_strike.description = "Deal {damage} damage to random enemy."
	quick_strike.card_type = "skill"
	quick_strike.effect_type = "instant_damage"
	quick_strike.tags = ["attack"]
	quick_strike.base_cost = 0
	quick_strike.base_damage = 2
	quick_strike.target_type = "random_enemy"
	quick_strike.target_rings = [0, 1, 2, 3]
	_register_card(quick_strike)


func _create_hex_cards() -> void:
	# === HEX CARDS ===
	
	# Simple Hex - basic hex application
	var simple_hex := CardDef.new()
	simple_hex.card_id = "simple_hex"
	simple_hex.card_name = "Simple Hex"
	simple_hex.description = "Apply {hex_damage} Hex to all enemies in target ring."
	simple_hex.card_type = "hex"
	simple_hex.effect_type = "apply_hex"
	simple_hex.tags = ["hex"]
	simple_hex.base_cost = 1
	simple_hex.hex_damage = 3
	simple_hex.target_type = "ring"
	simple_hex.target_rings = [0, 1, 2, 3]
	simple_hex.requires_target = true
	_register_card(simple_hex)
	
	# Mark of Gloom - single target high hex
	var gloom := CardDef.new()
	gloom.card_id = "mark_of_gloom"
	gloom.card_name = "Mark of Gloom"
	gloom.description = "Apply {hex_damage} Hex to single enemy."
	gloom.card_type = "hex"
	gloom.effect_type = "apply_hex"
	gloom.tags = ["hex"]
	gloom.base_cost = 1
	gloom.hex_damage = 4
	gloom.target_type = "random_enemy"
	gloom.target_rings = [0, 1, 2, 3]
	gloom.target_count = 1
	_register_card(gloom)
	
	# Plague Cloud - hex all enemies
	var plague := CardDef.new()
	plague.card_id = "plague_cloud"
	plague.card_name = "Plague Cloud"
	plague.description = "Apply {hex_damage} Hex to ALL enemies."
	plague.card_type = "hex"
	plague.effect_type = "apply_hex"
	plague.tags = ["hex"]
	plague.base_cost = 2
	plague.hex_damage = 2
	plague.target_type = "all_enemies"
	plague.rarity = 2
	_register_card(plague)
	
	# Wither - hex front-line enemies
	var wither := CardDef.new()
	wither.card_id = "wither"
	wither.card_name = "Wither"
	wither.description = "Apply {hex_damage} Hex to all enemies in Close and Melee."
	wither.card_type = "hex"
	wither.effect_type = "apply_hex"
	wither.tags = ["hex"]
	wither.base_cost = 1
	wither.hex_damage = 3
	wither.target_type = "ring"
	wither.target_rings = [0, 1]  # Melee and Close
	wither.requires_target = false
	_register_card(wither)
	
	# Cheap Curse - free but weak hex
	var cheap_curse := CardDef.new()
	cheap_curse.card_id = "cheap_curse"
	cheap_curse.card_name = "Cheap Curse"
	cheap_curse.description = "Apply {hex_damage} Hex to random enemy."
	cheap_curse.card_type = "hex"
	cheap_curse.effect_type = "apply_hex"
	cheap_curse.tags = ["hex"]
	cheap_curse.base_cost = 0
	cheap_curse.hex_damage = 2
	cheap_curse.target_type = "random_enemy"
	cheap_curse.target_rings = [0, 1, 2, 3]
	cheap_curse.target_count = 1
	_register_card(cheap_curse)
	
	# Soul Rend - damage + hex combo
	var soul_rend := CardDef.new()
	soul_rend.card_id = "soul_rend"
	soul_rend.card_name = "Soul Rend"
	soul_rend.description = "Deal {damage} damage and apply {hex_damage} Hex to enemy in Melee."
	soul_rend.card_type = "hex"
	soul_rend.effect_type = "damage_and_hex"
	soul_rend.tags = ["hex"]
	soul_rend.base_cost = 2
	soul_rend.base_damage = 3
	soul_rend.hex_damage = 5
	soul_rend.target_type = "random_enemy"
	soul_rend.target_rings = [0]  # Melee only
	soul_rend.rarity = 2
	_register_card(soul_rend)


func _create_defense_cards() -> void:
	# === DEFENSE CARDS ===
	
	# Glass Ward - basic armor
	var ward := CardDef.new()
	ward.card_id = "glass_ward"
	ward.card_name = "Glass Ward"
	ward.description = "Gain {armor} Armor."
	ward.card_type = "defense"
	ward.effect_type = "gain_armor"
	ward.tags = ["armor"]
	ward.base_cost = 1
	ward.armor_amount = 3
	_register_card(ward)
	
	# Iron Bastion - strong armor
	var bastion := CardDef.new()
	bastion.card_id = "iron_bastion"
	bastion.card_name = "Iron Bastion"
	bastion.description = "Gain {armor} Armor."
	bastion.card_type = "defense"
	bastion.effect_type = "gain_armor"
	bastion.tags = ["armor"]
	bastion.base_cost = 2
	bastion.armor_amount = 6
	bastion.rarity = 2
	_register_card(bastion)
	
	# Barrier Sigil - ring barrier
	var barrier := CardDef.new()
	barrier.card_id = "barrier_sigil"
	barrier.card_name = "Barrier Sigil"
	barrier.description = "Create barrier on target ring: enemies crossing take {damage} damage."
	barrier.card_type = "defense"
	barrier.effect_type = "ring_barrier"
	barrier.tags = ["barrier"]
	barrier.base_cost = 1
	barrier.base_damage = 4
	barrier.duration = 2
	barrier.target_type = "ring"
	barrier.target_rings = [1, 2, 3]  # Close, Mid, Far
	barrier.requires_target = true
	barrier.rarity = 2
	_register_card(barrier)
	
	# Draining Shield - armor + heal based on enemies
	var draining := CardDef.new()
	draining.card_id = "draining_shield"
	draining.card_name = "Draining Shield"
	draining.description = "Gain {armor} Armor. Heal 1 HP for each enemy in Melee."
	draining.card_type = "defense"
	draining.effect_type = "armor_and_lifesteal"
	draining.tags = ["armor", "lifesteal"]
	draining.base_cost = 1
	draining.armor_amount = 3
	draining.lifesteal_on_kill = 1
	_register_card(draining)
	
	# Repulsion - push enemies away
	var repulsion := CardDef.new()
	repulsion.card_id = "repulsion"
	repulsion.card_name = "Repulsion"
	repulsion.description = "Push all enemies in Melee back 1 ring."
	repulsion.card_type = "defense"
	repulsion.effect_type = "push_enemies"
	repulsion.tags = ["crowd_control"]
	repulsion.base_cost = 1
	repulsion.push_amount = 1
	repulsion.target_type = "ring"
	repulsion.target_rings = [0]  # Melee
	repulsion.requires_target = false
	_register_card(repulsion)
	
	# Shield Bash - damage based on armor
	var shield_bash := CardDef.new()
	shield_bash.card_id = "shield_bash"
	shield_bash.card_name = "Shield Bash"
	shield_bash.description = "Deal damage equal to your Armor to enemy in Melee."
	shield_bash.card_type = "defense"
	shield_bash.effect_type = "shield_bash"
	shield_bash.tags = ["armor", "attack"]
	shield_bash.base_cost = 1
	shield_bash.target_type = "random_enemy"
	shield_bash.target_rings = [0]  # Melee only
	shield_bash.rarity = 2
	_register_card(shield_bash)


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
