extends RefCounted
class_name DeckManager
## DeckManager - Manages deck, hand, discard, and exhaust zones during combat

signal card_drawn(card_entry: Dictionary)
signal card_played(card_entry: Dictionary)
signal card_discarded(card_entry: Dictionary)
signal card_exhausted(card_entry: Dictionary)
signal deck_shuffled()
signal hand_changed()

# Card zones - each entry is {card_id: String, tier: int}
var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard: Array[Dictionary] = []
var exhaust: Array[Dictionary] = []


func initialize(starting_deck: Array) -> void:  # Array[Dictionary]
	"""Initialize the deck with starting cards and shuffle."""
	deck.clear()
	hand.clear()
	discard.clear()
	exhaust.clear()
	
	# Copy starting deck
	for card_entry: Dictionary in starting_deck:
		deck.append(card_entry.duplicate())
	
	shuffle_deck()


func shuffle_deck() -> void:
	"""Shuffle the draw pile."""
	deck.shuffle()
	deck_shuffled.emit()


func draw_card() -> Dictionary:
	"""Draw a card from deck to hand. Returns the drawn card or empty dict."""
	if deck.size() == 0:
		# Shuffle discard into deck
		if discard.size() > 0:
			deck = discard.duplicate()
			discard.clear()
			shuffle_deck()
		else:
			return {}  # No cards to draw
	
	if deck.size() > 0:
		var card_entry: Dictionary = deck.pop_back()
		hand.append(card_entry)
		card_drawn.emit(card_entry)
		hand_changed.emit()
		return card_entry
	
	return {}


func draw_cards(count: int) -> Array[Dictionary]:
	"""Draw multiple cards. Returns array of drawn cards."""
	var drawn: Array[Dictionary] = []
	for i: int in range(count):
		var card: Dictionary = draw_card()
		if card.size() > 0:
			drawn.append(card)
	return drawn


func play_card(hand_index: int) -> Dictionary:
	"""Play a card from hand to discard. Returns the played card."""
	if hand_index < 0 or hand_index >= hand.size():
		return {}
	
	var card_entry: Dictionary = hand[hand_index]
	hand.remove_at(hand_index)
	discard.append(card_entry)
	
	card_played.emit(card_entry)
	hand_changed.emit()
	
	return card_entry


func discard_card(hand_index: int) -> Dictionary:
	"""Discard a card from hand without playing it."""
	if hand_index < 0 or hand_index >= hand.size():
		return {}
	
	var card_entry: Dictionary = hand[hand_index]
	hand.remove_at(hand_index)
	discard.append(card_entry)
	
	card_discarded.emit(card_entry)
	hand_changed.emit()
	
	return card_entry


func exhaust_card(hand_index: int) -> Dictionary:
	"""Exhaust a card (remove from game for this combat)."""
	if hand_index < 0 or hand_index >= hand.size():
		return {}
	
	var card_entry: Dictionary = hand[hand_index]
	hand.remove_at(hand_index)
	exhaust.append(card_entry)
	
	card_exhausted.emit(card_entry)
	hand_changed.emit()
	
	return card_entry


func discard_hand() -> void:
	"""Discard all cards in hand."""
	while hand.size() > 0:
		discard_card(0)


func get_hand_size() -> int:
	"""Get current hand size."""
	return hand.size()


func get_deck_size() -> int:
	"""Get current deck size."""
	return deck.size()


func get_discard_size() -> int:
	"""Get current discard pile size."""
	return discard.size()


func get_card_at(hand_index: int) -> Dictionary:
	"""Get card entry at hand index."""
	if hand_index >= 0 and hand_index < hand.size():
		return hand[hand_index]
	return {}


func find_card_in_hand(card_id: String) -> int:
	"""Find index of card in hand by ID. Returns -1 if not found."""
	for i: int in range(hand.size()):
		if hand[i].card_id == card_id:
			return i
	return -1


func add_card_to_hand(card_id: String, tier: int = 1) -> void:
	"""Add a card directly to hand."""
	var card_entry: Dictionary = {"card_id": card_id, "tier": tier}
	hand.append(card_entry)
	hand_changed.emit()


func add_card_to_discard(card_id: String, tier: int = 1) -> void:
	"""Add a card directly to discard pile."""
	var card_entry: Dictionary = {"card_id": card_id, "tier": tier}
	discard.append(card_entry)


func add_card_to_deck(card_id: String, tier: int = 1, shuffle_after: bool = true) -> void:
	"""Add a card to the deck."""
	var card_entry: Dictionary = {"card_id": card_id, "tier": tier}
	deck.append(card_entry)
	if shuffle_after:
		shuffle_deck()

