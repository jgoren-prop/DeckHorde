extends Node
## ShopGenerator - V5 Brotato-style shop with category biasing
## Uses 8 V5 categories for build identity
## V5: Interest system, new pricing, stat upgrades

# V5 Category definitions (from TagConstants)
const CATEGORIES: Array[String] = ["kinetic", "thermal", "arcane", "fortress", "shadow", "utility", "control", "volatile"]

# Shop structure (V5)
const CARD_SLOTS: int = 4
const ARTIFACT_SLOTS: int = 3
const STAT_UPGRADE_SLOTS: int = 3
const SERVICE_SLOTS: int = 2

# V5 Reroll cost: base 2, +2 per reroll
const REROLL_BASE_COST: int = 2
const REROLL_PER_REROLL_COST: int = 2

# Track rerolls per shop visit
var current_shop_reroll_count: int = 0

# =============================================================================
# V5 CARD PRICING
# =============================================================================

# Base prices by rarity (average of V5 ranges)
const RARITY_BASE_PRICES: Dictionary = {
	0: 15,   # Common: 12-18
	1: 38,   # Uncommon: 30-45
	2: 75,   # Rare: 65-85
}

# Tier multipliers for card prices
const TIER_PRICE_MULTIPLIERS: Dictionary = {
	1: 1.0,
	2: 1.8,
	3: 3.0,
	4: 4.5,
}

# =============================================================================
# V5 STAT UPGRADES (per DESIGN_V5.md)
# =============================================================================

const V5_STAT_UPGRADES: Dictionary = {
	"kinetic_up": {
		"name": "+3 Kinetic",
		"icon": "🔫",
		"description": "+3 Kinetic damage for scaling",
		"stat": "kinetic",
		"value": 3,
		"base_price": 12,
		"price_increment": 4,
	},
	"thermal_up": {
		"name": "+3 Thermal",
		"icon": "🔥",
		"description": "+3 Thermal damage for scaling",
		"stat": "thermal",
		"value": 3,
		"base_price": 12,
		"price_increment": 4,
	},
	"arcane_up": {
		"name": "+3 Arcane",
		"icon": "🔮",
		"description": "+3 Arcane damage for scaling",
		"stat": "arcane",
		"value": 3,
		"base_price": 12,
		"price_increment": 4,
	},
	"kinetic_percent_up": {
		"name": "+5% Kinetic",
		"icon": "💥",
		"description": "+5% Kinetic damage multiplier",
		"stat": "kinetic_percent",
		"value": 5.0,
		"base_price": 18,
		"price_increment": 6,
	},
	"thermal_percent_up": {
		"name": "+5% Thermal",
		"icon": "☀️",
		"description": "+5% Thermal damage multiplier",
		"stat": "thermal_percent",
		"value": 5.0,
		"base_price": 18,
		"price_increment": 6,
	},
	"arcane_percent_up": {
		"name": "+5% Arcane",
		"icon": "✨",
		"description": "+5% Arcane damage multiplier",
		"stat": "arcane_percent",
		"value": 5.0,
		"base_price": 18,
		"price_increment": 6,
	},
	"damage_percent_up": {
		"name": "+5% All Damage",
		"icon": "⚔️",
		"description": "+5% damage to ALL attacks",
		"stat": "damage_percent",
		"value": 5.0,
		"base_price": 22,
		"price_increment": 8,
	},
	"crit_chance_up": {
		"name": "+3% Crit",
		"icon": "🎯",
		"description": "+3% critical hit chance",
		"stat": "crit_chance",
		"value": 3.0,
		"base_price": 25,
		"price_increment": 8,
	},
	"crit_damage_up": {
		"name": "+10% Crit Damage",
		"icon": "💀",
		"description": "+10% critical hit damage",
		"stat": "crit_damage",
		"value": 10.0,
		"base_price": 20,
		"price_increment": 6,
	},
	"max_hp_up": {
		"name": "+5 Max HP",
		"icon": "❤️",
		"description": "+5 maximum health",
		"stat": "max_hp",
		"value": 5,
		"base_price": 12,
		"price_increment": 4,
	},
	"armor_start_up": {
		"name": "+2 Armor/Wave",
		"icon": "🛡️",
		"description": "+2 armor at wave start",
		"stat": "armor_start",
		"value": 2,
		"base_price": 15,
		"price_increment": 5,
	},
	"draw_up": {
		"name": "+1 Draw",
		"icon": "📜",
		"description": "+1 card drawn per turn",
		"stat": "draw_per_turn",
		"value": 1,
		"base_price": 45,
		"price_increment": 20,
		"cap": 8,
	},
	"energy_up": {
		"name": "+1 Energy",
		"icon": "⚡",
		"description": "+1 energy per turn",
		"stat": "energy_per_turn",
		"value": 1,
		"base_price": 55,
		"price_increment": 25,
		"cap": 6,
	},
}

