extends RefCounted
class_name CombatOverlayBuilder
## CombatOverlayBuilder - Factory for creating Combat UI overlays
## Extracted from CombatScreen.gd to keep files under 500 lines


static func create_intent_bar(parent: Control) -> Dictionary:
	"""Create the aggregated intent bar at the top of the combat screen.
	Returns dictionary with panel and label references."""
	var intent_bar: PanelContainer = PanelContainer.new()
	intent_bar.name = "IntentBar"
	
	# Position below the top bar
	intent_bar.anchors_preset = Control.PRESET_TOP_WIDE
	intent_bar.offset_top = 55
	intent_bar.offset_bottom = 90
	intent_bar.offset_left = 200
	intent_bar.offset_right = -200
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.92)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.3, 0.5, 0.8)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	intent_bar.add_theme_stylebox_override("panel", style)
	
	# Create HBox for intent items
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 25)
	intent_bar.add_child(hbox)
	
	# Damage section
	var damage_section: HBoxContainer = _create_intent_section("⚔️", "0 Incoming", Color(0.9, 0.9, 0.9))
	hbox.add_child(damage_section)
	var damage_label: Label = damage_section.get_child(1)
	
	hbox.add_child(VSeparator.new())
	
	# Bomber section
	var bomber_section: HBoxContainer = _create_intent_section("💣", "0 Bombers", Color(1.0, 0.85, 0.3))
	bomber_section.name = "BomberSection"
	hbox.add_child(bomber_section)
	var bomber_label: Label = bomber_section.get_child(1)
	
	hbox.add_child(VSeparator.new())
	
	# Buffer section
	var buffer_section: HBoxContainer = _create_intent_section("📢", "No Buff", Color(0.7, 0.4, 1.0))
	buffer_section.name = "BufferSection"
	hbox.add_child(buffer_section)
	var buffer_label: Label = buffer_section.get_child(1)
	
	hbox.add_child(VSeparator.new())
	
	# Spawner section
	var spawner_section: HBoxContainer = _create_intent_section("⚙️", "No Spawners", Color(0.3, 0.9, 0.9))
	spawner_section.name = "SpawnerSection"
	hbox.add_child(spawner_section)
	var spawner_label: Label = spawner_section.get_child(1)
	
	hbox.add_child(VSeparator.new())
	
	# Fast enemies section
	var fast_section: HBoxContainer = _create_intent_section("⚡", "0 Fast", Color(1.0, 0.6, 0.2))
	fast_section.name = "FastSection"
	hbox.add_child(fast_section)
	var fast_label: Label = fast_section.get_child(1)
	
	parent.add_child(intent_bar)
	
	return {
		"panel": intent_bar,
		"damage_label": damage_label,
		"bomber_label": bomber_label,
		"buffer_label": buffer_label,
		"spawner_label": spawner_label,
		"fast_label": fast_label
	}


static func _create_intent_section(icon: String, text: String, color: Color) -> HBoxContainer:
	"""Create a section for the intent bar."""
	var section: HBoxContainer = HBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	
	var icon_label: Label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 18)
	section.add_child(icon_label)
	
	var text_label: Label = Label.new()
	text_label.text = text
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", color)
	section.add_child(text_label)
	
	return section


