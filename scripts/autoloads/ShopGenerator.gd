extends Node
## ShopGenerator - V2 Brotato-style shop with family biasing
## Pushes players toward build identities through weighted offers

# Family definitions for biasing
const FAMILIES: Array[String] = ["gun", "hex_ritual", "barrier", "lifedrain"]
const BARRIER_FAMILY_TAGS: Array[String] = ["barrier", "barrier_trap", "fortress"]
const NEUTRAL_TAGS: Array[String] = ["skill", "defense", "engine_core"]

# Shop structure (V2)
const CARD_SLOTS: int = 4
const ARTIFACT_SLOTS: int = 3
const SERVICE_SLOTS: int = 2

# Reroll cost formula: 3 + floor((wave - 1) / 3)
const REROLL_BASE_COST: int = 3

# Card pricing
const CARD_BASE_PRICE: int = 30
const CARD_RARITY_PRICE: int = 15
const CARD_WAVE_PRICE: int = 3


func _ready() -> void:
	print("[ShopGenerator] V2 Shop System Initialized")


# =============================================================================
# FAMILY TRACKING
# =============================================================================

func get_owned_family_counts() -> Dictionary:
	"""Count how many cards/artifacts the player owns in each family."""
	var counts: Dictionary = {}
	for family: String in FAMILIES:
		counts[family] = 0
	counts["neutral"] = 0
	
	# Count cards in deck
	for entry: Dictionary in RunManager.deck:
		var card = CardDatabase.get_card(entry.card_id)
		if card:
			var card_family: String = _get_card_family(card)
			if counts.has(card_family):
				counts[card_family] += 1
			else:
				counts["neutral"] += 1
	
	# Count equipped artifacts
	for artifact in ArtifactManager.get_equipped_artifacts():
		var artifact_family: String = _get_artifact_family(artifact)
		if counts.has(artifact_family):
			counts[artifact_family] += 1
		else:
			counts["neutral"] += 1
	
	return counts


func _get_card_family(card) -> String:
	"""Determine which family a card belongs to based on its tags."""
	var tags: Array = card.tags
	
	# Check in order of priority
	if "gun" in tags:
		return "gun"
	if "hex_ritual" in tags:
		return "hex_ritual"
	for barrier_tag: String in BARRIER_FAMILY_TAGS:
		if barrier_tag in tags:
			return "barrier"
	if "lifedrain" in tags:
		return "lifedrain"
	
	return "neutral"


func _get_artifact_family(artifact) -> String:
	"""Determine which family an artifact belongs to.
	Works with both ArtifactDefinition resources and dictionaries."""
	
	# Handle both Resource (ArtifactDefinition) and Dictionary types
	var required_tags: Array = []
	var trigger_tag: String = ""
	var stat_modifiers: Dictionary = {}
	
	if artifact is Resource:
		# ArtifactDefinition resource - access properties directly
		required_tags = artifact.required_tags if artifact.required_tags else []
		trigger_tag = artifact.trigger_tag if artifact.trigger_tag else ""
		stat_modifiers = artifact.stat_modifiers if artifact.stat_modifiers else {}
	elif artifact is Dictionary:
		# Dictionary format (from get_available_artifacts)
		required_tags = artifact.get("required_tags", [])
		trigger_tag = str(artifact.get("trigger_tag", ""))
		stat_modifiers = artifact.get("stat_modifiers", {})
	
	# Check required tags first
	if "gun" in required_tags or trigger_tag == "gun":
		return "gun"
	if "hex_ritual" in required_tags or trigger_tag == "hex_ritual":
		return "hex_ritual"
	for barrier_tag: String in BARRIER_FAMILY_TAGS:
		if barrier_tag in required_tags or trigger_tag == barrier_tag:
			return "barrier"
	if "lifedrain" in required_tags or trigger_tag == "lifedrain":
		return "lifedrain"
	
	# Check stat modifiers for implicit family
	if stat_modifiers.size() > 0:
		if stat_modifiers.has("gun_damage_percent"):
			return "gun"
		if stat_modifiers.has("hex_damage_percent"):
			return "hex_ritual"
		if stat_modifiers.has("barrier_strength_percent"):
			return "barrier"
	
	return "neutral"


func get_primary_secondary_families() -> Dictionary:
	"""Get the player's primary and secondary family based on owned items."""
	var counts: Dictionary = get_owned_family_counts()
	
	var primary: String = ""
	var secondary: String = ""
	var primary_score: int = 0
	var secondary_score: int = 0
	
	for family: String in FAMILIES:
		var score: int = counts.get(family, 0)
		if score > primary_score:
			secondary = primary
			secondary_score = primary_score
			primary = family
			primary_score = score
		elif score > secondary_score:
			secondary = family
			secondary_score = score
	
	return {
		"primary": primary,
		"primary_score": primary_score,
		"secondary": secondary,
		"secondary_score": secondary_score
	}