# Track how many times each stat has been purchased this run
var stat_purchase_counts: Dictionary = {}


func _ready() -> void:
	print("[ShopGenerator] V5 Brotato Economy Shop Initialized")
	_reset_stat_purchase_counts()


func _reset_stat_purchase_counts() -> void:
	"""Reset stat purchase tracking for new run."""
	stat_purchase_counts = {}
	for upgrade_id: String in V5_STAT_UPGRADES:
		stat_purchase_counts[upgrade_id] = 0


# =============================================================================
# V5 CATEGORY TRACKING
# =============================================================================

func get_owned_category_counts() -> Dictionary:
	"""Count how many cards the player owns in each V5 category."""
	var counts: Dictionary = {}
	for category: String in CATEGORIES:
		counts[category] = 0
	counts["none"] = 0
	
	# Count cards in deck
	for entry: Dictionary in RunManager.deck:
		var card = CardDatabase.get_card(entry.card_id)
		if card and card.categories:
			for category: String in card.categories:
				if counts.has(category):
					counts[category] += 1
	
	return counts


func get_primary_secondary_categories() -> Dictionary:
	"""Get the player's primary and secondary category based on owned cards."""
	var counts: Dictionary = get_owned_category_counts()
	
	var primary: String = ""
	var secondary: String = ""
	var primary_score: int = 0
	var secondary_score: int = 0
	
	for category: String in CATEGORIES:
		var score: int = counts.get(category, 0)
		if score > primary_score:
			secondary = primary
			secondary_score = primary_score
			primary = category
			primary_score = score
		elif score > secondary_score:
			secondary = category
			secondary_score = score
	
	return {
		"primary": primary,
		"primary_score": primary_score,
		"secondary": secondary,
		"secondary_score": secondary_score
	}


# =============================================================================
# V5 INTEREST SYSTEM
# =============================================================================

func calculate_interest(current_scrap: int) -> int:
	"""V5: Calculate interest earned (5% of scrap, capped at 25)."""
	var interest: int = int(float(current_scrap) * 0.05)
	return mini(interest, 25)


func award_interest() -> int:
	"""Award interest based on current scrap. Returns amount awarded."""
	var interest: int = calculate_interest(RunManager.scrap)
	if interest > 0:
		RunManager.add_scrap(interest)
		print("[ShopGenerator V5] Interest awarded: +", interest, " scrap (from ", RunManager.scrap - interest, ")")
	return interest


# =============================================================================
# V5 SHOP GENERATION
# =============================================================================

func generate_shop_cards(wave: int) -> Array:
	"""Generate V5 category-biased card offers for the shop."""
	var cards: Array = []
	var used_ids: Array = []
	
	if wave <= 3:
		# Early waves: Strong push into one category
		cards = _generate_early_wave_cards(wave, used_ids)
	else:
		# Later waves: Bias toward player's build
		cards = _generate_late_wave_cards(wave, used_ids)
	
	return cards


func _generate_early_wave_cards(wave: int, used_ids: Array) -> Array:
	"""Generate cards for waves 1-3 with category focus."""
	var cards: Array = []
	
	# 70% chance to focus on a category
	var do_focus: bool = randf() < 0.7
	var focus_category: String = ""
	
	if do_focus:
		focus_category = CATEGORIES[randi() % CATEGORIES.size()]
	
	for slot: int in range(CARD_SLOTS):
		var card = null
		
		if do_focus:
			if slot < 2:
				# Slots 1-2: Must be from focus category
				card = _get_card_from_category(focus_category, used_ids, wave)
			elif slot == 2:
				# Slot 3: 50% focus, 50% any
				if randf() < 0.5:
					card = _get_card_from_category(focus_category, used_ids, wave)
				else:
					card = _get_random_card(used_ids, wave)
			else:
				# Slot 4: Unbiased
				card = _get_random_card(used_ids, wave)
		else:
			# No focus: all random
			card = _get_random_card(used_ids, wave)
		
		if card:
			cards.append(card)
			used_ids.append(card.card_id)
	
	return cards


