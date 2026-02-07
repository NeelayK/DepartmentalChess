extends RefCounted
class_name PlayerState

const HAND_LIMIT := 7

var is_white: bool
var deck: Array[Card] = []
var hand: Array[Card] = []
var active_cards: Array[Card] = []

var ap: int = 0
var saved_ap: int = 0

func draw(n := 1) -> void:
	for i in n:
		if deck.is_empty():
			return
		if hand.size() >= HAND_LIMIT:
			return
		hand.append(deck.pop_back())
