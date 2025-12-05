extends RefCounted
class_name TagConstants
## TagConstants - V5 Category and Damage Type System
## Based on DESIGN_V5.md with 3 damage types and 8 weapon categories
##
## V5 DESIGN: Categories determine family buff eligibility, Types determine % multipliers

# =============================================================================
# V5 DAMAGE TYPES (determines which % multipliers apply)
# =============================================================================
# Every weapon has exactly one damage type that determines which percentage
# bonus applies to its damage.

const TYPE_KINETIC: String = "kinetic"   # Physical projectiles
const TYPE_THERMAL: String = "thermal"   # Fire, explosions, burn
const TYPE_ARCANE: String = "arcane"     # Curses, magic, hex

const DAMAGE_TYPES: Array[String] = [
	TYPE_KINETIC,
	TYPE_THERMAL,
	TYPE_ARCANE,
]

# =============================================================================
# V5 WEAPON CATEGORIES (determines scaling and family buffs)
# =============================================================================
# Every weapon has 1-2 categories. Categories determine:
# 1. Which flat stats the weapon SCALES with
# 2. Which family buffs the card counts toward

const CAT_KINETIC: String = "Kinetic"     # Reliable guns, scales with Kinetic stat
const CAT_THERMAL: String = "Thermal"     # Explosions, scales with Thermal stat + AOE
const CAT_ARCANE: String = "Arcane"       # Curses, scales with Arcane stat + Hex
const CAT_FORTRESS: String = "Fortress"   # Tanky offense, scales with Armor
const CAT_SHADOW: String = "Shadow"       # Assassin, scales with Crit stats
const CAT_UTILITY: String = "Utility"     # Combo engine, scales with Cards Played + Draw
const CAT_CONTROL: String = "Control"     # Tower defense, scales with Barriers + Ring position
const CAT_VOLATILE: String = "Volatile"   # Glass cannon, scales with Missing HP + Self-damage

const CATEGORIES: Array[String] = [
	CAT_KINETIC,
	CAT_THERMAL,
	CAT_ARCANE,
	CAT_FORTRESS,
	CAT_SHADOW,
	CAT_UTILITY,
	CAT_CONTROL,
	CAT_VOLATILE,
]

# =============================================================================
# V5 FAMILY BUFF THRESHOLDS
# =============================================================================
# Tier 1: 3-5 cards of category
# Tier 2: 6-8 cards of category
# Tier 3: 9+ cards of category

const FAMILY_TIER_1_MIN: int = 3
const FAMILY_TIER_1_MAX: int = 5
const FAMILY_TIER_2_MIN: int = 6
const FAMILY_TIER_2_MAX: int = 8
const FAMILY_TIER_3_MIN: int = 9

# Family buff values per category per tier
# Format: { category: [tier1_value, tier2_value, tier3_value] }
const FAMILY_BUFFS: Dictionary = {
	CAT_KINETIC: {"stat": "kinetic", "values": [3, 6, 10]},
	CAT_THERMAL: {"stat": "thermal", "values": [3, 6, 10]},
	CAT_ARCANE: {"stat": "arcane", "values": [3, 6, 10]},
	CAT_FORTRESS: {"stat": "armor_start", "values": [3, 6, 10]},
	CAT_SHADOW: {"stat": "crit_chance", "values": [5, 10, 15]},
	CAT_UTILITY: {"stat": "draw_per_turn", "values": [1, 2, 3]},
	CAT_CONTROL: {"stat": "barriers", "type": "special", "values": [1, 1, 2], "barrier_damage": [2, 3, 3]},
	CAT_VOLATILE: {"stat": "max_hp", "values": [5, 12, 20]},
}

# =============================================================================
# V5 CARD SUBTYPES (for non-weapon cards)
# =============================================================================

const SUBTYPE_WEAPON: String = "weapon"     # Deals damage, has tiers
const SUBTYPE_INSTANT: String = "instant"   # Utility, no tiers, no merging

# =============================================================================
# LEGACY TAGS (for backward compatibility during migration)
# =============================================================================

const TAG_GUN: String = "gun"           # Maps to CAT_KINETIC
const TAG_HEX: String = "hex"           # Maps to CAT_ARCANE
const TAG_BARRIER: String = "barrier"   # Maps to CAT_CONTROL
const TAG_DEFENSE: String = "defense"   # Maps to CAT_FORTRESS
const TAG_SKILL: String = "skill"       # Maps to SUBTYPE_INSTANT
const TAG_ENGINE: String = "engine"     # Maps to CAT_UTILITY

const CORE_TYPES: Array[String] = [
	TAG_GUN,
	TAG_HEX,
	TAG_BARRIER,
	TAG_DEFENSE,
	TAG_SKILL,
	TAG_ENGINE,
]

