extends Control
class_name BattlefieldRings
## Handles drawing the battlefield lanes and their visual states (threat, barriers).
## V2: Horizontal lane layout - enemies march from top (FAR) to bottom (MELEE).

# Lane configuration - proportions of total height for each lane's TOP edge
# Lane order: FAR (top) -> MID -> CLOSE -> MELEE (bottom)
# Display order is reversed: index 0 = MELEE, index 3 = FAR
const LANE_PROPORTIONS: Array[float] = [0.75, 0.50, 0.25, 0.0]  # Bottom edge Y% for MELEE, CLOSE, MID, FAR
const LANE_COLORS: Array[Color] = [
	Color(0.25, 0.12, 0.12, 0.35),  # MELEE - reddish, most dangerous
	Color(0.22, 0.15, 0.12, 0.28),  # CLOSE - orange tint
	Color(0.18, 0.18, 0.12, 0.22),  # MID - yellow tint
	Color(0.12, 0.15, 0.18, 0.15)   # FAR - blue tint, safest
]
const RING_NAMES: Array[String] = ["MELEE", "CLOSE", "MID", "FAR"]
const LANE_BORDER_COLORS: Array[Color] = [
	Color(0.6, 0.25, 0.25, 0.6),   # MELEE - red border
	Color(0.5, 0.35, 0.25, 0.5),   # CLOSE - orange border
	Color(0.45, 0.45, 0.25, 0.4),  # MID - yellow border
	Color(0.25, 0.35, 0.5, 0.35)   # FAR - blue border
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

# Layout - for horizontal lanes, these represent the drawable area
var arena_center: Vector2 = Vector2.ZERO  # Center of the arena (for compatibility)
var arena_max_radius: float = 200.0  # Not used in horizontal mode, kept for compatibility

# Highlight state for card targeting
var _highlighted_rings: Array[bool] = [false, false, false, false]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	# Update pulse times
	_threat_pulse_time += delta * 4.0
	_barrier_pulse_time += delta * 3.0
	
	# Only redraw if we have critical threats, barriers, or highlights
	var needs_redraw: bool = false
	for level: ThreatLevel in ring_threat_levels:
		if level == ThreatLevel.CRITICAL:
			needs_redraw = true
			break
	
	if not ring_barriers.is_empty():
		needs_redraw = true
	
	# Also redraw if any rings are highlighted (for smooth visual updates)
	for is_highlighted: bool in _highlighted_rings:
		if is_highlighted:
			needs_redraw = true
			break
	
	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	
	var padding: float = 10.0
	var drawable_width: float = size.x - padding * 2
	var drawable_height: float = size.y - padding * 2
	
	# Draw lanes from top (FAR) to bottom (MELEE)
	# We iterate in reverse so FAR (index 3) is drawn first at top
	for i: int in range(3, -1, -1):
		var lane_rect: Rect2 = _get_lane_rect(i, padding, drawable_width, drawable_height)
		
		# Fill color
		var fill_color: Color = LANE_COLORS[i]
		
		# Apply highlight effect when lane is highlighted (card targeting)
		if _highlighted_rings[i]:
			fill_color = Color(0.2, 0.45, 0.2, 0.4)  # Green tint for valid target
		
		# Draw lane background
		draw_rect(lane_rect, fill_color, true)
		
		# Border with threat color (or highlight color)
		var threat_level: ThreatLevel = ring_threat_levels[i]
		var border_color: Color = THREAT_COLORS[threat_level] if threat_level != ThreatLevel.SAFE else LANE_BORDER_COLORS[i]
		var border_width: float = THREAT_BORDER_WIDTH[threat_level]
		
		# Override border for highlighted lanes
		if _highlighted_rings[i]:
			border_color = Color(0.3, 0.9, 0.3, 1.0)  # Bright green border
			border_width = 4.0
		# Pulse critical lanes
		elif threat_level == ThreatLevel.CRITICAL:
			var pulse: float = (sin(_threat_pulse_time) + 1.0) / 2.0
			border_color = border_color.lightened(pulse * 0.3)
			border_width += pulse * 2.0
		
		# Draw lane borders (top and bottom lines)
		var top_left: Vector2 = lane_rect.position
		var top_right: Vector2 = Vector2(lane_rect.end.x, lane_rect.position.y)
		var _bottom_left: Vector2 = Vector2(lane_rect.position.x, lane_rect.end.y)
		var _bottom_right: Vector2 = lane_rect.end
		
		# Draw top border (except for FAR which is at the very top)
		draw_line(top_left, top_right, border_color, border_width)
		
		# Draw lane label on the right side
		_draw_lane_label(i, lane_rect)
		
		# Draw barrier if present
		if ring_barriers.has(i):
			_draw_barrier_lane(i, lane_rect)
	
	# Draw player/warden area at bottom
	var warden_height: float = 40.0
	var warden_rect: Rect2 = Rect2(
		Vector2(padding, size.y - padding - warden_height),
		Vector2(drawable_width, warden_height)
	)
	draw_rect(warden_rect, Color(0.15, 0.2, 0.25, 0.6), true)
	draw_rect(warden_rect, Color(0.4, 0.5, 0.6, 0.8), false, 2.0)
	
	# Draw "WARDEN" label
	var font: Font = ThemeDB.fallback_font
	var warden_text: String = "⚔️ WARDEN"
	var text_pos: Vector2 = warden_rect.position + Vector2(warden_rect.size.x / 2 - 40, warden_rect.size.y / 2 + 5)
	draw_string(font, text_pos, warden_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.7, 0.8, 0.9, 0.9))


