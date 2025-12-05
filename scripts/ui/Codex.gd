extends Control
## Codex - In-game encyclopedia explaining all game mechanics
## Accessible from the Main Menu to teach players about effects, families, and systems

signal closed()

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBoxContainer/TabContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton

# Category data for each section
var _status_effects_data: Array[Dictionary] = []
var _damage_types_data: Array[Dictionary] = []
var _categories_data: Array[Dictionary] = []
var _enemy_types_data: Array[Dictionary] = []
var _mechanics_data: Array[Dictionary] = []
var _artifacts_data: Array[Dictionary] = []


func _ready() -> void:
	_populate_data()
	_build_tabs()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func _populate_data() -> void:
	"""Populate all codex data from game systems."""
	_populate_status_effects()
	_populate_damage_types()
	_populate_categories()
	_populate_enemy_types()
	_populate_mechanics()
	_populate_artifacts()


# =============================================================================
# STATUS EFFECTS
# =============================================================================

func _populate_status_effects() -> void:
	_status_effects_data = [
		{
			"name": "🔥 Burn",
			"color": Color(1.0, 0.5, 0.2),
			"description": "Damage over time effect that ticks at end of each turn.",
			"details": [
				"• Each stack deals 1 damage per turn",
				"• Stacks are consumed one at a time",
				"• Enhanced by [color=#ffaa44]Burn Potency[/color] stat",
				"• Thermal weapons often apply Burn",
				"• Example: 5 Burn = 5 damage turn 1, 4 turn 2, etc."
			]
		},
		{
			"name": "☠️ Hex",
			"color": Color(0.6, 0.3, 0.9),
			"description": "Stored damage that triggers when the enemy takes any hit.",
			"details": [
				"• When hexed enemy takes damage, Hex stacks are added as bonus damage",
				"• Hex is [color=#ff6666]consumed[/color] when triggered (one-time burst)",
				"• Enhanced by [color=#aa66ff]Hex Potency[/color] stat",
				"• Arcane weapons often apply Hex",
				"• Strategy: Stack Hex, then trigger with a big hit!"
			]
		},
		{
			"name": "⚡ Execute",
			"color": Color(0.9, 0.2, 0.2),
			"description": "Instant kill threshold - enemies below X% HP die on hit.",
			"details": [
				"• If enemy HP% falls at or below threshold, they die instantly",
				"• Threshold is a percentage (e.g., 20% = execute at 20% HP)",
				"• Multiple Execute effects take the [color=#66ff66]highest[/color] threshold",
				"• Enhanced by [color=#ff6666]Execute Threshold Bonus[/color] stat",
				"• Powerful against high-HP enemies!"
			]
		},
		{
			"name": "🛡️ Armor (Enemy)",
			"color": Color(0.6, 0.6, 0.7),
			"description": "Each hit removes 1 armor. Damage only applies after armor is stripped.",
			"details": [
				"• Each HIT removes exactly 1 armor (not damage-based)",
				"• While armor remains, no HP damage is dealt",
				"• Multi-hit weapons are [color=#66ff66]essential[/color] vs armored enemies",
				"• Example: Enemy with 4 armor needs 4+ hits before taking HP damage",
				"• Some weapons ignore armor entirely"
			]
		},
		{
			"name": "🛡️ Armor (Player)",
			"color": Color(0.5, 0.7, 0.9),
			"description": "Blocks incoming damage. Each point blocks 1 damage.",
			"details": [
				"• Player armor blocks damage 1:1",
				"• Armor persists between turns until depleted",
				"• [color=#66aaff]Armor Start[/color] stat grants armor at wave start",
				"• Some cards and artifacts grant armor",
				"• Fortress family specializes in armor"
			]
		},
	]


# =============================================================================
# DAMAGE TYPES
# =============================================================================

