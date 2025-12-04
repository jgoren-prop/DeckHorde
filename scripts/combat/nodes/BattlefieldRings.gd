extends Control
class_name BattlefieldRings
## Handles drawing the battlefield rings and their visual states (threat, barriers).

# Ring configuration
const RING_PROPORTIONS: Array[float] = [0.18, 0.42, 0.68, 0.95]
const RING_COLORS: Array[Color] = [
	Color(0.25, 0.18, 0.18, 0.20),
	Color(0.22, 0.18, 0.15, 0.15),
	Color(0.18, 0.18, 0.15, 0.12),
	Color(0.15, 0.15, 0.18, 0.08)
]
const RING_NAMES: Array[String] = ["MELEE", "CLOSE", "MID", "FAR"]
const RING_BORDER_COLORS: Array[Color] = [
	Color(0.5, 0.35, 0.35, 0.5),
	Color(0.45, 0.38, 0.35, 0.4),
	Color(0.4, 0.4, 0.35, 0.35),
	Color(0.35, 0.38, 0.45, 0.3)
]

# Threat colors
enum ThreatLevel { SAFE, LOW, MEDIUM, HIGH, CRITICAL }
const THREAT_COLORS: Dictionary = {
	ThreatLevel.SAFE: Color(0.3, 0.75, 0.3, 0.9),
	ThreatLevel.LOW: Color(0.95, 0.9, 0.2, 0.9),
	ThreatLevel.MEDIUM: Color(1.0, 0.55, 0.1, 0.95),
	ThreatLevel.HIGH: Color(1.0, 0.25, 0.2, 1.0),
	ThreatLevel.CRITICAL: Color(1.0, 0.1, 0.1, 1.0)
}
const THREAT_BORDER_WIDTH: Dictionary = {
	ThreatLevel.SAFE: 2.0,
	ThreatLevel.LOW: 3.0,
	ThreatLevel.MEDIUM: 4.0,
	ThreatLevel.HIGH: 5.0,
	ThreatLevel.CRITICAL: 6.0
}

# Barrier colors
const BARRIER_COLOR: Color = Color(0.3, 0.9, 0.5, 0.6)

# State
var ring_threat_levels: Array[ThreatLevel] = [ThreatLevel.SAFE, ThreatLevel.SAFE, ThreatLevel.SAFE, ThreatLevel.SAFE]
var ring_threat_damage: Array[int] = [0, 0, 0, 0]
var ring_has_bomber: Array[bool] = [false, false, false, false]
var ring_barriers: Dictionary = {}  # ring -> {damage: int, duration: int}
var _threat_pulse_time: float = 0.0
var _barrier_pulse_time: float = 0.0

# Layout
var arena_center: Vector2 = Vector2.ZERO
var arena_max_radius: float = 200.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	# Update pulse times
	_threat_pulse_time += delta * 4.0
	_barrier_pulse_time += delta * 3.0
	
	# Only redraw if we have critical threats or barriers
	var needs_redraw: bool = false
	for level: ThreatLevel in ring_threat_levels:
		if level == ThreatLevel.CRITICAL:
			needs_redraw = true
			break
	
	if not ring_barriers.is_empty():
		needs_redraw = true
	
	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	if arena_max_radius <= 0:
		return
	
	# Semicircle arc angles (top half, facing up from center)
	const ARC_START: float = PI  # Left side
	const ARC_END: float = TAU   # Right side (full semicircle on top)
	
	# Draw rings from outside in
	for i: int in range(RING_PROPORTIONS.size() - 1, -1, -1):
		var outer_radius: float = arena_max_radius * RING_PROPORTIONS[i]
		var inner_radius: float = 0.0
		if i > 0:
			inner_radius = arena_max_radius * RING_PROPORTIONS[i - 1]
		
		# Fill - draw as a filled arc (polygon)
		var fill_color: Color = RING_COLORS[i]
		_draw_semicircle_fill(arena_center, inner_radius, outer_radius, ARC_START, ARC_END, fill_color)
		
		# Border with threat color
		var threat_level: ThreatLevel = ring_threat_levels[i]
		var border_color: Color = THREAT_COLORS[threat_level]
		var border_width: float = THREAT_BORDER_WIDTH[threat_level]
		
		# Pulse critical rings
		if threat_level == ThreatLevel.CRITICAL:
			var pulse: float = (sin(_threat_pulse_time) + 1.0) / 2.0
			border_color = border_color.lightened(pulse * 0.3)
			border_width += pulse * 2.0
		
		# Draw outer arc border
		draw_arc(arena_center, outer_radius, ARC_START, ARC_END, 64, border_color, border_width)
		
		# Draw ring label on the right side of the arc
		_draw_ring_label(i, outer_radius)
		
		# Draw barrier if present
		if ring_barriers.has(i):
			_draw_barrier_ring(i, outer_radius, ARC_START, ARC_END)
	
	# Draw center (warden position) - at the arena center point
	var center_radius: float = arena_max_radius * 0.08
	draw_circle(arena_center, center_radius, Color(0.2, 0.25, 0.3, 0.8))
	draw_arc(arena_center, center_radius, 0, TAU, 32, Color(0.5, 0.6, 0.7, 0.9), 2.0)


