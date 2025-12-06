extends RefCounted
class_name ShopPanelBuilder
## ShopPanelBuilder - Factory for creating Shop UI panels
## Extracted from Shop.gd to keep files under 500 lines

# Note: TagConstants is globally available via class_name - use directly


static func create_dev_panel(parent: Control) -> PanelContainer:
	"""Create a dev cheat panel in the top-right corner."""
	var dev_panel: PanelContainer = PanelContainer.new()
	dev_panel.name = "DevPanel"
	
	# Position in top-right corner using manual anchors
	dev_panel.anchor_left = 1.0
	dev_panel.anchor_right = 1.0
	dev_panel.anchor_top = 0.0
	dev_panel.anchor_bottom = 0.0
	dev_panel.offset_left = -180
	dev_panel.offset_top = 80
	dev_panel.offset_right = -10
	dev_panel.offset_bottom = 235
	
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
	return dev_panel


static func create_dev_button(vbox: VBoxContainer, text: String, callback: Callable) -> Button:
	"""Create a standard dev panel button."""
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(150, 30)
	btn.pressed.connect(callback)
	vbox.add_child(btn)
	return btn


static func create_stats_panel(parent: Control) -> PanelContainer:
	"""Create the full stats panel on the left side of the workshop."""
	var stats_panel: PanelContainer = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	
	# Position on left side
	stats_panel.anchor_left = 0.0
	stats_panel.anchor_right = 0.0
	stats_panel.anchor_top = 0.0
	stats_panel.anchor_bottom = 0.0
	stats_panel.offset_left = 10
	stats_panel.offset_top = 10
	stats_panel.offset_right = 260
	stats_panel.offset_bottom = 470
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.5, 0.7, 0.9)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	stats_panel.add_theme_stylebox_override("panel", style)
	
	# Content container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	stats_panel.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "📊 BUILD STATS"
	title.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Stats display (RichTextLabel for BBCode)
	var stats_label: RichTextLabel = RichTextLabel.new()
	stats_label.name = "StatsLabel"
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.scroll_active = false
	stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stats_label.add_theme_font_size_override("normal_font_size", 12)
	vbox.add_child(stats_label)
	
	parent.add_child(stats_panel)
	return stats_panel


static func create_tag_tracker_panel(parent: Control) -> PanelContainer:
	"""Create a panel showing V5 category synergies from player's deck."""
	var tag_tracker_panel: PanelContainer = PanelContainer.new()
	tag_tracker_panel.name = "TagTrackerPanel"
	
	# Position on right side of stats panel
	tag_tracker_panel.anchor_left = 0.0
	tag_tracker_panel.anchor_right = 0.0
	tag_tracker_panel.anchor_top = 0.0
	tag_tracker_panel.anchor_bottom = 0.0
	tag_tracker_panel.offset_left = 270
	tag_tracker_panel.offset_top = 10
	tag_tracker_panel.offset_right = 490
	tag_tracker_panel.offset_bottom = 470
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.8, 0.6, 0.3, 0.9)  # Orange-gold border for synergies
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	tag_tracker_panel.add_theme_stylebox_override("panel", style)
	
	# Content container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	tag_tracker_panel.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "⚡ SYNERGIES"
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Subtitle explaining thresholds
	var subtitle: Label = Label.new()
	subtitle.text = "3/6/9 cards = ★1/★2/★3"
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Scroll container for tag content (so button stays at bottom)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Tag display (RichTextLabel for BBCode)
	var tag_label: RichTextLabel = RichTextLabel.new()
	tag_label.name = "TagLabel"
	tag_label.bbcode_enabled = true
	tag_label.fit_content = true
	tag_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_label.add_theme_font_size_override("normal_font_size", 11)
	scroll.add_child(tag_label)
	
	# Synergy Guide button at bottom (always visible)
	var help_btn: Button = Button.new()
	help_btn.name = "SynergyGuideButton"
	help_btn.text = "📖 Synergy Guide (S)"
	help_btn.custom_minimum_size = Vector2(0, 32)
	help_btn.add_theme_font_size_override("font_size", 12)
	vbox.add_child(help_btn)
	
	parent.add_child(tag_tracker_panel)
	return tag_tracker_panel