static func create_deck_viewer_overlay(parent: Control) -> Dictionary:
	"""Create the deck viewer overlay for viewing the current run deck.
	Returns dictionary with: overlay, grid, title references."""
	var deck_viewer_overlay: CanvasLayer = CanvasLayer.new()
	deck_viewer_overlay.name = "DeckViewerOverlay"
	deck_viewer_overlay.layer = 50
	deck_viewer_overlay.visible = false
	parent.add_child(deck_viewer_overlay)
	
	# Dimmer background
	var dimmer: ColorRect = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.85)
	deck_viewer_overlay.add_child(dimmer)
	
	# Main panel
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "DeckPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -450
	panel.offset_top = -400
	panel.offset_right = 450
	panel.offset_bottom = 400
	
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.05, 0.1, 0.98)
	panel_style.border_color = Color(0.5, 0.7, 0.9, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(16)
	panel_style.content_margin_left = 20.0
	panel_style.content_margin_right = 20.0
	panel_style.content_margin_top = 15.0
	panel_style.content_margin_bottom = 15.0
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	deck_viewer_overlay.add_child(panel)
	
	# VBox for content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	# Header with title and close button
	var header: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header)
	
	var deck_viewer_title: Label = Label.new()
	deck_viewer_title.text = "📚 YOUR DECK"
	deck_viewer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_viewer_title.add_theme_font_size_override("font_size", 28)
	deck_viewer_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	header.add_child(deck_viewer_title)
	
	var close_btn: Button = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(45, 45)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.flat = true
	header.add_child(close_btn)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Info label
	var info_label: Label = Label.new()
	info_label.text = "These are the cards in your current run deck."
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)
	
	# Scroll container for cards
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(860, 650)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Grid for cards
	var deck_viewer_grid: GridContainer = GridContainer.new()
	deck_viewer_grid.columns = 5
	deck_viewer_grid.add_theme_constant_override("h_separation", 15)
	deck_viewer_grid.add_theme_constant_override("v_separation", 15)
	scroll.add_child(deck_viewer_grid)
	
	return {
		"overlay": deck_viewer_overlay,
		"grid": deck_viewer_grid,
		"title": deck_viewer_title,
		"close_button": close_btn
	}


static func create_dev_panel(parent: Control) -> Dictionary:
	"""Create a dev cheat panel in the top-right corner.
	Returns dictionary with panel and vbox references."""
	var dev_panel: PanelContainer = PanelContainer.new()
	dev_panel.name = "DevPanel"
	
	# Position in top-right corner using manual anchors
	dev_panel.anchor_left = 1.0
	dev_panel.anchor_right = 1.0
	dev_panel.anchor_top = 0.0
	dev_panel.anchor_bottom = 0.0
	dev_panel.offset_left = -180
	dev_panel.offset_top = 55
	dev_panel.offset_right = -10
	dev_panel.offset_bottom = 210
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.2, 0.9)
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.4, 0.4, 0.8)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	dev_panel.add_theme_stylebox_override("panel", style)
	
	# VBox for buttons
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	dev_panel.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "🔧 DEV"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	parent.add_child(dev_panel)
	return {"panel": dev_panel, "vbox": vbox}


static func create_dev_button(vbox: VBoxContainer, text: String, callback: Callable) -> Button:
	"""Create a standard dev panel button."""
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(150, 30)
	btn.pressed.connect(callback)
	vbox.add_child(btn)
	return btn


static func create_turn_banner(parent: Control, text: String) -> Label:
	"""Create and animate a turn banner that slides in and out."""
	var banner: Label = Label.new()
	banner.text = text
	banner.add_theme_font_size_override("font_size", 48)
	banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	banner.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	banner.add_theme_constant_override("outline_size", 4)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.anchors_preset = Control.PRESET_CENTER
	banner.position = Vector2(parent.get_viewport_rect().size.x / 2 - 100, -50)
	parent.add_child(banner)
	
	# Slide in, pause, slide out
	var tween: Tween = parent.create_tween()
	tween.tween_property(banner, "position:y", parent.get_viewport_rect().size.y / 3, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(banner, "modulate:a", 0.0, 0.3)
	tween.tween_callback(banner.queue_free)
	
	return banner


static func create_hint_label(parent: Control, text: String, color: Color, y_offset: float = 300) -> Label:
	"""Create a temporary hint label that fades out."""
	var hint: Label = Label.new()
	hint.text = text
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", color)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	hint.add_theme_constant_override("outline_size", 3)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(parent.get_viewport_rect().size.x / 2 - 150, parent.get_viewport_rect().size.y - y_offset)
	parent.add_child(hint)
	
	return hint