# =============================================================================
# SHOP GENERATION
# =============================================================================

func generate_shop_cards(wave: int) -> Array:
	"""Generate biased card offers for the shop."""
	var cards: Array = []
	var used_ids: Array = []
	
	if wave <= 3:
		# Early waves: Strong push into one family (70% chance)
		cards = _generate_early_wave_cards(wave, used_ids)
	else:
		# Later waves: Bias toward player's build
		cards = _generate_late_wave_cards(wave, used_ids)
	
	return cards


func _generate_early_wave_cards(_wave: int, used_ids: Array) -> Array:
	"""Generate cards for waves 1-3 with strong family focus."""
	var cards: Array = []
	
	# 70% chance to focus on a family
	var do_focus: bool = randf() < 0.7
	var focus_family: String = ""
	
	if do_focus:
		focus_family = FAMILIES[randi() % FAMILIES.size()]
	
	for slot: int in range(CARD_SLOTS):
		var card = null
		
		if do_focus:
			if slot < 2:
				# Slots 1-2: Must be from focus family
				card = _get_card_from_family(focus_family, used_ids)
			elif slot == 2:
				# Slot 3: 50% focus, 50% any
				if randf() < 0.5:
					card = _get_card_from_family(focus_family, used_ids)
				else:
					card = _get_random_card_any_family(used_ids)
			else:
				# Slot 4: Unbiased
				card = _get_random_card_any_family(used_ids)
		else:
			# No focus: all random
			card = _get_random_card_any_family(used_ids)
		
		if card:
			cards.append(card)
			used_ids.append(card.card_id)
	
	return cards


func _generate_late_wave_cards(_wave: int, used_ids: Array) -> Array:
	"""Generate cards for waves 4+ with adaptive biasing."""
	var cards: Array = []
	var families_data: Dictionary = get_primary_secondary_families()
	var weights: Dictionary = _calculate_family_weights(families_data)
	
	var primary_count: int = 0
	var primary_family: String = families_data.primary
	var need_primary_guarantee: bool = families_data.primary_score >= 2
	
	for slot: int in range(CARD_SLOTS):
		var family: String = _sample_family_by_weight(weights)
		var card = _get_card_from_family(family, used_ids)
		
		if card:
			cards.append(card)
			used_ids.append(card.card_id)
			if _get_card_family(card) == primary_family:
				primary_count += 1
	
	# Guarantee at least 2 primary family cards if player has committed
	if need_primary_guarantee and primary_count < 2 and cards.size() >= 2:
		# Replace last card with primary family card
		var replacement = _get_card_from_family(primary_family, used_ids)
		if replacement:
			cards[cards.size() - 1] = replacement
	
	return cards


func _calculate_family_weights(families_data: Dictionary) -> Dictionary:
	"""Calculate family weights for biased sampling."""
	var weights: Dictionary = {}
	
	# Base weight for all families
	for family: String in FAMILIES:
		weights[family] = 1.0
	weights["neutral"] = 1.0
	
	# Boost primary family
	if families_data.primary != "":
		weights[families_data.primary] += 2.0
	
	# Boost secondary family
	if families_data.secondary != "":
		weights[families_data.secondary] += 1.0
	
	return weights


func _sample_family_by_weight(weights: Dictionary) -> String:
	"""Sample a family based on weights."""
	var total: float = 0.0
	for family: String in weights:
		total += weights[family]
	
	var roll: float = randf() * total
	var cumulative: float = 0.0
	
	for family: String in weights:
		cumulative += weights[family]
		if roll <= cumulative:
			return family
	
	return "neutral"


func _get_card_from_family(family: String, exclude_ids: Array):
	"""Get a random card from a specific family."""
	var available: Array = []
	
	for card_id: String in CardDatabase.cards:
		if card_id in exclude_ids:
			continue
		var card = CardDatabase.get_card(card_id)
		if card and _get_card_family(card) == family:
			available.append(card)
	
	if available.size() > 0:
		return available[randi() % available.size()]
	
	# Fallback to any card
	return _get_random_card_any_family(exclude_ids)


func _get_random_card_any_family(exclude_ids: Array):
	"""Get a random card from any family."""
	return CardDatabase.get_random_card(exclude_ids)


# =============================================================================
# ARTIFACT GENERATION
# =============================================================================

