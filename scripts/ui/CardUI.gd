extends Control
## CardUI - Visual representation of a card in hand

signal card_clicked(card_def, tier: int, hand_index: int)  # card_def: CardDefinition
signal card_hovered(card_def, tier: int, is_hovering: bool)  # card_def: CardDefinition

@onready var card_background: Panel = $CardBackground
@onready var cost_bg: Panel = $CardBackground/VBox/Header/CostBG
@onready var cost_label: Label = $CardBackground/VBox/Header/CostBG/CostLabel
@onready var name_label: Label = $CardBackground/VBox/Header/NameLabel
@onready var tier_label: Label = $CardBackground/VBox/Header/TierLabel
@onready var type_icon: Label = $CardBackground/VBox/TypeIcon
@onready var description: RichTextLabel = $CardBackground/VBox/Description
@onready var tags_label: Label = $CardBackground/VBox/TagsLabel
@onready var click_area: Button = $ClickArea

var card_def = null  # CardDefinition
var tier: int = 1
var hand_index: int = -1

const TYPE_ICONS: Dictionary = {
	"weapon": "⚔️",
	"skill": "✨",
	"hex": "☠️",
	"defense": "🛡️",
	"curse": "💀"
}

const TYPE_COLORS: Dictionary = {
	"weapon": Color(0.9, 0.4, 0.3),
	"skill": Color(0.4, 0.7, 0.9),
	"hex": Color(0.6, 0.3, 0.8),
	"defense": Color(0.4, 0.8, 0.5),
	"curse": Color(0.4, 0.4, 0.4)
}

const TIER_COLORS: Array[Color] = [
	Color(0.7, 0.7, 0.7),  # Tier 1 - Gray
	Color(0.3, 0.6, 1.0),  # Tier 2 - Blue
	Color(1.0, 0.8, 0.2)   # Tier 3 - Gold
]


func _ready() -> void:
	click_area.pressed.connect(_on_clicked)
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)


func setup(card, card_tier: int, index: int) -> void:  # card: CardDefinition
	card_def = card
	tier = card_tier
	hand_index = index
	
	_update_display()


func _update_display() -> void:
	if not card_def:
		return
	
	# Cost
	cost_label.text = str(card_def.base_cost)
	
	# Name with tier suffix
	var tier_suffix: String = card_def.get_tier_name(tier)
	name_label.text = card_def.card_name + tier_suffix
	
	# Tier indicator
	if tier > 1:
		tier_label.text = "T" + str(tier)
		tier_label.add_theme_color_override("font_color", TIER_COLORS[tier - 1])
	else:
		tier_label.text = ""
	
	# Type icon
	type_icon.text = TYPE_ICONS.get(card_def.card_type, "📜")
	
	# Description with values
	var desc_text: String = card_def.get_description_with_values(tier)
	description.text = "[center]" + desc_text + "[/center]"
	
	# Tags
	if card_def.tags.size() > 0:
		tags_label.text = ", ".join(card_def.tags).capitalize()
	else:
		tags_label.text = ""
	
	# Apply type color to background
	_apply_style()


func _apply_style() -> void:
	# Card background style
	var style: StyleBoxFlat = StyleBoxFlat.new()
	
	# Base color from type
	var base_color: Color = TYPE_COLORS.get(card_def.card_type, Color(0.3, 0.3, 0.3))
	style.bg_color = base_color.darkened(0.65)
	
	# Border color based on tier
	var tier_color: Color = TIER_COLORS[tier - 1] if tier <= 3 else TIER_COLORS[2]
	style.border_color = tier_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	
	card_background.add_theme_stylebox_override("panel", style)
	
	# Cost background style
	var cost_style: StyleBoxFlat = StyleBoxFlat.new()
	cost_style.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	cost_style.border_color = Color(1.0, 0.85, 0.2, 0.8)
	cost_style.set_border_width_all(2)
	cost_style.set_corner_radius_all(4)
	cost_bg.add_theme_stylebox_override("panel", cost_style)
	
	# Check if playable
	var can_play: bool = CombatManager.can_play_card(card_def, tier) if CombatManager else false
	if not can_play:
		modulate = Color(0.5, 0.5, 0.55, 1.0)
		cost_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4, 1.0))
	else:
		modulate = Color.WHITE
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))


func _on_clicked() -> void:
	card_clicked.emit(card_def, tier, hand_index)


func _on_mouse_entered() -> void:
	# Hover effect - scale up
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.parallel().tween_property(self, "position:y", position.y - 20, 0.1)
	
	# Bring to front
	z_index = 10
	
	card_hovered.emit(card_def, tier, true)


func _on_mouse_exited() -> void:
	# Reset hover effect
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(self, "position:y", position.y + 20, 0.1)
	
	z_index = 0
	
	card_hovered.emit(card_def, tier, false)