func _populate_damage_types() -> void:
	_damage_types_data = [
		{
			"name": "🔫 Kinetic",
			"color": Color(0.7, 0.7, 0.8),
			"description": "Physical projectile damage - reliable and consistent.",
			"details": [
				"• Scales with [color=#aaaacc]Kinetic[/color] flat stat",
				"• Multiplied by [color=#aaaacc]Kinetic %[/color] modifier",
				"• Best for: Raw damage, armor shredding",
				"• Weapons: Pistol, SMG, Minigun, Sniper, Railgun",
				"• Synergy: Multi-hit builds, crit builds"
			]
		},
		{
			"name": "🔥 Thermal",
			"color": Color(1.0, 0.5, 0.2),
			"description": "Fire and explosive damage - excels at AOE and burn.",
			"details": [
				"• Scales with [color=#ff8833]Thermal[/color] flat stat",
				"• Multiplied by [color=#ff8833]Thermal %[/color] modifier",
				"• Best for: AOE damage, burn application",
				"• Weapons: Flamethrower, Rocket Launcher, Napalm Strike",
				"• Synergy: AOE builds, burn builds"
			]
		},
		{
			"name": "✨ Arcane",
			"color": Color(0.6, 0.3, 0.9),
			"description": "Magical damage - specializes in hex and execute effects.",
			"details": [
				"• Scales with [color=#9944ee]Arcane[/color] flat stat",
				"• Multiplied by [color=#9944ee]Arcane %[/color] modifier",
				"• Best for: Hex stacking, execute threshold",
				"• Weapons: Hex Bolt, Curse, Soul Drain, Void Strike",
				"• Synergy: Hex builds, execute builds, lifesteal"
			]
		},
	]


# =============================================================================
# WEAPON CATEGORIES (FAMILIES)
# =============================================================================

func _populate_categories() -> void:
	_categories_data = [
		{
			"name": "🔫 Kinetic",
			"color": Color(0.7, 0.7, 0.8),
			"description": "Reliable guns with consistent damage output.",
			"buff": "+Kinetic damage",
			"thresholds": "T1: 3-5 cards (+3) | T2: 6-8 cards (+6) | T3: 9+ cards (+10)",
			"scaling": "Scales with Kinetic stat"
		},
		{
			"name": "🔥 Thermal",
			"color": Color(1.0, 0.5, 0.2),
			"description": "Explosions and fire - AOE specialists.",
			"buff": "+Thermal damage",
			"thresholds": "T1: 3-5 cards (+3) | T2: 6-8 cards (+6) | T3: 9+ cards (+10)",
			"scaling": "Scales with Thermal stat + AOE%"
		},
		{
			"name": "✨ Arcane",
			"color": Color(0.6, 0.3, 0.9),
			"description": "Curses and magic - hex and execute specialists.",
			"buff": "+Arcane damage",
			"thresholds": "T1: 3-5 cards (+3) | T2: 6-8 cards (+6) | T3: 9+ cards (+10)",
			"scaling": "Scales with Arcane stat + Hex"
		},
		{
			"name": "🛡️ Fortress",
			"color": Color(0.5, 0.6, 0.7),
			"description": "Tanky offense - armor-based builds.",
			"buff": "+Armor at wave start",
			"thresholds": "T1: 3-5 cards (+3) | T2: 6-8 cards (+6) | T3: 9+ cards (+10)",
			"scaling": "Scales with Armor Start stat"
		},
		{
			"name": "🗡️ Shadow",
			"color": Color(0.3, 0.3, 0.4),
			"description": "Assassin weapons - crit specialists.",
			"buff": "+Crit Chance",
			"thresholds": "T1: 3-5 cards (+5%) | T2: 6-8 cards (+10%) | T3: 9+ cards (+15%)",
			"scaling": "Scales with Crit stats"
		},
		{
			"name": "⚙️ Utility",
			"color": Color(0.4, 0.7, 0.9),
			"description": "Combo engines - card draw and energy.",
			"buff": "+Draw per turn",
			"thresholds": "T1: 3-5 cards (+1) | T2: 6-8 cards (+2) | T3: 9+ cards (+3)",
			"scaling": "Scales with Cards Played"
		},
		{
			"name": "🚧 Control",
			"color": Color(0.3, 0.8, 0.5),
			"description": "Tower defense - barriers and positioning.",
			"buff": "Free barriers at wave start",
			"thresholds": "T1: 3-5 cards (1 barrier) | T2: 6-8 cards (1 barrier) | T3: 9+ cards (2 barriers)",
			"scaling": "Scales with Barriers + Ring position"
		},
		{
			"name": "💥 Volatile",
			"color": Color(0.9, 0.2, 0.3),
			"description": "Glass cannon - high risk, high reward.",
			"buff": "+Max HP",
			"thresholds": "T1: 3-5 cards (+5) | T2: 6-8 cards (+12) | T3: 9+ cards (+20)",
			"scaling": "Scales with Missing HP + Self-damage"
		},
	]