func _get_lane_rect(ring: int, padding: float, drawable_width: float, drawable_height: float) -> Rect2:
	"""Get the rectangle for a lane. Ring 0=MELEE (bottom), Ring 3=FAR (top)."""
	# Reserve space at bottom for warden area
	var warden_height: float = 45.0
	var lanes_height: float = drawable_height - warden_height
	var lane_height: float = lanes_height / 4.0
	
	# Calculate Y position - FAR at top, MELEE at bottom (just above warden)
	# Ring 3 (FAR) -> y = padding
	# Ring 0 (MELEE) -> y = padding + 3 * lane_height
	var y_pos: float = padding + (3 - ring) * lane_height
	
	return Rect2(
		Vector2(padding, y_pos),
		Vector2(drawable_width, lane_height)
	)


func _draw_barrier_lane(ring: int, lane_rect: Rect2) -> void:
	"""Draw a barrier effect on a lane (horizontal band)."""
	var pulse: float = (sin(_barrier_pulse_time) + 1.0) / 2.0
	var fast_pulse: float = (sin(_barrier_pulse_time * 2.0) + 1.0) / 2.0
	
	# Brighter, more saturated barrier color
	var barrier_color: Color = Color(0.2, 1.0, 0.5, 0.9)
	barrier_color = barrier_color.lightened(pulse * 0.15)
	
	# Draw barrier line at bottom of lane (where enemies cross into next lane)
	var barrier_y: float = lane_rect.end.y - 8.0
	var barrier_start: Vector2 = Vector2(lane_rect.position.x + 20, barrier_y)
	var barrier_end: Vector2 = Vector2(lane_rect.end.x - 20, barrier_y)
	
	# Main barrier line - thick and prominent
	draw_line(barrier_start, barrier_end, barrier_color, 10.0 + pulse * 4.0)
	
	# Inner glow
	var inner_glow: Color = Color(0.6, 1.0, 0.8, 0.5)
	draw_line(barrier_start, barrier_end, inner_glow, 5.0)
	
	# Outer glow for "force field" effect
	var outer_glow: Color = Color(0.2, 0.8, 0.4, 0.25 + pulse * 0.15)
	draw_line(
		Vector2(barrier_start.x, barrier_y - 6),
		Vector2(barrier_end.x, barrier_y - 6),
		outer_glow, 4.0
	)
	draw_line(
		Vector2(barrier_start.x, barrier_y + 6),
		Vector2(barrier_end.x, barrier_y + 6),
		outer_glow, 4.0
	)
	
	# Draw barrier "posts" at intervals
	var post_count: int = 7
	for i: int in range(post_count):
		var x: float = barrier_start.x + (float(i) / float(post_count - 1)) * (barrier_end.x - barrier_start.x)
		var post_top: Vector2 = Vector2(x, barrier_y - 15)
		var post_bottom: Vector2 = Vector2(x, barrier_y + 5)
		
		var post_color: Color = barrier_color
		post_color.a = 0.6 + fast_pulse * 0.3
		draw_line(post_top, post_bottom, post_color, 3.0)
		draw_circle(post_top, 4.0 + pulse * 2.0, post_color)
	
	# Draw barrier info label
	if ring_barriers.has(ring):
		var barrier: Dictionary = ring_barriers[ring]
		var label_pos: Vector2 = Vector2(lane_rect.get_center().x, barrier_y - 25)
		
		var font: Font = ThemeDB.fallback_font
		var barrier_text: String = "🛡️ " + str(barrier.damage) + " DMG × " + str(barrier.duration)
		
		# Draw background
		var text_size: Vector2 = font.get_string_size(barrier_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		var bg_rect: Rect2 = Rect2(label_pos - Vector2(text_size.x / 2 + 8, 12), Vector2(text_size.x + 16, 22))
		
		# Pulsing background glow
		var glow_rect: Rect2 = bg_rect.grow(2.0 + pulse * 1.5)
		draw_rect(glow_rect, Color(0.2, 0.8, 0.4, 0.2 + pulse * 0.1), true)
		
		# Main background
		draw_rect(bg_rect, Color(0.0, 0.12, 0.05, 0.92), true)
		draw_rect(bg_rect, barrier_color, false, 2.0)
		
		# Text
		var text_color: Color = Color(0.7, 1.0, 0.8, 1.0).lightened(pulse * 0.2)
		draw_string(font, label_pos - Vector2(text_size.x / 2, -4), barrier_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, text_color)


func _draw_lane_label(ring: int, lane_rect: Rect2) -> void:
	"""Draw the lane name label on the right side."""
	var font: Font = ThemeDB.fallback_font
	var label_color: Color = LANE_BORDER_COLORS[ring].lightened(0.3)
	label_color.a = 0.8
	
	# Position on right side, vertically centered in lane
	var label_pos: Vector2 = Vector2(
		lane_rect.end.x - 55,
		lane_rect.position.y + lane_rect.size.y / 2 + 4
	)
	
	draw_string(font, label_pos, RING_NAMES[ring], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, label_color)


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
	"""Get the Y position for a ring (for compatibility - returns center Y of lane)."""
	var lane_rect: Rect2 = _get_lane_rect(ring, 10.0, size.x - 20.0, size.y - 20.0)
	return lane_rect.get_center().y


func get_ring_center_radius(ring: int) -> float:
	"""Get the center Y position of a ring."""
	return get_ring_radius(ring)


func get_lane_rect(ring: int) -> Rect2:
	"""Public accessor for lane rectangle."""
	return _get_lane_rect(ring, 10.0, size.x - 20.0, size.y - 20.0)


func get_lane_center_y(ring: int) -> float:
	"""Get the Y coordinate for the center of a lane."""
	var lane_rect: Rect2 = get_lane_rect(ring)
	return lane_rect.get_center().y


func recalculate_layout() -> void:
	"""Recalculate layout based on current size."""
	# For horizontal layout, center is at the middle-bottom of the arena
	arena_center = Vector2(size.x / 2, size.y - 50)
	arena_max_radius = size.y / 2  # Not really used, kept for compatibility
	queue_redraw()


# ================================================================
# HIGHLIGHT API - Used for card targeting visual feedback
# ================================================================

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
	"""Determine which ring/lane a position is in. Returns -1 if outside all lanes."""
	var padding: float = 10.0
	var drawable_width: float = size.x - padding * 2
	var drawable_height: float = size.y - padding * 2
	
	# Check each lane
	for i: int in range(4):
		var lane_rect: Rect2 = _get_lane_rect(i, padding, drawable_width, drawable_height)
		if lane_rect.has_point(pos):
			return i
	
	return -1
