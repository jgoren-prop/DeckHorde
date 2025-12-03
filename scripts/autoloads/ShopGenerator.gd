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

# =============================================================================
# BROTATO ECONOMY: STAT UPGRADES
# =============================================================================

# Stat upgrade definitions: {id: {name, icon, stat, value, base_price, price_scaling, cap, cap_stat_value}}
const STAT_UPGRADES: Dictionary = {
	"energy_up": {
		"name": "+1 Energy",
		"icon": "⚡",
		"description": "+1 energy per turn",
		"stat": "energy_per_turn",
		"value": 1,
		"base_price": 60,
		"price_scaling": 1.5,  # Exponential price increase
		"cap": 5,  # Max value for this stat
	},
	"draw_up": {
		"name": "+1 Draw",
		"icon": "📜",
		"description": "+1 card drawn per turn",
		"stat": "draw_per_turn",
		"value": 1,
		"base_price": 50,
		"price_scaling": 1.5,
		"cap": 7,
	},
	"hp_up": {
		"name": "+10 Max HP",
		"icon": "❤️",
		"description": "+10 maximum health",
		"stat": "max_hp",
		"value": 10,
		"base_price": 25,
		"price_scaling": 1.2,
		"cap": -1,  # No cap
	},
	"gun_damage_up": {
		"name": "+5% Gun Damage",
		"icon": "🔫",
		"description": "+5% damage from gun cards",
		"stat": "gun_damage_percent",
		"value": 5.0,
		"base_price": 20,
		"price_scaling": 1.3,
		"cap": -1,
	},
	"hex_damage_up": {
		"name": "+5% Hex Damage",
		"icon": "🔮",
		"description": "+5% damage from hex cards",
		"stat": "hex_damage_percent",
		"value": 5.0,
		"base_price": 20,
		"price_scaling": 1.3,
		"cap": -1,
	},
	"armor_gain_up": {
		"name": "+10% Armor Gain",
		"icon": "🛡️",
		"description": "+10% armor from all sources",
		"stat": "armor_gain_percent",
		"value": 10.0,
		"base_price": 15,
		"price_scaling": 1.3,
		"cap": -1,
	},
	# V2: Weapon slot upgrade REMOVED - no slot limit now
	# Keeping entry commented for reference
	#"weapon_slot_up": {
	#	"name": "+1 Weapon Slot",
	#	"icon": "🎰",
	#	"description": "+1 deployed weapon capacity",
	#	"stat": "weapon_slots_max",
	#	"value": 1,
	#	"base_price": 80,
	#	"price_scaling": 1.6,
	#	"cap": 8,
	#},
	"scrap_gain_up": {
		"name": "+10% Scrap Gain",
		"icon": "⚙️",
		"description": "+10% scrap from all sources",
		"stat": "scrap_gain_percent",
		"value": 10.0,
		"base_price": 30,
		"price_scaling": 1.4,
		"cap": -1,
	},
	"shop_discount": {
		"name": "-5% Shop Prices",
		"icon": "💰",
		"description": "-5% cost on all purchases",
		"stat": "shop_price_percent",
		"value": -5.0,
		"base_price": 40,
		"price_scaling": 1.5,
		"cap_stat_value": 70.0,  # Min 70% price (30% discount max)
	},
	"xp_gain_up": {
		"name": "+10% XP Gain",
		"icon": "⭐",
		"description": "+10% XP from enemy kills",
		"stat": "xp_gain_percent",
		"value": 10.0,
		"base_price": 25,
		"price_scaling": 1.3,
		"cap": -1,
	},
}

# Track how many times each stat has been purchased this run
var stat_purchase_counts: Dictionary = {}


func _ready() -> void:
	print("[ShopGenerator] V2 Brotato Economy Shop Initialized")
	_reset_stat_purchase_counts()


func _reset_stat_purchase_counts() -> void:
	"""Reset stat purchase tracking for new run."""
	stat_purchase_counts = {}
	for upgrade_id: String in STAT_UPGRADES:
		stat_purchase_counts[upgrade_id] = 0


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
	return REROLL_BASE_COST + floori(float(wave - 1) / 3.0)


# =============================================================================
# CARD PRICING
# =============================================================================

func get_card_price(card, wave: int) -> int:
	"""Calculate card price based on rarity and wave."""
	var price: int = CARD_BASE_PRICE
	price += card.rarity * CARD_RARITY_PRICE
	price += wave * CARD_WAVE_PRICE
	
	# Apply shop price discount
	var price_mult: float = RunManager.player_stats.get_shop_price_multiplier()
	return int(float(price) * price_mult)


# =============================================================================
# STAT UPGRADE GENERATION
# =============================================================================