# =============================================================================
# ENEMY TYPES
# =============================================================================

func _populate_enemy_types() -> void:
	_enemy_types_data = [
		{
			"name": "🏃 Rusher",
			"color": Color(0.9, 0.3, 0.3),
			"description": "Standard enemies that advance every turn until reaching melee.",
			"details": "Most common behavior. Deal with them before they reach you!"
		},
		{
			"name": "⚡ Fast",
			"color": Color(1.0, 0.6, 0.2),
			"description": "Moves 2+ rings per turn - reaches you quickly!",
			"details": "High priority targets. Can close distance in 1-2 turns."
		},
		{
			"name": "🏹 Ranged",
			"color": Color(0.4, 0.6, 1.0),
			"description": "Stops at distance and attacks from afar.",
			"details": "Won't reach melee but can damage you from Mid/Far rings."
		},
		{
			"name": "💣 Bomber",
			"color": Color(1.0, 0.85, 0.2),
			"description": "Explodes when killed, dealing AOE damage.",
			"details": "Be careful when killing - explosion damages nearby enemies AND you!"
		},
		{
			"name": "📢 Buffer",
			"color": Color(0.7, 0.4, 1.0),
			"description": "Strengthens nearby enemies.",
			"details": "Priority target! Kill buffers first to weaken the horde."
		},
		{
			"name": "⚙️ Spawner",
			"color": Color(0.3, 0.9, 0.9),
			"description": "Creates additional enemies each turn.",
			"details": "Must kill quickly or get overwhelmed by reinforcements."
		},
		{
			"name": "🛡️ Tank",
			"color": Color(0.6, 0.6, 0.7),
			"description": "High HP and armor, slow but deadly.",
			"details": "Use multi-hit weapons to strip armor, then finish off."
		},
		{
			"name": "🗡️ Ambush",
			"color": Color(0.9, 0.5, 0.7),
			"description": "Spawns directly in Close range!",
			"details": "Dangerous surprise attacks. Keep defenses ready."
		},
		{
			"name": "⚔️ Shredder",
			"color": Color(0.8, 0.2, 0.2),
			"description": "Destroys your armor and barriers efficiently.",
			"details": "Counter to defensive builds. Kill before they reach you."
		},
		{
			"name": "👑 Boss",
			"color": Color(1.0, 0.8, 0.2),
			"description": "Powerful enemy with special abilities.",
			"details": "Unique mechanics - read their patterns and adapt!"
		},
	]


# =============================================================================
# GAME MECHANICS
# =============================================================================