# Legacy family tags (mapped to V5 categories)
const TAG_LIFEDRAIN: String = "lifedrain"
const TAG_HEX_RITUAL: String = "hex_ritual"
const TAG_FORTRESS: String = "fortress"
const TAG_BARRIER_TRAP: String = "barrier_trap"
const TAG_VOLATILE: String = "volatile"
const TAG_ENGINE_CORE: String = "engine_core"

const FAMILY_TAGS: Array[String] = [
	TAG_LIFEDRAIN,
	TAG_HEX_RITUAL,
	TAG_FORTRESS,
	TAG_BARRIER_TRAP,
	TAG_VOLATILE,
	TAG_ENGINE_CORE,
]

# Legacy mechanical tags
const TAG_AOE: String = "aoe"
const TAG_SNIPER: String = "sniper"
const TAG_SHOTGUN: String = "shotgun"
const TAG_RING_CONTROL: String = "ring_control"

# =============================================================================
# ALL VALID TAGS (V5 + Legacy)
# =============================================================================

const ALL_TAGS: Array[String] = [
	# V5 Damage types
	"kinetic", "thermal", "arcane",
	# V5 Categories
	"Kinetic", "Thermal", "Arcane", "Fortress", "Shadow", "Utility", "Control", "Volatile",
	# Legacy core types
	"gun", "hex", "barrier", "defense", "skill", "engine",
	# Legacy family tags
	"lifedrain", "hex_ritual", "fortress", "barrier_trap", "volatile", "engine_core",
	# Mechanical tags
	"aoe", "sniper", "shotgun", "ring_control",
]

# =============================================================================
# V5 HELPER FUNCTIONS
# =============================================================================

static func is_valid_damage_type(dtype: String) -> bool:
	"""Check if a string is a valid V5 damage type."""
	return dtype in DAMAGE_TYPES


static func is_valid_category(category: String) -> bool:
	"""Check if a string is a valid V5 weapon category."""
	return category in CATEGORIES


static func get_family_buff_tier(card_count: int) -> int:
	"""Get the family buff tier for a given card count. Returns 0-3."""
	if card_count >= FAMILY_TIER_3_MIN:
		return 3
	elif card_count >= FAMILY_TIER_2_MIN:
		return 2
	elif card_count >= FAMILY_TIER_1_MIN:
		return 1
	else:
		return 0


static func get_family_buff_value(category: String, tier: int) -> int:
	"""Get the buff value for a category at a given tier (1-3). Returns 0 for tier 0."""
	if tier <= 0 or tier > 3:
		return 0
	if not FAMILY_BUFFS.has(category):
		return 0
	var buff_data: Dictionary = FAMILY_BUFFS[category]
	var values: Array = buff_data.get("values", [0, 0, 0])
	return values[tier - 1] if tier <= values.size() else 0


static func get_family_buff_stat(category: String) -> String:
	"""Get the stat name that a category's family buff modifies."""
	if not FAMILY_BUFFS.has(category):
		return ""
	return FAMILY_BUFFS[category].get("stat", "")


static func get_category_icon(category: String) -> String:
	"""Get the emoji icon for a weapon category."""
	match category:
		CAT_KINETIC:
			return "🔫"
		CAT_THERMAL:
			return "🔥"
		CAT_ARCANE:
			return "✨"
		CAT_FORTRESS:
			return "🛡️"
		CAT_SHADOW:
			return "🗡️"
		CAT_UTILITY:
			return "⚙️"
		CAT_CONTROL:
			return "🚧"
		CAT_VOLATILE:
			return "💥"
		_:
			return "❓"


static func get_damage_type_icon(dtype: String) -> String:
	"""Get the emoji icon for a damage type."""
	match dtype:
		TYPE_KINETIC:
			return "🔫"
		TYPE_THERMAL:
			return "🔥"
		TYPE_ARCANE:
			return "✨"
		_:
			return "❓"


static func get_category_color(category: String) -> Color:
	"""Get the UI color for a weapon category."""
	match category:
		CAT_KINETIC:
			return Color(0.7, 0.7, 0.8)  # Steel gray
		CAT_THERMAL:
			return Color(1.0, 0.5, 0.2)  # Orange-red
		CAT_ARCANE:
			return Color(0.6, 0.3, 0.9)  # Purple
		CAT_FORTRESS:
			return Color(0.5, 0.6, 0.7)  # Iron gray
		CAT_SHADOW:
			return Color(0.3, 0.3, 0.4)  # Dark gray
		CAT_UTILITY:
			return Color(0.4, 0.7, 0.9)  # Cyan
		CAT_CONTROL:
			return Color(0.3, 0.8, 0.5)  # Green
		CAT_VOLATILE:
			return Color(0.9, 0.2, 0.3)  # Red
		_:
			return Color.WHITE