func generate_shop_stat_upgrades() -> Array:
	"""Generate 1-2 stat upgrades for the shop."""
	var upgrades: Array = []
	var available_ids: Array = _get_available_stat_upgrade_ids()
	
	if available_ids.size() == 0:
		return upgrades
	
	# Always offer 1-2 stat upgrades
	var count: int = 1 if randf() < 0.4 else 2
	count = mini(count, available_ids.size())
	
	available_ids.shuffle()
	
	for i: int in range(count):
		var upgrade_id: String = available_ids[i]
		var upgrade_data: Dictionary = _create_stat_upgrade_offer(upgrade_id)
		upgrades.append(upgrade_data)
	
	return upgrades


func _get_available_stat_upgrade_ids() -> Array:
	"""Get stat upgrades that haven't hit their cap."""
	var available: Array = []
	
	for upgrade_id: String in STAT_UPGRADES:
		if _can_purchase_stat_upgrade(upgrade_id):
			available.append(upgrade_id)
	
	return available


func _can_purchase_stat_upgrade(upgrade_id: String) -> bool:
	"""Check if a stat upgrade can still be purchased (not at cap)."""
	var upgrade: Dictionary = STAT_UPGRADES.get(upgrade_id, {})
	if upgrade.size() == 0:
		return false
	
	var stat_name: String = upgrade.stat
	var cap: int = upgrade.get("cap", -1)
	var cap_stat_value = upgrade.get("cap_stat_value", null)
	
	# Check stat cap
	if cap > 0:
		var current_value = _get_current_stat_value(stat_name)
		if current_value >= cap:
			return false
	
	# Check cap_stat_value (for things like shop_price_percent with min value)
	if cap_stat_value != null:
		var current_value: float = float(_get_current_stat_value(stat_name))
		if current_value <= cap_stat_value:
			return false
	
	return true


func _get_current_stat_value(stat_name: String) -> Variant:
	"""Get current value of a stat from PlayerStats."""
	var stats = RunManager.player_stats
	
	match stat_name:
		"energy_per_turn":
			return stats.energy_per_turn
		"draw_per_turn":
			return stats.draw_per_turn
		"max_hp":
			return stats.max_hp
		"gun_damage_percent":
			return stats.gun_damage_percent
		"hex_damage_percent":
			return stats.hex_damage_percent
		"armor_gain_percent":
			return stats.armor_gain_percent
		"weapon_slots_max":
			return stats.weapon_slots_max
		"scrap_gain_percent":
			return stats.scrap_gain_percent
		"shop_price_percent":
			return stats.shop_price_percent
		"xp_gain_percent":
			return stats.xp_gain_percent
		_:
			return 0


func _create_stat_upgrade_offer(upgrade_id: String) -> Dictionary:
	"""Create a shop offer for a stat upgrade."""
	var base_upgrade: Dictionary = STAT_UPGRADES.get(upgrade_id, {})
	var purchase_count: int = stat_purchase_counts.get(upgrade_id, 0)
	
	# Calculate price with exponential scaling
	var base_price: int = base_upgrade.base_price
	var scaling: float = base_upgrade.price_scaling
	var price: int = int(float(base_price) * pow(scaling, float(purchase_count)))
	
	# Apply shop price discount
	var price_mult: float = RunManager.player_stats.get_shop_price_multiplier()
	price = int(float(price) * price_mult)
	
	return {
		"upgrade_id": upgrade_id,
		"name": base_upgrade.name,
		"icon": base_upgrade.icon,
		"description": base_upgrade.description,
		"stat": base_upgrade.stat,
		"value": base_upgrade.value,
		"price": price,
		"purchase_count": purchase_count,
		"current_value": _get_current_stat_value(base_upgrade.stat),
	}


func purchase_stat_upgrade(upgrade_id: String) -> bool:
	"""Purchase a stat upgrade. Returns true if successful."""
	if not _can_purchase_stat_upgrade(upgrade_id):
		print("[ShopGenerator] Cannot purchase stat upgrade: %s (at cap)" % upgrade_id)
		return false
	
	var offer: Dictionary = _create_stat_upgrade_offer(upgrade_id)
	
	if not RunManager.spend_scrap(offer.price):
		print("[ShopGenerator] Cannot purchase stat upgrade: not enough scrap")
		return false
	
	# Apply the upgrade
	var base_upgrade: Dictionary = STAT_UPGRADES.get(upgrade_id, {})
	RunManager.player_stats.apply_modifier(base_upgrade.stat, base_upgrade.value)
	
	# Track purchase
	stat_purchase_counts[upgrade_id] = stat_purchase_counts.get(upgrade_id, 0) + 1
	
	# Special handling for max_hp - also increase current HP
	if base_upgrade.stat == "max_hp":
		RunManager.current_hp += int(base_upgrade.value)
	
	RunManager.stats_changed.emit()
	
	print("[ShopGenerator] Purchased stat upgrade: %s (now %s = %s)" % [
		upgrade_id, base_upgrade.stat, _get_current_stat_value(base_upgrade.stat)
	])
	
	return true


func reset_shop_state() -> void:
	"""Reset shop state for new run."""
	_reset_stat_purchase_counts()


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
