extends Control
class_name RingTargetIndicator
## Visual indicator showing which rings a card can target
## Draws a mini semi-circle diagram with color-coded rings

# Ring names for tooltips
const RING_NAMES: Array[String] = ["MELEE", "CLOSE", "MID", "FAR"]

# Ring colors when TARGETED (bright, saturated)
const RING_COLORS_ACTIVE: Array[Color] = [
	Color(0.95, 0.30, 0.25, 1.0),  # MELEE - Bright red (danger!)
	Color(1.0, 0.60, 0.20, 1.0),   # CLOSE - Orange  
	Color(0.95, 0.85, 0.25, 1.0),  # MID - Yellow
	Color(0.40, 0.80, 0.50, 1.0),  # FAR - Green (safe)
]

# Ring colors when NOT targeted (dim, desaturated)
const RING_COLORS_INACTIVE: Array[Color] = [
	Color(0.30, 0.22, 0.22, 0.40),  # MELEE - Dim gray-red
	Color(0.30, 0.26, 0.22, 0.40),  # CLOSE - Dim gray-orange
	Color(0.30, 0.28, 0.22, 0.40),  # MID - Dim gray-yellow
	Color(0.22, 0.28, 0.25, 0.40),  # FAR - Dim gray-green
]

# Ring proportions (matching BattlefieldRingManager)
const RING_PROPORTIONS: Array[float] = [0.28, 0.50, 0.75, 1.0]

# Border colors for contrast
const RING_BORDER_ACTIVE: Color = Color(1.0, 1.0, 1.0, 0.8)
const RING_BORDER_INACTIVE: Color = Color(0.5, 0.5, 0.5, 0.3)

# State
var targeted_rings: Array[int] = []
var show_all_indicator: bool = false  # Special "ALL" mode


func _ready() -> void:
	# Ensure we redraw when needed
	set_process(false)


func set_targeted_rings(rings: Array) -> void:
	"""Set which rings are targeted by the card."""
	targeted_rings.clear()
	show_all_indicator = false
	
	for ring in rings:
		if ring is int and ring >= 0 and ring < 4:
			targeted_rings.append(ring)
	
	# Check if all rings are targeted
	if targeted_rings.size() >= 4:
		var has_all: bool = true
		for i: int in range(4):
			if i not in targeted_rings:
				has_all = false
				break
		show_all_indicator = has_all
	
	queue_redraw()


func clear_targeting() -> void:
	"""Clear all targeting (for self-targeting cards)."""
	targeted_rings.clear()
	show_all_indicator = false
	queue_redraw()


func _draw() -> void:
	"""Custom draw function for the ring indicator."""
	var center: Vector2 = Vector2(size.x / 2.0, size.y - 2.0)  # Bottom-center, slight padding
	var max_radius: float = min(size.x / 2.0, size.y) - 4.0  # Leave padding
	
	# Draw rings from outside in (FAR to MELEE) so inner rings draw on top
	for ring: int in range(3, -1, -1):
		var is_targeted: bool = ring in targeted_rings
		var outer_radius: float = max_radius * RING_PROPORTIONS[ring]
		var inner_radius: float = max_radius * RING_PROPORTIONS[ring - 1] if ring > 0 else 0.0
		
		# Get colors based on targeting state
		var fill_color: Color = RING_COLORS_ACTIVE[ring] if is_targeted else RING_COLORS_INACTIVE[ring]
		var border_color: Color = RING_BORDER_ACTIVE if is_targeted else RING_BORDER_INACTIVE
		
		# Draw the arc segment (semi-circle)
		_draw_ring_arc(center, inner_radius, outer_radius, fill_color, border_color, is_targeted)
	
	# Draw center warden/player indicator
	_draw_warden_indicator(center)
	
	# Draw ring labels if space permits
	if size.x >= 100:
		_draw_ring_labels(center, max_radius)


func _draw_ring_arc(center: Vector2, inner_radius: float, outer_radius: float, 
		fill_color: Color, border_color: Color, is_targeted: bool) -> void:
	"""Draw a single ring arc (semi-circle segment)."""
	var segments: int = 32  # Smoothness
	var start_angle: float = PI  # Left side
	var end_angle: float = 2.0 * PI  # Right side
	
	# Build polygon points for the arc
	var points: PackedVector2Array = PackedVector2Array()
	
	# Outer arc (left to right)
	for i: int in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = start_angle + t * (end_angle - start_angle)
		points.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)
	
	# Inner arc (right to left) - creates the donut shape
	for i: int in range(segments, -1, -1):
		var t: float = float(i) / float(segments)
		var angle: float = start_angle + t * (end_angle - start_angle)
		points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)
	
	# Draw filled polygon
	if points.size() >= 3:
		draw_colored_polygon(points, fill_color)
	
	# Draw borders for targeted rings
	if is_targeted:
		var border_width: float = 1.5
		
		# Outer arc border
		for i: int in range(segments):
			var t1: float = float(i) / float(segments)
			var t2: float = float(i + 1) / float(segments)
			var angle1: float = start_angle + t1 * (end_angle - start_angle)
			var angle2: float = start_angle + t2 * (end_angle - start_angle)
			var p1: Vector2 = center + Vector2(cos(angle1), sin(angle1)) * outer_radius
			var p2: Vector2 = center + Vector2(cos(angle2), sin(angle2)) * outer_radius
			draw_line(p1, p2, border_color, border_width, true)


func _draw_warden_indicator(center: Vector2) -> void:
	"""Draw a small indicator at the center representing the player/warden."""
	var warden_radius: float = 4.0
	var warden_color: Color = Color(0.4, 0.7, 1.0, 0.9)  # Soft blue
	
	# Draw a small circle
	draw_circle(center, warden_radius, warden_color)
	
	# Draw a subtle ring around it
	var segments: int = 16
	for i: int in range(segments):
		var angle1: float = 2.0 * PI * float(i) / float(segments)
		var angle2: float = 2.0 * PI * float(i + 1) / float(segments)
		var p1: Vector2 = center + Vector2(cos(angle1), sin(angle1)) * (warden_radius + 2.0)
		var p2: Vector2 = center + Vector2(cos(angle2), sin(angle2)) * (warden_radius + 2.0)
		draw_line(p1, p2, Color(0.6, 0.8, 1.0, 0.5), 1.0, true)


func _draw_ring_labels(center: Vector2, max_radius: float) -> void:
	"""Draw ring name labels on each ring."""
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 8
	
	for ring: int in range(4):
		var is_targeted: bool = ring in targeted_rings
		if not is_targeted:
			continue  # Only label targeted rings to reduce clutter
		
		var ring_radius: float = max_radius * RING_PROPORTIONS[ring]
		var inner_radius: float = max_radius * RING_PROPORTIONS[ring - 1] if ring > 0 else 0.0
		var mid_radius: float = (ring_radius + inner_radius) / 2.0
		
		# Position label at top of the arc
		var label_angle: float = PI * 1.5  # Top of semi-circle
		var label_pos: Vector2 = center + Vector2(cos(label_angle), sin(label_angle)) * mid_radius
		
		# Adjust for text centering
		var label: String = RING_NAMES[ring][0]  # Just first letter: M, C, M, F
		label_pos.x -= 3.0
		label_pos.y += 3.0
		
		var text_color: Color = Color(1.0, 1.0, 1.0, 0.9) if is_targeted else Color(0.6, 0.6, 0.6, 0.5)
		draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

