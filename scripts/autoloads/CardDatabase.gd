extends Node
## CardDatabase - V6 Horde Slaughter Card Pool
## Uses modular CardData.gd for card definitions
## Multi-hit is CORE - most weapons hit 2+ times
##
## SYNERGY PHILOSOPHY (Brotato-style):
## - Pure archetypes (1 category): Quintessential expression of playstyle
## - Thematic hybrids (2 categories): Build crossover potential

signal cards_loaded()

var cards: Dictionary = {}  # card_id -> CardDefinition
var cards_by_category: Dictionary = {}  # category -> Array[CardDefinition]
var cards_by_type: Dictionary = {}  # damage_type -> Array[CardDefinition]
var weapons: Array = []  # All weapon cards
var instants: Array = []  # All instant cards

const CardDef = preload("res://scripts/resources/CardDefinition.gd")
const TagConstantsClass = preload("res://scripts/constants/TagConstants.gd")
const CardDataClass = preload("res://scripts/data/CardData.gd")


func _ready() -> void:
	_load_cards_from_data()
	_print_synergy_summary()
	print("[CardDatabase] V6 Card Pool initialized with ", cards.size(), " cards (",
		weapons.size(), " weapons, ", instants.size(), " instants)")


func _load_cards_from_data() -> void:
	"""Load all cards from the modular CardData file."""
	# Load weapons
	for weapon_data: Dictionary in CardDataClass.get_all_weapons():
		var card: CardDef = _create_weapon_from_data(weapon_data)
		_register_card(card)
	
	# Load instants
	for instant_data: Dictionary in CardDataClass.get_all_instants():
		var card: CardDef = _create_instant_from_data(instant_data)
		_register_card(card)
	
	cards_loaded.emit()


func _print_synergy_summary() -> void:
	"""Print a summary of category distribution."""
	var summary: Dictionary = CardDataClass.get_category_summary()
	print("[CardDatabase] Category Distribution:")
	for cat: String in summary:
		var data: Dictionary = summary[cat]
		print("  - %s: %d total (%d pure, %d hybrid)" % [cat, data.total, data.pure, data.hybrid])


# =============================================================================
# WEAPON CREATION FROM DATA
# =============================================================================

func _create_weapon_from_data(data: Dictionary) -> CardDef:
	"""Create a weapon card from data dictionary."""
	var card := CardDef.new()
	
	# Basic info
	card.card_id = data.get("id", "")
	card.card_name = data.get("name", "")
	card.base_cost = data.get("cost", 1)
	card.base_damage = data.get("base", 1)
	card.damage_type = data.get("damage_type", "kinetic")
	card.rarity = data.get("rarity", 1)
	card.tier = 1
	card.is_instant_card = false
	card.card_type = "weapon"
	card.play_mode = "combat"
	card.hit_count = data.get("hits", 1)
	
	# Categories (1-2 per Brotato design)
	var categories: Array = data.get("categories", [])
	var typed_categories: Array[String] = []
	for cat: Variant in categories:
		typed_categories.append(str(cat))
	card.categories = typed_categories
	
	# Scaling
	var scaling: Dictionary = data.get("scaling", {})
	card.kinetic_scaling = scaling.get("kinetic", 0)
	card.thermal_scaling = scaling.get("thermal", 0)
	card.arcane_scaling = scaling.get("arcane", 0)
	card.armor_start_scaling = scaling.get("armor_start", 0)
	card.crit_damage_scaling = scaling.get("crit_damage", 0)
	card.missing_hp_scaling = scaling.get("missing_hp", 0)
	card.cards_played_scaling = scaling.get("cards_played", 0)
	card.barriers_scaling = scaling.get("barriers", 0)
	
	# Crit
	var base_crit: float = data.get("crit_chance", 5.0)
	var base_crit_dmg: float = data.get("crit_damage", 150.0)
	card.crit_chance_bonus = base_crit - 5.0
	card.crit_damage_bonus = base_crit_dmg - 150.0
	
	# Effect type based on hit count and target mode
	var target_mode: String = data.get("target_mode", "")
	if card.hit_count > 1:
		card.effect_type = "v5_multi_hit"
		card.target_type = "random_enemy"
		card.target_rings = [0, 1, 2, 3]
	elif target_mode == "ring":
		card.effect_type = "v5_ring_damage"
		card.target_type = "ring"
		card.requires_target = false  # Weapons auto-target
		card.target_rings = [0, 1, 2, 3]
	elif target_mode == "all":
		card.effect_type = "v5_aoe"
		card.target_type = "all_enemies"
	else:
		card.effect_type = "v5_damage"
		card.target_type = "random_enemy"
		card.target_rings = [0, 1, 2, 3]
	
	# Override effect type if specified
	if data.has("effect_type"):
		card.effect_type = data.get("effect_type")
	
	# Special properties
	if data.has("splash"):
		card.splash_damage = data.get("splash")
		if card.effect_type == "v5_damage":
			card.effect_type = "splash_damage"
	
	if data.has("burn"):
		card.burn_damage = data.get("burn")
	
	if data.has("hex"):
		card.hex_damage = data.get("hex")
	
	if data.has("heal"):
		card.heal_amount = data.get("heal")
	
	if data.has("self_damage"):
		card.self_damage = data.get("self_damage")
	
	if data.has("execute_threshold"):
		card.effect_type = "apply_execute"
		card.effect_params["execute_threshold"] = data.get("execute_threshold")
	
	if data.has("draw"):
		card.cards_to_draw = data.get("draw")
	
	if data.has("next_weapon_bonus"):
		card.effect_params["next_weapon_bonus"] = data.get("next_weapon_bonus")
	
	if data.has("grant_energy"):
		card.effect_params["grant_energy"] = data.get("grant_energy")
	
	# Flags
	var flags: Array = data.get("flags", [])
	if "can_repeat_target" in flags:
		card.can_repeat_target = true
	if "ignore_armor" in flags:
		card.effect_params["ignore_armor"] = true
	
	# Build description
	var effect: String = data.get("effect", "")
	card.description = _build_weapon_description(card, effect)
	
	if not effect.is_empty():
		card.effect_params["effect_text"] = effect
	
	# Legacy tags from categories
	card.tags = _categories_to_legacy_tags(card.categories)
	
	return card


