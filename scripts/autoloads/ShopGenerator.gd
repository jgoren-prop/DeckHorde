extends Node
## ShopGenerator - V5 Brotato-style shop with category biasing
## Uses 8 V5 categories for build identity
## V5: Interest system, new pricing, stat upgrades
## V5.1: Magnetism system - bias towards owned weapon types and artifact synergies

# V5 Category definitions (from TagConstants)
const CATEGORIES: Array[String] = ["kinetic", "thermal", "arcane", "fortress", "shadow", "utility", "control", "volatile"]

# =============================================================================
# V5.1 MAGNETISM SYSTEM - Weapon Family Definitions
# =============================================================================
# Cards are grouped into "weapon families" for magnetism. If you own cards from
# a family, you're more likely to see more of that family in the shop.

const WEAPON_FAMILIES: Dictionary = {
	"pistol": ["pistol", "heavy_pistol", "double_tap"],
	"shotgun": ["shotgun", "reckless_blast"],
	"rifle": ["assault_rifle", "sniper_rifle", "burst_fire", "precision_shot", "marksman", "chain_gun"],
	"grenade": ["frag_grenade", "cluster_bomb", "rocket", "firebomb", "inferno", "napalm_strike"],
	"hex": ["hex_bolt", "curse_wave", "hex_detonation", "spreading_plague", "dark_ritual"],
	"lifesteal": ["soul_drain", "life_siphon", "blood_rocket"],
	"armor": ["shield_bash", "iron_volley", "bulwark_shot", "fortified_barrage", "reactive_shell", "siege_cannon"],
	"crit": ["assassins_strike", "shadow_bolt", "killing_blow", "shadow_barrage", "backstab"],
	"multi_hit": ["rapid_fire", "chain_gun", "burst_fire", "assault_rifle", "cluster_bomb", "shadow_barrage"],
	"burn": ["incendiary", "firebomb", "inferno", "napalm_strike", "overcharge"],
	"control": ["repulsor", "barrier_shot", "lockdown", "far_strike", "killzone", "perimeter"],
	"volatile": ["overcharge", "reckless_blast", "blood_rocket", "unstable_core", "kamikaze_swarm", "desperation", "overdrive"],
}

# Magnetism weights - how much to boost based on ownership
const MAGNETISM_WEAPON_FAMILY_BASE: float = 0.3  # Per owned card in family
const MAGNETISM_WEAPON_FAMILY_CAP: float = 1.5   # Maximum family bonus
const MAGNETISM_ARTIFACT_SYNERGY: float = 0.4    # Per synergistic artifact
const MAGNETISM_STAT_SYNERGY: float = 0.25       # Per relevant stat point (scaled)

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

