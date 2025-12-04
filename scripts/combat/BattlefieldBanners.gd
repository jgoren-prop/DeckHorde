extends RefCounted
class_name BattlefieldBanners
## Manages event callout banners for the battlefield (spawn alerts, buff warnings, etc.)

const EVENT_BANNER_COLORS: Dictionary = {
	"spawn": Color(0.3, 0.9, 0.9, 0.95),    # Cyan for spawner
	"buff": Color(0.7, 0.4, 1.0, 0.95),     # Purple for buffer
	"bomber": Color(1.0, 0.85, 0.2, 0.95),  # Yellow for bomber
	"explode": Color(1.0, 0.3, 0.1, 0.95),  # Red-orange for explosion
	"boss": Color(1.0, 0.8, 0.2, 0.95)      # Gold for boss
}

var _event_banner: PanelContainer = null
var _event_banner_queue: Array[Dictionary] = []
var _event_banner_tween: Tween = null
var _parent: Control = null


func setup(parent: Control) -> void:
	"""Initialize with parent control for adding banners."""
	_parent = parent


func show_event_banner(icon: String, text: String, banner_type: String, duration: float) -> void:
	"""Show an event callout banner at top-center of screen."""
	if _event_banner and is_instance_valid(_event_banner):
		_event_banner_queue.append({
			"icon": icon,
			"text": text,
			"type": banner_type,
			"duration": duration
		})
		return
	
	_create_event_banner(icon, text, banner_type, duration)


func show_bomber_warning(enemy_def, explosion_damage: int) -> void:
	"""Show warning banner when a bomber reaches melee."""
	if not enemy_def:
		return
	var banner_text: String = enemy_def.enemy_name + " in MELEE - will explode for " + str(explosion_damage) + " damage!"
	show_event_banner("💣", banner_text, "bomber", 2.5)


func show_torchbearer_buff_banner(buff_amount: int) -> void:
	"""Show banner when torchbearer buff is active during enemy phase."""
	var banner_text: String = "TORCHBEARER BUFF - Enemies deal +" + str(buff_amount) + " damage!"
	show_event_banner("📢", banner_text, "buff", 2.0)


func show_ability_banner(enemy_def, ability: String, value: int) -> void:
	"""Show a banner for an enemy ability trigger."""
	if not enemy_def:
		return
	
	var banner_type: String = ""
	var banner_icon: String = ""
	var banner_text: String = ""
	var duration: float = 2.0
	
	match ability:
		"spawn":
			banner_type = "spawn"
			banner_icon = "👥"
			banner_text = enemy_def.enemy_name + " spawned " + str(value) + " enemies!"
			duration = 2.0
		
		"buff":
			banner_type = "buff"
			banner_icon = "📢"
			banner_text = enemy_def.enemy_name + " - Enemies gain +" + str(value) + " damage!"
			duration = 2.0
		
		"bomber_melee_warning":
			banner_type = "bomber"
			banner_icon = "💣"
			banner_text = enemy_def.enemy_name + " in MELEE - will explode for " + str(value) + " damage!"
			duration = 2.5
		
		_:
			return  # Unknown ability
	
	show_event_banner(banner_icon, banner_text, banner_type, duration)


func _create_event_banner(icon: String, text: String, banner_type: String, duration: float) -> void:
	"""Create and animate the event banner."""
	if not _parent or not is_instance_valid(_parent):
		return
	
	_event_banner = PanelContainer.new()
	_event_banner.name = "EventBanner"
	_event_banner.z_index = 100
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var banner_color: Color = EVENT_BANNER_COLORS.get(banner_type, Color(0.3, 0.3, 0.4, 0.95))
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	style.border_color = banner_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	style.shadow_color = banner_color
	style.shadow_color.a = 0.5
	style.shadow_size = 8
	_event_banner.add_theme_stylebox_override("panel", style)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	
	var icon_label: Label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 28)
	hbox.add_child(icon_label)
	
	var text_label: Label = Label.new()
	text_label.text = text
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", banner_color)
	text_label.add_theme_constant_override("outline_size", 2)
	text_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	hbox.add_child(text_label)
	
	_event_banner.add_child(hbox)
	_parent.add_child(_event_banner)
	
	# Position at top-center (deferred to get proper size)
	_event_banner.call_deferred("_setup_position_and_animate", _parent.size.x, duration)
	# Can't use deferred with custom method on PanelContainer, so inline the logic
	_animate_banner_in(duration)


func _animate_banner_in(duration: float) -> void:
	"""Animate the banner into view."""
	if not _event_banner or not is_instance_valid(_event_banner):
		return
	
	# Wait a frame for size calculation
	await _parent.get_tree().process_frame
	
	if not _event_banner or not is_instance_valid(_event_banner):
		return
	
	var screen_center_x: float = _parent.size.x / 2
	_event_banner.position = Vector2(screen_center_x - _event_banner.size.x / 2, -_event_banner.size.y - 10)
	
	if _event_banner_tween and _event_banner_tween.is_valid():
		_event_banner_tween.kill()
	
	_event_banner_tween = _parent.create_tween()
	_event_banner_tween.set_ease(Tween.EASE_OUT)
	_event_banner_tween.set_trans(Tween.TRANS_BACK)
	_event_banner_tween.tween_property(_event_banner, "position:y", 20.0, 0.3)
	_event_banner_tween.tween_interval(duration)
	_event_banner_tween.set_ease(Tween.EASE_IN)
	_event_banner_tween.set_trans(Tween.TRANS_QUAD)
	_event_banner_tween.tween_property(_event_banner, "position:y", -_event_banner.size.y - 10, 0.2)
	_event_banner_tween.tween_callback(_on_event_banner_finished)


func _on_event_banner_finished() -> void:
	"""Clean up banner and show next in queue."""
	if _event_banner and is_instance_valid(_event_banner):
		_event_banner.queue_free()
	_event_banner = null
	
	if not _event_banner_queue.is_empty():
		var next_banner: Dictionary = _event_banner_queue.pop_front()
		# Small delay between banners
		if _parent and is_instance_valid(_parent):
			var timer: SceneTreeTimer = _parent.get_tree().create_timer(0.15)
			timer.timeout.connect(func():
				_create_event_banner(next_banner.icon, next_banner.text, next_banner.type, next_banner.duration)
			)


