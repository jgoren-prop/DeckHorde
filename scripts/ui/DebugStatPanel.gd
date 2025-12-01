extends PanelContainer
class_name DebugStatPanel
## DebugStatPanel - V2 debug panel showing all player stat multipliers
## Toggle with F3 during combat

# V2: Preload dependencies
const PlayerStatsClass = preload("res://scripts/resources/PlayerStats.gd")

# Label references
var stats_label: RichTextLabel

func _ready() -> void:
	# Start hidden
	visible = false
	
	# Build the UI
	_setup_ui()
	
	# Connect to stats changes
	if RunManager:
		RunManager.stats_changed.connect(_update_display)
		RunManager.hp_changed.connect(_on_hp_changed)
		RunManager.armor_changed.connect(_on_armor_changed)
	
	# Initial update
	_update_display()


func _setup_ui() -> void:
	# Set up the panel style - fixed size to prevent overflow
	custom_minimum_size = Vector2(280, 400)
	size = Vector2(280, 400)  # Fixed size
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.5, 0.3, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	
	# Create content container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "📊 V2 STATS (F3)"
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)
	
	# Scroll container for stats (allows scrolling if content is too long)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	# Stats display inside scroll container
	stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	stats_label.scroll_active = false  # Let ScrollContainer handle scrolling
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_label.add_theme_font_size_override("normal_font_size", 12)
	scroll.add_child(stats_label)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		visible = !visible
		if visible:
			_update_display()


func _on_hp_changed(_current: int, _max_hp: int) -> void:
	_update_display()


func _on_armor_changed(_amount: int) -> void:
	_update_display()


func _update_display() -> void:
	if not stats_label:
		return
	
	var stats = RunManager.player_stats
	if not stats:
		stats_label.text = "[color=#ff6666]No PlayerStats available[/color]"
		return
	
	var text: String = ""
	
	# Runtime state
	text += "[color=#ffcc66]━━ RUNTIME ━━[/color]\n"
	text += "HP: [color=#ff6666]%d/%d[/color]\n" % [RunManager.current_hp, stats.max_hp]
	text += "Armor: [color=#66ccff]%d[/color]\n" % RunManager.armor
	text += "Scrap: [color=#ffcc33]%d[/color]\n" % RunManager.scrap
	text += "Wave: [color=#ffaa33]%d[/color]\n" % RunManager.current_wave
	
	# Warden info
	if RunManager.current_warden:
		var warden_name: String = "Unknown"
		if RunManager.current_warden is WardenDefinition:
			warden_name = RunManager.current_warden.warden_name
		text += "Warden: [color=#66ff66]%s[/color]\n" % warden_name
	text += "\n"
	
	# Offense stats
	text += "[color=#ff6666]━━ OFFENSE ━━[/color]\n"
	text += "Gun Damage: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.gun_damage_percent), stats.gun_damage_percent]
	text += "Hex Damage: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.hex_damage_percent), stats.hex_damage_percent]
	text += "Barrier Damage: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.barrier_damage_percent), stats.barrier_damage_percent]
	text += "Generic Damage: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.generic_damage_percent), stats.generic_damage_percent]
	text += "\n"
	
	# Defense stats
	text += "[color=#66ccff]━━ DEFENSE ━━[/color]\n"
	text += "Armor Gain: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.armor_gain_percent), stats.armor_gain_percent]
	text += "Heal Power: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.heal_power_percent), stats.heal_power_percent]
	text += "Barrier Strength: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.barrier_strength_percent), stats.barrier_strength_percent]
	text += "\n"
	
	# Economy stats
	text += "[color=#ffcc33]━━ ECONOMY ━━[/color]\n"
	text += "Energy/Turn: [color=#ffff66]%d[/color]\n" % stats.energy_per_turn
	text += "Draw/Turn: [color=#66aaff]%d[/color]\n" % stats.draw_per_turn
	text += "Hand Size: [color=#aaaaaa]%d[/color]\n" % stats.hand_size_max
	text += "Scrap Gain: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.scrap_gain_percent), stats.scrap_gain_percent]
	text += "Shop Prices: [color=#%s]%.0f%%[/color]\n" % [_get_inverse_color(stats.shop_price_percent), stats.shop_price_percent]
	text += "\n"
	
	# Ring damage
	text += "[color=#aa66ff]━━ RING DMG ━━[/color]\n"
	text += "vs Melee: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.damage_vs_melee_percent), stats.damage_vs_melee_percent]
	text += "vs Close: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.damage_vs_close_percent), stats.damage_vs_close_percent]
	text += "vs Mid: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.damage_vs_mid_percent), stats.damage_vs_mid_percent]
	text += "vs Far: [color=#%s]%.0f%%[/color]\n" % [_get_color(stats.damage_vs_far_percent), stats.damage_vs_far_percent]
	text += "\n"
	
	# Active combat state (if CombatManager is available)
	if CombatManager and CombatManager.active_weapons.size() > 0:
		text += "[color=#ffaa00]━━ ACTIVE ━━[/color]\n"
		text += "Weapons: [color=#ffaa00]%d[/color]\n" % CombatManager.active_weapons.size()
	
	# Passive state
	if RunManager._has_cheat_death_passive():
		var cheat_status: String = "Ready" if RunManager.cheat_death_available else "Used"
		var cheat_color: String = "66ff66" if RunManager.cheat_death_available else "ff6666"
		text += "Cheat Death: [color=#%s]%s[/color]\n" % [cheat_color, cheat_status]
	
	stats_label.text = text


func _get_color(value: float) -> String:
	"""Get color hex based on whether value is above, below, or at 100%."""
	if value > 100.0:
		return "66ff66"  # Green for bonus
	elif value < 100.0:
		return "ff6666"  # Red for penalty
	else:
		return "aaaaaa"  # Gray for neutral


func _get_inverse_color(value: float) -> String:
	"""Get color hex for inverse stats (lower is better, like shop prices)."""
	if value < 100.0:
		return "66ff66"  # Green for bonus (cheaper)
	elif value > 100.0:
		return "ff6666"  # Red for penalty (more expensive)
	else:
		return "aaaaaa"  # Gray for neutral