# Base prices by rarity (Brotato-style: cheaper early game)
const RARITY_BASE_PRICES: Dictionary = {
	0: 10,   # Common: 8-12 (was 12-18)
	1: 25,   # Uncommon: 20-30 (was 30-45)
	2: 50,   # Rare: 40-60 (was 65-85)
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
		"base_price": 25,  # Reduced from 45 - critical early stat
		"price_increment": 15,
		"cap": 8,
	},
	"energy_up": {
		"name": "+1 Energy",
		"icon": "⚡",
		"description": "+1 energy per turn",
		"stat": "energy_per_turn",
		"value": 1,
		"base_price": 30,  # Reduced from 55 - critical early stat
		"price_increment": 20,
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
# V5.1 MAGNETISM SYSTEM
# =============================================================================

func _get_card_weapon_families(card_id: String) -> Array[String]:
	"""Get all weapon families a card belongs to."""
	var families: Array[String] = []
	for family: String in WEAPON_FAMILIES:
		if card_id in WEAPON_FAMILIES[family]:
			families.append(family)
	return families


func _get_owned_weapon_family_counts() -> Dictionary:
	"""Count how many cards the player owns in each weapon family."""
	var counts: Dictionary = {}
	for family: String in WEAPON_FAMILIES:
		counts[family] = 0
	
	for entry: Dictionary in RunManager.deck:
		var card_id: String = entry.card_id
		var card_count: int = entry.get("count", 1)
		for family: String in WEAPON_FAMILIES:
			if card_id in WEAPON_FAMILIES[family]:
				counts[family] += card_count
	
	return counts


func _calculate_weapon_family_magnetism(card) -> float:
	"""Calculate magnetism bonus for a card based on owned weapon families."""
	if card == null:
		return 0.0
	
	var family_counts: Dictionary = _get_owned_weapon_family_counts()
	var card_families: Array[String] = _get_card_weapon_families(card.card_id)
	
	var total_bonus: float = 0.0
	for family: String in card_families:
		var owned: int = family_counts.get(family, 0)
		if owned > 0:
			# Scale bonus: first owned card gives full bonus, diminishing returns
			var family_bonus: float = MAGNETISM_WEAPON_FAMILY_BASE * sqrt(float(owned))
			total_bonus += minf(family_bonus, MAGNETISM_WEAPON_FAMILY_CAP)
	
	return total_bonus


func _calculate_artifact_synergy_magnetism(card) -> float:
	"""Calculate magnetism bonus based on artifact synergies."""
	if card == null:
		return 0.0
	
	var total_bonus: float = 0.0
	var equipped: Array = ArtifactManager.get_equipped_artifacts()
	
	for artifact_id: String in equipped:
		var artifact = ArtifactManager.get_artifact(artifact_id)
		if artifact == null:
			continue
		
		# Check if artifact boosts this card's damage type
		var trigger: String = artifact.trigger_type
		
		# Kinetic synergy
		if trigger in ["on_kinetic_attack", "on_kinetic_kill"]:
			if card.damage_type == "kinetic" or card.kinetic_scaling > 0:
				total_bonus += MAGNETISM_ARTIFACT_SYNERGY
		
		# Thermal synergy
		if trigger in ["on_thermal_attack", "on_thermal_kill"]:
			if card.damage_type == "thermal" or card.thermal_scaling > 0:
				total_bonus += MAGNETISM_ARTIFACT_SYNERGY
		
		# Arcane synergy
		if trigger in ["on_arcane_damage", "on_arcane_kill"]:
			if card.damage_type == "arcane" or card.arcane_scaling > 0:
				total_bonus += MAGNETISM_ARTIFACT_SYNERGY
		
		# Shadow/crit synergy
		if trigger in ["on_shadow_crit", "on_crit"]:
			if card.has_category("Shadow") or card.crit_chance_bonus > 0:
				total_bonus += MAGNETISM_ARTIFACT_SYNERGY
		
		# Fortress synergy
		if trigger in ["on_fortress_play", "on_armor_gain"]:
			if card.has_category("Fortress") or card.armor_amount > 0:
				total_bonus += MAGNETISM_ARTIFACT_SYNERGY
		
		# Control/barrier synergy
		if trigger in ["on_barrier_trigger"]:
			if card.has_category("Control") or "barrier" in card.effect_params:
				total_bonus += MAGNETISM_ARTIFACT_SYNERGY
		
		# Volatile synergy (self-damage)
		if trigger in ["on_player_damage"]:
			if card.has_category("Volatile") or card.self_damage > 0:
				total_bonus += MAGNETISM_ARTIFACT_SYNERGY
		
		# Utility synergy (card play/draw)
		if trigger in ["on_card_play", "on_draw", "on_first_utility"]:
			if card.has_category("Utility") or card.cards_to_draw > 0:
				total_bonus += MAGNETISM_ARTIFACT_SYNERGY
	
	return total_bonus


func _calculate_stat_synergy_magnetism(card) -> float:
	"""Calculate magnetism bonus based on player stats that would benefit this card."""
	if card == null:
		return 0.0
	
	var stats = RunManager.player_stats
	if stats == null:
		return 0.0
	
	var total_bonus: float = 0.0
	
	# Cards with scaling benefit from flat stat investment
	if card.kinetic_scaling > 0:
		var kinetic_stat: int = stats.get_flat_damage_stat("kinetic")
		if kinetic_stat > 0:
			# Scale logarithmically to avoid excessive bonus
			total_bonus += MAGNETISM_STAT_SYNERGY * log(1.0 + float(kinetic_stat) / 5.0)
	
	if card.thermal_scaling > 0:
		var thermal_stat: int = stats.get_flat_damage_stat("thermal")
		if thermal_stat > 0:
			total_bonus += MAGNETISM_STAT_SYNERGY * log(1.0 + float(thermal_stat) / 5.0)
	
	if card.arcane_scaling > 0:
		var arcane_stat: int = stats.get_flat_damage_stat("arcane")
		if arcane_stat > 0:
			total_bonus += MAGNETISM_STAT_SYNERGY * log(1.0 + float(arcane_stat) / 5.0)
	
	if card.armor_start_scaling > 0:
		var armor_stat: int = stats.get_flat_damage_stat("armor_start")
		if armor_stat > 0:
			total_bonus += MAGNETISM_STAT_SYNERGY * log(1.0 + float(armor_stat) / 3.0)
	
	if card.crit_chance_bonus > 0 or card.crit_damage_scaling > 0:
		var crit_chance: float = stats.get_crit_chance()
		if crit_chance > 0.05:  # More than base 5%
			total_bonus += MAGNETISM_STAT_SYNERGY * (crit_chance - 0.05) * 5.0
	
	return total_bonus


func _calculate_card_magnetism(card) -> float:
	"""Calculate total magnetism score for a card."""
	if card == null:
		return 0.0
	
	var weapon_family: float = _calculate_weapon_family_magnetism(card)
	var artifact_synergy: float = _calculate_artifact_synergy_magnetism(card)
	var stat_synergy: float = _calculate_stat_synergy_magnetism(card)
	
	return weapon_family + artifact_synergy + stat_synergy


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
	"""Calculate category weights for biased sampling (including artifact synergies)."""
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
	
	# V5.1: Boost categories based on artifact synergies
	var artifact_category_bonuses: Dictionary = _get_artifact_category_bonuses()
	for category: String in artifact_category_bonuses:
		if weights.has(category):
			weights[category] += artifact_category_bonuses[category]
	
	return weights


func _get_artifact_category_bonuses() -> Dictionary:
	"""Get category weight bonuses from equipped artifacts."""
	var bonuses: Dictionary = {}
	var equipped: Array = ArtifactManager.get_equipped_artifacts()
	
	for artifact_id: String in equipped:
		var artifact = ArtifactManager.get_artifact(artifact_id)
		if artifact == null:
			continue
		
		var trigger: String = artifact.trigger_type
		var bonus: float = 0.3  # Per artifact
		
		# Map artifact triggers to categories
		if trigger in ["on_kinetic_attack", "on_kinetic_kill"]:
			bonuses["kinetic"] = bonuses.get("kinetic", 0.0) + bonus
		elif trigger in ["on_thermal_attack", "on_thermal_kill"]:
			bonuses["thermal"] = bonuses.get("thermal", 0.0) + bonus
		elif trigger in ["on_arcane_damage", "on_arcane_kill"]:
			bonuses["arcane"] = bonuses.get("arcane", 0.0) + bonus
		elif trigger in ["on_fortress_play", "on_armor_gain"]:
			bonuses["fortress"] = bonuses.get("fortress", 0.0) + bonus
		elif trigger in ["on_shadow_crit"]:
			bonuses["shadow"] = bonuses.get("shadow", 0.0) + bonus
		elif trigger in ["on_first_utility", "on_card_play", "on_draw"]:
			bonuses["utility"] = bonuses.get("utility", 0.0) + bonus
		elif trigger in ["on_barrier_trigger"]:
			bonuses["control"] = bonuses.get("control", 0.0) + bonus
		elif trigger in ["on_player_damage"]:
			bonuses["volatile"] = bonuses.get("volatile", 0.0) + bonus
		
		# Also check stat modifiers for category affinity
		if artifact.stat_modifiers.size() > 0:
			if artifact.stat_modifiers.has("kinetic") or artifact.stat_modifiers.has("kinetic_percent"):
				bonuses["kinetic"] = bonuses.get("kinetic", 0.0) + bonus * 0.5
			if artifact.stat_modifiers.has("thermal") or artifact.stat_modifiers.has("thermal_percent"):
				bonuses["thermal"] = bonuses.get("thermal", 0.0) + bonus * 0.5
			if artifact.stat_modifiers.has("arcane") or artifact.stat_modifiers.has("arcane_percent"):
				bonuses["arcane"] = bonuses.get("arcane", 0.0) + bonus * 0.5
			if artifact.stat_modifiers.has("armor_start"):
				bonuses["fortress"] = bonuses.get("fortress", 0.0) + bonus * 0.5
			if artifact.stat_modifiers.has("crit_chance") or artifact.stat_modifiers.has("crit_damage"):
				bonuses["shadow"] = bonuses.get("shadow", 0.0) + bonus * 0.5
	
	return bonuses


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
	"""Get a magnetism-weighted card from a specific V5 category."""
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
		return _select_card_with_magnetism(available)
	
	# Fallback to any card
	return _get_random_card(exclude_ids, wave)


func _get_random_card(exclude_ids: Array, wave: int):
	"""Get a magnetism-weighted card from any category."""
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
		return _select_card_with_magnetism(available)
	return null


func _select_card_with_magnetism(available_cards: Array):
	"""Select a card from available pool using magnetism-weighted random selection.
	Cards that synergize with your build have higher chance to appear."""
	if available_cards.size() == 0:
		return null
	
	if available_cards.size() == 1:
		return available_cards[0]
	
	# Calculate weights for each card
	var weights: Array[float] = []
	var total_weight: float = 0.0
	
	for card in available_cards:
		# Base weight of 1.0 for all cards
		var weight: float = 1.0
		
		# Add magnetism bonus
		var magnetism: float = _calculate_card_magnetism(card)
		weight += magnetism
		
		weights.append(weight)
		total_weight += weight
	
	# Weighted random selection
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	
	for i: int in range(available_cards.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return available_cards[i]
	
	# Fallback to last card (shouldn't happen)
	return available_cards[available_cards.size() - 1]


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
# ARTIFACT GENERATION (V5.1 with magnetism)
# =============================================================================

func generate_shop_artifacts(_wave: int) -> Array:
	"""Generate artifact offers for the shop with magnetism bias."""
	var artifacts: Array = []
	var used_ids: Array = []
	
	for _slot: int in range(ARTIFACT_SLOTS):
		var artifact: Dictionary = _get_random_artifact_with_magnetism(used_ids)
		if artifact.size() > 0:
			artifacts.append(artifact)
			used_ids.append(artifact.artifact_id)
	
	return artifacts


func _get_random_artifact(exclude_ids: Array) -> Dictionary:
	"""Get a random artifact (legacy, no magnetism)."""
	var available: Array = ArtifactManager.get_available_artifacts()
	var filtered: Array = []
	
	for artifact: Dictionary in available:
		if artifact.artifact_id not in exclude_ids:
			filtered.append(artifact)
	
	if filtered.size() > 0:
		return filtered[randi() % filtered.size()]
	return {}


func _get_random_artifact_with_magnetism(exclude_ids: Array) -> Dictionary:
	"""Get an artifact using magnetism-weighted selection.
	Artifacts that synergize with your cards/stats appear more often."""
	var available: Array = ArtifactManager.get_available_artifacts()
	var filtered: Array = []
	
	for artifact: Dictionary in available:
		if artifact.artifact_id not in exclude_ids:
			filtered.append(artifact)
	
	if filtered.size() == 0:
		return {}
	
	if filtered.size() == 1:
		return filtered[0]
	
	# Calculate weights based on build synergy
	var weights: Array[float] = []
	var total_weight: float = 0.0
	var categories_data: Dictionary = get_primary_secondary_categories()
	var primary_cat: String = categories_data.primary.to_lower() if categories_data.primary != "" else ""
	var secondary_cat: String = categories_data.secondary.to_lower() if categories_data.secondary != "" else ""
	
	for artifact: Dictionary in filtered:
		var weight: float = 1.0
		var artifact_id: String = artifact.artifact_id
		var full_artifact = ArtifactManager.get_artifact(artifact_id)
		
		if full_artifact:
			# Boost artifacts that match player's damage type focus
			if full_artifact.stat_modifiers.size() > 0:
				# Check for category alignment
				if primary_cat != "":
					if full_artifact.stat_modifiers.has(primary_cat) or \
					   full_artifact.stat_modifiers.has(primary_cat + "_percent"):
						weight += 0.8  # Strong bonus for primary category match
				
				if secondary_cat != "":
					if full_artifact.stat_modifiers.has(secondary_cat) or \
					   full_artifact.stat_modifiers.has(secondary_cat + "_percent"):
						weight += 0.4  # Moderate bonus for secondary category match
			
			# Boost artifacts with triggers that match owned cards
			var trigger: String = full_artifact.trigger_type
			if trigger != "passive" and trigger != "":
				# Check if player has cards that would trigger this
				var trigger_bonus: float = _get_artifact_trigger_synergy(trigger)
				weight += trigger_bonus
		
		weights.append(weight)
		total_weight += weight
	
	# Weighted random selection
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	
	for i: int in range(filtered.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return filtered[i]
	
	return filtered[filtered.size() - 1]


func _get_artifact_trigger_synergy(trigger: String) -> float:
	"""Calculate synergy bonus for an artifact trigger based on owned cards."""
	var bonus: float = 0.0
	
	for entry: Dictionary in RunManager.deck:
		var card = CardDatabase.get_card(entry.card_id)
		if card == null:
			continue
		
		var count: int = entry.get("count", 1)
		var match_found: bool = false
		
		# Check trigger alignment with card properties
		match trigger:
			"on_kinetic_attack", "on_kinetic_kill":
				if card.damage_type == "kinetic" or card.kinetic_scaling > 0:
					match_found = true
			"on_thermal_attack", "on_thermal_kill":
				if card.damage_type == "thermal" or card.thermal_scaling > 0:
					match_found = true
			"on_arcane_damage", "on_arcane_kill":
				if card.damage_type == "arcane" or card.arcane_scaling > 0:
					match_found = true
			"on_crit", "on_shadow_crit":
				if card.crit_chance_bonus > 0 or card.has_category("Shadow"):
					match_found = true
			"on_fortress_play", "on_armor_gain":
				if card.armor_amount > 0 or card.has_category("Fortress"):
					match_found = true
			"on_kill":
				# Most cards can trigger on-kill
				match_found = true
			"on_player_damage":
				if card.self_damage > 0 or card.has_category("Volatile"):
					match_found = true
			"on_draw", "on_card_play":
				if card.cards_to_draw > 0 or card.has_category("Utility"):
					match_found = true
		
		if match_found:
			bonus += 0.15 * sqrt(float(count))  # Diminishing returns per card
	
	return minf(bonus, 1.0)  # Cap at 1.0 bonus


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