func _populate_mechanics() -> void:
	_mechanics_data = [
		{
			"name": "🎯 Ring Battlefield",
			"color": Color(0.4, 0.7, 0.9),
			"description": "Combat takes place across 4 rings.",
			"details": [
				"[color=#ff6666]MELEE (0)[/color] - Enemies here attack you!",
				"[color=#ffaa44]CLOSE (1)[/color] - One step from melee",
				"[color=#66ff66]MID (2)[/color] - Middle distance",
				"[color=#6699ff]FAR (3)[/color] - Enemies spawn here",
				"",
				"Enemies advance toward melee each turn.",
				"Some weapons target specific rings.",
				"Barriers can be placed on rings to block/damage."
			]
		},
		{
			"name": "🔫 Multi-Hit System",
			"color": Color(0.7, 0.7, 0.8),
			"description": "Weapons fire multiple times per play.",
			"details": [
				"Most weapons hit 2+ times per card",
				"Each hit can:",
				"  • Remove 1 enemy armor",
				"  • Roll for crit separately",
				"  • Trigger on-hit effects",
				"",
				"Multi-hit is ESSENTIAL vs armored enemies!",
				"Example: Minigun (8 hits) vs 4 armor enemy:",
				"  Hits 1-4: Strip all armor",
				"  Hits 5-8: Deal 4x damage to HP"
			]
		},
		{
			"name": "⬆️ Tier System",
			"color": Color(0.4, 0.8, 0.4),
			"description": "Weapons can be merged to increase tier.",
			"details": [
				"[color=#aaaaaa]Tier 1[/color] - Base stats (×1.0)",
				"[color=#44ff44]Tier 2[/color] - +50% base damage (×1.5)",
				"[color=#4488ff]Tier 3[/color] - +100% base damage (×2.0)",
				"[color=#ffcc22]Tier 4[/color] - +150% base damage (×2.5)",
				"",
				"Merge 3 identical weapons to tier up!",
				"Higher tiers also boost scaling bonuses.",
				"Instant cards cannot be merged."
			]
		},
		{
			"name": "💥 Critical Hits",
			"color": Color(1.0, 0.8, 0.2),
			"description": "Chance to deal bonus damage.",
			"details": [
				"Base crit chance: 5%",
				"Base crit damage: 150% (×1.5)",
				"",
				"Crit stats can be increased by:",
				"  • Shadow family buffs",
				"  • Artifacts (Lucky Coin, Heavy Hitter)",
				"  • Some weapons have crit bonuses",
				"",
				"Each hit in multi-hit weapons rolls crit separately!"
			]
		},
		{
			"name": "👨‍👩‍👧‍👦 Family Buffs",
			"color": Color(0.8, 0.5, 0.9),
			"description": "Collect cards of the same category for bonuses.",
			"details": [
				"Each weapon has 1-2 categories (families)",
				"Having multiple cards of a category grants buffs:",
				"",
				"[color=#66ff66]Tier 1[/color]: 3-5 cards",
				"[color=#4488ff]Tier 2[/color]: 6-8 cards",
				"[color=#ffcc22]Tier 3[/color]: 9+ cards",
				"",
				"Build around 1-2 families for synergy!",
				"Family buffs apply to ALL your damage."
			]
		},
		{
			"name": "🌊 Ripple Effects",
			"color": Color(0.5, 0.8, 1.0),
			"description": "Chain reactions when killing enemies.",
			"details": [
				"Some weapons trigger effects on kill:",
				"",
				"[color=#ffaa44]Chain Damage[/color] - Hits nearby enemies",
				"[color=#ff6666]Group Damage[/color] - Damages same spawn group",
				"[color=#66ff66]AOE Damage[/color] - Hits entire ring",
				"[color=#aa66ff]Spread Damage[/color] - Scales with group size",
				"",
				"Ripple builds excel at horde slaughter!"
			]
		},
		{
			"name": "💰 Economy",
			"color": Color(1.0, 0.85, 0.3),
			"description": "Scrap and interest system.",
			"details": [
				"Earn scrap by killing enemies",
				"After each wave: +5% interest (max 25)",
				"",
				"Spend scrap in shop on:",
				"  • New weapons and skills",
				"  • Artifacts",
				"  • Stat upgrades",
				"  • Card removal",
				"",
				"Balance spending vs banking for interest!"
			]
		},
	]


# =============================================================================
# ARTIFACTS
# =============================================================================

