extends Control
## LevelUpPicker - Brotato-style level-up stat selection modal
## Shows 3-4 stat options when player levels up, player picks one

signal stat_selected(choice_id: String)
signal picker_closed()

var options_container: HBoxContainer
var title_label: Label
var pending_label: Label
var background: ColorRect
var panel: PanelContainer

var current_options: Array = []


func _ready() -> void:
	_build_ui()
	visible = false
	
	# Connect to RunManager level-up signal
	RunManager.levelup_choices_available.connect(_on_levelup_choices_available)


func _build_ui() -> void:
	"""Build the level-up picker UI programmatically."""
	# Full-screen semi-transparent background
	background = ColorRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.0, 0.0, 0.0, 0.7)
	add_child(background)
	
	# Main panel centered
	panel = PanelContainer.new()
	panel.name = "MainPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350
	panel.offset_right = 350
	panel.offset_top = -220
	panel.offset_bottom = 220
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.border_color = Color(1.0, 0.85, 0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 15.0
	style.content_margin_bottom = 15.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	# VBox for content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# Title
	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = "⭐ LEVEL UP!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title_label)
	
	# Subtitle
	var subtitle: Label = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Choose a stat bonus"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(subtitle)
	
	# Pending level-ups indicator
	pending_label = Label.new()
	pending_label.name = "PendingLabel"
	pending_label.text = ""
	pending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pending_label.add_theme_font_size_override("font_size", 14)
	pending_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	vbox.add_child(pending_label)
	
	# Options container (horizontal layout)
	options_container = HBoxContainer.new()
	options_container.name = "OptionsContainer"
	options_container.add_theme_constant_override("separation", 15)
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(options_container)


func _on_levelup_choices_available(options: Array) -> void:
	"""Called when RunManager has level-up choices ready."""
	current_options = options
	_display_options(options)
	_show()


func _display_options(options: Array) -> void:
	"""Display the stat options as clickable cards."""
	# Clear existing options
	for child: Node in options_container.get_children():
		child.queue_free()
	
	# Update pending label
	var pending: int = RunManager.get_pending_levelup_count()
	if pending > 1:
		pending_label.text = "(%d more choices after this)" % (pending - 1)
		pending_label.visible = true
	else:
		pending_label.visible = false
	
	# Create option cards
	for option: Dictionary in options:
		var card: PanelContainer = _create_option_card(option)
		options_container.add_child(card)


func _create_option_card(option: Dictionary) -> PanelContainer:
	"""Create a clickable card for a stat option."""
	var card: PanelContainer = PanelContainer.new()
	card.name = "Option_" + option.id
	card.custom_minimum_size = Vector2(150, 180)
	
	# Style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.18, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", style)
	
	# Make it clickable
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_option_input.bind(option.id, card))
	card.mouse_entered.connect(_on_option_hover.bind(card, true))
	card.mouse_exited.connect(_on_option_hover.bind(card, false))
	
	# VBox for content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	# Icon
	var icon_label: Label = Label.new()
	icon_label.text = option.get("icon", "📊")
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 36)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)
	
	# Name
	var name_label: Label = Label.new()
	name_label.text = option.get("name", "Unknown")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	
	# Description
	var desc_label: Label = Label.new()
	desc_label.text = option.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_label)
	
	return card


func _on_option_hover(card: PanelContainer, is_hovering: bool) -> void:
	"""Handle hover effect on option cards."""
	var style: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
	
	if is_hovering:
		style.border_color = Color(1.0, 0.85, 0.3)
		style.bg_color = Color(0.18, 0.15, 0.25, 0.98)
		card.scale = Vector2(1.05, 1.05)
	else:
		style.border_color = Color(0.4, 0.4, 0.5)
		style.bg_color = Color(0.12, 0.1, 0.18, 0.95)
		card.scale = Vector2(1.0, 1.0)
	
	card.add_theme_stylebox_override("panel", style)


func _on_option_input(event: InputEvent, choice_id: String, _card: PanelContainer) -> void:
	"""Handle click on option card."""
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_select_option(choice_id)


func _select_option(choice_id: String) -> void:
	"""Apply the selected stat and close or show next choices."""
	print("[LevelUpPicker] Selected: ", choice_id)
	
	# Apply the choice through RunManager
	RunManager.apply_levelup_choice(choice_id)
	
	# Emit signal for any listeners
	stat_selected.emit(choice_id)
	
	# Check if more pending - RunManager will emit signal again if so
	if not RunManager.has_pending_levelups():
		_hide()


func _show() -> void:
	"""Show the picker with animation."""
	visible = true
	modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _hide() -> void:
	"""Hide the picker with animation."""
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): 
		visible = false
		picker_closed.emit()
	)


func is_showing() -> bool:
	"""Check if the picker is currently visible."""
	return visible