func _draw_semicircle_fill(center: Vector2, inner_r: float, outer_r: float, start_angle: float, end_angle: float, color: Color) -> void:
	"""Draw a filled semicircle/arc segment between inner and outer radius."""
	var segments: int = 48
	var points: PackedVector2Array = PackedVector2Array()
	
	# Outer arc (from start to end)
	for i: int in range(segments + 1):
		var angle: float = start_angle + (end_angle - start_angle) * float(i) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * outer_r)
	
	# Inner arc (from end back to start) - or center point if inner_r is 0
	if inner_r > 0:
		for i: int in range(segments, -1, -1):
			var angle: float = start_angle + (end_angle - start_angle) * float(i) / float(segments)
			points.append(center + Vector2(cos(angle), sin(angle)) * inner_r)
	else:
		points.append(center)
	
	draw_colored_polygon(points, color)


func _draw_barrier_ring(ring: int, radius: float, arc_start: float = PI, arc_end: float = TAU) -> void:
	"""Draw a barrier effect on a ring (as a semicircle arc)."""
	var pulse: float = (sin(_barrier_pulse_time) + 1.0) / 2.0
	var barrier_color: Color = BARRIER_COLOR.lightened(pulse * 0.2)
	barrier_color.a = 0.4 + pulse * 0.2
	
	# Draw glowing barrier arc (semicircle)
	draw_arc(arena_center, radius - 3, arc_start, arc_end, 64, barrier_color, 6.0)
	
	# Inner glow
	var inner_glow: Color = barrier_color
	inner_glow.a *= 0.5
	draw_arc(arena_center, radius - 6, arc_start, arc_end, 64, inner_glow, 3.0)


func _draw_ring_label(ring: int, radius: float) -> void:
	"""Draw the ring name label on the right side of the arc."""
	# Position label on the right edge of the ring, slightly above center line
	var label_angle: float = TAU - 0.15  # Just before the right edge
	var label_radius: float = radius - 20
	var label_pos: Vector2 = arena_center + Vector2(cos(label_angle), sin(label_angle)) * label_radius
	
	var font: Font = ThemeDB.fallback_font
	var label_color: Color = Color(0.7, 0.7, 0.7, 0.7)
	
	# Offset to align text properly
	label_pos.x -= 30
	label_pos.y -= 5
	
	draw_string(font, label_pos, RING_NAMES[ring], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, label_color)


func set_threat_level(ring: int, level: ThreatLevel, damage: int = 0, has_bomber: bool = false) -> void:
	"""Set the threat level for a ring."""
	if ring < 0 or ring >= ring_threat_levels.size():
		return
	
	ring_threat_levels[ring] = level
	ring_threat_damage[ring] = damage
	ring_has_bomber[ring] = has_bomber
	queue_redraw()


func set_barrier(ring: int, damage: int, duration: int) -> void:
	"""Set a barrier on a ring."""
	if damage > 0 and duration > 0:
		ring_barriers[ring] = {"damage": damage, "duration": duration}
	else:
		ring_barriers.erase(ring)
	queue_redraw()


func clear_barrier(ring: int) -> void:
	"""Clear a barrier from a ring."""
	ring_barriers.erase(ring)
	queue_redraw()


func get_ring_radius(ring: int) -> float:
	"""Get the outer radius of a ring."""
	if ring < 0 or ring >= RING_PROPORTIONS.size():
		return 0.0
	return arena_max_radius * RING_PROPORTIONS[ring]


func get_ring_center_radius(ring: int) -> float:
	"""Get the center radius of a ring (between inner and outer)."""
	var outer: float = get_ring_radius(ring)
	var inner: float = 0.0
	if ring > 0:
		inner = get_ring_radius(ring - 1)
	return (inner + outer) / 2.0


func recalculate_layout() -> void:
	"""Recalculate layout based on current size for a semicircle."""
	# For a semicircle facing upward, place center at bottom-center of arena
	# with some padding so the warden circle is visible
	var padding: float = 30.0
	arena_center = Vector2(size.x / 2, size.y - padding)
	
	# Radius can use full width (since it's a semicircle) or height minus padding
	# Use whichever is smaller to ensure it fits
	var max_by_width: float = (size.x / 2) * 0.95  # 95% of half-width
	var max_by_height: float = (size.y - padding * 2) * 0.95  # 95% of available height
	arena_max_radius = min(max_by_width, max_by_height)
	
	queue_redraw()


# ================================================================
# HIGHLIGHT API - Used for card targeting visual feedback
# ================================================================

var _highlighted_rings: Array[bool] = [false, false, false, false]

func highlight_all_rings(should_highlight: bool) -> void:
	"""Highlight or unhighlight all rings."""
	for i: int in range(_highlighted_rings.size()):
		_highlighted_rings[i] = should_highlight
	queue_redraw()


func highlight_ring(ring: int, should_highlight: bool) -> void:
	"""Highlight or unhighlight a specific ring."""
	if ring >= 0 and ring < _highlighted_rings.size():
		_highlighted_rings[ring] = should_highlight
		queue_redraw()
	elif ring < 0:
		# -1 means clear all highlights
		highlight_all_rings(false)


func highlight_rings(rings: Array, should_highlight: bool) -> void:
	"""Highlight or unhighlight multiple specific rings."""
	for ring in rings:
		if ring >= 0 and ring < _highlighted_rings.size():
			_highlighted_rings[ring] = should_highlight
	queue_redraw()


func get_ring_at_position(pos: Vector2) -> int:
	"""Determine which ring a position is in. Returns -1 if outside all rings or below center."""
	# For semicircle, only detect in the upper half (above the center line)
	if pos.y > arena_center.y:
		return -1
	
	var distance: float = (pos - arena_center).length()
	
	for i: int in range(RING_PROPORTIONS.size()):
		var ring_radius: float = arena_max_radius * RING_PROPORTIONS[i]
		if distance <= ring_radius:
			return i
	
	return -1