func _generate_late_wave_cards(wave: int, used_ids: Array) -> Array:
	"""Generate cards for waves 4+ with adaptive biasing."""
	var cards: Array = []
	var categories_data: Dictionary = get_primary_secondary_categories()
	var weights: Dictionary = _calculate_category_weights(categories_data)
	
	var primary_count: int = 0
	var primary_category: String = categories_data.primary
	var need_primary_guarantee: bool = categories_data.primary_score >= 3  # V5: family tier 1
	
	for slot: int in range(CARD_SLOTS):
		var category: String = _sample_category_by_weight(weights)
		var card = _get_card_from_category(category, used_ids, wave)
		
		if card:
			cards.append(card)
			used_ids.append(card.card_id)
			if primary_category in card.categories:
				primary_count += 1
	
	# Guarantee at least 2 primary category cards if player has committed
	if need_primary_guarantee and primary_count < 2 and cards.size() >= 2:
		var replacement = _get_card_from_category(primary_category, used_ids, wave)
		if replacement:
			cards[cards.size() - 1] = replacement
	
	return cards


func _calculate_category_weights(categories_data: Dictionary) -> Dictionary:
	"""Calculate category weights for biased sampling."""
	var weights: Dictionary = {}
	
	# Base weight for all categories
	for category: String in CATEGORIES:
		weights[category] = 1.0
	
	# Boost primary category
	if categories_data.primary != "":
		weights[categories_data.primary] += 2.0
	
	# Boost secondary category
	if categories_data.secondary != "":
		weights[categories_data.secondary] += 1.0
	
	return weights


func _sample_category_by_weight(weights: Dictionary) -> String:
	"""Sample a category based on weights."""
	var total: float = 0.0
	for category: String in weights:
		total += weights[category]
	
	var roll: float = randf() * total
	var cumulative: float = 0.0
	
	for category: String in weights:
		cumulative += weights[category]
		if roll <= cumulative:
			return category
	
	return CATEGORIES[0]


func _get_card_from_category(category: String, exclude_ids: Array, wave: int):
	"""Get a random card from a specific V5 category."""
	var available: Array = []
	
	# Determine max tier based on wave
	var max_tier: int = _get_max_tier_for_wave(wave)
	
	for card_id: String in CardDatabase.cards:
		if card_id in exclude_ids:
			continue
		var card = CardDatabase.get_card(card_id)
		if card and card.categories and category in card.categories:
			# Check tier availability
			var card_tier: int = card.tier if "tier" in card else 1
			if card_tier <= max_tier:
				available.append(card)
	
	if available.size() > 0:
		return available[randi() % available.size()]
	
	# Fallback to any card
	return _get_random_card(exclude_ids, wave)


func _get_random_card(exclude_ids: Array, wave: int):
	"""Get a random card from any category."""
	var max_tier: int = _get_max_tier_for_wave(wave)
	var available: Array = []
	
	for card_id: String in CardDatabase.cards:
		if card_id in exclude_ids:
			continue
		var card = CardDatabase.get_card(card_id)
		if card:
			var card_tier: int = card.tier if "tier" in card else 1
			if card_tier <= max_tier:
				available.append(card)
	
	if available.size() > 0:
		return available[randi() % available.size()]
	return null


func _get_max_tier_for_wave(wave: int) -> int:
	"""Determine max card tier available based on wave."""
	if wave >= 15:
		return 4  # Tier 4 from wave 15+
	elif wave >= 10:
		return 3  # Tier 3 from wave 10+
	elif wave >= 5:
		return 2  # Tier 2 from wave 5+
	else:
		return 1  # Only Tier 1 early


# =============================================================================
# V5 CARD PRICING
# =============================================================================