func generate_shop_artifacts(wave: int) -> Array:
	"""Generate biased artifact offers for the shop."""
	var artifacts: Array = []
	var used_ids: Array = []
	
	var families_data: Dictionary = get_primary_secondary_families()
	var weights: Dictionary = _calculate_family_weights(families_data)
	
	# Early waves: 60% chance to include focus family artifact
	var focus_family: String = ""
	if wave <= 3 and randf() < 0.6:
		focus_family = FAMILIES[randi() % FAMILIES.size()]
	
	for slot: int in range(ARTIFACT_SLOTS):
		var artifact: Dictionary = {}
		
		if slot == 0 and focus_family != "":
			# First slot: Try to get from focus family
			artifact = _get_artifact_from_family(focus_family, used_ids)
		else:
			# Sample by weight
			var family: String = _sample_family_by_weight(weights)
			artifact = _get_artifact_from_family(family, used_ids)
		
		if artifact.size() > 0:
			artifacts.append(artifact)
			used_ids.append(artifact.artifact_id)
	
	return artifacts


func _get_artifact_from_family(family: String, exclude_ids: Array) -> Dictionary:
	"""Get a random artifact from a specific family."""
	var available: Array = ArtifactManager.get_available_artifacts()
	var family_artifacts: Array = []
	
	for artifact: Dictionary in available:
		if artifact.artifact_id in exclude_ids:
			continue
		var artifact_def = ArtifactManager.get_artifact(artifact.artifact_id)
		if artifact_def and _get_artifact_family(artifact_def) == family:
			family_artifacts.append(artifact)
	
	if family_artifacts.size() > 0:
		return family_artifacts[randi() % family_artifacts.size()]
	
	# Fallback to any artifact
	return _get_random_artifact_any_family(exclude_ids)


func _get_random_artifact_any_family(exclude_ids: Array) -> Dictionary:
	"""Get a random artifact from any family."""
	var available: Array = ArtifactManager.get_available_artifacts()
	var filtered: Array = []
	
	for artifact: Dictionary in available:
		if artifact.artifact_id not in exclude_ids:
			filtered.append(artifact)
	
	if filtered.size() > 0:
		return filtered[randi() % filtered.size()]
	
	return {}


# =============================================================================
# SERVICE COSTS
# =============================================================================

func get_heal_cost(wave: int) -> int:
	"""Calculate heal cost: 10 + 2 * wave."""
	return 10 + 2 * wave


func get_remove_card_cost(wave: int) -> int:
	"""Calculate remove card cost: 10 + 3 * wave."""
	return 10 + 3 * wave


func get_reroll_cost(wave: int) -> int:
	"""Calculate reroll cost: 3 + floor((wave - 1) / 3)."""
	return REROLL_BASE_COST + int((wave - 1) / 3)


# =============================================================================
# CARD PRICING
# =============================================================================

func get_card_price(card, wave: int) -> int:
	"""Calculate card price based on rarity and wave."""
	var price: int = CARD_BASE_PRICE
	price += card.rarity * CARD_RARITY_PRICE
	price += wave * CARD_WAVE_PRICE
	return price


# =============================================================================
# REWARD GENERATION (Post-wave rewards)
# =============================================================================

func generate_wave_rewards(wave: int) -> Dictionary:
	"""Generate post-wave reward choices (2 cards + 1 flex)."""
	var rewards: Dictionary = {
		"cards": [],
		"flex": null,
		"flex_is_artifact": false
	}
	
	var families_data: Dictionary = get_primary_secondary_families()
	var weights: Dictionary = _calculate_family_weights(families_data)
	var used_ids: Array = []
	
	# 2 card rewards
	for i: int in range(2):
		var family: String = _sample_family_by_weight(weights)
		var card = _get_card_from_family(family, used_ids)
		if card:
			rewards.cards.append(card)
			used_ids.append(card.card_id)
	
	# Flex slot (card or artifact)
	var artifact_chance: float = 0.5 if wave > 3 else 0.7
	if randf() < artifact_chance:
		# Artifact
		var family: String = _sample_family_by_weight(weights)
		var artifact: Dictionary = _get_artifact_from_family(family, [])
		if artifact.size() > 0:
			rewards.flex = artifact
			rewards.flex_is_artifact = true
	
	if rewards.flex == null:
		# Card fallback
		var family: String = _sample_family_by_weight(weights)
		var card = _get_card_from_family(family, used_ids)
		if card:
			rewards.flex = card
			rewards.flex_is_artifact = false
	
	# Guarantee: If player has 2+ in primary family, ensure 1 reward from that family
	if families_data.primary_score >= 2:
		var has_primary: bool = false
		var primary_family: String = families_data.primary
		
		for card in rewards.cards:
			if _get_card_family(card) == primary_family:
				has_primary = true
				break
		
		if not has_primary and rewards.cards.size() > 0:
			var replacement = _get_card_from_family(primary_family, used_ids)
			if replacement:
				rewards.cards[0] = replacement
	
	return rewards