static func get_damage_type_color(dtype: String) -> Color:
	"""Get the UI color for a damage type."""
	match dtype:
		TYPE_KINETIC:
			return Color(0.7, 0.7, 0.8)  # Steel gray
		TYPE_THERMAL:
			return Color(1.0, 0.5, 0.2)  # Orange-red
		TYPE_ARCANE:
			return Color(0.6, 0.3, 0.9)  # Purple
		_:
			return Color.WHITE


# =============================================================================
# LEGACY HELPER FUNCTIONS (for backward compatibility)
# =============================================================================

static func is_valid_tag(tag: String) -> bool:
	"""Check if a tag string is a known valid tag."""
	return tag in ALL_TAGS


static func is_core_type(tag: String) -> bool:
	"""Check if a tag is a legacy core type tag."""
	return tag in CORE_TYPES


static func is_family_tag(tag: String) -> bool:
	"""Check if a tag is a legacy build-family tag."""
	return tag in FAMILY_TAGS


static func get_family_tags_from_list(tags: Array) -> Array[String]:
	"""Extract only the family tags from a list of tags."""
	var result: Array[String] = []
	for tag: Variant in tags:
		if tag is String and is_family_tag(tag):
			result.append(tag)
	return result


static func get_core_type_from_list(tags: Array) -> String:
	"""Get the core type tag from a list of tags. Returns empty string if none found."""
	for tag: Variant in tags:
		if tag is String and is_core_type(tag):
			return tag
	return ""


static func format_tags_for_display(tags: Array) -> String:
	"""Format tags for UI display (comma-separated)."""
	var valid_tags: Array[String] = []
	for tag: Variant in tags:
		if tag is String:
			valid_tags.append(tag)
	return ", ".join(valid_tags)


static func format_categories_for_display(categories: Array) -> String:
	"""Format V5 categories for UI display."""
	var parts: Array[String] = []
	for cat: Variant in categories:
		if cat is String:
			parts.append(get_category_icon(cat) + " " + cat)
	return " | ".join(parts)


static func get_family_display_name(tag: String) -> String:
	"""Get a human-readable display name for a tag/category."""
	# Check if it's a V5 category first
	if tag in CATEGORIES:
		return tag
	# Legacy mapping
	match tag:
		TAG_LIFEDRAIN:
			return "Lifedrain"
		TAG_HEX_RITUAL:
			return "Hex Ritual"
		TAG_FORTRESS:
			return "Fortress"
		TAG_BARRIER_TRAP:
			return "Barrier Trap"
		TAG_VOLATILE:
			return "Volatile"
		TAG_ENGINE_CORE:
			return "Engine Core"
		_:
			return tag.capitalize()


static func get_core_type_display_name(tag: String) -> String:
	"""Get a human-readable display name for a core type tag."""
	match tag:
		TAG_GUN:
			return "Gun"
		TAG_HEX:
			return "Hex"
		TAG_BARRIER:
			return "Barrier"
		TAG_DEFENSE:
			return "Defense"
		TAG_SKILL:
			return "Skill"
		TAG_ENGINE:
			return "Engine"
		_:
			return tag.capitalize()


# =============================================================================
# V5 CATEGORY TO LEGACY TAG MAPPING
# =============================================================================

static func category_to_legacy_tag(category: String) -> String:
	"""Map a V5 category to its closest legacy tag."""
	match category:
		CAT_KINETIC:
			return TAG_GUN
		CAT_THERMAL:
			return TAG_GUN  # Thermal guns
		CAT_ARCANE:
			return TAG_HEX
		CAT_FORTRESS:
			return TAG_DEFENSE
		CAT_SHADOW:
			return TAG_GUN
		CAT_UTILITY:
			return TAG_SKILL
		CAT_CONTROL:
			return TAG_BARRIER
		CAT_VOLATILE:
			return TAG_GUN
		_:
			return ""


static func legacy_tag_to_categories(tag: String) -> Array[String]:
	"""Map a legacy tag to V5 categories for backward compatibility."""
	match tag:
		TAG_GUN:
			return [CAT_KINETIC]
		TAG_HEX:
			return [CAT_ARCANE]
		TAG_BARRIER:
			return [CAT_CONTROL]
		TAG_DEFENSE:
			return [CAT_FORTRESS]
		TAG_SKILL:
			return [CAT_UTILITY]
		TAG_ENGINE:
			return [CAT_UTILITY]
		TAG_VOLATILE:
			return [CAT_VOLATILE]
		TAG_FORTRESS:
			return [CAT_FORTRESS]
		_:
			return []