func get_card_price(card, _wave: int) -> int:
	"""Calculate V5 card price based on rarity and tier."""
	var rarity: int = card.rarity if "rarity" in card else 0
	var tier: int = card.tier if "tier" in card else 1
	
	# Get base price from rarity
	var base_price: int = RARITY_BASE_PRICES.get(rarity, 15)
	
	# Apply tier multiplier
	var tier_mult: float = TIER_PRICE_MULTIPLIERS.get(tier, 1.0)
	var price: int = int(float(base_price) * tier_mult)
	
	# Apply shop price discount from PlayerStats
	var price_mult: float = RunManager.player_stats.get_shop_price_multiplier()
	return int(float(price) * price_mult)


# =============================================================================
# V5 STAT UPGRADE GENERATION
# =============================================================================

func generate_shop_stat_upgrades() -> Array:
	"""Generate V5 stat upgrade offers for the shop."""
	var upgrades: Array = []
	var available_ids: Array = _get_available_stat_upgrade_ids()
	
	if available_ids.size() == 0:
		return upgrades
	
	available_ids.shuffle()
	var count: int = mini(STAT_UPGRADE_SLOTS, available_ids.size())
	
	for i: int in range(count):
		var upgrade_id: String = available_ids[i]
		var upgrade_data: Dictionary = _create_stat_upgrade_offer(upgrade_id)
		upgrades.append(upgrade_data)
	
	return upgrades


func _get_available_stat_upgrade_ids() -> Array:
	"""Get stat upgrades that haven't hit their cap."""
	var available: Array = []
	
	for upgrade_id: String in V5_STAT_UPGRADES:
		if _can_purchase_stat_upgrade(upgrade_id):
			available.append(upgrade_id)
	
	return available


func _can_purchase_stat_upgrade(upgrade_id: String) -> bool:
	"""Check if a stat upgrade can still be purchased."""
	var upgrade: Dictionary = V5_STAT_UPGRADES.get(upgrade_id, {})
	if upgrade.size() == 0:
		return false
	
	var cap: int = upgrade.get("cap", -1)
	if cap > 0:
		var current_value = _get_current_stat_value(upgrade.stat)
		if current_value >= cap:
			return false
	
	return true


func _get_current_stat_value(stat_name: String) -> Variant:
	"""Get current value of a stat from PlayerStats."""
	var stats = RunManager.player_stats
	return stats.get(stat_name) if stats else 0


func _create_stat_upgrade_offer(upgrade_id: String) -> Dictionary:
	"""Create a shop offer for a V5 stat upgrade."""
	var base_upgrade: Dictionary = V5_STAT_UPGRADES.get(upgrade_id, {})
	var purchase_count: int = stat_purchase_counts.get(upgrade_id, 0)
	
	# V5: Linear price scaling (base + increment * purchase_count)
	var base_price: int = base_upgrade.base_price
	var increment: int = base_upgrade.price_increment
	var price: int = base_price + (increment * purchase_count)
	
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
	"""Purchase a V5 stat upgrade. Returns true if successful."""
	if not _can_purchase_stat_upgrade(upgrade_id):
		print("[ShopGenerator V5] Cannot purchase stat upgrade: %s (at cap)" % upgrade_id)
		return false
	
	var offer: Dictionary = _create_stat_upgrade_offer(upgrade_id)
	
	if not RunManager.spend_scrap(offer.price):
		print("[ShopGenerator V5] Cannot purchase stat upgrade: not enough scrap")
		return false
	
	# Apply the upgrade
	var base_upgrade: Dictionary = V5_STAT_UPGRADES.get(upgrade_id, {})
	RunManager.player_stats.apply_modifier(base_upgrade.stat, base_upgrade.value)
	
	# Track purchase
	stat_purchase_counts[upgrade_id] = stat_purchase_counts.get(upgrade_id, 0) + 1
	
	# Special handling for max_hp - also increase current HP
	if base_upgrade.stat == "max_hp":
		RunManager.current_hp += int(base_upgrade.value)
	
	RunManager.stats_changed.emit()
	
	print("[ShopGenerator V5] Purchased: %s (+%s %s)" % [
		base_upgrade.name, base_upgrade.value, base_upgrade.stat
	])
	
	return true


# =============================================================================
# V5 REROLL SYSTEM
# =============================================================================

