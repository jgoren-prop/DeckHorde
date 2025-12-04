extends RefCounted
class_name BattlefieldRingManager
## Manages ring drawing, barriers, threat levels, and ring highlighting.

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

# Threat level system
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

# Ring state
var ring_threat_levels: Array[ThreatLevel] = [ThreatLevel.SAFE, ThreatLevel.SAFE, ThreatLevel.SAFE, ThreatLevel.SAFE]
var ring_threat_damage: Array[int] = [0, 0, 0, 0]
var ring_has_bomber: Array[bool] = [false, false, false, false]
var ring_barriers: Dictionary = {}  # ring -> {damage, duration}
var ring_highlights: Array[bool] = [false, false, false, false]

# Pulse timers
var _threat_pulse_time: float = 0.0
var _barrier_pulse_time: float = 0.0


func update_pulse_time(delta: float) -> void:
	"""Update pulse timers."""
	_threat_pulse_time += delta
	_barrier_pulse_time += delta


func get_threat_pulse_alpha() -> float:
	"""Get pulse alpha for critical threats."""
	return 0.7 + 0.3 * sin(_threat_pulse_time * 4.0)


func get_barrier_pulse_alpha() -> float:
	"""Get pulse alpha for barriers."""
	return 0.5 + 0.3 * sin(_barrier_pulse_time * 3.0)


# ============== THREAT LEVEL MANAGEMENT ==============

func update_ring_threat_levels(battlefield) -> void:
	"""Update threat levels for all rings based on enemy state."""
	if not battlefield:
		return
	
	for ring: int in range(4):
		var enemies: Array = battlefield.get_enemies_in_ring(ring)
		ring_has_bomber[ring] = false
		
		if enemies.is_empty():
			ring_threat_levels[ring] = ThreatLevel.SAFE
			ring_threat_damage[ring] = 0
			continue
		
		var total_damage: int = 0
		var has_immediate_threat: bool = false
		var has_bomber: bool = false
		
		for enemy in enemies:
			var enemy_def = _get_enemy_def(enemy.enemy_id)
			if not enemy_def:
				continue
			
			var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
			total_damage += dmg
			
			# Check for immediate melee threat
			if ring == 0:
				has_immediate_threat = true
			
			# Check for bombers
			if enemy_def.special_ability == "explode_on_death" or enemy_def.enemy_type == "bomber":
				has_bomber = true
				if ring <= 1:
					has_immediate_threat = true
		
		ring_has_bomber[ring] = has_bomber
		ring_threat_damage[ring] = total_damage
		
		# Determine threat level
		if has_immediate_threat and has_bomber:
			ring_threat_levels[ring] = ThreatLevel.CRITICAL
		elif has_immediate_threat or (ring == 0 and total_damage > 0):
			ring_threat_levels[ring] = ThreatLevel.HIGH
		elif ring <= 1 and total_damage > 10:
			ring_threat_levels[ring] = ThreatLevel.MEDIUM
		elif total_damage > 0:
			ring_threat_levels[ring] = ThreatLevel.LOW
		else:
			ring_threat_levels[ring] = ThreatLevel.SAFE


func get_ring_threat_color(ring: int) -> Color:
	"""Get the threat color for a ring."""
	if ring < 0 or ring >= 4:
		return RING_BORDER_COLORS[0]
	
	var threat: ThreatLevel = ring_threat_levels[ring]
	var base_color: Color = THREAT_COLORS[threat]
	
	# Pulse critical rings
	if threat == ThreatLevel.CRITICAL:
		base_color.a = get_threat_pulse_alpha()
	
	return base_color


func get_ring_threat_border_width(ring: int) -> float:
	"""Get border width based on threat level."""
	if ring < 0 or ring >= 4:
		return 2.0
	return THREAT_BORDER_WIDTH[ring_threat_levels[ring]]


# ============== BARRIER MANAGEMENT ==============

func set_ring_barrier(ring: int, damage: int, duration: int) -> void:
	"""Set a barrier on a ring."""
	ring_barriers[ring] = {"damage": damage, "duration": duration}


func update_barrier_duration(ring: int, new_duration: int) -> void:
	"""Update barrier duration."""
	if ring_barriers.has(ring):
		ring_barriers[ring].duration = new_duration


func clear_ring_barrier(ring: int) -> void:
	"""Clear a barrier from a ring."""
	ring_barriers.erase(ring)


func clear_all_barriers() -> void:
	"""Clear all barriers."""
	ring_barriers.clear()


func has_barrier(ring: int) -> bool:
	"""Check if a ring has a barrier."""
	return ring_barriers.has(ring)


func get_barrier_damage(ring: int) -> int:
	"""Get barrier damage for a ring."""
	if ring_barriers.has(ring):
		return ring_barriers[ring].damage
	return 0