func _build_weapon_description(card: CardDef, effect: String) -> String:
	"""Build description string for a weapon."""
	var desc: String = ""
	
	if card.hit_count > 1:
		desc = "Deal {damage} damage %d times." % card.hit_count
	elif card.effect_type == "v5_ring_damage":
		desc = "Deal {damage} damage to closest lane."
	elif card.effect_type == "v5_aoe":
		desc = "Deal {damage} damage to ALL enemies."
	else:
		desc = "Deal {damage} damage."
	
	if not effect.is_empty():
		desc += " " + effect
	
	return desc


# =============================================================================
# INSTANT CREATION FROM DATA
# =============================================================================

func _create_instant_from_data(data: Dictionary) -> CardDef:
	"""Create an instant card from data dictionary."""
	var card := CardDef.new()
	
	# Basic info
	card.card_id = data.get("id", "")
	card.card_name = data.get("name", "")
	card.description = data.get("desc", "")
	card.base_cost = data.get("cost", 1)
	card.rarity = data.get("rarity", 1)
	card.is_instant_card = true
	card.card_type = "skill"
	card.play_mode = "instant"
	card.effect_type = data.get("effect_type", "buff")
	card.damage_type = "none"
	card.tier = 1
	
	# Categories (1-2 per Brotato design)
	var categories: Array = data.get("categories", [])
	var typed_categories: Array[String] = []
	for cat: Variant in categories:
		typed_categories.append(str(cat))
	card.categories = typed_categories
	
	# Buff properties
	if data.has("buff_type"):
		card.buff_type = data.get("buff_type")
	if data.has("buff_value"):
		card.buff_value = data.get("buff_value")
	
	# Lane buff properties
	if card.effect_type == "lane_buff":
		card.lane_buff_type = data.get("buff_type", "all_damage")
		card.lane_buff_value = data.get("buff_value", 0)
	
	# Targeting
	if data.get("requires_target", false):
		card.requires_target = true
		card.target_type = "ring"
		card.target_rings = [0, 1, 2, 3]
	
	var target_mode: String = data.get("target_mode", "")
	if target_mode == "all":
		card.target_type = "all_enemies"
	
	if data.has("target_count"):
		card.target_count = data.get("target_count")
		card.target_type = "random_enemy"
	
	# Special properties
	if data.has("armor"):
		card.armor_amount = data.get("armor")
	
	if data.has("heal"):
		card.heal_amount = data.get("heal")
	
	if data.has("draw"):
		card.cards_to_draw = data.get("draw")
	
	if data.has("burn"):
		card.burn_damage = data.get("burn")
	
	if data.has("hex"):
		card.hex_damage = data.get("hex")
	
	if data.has("execute_threshold"):
		card.effect_params["execute_threshold"] = data.get("execute_threshold")
	
	if data.has("barrier_damage"):
		card.base_damage = data.get("barrier_damage")
		card.effect_params["barrier_uses"] = data.get("barrier_uses", 2)
	
	# Legacy tags
	card.tags = ["skill"]
	
	return card


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

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


func get_cards_by_rarity(rarity_level: int) -> Array:
	"""Get all cards with a specific rarity."""
	var result: Array = []
	for card: CardDef in cards.values():
		if card.rarity == rarity_level:
			result.append(card)
	return result


func get_veteran_starter_deck() -> Array:
	"""Get the V6 starter deck - start with pistol."""
	return [
		{"card_id": "pistol", "count": 1, "tier": 1},
	]


func get_pure_archetype_cards() -> Array:
	"""Get cards that are pure archetypes (single category)."""
	var result: Array = []
	for card: CardDef in cards.values():
		if card.categories.size() == 1:
			result.append(card)
	return result


func get_hybrid_cards() -> Array:
	"""Get cards that have dual synergies (2 categories)."""
	var result: Array = []
	for card: CardDef in cards.values():
		if card.categories.size() == 2:
			result.append(card)
	return result


func get_cards_with_category(category: String, include_hybrids: bool = true) -> Array:
	"""Get cards that have a specific category (optionally including hybrids)."""
	var result: Array = []
	for card: CardDef in cards.values():
		if category in card.categories:
			if include_hybrids or card.categories.size() == 1:
				result.append(card)
	return result