static func create_synergy_info_panel(parent: Control) -> PanelContainer:
	"""Create a panel showing detailed synergy information (what each synergy does)."""
	var synergy_panel: PanelContainer = PanelContainer.new()
	synergy_panel.name = "SynergyInfoPanel"
	synergy_panel.visible = false  # Hidden by default, toggled with button
	
	# Position as an overlay in the center - wider for table format
	synergy_panel.anchor_left = 0.5
	synergy_panel.anchor_right = 0.5
	synergy_panel.anchor_top = 0.5
	synergy_panel.anchor_bottom = 0.5
	synergy_panel.offset_left = -380
	synergy_panel.offset_top = -320
	synergy_panel.offset_right = 380
	synergy_panel.offset_bottom = 320
	synergy_panel.z_index = 100
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.1, 0.98)
	style.set_border_width_all(3)
	style.border_color = Color(1.0, 0.7, 0.3, 1.0)  # Gold border
	style.set_corner_radius_all(12)
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 10
	synergy_panel.add_theme_stylebox_override("panel", style)
	
	# Main VBox
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	synergy_panel.add_child(vbox)
	
	# Header with title and close button
	var header: HBoxContainer = HBoxContainer.new()
	vbox.add_child(header)
	
	var title: Label = Label.new()
	title.text = "📖 SYNERGY GUIDE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	header.add_child(title)
	
	var close_btn: Button = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.flat = true
	header.add_child(close_btn)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Scroll container for synergy info
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Content label (RichTextLabel for BBCode)
	var content_label: RichTextLabel = RichTextLabel.new()
	content_label.name = "ContentLabel"
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.add_theme_font_size_override("normal_font_size", 12)
	scroll.add_child(content_label)
	
	parent.add_child(synergy_panel)
	return synergy_panel


static func create_owned_artifacts_panel(parent: Control) -> PanelContainer:
	"""Create a panel showing all artifacts the player owns."""
	var owned_artifacts_panel: PanelContainer = PanelContainer.new()
	owned_artifacts_panel.name = "OwnedArtifactsPanel"
	
	# Position below the tag tracker panel (synergies panel is now larger)
	owned_artifacts_panel.anchor_left = 0.0
	owned_artifacts_panel.anchor_right = 0.0
	owned_artifacts_panel.anchor_top = 0.0
	owned_artifacts_panel.anchor_bottom = 0.0
	owned_artifacts_panel.offset_left = 270
	owned_artifacts_panel.offset_top = 485
	owned_artifacts_panel.offset_right = 490
	owned_artifacts_panel.offset_bottom = 665
	
	# Style the panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.8, 0.3, 0.9)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	owned_artifacts_panel.add_theme_stylebox_override("panel", style)
	
	# Content container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	owned_artifacts_panel.add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "💎 OWNED ARTIFACTS"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Scroll container for artifacts grid
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Grid for artifact icons
	var grid: GridContainer = GridContainer.new()
	grid.name = "ArtifactGrid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	
	parent.add_child(owned_artifacts_panel)
	return owned_artifacts_panel


static func create_artifact_tooltip(parent: Control) -> PanelContainer:
	"""Create the floating tooltip for artifact hover."""
	var artifact_tooltip: PanelContainer = PanelContainer.new()
	artifact_tooltip.name = "ArtifactTooltip"
	artifact_tooltip.visible = false
	artifact_tooltip.z_index = 100
	
	# Style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.98)
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color(0.8, 0.7, 0.5)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	artifact_tooltip.add_theme_stylebox_override("panel", style)
	
	# Content
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	artifact_tooltip.add_child(vbox)
	
	# Name label
	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	vbox.add_child(name_label)
	
	# Description label
	var desc_label: Label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 180
	vbox.add_child(desc_label)
	
	parent.add_child(artifact_tooltip)
	return artifact_tooltip


static func create_artifact_icon(artifact, count: int, hover_callback: Callable, exit_callback: Callable) -> Button:
	"""Create an artifact icon with hover functionality using Button for reliable mouse events."""
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(44, 44)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	
	# Create a stylebox for the button
	var style_normal: StyleBoxFlat = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.12, 0.2)
	style_normal.set_corner_radius_all(4)
	style_normal.set_border_width_all(2)
	
	# Border color by rarity
	match artifact.rarity:
		1: style_normal.border_color = Color(0.5, 0.5, 0.5)
		2: style_normal.border_color = Color(0.3, 0.6, 1.0)
		3: style_normal.border_color = Color(0.8, 0.5, 1.0)
		4: style_normal.border_color = Color(1.0, 0.8, 0.3)
		_: style_normal.border_color = Color(0.5, 0.5, 0.5)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_normal)
	btn.add_theme_stylebox_override("pressed", style_normal)
	btn.add_theme_stylebox_override("focus", style_normal)
	
	# Set the icon as text
	var icon_text: String = artifact.icon
	if count > 1:
		icon_text += "\nx%d" % count
	btn.text = icon_text
	btn.add_theme_font_size_override("font_size", 18)
	
	# Store artifact data for tooltip
	btn.set_meta("artifact", artifact)
	btn.set_meta("count", count)
	
	# Connect hover signals
	btn.mouse_entered.connect(hover_callback.bind(btn))
	btn.mouse_exited.connect(exit_callback)
	
	return btn


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

