extends RefCounted
class_name DeckManager
## DeckManager - Manages deck, hand, discard, and exhaust zones during combat

signal card_drawn(card_entry: Dictionary)
signal card_played(card_entry: Dictionary)
signal card_discarded(card_entry: Dictionary)
signal card_exhausted(card_entry: Dictionary)
signal card_deployed(card_entry: Dictionary)  # Persistent weapon deployed
signal card_undeployed(card_entry: Dictionary)  # Weapon removed from play
signal card_banished(card_entry: Dictionary)  # Card banished for rest of wave
signal deck_shuffled()
signal hand_changed()

# Card zones - each entry is {card_id: String, tier: int}
var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard: Array[Dictionary] = []
var exhaust: Array[Dictionary] = []
var deployed: Array[Dictionary] = []  # Persistent weapons currently in play (OUT of deck)
var banished: Array[Dictionary] = []  # Cards removed for rest of wave (return next wave)


func initialize(starting_deck: Array) -> void:  # Array[Dictionary]
	"""Initialize the deck with starting cards and shuffle."""
	deck.clear()
	hand.clear()
	discard.clear()
	exhaust.clear()
	deployed.clear()
	banished.clear()
	
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


# =============================================================================
# V2 DEPLOYED WEAPON MANAGEMENT
# =============================================================================

func deploy_card(hand_index: int) -> Dictionary:
	"""Deploy a persistent card from hand. Card is removed from deck circulation while deployed.
	Returns the deployed card entry."""
	if hand_index < 0 or hand_index >= hand.size():
		return {}
	
	var card_entry: Dictionary = hand[hand_index]
	hand.remove_at(hand_index)
	deployed.append(card_entry)
	
	card_deployed.emit(card_entry)
	hand_changed.emit()
	
	return card_entry


func undeploy_card(deployed_index: int, destination: String = "discard") -> Dictionary:
	"""Remove a deployed weapon and send it to the specified destination.
	destination: "discard" (can draw again), "banish" (gone for wave), "destroy" (gone forever)
	Returns the removed card entry."""
	if deployed_index < 0 or deployed_index >= deployed.size():
		return {}
	
	var card_entry: Dictionary = deployed[deployed_index]
	deployed.remove_at(deployed_index)
	
	match destination:
		"discard":
			discard.append(card_entry)
			card_discarded.emit(card_entry)
		"banish":
			banished.append(card_entry)
			card_banished.emit(card_entry)
		"destroy":
			exhaust.append(card_entry)
			card_exhausted.emit(card_entry)
		_:
			discard.append(card_entry)
			card_discarded.emit(card_entry)
	
	card_undeployed.emit(card_entry)
	return card_entry


func undeploy_card_by_id(card_id: String, destination: String = "discard") -> Dictionary:
	"""Remove a deployed weapon by card_id and send it to destination."""
	for i: int in range(deployed.size()):
		if deployed[i].card_id == card_id:
			return undeploy_card(i, destination)
	return {}


func banish_card_from_hand(hand_index: int) -> Dictionary:
	"""Banish a card from hand (removed for rest of wave)."""
	if hand_index < 0 or hand_index >= hand.size():
		return {}
	
	var card_entry: Dictionary = hand[hand_index]
	hand.remove_at(hand_index)
	banished.append(card_entry)
	
	card_banished.emit(card_entry)
	hand_changed.emit()
	
	return card_entry


func get_deployed_count() -> int:
	"""Get number of deployed weapons."""
	return deployed.size()


func get_deployed_cards() -> Array[Dictionary]:
	"""Get all deployed weapon entries."""
	return deployed


func is_card_deployed(card_id: String) -> bool:
	"""Check if a card with given ID is currently deployed."""
	for entry: Dictionary in deployed:
		if entry.card_id == card_id:
			return true
	return false


func return_banished_to_deck() -> void:
	"""Return all banished cards to deck (call at wave end)."""
	for card_entry: Dictionary in banished:
		deck.append(card_entry)
	banished.clear()
	shuffle_deck()


func return_deployed_to_deck() -> void:
	"""Return all deployed weapons to deck (call at wave end)."""
	for card_entry: Dictionary in deployed:
		discard.append(card_entry)
	deployed.clear()

