extends RefCounted
class_name BattlefieldInfoCards
## BattlefieldInfoCards - Creates enemy info card and tooltip UI elements
## Extracted from BattlefieldArena.gd to improve code organization


static func create_enemy_type_card(enemy_def, ring_names: Array[String], enemy_colors: Dictionary) -> PanelContainer:
	"""Create a card-style panel displaying enemy TYPE information (base stats, not instance-specific)."""
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 280)
	
	# Card background style - similar to player cards
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.15, 0.98)
	
	# Border color based on enemy type
	if enemy_def.is_boss:
		style.border_color = Color(1.0, 0.3, 0.3, 1.0)  # Red for boss
	elif enemy_def.is_elite:
		style.border_color = Color(1.0, 0.8, 0.2, 1.0)  # Gold for elite
	else:
		style.border_color = enemy_colors.get(enemy_def.enemy_id, Color(0.5, 0.4, 0.6))
	
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	card.add_theme_stylebox_override("panel", style)
	
	# Main container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	# Header row with behavior badge and name
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)
	
	# Behavior badge
	var badge_panel: Panel = Panel.new()
	var badge_size: float = 28.0
	badge_panel.custom_minimum_size = Vector2(badge_size, badge_size)
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	badge_style.set_corner_radius_all(int(badge_size / 2))
	badge_style.set_border_width_all(2)
	badge_style.border_color = enemy_def.get_behavior_badge_color()
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	
	var badge_icon: Label = Label.new()
	badge_icon.text = enemy_def.get_behavior_badge_icon()
	badge_icon.add_theme_font_size_override("font_size", 14)
	badge_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_icon.size = Vector2(badge_size, badge_size)
	badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.add_child(badge_icon)
	header.add_child(badge_panel)
	
	# Name and type
	var name_vbox: VBoxContainer = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 0)
	name_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(name_vbox)
	
	var name_label: Label = Label.new()
	name_label.text = enemy_def.enemy_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", enemy_colors.get(enemy_def.enemy_id, Color.WHITE))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.add_child(name_label)
	
	var type_label: Label = Label.new()
	if enemy_def.is_boss:
		type_label.text = "💀 BOSS"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif enemy_def.is_elite:
		type_label.text = "⭐ ELITE"
		type_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		type_label.text = enemy_def.enemy_type.to_upper()
		type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_vbox.add_child(type_label)
	
	# Large enemy icon
	var icon_label: Label = Label.new()
	icon_label.text = enemy_def.display_icon
	icon_label.add_theme_font_size_override("font_size", 42)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)
	
	# Base stats row (showing BASE stats, not instance-specific)
	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 12)
	stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_row)
	
	# Base HP stat
	var hp_label: Label = Label.new()
	var scaled_hp: int = enemy_def.get_scaled_hp(RunManager.current_wave)
	hp_label.text = "❤️ " + str(scaled_hp)
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.add_child(hp_label)
	
	# Damage stat
	var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
	var dmg_label: Label = Label.new()
	dmg_label.text = "⚔️ " + str(dmg)
	dmg_label.add_theme_font_size_override("font_size", 14)
	dmg_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	dmg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.add_child(dmg_label)
	
	# Armor stat (if any)
	if enemy_def.armor > 0:
		var armor_label: Label = Label.new()
		armor_label.text = "🛡️ " + str(enemy_def.armor)
		armor_label.add_theme_font_size_override("font_size", 14)
		armor_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		armor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_row.add_child(armor_label)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)
	
	# Attack info
	var attack_label: Label = Label.new()
	var attack_text: String = "🎯 " + enemy_def.attack_type.capitalize()
	if enemy_def.attack_type == "ranged":
		attack_text += " (range " + str(enemy_def.attack_range) + ")"
	elif enemy_def.attack_type == "suicide":
		attack_text = "💥 Suicide (" + str(enemy_def.buff_amount) + " dmg)"
	attack_label.text = attack_text
	attack_label.add_theme_font_size_override("font_size", 12)
	attack_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
	attack_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(attack_label)
	
	# Speed and target
	var movement_label: Label = Label.new()
	movement_label.text = "💨 Speed: " + str(enemy_def.movement_speed) + " │ 📍 Target: " + ring_names[enemy_def.target_ring]
	movement_label.add_theme_font_size_override("font_size", 11)
	movement_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	movement_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(movement_label)
	
	# Behavior tooltip
	var behavior_label: Label = Label.new()
	behavior_label.text = enemy_def.get_behavior_tooltip()
	behavior_label.add_theme_font_size_override("font_size", 11)
	behavior_label.add_theme_color_override("font_color", enemy_def.get_behavior_badge_color())
	behavior_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	behavior_label.custom_minimum_size.x = 180
	behavior_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(behavior_label)
	
	# Special ability (if any)
	if enemy_def.special_ability != "":
		var sep2: HSeparator = HSeparator.new()
		sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(sep2)
		
		var ability_label: Label = Label.new()
		ability_label.add_theme_font_size_override("font_size", 11)
		ability_label.add_theme_color_override("font_color", Color(0.9, 0.6, 1.0))
		ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		ability_label.custom_minimum_size.x = 180
		ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		match enemy_def.special_ability:
			"explode_on_death":
				ability_label.text = "💥 Explodes on death for " + str(enemy_def.buff_amount) + " damage!"
			"buff_allies":
				ability_label.text = "✨ Buffs allies +" + str(enemy_def.buff_amount) + " damage"
			"spawn_minions":
				ability_label.text = "🔮 Spawns " + str(enemy_def.spawn_count) + "x " + enemy_def.spawn_enemy_id
			_:
				ability_label.text = "⚡ " + enemy_def.special_ability
		vbox.add_child(ability_label)
	
	# Description (if any)
	if enemy_def.description != "":
		var sep3: HSeparator = HSeparator.new()
		sep3.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(sep3)
		
		var desc_label: Label = Label.new()
		desc_label.text = enemy_def.description
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size.x = 180
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(desc_label)
	
	return card