func get_barrier_duration(ring: int) -> int:
	"""Get barrier duration for a ring."""
	if ring_barriers.has(ring):
		return ring_barriers[ring].duration
	return 0


# ============== RING HIGHLIGHTING ==============

func highlight_ring(ring: int, highlight: bool) -> void:
	"""Set highlight state for a ring."""
	if ring >= 0 and ring < 4:
		ring_highlights[ring] = highlight


func highlight_all_rings(highlight: bool) -> void:
	"""Set highlight state for all rings."""
	for i: int in range(4):
		ring_highlights[i] = highlight


func highlight_rings(rings: Array, highlight: bool) -> void:
	"""Set highlight state for specific rings."""
	for ring in rings:
		if ring is int and ring >= 0 and ring < 4:
			ring_highlights[ring] = highlight


func is_ring_highlighted(ring: int) -> bool:
	"""Check if a ring is highlighted."""
	if ring >= 0 and ring < 4:
		return ring_highlights[ring]
	return false


# ============== RING DETECTION ==============

func get_ring_at_position(global_pos: Vector2, center: Vector2, max_radius: float) -> int:
	"""Detect which ring a position is in. Returns -1 if outside all rings."""
	var distance: float = global_pos.distance_to(center)
	
	for i: int in range(4):
		var ring_radius: float = max_radius * RING_PROPORTIONS[i]
		if distance <= ring_radius:
			return i
	
	return -1


func get_ring_radius(ring: int, max_radius: float) -> float:
	"""Get the radius for a ring."""
	if ring >= 0 and ring < 4:
		return max_radius * RING_PROPORTIONS[ring]
	return 0.0


func get_ring_inner_radius(ring: int, max_radius: float) -> float:
	"""Get the inner radius for a ring (outer radius of inner ring)."""
	if ring <= 0:
		return 0.0
	return get_ring_radius(ring - 1, max_radius)


# ============== DRAWING HELPERS ==============

func draw_ring(canvas: CanvasItem, ring_index: int, radius: float, center: Vector2) -> void:
	"""Draw a single ring with fill and border."""
	var segments: int = 64
	var fill_color: Color = RING_COLORS[ring_index]
	var border_color: Color = get_ring_threat_color(ring_index)
	var border_width: float = get_ring_threat_border_width(ring_index)
	
	# Apply highlight
	if ring_highlights[ring_index]:
		fill_color = Color(0.3, 0.7, 0.3, 0.3)
		border_color = Color(0.3, 0.9, 0.3, 1.0)
		border_width = 4.0
	
	# Draw filled circle
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(segments + 1):
		var angle: float = 2 * PI * i / segments
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	if ring_index == 3:  # FAR ring - draw filled
		canvas.draw_colored_polygon(points, fill_color)
	
	# Draw border
	for i: int in range(segments):
		var p1: Vector2 = points[i]
		var p2: Vector2 = points[i + 1]
		canvas.draw_line(p1, p2, border_color, border_width, true)
	
	# Draw ring label
	var label_pos: Vector2 = center + Vector2(radius - 25, -8)
	var font: Font = ThemeDB.fallback_font
	canvas.draw_string(font, label_pos, RING_NAMES[ring_index], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7, 0.6))


func draw_barrier_indicator(canvas: CanvasItem, ring_index: int, radius: float, center: Vector2) -> void:
	"""Draw barrier indicator on a ring."""
	if not ring_barriers.has(ring_index):
		return
	
	var barrier: Dictionary = ring_barriers[ring_index]
	var segments: int = 64
	
	# Pulsing barrier color
	var barrier_color: Color = Color(0.3, 0.9, 0.5, get_barrier_pulse_alpha())
	
	# Draw barrier ring slightly inside the main ring
	var barrier_radius: float = radius - 5.0
	for i: int in range(segments):
		var angle1: float = 2 * PI * i / segments
		var angle2: float = 2 * PI * (i + 1) / segments
		var p1: Vector2 = center + Vector2(cos(angle1), sin(angle1)) * barrier_radius
		var p2: Vector2 = center + Vector2(cos(angle2), sin(angle2)) * barrier_radius
		canvas.draw_line(p1, p2, barrier_color, 3.0, true)
	
	# Draw barrier info
	var label_pos: Vector2 = center + Vector2(barrier_radius - 60, 15)
	var font: Font = ThemeDB.fallback_font
	var text: String = "🛡️ " + str(barrier.damage) + " (" + str(barrier.duration) + "t)"
	canvas.draw_string(font, label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, barrier_color)


func _get_enemy_def(enemy_id: String) -> EnemyDefinition:
	"""Get enemy definition from database."""
	return EnemyDatabase.get_enemy(enemy_id)

