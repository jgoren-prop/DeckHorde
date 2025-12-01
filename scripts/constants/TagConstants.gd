extends RefCounted
class_name TagConstants
## TagConstants - Canonical tag names for V2 card/artifact system
## This is the single source of truth for all tag strings.
##
## DESIGN PRINCIPLE: Tags exist for SYNERGIES, not for describing visible info.
## - Instant/Persistent: Already shown on card layout (no tag needed)
## - Targeting/AOE: Already in effect text (no tag needed)
## - Tags are for: Artifact bonuses, shop weighting, build identity

# =============================================================================
# CORE TYPE TAGS (exactly 1 per card)
# =============================================================================
# These define what category of card it is for artifact synergies.
# Example artifacts: "+1 damage to gun cards", "Hex cards apply +1 stack"

const TAG_GUN: String = "gun"           # Direct damage weapons
const TAG_HEX: String = "hex"           # Curse / debuff / DoT
const TAG_BARRIER: String = "barrier"   # Ring traps and movement-triggered effects
const TAG_DEFENSE: String = "defense"   # Armor, shields, direct HP manipulation
const TAG_SKILL: String = "skill"       # Instant utility: draw, energy, manipulation
const TAG_ENGINE: String = "engine"     # Persistent non-weapon effects (turrets, auras)

const CORE_TYPES: Array[String] = [
	TAG_GUN,
	TAG_HEX,
	TAG_BARRIER,
	TAG_DEFENSE,
	TAG_SKILL,
	TAG_ENGINE,
]

# =============================================================================
# BUILD-FAMILY TAGS (0-2 per card)
# =============================================================================
# These define Brotato-style build families for synergies and shop weighting.
# Example artifacts: "Volatile cards cost 1 less", "+20% lifedrain cards in shop"

const TAG_LIFEDRAIN: String = "lifedrain"       # Sustain/vampire - heals, HP manipulation
const TAG_HEX_RITUAL: String = "hex_ritual"     # Dark magic - spends hex/HP for power
const TAG_FORTRESS: String = "fortress"         # Tank builds - heavy armor/barrier stacking
const TAG_BARRIER_TRAP: String = "barrier_trap" # Offensive barriers - barriers that deal damage
const TAG_VOLATILE: String = "volatile"         # Glass cannon - self-damage, risky payoffs
const TAG_ENGINE_CORE: String = "engine_core"   # Economy - draw/energy generation

const FAMILY_TAGS: Array[String] = [
	TAG_LIFEDRAIN,
	TAG_HEX_RITUAL,
	TAG_FORTRESS,
	TAG_BARRIER_TRAP,
	TAG_VOLATILE,
	TAG_ENGINE_CORE,
]

# =============================================================================
# ALL TAGS (for validation)
# =============================================================================

const ALL_TAGS: Array[String] = [
	# Core types (6)
	"gun", "hex", "barrier", "defense", "skill", "engine",
	# Family tags (6)
	"lifedrain", "hex_ritual", "fortress", "barrier_trap", "volatile", "engine_core",
]


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func is_valid_tag(tag: String) -> bool:
	"""Check if a tag string is a known valid tag."""
	return tag in ALL_TAGS


static func is_core_type(tag: String) -> bool:
	"""Check if a tag is a core type tag."""
	return tag in CORE_TYPES


static func is_family_tag(tag: String) -> bool:
	"""Check if a tag is a build-family tag."""
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


static func get_family_display_name(tag: String) -> String:
	"""Get a human-readable display name for a family tag."""
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