func _populate_artifacts() -> void:
	_artifacts_data = [
		{
			"name": "Common Artifacts",
			"color": Color(0.7, 0.7, 0.7),
			"description": "Simple stat bonuses - stackable!",
			"items": [
				"Kinetic Rounds (+3 Kinetic dmg)",
				"Thermal Core (+3 Thermal dmg)",
				"Arcane Focus (+3 Arcane dmg)",
				"Lucky Coin (+5% Crit chance)",
				"Heavy Hitter (+20% Crit damage)",
				"Extra Rounds (+1 hit to all weapons)",
				"Iron Skin (+10 Max HP)",
				"Steel Plate (+3 Armor at wave start)",
				"Vampiric Fang (+5% Lifesteal)",
				"AOE Amplifier (+15% AOE damage)"
			]
		},
		{
			"name": "Uncommon Artifacts",
			"color": Color(0.3, 0.8, 0.3),
			"description": "Synergy enablers - build around these!",
			"items": [
				"Hunter's Instinct (On kill: heal 2 HP)",
				"Bounty Hunter (On kill: +2 scrap)",
				"Rapid Fire Module (Multi-hit +20% dmg)",
				"Crit Chain (Crits grant +1 hit)",
				"Executioner's Blade (Execute kills: +1 energy)",
				"Burn Amplifier (+50% Burn damage)",
				"Hex Amplifier (+50% Hex damage)",
				"Rapid Loader (+1 Draw per turn)",
				"Power Cell (+1 Energy per turn)",
				"Opening Salvo (First card: +2 hits)"
			]
		},
		{
			"name": "Rare Artifacts",
			"color": Color(0.3, 0.5, 1.0),
			"description": "Powerful effects that define builds.",
			"items": [
				"Overkill (Excess kill dmg chains)",
				"Death Echo (Kills deal 2 to group)",
				"Mercy Killer (+3 Execute threshold)",
				"Burning Strikes (Crits apply 2 Burn)",
				"Focused Fire (All multi-hit repeats)",
				"Berserker's Rage (+25% dmg, 1 self-dmg)"
			]
		},
		{
			"name": "Legendary Artifacts",
			"color": Color(1.0, 0.7, 0.2),
			"description": "Run-changing power!",
			"items": [
				"Infinity Engine (Kills refund 1 energy)",
				"Bullet Storm (+3 hits to all weapons)",
				"Blood Pact (+20% Lifesteal, -30 Max HP)",
				"Chain Reaction (Every kill triggers ripple)"
			]
		},
	]


# =============================================================================
# UI BUILDING
# =============================================================================

func _build_tabs() -> void:
	"""Build all tabs with content."""
	if not tab_container:
		return
	
	# Clear existing tabs
	for child in tab_container.get_children():
		child.queue_free()
	
	# Create each tab
	_create_status_effects_tab()
	_create_damage_types_tab()
	_create_categories_tab()
	_create_enemies_tab()
	_create_mechanics_tab()
	_create_artifacts_tab()


func _create_scrollable_container() -> ScrollContainer:
	"""Create a scrollable container for tab content."""
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return scroll


func _create_content_vbox() -> VBoxContainer:
	"""Create a VBox for content with proper spacing."""
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	return vbox


func _create_status_effects_tab() -> void:
	var scroll := _create_scrollable_container()
	scroll.name = "Status Effects"
	tab_container.add_child(scroll)
	
	var content := _create_content_vbox()
	scroll.add_child(content)
	
	var intro := _create_section_intro("Status effects change how enemies (and you) take damage. Understanding these is key to building powerful synergies!")
	content.add_child(intro)
	
	for effect: Dictionary in _status_effects_data:
		var card := _create_info_card(effect.name, effect.description, effect.details, effect.color)
		content.add_child(card)


func _create_damage_types_tab() -> void:
	var scroll := _create_scrollable_container()
	scroll.name = "Damage Types"
	tab_container.add_child(scroll)
	
	var content := _create_content_vbox()
	scroll.add_child(content)
	
	var intro := _create_section_intro("Every weapon has one damage type. Your stats boost damage of matching types!")
	content.add_child(intro)
	
	for dtype: Dictionary in _damage_types_data:
		var card := _create_info_card(dtype.name, dtype.description, dtype.details, dtype.color)
		content.add_child(card)


func _create_categories_tab() -> void:
	var scroll := _create_scrollable_container()
	scroll.name = "Families"
	tab_container.add_child(scroll)
	
	var content := _create_content_vbox()
	scroll.add_child(content)
	
	var intro := _create_section_intro("Weapons belong to families (categories). Collect cards of the same family for powerful bonuses!")
	content.add_child(intro)
	
	for cat: Dictionary in _categories_data:
		var details: Array = [
			cat.description,
			"",
			"[color=#ffcc44]Family Buff:[/color] " + cat.buff,
			"[color=#66aaff]Thresholds:[/color] " + cat.thresholds,
			"[color=#aa66ff]Scaling:[/color] " + cat.scaling
		]
		var card := _create_info_card(cat.name, "", details, cat.color)
		content.add_child(card)