func get_reroll_cost(_wave: int = 0, reroll_count: int = -1) -> int:
	"""V5 reroll cost: base 2, +2 per reroll."""
	var actual_count: int = reroll_count if reroll_count >= 0 else current_shop_reroll_count
	var cost: int = REROLL_BASE_COST + (REROLL_PER_REROLL_COST * actual_count)
	
	# Apply shop price discount
	var price_mult: float = RunManager.player_stats.get_shop_price_multiplier()
	return int(float(cost) * price_mult)


func increment_reroll_count() -> void:
	"""Increment reroll count for current shop visit."""
	current_shop_reroll_count += 1


func reset_shop_reroll_count() -> void:
	"""Reset reroll count when entering a new shop."""
	current_shop_reroll_count = 0


# =============================================================================
# V5 SERVICE COSTS
# =============================================================================

func get_remove_card_cost(wave: int) -> int:
	"""V5: Remove card cost = 15 + (wave × 3)."""
	return 15 + (wave * 3)


func get_heal_cost(wave: int) -> int:
	"""Calculate heal cost: 10 + 2 * wave."""
	return 10 + 2 * wave


# =============================================================================
# ARTIFACT GENERATION (stub for V5 artifacts)
# =============================================================================

func generate_shop_artifacts(_wave: int) -> Array:
	"""Generate artifact offers for the shop."""
	var artifacts: Array = []
	var used_ids: Array = []
	
	for _slot: int in range(ARTIFACT_SLOTS):
		var artifact: Dictionary = _get_random_artifact(used_ids)
		if artifact.size() > 0:
			artifacts.append(artifact)
			used_ids.append(artifact.artifact_id)
	
	return artifacts


func _get_random_artifact(exclude_ids: Array) -> Dictionary:
	"""Get a random artifact."""
	var available: Array = ArtifactManager.get_available_artifacts()
	var filtered: Array = []
	
	for artifact: Dictionary in available:
		if artifact.artifact_id not in exclude_ids:
			filtered.append(artifact)
	
	if filtered.size() > 0:
		return filtered[randi() % filtered.size()]
	return {}


# =============================================================================
# SHOP STATE MANAGEMENT
# =============================================================================

# V4: Track if shop clearing reward is available
var _shop_clearing_reward_available: bool = false

func reset_shop_state() -> void:
	"""Reset shop state for new run."""
	_reset_stat_purchase_counts()
	reset_shop_reroll_count()
	_shop_clearing_reward_available = false


# =============================================================================
# V4 SHOP CLEARING REWARD
# =============================================================================

func check_shop_clearing_reward(cards_remaining: int, artifacts_remaining: int) -> bool:
	"""V4: Check if player cleared the shop (bought all cards and artifacts).
	If cleared, grants a free reroll. Returns true if reward was granted."""
	if cards_remaining == 0 and artifacts_remaining == 0:
		if not _shop_clearing_reward_available:
			_shop_clearing_reward_available = true
			print("[ShopGenerator V4] Shop cleared! Free reroll available.")
			return true
	return false


func has_shop_clearing_reward() -> bool:
	"""V4: Check if a shop clearing reward (free reroll) is available."""
	return _shop_clearing_reward_available


func consume_shop_clearing_reward() -> bool:
	"""V4: Consume the shop clearing reward. Returns true if consumed."""
	if _shop_clearing_reward_available:
		_shop_clearing_reward_available = false
		print("[ShopGenerator V4] Shop clearing reward consumed.")
		return true
	return false


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
	
	var categories_data: Dictionary = get_primary_secondary_categories()
	var weights: Dictionary = _calculate_category_weights(categories_data)
	var used_ids: Array = []
	
	# 2 card rewards
	for _i: int in range(2):
		var category: String = _sample_category_by_weight(weights)
		var card = _get_card_from_category(category, used_ids, wave)
		if card:
			rewards.cards.append(card)
			used_ids.append(card.card_id)
	
	# Flex slot (card or artifact)
	var artifact_chance: float = 0.5 if wave > 3 else 0.7
	if randf() < artifact_chance:
		var artifact: Dictionary = _get_random_artifact([])
		if artifact.size() > 0:
			rewards.flex = artifact
			rewards.flex_is_artifact = true
	
	if rewards.flex == null:
		var category: String = _sample_category_by_weight(weights)
		var card = _get_card_from_category(category, used_ids, wave)
		if card:
			rewards.flex = card
			rewards.flex_is_artifact = false
	
	return rewards
