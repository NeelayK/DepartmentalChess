extends RefCounted
class_name PlayerState

const HAND_LIMIT := 7

var is_white: bool
var deck: Array[Card] = []
var hand: Array[Card] = []
var active_deck: Array[Card] = []

var ap: int = 0
var saved_ap: int = 0

func draw(n := 1) -> void:
	for i in n:
		if deck.is_empty():
			return
		if hand.size() >= HAND_LIMIT:
			return
		hand.append(deck.pop_back())

func can_select_more_cards() -> bool:
	return active_deck.size() < 3

func select_card(card: Card) -> bool:
	if card in active_deck:
		return false
	if not can_select_more_cards():
		return false

	active_deck.append(card)
	return true

func unselect_card(card: Card) -> void:
	active_deck.erase(card)

func clear_active_deck() -> void:
	active_deck.clear()