static func create_enemy_instance_mini_card(enemy, enemy_def, danger_level: int, danger_glow_colors: Dictionary, enemy_colors: Dictionary) -> PanelContainer:
	"""Create a small mini card showing an individual enemy instance's current state."""
	if not enemy_def:
		return PanelContainer.new()
	
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(65, 85)
	
	# Check if this enemy has danger highlighting
	var has_danger: bool = danger_level != 0  # NONE = 0
	
	# Card background style - apply danger color if applicable
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.12, 0.95)
	
	if has_danger:
		var danger_color: Color = danger_glow_colors.get(danger_level, Color.WHITE)
		style.border_color = danger_color
		style.set_border_width_all(3)
		style.shadow_color = danger_color
		style.shadow_size = 6
	else:
		style.border_color = enemy_colors.get(enemy.enemy_id, Color(0.5, 0.4, 0.6))
		style.set_border_width_all(2)
		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = 2
	
	style.set_corner_radius_all(5)
	style.set_content_margin_all(3)
	card.add_theme_stylebox_override("panel", style)
	
	# Main container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	# Enemy icon
	var icon_label: Label = Label.new()
	icon_label.text = enemy_def.display_icon
	icon_label.add_theme_font_size_override("font_size", 22)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)
	
	# HP bar background
	var hp_bar_bg: ColorRect = ColorRect.new()
	hp_bar_bg.custom_minimum_size = Vector2(56, 6)
	hp_bar_bg.color = Color(0.15, 0.1, 0.1, 1.0)
	hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hp_bar_bg)
	
	# HP bar fill
	var hp_percent: float = enemy.get_hp_percentage()
	var hp_bar_fill: ColorRect = ColorRect.new()
	hp_bar_fill.custom_minimum_size = Vector2(56 * hp_percent, 6)
	hp_bar_fill.color = Color(0.2, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.2), 1.0 - hp_percent)
	hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar_fill.position = hp_bar_bg.position
	hp_bar_bg.add_child(hp_bar_fill)
	
	# HP text
	var hp_label: Label = Label.new()
	hp_label.text = str(enemy.current_hp)
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hp_label)
	
	# Damage display with dark background
	var dmg: int = enemy_def.get_scaled_damage(RunManager.current_wave)
	var dmg_label: Label = Label.new()
	dmg_label.text = "⚔️" + str(dmg)
	dmg_label.add_theme_font_size_override("font_size", 11)
	dmg_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	# Add dark background for legibility
	var mini_dmg_bg: StyleBoxFlat = StyleBoxFlat.new()
	mini_dmg_bg.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	mini_dmg_bg.set_corner_radius_all(2)
	mini_dmg_bg.content_margin_left = 2
	mini_dmg_bg.content_margin_right = 2
	dmg_label.add_theme_stylebox_override("normal", mini_dmg_bg)
	dmg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(dmg_label)
	
	# Status effects (hex indicator - compact)
	if enemy.has_status("hex"):
		var hex_label: Label = Label.new()
		hex_label.text = "☠" + str(enemy.get_status_value("hex"))
		hex_label.add_theme_font_size_override("font_size", 10)
		hex_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0))
		hex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hex_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(hex_label)
	
	return card


static func create_behavior_badge(enemy_def, is_mini_badge: bool = false) -> Panel:
	"""Create a behavior badge indicator for an enemy visual."""
	var panel: Panel = Panel.new()
	
	# Size based on whether it's a mini badge
	var badge_size: float = 22.0 if is_mini_badge else 28.0
	panel.custom_minimum_size = Vector2(badge_size, badge_size)
	
	# Badge style - circular with border matching behavior type
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.15, 0.9)
	style.set_corner_radius_all(int(badge_size / 2))
	style.set_border_width_all(2)
	
	# Get behavior badge color from enemy_def
	style.border_color = enemy_def.get_behavior_badge_color()
	panel.add_theme_stylebox_override("panel", style)
	
	# Badge icon
	var icon: Label = Label.new()
	icon.text = enemy_def.get_behavior_badge_icon()
	icon.add_theme_font_size_override("font_size", 12 if is_mini_badge else 14)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(icon)
	
	return panel


static func create_stat_label(text: String, color: Color) -> Label:
	"""Create a standardized stat label."""
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	return label

