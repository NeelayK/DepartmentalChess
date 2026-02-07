extends Node
class_name CardDatabase

static func make_test_deck() -> Array[Card]:
	var deck: Array[Card] = []

	for i in 5:
		var c := Card.new()
		c.name = "Gain 2 AP"
		c.description = "Gain 2 Action Points"
		c.type = Card.CardType.AP_GAIN
		c.ap_gain = 2
		deck.append(c)

	deck.shuffle()
	return deck