func _create_enemies_tab() -> void:
	var scroll := _create_scrollable_container()
	scroll.name = "Enemies"
	tab_container.add_child(scroll)
	
	var content := _create_content_vbox()
	scroll.add_child(content)
	
	var intro := _create_section_intro("Enemies have behavior types that determine how they move and attack. Learn their patterns!")
	content.add_child(intro)
	
	# Create a 2-column grid for enemy types
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 15)
	content.add_child(grid)
	
	for enemy: Dictionary in _enemy_types_data:
		var card := _create_compact_card(enemy.name, enemy.description, enemy.details, enemy.color)
		grid.add_child(card)


func _create_mechanics_tab() -> void:
	var scroll := _create_scrollable_container()
	scroll.name = "Mechanics"
	tab_container.add_child(scroll)
	
	var content := _create_content_vbox()
	scroll.add_child(content)
	
	var intro := _create_section_intro("Core combat mechanics that every Riftwarden should master!")
	content.add_child(intro)
	
	for mech: Dictionary in _mechanics_data:
		var card := _create_info_card(mech.name, mech.description, mech.details, mech.color)
		content.add_child(card)


func _create_artifacts_tab() -> void:
	var scroll := _create_scrollable_container()
	scroll.name = "Artifacts"
	tab_container.add_child(scroll)
	
	var content := _create_content_vbox()
	scroll.add_child(content)
	
	var intro := _create_section_intro("Artifacts are permanent upgrades you buy in the shop. Build synergies by stacking similar effects!")
	content.add_child(intro)
	
	for artifact_group: Dictionary in _artifacts_data:
		var card := _create_artifact_card(artifact_group.name, artifact_group.description, artifact_group.items, artifact_group.color)
		content.add_child(card)


# =============================================================================
# UI COMPONENT CREATION
# =============================================================================

func _create_section_intro(text: String) -> Label:
	"""Create an intro label for a section."""
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _create_info_card(title: String, subtitle: String, details, accent_color: Color) -> PanelContainer:
	"""Create an info card with title, subtitle, and details."""
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 0.95)
	style.border_color = accent_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Title
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", accent_color)
	vbox.add_child(title_label)
	
	# Subtitle
	if not subtitle.is_empty():
		var subtitle_label := Label.new()
		subtitle_label.text = subtitle
		subtitle_label.add_theme_font_size_override("font_size", 15)
		subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75))
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(subtitle_label)
	
	# Details (as RichTextLabel for BBCode support)
	if details is Array:
		var details_label := RichTextLabel.new()
		details_label.bbcode_enabled = true
		details_label.fit_content = true
		details_label.scroll_active = false
		details_label.add_theme_font_size_override("normal_font_size", 14)
		details_label.add_theme_color_override("default_color", Color(0.65, 0.65, 0.6))
		details_label.text = "\n".join(details)
		vbox.add_child(details_label)
	
	return panel


func _create_compact_card(title: String, description: String, details: String, accent_color: Color) -> PanelContainer:
	"""Create a compact info card for grid layouts."""
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 0.95)
	style.border_color = accent_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", accent_color)
	vbox.add_child(title_label)
	
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	var details_label := Label.new()
	details_label.text = details
	details_label.add_theme_font_size_override("font_size", 12)
	details_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55))
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(details_label)
	
	return panel


func _create_artifact_card(title: String, description: String, items: Array, accent_color: Color) -> PanelContainer:
	"""Create an artifact group card with list of items."""
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 0.95)
	style.border_color = accent_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", accent_color)
	vbox.add_child(title_label)
	
	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.7))
	vbox.add_child(desc_label)
	
	# Items in a flow/grid
	var items_container := GridContainer.new()
	items_container.columns = 2
	items_container.add_theme_constant_override("h_separation", 20)
	items_container.add_theme_constant_override("v_separation", 4)
	vbox.add_child(items_container)
	
	for item: String in items:
		var item_label := Label.new()
		item_label.text = "• " + item
		item_label.add_theme_font_size_override("font_size", 13)
		item_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.6))
		items_container.add_child(item_label)
	
	return panel


# =============================================================================
# EVENTS
# =============================================================================

func _on_close_pressed() -> void:
	AudioManager.play_button_click()
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()

