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
# V2 DAMAGE-TYPE TAGS (0-1 per card)
# =============================================================================
# These define how damage behaves for synergies and artifact scaling.
# Example artifacts: "+15% explosive damage", "Beam attacks chain +1 target"

const TAG_EXPLOSIVE: String = "explosive"   # Splash damage to adjacent rings
const TAG_PIERCING: String = "piercing"     # Overkill flows to next target
const TAG_BEAM: String = "beam"             # Chain damage through targets
const TAG_SHOCK: String = "shock"           # Slow/stun chance on hit
const TAG_CORROSIVE: String = "corrosive"   # Armor shred, doubled on hexed

const DAMAGE_TYPE_TAGS: Array[String] = [
	TAG_EXPLOSIVE,
	TAG_PIERCING,
	TAG_BEAM,
	TAG_SHOCK,
	TAG_CORROSIVE,
]

# =============================================================================
# V2 MECHANICAL TAGS (0-2 per card)
# =============================================================================
# These define card mechanics for targeting and artifact interactions.
# Example artifacts: "Guns with ammo +1 max", "Reload cards cost 1 less"

const TAG_AMMO: String = "ammo"             # Has limited ammo charges
const TAG_RELOAD: String = "reload"         # Can restore ammo to guns
const TAG_SWARM_CLEAR: String = "swarm_clear"   # Effective against multiple enemies
const TAG_SINGLE_TARGET: String = "single_target" # Focuses one enemy
const TAG_SNIPER: String = "sniper"         # Prefers Far/Mid ring targets
const TAG_SHOTGUN: String = "shotgun"       # Multi-hit or Close/Melee focus
const TAG_AOE: String = "aoe"               # Area of effect
const TAG_RING_CONTROL: String = "ring_control" # Pushes/moves enemies between rings

const MECHANICAL_TAGS: Array[String] = [
	TAG_AMMO,
	TAG_RELOAD,
	TAG_SWARM_CLEAR,
	TAG_SINGLE_TARGET,
	TAG_SNIPER,
	TAG_SHOTGUN,
	TAG_AOE,
	TAG_RING_CONTROL,
]

# =============================================================================
# ALL TAGS (for validation)
# =============================================================================

const ALL_TAGS: Array[String] = [
	# Core types (6)
	"gun", "hex", "barrier", "defense", "skill", "engine",
	# Family tags (6)
	"lifedrain", "hex_ritual", "fortress", "barrier_trap", "volatile", "engine_core",
	# V2 Damage-type tags (5)
	"explosive", "piercing", "beam", "shock", "corrosive",
	# V2 Mechanical tags (8)
	"ammo", "reload", "swarm_clear", "single_target", "sniper", "shotgun", "aoe", "ring_control",
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


static func is_damage_type_tag(tag: String) -> bool:
	"""Check if a tag is a V2 damage-type tag."""
	return tag in DAMAGE_TYPE_TAGS


static func is_mechanical_tag(tag: String) -> bool:
	"""Check if a tag is a V2 mechanical tag."""
	return tag in MECHANICAL_TAGS


static func get_family_tags_from_list(tags: Array) -> Array[String]:
	"""Extract only the family tags from a list of tags."""
	var result: Array[String] = []
	for tag: Variant in tags:
		if tag is String and is_family_tag(tag):
			result.append(tag)
	return result


static func get_damage_type_from_list(tags: Array) -> String:
	"""Get the damage-type tag from a list of tags. Returns empty string if none found."""
	for tag: Variant in tags:
		if tag is String and is_damage_type_tag(tag):
			return tag
	return ""


static func get_mechanical_tags_from_list(tags: Array) -> Array[String]:
	"""Extract only the mechanical tags from a list of tags."""
	var result: Array[String] = []
	for tag: Variant in tags:
		if tag is String and is_mechanical_tag(tag):
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


static func get_damage_type_display_name(tag: String) -> String:
	"""Get a human-readable display name for a damage-type tag."""
	match tag:
		TAG_EXPLOSIVE:
			return "Explosive"
		TAG_PIERCING:
			return "Piercing"
		TAG_BEAM:
			return "Beam"
		TAG_SHOCK:
			return "Shock"
		TAG_CORROSIVE:
			return "Corrosive"
		_:
			return tag.capitalize()


static func get_mechanical_tag_display_name(tag: String) -> String:
	"""Get a human-readable display name for a mechanical tag."""
	match tag:
		TAG_AMMO:
			return "Ammo"
		TAG_RELOAD:
			return "Reload"
		TAG_SWARM_CLEAR:
			return "Swarm Clear"
		TAG_SINGLE_TARGET:
			return "Single Target"
		TAG_SNIPER:
			return "Sniper"
		TAG_SHOTGUN:
			return "Shotgun"
		TAG_AOE:
			return "AoE"
		TAG_RING_CONTROL:
			return "Ring Control"
		_:
			return tag.capitalize()
